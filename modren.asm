; ============================================================================
; MODREN — BASIC Line Renumber Module for PETProject
;
; Pass 1: scan buffer, build old→new line-number mapping table.
; Pass 2: copy pre-gap source to staging (top of buffer) so the full source
;         is linear, then rewrite from work_buf upward — replacing line-number
;         headers and all GOTO/GOSUB/THEN references.
;
; Loads at $C000 via module.cfg.
; Returns MOD_STATUS = $02 (buffer replaced), $01 on error.
;
; Staging guarantee: staging_start = BUF + gap_size.  Since DST starts at BUF
; and SRC starts at staging_start, DST always trails SRC — no collision even
; when output grows slightly.
;
; Handles: GOTO, GOSUB, THEN; string literals; REM comments.
; Defaults: start = 10, step = 10.
; Table: 512 entries × 4 bytes = 2048 bytes (BSS after code).
; ============================================================================

; ---- Module parameter block ($0212-$0220) ----
MOD_MAGIC        = $0212
MOD_BUF_LO       = $0214
MOD_BUF_HI       = $0215
MOD_GAP_START_LO = $0216
MOD_GAP_START_HI = $0217
MOD_GAP_END_LO   = $0218
MOD_GAP_END_HI   = $0219
MOD_BUF_END_LO   = $021A
MOD_BUF_END_HI   = $021B
MOD_STATUS       = $021E
MOD_NEW_END_LO   = $021F
MOD_NEW_END_HI   = $0220

; ---- Constants ----
MOD_MAGIC_VAL    = $4D
PET_CR           = $0D
PET_0            = $30
PET_9            = $39
PET_SPACE        = $20
PET_QUOTE        = $22
CONTENT_ROWS     = 24           ; sentinel CRs written after output

REN_MAX_HI       = $FA          ; new number overflows when hi >= $FA (>= 64000)
REN_TABLE_MAX    = 512
REN_DEFAULT_START_LO = 10
REN_DEFAULT_START_HI = 0
REN_DEFAULT_STEP_LO  = 10
REN_DEFAULT_STEP_HI  = 0

SPIN_CELL        = $D800
SPIN_COLOR_A     = $01
SPIN_COLOR_B     = $00

; ---- Zero page (saved / restored around module call) ----
SRC_PTR          = $FB          ; 16-bit source walker    ($FC = hi)
DST_PTR          = $FD          ; 16-bit destination ptr  ($FE = hi)
TMP              = $3A          ; scratch lo              ($3B = hi)
TMP2             = $3C          ; number lo               ($3D = TMP2+1 = hi)
TMP3             = $3E          ; table ptr lo            ($3F = TMP3+1 = hi)

; ============================================================================
.segment "LOADADDR"
    .word $C000

.segment "CODE"

    jmp modren_entry

; ============================================================================
; modren_entry
; ============================================================================
modren_entry:
    sei
    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq :+
    cli
    rts
:
    ; Save ZP $3A-$3F
    ldx #0
@zpsave:
    lda $3A,x
    sta ZP_SAVE,x
    inx
    cpx #6
    bne @zpsave
    ; Save $FB-$FE
    lda $FB
    sta ZP_SAVE+6
    lda $FC
    sta ZP_SAVE+7
    lda $FD
    sta ZP_SAVE+8
    lda $FE
    sta ZP_SAVE+9

    ; Copy MOD parameters into local state
    lda MOD_BUF_LO
    sta REN_BUF_LO
    lda MOD_BUF_HI
    sta REN_BUF_HI
    lda MOD_GAP_START_LO
    sta REN_GAP_LO
    lda MOD_GAP_START_HI
    sta REN_GAP_HI
    lda MOD_GAP_END_LO
    sta REN_GAP_END_LO
    lda MOD_GAP_END_HI
    sta REN_GAP_END_HI
    lda MOD_BUF_END_LO
    sta REN_END_LO
    lda MOD_BUF_END_HI
    sta REN_END_HI

    ; Initialise renumber state
    lda #REN_DEFAULT_START_LO
    sta REN_CUR_LO
    lda #REN_DEFAULT_START_HI
    sta REN_CUR_HI
    lda #REN_DEFAULT_STEP_LO
    sta REN_STEP_LO
    lda #REN_DEFAULT_STEP_HI
    sta REN_STEP_HI
    lda #0
    sta REN_COUNT_LO
    sta REN_COUNT_HI
    sta REN_SPINNER
    lda #SPIN_COLOR_A
    sta REN_SPIN_IDX

    ; SRC_PTR = work_buf
    lda REN_BUF_LO
    sta SRC_PTR
    lda REN_BUF_HI
    sta SRC_PTR+1

    ; Pass 1: build mapping table
    jsr pass1
    bcs @error

    ; Pass 2: rewrite buffer
    jsr pass2
    bcs @error

    ; Success
    lda #$02
    sta MOD_STATUS
    lda DST_PTR
    sta MOD_NEW_END_LO
    lda DST_PTR+1
    sta MOD_NEW_END_HI
    jmp @done

@error:
    lda #$01
    sta MOD_STATUS

@done:
    lda #SPIN_COLOR_A
    sta SPIN_CELL

    ldx #0
@zprestore:
    lda ZP_SAVE,x
    sta $3A,x
    inx
    cpx #6
    bne @zprestore
    lda ZP_SAVE+6
    sta $FB
    lda ZP_SAVE+7
    sta $FC
    lda ZP_SAVE+8
    sta $FD
    lda ZP_SAVE+9
    sta $FE

    cli
    rts

; ============================================================================
; pass1 — scan all BASIC lines, build old→new mapping table.
; C=0 success, C=1 overflow.
; ============================================================================
pass1:
@loop:
    inc REN_SPINNER
    lda REN_SPINNER
    and #$0F
    bne @no_spin
    lda REN_SPIN_IDX
    eor #(SPIN_COLOR_A ^ SPIN_COLOR_B)
    sta REN_SPIN_IDX
    sta SPIN_CELL
@no_spin:
    jsr warp_if_at_gap
    jsr at_content_end
    bcs @done

    jsr parse_line_number       ; C=0 → TMP2+1:TMP2 = old num, SRC past digits
    bcs @skip

    ldy #0                      ; line number must be followed by a space
    lda (SRC_PTR),y
    cmp #PET_SPACE
    bne @skip

    lda TMP2+1                  ; reject out-of-range line numbers
    cmp #REN_MAX_HI
    bcs @skip

    ; check_lineno_directive parses through parse_line_number, which clobbers
    ; TMP2/TMP2+1 (and TMP/TMP+1, via mul16x10) — but store_entry needs TMP2 to
    ; still hold this line's OLD number.  Stash it in TMP3/TMP3+1, which nothing
    ; in the Pass-1 path touches (it's a Pass-2 table pointer), and restore
    ; before store_entry.
    lda TMP2
    sta TMP3
    lda TMP2+1
    sta TMP3+1

    ; SRC_PTR points at the space after the digits. Peek the body for a
    ; "REM LINENO nnnn [sss]" directive. If found, it overrides REN_CUR
    ; (and REN_STEP) for this line and everything after it.
    jsr check_lineno_directive  ; C=0 → REN_CUR/REN_STEP already updated

    lda TMP3                    ; restore old number for store_entry
    sta TMP2
    lda TMP3+1
    sta TMP2+1

    lda REN_CUR_HI              ; reject if new number already overflowed
    cmp #REN_MAX_HI
    bcs @overflow

    jsr store_entry
    bcs @overflow

    lda REN_CUR_LO
    clc
    adc REN_STEP_LO
    sta REN_CUR_LO
    lda REN_CUR_HI
    adc REN_STEP_HI
    sta REN_CUR_HI

@skip:
    jsr skip_to_next_cr
    jmp @loop

@done:
    clc
    rts
@overflow:
    sec
    rts

; ============================================================================
; pass2 — rewrite buffer via staging area.
; C=0 success, C=1 error.
; ============================================================================
pass2:
    jsr setup_staging           ; linearise source, set SRC_PTR
    bcs @error

    ; DST_PTR = work_buf
    lda REN_BUF_LO
    sta DST_PTR
    lda REN_BUF_HI
    sta DST_PTR+1

@line_loop:
    lda SRC_PTR+1
    cmp REN_END_HI
    bne @do_line
    lda SRC_PTR
    cmp REN_END_LO
    beq @all_done
@do_line:
    jsr process_line
    jmp @line_loop

@all_done:
    ; Output complete. DST_PTR is the true end of renumbered text. Do NOT
    ; write sentinel CRs here or advance past them: MOD_NEW_END must point at
    ; the real content end so the editor can place the gap correctly. The
    ; editor's $02 handler is responsible for any trailing sentinel fill (it
    ; writes them into the gap region as non-content scratch, exactly as the
    ; MODDIS load path does).
    clc
    rts
@error:
    sec
    rts

; ============================================================================
; setup_staging
; Copy pre-gap [BUF..GAP_START) to [BUF_END-content_size..BUF_END-post_size).
; Post-gap is already at the top of the buffer; pre-gap is appended before it.
; Linearised source occupies [staging_start..BUF_END).
; On return: SRC_PTR = staging_start.
; C=0 success, C=1 if buffer too full (no room for staging).
; ============================================================================
setup_staging:
    ; pre_size  = GAP_START - BUF
    lda REN_GAP_LO
    sec
    sbc REN_BUF_LO
    sta REN_PREGAP_LO
    lda REN_GAP_HI
    sbc REN_BUF_HI
    sta REN_PREGAP_HI

    ; post_size = BUF_END - GAP_END  (post-gap is already at top of buffer)
    lda REN_END_LO
    sec
    sbc REN_GAP_END_LO
    sta TMP                     ; post_lo
    lda REN_END_HI
    sbc REN_GAP_END_HI
    sta TMP+1                   ; post_hi

    ; content_size = pre + post
    lda REN_PREGAP_LO
    clc
    adc TMP
    sta TMP2
    lda REN_PREGAP_HI
    adc TMP+1
    sta TMP2+1

    ; staging_start = BUF_END - content_size
    lda REN_END_LO
    sec
    sbc TMP2
    sta REN_STAG_LO
    lda REN_END_HI
    sbc TMP2+1
    sta REN_STAG_HI

    ; staging_start must be >= BUF (gap big enough to hold linearised content)
    lda REN_STAG_HI
    cmp REN_BUF_HI
    bcc @no_space
    bne @ok
    lda REN_STAG_LO
    cmp REN_BUF_LO
    bcc @no_space
@ok:
    ; Copy pre-gap → staging.  Skip if pre-gap is empty.
    lda REN_PREGAP_LO
    ora REN_PREGAP_HI
    beq @no_pregap

    ; Source: BUF;  Dest: REN_STAG.  TMP3 = dest ptr.
    lda REN_BUF_LO
    sta SRC_PTR
    lda REN_BUF_HI
    sta SRC_PTR+1
    lda REN_STAG_LO
    sta TMP3
    lda REN_STAG_HI
    sta TMP3+1
    ; Counter in TMP2/TMP2+1 (= pre_size, which we just computed above)
    lda REN_PREGAP_LO
    sta TMP2
    lda REN_PREGAP_HI
    sta TMP2+1
@copy:
    lda TMP2
    ora TMP2+1
    beq @no_pregap
    ldy #0
    lda (SRC_PTR),y
    sta (TMP3),y
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   inc TMP3
    bne :+
    inc TMP3+1
:   lda TMP2
    bne :+
    dec TMP2+1
:   dec TMP2
    jmp @copy

@no_pregap:
    lda REN_STAG_LO
    sta SRC_PTR
    lda REN_STAG_HI
    sta SRC_PTR+1
    clc
    rts
@no_space:
    sec
    rts

; ============================================================================
; process_line — rewrite one complete BASIC line SRC→DST.
; ============================================================================
process_line:
    ; If line starts with a digit: parse, look up, write new number
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_0
    bcc @body
    cmp #PET_9+1
    bcs @body
    jsr parse_line_number       ; TMP2+1:TMP2 = old number
    jsr find_mapping            ; TMP2+1:TMP2 = new number (unchanged if absent)
    jsr write_number
@body:
    ; Process rest of line with keyword/string/REM awareness
    lda #0
    sta REN_IN_STR
    sta REN_IN_REM
    jmp process_body            ; tail call — returns after writing CR

; ============================================================================
; process_body — copy line body SRC→DST handling GOTO/GOSUB/THEN/strings/REM.
; Returns after writing the CR that terminates the line.
; ============================================================================
process_body:
@loop:
    lda SRC_PTR+1
    cmp REN_END_HI
    bne @read
    lda SRC_PTR
    cmp REN_END_LO
    bcs @eof
@read:
    ldy #0
    lda (SRC_PTR),y

    cmp #PET_CR
    bne @not_cr
    jsr emit_src_char           ; write CR, advance both ptrs
    lda #0
    sta REN_IN_STR
    sta REN_IN_REM
    rts                         ; line done

@not_cr:
    ; Inside REM: copy verbatim
    lda REN_IN_REM
    bne @verbatim

    ; Inside string: copy verbatim, watch for closing quote
    lda REN_IN_STR
    beq @normal
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_QUOTE
    bne @verbatim
    jsr emit_src_char
    lda #0
    sta REN_IN_STR
    jmp @loop

@normal:
    ldy #0
    lda (SRC_PTR),y

    cmp #PET_QUOTE              ; opening quote
    bne @not_quote
    jsr emit_src_char
    lda #$FF
    sta REN_IN_STR
    jmp @loop
@not_quote:

    cmp #$47                    ; 'G' — try GOTO / GOSUB
    bne @not_g
    jsr try_goto_gosub
    bcc @loop                   ; C=0: matched and handled
@not_g:
    cmp #$54                    ; 'T' — try THEN
    bne @not_t
    jsr try_then
    bcc @loop
@not_t:
    cmp #$52                    ; 'R' — try REM
    bne @verbatim
    jsr try_rem
    bcc @loop

@verbatim:
    jsr emit_src_char
    jmp @loop
@eof:
    rts

; ============================================================================
; try_goto_gosub — SRC at 'G'. Peek ahead for GOTO (4) or GOSUB (5).
; Match: copy keyword, call renumber_ref, return C=0.
; No match: C=1 (caller copies 'G' as plain text).
; ============================================================================
try_goto_gosub:
    ldy #1
    lda (SRC_PTR),y
    cmp #$4F                    ; 'O'
    bne @no

    iny                         ; y=2
    lda (SRC_PTR),y
    cmp #$54                    ; 'T' → GOTO?
    beq @try_goto
    cmp #$53                    ; 'S' → GOSUB?
    bne @no

    ; GOSUB: need U, B
    iny                         ; y=3
    lda (SRC_PTR),y
    cmp #$55                    ; 'U'
    bne @no
    iny                         ; y=4
    lda (SRC_PTR),y
    cmp #$42                    ; 'B'
    bne @no
    iny                         ; y=5 — must not be alpha (avoid GOSUBROUTINE)
    lda (SRC_PTR),y
    jsr is_alpha
    bcs @no
    lda #5
    bne @matched                ; always

@try_goto:
    iny                         ; y=3
    lda (SRC_PTR),y
    cmp #$4F                    ; 'O'
    bne @no
    iny                         ; y=4 — must not be alpha
    lda (SRC_PTR),y
    jsr is_alpha
    bcs @no
    lda #4

@matched:
    jsr copy_kw_and_ref
    clc
    rts
@no:
    sec
    rts

; ============================================================================
; try_then — SRC at 'T'. Peek for THEN (4 chars).
; ============================================================================
try_then:
    ldy #1
    lda (SRC_PTR),y
    cmp #$48                    ; 'H'
    bne @no
    iny
    lda (SRC_PTR),y
    cmp #$45                    ; 'E'
    bne @no
    iny
    lda (SRC_PTR),y
    cmp #$4E                    ; 'N'
    bne @no
    iny                         ; y=4 — must not be alpha
    lda (SRC_PTR),y
    jsr is_alpha
    bcs @no
    lda #4
    jsr copy_kw_and_ref
    clc
    rts
@no:
    sec
    rts

; ============================================================================
; try_rem — SRC at 'R'. Peek for REM (3 chars).
; Match: copy R,E,M, set REN_IN_REM, return C=0.
; ============================================================================
try_rem:
    ldy #1
    lda (SRC_PTR),y
    cmp #$45                    ; 'E'
    bne @no
    iny
    lda (SRC_PTR),y
    cmp #$4D                    ; 'M'
    bne @no
    lda #3
    jsr copy_kw_only            ; just copy R,E,M — no number after REM
    lda #$FF
    sta REN_IN_REM
    clc
    rts
@no:
    sec
    rts

; ============================================================================
; copy_kw_and_ref — copy A chars SRC→DST, then process a number argument.
; ============================================================================
copy_kw_and_ref:
    jsr copy_kw_only
    ; fall through

; ============================================================================
; renumber_ref — skip spaces, then if a digit follows: parse→look up→write.
; ============================================================================
renumber_ref:
@sp:
    lda SRC_PTR+1
    cmp REN_END_HI
    bne @peek
    lda SRC_PTR
    cmp REN_END_LO
    bcs @done
@peek:
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_SPACE
    bne @not_sp
    jsr emit_src_char
    jmp @sp
@not_sp:
    cmp #PET_0
    bcc @done
    cmp #PET_9+1
    bcs @done
    jsr parse_line_number
    jsr find_mapping
    jsr write_number
@done:
    rts

; ============================================================================
; copy_kw_only — copy A chars from (SRC_PTR)→(DST_PTR), advancing both.
; ============================================================================
copy_kw_only:
    tax
@lp:
    ldy #0
    lda (SRC_PTR),y
    sta (DST_PTR),y
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   inc DST_PTR
    bne :+
    inc DST_PTR+1
:   dex
    bne @lp
    rts

; ============================================================================
; emit_src_char — copy one char from (SRC_PTR) to (DST_PTR), advance both.
; ============================================================================
emit_src_char:
    ldy #0
    lda (SRC_PTR),y
    sta (DST_PTR),y
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   inc DST_PTR
    bne :+
    inc DST_PTR+1
:   rts

; ============================================================================
; find_mapping — linear search: TMP2+1:TMP2 → new number.
; C=0 found (TMP2+1:TMP2 updated); C=1 not found (unchanged).
; REN_COUNT_LO assumed < 256 for this iteration.
; ============================================================================
find_mapping:
    lda #<REN_TABLE
    sta TMP3
    lda #>REN_TABLE
    sta TMP3+1
    ldx REN_COUNT_LO
    beq @nf
@lp:
    ldy #0
    lda (TMP3),y
    cmp TMP2
    bne @nx
    iny
    lda (TMP3),y
    cmp TMP2+1
    bne @nx
    iny
    lda (TMP3),y                ; new_lo
    pha
    iny
    lda (TMP3),y                ; new_hi
    sta TMP2+1
    pla
    sta TMP2
    clc
    rts
@nx:
    lda TMP3
    clc
    adc #4
    sta TMP3
    bcc :+
    inc TMP3+1
:   dex
    bne @lp
@nf:
    sec
    rts

; ============================================================================
; write_number — write TMP2+1:TMP2 as decimal to (DST_PTR), leading zeros
; suppressed.  Handles 0-63999 (1-5 digits).
; Uses: X (divisor index), REN_LEADING, REN_DIV_LO/HI, REN_DIGIT.
; ============================================================================
write_number:
    lda #0
    sta REN_LEADING
    ldx #0
@dl:
    lda wn_div_lo,x
    sta REN_DIV_LO
    lda wn_div_hi,x
    sta REN_DIV_HI
    lda #0
    sta REN_DIGIT
@sl:
    lda TMP2+1
    cmp REN_DIV_HI
    bcc @em
    bne @sub
    lda TMP2
    cmp REN_DIV_LO
    bcc @em
@sub:
    lda TMP2
    sec
    sbc REN_DIV_LO
    sta TMP2
    lda TMP2+1
    sbc REN_DIV_HI
    sta TMP2+1
    inc REN_DIGIT
    jmp @sl
@em:
    lda REN_DIGIT
    bne @nonzero
    lda REN_LEADING
    beq @skip
    lda #$30
    bne @wr
@nonzero:
    lda #$FF
    sta REN_LEADING
    lda REN_DIGIT
    ora #$30
@wr:
    ldy #0
    sta (DST_PTR),y
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:
@skip:
    inx
    cpx #4
    bne @dl

    ; Units digit — always emit
    lda TMP2
    ora #$30
    ldy #0
    sta (DST_PTR),y
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:   rts

wn_div_lo: .byte <10000, <1000, <100, <10
wn_div_hi: .byte >10000, >1000, >100, >10

; ============================================================================
; is_alpha — C=1 if A in 'A'..'Z' ($41-$5A), C=0 otherwise.
; ============================================================================
is_alpha:
    cmp #$41
    bcc @no
    cmp #$5B
    bcs @no
    sec
    rts
@no:
    clc
    rts

; ============================================================================
; check_lineno_directive — Pass-1 only.
;
; On entry SRC_PTR points at the space after a line's leading number.
; Tests whether the line body is a renumber directive of the form:
;
;       REM LINENO <base> [ <step> ]
;
; ("REM" then a space, "LINENO", one or more spaces, a decimal base, and
;  optionally another run of spaces and a decimal step.)
;
; Matching is non-destructive: SRC_PTR is preserved across the call so the
; surrounding Pass-1 loop's skip_to_next_cr still works.  We walk a private
; copy in LINENO_SAVE while temporarily borrowing SRC_PTR for the existing
; parse_line_number helper, then restore.
;
; On match (C=0):
;   REN_CUR_LO/HI  = parsed base
;   REN_STEP_LO/HI = parsed step, or default 10 if no step was given
;   (overflow of the base against REN_MAX_HI is left to the caller's existing
;    check, exactly as for an ordinary line)
;
; On no match (C=1): REN_CUR / REN_STEP untouched.
;
; Letters in the work buffer are uppercase PETSCII; we compare raw bytes.
; Clobbers A, X, Y, TMP2/TMP2+1.  Preserves SRC_PTR.
; ============================================================================
LINENO_KW_LEN = 6               ; "LINENO"

check_lineno_directive:
    ; Save the live SRC_PTR — we restore it on every exit path.
    lda SRC_PTR
    sta LINENO_SAVE
    lda SRC_PTR+1
    sta LINENO_SAVE+1
    jmp @begin

    ; Near trampoline: the early-rejection branches below are too far from the
    ; real @nomatch (which sits past all the parse code) to reach with a signed
    ; 8-bit branch. They target this instead.
@nm_tramp:
    jmp @nomatch

@begin:
    ; SRC_PTR currently at the space after the digits. Require exactly one
    ; space, then "REM", then one space, then "LINENO".  (We use a single
    ; required space before REM to match how a normal "10 REM..." line reads;
    ; extra spaces would simply not match, which is fine — the directive is a
    ; documented exact form.)
    jsr cld_peek                ; A = (SRC_PTR), but does not advance
    cmp #PET_SPACE
    bne @nm_tramp
    jsr cld_adv

    ; "REM"
    jsr cld_peek
    cmp #$52                    ; 'R'
    bne @nm_tramp
    jsr cld_adv
    jsr cld_peek
    cmp #$45                    ; 'E'
    bne @nm_tramp
    jsr cld_adv
    jsr cld_peek
    cmp #$4D                    ; 'M'
    bne @nm_tramp
    jsr cld_adv

    ; exactly one space between REM and LINENO
    jsr cld_peek
    cmp #PET_SPACE
    bne @nm_tramp
    jsr cld_adv

    ; "LINENO"
    ldx #0
@kw:
    jsr cld_peek
    cmp lineno_kw,x
    bne @nm_tramp
    jsr cld_adv
    inx
    cpx #LINENO_KW_LEN
    bne @kw

    ; The char after LINENO must be a space (guards against LINENOX etc.)
    jsr cld_peek
    cmp #PET_SPACE
    bne @nm_tramp

    ; --- parse the base number ---
    jsr cld_skip_spaces
    jsr cld_peek                ; need at least one digit
    cmp #PET_0
    bcc @nm_tramp
    cmp #PET_9+1
    bcs @nm_tramp
    jsr cld_parse_num           ; TMP2+1:TMP2 = base
    lda TMP2
    sta REN_CUR_LO
    lda TMP2+1
    sta REN_CUR_HI

    ; --- default the step, then look for an optional explicit step ---
    lda #REN_DEFAULT_STEP_LO
    sta REN_STEP_LO
    lda #REN_DEFAULT_STEP_HI
    sta REN_STEP_HI

    jsr cld_skip_spaces
    jsr cld_peek
    cmp #PET_0
    bcc @match                  ; no step token → keep default 10
    cmp #PET_9+1
    bcs @match
    jsr cld_parse_num           ; TMP2+1:TMP2 = step
    lda TMP2
    sta REN_STEP_LO
    lda TMP2+1
    sta REN_STEP_HI
    ; (a step of 0 is the user's problem; documented be-careful zone)

@match:
    jsr cld_restore
    clc
    rts
@nomatch:
    jsr cld_restore
    sec
    rts

; ---- private helpers for check_lineno_directive ----
; These walk SRC_PTR directly but are only ever called between save/restore,
; so the live Pass-1 pointer is safe.  cld_adv honours the gap so a directive
; that straddles the gap is still parsed correctly.

cld_peek:
    ldy #0
    lda (SRC_PTR),y
    rts

cld_adv:
    jsr advance_src             ; reuse the gap-aware increment
    rts

cld_skip_spaces:
    jsr cld_peek
    cmp #PET_SPACE
    bne @d
    jsr cld_adv
    jmp cld_skip_spaces
@d: rts

; Parse decimal at SRC_PTR into TMP2+1:TMP2, advancing past the digits.
; Thin wrapper so the intent reads clearly; parse_line_number already does
; exactly this against SRC_PTR.
cld_parse_num:
    jsr parse_line_number
    rts

cld_restore:
    lda LINENO_SAVE
    sta SRC_PTR
    lda LINENO_SAVE+1
    sta SRC_PTR+1
    rts

lineno_kw: .byte $4C, $49, $4E, $45, $4E, $4F   ; "LINENO" uppercase PETSCII

; ============================================================================
; Pass-1 helpers
; ============================================================================

warp_if_at_gap:
    lda SRC_PTR
    cmp REN_GAP_LO
    bne @d
    lda SRC_PTR+1
    cmp REN_GAP_HI
    bne @d
    lda REN_GAP_END_LO
    sta SRC_PTR
    lda REN_GAP_END_HI
    sta SRC_PTR+1
@d: rts

at_content_end:
    lda SRC_PTR+1
    cmp REN_END_HI
    bcc @n
    bne @y
    lda SRC_PTR
    cmp REN_END_LO
    bcc @n
@y: sec
    rts
@n: clc
    rts

advance_src:
    inc SRC_PTR
    bne @c
    inc SRC_PTR+1
@c: lda SRC_PTR
    cmp REN_GAP_LO
    bne @d
    lda SRC_PTR+1
    cmp REN_GAP_HI
    bne @d
    lda REN_GAP_END_LO
    sta SRC_PTR
    lda REN_GAP_END_HI
    sta SRC_PTR+1
@d: rts

skip_to_next_cr:
    jsr at_content_end
    bcs @d
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_CR
    bne @nc
    jsr advance_src
    rts
@nc:
    jsr advance_src
    jmp skip_to_next_cr
@d: rts

parse_line_number:
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_0
    bcc @nd
    cmp #PET_9+1
    bcs @nd
    lda #0
    sta TMP2
    sta TMP2+1
@dl:
    jsr at_content_end
    bcs @ok
    ldy #0
    lda (SRC_PTR),y
    cmp #PET_0
    bcc @ok
    cmp #PET_9+1
    bcs @ok
    sec
    sbc #PET_0
    pha
    jsr mul16x10
    pla
    clc
    adc TMP2
    sta TMP2
    bcc :+
    inc TMP2+1
:   jsr advance_src
    jmp @dl
@ok:
    clc
    rts
@nd:
    sec
    rts

mul16x10:
    ; TMP2+1:TMP2 *= 10 = (×8) + (×2). Uses TMP/TMP+1. Preserves A.
    pha
    lda TMP2
    sta TMP
    lda TMP2+1
    sta TMP+1
    asl TMP2
    rol TMP2+1
    asl TMP2
    rol TMP2+1
    asl TMP2
    rol TMP2+1
    asl TMP
    rol TMP+1
    lda TMP2
    clc
    adc TMP
    sta TMP2
    lda TMP2+1
    adc TMP+1
    sta TMP2+1
    pla
    rts

store_entry:
    lda REN_COUNT_HI            ; table full when COUNT_HI >= 2 (512 entries)
    cmp #>REN_TABLE_MAX
    bcc @ok
    sec
    rts
@ok:
    lda TMP2
    pha
    lda TMP2+1
    pha
    ; offset = COUNT × 4 into TMP/TMP+1
    lda REN_COUNT_LO
    asl
    sta TMP
    lda REN_COUNT_HI
    rol
    sta TMP+1
    asl TMP
    rol TMP+1
    lda TMP
    clc
    adc #<REN_TABLE
    sta TMP
    lda TMP+1
    adc #>REN_TABLE
    sta TMP+1
    pla
    sta TMP2+1
    pla
    sta TMP2
    ldy #0
    lda TMP2
    sta (TMP),y
    iny
    lda TMP2+1
    sta (TMP),y
    iny
    lda REN_CUR_LO
    sta (TMP),y
    iny
    lda REN_CUR_HI
    sta (TMP),y
    inc REN_COUNT_LO
    bne :+
    inc REN_COUNT_HI
:   clc
    rts

; ============================================================================
; BSS — allocated in module RAM after code, not stored in PRG.
; Total: ~1350 bytes code + ~45 bytes state + 2048 bytes table ≈ 3443 bytes
; (limit is $FFE = 4094 bytes per module.cfg).
; ============================================================================
.segment "BSS"

ZP_SAVE:         .res 10
REN_BUF_LO:      .res 1
REN_BUF_HI:      .res 1
REN_GAP_LO:      .res 1
REN_GAP_HI:      .res 1
REN_GAP_END_LO:  .res 1
REN_GAP_END_HI:  .res 1
REN_END_LO:      .res 1
REN_END_HI:      .res 1
REN_CUR_LO:      .res 1
REN_CUR_HI:      .res 1
REN_STEP_LO:     .res 1
REN_STEP_HI:     .res 1
REN_COUNT_LO:    .res 1
REN_COUNT_HI:    .res 1
REN_SPINNER:     .res 1
REN_SPIN_IDX:    .res 1

; Pass-2 state
REN_STAG_LO:     .res 1        ; staging area start lo
REN_STAG_HI:     .res 1        ; staging area start hi
REN_PREGAP_LO:   .res 1        ; pre-gap content size lo
REN_PREGAP_HI:   .res 1        ; pre-gap content size hi
REN_IN_STR:      .res 1        ; $FF = inside string literal
REN_IN_REM:      .res 1        ; $FF = inside REM comment
REN_LEADING:     .res 1        ; 0 = suppressing leading zeros
REN_DIV_LO:      .res 1        ; divisor lo for write_number
REN_DIV_HI:      .res 1        ; divisor hi
REN_DIGIT:       .res 1        ; digit accumulator for write_number
LINENO_SAVE:     .res 2        ; SRC_PTR save for check_lineno_directive

; Mapping table: [old_lo, old_hi, new_lo, new_hi] × 512
REN_TABLE:       .res 4 * REN_TABLE_MAX
