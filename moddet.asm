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
;   When done, copy staging area back to MOD_BUF and report MOD_STATUS=$02.
;
; ROM keyword table ($A09E):
;   Contiguous keyword strings, last char of each has bit 7 set.
;   Token $80 = index 0 (END), $81 = index 1 (FOR), ..., $CB = index $4B (GO).
;   Walk: skip (token - $80) null-terminated-by-high-bit entries, then copy
;   chars with bit 7 cleared until we see a char with bit 7 set (inclusive).
;
; Zero page used (free during our execution):
;   $FB/$FC — SRC_PTR:  walks tokenized source
;   $FD/$FE — DST_PTR:  walks staging area
;   $F7/$F8 — COPY_SRC: copy-back loop source pointer
;   $F9/$FA — COPY_DST: copy-back loop dest pointer
;   $3A/$3B — LINENO:   16-bit line number value (modified by decimal output)
;   $3C     — NZFLAG:   non-zero digit seen flag (decimal output)
;   $3D/$3E — KWTAB:    keyword table walker pointer
;
; Staging buffer: $C300-$CFFF (3.25K) — output written here, then copied
; back.  Code+data must fit in $C000-$C2FF.  Output larger than staging
; aborts with MOD_STATUS=$01 (buffer left untouched) — see emit_byte.
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
SRC_PTR          = $FB              ; source walk pointer (lo/hi)
DST_PTR          = $FD              ; staging write pointer (lo/hi)
COPY_SRC         = $F7              ; copy-back source (lo/hi)
COPY_DST         = $F9              ; copy-back dest  (lo/hi)
LINENO           = $3A              ; 16-bit line number scratch (lo/hi)
NZFLAG           = $3C              ; non-zero digit seen (decimal output)
KWTAB            = $3D              ; keyword table walker (lo/hi)
OVFLAG           = $3F              ; staging overflow flag ($FF = overflowed)



; STAGING must start after the code+kwtab — $C300 gives page alignment and
; margin.  STAGING_END is the first address staging may NOT touch: $D000 is
; the I/O area while the module runs with $01=$37, so an unchecked write
; there sprays VIC/SID/CIA registers.  emit_byte enforces this bound; on
; overflow the module reports MOD_STATUS=$01 and leaves MOD_BUF untouched.
STAGING          = $C300
STAGING_END      = $D000

; ============================================================================

.segment "LOADADDR"
    .word $C000

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

    ; SRC_PTR = MOD_BUF (start of buffer)
    lda MOD_BUF_LO
    sta SRC_PTR
    lda MOD_BUF_HI
    sta SRC_PTR+1

    ; PRG header detection: if buf[0..1] (as 16-bit LE) < MOD_BUF address,
    ; the buffer starts with a PRG load-address header ($01 $08 etc.) — skip it.
    ; Comparison: header_hi < MOD_BUF_HI  → header
    ;             header_hi = MOD_BUF_HI AND header_lo < MOD_BUF_LO → header
    ;             otherwise → raw BASIC, no skip needed.
    ldy #1
    lda (SRC_PTR),y             ; buf[1] = candidate header hi byte
    cmp MOD_BUF_HI
    bcc @skip_header            ; header_hi < MOD_BUF_HI -> definitely a header
    bne @no_header              ; header_hi > MOD_BUF_HI -> not a header
    ; header_hi == MOD_BUF_HI: check lo byte
    ldy #0
    lda (SRC_PTR),y             ; buf[0] = candidate header lo byte
    cmp MOD_BUF_LO
    bcs @no_header              ; header_lo >= MOD_BUF_LO -> raw BASIC
@skip_header:
    jsr inc_src_ptr
    jsr inc_src_ptr
@no_header:

    ; DST_PTR = STAGING
    lda #<STAGING
    sta DST_PTR
    lda #>STAGING
    sta DST_PTR+1
    lda #0
    sta OVFLAG

; ============================================================================
; @line_loop — walk one BASIC line per iteration
; ============================================================================

@line_loop:
    ; Bounds check
    lda SRC_PTR
    cmp MOD_GAP_START_LO
    lda SRC_PTR+1
    sbc MOD_GAP_START_HI
    bcs @all_done

    ; Check for end-of-program sentinel ($0000 link word)
    ldy #0
    lda (SRC_PTR),y
    bne @has_line
    iny
    lda (SRC_PTR),y
    beq @all_done           ; both bytes zero = sentinel

@has_line:
    ; Skip link word
    jsr inc_src_ptr
    jsr inc_src_ptr

    ; Read line number
    ldy #0
    lda (SRC_PTR),y
    sta LINENO
    iny
    lda (SRC_PTR),y
    sta LINENO+1

    ; Skip past line number bytes
    jsr inc_src_ptr
    jsr inc_src_ptr

    ; Emit line number as decimal digits
    jsr emit_lineno

    ; Emit a space after the line number
    lda #$20
    jsr emit_byte

; ============================================================================
; @token_loop — process token bytes until line terminator ($00)
; ============================================================================

@token_loop:
    ldy #0
    lda (SRC_PTR),y             ; read next byte
    beq @end_line               ; $00 = end of this line
    jsr inc_src_ptr             ; advance past the byte we just read

    ; Token or literal char?
    cmp #$80
    bcc @literal                ; < $80 → emit as-is

    ; Token $80-$D8: look up keyword in embedded table (standard $80-$CB
    ; plus PETProject extended keywords $CC-$D8). The kwtab below already
    ; carries the extended entries, so emit_keyword handles the full range.
    cmp #$D9
    bcs @literal                ; >= $D9 → genuinely out of range, emit as-is
    jsr emit_keyword            ; A = token byte on entry
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
; @all_done — copy staging area back to MOD_BUF
; ============================================================================

@all_done:
    ; If staging overflowed, the output is truncated — do NOT copy it back
    ; over the caller's buffer.  Report an error and leave MOD_BUF intact.
    lda OVFLAG
    beq @no_overflow
    jmp @bad
@no_overflow:

    ; COPY_SRC = STAGING (start of staging output)
    lda #<STAGING
    sta COPY_SRC
    lda #>STAGING
    sta COPY_SRC+1

    ; COPY_DST = MOD_BUF (where to copy back to)
    lda MOD_BUF_LO
    sta COPY_DST
    lda MOD_BUF_HI
    sta COPY_DST+1

    ; Copy until COPY_SRC reaches DST_PTR (the staging write head).
    ; Fix: compare COPY_SRC (not COPY_DST) against DST_PTR.
    ; Both start at STAGING and track the output head, so this terminates
    ; correctly regardless of where MOD_BUF lives in memory.
@copy:
    lda COPY_SRC
    cmp DST_PTR
    bne @copy_byte
    lda COPY_SRC+1
    cmp DST_PTR+1
    beq @copy_done

@copy_byte:
    ldy #0
    lda (COPY_SRC),y
    sta (COPY_DST),y
    ; Advance both pointers
    inc COPY_SRC
    bne :+
    inc COPY_SRC+1
:   inc COPY_DST
    bne @copy
    inc COPY_DST+1
    jmp @copy

@copy_done:
    ; Report new buffer end (COPY_DST = MOD_BUF + bytes_written)
    lda COPY_DST
    sta MOD_NEW_END_LO
    lda COPY_DST+1
    sta MOD_NEW_END_HI
    lda #$02                    ; MOD_STATUS: buffer replaced
    sta MOD_STATUS
    rts

@bad:
    lda #$01                    ; MOD_STATUS: error
    sta MOD_STATUS
    rts

; ============================================================================
; emit_lineno — write LINENO (16-bit) as decimal digits to staging.
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
; emit_keyword — look up and emit the keyword for token byte in A.
;
; Token $80 = keyword index 0 (END), $81 = index 1 (FOR), etc.
; ROM table at BASIC_KWTAB: last char of each keyword has bit 7 set.
; Walk: skip (A - $80) entries, then emit chars with bit 7 cleared,
; emit the final char (bit 7 set) with bit 7 cleared.
; Clobbers: A, X, Y, KWTAB
; ============================================================================

emit_keyword:
    ; Look up keyword for token byte in A using our own embedded table.
    ; No ROM banking required — immune to whatever $00/$01 state the editor sets.
    ;
    ; Table format: same as BASIC ROM — last char of each keyword has bit 7 set.
    ; Token $80 = index 0 (END), $81 = index 1 (FOR), ..., $CB = index $4B (GO).
    ;
    ; X = number of keywords to skip = token - $80
    sec
    sbc #$80
    tax                             ; X = skip count

    ; Point KWTAB at our embedded keyword table
    lda #<kwtab
    sta KWTAB
    lda #>kwtab
    sta KWTAB+1

    ; Skip X keywords (each ends with a byte that has bit 7 set).
    ; CRITICAL: JSR inc_kwtab corrupts the N flag (INC inside sets N based on the
    ; new pointer value, not the kwtab byte). Save A before the JSR and check
    ; bit 7 of A explicitly after it returns.
    cpx #0
    beq @emit_chars
@skip_loop:
    ldy #0
    lda (KWTAB),y               ; read kwtab byte
    pha                         ; save it — JSR will corrupt N
    jsr inc_kwtab               ; advance KWTAB (N is now from INC, not from LDA)
    pla                         ; restore kwtab byte; PLA sets N from this byte
    bpl @skip_loop              ; N from PLA: bit7 clear → mid-keyword, keep consuming
    dex                         ; bit7 set → end of keyword
    bne @skip_loop              ; more keywords to skip

@emit_chars:
    ; KWTAB now points to first char of target keyword. Same flag-save pattern.
    ldy #0
    lda (KWTAB),y
    pha                         ; save kwtab byte before JSR corrupts N
    jsr inc_kwtab
    pla                         ; PLA sets N from the kwtab byte
    pha                         ; save again for the BPL check after emit
    and #$7F                    ; strip high bit for output
    jsr emit_byte
    pla                         ; restore kwtab byte; PLA sets N
    bpl @emit_chars             ; bit7 clear → more chars in keyword
    rts                         ; bit7 set → keyword done

; ============================================================================
; kwtab — embedded BASIC 2.0 keyword table
;
; Each keyword string ends with its last character OR'd with $80.
; Tokens $80–$CB map to indices 0–75.
; ============================================================================
kwtab:
    ; $80 END
    .byte $45,$4E,$C4
    ; $81 FOR
    .byte $46,$4F,$D2
    ; $82 NEXT
    .byte $4E,$45,$58,$D4
    ; $83 DATA
    .byte $44,$41,$54,$C1
    ; $84 INPUT#
    .byte $49,$4E,$50,$55,$54,$A3
    ; $85 INPUT
    .byte $49,$4E,$50,$55,$D4
    ; $86 DIM
    .byte $44,$49,$CD
    ; $87 READ
    .byte $52,$45,$41,$C4
    ; $88 LET
    .byte $4C,$45,$D4
    ; $89 GOTO
    .byte $47,$4F,$54,$CF
    ; $8A RUN
    .byte $52,$55,$CE
    ; $8B IF
    .byte $49,$C6
    ; $8C RESTORE
    .byte $52,$45,$53,$54,$4F,$52,$C5
    ; $8D GOSUB
    .byte $47,$4F,$53,$55,$C2
    ; $8E RETURN
    .byte $52,$45,$54,$55,$52,$CE
    ; $8F REM
    .byte $52,$45,$CD
    ; $90 STOP
    .byte $53,$54,$4F,$D0
    ; $91 ON
    .byte $4F,$CE
    ; $92 WAIT
    .byte $57,$41,$49,$D4
    ; $93 LOAD
    .byte $4C,$4F,$41,$C4
    ; $94 SAVE
    .byte $53,$41,$56,$C5
    ; $95 VERIFY
    .byte $56,$45,$52,$49,$46,$D9
    ; $96 DEF
    .byte $44,$45,$C6
    ; $97 POKE
    .byte $50,$4F,$4B,$C5
    ; $98 PRINT#
    .byte $50,$52,$49,$4E,$54,$A3
    ; $99 PRINT
    .byte $50,$52,$49,$4E,$D4
    ; $9A CONT
    .byte $43,$4F,$4E,$D4
    ; $9B LIST
    .byte $4C,$49,$53,$D4
    ; $9C CLR
    .byte $43,$4C,$D2
    ; $9D CMD
    .byte $43,$4D,$C4
    ; $9E SYS
    .byte $53,$59,$D3
    ; $9F OPEN
    .byte $4F,$50,$45,$CE
    ; $A0 CLOSE
    .byte $43,$4C,$4F,$53,$C5
    ; $A1 GET
    .byte $47,$45,$D4
    ; $A2 NEW
    .byte $4E,$45,$D7
    ; $A3 TAB(
    .byte $54,$41,$42,$A8
    ; $A4 TO
    .byte $54,$CF
    ; $A5 FN
    .byte $46,$CE
    ; $A6 SPC(
    .byte $53,$50,$43,$A8
    ; $A7 THEN
    .byte $54,$48,$45,$CE
    ; $A8 NOT
    .byte $4E,$4F,$D4
    ; $A9 STEP
    .byte $53,$54,$45,$D0
    ; $AA +
    .byte $AB
    ; $AB -
    .byte $AD
    ; $AC *
    .byte $AA
    ; $AD /
    .byte $AF
    ; $AE ^
    .byte $DE
    ; $AF AND
    .byte $41,$4E,$C4
    ; $B0 OR
    .byte $4F,$D2
    ; $B1 >
    .byte $BE
    ; $B2 =
    .byte $BD
    ; $B3 <
    .byte $BC
    ; $B4 SGN
    .byte $53,$47,$CE
    ; $B5 INT
    .byte $49,$4E,$D4
    ; $B6 ABS
    .byte $41,$42,$D3
    ; $B7 USR
    .byte $55,$53,$D2
    ; $B8 FRE
    .byte $46,$52,$C5
    ; $B9 POS
    .byte $50,$4F,$D3
    ; $BA SQR
    .byte $53,$51,$D2
    ; $BB RND
    .byte $52,$4E,$C4
    ; $BC LOG
    .byte $4C,$4F,$C7
    ; $BD EXP
    .byte $45,$58,$D0
    ; $BE COS
    .byte $43,$4F,$D3
    ; $BF SIN
    .byte $53,$49,$CE
    ; $C0 TAN
    .byte $54,$41,$CE
    ; $C1 ATN
    .byte $41,$54,$CE
    ; $C2 PEEK
    .byte $50,$45,$45,$CB
    ; $C3 LEN
    .byte $4C,$45,$CE
    ; $C4 STR$
    .byte $53,$54,$52,$A4
    ; $C5 VAL
    .byte $56,$41,$CC
    ; $C6 ASC
    .byte $41,$53,$C3
    ; $C7 CHR$
    .byte $43,$48,$52,$A4
    ; $C8 LEFT$
    .byte $4C,$45,$46,$54,$A4
    ; $C9 RIGHT$
    .byte $52,$49,$47,$48,$54,$A4
    ; $CA MID$
    .byte $4D,$49,$44,$A4
    ; $CB GO
    .byte $47,$CF
; $CC ASSEMBLE
    .byte $41,$53,$53,$45,$4D,$42,$4C,$C5
    ; $CD INCLUDE
    .byte $49,$4E,$43,$4C,$55,$44,$C5
    ; $CE RUNPROG
    .byte $52,$55,$4E,$50,$52,$4F,$C7
    ; $CF SCRATCH
    .byte $53,$43,$52,$41,$54,$43,$C8
    ; $D0 DELETE
    .byte $44,$45,$4C,$45,$54,$C5
    ; $D1 EXISTS
    .byte $45,$58,$49,$53,$54,$D3
    ; $D2 RENAME
    .byte $52,$45,$4E,$41,$4D,$C5
    ; $D3 STATUS
    .byte $53,$54,$41,$54,$55,$D3
    ; $D4 DRIVE
    .byte $44,$52,$49,$56,$C5
    ; $D5 ONERR
    .byte $4F,$4E,$45,$52,$D2
    ; $D6 PAUSE
    .byte $50,$41,$55,$53,$C5
    ; $D7 COPY
    .byte $43,$4F,$50,$D9
    ; $D8 DIR
    .byte $44,$49,$D2

; ============================================================================
; emit_byte — write A to (DST_PTR), advance DST_PTR.
; Bounds-checked: at STAGING_END the byte is dropped and OVFLAG is set —
; without this, output longer than staging (any BASIC program over ~3 KB)
; would write straight through the $D000 I/O registers.
; Clobbers: Y
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
; Clobbers: nothing (saves/restores A via stack? No - callers handle it.)
; Actually: clobbers nothing besides carry (uses inc, not adc).
; ============================================================================

inc_src_ptr:
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   rts

; ============================================================================
; inc_kwtab — advance KWTAB by 1.
; ============================================================================

inc_kwtab:
    inc KWTAB
    bne :+
    inc KWTAB+1
:   rts
