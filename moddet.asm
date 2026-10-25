; ============================================================================
; moddet.asm — Detokenizer module for PETProject
;
; Loaded at $C000 by the editor's module loader.
; Expands tokenized C64 BASIC 2.0 in the editor buffer to plain text.
;
; Entry: JSR $C000 (first 3 bytes are JMP detokenize)
; Parameter block at $0212 (see modules.asm for layout).
;
; Algorithm:
;   Walk tokenized BASIC lines. For each line:
;     - Skip the 2-byte link word (next-line RAM pointer, meaningless here).
;     - Read the 2-byte line number and emit it as decimal digits + space.
;     - Walk token bytes until $00:
;         * Byte < $80  → emit as-is (printable char or punctuation).
;         * Byte $80-$CB → look up keyword in ROM table at $A09E and emit.
;         * Byte > $CB   → emit as-is (shouldn't appear in BASIC 2.0).
;     - Emit $0D (CR) after each line.
;   When done, report MOD_STATUS=$02 (output was streamed in place).
;
; Keyword table (embedded copy in the BASIC ROM's $A09E format):
;   Contiguous keyword strings, last char of each has bit 7 set.
;   Token $80 = index 0 (END), $81 = index 1 (FOR), ..., $D8 (DIR).
;   kw_off locates a token's entry directly; its chars are copied with
;   bit 7 cleared up to and including the one with bit 7 set.
;
; Zero page used (free during our execution; addresses come from zp.inc):
;   ZP_PTR2      — SRC_PTR:  walks tokenized source
;   ZP_PTR3      — DST_PTR:  output write pointer (streams into MOD_BUF)
;   ZP_PTR0      — COPY_SRC: copy-back loop source pointer
;   ZP_PTR1      — COPY_DST: copy-back loop dest pointer
;   ZP_SCRATCH+0 — LINENO:   16-bit line number value (modified by decimal output)
;   ZP_SCRATCH+2 — NZFLAG:   non-zero digit seen flag (decimal output)
;   ZP_SCRATCH+3 — KWTAB:    keyword table walker pointer
;   ZP_SCRATCH+5 — OVFLAG:   output-overflow flag
;
; Streaming: input relocated to the top of work_buf, output written in
; place from MOD_BUF up (see the STREAMING MODEL note below).  A listing
; larger than the buffer aborts with MOD_STATUS=$01 — see emit_byte.
; ============================================================================

.setcpu "6502"

; ---- Parameter block (modules.asm layout) ----------------------------------
MOD_MAGIC        = $0212
MOD_COMMAND      = $0213
MOD_BUF_LO       = $0214
MOD_BUF_HI       = $0215
MOD_GAP_START_LO = $0216
MOD_GAP_START_HI = $0217
MOD_GAP_END_LO   = $0218
MOD_GAP_END_HI   = $0219
MOD_BUF_END_LO   = $021A
MOD_BUF_END_HI   = $021B
MOD_DRIVE        = $021C
MOD_DIALECT      = $021D
MOD_STATUS       = $021E
MOD_NEW_END_LO   = $021F
MOD_NEW_END_HI   = $0220

MOD_MAGIC_VAL    = $4D

; ---- Zero page -------------------------------------------------------------
; Addresses come from zp.inc (see docs/c128-port-notes.md).
.include "zp.inc"

SRC_PTR          = ZP_PTR2          ; source walk pointer (lo/hi)
DST_PTR          = ZP_PTR3          ; output write pointer (lo/hi)
COPY_SRC         = ZP_PTR0          ; copy-back source (lo/hi)
COPY_DST         = ZP_PTR1          ; copy-back dest  (lo/hi)
LINENO           = ZP_SCRATCH+0     ; 16-bit line number scratch (lo/hi)
NZFLAG           = ZP_SCRATCH+2     ; non-zero digit seen (decimal output)
KWTAB            = ZP_SCRATCH+3     ; keyword table walker (lo/hi)
OVFLAG           = ZP_SCRATCH+5     ; output-overflow flag ($FF = won't fit)



; STREAMING MODEL (no staging buffer): the tokenized input is relocated to
; the TOP of work_buf with a descending copy, then detokenized forward
; with output written from MOD_BUF up.  emit_byte keeps the output
; strictly below SRC_PTR, so a collision can only mean the listing
; doesn't fit the 24 KB buffer at all — reported as MOD_STATUS=$01.
; This replaces the old 3.25 KB module-RAM staging buffer (which capped
; loadable BASIC programs at ~3 KB) and its copy-back pass.

; ============================================================================

; PRG load address comes from the linker config (MAIN start) and must
; agree with layout.inc, which the module loader in modules.asm uses.
.import __MAIN_START__
.include "layout.inc"
.assert __MAIN_START__ = MOD_LO_BASE, lderror, "moddet: linker config load address disagrees with layout.inc MOD_LO_BASE"
.segment "LOADADDR"
    .word __MAIN_START__

.segment "CODE"

    jmp detokenize

; ============================================================================
; detokenize — main entry point
; ============================================================================

detokenize:
    ; Validate magic byte
    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq @magic_ok
    jmp @bad
@magic_ok:

    ; ---- Relocate the tokenized input to the top of the buffer ----
    ; len = MOD_GAP_START - MOD_BUF (the loader set GAP_START to one past
    ; the loaded data); reloc = MOD_BUF_END - len.  Detokenized output is
    ; then written forward from MOD_BUF, kept strictly below SRC_PTR by
    ; emit_byte — output can only collide with input if the result
    ; genuinely doesn't fit the 24 KB buffer.
    lda MOD_GAP_START_LO
    sec
    sbc MOD_BUF_LO
    sta LINENO                  ; len lo (LINENO free until line parsing)
    lda MOD_GAP_START_HI
    sbc MOD_BUF_HI
    sta LINENO+1                ; len hi
    lda MOD_BUF_END_LO
    sec
    sbc LINENO
    sta det_reloc_lo
    lda MOD_BUF_END_HI
    sbc LINENO+1
    sta det_reloc_hi

    ; Descending copy [MOD_BUF..MOD_BUF+len) -> [reloc..MOD_BUF_END);
    ; regions overlap whenever len > free space, so copy last byte first.
    lda MOD_GAP_START_LO
    sta COPY_SRC
    lda MOD_GAP_START_HI
    sta COPY_SRC+1
    lda MOD_BUF_END_LO
    sta COPY_DST
    lda MOD_BUF_END_HI
    sta COPY_DST+1
@reloc_loop:
    lda LINENO
    ora LINENO+1
    beq @reloc_done
    lda COPY_SRC
    bne :+
    dec COPY_SRC+1
:   dec COPY_SRC
    lda COPY_DST
    bne :+
    dec COPY_DST+1
:   dec COPY_DST
    ldy #0
    buf_lda COPY_SRC
    buf_sta COPY_DST
    lda LINENO
    bne :+
    dec LINENO+1
:   dec LINENO
    jmp @reloc_loop
@reloc_done:

    ; SRC_PTR = relocated input
    lda det_reloc_lo
    sta SRC_PTR
    lda det_reloc_hi
    sta SRC_PTR+1

    ; PRG header detection: if buf[0..1] (as 16-bit LE) < MOD_BUF address,
    ; the buffer starts with a PRG load-address header ($01 $08 etc.) — skip it.
    ; Comparison: header_hi < MOD_BUF_HI  → header
    ;             header_hi = MOD_BUF_HI AND header_lo < MOD_BUF_LO → header
    ;             otherwise → raw BASIC, no skip needed.
    ldy #1
    buf_lda SRC_PTR             ; buf[1] = candidate header hi byte
    cmp MOD_BUF_HI
    bcc @skip_header            ; header_hi < MOD_BUF_HI -> definitely a header
    bne @no_header              ; header_hi > MOD_BUF_HI -> not a header
    ; header_hi == MOD_BUF_HI: check lo byte
    ldy #0
    buf_lda SRC_PTR             ; buf[0] = candidate header lo byte
    cmp MOD_BUF_LO
    bcs @no_header              ; header_lo >= MOD_BUF_LO -> raw BASIC
@skip_header:
    jsr inc_src_ptr
    jsr inc_src_ptr
@no_header:

    ; Output streams in place, from the bottom of the caller's buffer.
    lda MOD_BUF_LO
    sta DST_PTR
    lda MOD_BUF_HI
    sta DST_PTR+1
    lda #0
    sta OVFLAG

; ============================================================================
; @line_loop — walk one BASIC line per iteration
; ============================================================================

@line_loop:
    ; Bounds check — the relocated input ends exactly at MOD_BUF_END
    lda SRC_PTR
    cmp MOD_BUF_END_LO
    lda SRC_PTR+1
    sbc MOD_BUF_END_HI
    bcs @to_all_done

    ; Check for end-of-program sentinel ($0000 link word)
    ldy #0
    buf_lda SRC_PTR
    bne @has_line
    iny
    buf_lda SRC_PTR
    bne @has_line
@to_all_done:
    jmp @all_done           ; both bytes zero = sentinel

@has_line:
    ; Skip link word
    jsr inc_src_ptr
    jsr inc_src_ptr

    ; Read line number
    ldy #0
    buf_lda SRC_PTR
    sta LINENO
    iny
    buf_lda SRC_PTR
    sta LINENO+1

    ; Skip past line number bytes
    jsr inc_src_ptr
    jsr inc_src_ptr

    ; Emit line number as decimal digits
    jsr emit_lineno

    ; Emit a space after the line number
    lda #$20
    jsr emit_byte

    ; Quote mode resets at the start of every line (same as ROM LIST), and
    ; so do the REM and DATA literal modes.
    lda #0
    sta in_string
    sta after_rem
    sta after_data

; ============================================================================
; @token_loop — process token bytes until line terminator ($00)
; ============================================================================

@token_loop:
    ldy #0
    buf_lda SRC_PTR             ; read next byte
    beq @end_line               ; $00 = end of this line
    jsr inc_src_ptr             ; advance past the byte we just read

    ; After REM every byte to the end of the line is literal text: MODTOK
    ; stores it untokenized, so expanding $80-$D8 here would turn graphics
    ; and shifted letters into keywords — on every save, permanently.
    ldx after_rem
    bne @literal

    ; Quote tracking (same rule as ROM LIST): '"' toggles string mode, and
    ; inside a string EVERY byte is literal.  String contents are stored as
    ; raw PETSCII, and shifted letters/graphics are >= $80 — without this,
    ; PRINT"<shift-A>" detokenized as PRINT"ATN"... and corrupted the text.
    cmp #$22
    bne @not_quote
    pha
    lda in_string
    eor #$FF
    sta in_string
    pla
    jmp @literal                ; the quote char itself is literal
@not_quote:
    ldx in_string
    bne @literal                ; inside a string: emit untouched

    ; DATA items are literal up to an unquoted ':' (MODTOK's rule, and the
    ; ROM's CRUNCH).
    ldx after_data
    beq @not_data
    cmp #':'
    bne @literal
    ldx #0
    stx after_data              ; ':' ends the statement and is literal
    beq @literal
@not_data:

    ; Token or literal char?
    cmp #$80
    bcc @literal                ; < $80 → emit as-is

    ; Token $80-$D8: look up keyword in embedded table (standard $80-$CB
    ; plus PETProject extended keywords $CC-$D8). The kwtab below already
    ; carries the extended entries, so emit_keyword handles the full range.
    cmp #$D9
    bcs @literal                ; >= $D9 → genuinely out of range, emit as-is
    ldx #$FF
    cmp #$8F                    ; REM — rest of the line is literal
    bne :+
    stx after_rem
:   cmp #$83                    ; DATA — rest of the statement is literal
    bne :+
    stx after_data
:   jsr emit_keyword            ; A = token byte on entry
    jmp @token_loop

@literal:
    jsr emit_byte               ; A = char to emit
    jmp @token_loop

@end_line:
    ; SRC_PTR still points at the $00 line terminator we just read via BEQ.
    ; Advance past it before returning to @line_loop, otherwise the zero-check
    ; there reads this $00 as the first byte of the next line's link word,
    ; misses the BNE, then reads link_lo as link_hi — shifting the entire parse.
    jsr inc_src_ptr
    ; Emit CR at end of line
    lda #$0D
    jsr emit_byte
    jmp @line_loop

; ============================================================================
; @all_done — finish up (output already in place)
; ============================================================================

@all_done:
    ; Output streamed in place — nothing to copy on success.  On overflow
    ; (the listing wouldn't fit the 24 KB buffer) the buffer holds a
    ; truncated listing; nothing is lost — the input was a just-loaded
    ; file that is still on disk — and the caller reports the error.
    lda OVFLAG
    beq @no_overflow
    jmp @bad
@no_overflow:
    lda DST_PTR
    sta MOD_NEW_END_LO
    lda DST_PTR+1
    sta MOD_NEW_END_HI
    lda #$02                    ; MOD_STATUS: buffer replaced
    sta MOD_STATUS
    rts

@bad:
    lda #$01                    ; MOD_STATUS: error
    sta MOD_STATUS
    rts

; ============================================================================
; emit_lineno — write LINENO (16-bit) as decimal digits to the output.
;
; Uses subtract-and-count with powers of 10.
; Suppresses leading zeros (always emits the units digit).
; Clobbers: A, X, Y, NZFLAG, KWTAB (used as temp in subtraction loop)
; ============================================================================

emit_lineno:
    lda #0
    sta NZFLAG                  ; leading-zero suppression flag

    ldx #4                      ; 5 powers: index 4..0 (10000, 1000, 100, 10, 1)
@pow_loop:
    lda #0
    sta KWTAB                   ; digit counter (reuse KWTAB lo byte as scratch)

@sub_loop:
    ; Subtract pow10_lo[x]/pow10_hi[x] from LINENO, check borrow
    sec
    lda LINENO
    sbc pow10_lo,x
    tay                         ; save lo result
    lda LINENO+1
    sbc pow10_hi,x
    bcc @sub_done               ; borrow → went negative, digit complete

    ; Subtraction succeeded: commit and count
    sty LINENO
    sta LINENO+1
    inc KWTAB                   ; digit++
    jmp @sub_loop

@sub_done:
    ; Emit digit if non-zero OR if we've seen a non-zero already OR last digit
    lda KWTAB                   ; digit value
    bne @emit_digit
    lda NZFLAG
    bne @emit_zero
    cpx #0                      ; always emit units digit (x=0)
    bne @skip_digit
@emit_zero:
    lda #0                      ; digit is 0 but we must emit
    jmp @do_emit
@emit_digit:
    lda KWTAB
    sta NZFLAG                  ; mark non-zero seen
@do_emit:
    clc
    adc #$30                    ; ASCII '0'
    jsr emit_byte
@skip_digit:
    dex
    bpl @pow_loop
    rts

; Powers of 10 table (16-bit, lo/hi pairs), index 0=1, 1=10, ..., 4=10000
pow10_lo:   .byte <1, <10, <100, <1000, <10000
pow10_hi:   .byte >1, >10, >100, >1000, >10000

; ============================================================================
; emit_keyword — look up and emit the keyword for token byte in A
; ($80-$D8; the caller checks the range).
;
; The keyword table has the BASIC ROM's format (last char of each keyword
; has bit 7 set); kw_off gives each token's entry directly, so the lookup
; no longer walks (token - $80) entries byte by byte. Each char is emitted
; with bit 7 cleared, up to and including the final one.
; Clobbers: A, X, Y, KWTAB
; ============================================================================

emit_keyword:
    ; Own embedded table: no ROM banking required — immune to whatever
    ; $00/$01 state the editor sets.
    tax                             ; X = token
    ldy #>kwtab
    cpx #KW_SECOND_HALF             ; from here on: offsets from kwtab+256
    bcc :+
    iny
:   lda kw_off-$80,x
    clc
    adc #<kwtab
    sta KWTAB
    bcc :+
    iny
:   sty KWTAB+1
@emit_chars:
    ldy #0
    lda (KWTAB),y
    bmi @last                       ; bit 7 set → the keyword's final char
    jsr emit_byte                   ; (clobbers Y, hence the pointer bump)
    inc KWTAB
    bne @emit_chars
    inc KWTAB+1
    bne @emit_chars                 ; always taken
@last:
    and #$7F                        ; strip the end marker for output
    jmp emit_byte

; One keyword-table entry: the string with its last char OR'd with $80,
; at label kwt_<token - $80>.
KW_TOK .set $80
.macro dkw str
    .ident(.sprintf("kwt_%d", KW_TOK - $80)) := *
    .repeat .strlen(str) - 1, KWI
        .byte .strat(str, KWI)
    .endrepeat
    .byte .strat(str, .strlen(str) - 1) | $80
    KW_TOK .set KW_TOK + 1
.endmacro

; ============================================================================
; kwtab — embedded BASIC 2.0 keyword table, plus PETProject's extended
; keywords $CC-$D8. Each keyword string ends with its last character
; OR'd with $80; one entry per token, in token order from $80.
; ============================================================================
kwtab:
    dkw "END"       ; $80
    dkw "FOR"       ; $81
    dkw "NEXT"      ; $82
    dkw "DATA"      ; $83
    dkw "INPUT#"    ; $84
    dkw "INPUT"     ; $85
    dkw "DIM"       ; $86
    dkw "READ"      ; $87
    dkw "LET"       ; $88
    dkw "GOTO"      ; $89
    dkw "RUN"       ; $8A
    dkw "IF"        ; $8B
    dkw "RESTORE"   ; $8C
    dkw "GOSUB"     ; $8D
    dkw "RETURN"    ; $8E
    dkw "REM"       ; $8F
    dkw "STOP"      ; $90
    dkw "ON"        ; $91
    dkw "WAIT"      ; $92
    dkw "LOAD"      ; $93
    dkw "SAVE"      ; $94
    dkw "VERIFY"    ; $95
    dkw "DEF"       ; $96
    dkw "POKE"      ; $97
    dkw "PRINT#"    ; $98
    dkw "PRINT"     ; $99
    dkw "CONT"      ; $9A
    dkw "LIST"      ; $9B
    dkw "CLR"       ; $9C
    dkw "CMD"       ; $9D
    dkw "SYS"       ; $9E
    dkw "OPEN"      ; $9F
    dkw "CLOSE"     ; $A0
    dkw "GET"       ; $A1
    dkw "NEW"       ; $A2
    dkw "TAB("      ; $A3
    dkw "TO"        ; $A4
    dkw "FN"        ; $A5
    dkw "SPC("      ; $A6
    dkw "THEN"      ; $A7
    dkw "NOT"       ; $A8
    dkw "STEP"      ; $A9
    dkw "+"         ; $AA
    dkw "-"         ; $AB
    dkw "*"         ; $AC
    dkw "/"         ; $AD
    dkw "^"         ; $AE
    dkw "AND"       ; $AF
    dkw "OR"        ; $B0
    dkw ">"         ; $B1
    dkw "="         ; $B2
    dkw "<"         ; $B3
    dkw "SGN"       ; $B4
    dkw "INT"       ; $B5
    dkw "ABS"       ; $B6
    dkw "USR"       ; $B7
    dkw "FRE"       ; $B8
    dkw "POS"       ; $B9
    dkw "SQR"       ; $BA
    dkw "RND"       ; $BB
    dkw "LOG"       ; $BC
    dkw "EXP"       ; $BD
    dkw "COS"       ; $BE
    dkw "SIN"       ; $BF
    dkw "TAN"       ; $C0
    dkw "ATN"       ; $C1
    dkw "PEEK"      ; $C2
    dkw "LEN"       ; $C3
    dkw "STR$"      ; $C4
    dkw "VAL"       ; $C5
    dkw "ASC"       ; $C6
    dkw "CHR$"      ; $C7
    dkw "LEFT$"     ; $C8
    dkw "RIGHT$"    ; $C9
    dkw "MID$"      ; $CA
    dkw "GO"        ; $CB
    dkw "ASSEMBLE"  ; $CC
    dkw "INCLUDE"   ; $CD
    dkw "RUNPROG"   ; $CE
    dkw "SCRATCH"   ; $CF
    dkw "DELETE"    ; $D0
    dkw "EXISTS"    ; $D1
    dkw "RENAME"    ; $D2
    dkw "STATUS"    ; $D3
    dkw "DRIVE"     ; $D4
    dkw "ONERR"     ; $D5
    dkw "PAUSE"     ; $D6
    dkw "COPY"      ; $D7
    dkw "DIR"       ; $D8
KW_END_TOKEN = KW_TOK               ; one past the last token ($D9)

; kw_off — each token's entry, as an offset from kwtab (tokens below
; KW_SECOND_HALF) or from kwtab+256 (KW_SECOND_HALF and up): one byte per token, the
; table being longer than a page.
KW_SPLIT .set KW_END_TOKEN
.repeat KW_END_TOKEN - $80, KWI
    .if KW_SPLIT = KW_END_TOKEN && .ident(.sprintf("kwt_%d", KWI)) - kwtab > $FF
        KW_SPLIT .set $80 + KWI
    .endif
.endrepeat
KW_SECOND_HALF = KW_SPLIT           ; a constant: emit_keyword refers to it ahead
kw_off:
.repeat KW_END_TOKEN - $80, KWI
    .if $80 + KWI < KW_SPLIT
        .byte .ident(.sprintf("kwt_%d", KWI)) - kwtab
    .else
        .assert .ident(.sprintf("kwt_%d", KWI)) - kwtab - $100 <= $FF, error, "moddet: kwtab longer than two pages"
        .byte .ident(.sprintf("kwt_%d", KWI)) - kwtab - $100
    .endif
.endrepeat

; ============================================================================
; emit_byte — write A to (DST_PTR), advance DST_PTR.
; Bounds-checked: output must stay strictly BELOW SRC_PTR (the unread part
; of the relocated input).  Since the input is consumed as the output
; grows, a collision means the detokenized listing genuinely cannot fit
; the 24 KB buffer.  The byte is dropped and OVFLAG is set.
; Clobbers: Y
; ============================================================================

emit_byte:
    ldy DST_PTR+1
    cpy SRC_PTR+1
    bcc @ok
    bne @overflow
    ldy DST_PTR
    cpy SRC_PTR
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
; inc_src_ptr — advance SRC_PTR by 1.
; Clobbers: nothing (saves/restores A via stack? No - callers handle it.)
; Actually: clobbers nothing besides carry (uses inc, not adc).
; ============================================================================

inc_src_ptr:
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   rts

; in_string — $FF while inside a "" string literal (module RAM; ZP is full)
in_string:
    .byte 0
; after_rem / after_data — $FF while in a REM line / DATA statement
after_rem:
    .byte 0
after_data:
    .byte 0

; det_reloc — start of the relocated tokenized input at the top of
; work_buf (= MOD_BUF_END - input length)
det_reloc_lo:
    .byte 0
det_reloc_hi:
    .byte 0
