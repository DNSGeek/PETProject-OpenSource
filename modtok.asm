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
; Advance SRC_PTR past CR before re-entering @line_loop.
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
; STREAMING MODEL (no staging buffer): the source text is first relocated
; to the TOP of work_buf with a descending copy, then tokenized forward
; with output written from MOD_BUF up.  Output must stay strictly below
; the relocated input (reloc_lo/hi); on violation the original text is
; restored exactly from the untouched relocated copy and the module
; errors out.  This replaces the old 3 KB module-RAM staging buffer and
; its copy-back — capacity is now "text + tokenized output <= 24 KB"
; (roughly a 13 KB source) instead of ~2.9 KB of output.

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

    ; ---- Relocate the source text to the top of the buffer ----
    ; len = MOD_GAP_START - MOD_BUF (content is contiguous — the save path
    ; ran compact_gap); reloc = MOD_BUF_END - len.
    lda MOD_GAP_START_LO
    sec
    sbc MOD_BUF_LO
    sta TMP16                   ; len lo
    lda MOD_GAP_START_HI
    sbc MOD_BUF_HI
    sta TMP16+1                 ; len hi
    lda MOD_BUF_END_LO
    sec
    sbc TMP16
    sta reloc_lo
    lda MOD_BUF_END_HI
    sbc TMP16+1
    sta reloc_hi

    ; Descending copy [MOD_BUF..MOD_BUF+len) -> [reloc..MOD_BUF_END).
    ; Regions overlap whenever len > free space, so the copy must run
    ; from the last byte down.  Pointers start one past their block.
    lda MOD_GAP_START_LO
    sta SRC_PTR
    lda MOD_GAP_START_HI
    sta SRC_PTR+1
    lda MOD_BUF_END_LO
    sta DST_PTR
    lda MOD_BUF_END_HI
    sta DST_PTR+1
@reloc_loop:
    lda TMP16
    ora TMP16+1
    beq @reloc_done
    lda SRC_PTR
    bne :+
    dec SRC_PTR+1
:   dec SRC_PTR
    lda DST_PTR
    bne :+
    dec DST_PTR+1
:   dec DST_PTR
    ldy #0
    lda (SRC_PTR),y
    sta (DST_PTR),y
    lda TMP16
    bne :+
    dec TMP16+1
:   dec TMP16
    jmp @reloc_loop
@reloc_done:

    ; ---- Stream: read from the relocated copy, write from MOD_BUF ----
    lda reloc_lo
    sta SRC_PTR
    lda reloc_hi
    sta SRC_PTR+1
    lda MOD_BUF_LO
    sta DST_PTR
    lda MOD_BUF_HI
    sta DST_PTR+1
    lda #0
    sta OVFLAG

    lda #$01
    jsr emit_byte
    lda #$08
    jsr emit_byte               ; PRG load-address header: $0801 lo, hi

    lda #<BASIC_START
    sta BASIC_ADDR
    lda #>BASIC_START
    sta BASIC_ADDR+1

; ============================================================================
; @line_loop
; ============================================================================

@line_loop:
    ; Source is the relocated copy, which ends exactly at MOD_BUF_END.
    lda SRC_PTR
    cmp MOD_BUF_END_LO
    lda SRC_PTR+1
    sbc MOD_BUF_END_HI
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
    sta after_data

; ============================================================================
; @token_loop
; ============================================================================

@token_loop:
    ldy #0
    lda (SRC_PTR),y
    bne :+
    jmp @eof_line               ; source ended mid-line — close the line first
:   cmp #$0D
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

    ; DATA statements: real CRUNCH copies everything after DATA literally
    ; until ':' (outside quotes) or end of line.  Tokenizing here corrupts
    ; the data — "DATA MONDAY" LISTs fine but READs garbage token bytes.
    lda after_data
    beq @not_data
    ldy #0
    lda (SRC_PTR),y
    cmp #':'
    bne @literal                ; still inside the DATA item list
    lda #0
    sta after_data              ; ':' ends the statement...
    jmp @literal                ; ...and is itself emitted literally
@not_data:

    ; '?' is BASIC shorthand for PRINT — CRUNCH tokenizes it to $99.
    ; Left literal it would be a runtime SYNTAX ERROR.
    ldy #0
    lda (SRC_PTR),y
    cmp #'?'
    bne @not_qmark
    jsr inc_src_ptr
    lda #$99                    ; PRINT token
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop
@not_qmark:

    jsr try_keyword
    bcc @literal

    ; keyword matched: A = token, SRC_PTR advanced
    cmp #$8F                    ; REM — rest of LINE is literal
    bne :+
    ldx #$FF
    stx AFTER_REM
:   cmp #$83                    ; DATA — rest of STATEMENT is literal
    bne :+
    ldx #$FF
    stx after_data
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

    ; Output was written in place, so on success there is nothing to copy.
    ; On overflow (output met the relocated source) the tokenized result is
    ; truncated AND the low part of the original text was overwritten — but
    ; the relocated copy above the collision point was never touched, so
    ; the user's text can be restored exactly.
    lda OVFLAG
    beq @success

    ; Restore text: ascending copy [reloc..MOD_BUF_END) -> MOD_BUF.
    ; Moving DOWN in memory, so the forward copy is overlap-safe.
    lda reloc_lo
    sta LINK_PTR
    lda reloc_hi
    sta LINK_PTR+1
    lda MOD_BUF_LO
    sta BASIC_ADDR
    lda MOD_BUF_HI
    sta BASIC_ADDR+1
@rst:
    lda LINK_PTR
    cmp MOD_BUF_END_LO
    bne @rst_byte
    lda LINK_PTR+1
    cmp MOD_BUF_END_HI
    beq @rst_done
@rst_byte:
    ldy #0
    lda (LINK_PTR),y
    sta (BASIC_ADDR),y
    inc LINK_PTR
    bne :+
    inc LINK_PTR+1
:   inc BASIC_ADDR
    bne @rst
    inc BASIC_ADDR+1
    jmp @rst
@rst_done:
    jmp @bad                    ; text restored — report the error

@success:
    lda DST_PTR
    sta MOD_NEW_END_LO
    lda DST_PTR+1
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
    ; ---- Fast paths (the bulk of the old cost was here) ----
    ; The old loop walked the whole ~600-byte table with a 16-bit INC and
    ; a PHA/PLA flag dance per BYTE, for every source character — saving
    ; a large file took minutes.  Three fixes, ~10x combined:
    ;   1. single-char operators dispatch through an 8-entry table,
    ;   2. characters that can't start a keyword skip the scan entirely,
    ;   3. entries reject on their first char, and the walk is Y-indexed
    ;      from a pointer that only advances once per entry.
    ldy #0
    lda (SRC_PTR),y
    sta KW_XSAVE                ; cache first source char for entry rejects
    ldx #7
@op_chk:
    cmp kw_op_chars,x
    beq @op_hit
    dex
    bpl @op_chk
    ; Only A-Z can start a multi-char keyword — digits, space, and
    ; punctuation can never match, so don't scan at all.
    cmp #'A'
    bcc @kw_no_match
    cmp #'Z'+1
    bcs @kw_no_match

    lda #<kwtab
    sta TMP16
    lda #>kwtab
    sta TMP16+1

@kw_entry:
    ldy #0
    lda (TMP16),y               ; token byte, $FF = sentinel
    cmp #$FF
    beq @kw_no_match
    sta KW_TOKEN
    ; First-char reject: most entries fail here for 13 cycles instead of
    ; a byte-by-byte walk.
    ldy #1
    lda (TMP16),y
    and #$7F
    cmp KW_XSAVE
    bne @kw_skip_entry

    ; Full compare.  Y indexes the keyword inside the entry (1..len);
    ; the matching source index is always Y-1.
@kw_match:
    dey
    lda (SRC_PTR),y             ; source char at (kw index - 1)
    iny
    eor (TMP16),y               ; $00 = match; $80 = match on final char
    asl                         ; C = final-char flag, A = difference << 1
    bne @kw_skip_from_y         ; real difference → try next entry
    bcs @kw_full_match          ; matched the entry's final char
    iny
    bne @kw_match               ; always taken (Y stays tiny)

@kw_skip_entry:
    ldy #1
@kw_skip_from_y:
    ; Find the entry's final char (bit7 set); next entry starts at Y+1.
    lda (TMP16),y
    bmi @kw_advance_entry
    iny
    bne @kw_skip_from_y         ; always taken
@kw_advance_entry:
    iny                         ; Y = offset of the next entry's token byte
    tya
    clc
    adc TMP16
    sta TMP16
    bcc @kw_entry
    inc TMP16+1
    jmp @kw_entry

@kw_full_match:
    ; Keyword chars occupy offsets 1..Y, so Y = keyword length.
    tya
    tax
@kw_advance:
    jsr inc_src_ptr
    dex
    bne @kw_advance
    lda KW_TOKEN
    sec
    rts

@op_hit:
    lda kw_op_tokens,x
    sta KW_TOKEN
    jsr inc_src_ptr             ; consume the operator char
    lda KW_TOKEN
    sec
    rts

@kw_no_match:
    clc
    rts

; Single-char operator dispatch — chars and their BASIC tokens (same
; encodings as the kwtab's 1-char entries, which are now unreachable and
; kept only as documentation).
kw_op_chars:  .byte $2A,$2B,$2D,$2F,$3C,$3D,$3E,$5E   ; * + - / < = > ^
kw_op_tokens: .byte $AC,$AA,$AB,$AD,$B3,$B2,$B1,$AE

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
; ============================================================================

emit_byte:
    ; Output must stay strictly BELOW the relocated source text.  On
    ; violation the byte is dropped, OVFLAG is set, and @all_done restores
    ; the original text from the (never overwritten) relocated copy.
    ldy DST_PTR+1
    cpy reloc_hi
    bcc @ok
    bne @overflow
    ldy DST_PTR
    cpy reloc_lo
    bcs @overflow
@ok:
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

; after_data — $FF while inside a DATA statement (module RAM; ZP is full)
after_data:
    .byte 0

; reloc — start of the relocated source text at the top of work_buf
; (= MOD_BUF_END - text length); the output's hard ceiling.
reloc_lo:
    .byte 0
reloc_hi:
    .byte 0

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
