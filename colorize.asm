; ============================================================================
; colorize.asm — Syntax colorizer for PETProject v0.1
;
; Drop-in .include for editor.asm. Provides colorize_row, called once per
; content row from render_viewport before the LEFT_COL skip loop.
;
; ── Design ──────────────────────────────────────────────────────────────────
;
; colorize_row walks the gap buffer from the *logical start of the line*
; (the position BUF_PTR holds before render_viewport's LEFT_COL skip).
; It tracks syntax state and writes one color byte per visible column
; directly to color RAM. BUF_PTR is saved/restored on the stack, so
; render_viewport's own walk is completely unaffected.
;
; Color RAM address = SCREEN_PTR + $D400 (always valid for $0401..$07FF).
;
; ── Syntax states (held in X register throughout the main loop) ──────────────
;
;   STATE_LINENUM  consuming leading decimal digits (the BASIC line number)
;   STATE_SPACE    space(s) between line number and first token
;   STATE_NORMAL   scanning for keywords, quotes, and literals
;   STATE_STRING   inside a double-quoted string
;   STATE_REM      past a REM — everything until CR is a comment
;
; ── Color scheme (C64 color indices) ────────────────────────────────────────
;
;   Line numbers  COL_LINENUM  cyan    (6)
;   Keywords      COL_KEYWORD  yellow  (7)
;   Strings       COL_STRING   green   (5)
;   REM comments  COL_REM      gray3  (15)
;   Everything else            SETTING_FG (user's text color)
;
;   Plain text files (IS_BASIC = 0): uniform SETTING_FG, cheap early-out.
;
; ── ZP requirements (add ONLY these 5 bytes to .zeropage in editor.asm) ──────
;
;   CLR_PTR:   .res 2   color RAM row pointer
;   CLR_CTMP:  .res 2   colortab walk pointer (col_try_keyword internal)
;   CLR_KWLEN: .res 1   keyword length from col_try_keyword; bit 7 = was REM
;
;   Aliases to existing ZP (no new bytes needed):
;     CLR_LCOL  →  COL_SAVE   (logical column counter; COL_SAVE not live
;                               during render_viewport, safe to alias)
;     CLR_SCOL  →  TMP        (screen column write cursor; TMP not live
;                               during colorize_row, safe to alias)
;     CLR_TMP   →  TMP+1      (scratch byte; same reasoning)
;
;   BUF_PTR save/restore: done on the hardware stack (two PHA/PLA pairs),
;   not in ZP — saves 2 bytes vs a dedicated CLR_BPTR pair.
;
;   Syntax state: held in the X register throughout the main loop.
;   col_try_keyword clobbers X internally; the caller reloads X explicitly
;   after each call (state is always known at those call sites anyway).
;
;   Total new ZP bytes: 5  (down from an earlier draft's 12)
;
; ── Integration (one line change to render_viewport) ────────────────────────
;
;   @row_loop:
;       jsr colorize_row    ; ← add ONLY this line before the skip loop
;       ; ---- 1. Skip LEFT_COL chars ----
;       lda LEFT_COL
;       ...
;
;   colorize_row owns color RAM for content rows 1..24.
;   Row 0 (status bar) remains owned by render_status — no change there.
;
;   apply_colors floods ALL of color RAM with SETTING_FG. That's fine on
;   startup/settings-change, but render_viewport calls colorize_row on every
;   keypress immediately after, so the content rows are repainted correctly
;   before the user sees them. No visible artifact.
;
; ============================================================================

; ── Aliases to existing ZP variables ────────────────────────────────────────
; These reuse bytes already declared in editor.asm — no new .res needed.

CLR_LCOL    = COL_SAVE      ; logical column (0 = first char of line)
CLR_SCOL    = TMP           ; screen columns written so far (0..COLS)
CLR_TMP     = TMP+1         ; scratch byte

; ── Color constants (adjust to taste) ───────────────────────────────────────

COL_LINENUM     = 7         ; yellow
COL_KEYWORD     = 3         ; cyan
COL_STRING      = 5         ; green
COL_REM         = 11        ; dark gray

; ── State constants (held in X register) ────────────────────────────────────

STATE_LINENUM   = 0
STATE_SPACE     = 1
STATE_NORMAL    = 2
STATE_STRING    = 3
STATE_REM       = 4

; ── Assembly colorizer state constants ──────────────────────────────────────

STATE_ASM_SOL     = 5    ; start of line
STATE_ASM_LABEL   = 6    ; consuming a label identifier
STATE_ASM_MNEM    = 7    ; consuming mnemonic or directive
STATE_ASM_OPERAND = 8    ; after mnemonic — operand territory
STATE_ASM_COMMENT = 9    ; after ';' — comment to end of line
STATE_ASM_STRING  = 10   ; inside "..." in operand

; ── Assembly color constants ─────────────────────────────────────────────────
; Deliberately reuse BASIC color values for visual consistency.

COL_ASM_LABEL     = 6    ; cyan  — labels
COL_ASM_MNEM      = 7    ; yellow — mnemonics (LDA, JSR, etc.)
COL_ASM_DIRECTIVE = 8    ; orange — .byte .word .org .text *=
COL_ASM_COMMENT   = 15   ; light gray — ; comments
COL_ASM_STRING    = 5    ; green — strings in .text/.byte

; ============================================================================
; ============================================================================
; kw_strtab — concatenated PETSCII keyword strings, in token order ($80-$CB).
; No terminators; use kw_len_tab for each entry's length.
; Used by tl_match_kw for on-commit tokenization.
; Stored as lowercase so ca65 -t c64 produces uppercase PETSCII ($41-$5A).
; ============================================================================
kw_strtab:
    .byte "end"         ; $80  3
    .byte "for"         ; $81  3
    .byte "next"        ; $82  4
    .byte "data"        ; $83  4
    .byte "input#"      ; $84  6
    .byte "input"       ; $85  5
    .byte "dim"         ; $86  3
    .byte "read"        ; $87  4
    .byte "let"         ; $88  3
    .byte "goto"        ; $89  4
    .byte "run"         ; $8A  3
    .byte "if"          ; $8B  2
    .byte "restore"     ; $8C  7
    .byte "gosub"       ; $8D  5
    .byte "return"      ; $8E  6
    .byte "rem"         ; $8F  3
    .byte "stop"        ; $90  4
    .byte "on"          ; $91  2
    .byte "wait"        ; $92  4
    .byte "load"        ; $93  4
    .byte "save"        ; $94  4
    .byte "verify"      ; $95  6
    .byte "def"         ; $96  3
    .byte "poke"        ; $97  4
    .byte "print#"      ; $98  6
    .byte "print"       ; $99  5
    .byte "cont"        ; $9A  4
    .byte "list"        ; $9B  4
    .byte "clr"         ; $9C  3
    .byte "cmd"         ; $9D  3
    .byte "sys"         ; $9E  3
    .byte "open"        ; $9F  4
    .byte "close"       ; $A0  5
    .byte "get"         ; $A1  3
    .byte "new"         ; $A2  3
    .byte "tab("        ; $A3  4
    .byte "to"          ; $A4  2
    .byte "fn"          ; $A5  2
    .byte "spc("        ; $A6  4
    .byte "then"        ; $A7  4
    .byte "not"         ; $A8  3
    .byte "step"        ; $A9  4
    .byte "+"           ; $AA  1
    .byte "-"           ; $AB  1
    .byte "*"           ; $AC  1
    .byte "/"           ; $AD  1
    .byte "^"           ; $AE  1
    .byte "and"         ; $AF  3
    .byte "or"          ; $B0  2
    .byte ">"           ; $B1  1
    .byte "="           ; $B2  1
    .byte "<"           ; $B3  1
    .byte "sgn"         ; $B4  3
    .byte "int"         ; $B5  3
    .byte "abs"         ; $B6  3
    .byte "usr"         ; $B7  3
    .byte "fre"         ; $B8  3
    .byte "pos"         ; $B9  3
    .byte "sqr"         ; $BA  3
    .byte "rnd"         ; $BB  3
    .byte "log"         ; $BC  3
    .byte "exp"         ; $BD  3
    .byte "cos"         ; $BE  3
    .byte "sin"         ; $BF  3
    .byte "tan"         ; $C0  3
    .byte "atn"         ; $C1  3
    .byte "peek"        ; $C2  4
    .byte "len"         ; $C3  3
    .byte "str$"        ; $C4  4
    .byte "val"         ; $C5  3
    .byte "asc"         ; $C6  3
    .byte "chr$"        ; $C7  4
    .byte "left$"       ; $C8  5
    .byte "right$"      ; $C9  6
    .byte "mid$"        ; $CA  4
    .byte "go"          ; $CB  2
    .byte "assemble"   ; $CC  8
    .byte "include"    ; $CD  7
    .byte "runprog"    ; $CE  7
    .byte "scratch"    ; $CF  7
    .byte "delete"     ; $D0  6
    .byte "exists"     ; $D1  6
    .byte "rename"     ; $D2  6
    .byte "status"     ; $D3  6
    .byte "drive"      ; $D4  5
    .byte "onerr"      ; $D5  5
    .byte "pause"      ; $D6  5
    .byte "copy"       ; $D7  4
    .byte "dir"        ; $D8  3

; kw_len_tab — display width (screen columns) for each C64 BASIC 2.0 keyword.
; Indexed by (token_byte - $80). 76 entries for tokens $80-$CB.
; Used by colorize_row to emit the right number of COL_KEYWORD colors when
; a pre-tokenized keyword token is encountered in the buffer.
; ============================================================================
kw_len_tab:
    .byte 3   ; $80 END
    .byte 3   ; $81 FOR
    .byte 4   ; $82 NEXT
    .byte 4   ; $83 DATA
    .byte 6   ; $84 INPUT#
    .byte 5   ; $85 INPUT
    .byte 3   ; $86 DIM
    .byte 4   ; $87 READ
    .byte 3   ; $88 LET
    .byte 4   ; $89 GOTO
    .byte 3   ; $8A RUN
    .byte 2   ; $8B IF
    .byte 7   ; $8C RESTORE
    .byte 5   ; $8D GOSUB
    .byte 6   ; $8E RETURN
    .byte 3   ; $8F REM
    .byte 4   ; $90 STOP
    .byte 2   ; $91 ON
    .byte 4   ; $92 WAIT
    .byte 4   ; $93 LOAD
    .byte 4   ; $94 SAVE
    .byte 6   ; $95 VERIFY
    .byte 3   ; $96 DEF
    .byte 4   ; $97 POKE
    .byte 6   ; $98 PRINT#
    .byte 5   ; $99 PRINT
    .byte 4   ; $9A CONT
    .byte 4   ; $9B LIST
    .byte 3   ; $9C CLR
    .byte 3   ; $9D CMD
    .byte 3   ; $9E SYS
    .byte 4   ; $9F OPEN
    .byte 5   ; $A0 CLOSE
    .byte 3   ; $A1 GET
    .byte 3   ; $A2 NEW
    .byte 4   ; $A3 TAB(
    .byte 2   ; $A4 TO
    .byte 2   ; $A5 FN
    .byte 4   ; $A6 SPC(
    .byte 4   ; $A7 THEN
    .byte 3   ; $A8 NOT
    .byte 4   ; $A9 STEP
    .byte 1   ; $AA +
    .byte 1   ; $AB -
    .byte 1   ; $AC *
    .byte 1   ; $AD /
    .byte 1   ; $AE ^
    .byte 3   ; $AF AND
    .byte 2   ; $B0 OR
    .byte 1   ; $B1 >
    .byte 1   ; $B2 =
    .byte 1   ; $B3 <
    .byte 3   ; $B4 SGN
    .byte 3   ; $B5 INT
    .byte 3   ; $B6 ABS
    .byte 3   ; $B7 USR
    .byte 3   ; $B8 FRE
    .byte 3   ; $B9 POS
    .byte 3   ; $BA SQR
    .byte 3   ; $BB RND
    .byte 3   ; $BC LOG
    .byte 3   ; $BD EXP
    .byte 3   ; $BE COS
    .byte 3   ; $BF SIN
    .byte 3   ; $C0 TAN
    .byte 3   ; $C1 ATN
    .byte 4   ; $C2 PEEK
    .byte 3   ; $C3 LEN
    .byte 4   ; $C4 STR$
    .byte 3   ; $C5 VAL
    .byte 3   ; $C6 ASC
    .byte 4   ; $C7 CHR$
    .byte 5   ; $C8 LEFT$
    .byte 6   ; $C9 RIGHT$
    .byte 4   ; $CA MID$
    .byte 2   ; $CB GO
    .byte 8   ; $CC ASSEMBLE
    .byte 7   ; $CD INCLUDE
    .byte 7   ; $CE RUNPROG
    .byte 7   ; $CF SCRATCH
    .byte 6   ; $D0 DELETE
    .byte 6   ; $D1 EXISTS
    .byte 6   ; $D2 RENAME
    .byte 6   ; $D3 STATUS
    .byte 5   ; $D4 DRIVE
    .byte 5   ; $D5 ONERR
    .byte 5   ; $D6 PAUSE
    .byte 4   ; $D7 COPY
    .byte 3   ; $D8 DIR

; ============================================================================
; colorize_row
;
; Entry:  BUF_PTR    = start of logical line in gap buffer (pre-LEFT_COL-skip)
;         SCREEN_PTR = first screen cell of this row
;         X          = caller's X (clobbered — caller must save if needed;
;                      render_viewport's X is its row counter, so the call
;                      site must do: stx <save> / jsr colorize_row / ldx <save>)
; Exit:   BUF_PTR restored; color RAM written for COLS cells of this row
;         A, X, Y clobbered
; ============================================================================

colorize_row:

    ; ------------------------------------------------------------------
    ; Branch on file type:
    ;   IS_BASIC = $FF → BASIC colorizer
    ;   IS_BASIC = $00 → assembly colorizer
    ; ------------------------------------------------------------------
    lda IS_BASIC
    bne @is_basic
    jmp colorize_row_asm    ; IS_BASIC=0 → assembly syntax highlighting

@is_basic:
    ; ------------------------------------------------------------------
    ; Compute CLR_PTR = SCREEN_PTR + $D400
    ; ------------------------------------------------------------------
    clc
    lda SCREEN_PTR
    adc #<$D400
    sta CLR_PTR
    lda SCREEN_PTR+1
    adc #>$D400
    sta CLR_PTR+1

    ; ------------------------------------------------------------------
    ; Save BUF_PTR on stack (restored at exit)
    ; ------------------------------------------------------------------
    lda BUF_PTR+1
    pha
    lda BUF_PTR
    pha

    ; ------------------------------------------------------------------
    ; Initialise state machine
    ; State in X register throughout the main loop.
    ; ------------------------------------------------------------------
    ldx #STATE_LINENUM
    lda #0
    sta CLR_LCOL
    sta CLR_SCOL

    ; ------------------------------------------------------------------
    ; Main character loop — one iteration per logical buffer character.
    ;
    ; CLR_LCOL counts all characters from the line start, including those
    ; scrolled off to the left. clr_emit silently drops color writes when
    ; CLR_LCOL < LEFT_COL, so off-screen chars are parsed for state but
    ; produce no output — horizontal scroll is handled correctly at zero cost.
    ; ------------------------------------------------------------------

@loop:
    ; Row full?
    lda CLR_SCOL
    cmp #COLS
    beq @tramp_ret

    ; EOF?
    jsr clr_at_eof
    bcs @tramp_pad

    ; Peek at current char
    ldy #0
    lda (BUF_PTR),y
    cmp #PET_CR
    beq @tramp_pad

    ; Dispatch — near jump past trampolines
    jmp @dispatch

    ; Trampolines for the three out-of-range targets above
@tramp_ret:
    jmp @restore_and_ret
@tramp_pad:
    jmp @pad_to_eol

@dispatch:
    cpx #STATE_LINENUM
    beq @s_linenum
    cpx #STATE_STRING
    beq @s_string
    cpx #STATE_REM
    beq @s_rem
    cpx #STATE_SPACE
    beq @s_space
    jmp @s_normal

    ; ------------------------------------------------------------------
    ; STATE_LINENUM — leading decimal digits get COL_LINENUM
    ; ------------------------------------------------------------------
@s_linenum:
    ; A = current char from peek
    cmp #'0'
    bcc @ln_not_digit
    cmp #'9'+1
    bcs @ln_not_digit
    lda #COL_LINENUM
    jsr clr_emit
    jsr clr_advance
    jmp @loop

@ln_not_digit:
    ; Transition: space → STATE_SPACE, else STATE_NORMAL.
    ; Do NOT advance — let the new state handle this character.
    cmp #$20
    bne @ln_to_normal
    ldx #STATE_SPACE
    jmp @s_space

@ln_to_normal:
    ldx #STATE_NORMAL
    jmp @s_normal

    ; ------------------------------------------------------------------
    ; STATE_SPACE — spaces between line number and first statement
    ; ------------------------------------------------------------------
@s_space:
    ; A = current char
    cmp #$20
    bne @sp_end
    lda SETTING_FG
    jsr clr_emit
    jsr clr_advance
    jmp @loop

@sp_end:
    ; Non-space: transition to NORMAL without consuming this char
    ldx #STATE_NORMAL
    jmp @s_normal

    ; ------------------------------------------------------------------
    ; STATE_STRING — everything is COL_STRING until closing quote
    ; ------------------------------------------------------------------
@s_string:
    lda #COL_STRING
    jsr clr_emit
    ldy #0
    lda (BUF_PTR),y
    cmp #$22                ; closing " ?
    bne @str_no_close
    ldx #STATE_NORMAL
@str_no_close:
    jsr clr_advance
    jmp @loop

    ; ------------------------------------------------------------------
    ; STATE_REM — everything until CR is COL_REM
    ; ------------------------------------------------------------------
@s_rem:
    lda #COL_REM
    jsr clr_emit
    jsr clr_advance
    jmp @loop

    ; ------------------------------------------------------------------
    ; STATE_NORMAL — keyword scan, quote detection, literal fallback
    ; ------------------------------------------------------------------
@s_normal:
    ; Re-read current char (may have been reached via state transition).
    ldy #0
    lda (BUF_PTR),y

    ; String literal?
    cmp #$22                        ; $22 = '"'
    bne @n_check_token
    ldx #STATE_STRING
    lda SETTING_FG
    jsr clr_emit
    jsr clr_advance
    jmp @loop

    ; BASIC keyword? (buffer is plain text; match keyword strings, not tokens)
@n_check_token:
    jsr col_match_kw                ; C=1 -> CLR_KWLEN=len, KW_TOKEN=token
    bcc @n_literal

    ; Matched: paint CLR_KWLEN cells with the keyword color and advance past
    ; the whole keyword. col_match_kw clobbered X (state); we restore it after.
    lda CLR_KWLEN
    sta CLR_TMP                     ; cells remaining to paint/advance
@n_kw_loop:
    lda #COL_KEYWORD
    jsr clr_emit
    jsr clr_advance
    dec CLR_TMP
    bne @n_kw_loop

    ; REM ($8F)? rest of line is a comment.
    ldx #STATE_NORMAL
    lda KW_TOKEN
    cmp #$8F
    bne @n_kw_done
    ldx #STATE_REM
@n_kw_done:
    jmp @loop

    ; Plain PETSCII char — emit default foreground color
@n_literal:
    ldx #STATE_NORMAL
    lda SETTING_FG
    jsr clr_emit
    jsr clr_advance
    jmp @loop


@pad_to_eol:
    ldy CLR_SCOL
@pad_loop:
    cpy #COLS
    beq @restore_and_ret
    lda SETTING_FG
    sta (CLR_PTR),y
    iny
    jmp @pad_loop

    ; ------------------------------------------------------------------
    ; Restore BUF_PTR from stack and return
    ; ------------------------------------------------------------------
@restore_and_ret:
    pla
    sta BUF_PTR
    pla
    sta BUF_PTR+1
    rts

; ============================================================================
; clr_emit — write color byte A to color RAM if in the visible window.
;
; Visible: CLR_LCOL >= LEFT_COL and CLR_SCOL < COLS.
; If visible, stores A at (CLR_PTR)+CLR_SCOL and increments CLR_SCOL.
; Preserves X and Y.
; ============================================================================

clr_emit:
    pha
    lda CLR_LCOL
    cmp LEFT_COL
    bcc @skip               ; not yet in visible window
    lda CLR_SCOL
    cmp #COLS
    bcs @skip               ; row already full
    pla
    ldy CLR_SCOL
    sta (CLR_PTR),y
    inc CLR_SCOL
    rts
@skip:
    pla
    rts

; ============================================================================
; clr_advance — increment CLR_LCOL and advance BUF_PTR by one,
; warping across the gap if BUF_PTR reaches GAP_START. Preserves X and Y.
; ============================================================================

clr_advance:
    inc CLR_LCOL
    inc BUF_PTR
    bne @check_gap
    inc BUF_PTR+1
@check_gap:
    lda BUF_PTR
    cmp GAP_START
    bne @done
    lda BUF_PTR+1
    cmp GAP_START+1
    bne @done
    lda GAP_END
    sta BUF_PTR
    lda GAP_END+1
    sta BUF_PTR+1
@done:
    rts

; ============================================================================
; clr_at_eof — set C=1 if BUF_PTR >= work_buf_end. Preserves X and Y.
; ============================================================================

clr_at_eof:
    lda BUF_PTR+1
    cmp #>work_buf_end
    bne @done
    lda BUF_PTR
    cmp #<work_buf_end
@done:
    rts

; ============================================================================
; col_match_kw — gap-aware longest-match keyword scan at the current colorizer
; position (BUF_PTR, which may be just before the gap).
;
; The buffer is plain PETSCII text (keywords are NOT tokenized — MODDET/MODTOK
; keep work_buf in plain text). This routine matches the text at BUF_PTR
; against the keyword table (kw_strtab / kw_len_tab, token order $80-$D8),
; longest entry wins because the table is ordered longest-first within length
; groups and we accept the first full match.
;
; To stay correct across the gap, it first copies up to 8 logical characters
; ahead into COL_PEEK using the same gap-warp rule as clr_advance, padding with
; $00 at CR / EOF / gap-of-document. The flat COL_PEEK buffer is then matched.
;
; Returns:
;   C=1  match → CLR_KWLEN = char count, KW_TOKEN = token byte ($80-$D8)
;   C=0  no match
; Clobbers A, X, Y, CLR_CTMP, CLR_TMP. Preserves BUF_PTR.
; ============================================================================
COL_PEEK_LEN = 8

col_match_kw:
    ; ---- Fill COL_PEEK[0..7] with logical lookahead, gap-aware ----
    lda BUF_PTR
    sta CLR_CTMP
    lda BUF_PTR+1
    sta CLR_CTMP+1
    ldx #0                      ; X = COL_PEEK index
@peek_loop:
    ; At end of document? (CLR_CTMP >= work_buf_end)
    lda CLR_CTMP+1
    cmp #>work_buf_end
    bne @peek_read
    lda CLR_CTMP
    cmp #<work_buf_end
    bcs @peek_pad               ; reached end of buffer -> pad with $00
@peek_read:
    ldy #0
    lda (CLR_CTMP),y
    cmp #PET_CR
    beq @peek_pad               ; CR ends the logical line -> pad
    sta COL_PEEK,x
    ; advance CLR_CTMP by one, warping the gap exactly like clr_advance
    inc CLR_CTMP
    bne @peek_nogap
    inc CLR_CTMP+1
@peek_nogap:
    lda CLR_CTMP
    cmp GAP_START
    bne @peek_next
    lda CLR_CTMP+1
    cmp GAP_START+1
    bne @peek_next
    lda GAP_END
    sta CLR_CTMP
    lda GAP_END+1
    sta CLR_CTMP+1
@peek_next:
    inx
    cpx #COL_PEEK_LEN
    bcc @peek_loop
    jmp @match
@peek_pad:
    lda #0
@peek_pad_loop:
    sta COL_PEEK,x
    inx
    cpx #COL_PEEK_LEN
    bcc @peek_pad_loop

    ; ---- Match COL_PEEK against the keyword table ----
@match:
    lda #<kw_strtab
    sta CLR_CTMP
    lda #>kw_strtab
    sta CLR_CTMP+1
    lda #$80
    sta KW_TOKEN                ; current token being tried
@mk_try:
    lda KW_TOKEN
    cmp #$D9                    ; past last keyword ($D8)?
    bcs @mk_no_match
    sec
    sbc #$80
    tax                         ; X = index into kw_len_tab
    lda kw_len_tab,x
    sta CLR_KWLEN               ; candidate length
    ldy #0
@mk_cmp:
    lda (CLR_CTMP),y            ; keyword char
    cmp COL_PEEK,y              ; lookahead char
    bne @mk_miss
    iny
    cpy CLR_KWLEN
    bcc @mk_cmp
    ; full match — KW_TOKEN and CLR_KWLEN already set
    sec
    rts
@mk_miss:
    ; advance table pointer past this keyword's CLR_KWLEN chars
    clc
    lda CLR_CTMP
    adc CLR_KWLEN
    sta CLR_CTMP
    bcc :+
    inc CLR_CTMP+1
:   inc KW_TOKEN
    jmp @mk_try
@mk_no_match:
    clc
    rts


; ============================================================================
; col_try_keyword — longest-first keyword scan at BUF_PTR.
;
; Buffer contains PETSCII uppercase. colortab chars are PETSCII.
;
; Returns:
;   C=1  match found:
;          CLR_KWLEN = length in chars, with bit 7 SET if keyword was REM
;   C=0  no match
;
; Clobbers A, X, Y. CLR_CTMP used as table pointer.
; ============================================================================

; ============================================================================
; col_try_keyword — keyword scan for the colorizer, sharing tok_kwtab with
; the BASIC 65 tokenizer.
;
; tok_kwtab format:  [prefix][token][chars... last char has bit 7 set]
;                    sentinel: $FF in prefix slot.
;
; Differences from tok_try_keyword:
;   - Does NOT consume from any source pointer; just matches at (BUF_PTR),y
;     and returns the length so the caller can paint that many color cells.
;   - Returns:
;        C=1 on match  → CLR_KWLEN = char count, KW_TOKEN = BASIC token byte
;                         (caller checks KW_TOKEN == $8F for REM)
;        C=0 on no match
;   - Ignores the prefix byte for color purposes; the colorizer doesn't care
;     whether a keyword is single-byte ($00 prefix) or multi-byte (CE/E0/FE).
;
; ZP usage:
;   CLR_CTMP   — table walking pointer
;   CLR_KWLEN  — length on match (count of matched chars)
;   KW_TOKEN   — token byte of the matched entry (or last attempted)
;   CLR_TMP    — case-folded keyword char (scratch)
;   X          — match length counter / mismatch-skip flag
;   Y          — index into both table chars and buffer chars
; ============================================================================
colorize_row_asm:

    ; Compute CLR_PTR = SCREEN_PTR + $D400
    clc
    lda SCREEN_PTR
    adc #<$D400
    sta CLR_PTR
    lda SCREEN_PTR+1
    adc #>$D400
    sta CLR_PTR+1

    ; Save BUF_PTR on stack
    lda BUF_PTR+1
    pha
    lda BUF_PTR
    pha

    ; Init state
    ldx #STATE_ASM_SOL
    lda #0
    sta CLR_LCOL
    sta CLR_SCOL

@asm_loop:
    lda CLR_SCOL
    cmp #COLS
    beq @asm_tramp_ret

    jsr clr_at_eof
    bcs @asm_tramp_pad

    ldy #0
    lda (BUF_PTR),y
    cmp #PET_CR
    beq @asm_tramp_pad

    jmp @asm_dispatch

@asm_tramp_ret:
    jmp @asm_restore_and_ret
@asm_tramp_pad:
    jmp @asm_pad_to_eol

@asm_dispatch:
    cpx #STATE_ASM_COMMENT
    bne :+
    jmp @asm_s_comment
:   cpx #STATE_ASM_STRING
    bne :+
    jmp @asm_s_string
:   cpx #STATE_ASM_OPERAND
    bne :+
    jmp @asm_s_operand
:   cpx #STATE_ASM_MNEM
    bne :+
    jmp @asm_s_mnem
:   cpx #STATE_ASM_LABEL
    bne :+
    jmp @asm_s_label
:   ; STATE_ASM_SOL — fall through

    ; ------------------------------------------------------------------
    ; STATE_ASM_SOL — start of line, figure out what we're looking at
    ; ------------------------------------------------------------------
@asm_s_sol:
    ; A = first non-CR char on the line
    ; ';' → full-line comment
    cmp #$3B
    bne @sol_not_comment
    ldx #STATE_ASM_COMMENT
    jmp @asm_s_comment
@sol_not_comment:
    ; '.' → directive (.byte .word .org .text)
    cmp #$2E
    bne @sol_not_dot
    lda #0
    sta CLR_TMP             ; token length counter
    lda #COL_ASM_DIRECTIVE
    sta CLR_KWLEN           ; color to apply when token done
    ldx #STATE_ASM_MNEM
    jmp @asm_s_mnem
@sol_not_dot:
    ; '*' → *= org shorthand
    cmp #$2A
    bne @sol_not_star
    lda #COL_ASM_DIRECTIVE
    jsr clr_emit
    jsr clr_advance
    ldx #STATE_ASM_OPERAND
    jmp @asm_loop
@sol_not_star:
    ; ' ' or TAB → leading whitespace, mnemonic follows
    cmp #$20
    beq @sol_whitespace
    cmp #$09                ; TAB
    beq @sol_whitespace
    ; Letter/digit/_ → start of label
    ldx #STATE_ASM_LABEL
    jmp @asm_s_label
@sol_whitespace:
    lda SETTING_FG
    jsr clr_emit
    jsr clr_advance
    ; After whitespace, look for mnemonic
    ldy #0
    lda (BUF_PTR),y
    cmp #$20
    beq @sol_whitespace_cont    ; more whitespace
    cmp #$09
    beq @sol_whitespace_cont
    cmp #$3B
    beq @sol_to_comment         ; ';' — empty statement
    cmp #PET_CR
    beq @asm_tramp_pad
    ; Non-space non-comment → start mnemonic
    lda #0
    sta CLR_TMP
    lda #COL_ASM_MNEM
    sta CLR_KWLEN
    ldx #STATE_ASM_MNEM
    jmp @asm_s_mnem
@sol_whitespace_cont:
    jmp @asm_loop
@sol_to_comment:
    ldx #STATE_ASM_COMMENT
    jmp @asm_s_comment

    ; ------------------------------------------------------------------
    ; STATE_ASM_LABEL — consuming label chars until ':' or non-ident
    ; ------------------------------------------------------------------
@asm_s_label:
    ldy #0
    lda (BUF_PTR),y         ; re-read current char (A may be stale on some paths)
    ; ':' ends the label — emit label color for the colon too
    cmp #$3A
    beq @label_colon
    ; Letter, digit, underscore → label char
    ; Anything else (space, ;, CR) → label done without colon (treat as mnemonic?)
    ; Emit cyan for label chars
    lda #COL_ASM_LABEL
    jsr clr_emit
    jsr clr_advance
    jmp @asm_loop
@label_colon:
    lda #COL_ASM_LABEL
    jsr clr_emit
    jsr clr_advance
    ; After ':', expect whitespace then mnemonic
    ldx #STATE_ASM_SOL      ; reuse SOL to handle whitespace→mnemonic
    jmp @asm_loop

    ; ------------------------------------------------------------------
    ; STATE_ASM_MNEM — consuming mnemonic/directive token chars
    ; Stops at first whitespace, ';', or CR.
    ; CLR_KWLEN = color to emit. CLR_TMP = chars consumed so far.
    ; ------------------------------------------------------------------
@asm_s_mnem:
    ldy #0
    lda (BUF_PTR),y
    cmp #$20
    beq @mnem_done
    cmp #$09
    beq @mnem_done
    cmp #$3B                ; ';'
    beq @mnem_done
    cmp #PET_CR
    beq @mnem_done
    ; Emit token char in keyword color
    lda CLR_KWLEN
    jsr clr_emit
    jsr clr_advance
    inc CLR_TMP
    jmp @asm_loop
@mnem_done:
    ; Token ended — transition to OPERAND (whitespace will be emitted there)
    ldx #STATE_ASM_OPERAND
    jmp @asm_s_operand

    ; ------------------------------------------------------------------
    ; STATE_ASM_OPERAND — operand territory, default color
    ; Watch for '"' (string) and ';' (comment)
    ; ------------------------------------------------------------------
@asm_s_operand:
    ldy #0
    lda (BUF_PTR),y
    cmp #$3B                ; ';' → comment
    bne @operand_not_comment
    ldx #STATE_ASM_COMMENT
    jmp @asm_s_comment
@operand_not_comment:
    cmp #$22                ; '"' → string
    bne @operand_not_string
    ldx #STATE_ASM_STRING
    lda SETTING_FG          ; quote itself is default color
    jsr clr_emit
    jsr clr_advance
    jmp @asm_loop
@operand_not_string:
    lda SETTING_FG
    jsr clr_emit
    jsr clr_advance
    jmp @asm_loop

    ; ------------------------------------------------------------------
    ; STATE_ASM_COMMENT — everything until CR is gray
    ; ------------------------------------------------------------------
@asm_s_comment:
    lda #COL_ASM_COMMENT
    jsr clr_emit
    jsr clr_advance
    jmp @asm_loop

    ; ------------------------------------------------------------------
    ; STATE_ASM_STRING — inside "..." — green until closing quote
    ; ------------------------------------------------------------------
@asm_s_string:
    lda #COL_ASM_STRING
    jsr clr_emit
    ldy #0
    lda (BUF_PTR),y
    cmp #$22                ; closing "?
    bne @asm_str_no_close
    ldx #STATE_ASM_OPERAND
@asm_str_no_close:
    jsr clr_advance
    jmp @asm_loop

    ; ------------------------------------------------------------------
    ; Pad + restore
    ; ------------------------------------------------------------------
@asm_pad_to_eol:
    ldy CLR_SCOL
@asm_pad_loop:
    cpy #COLS
    beq @asm_restore_and_ret
    lda SETTING_FG
    sta (CLR_PTR),y
    iny
    jmp @asm_pad_loop

@asm_restore_and_ret:
    pla
    sta BUF_PTR
    pla
    sta BUF_PTR+1
    rts
