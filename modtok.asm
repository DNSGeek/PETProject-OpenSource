; ============================================================================
; modtok.asm — Tokenizer module for PETProject v0.1
;
; Converts detokenized plain-text BASIC (CR-separated lines) to tokenized
; BASIC 2.0 PRG format. Inverse of moddet.asm.
;
; Entry:  JSR $C000 (first 3 bytes = JMP tokenize)
; Input:  MOD_BUF = "10 REM HELLO\r20 PRINT\"X\"\r" (CR-separated, UPPERCASE)
; Output: Standard C64 BASIC 2.0 PRG in MOD_BUF. MOD_NEW_END updated.
;
; Tokenization:
;   Longest keyword match wins. No tokenization inside "" strings.
;   After REM: rest of line is literal. Operators tokenized outside strings.
;
; ZP dual-use (no overlap — LINENO only used before try_keyword is called):
;   $3A/$3B = LINENO lo/hi  (digit parse phase)
;          = KW_TOKEN/$3B KW_XSAVE  (try_keyword phase)
;   $3C/$3D = TMP16 lo/hi   (multiply scratch / kwtab pointer)
;   $3E     = IN_STRING      ($FF = inside string, $00 = not)
;   $3F     = AFTER_REM      ($FF = past REM, $00 = not)
;   $F7/$F8 = LINK_PTR       (back-patch pointer for link words)
;   $F9/$FA = BASIC_ADDR     (running $0801-based C64 address)
;   $FB/$FC = SRC_PTR        (input pointer)
;   $FD/$FE = DST_PTR        (staging output pointer)
;   $FF     = OVFLAG         ($FF = staging overflowed, output truncated)
;
; Lessons from moddet: PHA/PLA around JSR before branches. INC corrupts flags.
; Advance SRC_PTR past CR before re-entering @line_loop. STAGING at $C300.
; Copy loop compares COPY_SRC (not COPY_DST) against DST_PTR.
; ============================================================================

.setcpu "6502"

MOD_MAGIC       = $0212
MOD_MAGIC_VAL   = $4D
MOD_BUF_LO      = $0214
MOD_BUF_HI      = $0215
MOD_BUF_END_LO  = $021A
MOD_BUF_END_HI  = $021B
MOD_STATUS      = $021E
MOD_NEW_END_LO  = $021F
MOD_NEW_END_HI  = $0220
MOD_GAP_START_LO = $0216
MOD_GAP_START_HI = $0217

LINENO          = $3A   ; line number lo (hi at $3B); also KW_TOKEN in try_keyword
KW_TOKEN        = $3A   ; token byte (try_keyword) — same ZP, different phase
KW_XSAVE        = $3B   ; saved source index (try_keyword)
TMP16           = $3C   ; 16-bit scratch lo (hi at $3D)
IN_STRING       = $3E
AFTER_REM       = $3F
LINK_PTR        = $F7   ; lo (hi at $F8)
BASIC_ADDR      = $F9   ; lo (hi at $FA)
SRC_PTR         = $FB   ; lo (hi at $FC)
DST_PTR         = $FD   ; lo (hi at $FE)
OVFLAG          = $FF   ; staging overflow flag ($FF = overflowed)

BASIC_START     = $0801
STAGING         = $C400
; First address staging may NOT touch: $D000 is the I/O area while the
; module runs, so an unchecked write there sprays VIC/SID/CIA registers.
STAGING_END     = $D000

.segment "LOADADDR"
    .word $C000

.segment "CODE"

    jmp tokenize

; ============================================================================
; tokenize
; ============================================================================

tokenize:
    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq :+
    jmp @bad
:

    lda MOD_BUF_LO
    sta SRC_PTR
    lda MOD_BUF_HI
    sta SRC_PTR+1

    lda #<STAGING
    sta DST_PTR
    lda #>STAGING
    sta DST_PTR+1
    lda #0
    sta OVFLAG

    lda #$01
    jsr emit_byte
    lda #$08
    jsr emit_byte               ; PRG load address $0108... wait: $0801 lo=$01, hi=$08

    lda #<BASIC_START
    sta BASIC_ADDR
    lda #>BASIC_START
    sta BASIC_ADDR+1

; ============================================================================
; @line_loop
; ============================================================================

@line_loop:
    lda SRC_PTR
    cmp MOD_GAP_START_LO
    lda SRC_PTR+1
    sbc MOD_GAP_START_HI
    bcc :+
    jmp @all_done
:

    ldy #0
    lda (SRC_PTR),y
    bne :+
    jmp @all_done
:   cmp #$0D
    bne @parse_lineno
    jsr inc_src_ptr
    jmp @line_loop

@parse_lineno:
    lda #0
    sta LINENO
    sta LINENO+1

@digit_loop:
    ldy #0
    lda (SRC_PTR),y
    cmp #'0'
    bcc @digits_done
    cmp #'9'+1
    bcs @digits_done
    sec
    sbc #'0'
    pha                         ; save digit; mul uses shifts
    ; TMP16 = LINENO<<1
    lda LINENO
    asl a
    sta TMP16
    lda LINENO+1
    rol a
    sta TMP16+1
    ; LINENO <<= 3
    asl LINENO
    rol LINENO+1
    asl LINENO
    rol LINENO+1
    asl LINENO
    rol LINENO+1
    ; LINENO = *8 + *2 = *10
    lda LINENO
    clc
    adc TMP16
    sta LINENO
    lda LINENO+1
    adc TMP16+1
    sta LINENO+1
    pla                         ; retrieve digit
    clc
    adc LINENO
    sta LINENO
    bcc :+
    inc LINENO+1
:   jsr inc_src_ptr
    jmp @digit_loop

@digits_done:
@skip_spaces:
    ldy #0
    lda (SRC_PTR),y
    cmp #$20
    bne @begin_line
    jsr inc_src_ptr
    jmp @skip_spaces

@begin_line:
    lda DST_PTR
    sta LINK_PTR
    lda DST_PTR+1
    sta LINK_PTR+1

    lda #0
    jsr emit_byte               ; link word placeholder lo
    jsr emit_byte               ; link word placeholder hi
    lda LINENO
    jsr emit_byte               ; line number lo
    lda LINENO+1
    jsr emit_byte               ; line number hi

    lda BASIC_ADDR
    clc
    adc #4
    sta BASIC_ADDR
    bcc :+
    inc BASIC_ADDR+1
:

    lda #0
    sta IN_STRING
    sta AFTER_REM

; ============================================================================
; @token_loop
; ============================================================================

@token_loop:
    ldy #0
    lda (SRC_PTR),y
    beq @eof_line               ; source ended mid-line — close the line first
    cmp #$0D
    beq @end_line

    lda AFTER_REM
    bne @literal

    ldy #0
    lda (SRC_PTR),y
    cmp #$22
    bne @no_quote
    lda IN_STRING
    eor #$FF
    sta IN_STRING
    lda #$22
    jsr inc_src_ptr
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop
@no_quote:

    lda IN_STRING
    bne @literal

    jsr try_keyword
    bcc @literal

    ; keyword matched: A = token, SRC_PTR advanced
    cmp #$8F
    bne :+
    lda #$FF
    sta AFTER_REM
    lda #$8F
:   jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@literal:
    ldy #0
    lda (SRC_PTR),y
    jsr inc_src_ptr
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@end_line:
    jsr inc_src_ptr             ; advance past CR first (moddet lesson)
    lda #0
    jsr emit_byte               ; null terminator
    jsr inc_basic_addr

    ; back-patch link word
    ldy #0
    lda BASIC_ADDR
    sta (LINK_PTR),y
    iny
    lda BASIC_ADDR+1
    sta (LINK_PTR),y

    jmp @line_loop

@eof_line:
    ; Source ended without a trailing CR: close the line properly — emit
    ; the $00 terminator and back-patch the link word — before finishing.
    ; Otherwise the line's link stays at its $0000 placeholder, which is
    ; BASIC's end-of-program marker, and the whole line silently vanishes.
    lda #0
    jsr emit_byte
    jsr inc_basic_addr
    ldy #0
    lda BASIC_ADDR
    sta (LINK_PTR),y
    iny
    lda BASIC_ADDR+1
    sta (LINK_PTR),y
    jmp @all_done

; ============================================================================
; @all_done
; ============================================================================

@all_done:
    lda #0
    jsr emit_byte
    jsr emit_byte               ; $00 $00 end-of-program

    ; If staging overflowed, the output is truncated — do NOT copy it back
    ; over the caller's plain-text buffer.  Report an error and leave
    ; MOD_BUF intact (the caller keeps its untokenized text).
    lda OVFLAG
    beq :+
    jmp @bad
:
    ; copy staging → MOD_BUF
    lda #<STAGING
    sta LINK_PTR
    lda #>STAGING
    sta LINK_PTR+1
    lda MOD_BUF_LO
    sta BASIC_ADDR
    lda MOD_BUF_HI
    sta BASIC_ADDR+1

@copy:
    lda LINK_PTR
    cmp DST_PTR
    bne @copy_byte
    lda LINK_PTR+1
    cmp DST_PTR+1
    beq @copy_done
@copy_byte:
    ldy #0
    lda (LINK_PTR),y
    sta (BASIC_ADDR),y
    inc LINK_PTR
    bne :+
    inc LINK_PTR+1
:   inc BASIC_ADDR
    bne @copy
    inc BASIC_ADDR+1
    jmp @copy

@copy_done:
    lda BASIC_ADDR
    sta MOD_NEW_END_LO
    lda BASIC_ADDR+1
    sta MOD_NEW_END_HI
    lda #$02
    sta MOD_STATUS
    rts

@bad:
    lda #$01
    sta MOD_STATUS
    rts

; ============================================================================
; try_keyword — longest-first keyword match at SRC_PTR.
;
; Table: [token][chars, last|$80] ... $FF sentinel
;
; Register protocol:
;   TMP16 ($3C/$3D): kwtab pointer. Advanced by INC one char at a time.
;   KW_TOKEN ($3A): token byte for current entry (saved at @kw_next).
;   KW_XSAVE ($3B): source index X, saved here before forcing Y=0 for kwtab read.
;   X: source char index (0=first char). Incremented per match step.
;   Stack: 2 pushes per loop (source index, keyword char with bit7). Both pulled per loop.
;
; Returns carry set + A=token on match (SRC_PTR advanced by keyword length).
;         carry clear on no match.
; ============================================================================

try_keyword:
    lda #<kwtab
    sta TMP16
    lda #>kwtab
    sta TMP16+1

@kw_next:
    ldy #0
    lda (TMP16),y
    cmp #$FF
    beq @kw_no_match
    sta KW_TOKEN                ; save token byte
    inc TMP16                   ; advance past token byte
    bne :+
    inc TMP16+1
:   ldx #0                      ; X = source char index

@kw_match:
    stx KW_XSAVE                ; save source index
    ldy #0
    lda (TMP16),y               ; read keyword char (with bit7 end-marker)
    pha                         ; save full byte BEFORE INC corrupts N
    inc TMP16                   ; advance TMP16 (INC corrupts N — PHA already done)
    bne :+
    inc TMP16+1
:   pla                         ; PLA: N = bit7 of keyword char ✓
    pha                         ; save again — need bit7 after comparison
    and #$7F                    ; A = keyword char (no bit7)
    ldy KW_XSAVE                ; Y = source index (does NOT clobber A)
    cmp (SRC_PTR),y             ; keyword char == source char?
    ; Branch on MISMATCH before PLA can clobber Z flag:
    bne @kw_mismatch_pull       ; mismatch — pull saved byte and handle
    ; Match on this char. Pull saved byte to check if it was the last char:
    pla                         ; PLA: N = bit7 of keyword char ✓
    bmi @kw_full_match          ; bit7 set → last char matched → full match
    ; More chars to compare:
    ldx KW_XSAVE
    inx
    jmp @kw_match

@kw_mismatch_pull:
    ; CMP said mismatch. The saved keyword char byte is on stack — pull it.
    pla                         ; PLA: N = bit7 of the mismatched keyword char
    bmi @kw_next                ; bit7 set → we were on the last char → already past entry
    ; bit7 clear → more chars remain in this entry; skip to the end
@kw_skip:
    ldy #0
    lda (TMP16),y
    pha                         ; save with bit7
    inc TMP16
    bne :+
    inc TMP16+1
:   pla                         ; PLA: N = bit7
    bpl @kw_skip                ; bit7 clear → more chars
    jmp @kw_next                ; bit7 set → past end of entry

@kw_full_match:
    ; X = index of last matched char = keyword_length - 1.
    ; Advance SRC_PTR by X+1 = keyword_length.
    ldx KW_XSAVE
    inx                         ; X = keyword length
@kw_advance:
    jsr inc_src_ptr
    dex
    bne @kw_advance
    lda KW_TOKEN
    sec
    rts

@kw_no_match:
    clc
    rts

; ============================================================================
; inc_basic_addr — advance BASIC_ADDR by 1.
; ============================================================================

inc_basic_addr:
    inc BASIC_ADDR
    bne :+
    inc BASIC_ADDR+1
:   rts

; ============================================================================
; emit_byte — write A to (DST_PTR), advance DST_PTR. Clobbers Y.
; Bounds-checked: at STAGING_END the byte is dropped and OVFLAG is set —
; without this, output longer than staging (~3 KB of source) would write
; straight through the $D000 I/O registers.
; ============================================================================

emit_byte:
    ldy DST_PTR+1
    cpy #>STAGING_END
    bcs @overflow
    ldy #0
    sta (DST_PTR),y
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:   rts
@overflow:
    ldy #$FF
    sty OVFLAG
    rts

; ============================================================================
; inc_src_ptr — advance SRC_PTR by 1.
; ============================================================================

inc_src_ptr:
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   rts

; ============================================================================
; kwtab — longest-first. [token][chars, last|$80] ... $FF sentinel
; ============================================================================

kwtab:
    .byte $CC,$41,$53,$53,$45,$4D,$42,$4C,$C5   ; ASSEMBLE
    .byte $CD,$49,$4E,$43,$4C,$55,$44,$C5       ; INCLUDE
    .byte $CE,$52,$55,$4E,$50,$52,$4F,$C7       ; RUNPROG  (before RUN)
    .byte $CF,$53,$43,$52,$41,$54,$43,$C8       ; SCRATCH
    .byte $8C,$52,$45,$53,$54,$4F,$52,$C5   ; RESTORE (7)
    .byte $D0,$44,$45,$4C,$45,$54,$C5           ; DELETE
    .byte $D1,$45,$58,$49,$53,$54,$D3           ; EXISTS
    .byte $D2,$52,$45,$4E,$41,$4D,$C5           ; RENAME
    .byte $D3,$53,$54,$41,$54,$55,$D3           ; STATUS
    .byte $84,$49,$4E,$50,$55,$54,$A3       ; INPUT#  (6)
    .byte $98,$50,$52,$49,$4E,$54,$A3       ; PRINT#  (6)
    .byte $8E,$52,$45,$54,$55,$52,$CE       ; RETURN  (6)
    .byte $C9,$52,$49,$47,$48,$54,$A4       ; RIGHT$  (6)
    .byte $95,$56,$45,$52,$49,$46,$D9       ; VERIFY  (6)
    .byte $D4,$44,$52,$49,$56,$C5               ; DRIVE
    .byte $D5,$4F,$4E,$45,$52,$D2               ; ONERR
    .byte $D6,$50,$41,$55,$53,$C5               ; PAUSE
    .byte $A0,$43,$4C,$4F,$53,$C5           ; CLOSE   (5)
    .byte $8D,$47,$4F,$53,$55,$C2           ; GOSUB   (5)
    .byte $85,$49,$4E,$50,$55,$D4           ; INPUT   (5)
    .byte $C8,$4C,$45,$46,$54,$A4           ; LEFT$   (5)
    .byte $99,$50,$52,$49,$4E,$D4           ; PRINT   (5)
    .byte $D7,$43,$4F,$50,$D9                   ; COPY
    .byte $C7,$43,$48,$52,$A4               ; CHR$    (4)
    .byte $9A,$43,$4F,$4E,$D4               ; CONT    (4)
    .byte $83,$44,$41,$54,$C1               ; DATA    (4)
    .byte $89,$47,$4F,$54,$CF               ; GOTO    (4)
    .byte $9B,$4C,$49,$53,$D4               ; LIST    (4)
    .byte $93,$4C,$4F,$41,$C4               ; LOAD    (4)
    .byte $CA,$4D,$49,$44,$A4               ; MID$    (4)
    .byte $82,$4E,$45,$58,$D4               ; NEXT    (4)
    .byte $9F,$4F,$50,$45,$CE               ; OPEN    (4)
    .byte $C2,$50,$45,$45,$CB               ; PEEK    (4)
    .byte $97,$50,$4F,$4B,$C5               ; POKE    (4)
    .byte $87,$52,$45,$41,$C4               ; READ    (4)
    .byte $94,$53,$41,$56,$C5               ; SAVE    (4)
    .byte $A6,$53,$50,$43,$A8               ; SPC(    (4)
    .byte $A9,$53,$54,$45,$D0               ; STEP    (4)
    .byte $90,$53,$54,$4F,$D0               ; STOP    (4)
    .byte $C4,$53,$54,$52,$A4               ; STR$    (4)
    .byte $A3,$54,$41,$42,$A8               ; TAB(    (4)
    .byte $A7,$54,$48,$45,$CE               ; THEN    (4)
    .byte $92,$57,$41,$49,$D4               ; WAIT    (4)
    .byte $D8,$44,$49,$D2                       ; DIR
    .byte $B6,$41,$42,$D3                   ; ABS     (3)
    .byte $AF,$41,$4E,$C4                   ; AND     (3)
    .byte $C6,$41,$53,$C3                   ; ASC     (3)
    .byte $C1,$41,$54,$CE                   ; ATN     (3)
    .byte $9C,$43,$4C,$D2                   ; CLR     (3)
    .byte $9D,$43,$4D,$C4                   ; CMD     (3)
    .byte $BE,$43,$4F,$D3                   ; COS     (3)
    .byte $96,$44,$45,$C6                   ; DEF     (3)
    .byte $86,$44,$49,$CD                   ; DIM     (3)
    .byte $80,$45,$4E,$C4                   ; END     (3)
    .byte $BD,$45,$58,$D0                   ; EXP     (3)
    .byte $81,$46,$4F,$D2                   ; FOR     (3)
    .byte $B8,$46,$52,$C5                   ; FRE     (3)
    .byte $A1,$47,$45,$D4                   ; GET     (3)
    .byte $B5,$49,$4E,$D4                   ; INT     (3)
    .byte $C3,$4C,$45,$CE                   ; LEN     (3)
    .byte $88,$4C,$45,$D4                   ; LET     (3)
    .byte $BC,$4C,$4F,$C7                   ; LOG     (3)
    .byte $A2,$4E,$45,$D7                   ; NEW     (3)
    .byte $A8,$4E,$4F,$D4                   ; NOT     (3)
    .byte $B9,$50,$4F,$D3                   ; POS     (3)
    .byte $8F,$52,$45,$CD                   ; REM     (3)
    .byte $BB,$52,$4E,$C4                   ; RND     (3)
    .byte $8A,$52,$55,$CE                   ; RUN     (3)
    .byte $B4,$53,$47,$CE                   ; SGN     (3)
    .byte $BF,$53,$49,$CE                   ; SIN     (3)
    .byte $BA,$53,$51,$D2                   ; SQR     (3)
    .byte $9E,$53,$59,$D3                   ; SYS     (3)
    .byte $C0,$54,$41,$CE                   ; TAN     (3)
    .byte $B7,$55,$53,$D2                   ; USR     (3)
    .byte $C5,$56,$41,$CC                   ; VAL     (3)
    .byte $A5,$46,$CE                       ; FN      (2)
    .byte $CB,$47,$CF                       ; GO      (2)
    .byte $8B,$49,$C6                       ; IF      (2)
    .byte $91,$4F,$CE                       ; ON      (2)
    .byte $B0,$4F,$D2                       ; OR      (2)
    .byte $A4,$54,$CF                       ; TO      (2)
    .byte $AC,$AA                           ; *       (1)
    .byte $AA,$AB                           ; +       (1)
    .byte $AB,$AD                           ; -       (1)
    .byte $AD,$AF                           ; /       (1)
    .byte $B3,$BC                           ; <       (1)
    .byte $B2,$BD                           ; =       (1)
    .byte $B1,$BE                           ; >       (1)
    .byte $AE,$DE                           ; ^       (1)
    .byte $FF                               ; sentinel
