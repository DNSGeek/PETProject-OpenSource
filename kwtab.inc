; ============================================================================
; kwtab.inc — the tokenizer keyword table and its first-letter index, shared
; by modtok.asm and modsct.asm (the two tables were byte-for-byte copies).
;
;   kw_index  emits  kw_first / kw_idx_lo / kw_idx_hi  (see below)
;   kw_table  emits  kwtab: [token][chars, last|$80] ... $FF sentinel
;
; kwtab is longest-first; try_keyword's result depends on that order, so
; the index lists each letter's entries in table order. Every entry's
; bytes, and the order of entries, are exactly those of the table the two
; modules used to spell out with .byte lines.
;
; Index layout: for a first letter L ('A'..'Z'), kw_first[L-'A'] is the
; position in kw_idx_lo/kw_idx_hi of the addresses of the entries that
; start with L, in table order, followed by a 0 in kw_idx_hi (no entry
; lives in page zero). Letters no keyword starts with get just the 0.
;
; Both macros run the entry list, so kw_index (which needs each entry's
; first letter as a constant) can come before kw_table (whose addresses it
; references forward).
; ============================================================================

.ifndef KWTAB_INC_INCLUDED
KWTAB_INC_INCLUDED = 1

.macro kw_entries
    kw $CC, "ASSEMBLE"
    kw $CD, "INCLUDE"
    kw $CE, "RUNPROG"           ; before RUN
    kw $CF, "SCRATCH"
    kw $8C, "RESTORE"
    kw $D0, "DELETE"
    kw $D1, "EXISTS"
    kw $D2, "RENAME"
    kw $D3, "STATUS"
    kw $84, "INPUT#"
    kw $98, "PRINT#"
    kw $8E, "RETURN"
    kw $C9, "RIGHT$"
    kw $95, "VERIFY"
    kw $D4, "DRIVE"
    kw $D5, "ONERR"             ; before ON
    kw $D6, "PAUSE"
    kw $A0, "CLOSE"
    kw $8D, "GOSUB"
    kw $85, "INPUT"
    kw $C8, "LEFT$"
    kw $99, "PRINT"
    kw $D7, "COPY"
    kw $C7, "CHR$"
    kw $9A, "CONT"
    kw $83, "DATA"
    kw $89, "GOTO"
    kw $9B, "LIST"
    kw $93, "LOAD"
    kw $CA, "MID$"
    kw $82, "NEXT"
    kw $9F, "OPEN"
    kw $C2, "PEEK"
    kw $97, "POKE"
    kw $87, "READ"
    kw $94, "SAVE"
    kw $A6, "SPC("
    kw $A9, "STEP"
    kw $90, "STOP"
    kw $C4, "STR$"
    kw $A3, "TAB("
    kw $A7, "THEN"
    kw $92, "WAIT"
    kw $D8, "DIR"
    kw $B6, "ABS"
    kw $AF, "AND"
    kw $C6, "ASC"
    kw $C1, "ATN"
    kw $9C, "CLR"
    kw $9D, "CMD"
    kw $BE, "COS"
    kw $96, "DEF"
    kw $86, "DIM"
    kw $80, "END"
    kw $BD, "EXP"
    kw $81, "FOR"
    kw $B8, "FRE"
    kw $A1, "GET"
    kw $B5, "INT"
    kw $C3, "LEN"
    kw $88, "LET"
    kw $BC, "LOG"
    kw $A2, "NEW"
    kw $A8, "NOT"
    kw $B9, "POS"
    kw $8F, "REM"
    kw $BB, "RND"
    kw $8A, "RUN"               ; after RUNPROG
    kw $B4, "SGN"
    kw $BF, "SIN"
    kw $BA, "SQR"
    kw $9E, "SYS"
    kw $C0, "TAN"
    kw $B7, "USR"
    kw $C5, "VAL"
    kw $A5, "FN"
    kw $CB, "GO"
    kw $8B, "IF"
    kw $91, "ON"                ; after ONERR
    kw $B0, "OR"
    kw $A4, "TO"
    ; 1-char operators: dispatched by kw_op_chars before the table is
    ; consulted, so never reached as entries — but they stay in the table:
    ; a walk that runs past an entry's end (see try_keyword) reads them.
    kw $AC, "*"
    kw $AA, "+"
    kw $AB, "-"
    kw $AD, "/"
    kw $B3, "<"
    kw $B2, "="
    kw $B1, ">"
    kw $AE, "^"
.endmacro

; One entry. Pass 1 records its first char (kwf_<n>); pass 2 emits it at
; label kwa_<n>.
.macro kw tok, str
.if KW_PASS = 1
    .ident(.sprintf("kwf_%d", KW_N)) = .strat(str, 0)
    .if .strat(str, 0) >= 'A' && .strat(str, 0) <= 'Z'
        ; try_keyword skips the compare of the first char, which is only
        ; sound when that char is not also the entry's (bit-7) final char.
        .assert .strlen(str) >= 2, error, "kwtab.inc: a keyword starting with a letter must be at least 2 chars"
    .endif
.else
    .ident(.sprintf("kwa_%d", KW_N)) := *
    .byte tok
    .repeat .strlen(str) - 1, KWI
        .byte .strat(str, KWI)
    .endrepeat
    .byte .strat(str, .strlen(str) - 1) | $80
.endif
KW_N .set KW_N + 1
.endmacro

.macro kw_index
KW_PASS .set 1
KW_N .set 0
kw_entries
KW_COUNT = KW_N

; kw_first[L-'A'] — start of letter L's list in kw_idx_lo/hi
KW_POS .set 0
kw_first:
.repeat 26, KWL
    .byte KW_POS
    .repeat KW_COUNT, KWI
        .if .ident(.sprintf("kwf_%d", KWI)) = 'A' + KWL
            KW_POS .set KW_POS + 1
        .endif
    .endrepeat
    KW_POS .set KW_POS + 1          ; the list's 0 terminator
.endrepeat
.assert KW_POS <= 256, error, "kwtab.inc: keyword index exceeds 256 entries"

kw_idx_lo:
.repeat 26, KWL
    .repeat KW_COUNT, KWI
        .if .ident(.sprintf("kwf_%d", KWI)) = 'A' + KWL
            .byte <.ident(.sprintf("kwa_%d", KWI))
        .endif
    .endrepeat
    .byte 0
.endrepeat

kw_idx_hi:
.repeat 26, KWL
    .repeat KW_COUNT, KWI
        .if .ident(.sprintf("kwf_%d", KWI)) = 'A' + KWL
            .byte >.ident(.sprintf("kwa_%d", KWI))
        .endif
    .endrepeat
    .byte 0                         ; terminator: no entry is in page zero
.endrepeat
.endmacro

.macro kw_table
KW_PASS .set 2
KW_N .set 0
kwtab:
kw_entries
    .byte $FF                       ; sentinel
.endmacro

.endif ; KWTAB_INC_INCLUDED
