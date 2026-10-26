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
; ZP dual-use (no overlap — LINENO only used before try_keyword is called).
; Addresses come from zp.inc:
;   ZP_SCRATCH+0/+1 = LINENO lo/hi  (digit parse phase)
;                   = KW_TOKEN / KW_XSAVE  (try_keyword phase)
;   ZP_SCRATCH+2/+3 = TMP16 lo/hi   (multiply scratch / kwtab pointer)
;   ZP_SCRATCH+4    = IN_STRING      ($FF = inside string, $00 = not)
;   ZP_SCRATCH+5    = AFTER_REM      ($FF = past REM, $00 = not)
;   ZP_PTR0         = LINK_PTR       (back-patch pointer for link words)
;   ZP_PTR1         = BASIC_ADDR     (running $0801-based C64 address)
;   ZP_PTR2         = SRC_PTR        (input pointer)
;   ZP_PTR3         = DST_PTR        (staging output pointer)
;   ZP_OVFLAG       = OVFLAG         ($FF = staging overflowed, output truncated)
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

; ---- ZP scratch — addresses come from zp.inc (see docs/c128-port-notes.md) --
.include "zp.inc"
.include "kwtab.inc"

LINENO          = ZP_SCRATCH+0  ; line number lo (hi at +1); also KW_TOKEN
KW_TOKEN        = ZP_SCRATCH+0  ; token byte (try_keyword) — same ZP, different phase
KW_XSAVE        = ZP_SCRATCH+1  ; saved source index (try_keyword)
TMP16           = ZP_SCRATCH+2  ; 16-bit scratch lo (hi at +3)
IN_STRING       = ZP_SCRATCH+4
AFTER_REM       = ZP_SCRATCH+5
LINK_PTR        = ZP_PTR0       ; lo (hi at +1)
BASIC_ADDR      = ZP_PTR1       ; lo (hi at +1)
SRC_PTR         = ZP_PTR2       ; lo (hi at +1)
DST_PTR         = ZP_PTR3       ; lo (hi at +1)
OVFLAG          = ZP_OVFLAG     ; staging overflow flag ($FF = overflowed)

BASIC_START     = $0801
; STREAMING MODEL (no staging buffer): the source text is first relocated
; to the TOP of work_buf with a descending copy, then tokenized forward
; with output written from MOD_BUF up.  Output must stay strictly below
; the relocated input (reloc_lo/hi); on violation the original text is
; restored exactly from the untouched relocated copy and the module
; errors out.  This replaces the old 3 KB module-RAM staging buffer and
; its copy-back — capacity is now "text + tokenized output <= 24 KB"
; (roughly a 13 KB source) instead of ~2.9 KB of output.

; PRG load address comes from the linker config (MAIN start) and must
; agree with layout.inc, which the module loader in modules.asm uses.
.import __MAIN_START__
.include "layout.inc"
.assert __MAIN_START__ = MOD_LO_BASE, lderror, "modtok: linker config load address disagrees with layout.inc MOD_LO_BASE"
.segment "LOADADDR"
    .word __MAIN_START__

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
    ; from the last byte down.  Page-wise with Y as the index: the
    ; pointers sit len_hi pages above each block's start, the partial top
    ; page (len_lo bytes) goes first, then each whole page below it, every
    ; page from offset $FF down to $00.  ~19 cycles a byte on the C64
    ; instead of ~50 for the 16-bit pointer/counter decrements.
    lda MOD_BUF_LO
    sta SRC_PTR
    lda MOD_BUF_HI
    clc
    adc TMP16+1
    sta SRC_PTR+1
    lda reloc_lo
    sta DST_PTR
    lda reloc_hi
    clc
    adc TMP16+1
    sta DST_PTR+1
    ldx TMP16+1                 ; whole pages below the partial one
    ldy TMP16                   ; bytes in the partial top page
    beq @reloc_page
@reloc_byte:
    dey
    buf_lda SRC_PTR
    buf_sta DST_PTR
    tya
    bne @reloc_byte
@reloc_page:
    txa
    beq @reloc_done
    dex
    dec SRC_PTR+1
    dec DST_PTR+1
    jmp @reloc_byte             ; Y = 0: the whole page, $FF down to $00
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
    buf_lda SRC_PTR
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
    buf_lda SRC_PTR
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
    buf_lda SRC_PTR
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
    lda #$FF
    sta at_stmt                 ; a line starts with a statement

; ============================================================================
; @token_loop
; ============================================================================

@token_loop:
    ldy #0
    buf_lda SRC_PTR
    bne :+
    jmp @eof_line               ; source ended mid-line — close the line first
:   cmp #$0D
    bne :+                      ; @end_line is out of branch range
    jmp @end_line
:

    lda AFTER_REM
    beq :+
    jmp @literal
:
    ldy #0
    buf_lda SRC_PTR
    cmp #$22
    bne @no_quote
    lda IN_STRING
    eor #$FF
    sta IN_STRING
    lda #0
    sta at_stmt
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
    buf_lda SRC_PTR
    cmp #':'
    bne @literal                ; still inside the DATA item list
    lda #0
    sta after_data              ; ':' ends the statement...
    jmp @literal                ; ...and is itself emitted literally
@not_data:

    ; '?' is BASIC shorthand for PRINT — CRUNCH tokenizes it to $99.
    ; Left literal it would be a runtime SYNTAX ERROR.
    ldy #0
    buf_lda SRC_PTR
    cmp #'?'
    bne @not_qmark
    jsr inc_src_ptr
    lda #0
    sta at_stmt
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
:   ldx #0                      ; a statement follows THEN, nothing else
    cmp #$A7
    bne :+
    dex
:   stx at_stmt
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@literal:
    ldy #0
    buf_lda SRC_PTR
    ldx at_stmt
    cmp #' '
    beq @lit_emit               ; spaces don't change it
    ldx #0
    cmp #':'
    bne @lit_emit
    bit IN_STRING
    bmi @lit_emit               ; a ':' inside a string
    dex                         ; X = $FF: a statement starts after ':'
@lit_emit:
    stx at_stmt
    jsr inc_src_ptr
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@end_line:
    jsr inc_src_ptr             ; advance past CR first (moddet lesson)
    lda #0
    jsr emit_byte               ; null terminator
    jsr inc_basic_addr

    jsr patch_link
    jmp @line_loop

@eof_line:
    ; Source ended without a trailing CR: close the line properly — emit
    ; the $00 terminator and back-patch the link word — before finishing.
    ; Otherwise the line's link stays at its $0000 placeholder, which is
    ; BASIC's end-of-program marker, and the whole line silently vanishes.
    lda #0
    jsr emit_byte
    jsr inc_basic_addr
    jsr patch_link
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
    ; Moving DOWN in memory, so the forward copy is overlap-safe.  Page-
    ; wise with Y as the index: whole pages first, then the partial top
    ; page, each from offset $00 up — strictly ascending throughout.
    lda MOD_BUF_END_LO
    sec
    sbc reloc_lo
    sta TMP16                   ; bytes in the partial top page
    lda MOD_BUF_END_HI
    sbc reloc_hi
    tax                         ; whole pages
    lda reloc_lo
    sta LINK_PTR
    lda reloc_hi
    sta LINK_PTR+1
    lda MOD_BUF_LO
    sta BASIC_ADDR
    lda MOD_BUF_HI
    sta BASIC_ADDR+1
    ldy #0
    txa
    beq @rst_tail
@rst_page:
    buf_lda LINK_PTR
    buf_sta BASIC_ADDR
    iny
    bne @rst_page
    inc LINK_PTR+1
    inc BASIC_ADDR+1
    dex
    bne @rst_page
@rst_tail:
    cpy TMP16
    beq @rst_done
    buf_lda LINK_PTR
    buf_sta BASIC_ADDR
    iny
    bne @rst_tail               ; always taken (Y < TMP16 <= $FF)
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
; Table: [token][chars, last|$80] ... $FF sentinel (kwtab.inc), searched
; through its first-letter index.
;
; Register protocol:
;   TMP16 (ZP_SCRATCH+2/+3): address of the entry being compared.
;   KW_TOKEN (ZP_SCRATCH+0): token byte of that entry.
;   X: position in kw_idx_lo/hi.  Y: index into the entry (source index Y-1).
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
    ; Since then: a first-letter index replaces the first-char rejects.
    ldy #0
    buf_lda SRC_PTR
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

    ; ---- First-letter index (kwtab.inc) ----
    ; Walking the whole table rejected ~85 entries on their first char
    ; for every letter in the source.  The index lists, in table order,
    ; just the entries that start with this letter; every entry in
    ; between would have failed the first-char reject, so trying only
    ; these is the same longest-first search.
    tax
    lda kw_first-'A',x
    tax
@kw_cand:
    lda kw_idx_hi,x
    beq @kw_no_match            ; end of this letter's list
    sta TMP16+1
    lda kw_idx_lo,x
    sta TMP16
    ldy #0
    lda (TMP16),y
    sta KW_TOKEN
    ; The first char is known equal (and never an entry's final char —
    ; kwtab.inc asserts it), so the compare starts at the second.
    ldy #2
@kw_cmp:
    dey
    buf_lda SRC_PTR             ; source char at (kw index - 1)
    iny
    eor (TMP16),y               ; $00 = match; $80 = match on final char
    asl                         ; C = final-char flag, A = difference << 1
    bne @kw_cand_next           ; real difference → next candidate
    bcs @kw_hit                 ; matched the entry's final char
    ; Exact match. If that was the entry's final char (bit 7 set), the
    ; source has a SHIFTED letter equal to it — "T<shift-O>" against TO.
    ; That is not this keyword (a shifted letter only ends an abbreviation
    ; before the final char), so try the next candidate. The old code
    ; compared on into the following table bytes instead, off entry
    ; boundaries, and could run past the $FF sentinel into whatever
    ; memory followed the module — on a common abbreviation habit.
    lda (TMP16),y
    bmi @kw_cand_next
    iny
    bne @kw_cmp                 ; always taken (Y stays tiny)
@kw_cand_next:
    inx
    bne @kw_cand                ; always taken (X < 256)
@kw_no_match:
    clc
    rts

@kw_hit:
    ; PETProject's own keywords ($CC-$D8) are statements the script runner
    ; dispatches only at the start of a statement. Anywhere else, or as an
    ; assignment target, the same letters are an ordinary variable name, as
    ; on a stock C64: PRINT STATUS, DRIVE=8 and A=COPY+1 must not become
    ; tokens a C64 can't run. (DRIVE 9 or RUNPROG "X" still tokenize.)
    lda KW_TOKEN
    cmp #$CC
    bcc @kw_full_match          ; a BASIC 2.0 keyword: always
    lda at_stmt
    beq @kw_cand_next
    sty kw_len
@kw_peek:                       ; next non-space source char after it
    buf_lda SRC_PTR
    iny
    cmp #' '
    beq @kw_peek
    ldy kw_len
    cmp #'='
    beq @kw_cand_next
    bne @kw_full_match          ; always

@op_hit:
    lda kw_op_tokens,x
    sta KW_TOKEN
    jsr inc_src_ptr             ; consume the operator char
    lda KW_TOKEN
    sec
    rts

@kw_full_match:
    ; Keyword chars occupy offsets 1..Y, so Y = keyword length (1..255,
    ; never 0): advance SRC_PTR past them in one add.
    tya
    clc
    adc SRC_PTR
    sta SRC_PTR
    bcc :+
    inc SRC_PTR+1
:   lda KW_TOKEN
    sec
    rts

; Single-char operator dispatch — chars and their BASIC tokens (same
; encodings as the kwtab's 1-char entries, which are never matched as
; entries).
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
    buf_sta DST_PTR
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:   rts
@overflow:
    ldy #$FF
    sty OVFLAG
    rts

; ============================================================================
; patch_link — back-patch the current line's link word with BASIC_ADDR.
; Skipped once the output has overflowed: emit_byte then freezes DST_PTR at
; reloc, so LINK_PTR points INTO the relocated source text, and the patch
; would corrupt the copy @all_done restores the user's text from.
; ============================================================================

patch_link:
    lda OVFLAG
    bne @skip
    ldy #0
    lda BASIC_ADDR
    buf_sta LINK_PTR
    iny
    lda BASIC_ADDR+1
    buf_sta LINK_PTR
@skip:
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

; at_stmt — $FF where a statement may start (line start, after an unquoted
; ':' or THEN, spaces aside); kw_len — try_keyword scratch
at_stmt:
    .byte 0
kw_len:
    .byte 0

; reloc — start of the relocated source text at the top of work_buf
; (= MOD_BUF_END - text length); the output's hard ceiling.
reloc_lo:
    .byte 0
reloc_hi:
    .byte 0

; ============================================================================
; Keyword table and its first-letter index (kwtab.inc).
;
; ============================================================================

    kw_index
    kw_table
