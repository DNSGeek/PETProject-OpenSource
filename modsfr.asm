; =============================================================================
; modsfr.asm — Search / Replace module for PETProject
; =============================================================================

; Editor parameter block
MOD_STATUS       = $021E
MOD_GAP_START_LO = $0216
MOD_GAP_START_HI = $0217
MOD_GAP_END_LO   = $0218
MOD_GAP_END_HI   = $0219
MOD_BUF_LO       = $0214
MOD_BUF_HI       = $0215
MOD_BUF_END_LO   = $021A
MOD_BUF_END_HI   = $021B

; Editor ZP — borrowed for pointer dereferences while module runs
WORK_PTR         = $0013
LPTR             = $0015
ZP_GAP_START     = $0002
ZP_GAP_END       = $0004
ZP_CURSOR_ROW    = $0010
ZP_CURSOR_COL    = $0011

; Editor callbacks intentionally removed — hardcoded addresses shift on every
; recompile. Rendering is handled by do_search_replace after the module exits.

; Screen / color RAM
ROW0_SCR         = $0400
ROW1_SCR         = $0428
ROW2_SCR         = $0450
ROW0_COL         = $D800
ROW1_COL         = $D828
ROW2_COL         = $D850

; Screen codes
SC_LBRACKET      = $1B
SC_RBRACKET      = $1D
SC_SPACE         = $20
SC_COLON         = $3A
SC_UNDERSCORE    = $1F
SC_A             = $01
SC_C             = $03
SC_D             = $04
SC_E             = $05
SC_F             = $06
SC_I             = $09
SC_L             = $0C
SC_N             = $0E
SC_P             = $10
SC_R             = $12

; Colors
COL_CHROME       = 11
COL_TOGGLE_ON    = 7
COL_INPUT        = 1
COL_CURSOR_CHAR  = 7
COL_FOUND        = 5
COL_NOT_FOUND    = 2

; Keys
KEY_STOP         = $03
KEY_F1           = $85          ; F1 — toggle case sensitivity inside module
KEY_RETURN       = $0D
KEY_DEL          = $14
KEY_CRSR_DN      = $11
KEY_CRSR_UP      = $91

; Input limits
FIND_MAXLEN      = 24
REPL_MAXLEN      = 24
CHROME_COLS      = 14
INPUT_COLS       = 25

MSTAT_OK         = $00
MSTAT_REPOSITION = $04
JIFFY_LO         = $00A2

; =============================================================================
.segment "LOADADDR"
    .word $C000

.segment "CODE"

; -----------------------------------------------------------------------------
sfr_main:
    lda MOD_BUF_LO
    sta sfr_buf_lo
    lda MOD_BUF_HI
    sta sfr_buf_hi
    lda MOD_GAP_START_LO
    sta sfr_gs_lo
    lda MOD_GAP_START_HI
    sta sfr_gs_hi
    lda MOD_GAP_END_LO
    sta sfr_ge_lo
    lda MOD_GAP_END_HI
    sta sfr_ge_hi
    lda MOD_BUF_END_LO
    sta sfr_be_lo
    lda MOD_BUF_END_HI
    sta sfr_be_hi

    ; pre_len = GAP_START - BUF_START
    lda sfr_gs_lo
    sec
    sbc sfr_buf_lo
    sta sfr_pre_lo
    lda sfr_gs_hi
    sbc sfr_buf_hi
    sta sfr_pre_hi

    ; total = pre_len + (BUF_END - GAP_END)
    lda sfr_be_lo
    sec
    sbc sfr_ge_lo
    sta sfr_total_lo
    lda sfr_be_hi
    sbc sfr_ge_hi
    sta sfr_total_hi
    lda sfr_total_lo
    clc
    adc sfr_pre_lo
    sta sfr_total_lo
    lda sfr_total_hi
    adc sfr_pre_hi
    sta sfr_total_hi

    lda #0
    sta sfr_find_len
    sta sfr_find_buf
    sta sfr_repl_len
    sta sfr_repl_buf
    sta sfr_have_match
    sta sfr_did_move
    sta sfr_cur_field
    lda #$FF
    sta sfr_case_mode

    lda sfr_pre_lo
    sta sfr_srch_lo
    lda sfr_pre_hi
    sta sfr_srch_hi

    jsr sfr_draw_chrome
    jsr sfr_draw_find_field
    jsr sfr_draw_repl_field

; ---- Input loop ----
sfr_loop:
    jsr $FFE4
    beq sfr_loop

    cmp #KEY_STOP
    beq sfr_exit

    cmp #KEY_F1
    bne @t1
    jsr sfr_toggle_case
    jmp sfr_loop
@t1:
    cmp #KEY_CRSR_DN
    bne @t2
    jsr sfr_field_dn
    jmp sfr_loop
@t2:
    cmp #KEY_CRSR_UP
    bne @t3
    jsr sfr_field_up
    jmp sfr_loop
@t3:
    cmp #KEY_DEL
    bne @t4
    jsr sfr_do_del
    jmp sfr_loop
@t4:
    cmp #KEY_RETURN
    bne @t5
    jsr sfr_do_return
    jmp sfr_loop
@t5:
    cmp #$20
    bcc sfr_loop            ; control chars — ignore
    cmp #$80
    bcs sfr_loop            ; high PETSCII (function keys etc.) — ignore
    jsr sfr_type_char
    jmp sfr_loop

sfr_exit:
    lda sfr_did_move
    beq @nomove
    lda sfr_gs_lo
    sta MOD_GAP_START_LO
    lda sfr_gs_hi
    sta MOD_GAP_START_HI
    lda sfr_ge_lo
    sta MOD_GAP_END_LO
    lda sfr_ge_hi
    sta MOD_GAP_END_HI
    lda #MSTAT_REPOSITION
    sta MOD_STATUS
    rts
@nomove:
    lda #MSTAT_OK
    sta MOD_STATUS
    rts

; ---- Dialog actions ----
sfr_toggle_case:
    lda sfr_case_mode
    eor #$FF
    sta sfr_case_mode
    jsr sfr_draw_toggle
    lda #0
    sta sfr_have_match
    rts

sfr_field_dn:
    lda sfr_cur_field
    bne @done
    lda #1
    sta sfr_cur_field
    jsr sfr_draw_find_field
    jsr sfr_draw_repl_field
@done:
    rts

sfr_field_up:
    lda sfr_cur_field
    beq @done
    lda #0
    sta sfr_cur_field
    jsr sfr_draw_repl_field
    jsr sfr_draw_find_field
@done:
    rts

sfr_do_del:
    lda sfr_cur_field
    bne @repl
    lda sfr_find_len
    beq @done
    dec sfr_find_len
    lda #0
    sta sfr_have_match
    jsr sfr_draw_find_field
    rts
@repl:
    lda sfr_repl_len
    beq @done
    dec sfr_repl_len
    jsr sfr_draw_repl_field
@done:
    rts

sfr_type_char:
    ldx sfr_cur_field
    bne @repl
    ldx sfr_find_len
    cpx #FIND_MAXLEN
    bcs @done
    sta sfr_find_buf,x
    inc sfr_find_len
    lda #0
    sta sfr_have_match
    jsr sfr_draw_find_field
    rts
@repl:
    ldx sfr_repl_len
    cpx #REPL_MAXLEN
    bcs @done
    sta sfr_repl_buf,x
    inc sfr_repl_len
    jsr sfr_draw_repl_field
@done:
    rts

sfr_do_return:
    lda sfr_find_len
    beq @done
    lda sfr_have_match
    beq @find
    ; Replace then find next
    lda sfr_repl_len
    bne @do_repl
    ; Empty replacement: skip match by advancing GAP_END
    lda sfr_ge_lo
    clc
    adc sfr_find_len
    sta sfr_ge_lo
    sta ZP_GAP_END
    sta MOD_GAP_END_LO
    lda sfr_ge_hi
    adc #0
    sta sfr_ge_hi
    sta ZP_GAP_END+1
    sta MOD_GAP_END_HI
    ; Deleting the match shrinks the document — keep sfr_total in sync,
    ; or later searches scan find_len bytes past the real content and can
    ; act on phantom matches beyond the buffer.
    lda sfr_total_lo
    sec
    sbc sfr_find_len
    sta sfr_total_lo
    lda sfr_total_hi
    sbc #0
    sta sfr_total_hi
    lda #$FF
    sta sfr_did_move
    jmp @after_repl
@do_repl:
    jsr sfr_replace_at_match
    bcs @done                   ; no room in gap — replace aborted
@after_repl:
    lda #0
    sta sfr_have_match
    lda sfr_gs_lo
    sec
    sbc sfr_buf_lo
    sta sfr_srch_lo
    lda sfr_gs_hi
    sbc sfr_buf_hi
    sta sfr_srch_hi
@find:
    jsr sfr_find_next
@done:
    rts

; =============================================================================
; sfr_find_next
; =============================================================================
sfr_find_next:
    lda sfr_find_len
    bne @has_str
    rts                     ; no search string — nothing to do
@has_str:
    ; Pattern longer than the document can never match — bail out now,
    ; which also keeps the "total - find_len" limit below from wrapping
    ; negative and scanning memory past the buffer.
    lda sfr_total_hi
    bne @len_ok
    lda sfr_total_lo
    cmp sfr_find_len
    bcs @len_ok
    jmp @nf
@len_ok:
    lda sfr_srch_lo
    sta sfr_i_lo
    lda sfr_srch_hi
    sta sfr_i_hi
@outer:
    ; limit = total - find_len
    lda sfr_total_lo
    sec
    sbc sfr_find_len
    sta sfr_tmp_lo
    lda sfr_total_hi
    sbc #0
    sta sfr_tmp_hi
    ; i > limit → not found
    lda sfr_i_hi
    cmp sfr_tmp_hi
    bcc @try
    bne @nf
    lda sfr_i_lo
    cmp sfr_tmp_lo
    bcc @try
    beq @try
    bcs @nf
@try:
    lda #0
    sta sfr_j
@inner:
    lda sfr_j
    cmp sfr_find_len
    beq @found
    lda sfr_i_lo
    clc
    adc sfr_j
    sta sfr_voff_lo
    lda sfr_i_hi
    adc #0
    sta sfr_voff_hi
    jsr sfr_vbyte
    ldx sfr_case_mode
    beq @nf_buf
    jsr sfr_fold
@nf_buf:
    sta sfr_tmp_val
    ldx sfr_j
    lda sfr_find_buf,x
    ldx sfr_case_mode
    beq @nf_pat
    jsr sfr_fold
@nf_pat:
    cmp sfr_tmp_val
    bne @miss
    inc sfr_j
    bne @inner
@miss:
    inc sfr_i_lo
    bne @outer
    inc sfr_i_hi
    bne @outer
@nf:
    lda #0
    sta sfr_have_match
    jsr sfr_flash_not_found
@ret:
    rts

@found:
    lda sfr_i_lo
    sta sfr_match_lo
    lda sfr_i_hi
    sta sfr_match_hi
    lda #$FF
    sta sfr_have_match
    jsr sfr_move_gap
    lda sfr_i_lo
    clc
    adc sfr_find_len
    sta sfr_srch_lo
    lda sfr_i_hi
    adc #0
    sta sfr_srch_hi
    ; Flash "FOUND" in status bar — editor renders viewport on module exit.
    ; Do NOT call back into the editor here: the addresses shift every recompile.
    jsr sfr_flash_found
    rts

; =============================================================================
; sfr_move_gap — reposition gap to virtual offset sfr_match_lo/hi
; =============================================================================
sfr_move_gap:
    lda sfr_match_hi
    cmp sfr_pre_hi
    bcc @go_case_a
    bne @case_b
    lda sfr_match_lo
    cmp sfr_pre_lo
    bcs @not_case_a
@go_case_a:
    jmp @case_a
@not_case_a:

@case_b:
    lda sfr_match_lo
    sec
    sbc sfr_pre_lo
    sta sfr_mv_sz_lo
    lda sfr_match_hi
    sbc sfr_pre_hi
    sta sfr_mv_sz_hi
    lda sfr_mv_sz_lo
    ora sfr_mv_sz_hi
    beq @b_upd
    lda sfr_ge_lo
    sta sfr_src_lo
    lda sfr_ge_hi
    sta sfr_src_hi
    lda sfr_gs_lo
    sta sfr_dst_lo
    lda sfr_gs_hi
    sta sfr_dst_hi
    lda sfr_mv_sz_lo
    sta sfr_mv_cnt_lo
    lda sfr_mv_sz_hi
    sta sfr_mv_cnt_hi
    jsr sfr_fwd_copy
@b_upd:
    lda sfr_gs_lo
    clc
    adc sfr_mv_sz_lo
    sta sfr_gs_lo
    lda sfr_gs_hi
    adc sfr_mv_sz_hi
    sta sfr_gs_hi
    lda sfr_ge_lo
    clc
    adc sfr_mv_sz_lo
    sta sfr_ge_lo
    lda sfr_ge_hi
    adc sfr_mv_sz_hi
    sta sfr_ge_hi
    lda sfr_match_lo
    sta sfr_pre_lo
    lda sfr_match_hi
    sta sfr_pre_hi
    jmp @zp

@case_a:
    lda sfr_pre_lo
    sec
    sbc sfr_match_lo
    sta sfr_mv_sz_lo
    lda sfr_pre_hi
    sbc sfr_match_hi
    sta sfr_mv_sz_hi
    lda sfr_mv_sz_lo
    ora sfr_mv_sz_hi
    beq @a_upd
    lda sfr_buf_lo
    clc
    adc sfr_match_lo
    sta sfr_src_lo
    lda sfr_buf_hi
    adc sfr_match_hi
    sta sfr_src_hi
    lda sfr_ge_lo
    sec
    sbc sfr_mv_sz_lo
    sta sfr_dst_lo
    lda sfr_ge_hi
    sbc sfr_mv_sz_hi
    sta sfr_dst_hi
    lda sfr_mv_sz_lo
    sta sfr_mv_cnt_lo
    lda sfr_mv_sz_hi
    sta sfr_mv_cnt_hi
    ; Case A moves the block UP in memory (dst = src + gap size), so the
    ; regions overlap whenever the block is larger than the gap.  Copy
    ; descending — a forward copy would overwrite the block's tail before
    ; reading it.  (Case B moves down, where the forward copy is safe.)
    jsr sfr_bwd_copy
@a_upd:
    lda sfr_buf_lo
    clc
    adc sfr_match_lo
    sta sfr_gs_lo
    lda sfr_buf_hi
    adc sfr_match_hi
    sta sfr_gs_hi
    lda sfr_match_lo
    sta sfr_pre_lo
    lda sfr_match_hi
    sta sfr_pre_hi

@zp:
    lda sfr_gs_lo
    sta ZP_GAP_START
    sta MOD_GAP_START_LO
    lda sfr_gs_hi
    sta ZP_GAP_START+1
    sta MOD_GAP_START_HI
    lda sfr_ge_lo
    sta ZP_GAP_END
    sta MOD_GAP_END_LO
    lda sfr_ge_hi
    sta ZP_GAP_END+1
    sta MOD_GAP_END_HI
    lda #$FF
    sta sfr_did_move
    rts

; =============================================================================
; sfr_replace_at_match
; C=0 replaced; C=1 aborted — the free gap (ge - gs) is smaller than the
; replacement, and writing anyway would trample post-gap content and leave
; gap_start past gap_end (after which every gap operation corrupts memory).
; =============================================================================
sfr_replace_at_match:
    lda sfr_ge_lo
    sec
    sbc sfr_gs_lo
    sta sfr_tmp_lo
    lda sfr_ge_hi
    sbc sfr_gs_hi
    bne @fits                   ; gap >= 256 bytes — always enough
    lda sfr_tmp_lo
    cmp sfr_repl_len
    bcs @fits
    jsr sfr_flash_full          ; "BUFFER FULL" — nothing was changed
    sec
    rts
@fits:
    lda sfr_gs_lo
    sta LPTR
    lda sfr_gs_hi
    sta LPTR+1
    ldy #0
@wr:
    cpy sfr_repl_len
    beq @done
    lda sfr_repl_buf,y
    sta (LPTR),y
    iny
    bne @wr
@done:
    lda sfr_gs_lo
    clc
    adc sfr_repl_len
    sta sfr_gs_lo
    sta ZP_GAP_START
    sta MOD_GAP_START_LO
    lda sfr_gs_hi
    adc #0
    sta sfr_gs_hi
    sta ZP_GAP_START+1
    sta MOD_GAP_START_HI
    lda sfr_ge_lo
    clc
    adc sfr_find_len
    sta sfr_ge_lo
    sta ZP_GAP_END
    sta MOD_GAP_END_LO
    lda sfr_ge_hi
    adc #0
    sta sfr_ge_hi
    sta ZP_GAP_END+1
    sta MOD_GAP_END_HI
    lda sfr_gs_lo
    sec
    sbc sfr_buf_lo
    sta sfr_pre_lo
    lda sfr_gs_hi
    sbc sfr_buf_hi
    sta sfr_pre_hi
    lda sfr_be_lo
    sec
    sbc sfr_ge_lo
    sta sfr_total_lo
    lda sfr_be_hi
    sbc sfr_ge_hi
    sta sfr_total_hi
    lda sfr_total_lo
    clc
    adc sfr_pre_lo
    sta sfr_total_lo
    lda sfr_total_hi
    adc sfr_pre_hi
    sta sfr_total_hi
    lda #$FF
    sta sfr_did_move
    clc
    rts

; =============================================================================
; sfr_fwd_copy — sfr_mv_cnt bytes from sfr_src to sfr_dst.
; Loads src→WORK_PTR, dst→LPTR for ZP indirect access.
; =============================================================================
sfr_fwd_copy:
    lda sfr_mv_cnt_lo
    ora sfr_mv_cnt_hi
    beq @done
    lda sfr_src_lo
    sta WORK_PTR
    lda sfr_src_hi
    sta WORK_PTR+1
    lda sfr_dst_lo
    sta LPTR
    lda sfr_dst_hi
    sta LPTR+1
    ldy #0
@pg:
    lda sfr_mv_cnt_hi
    beq @tail
@full:
    lda (WORK_PTR),y
    sta (LPTR),y
    iny
    bne @full
    inc WORK_PTR+1
    inc LPTR+1
    dec sfr_mv_cnt_hi
    bne @pg
@tail:
    ldy #0
    ldx sfr_mv_cnt_lo
    beq @done
@tl:
    lda (WORK_PTR),y
    sta (LPTR),y
    iny
    dex
    bne @tl
@done:
    rts

; =============================================================================
; sfr_bwd_copy — sfr_mv_cnt bytes from sfr_src to sfr_dst, copied DESCENDING
; (last byte first).  Required when dst > src and the regions may overlap.
; sfr_src/sfr_dst are the START addresses, same convention as sfr_fwd_copy.
; Clobbers sfr_mv_cnt.
; =============================================================================
sfr_bwd_copy:
    lda sfr_mv_cnt_lo
    ora sfr_mv_cnt_hi
    beq @done
    ; WORK_PTR = src + cnt, LPTR = dst + cnt (one past the last byte)
    lda sfr_src_lo
    clc
    adc sfr_mv_cnt_lo
    sta WORK_PTR
    lda sfr_src_hi
    adc sfr_mv_cnt_hi
    sta WORK_PTR+1
    lda sfr_dst_lo
    clc
    adc sfr_mv_cnt_lo
    sta LPTR
    lda sfr_dst_hi
    adc sfr_mv_cnt_hi
    sta LPTR+1
@loop:
    ; Pre-decrement both pointers, copy one byte, then count down.
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    lda LPTR
    bne :+
    dec LPTR+1
:   dec LPTR
    ldy #0
    lda (WORK_PTR),y
    sta (LPTR),y
    lda sfr_mv_cnt_lo
    bne :+
    dec sfr_mv_cnt_hi
:   dec sfr_mv_cnt_lo
    lda sfr_mv_cnt_lo
    ora sfr_mv_cnt_hi
    bne @loop
@done:
    rts

; =============================================================================
; sfr_vbyte — virtual byte at sfr_voff_lo/hi.  Uses LPTR for dereference.
; =============================================================================
sfr_vbyte:
    lda sfr_voff_hi
    cmp sfr_pre_hi
    bcc @pre
    bne @post
    lda sfr_voff_lo
    cmp sfr_pre_lo
    bcc @pre
@post:
    lda sfr_voff_lo
    sec
    sbc sfr_pre_lo
    sta sfr_tmp_lo
    lda sfr_voff_hi
    sbc sfr_pre_hi
    sta sfr_tmp_hi
    lda sfr_tmp_lo
    clc
    adc sfr_ge_lo
    sta LPTR
    lda sfr_tmp_hi
    adc sfr_ge_hi
    sta LPTR+1
    jmp @load
@pre:
    lda sfr_buf_lo
    clc
    adc sfr_voff_lo
    sta LPTR
    lda sfr_buf_hi
    adc sfr_voff_hi
    sta LPTR+1
@load:
    ldy #0
    lda (LPTR),y
    rts

; =============================================================================
; sfr_fold — PETSCII lowercase→uppercase for case-insensitive compare
; =============================================================================
sfr_fold:
    cmp #$61
    bcc @done
    cmp #$7B
    bcs @done
    sec
    sbc #$20
@done:
    rts

; =============================================================================
; Screen drawing
; =============================================================================
sfr_draw_chrome:
    lda sfr_case_mode
    beq @useC
    lda #SC_I
    jmp @tog
@useC:
    lda #SC_C
@tog:
    sta sfr_toggle_sc
    ; Row 1
    lda #SC_LBRACKET
    sta ROW1_SCR+0
    lda sfr_toggle_sc
    sta ROW1_SCR+1
    lda #SC_RBRACKET
    sta ROW1_SCR+2
    lda #SC_SPACE
    sta ROW1_SCR+3
    lda #SC_F
    sta ROW1_SCR+4
    lda #SC_I
    sta ROW1_SCR+5
    lda #SC_N
    sta ROW1_SCR+6
    lda #SC_D
    sta ROW1_SCR+7
    lda #SC_COLON
    sta ROW1_SCR+8
    lda #SC_SPACE
    sta ROW1_SCR+9
    sta ROW1_SCR+10
    sta ROW1_SCR+11
    sta ROW1_SCR+12
    sta ROW1_SCR+13
    ; Row 2
    lda #SC_LBRACKET
    sta ROW2_SCR+0
    lda sfr_toggle_sc
    sta ROW2_SCR+1
    lda #SC_RBRACKET
    sta ROW2_SCR+2
    lda #SC_SPACE
    sta ROW2_SCR+3
    lda #SC_R
    sta ROW2_SCR+4
    lda #SC_E
    sta ROW2_SCR+5
    lda #SC_P
    sta ROW2_SCR+6
    lda #SC_L
    sta ROW2_SCR+7
    lda #SC_A
    sta ROW2_SCR+8
    lda #SC_C
    sta ROW2_SCR+9
    lda #SC_E
    sta ROW2_SCR+10
    lda #SC_COLON
    sta ROW2_SCR+11
    lda #SC_SPACE
    sta ROW2_SCR+12
    sta ROW2_SCR+13
    ; Colors cols 0-13
    ldy #0
@cl:
    lda #COL_CHROME
    cpy #1
    bne @sc
    lda #COL_TOGGLE_ON
@sc:
    sta ROW1_COL,y
    sta ROW2_COL,y
    iny
    cpy #CHROME_COLS
    bne @cl
    rts

sfr_draw_toggle:
    lda sfr_case_mode
    beq @C
    lda #SC_I
    jmp @w
@C:
    lda #SC_C
@w:
    sta ROW1_SCR+1
    sta ROW2_SCR+1
    rts

; sfr_pet2scr — convert PETSCII byte in A to C64 screen code.
;   $20-$3F: no change (digits, space, punctuation)
;   $40-$5F: subtract $40  (A-Z → screen codes $01-$1A)
;   $60-$7F: subtract $20  (a-z → screen codes $41-$5A in lowercase charset)
sfr_pet2scr:
    cmp #$40
    bcc @done               ; $20-$3F: already correct
    cmp #$60
    bcs @lo
    sec                     ; $40-$5F: subtract $40
    sbc #$40
    rts
@lo:
    sec                     ; $60-$7F: subtract $20
    sbc #$20
@done:
    rts

sfr_draw_find_field:
    ldy #0
@clr:
    cpy #INPUT_COLS
    beq @fill
    lda #SC_SPACE
    sta ROW1_SCR+CHROME_COLS,y
    lda #COL_INPUT
    sta ROW1_COL+CHROME_COLS,y
    iny
    bne @clr
@fill:
    ldy #0
@ch:
    cpy sfr_find_len
    beq @cur
    lda sfr_find_buf,y
    jsr sfr_pet2scr         ; PETSCII → screen code
    sta ROW1_SCR+CHROME_COLS,y
    lda #COL_INPUT
    sta ROW1_COL+CHROME_COLS,y
    iny
    cpy #INPUT_COLS
    bcc @ch
@cur:
    lda sfr_cur_field
    bne @done
    cpy #INPUT_COLS
    bcs @done
    lda #SC_UNDERSCORE
    sta ROW1_SCR+CHROME_COLS,y
    lda #COL_CURSOR_CHAR
    sta ROW1_COL+CHROME_COLS,y
@done:
    rts

sfr_draw_repl_field:
    ldy #0
@clr:
    cpy #INPUT_COLS
    beq @fill
    lda #SC_SPACE
    sta ROW2_SCR+CHROME_COLS,y
    lda #COL_INPUT
    sta ROW2_COL+CHROME_COLS,y
    iny
    bne @clr
@fill:
    ldy #0
@ch:
    cpy sfr_repl_len
    beq @cur
    lda sfr_repl_buf,y
    jsr sfr_pet2scr         ; PETSCII → screen code
    sta ROW2_SCR+CHROME_COLS,y
    lda #COL_INPUT
    sta ROW2_COL+CHROME_COLS,y
    iny
    cpy #INPUT_COLS
    bcc @ch
@cur:
    lda sfr_cur_field
    beq @done               ; cursor is in FIND row
    cpy #INPUT_COLS
    bcs @done
    lda #SC_UNDERSCORE
    sta ROW2_SCR+CHROME_COLS,y
    lda #COL_CURSOR_CHAR
    sta ROW2_COL+CHROME_COLS,y
@done:
    rts

sfr_flash_found:
    ldy #0
@wr:
    lda sfr_msg_found,y
    beq @wait
    sta ROW0_SCR,y
    lda #COL_FOUND
    sta ROW0_COL,y
    iny
    bne @wr
@wait:
    lda JIFFY_LO
    clc
    adc #45
    sta sfr_jtmp
@sp:
    lda JIFFY_LO
    cmp sfr_jtmp
    bne @sp
    ; Status bar stays "FOUND" until module exits — editor restores it then.
    rts

sfr_flash_not_found:
    ldy #0
@wr:
    lda sfr_msg_nf,y
    beq @wait
    sta ROW0_SCR,y
    lda #COL_NOT_FOUND
    sta ROW0_COL,y
    iny
    bne @wr
@wait:
    lda JIFFY_LO
    clc
    adc #45
    sta sfr_jtmp
@sp:
    lda JIFFY_LO
    cmp sfr_jtmp
    bne @sp
    ; Status bar stays "NOT FOUND" until module exits — editor restores it then.
    rts

sfr_flash_full:
    ldy #0
@wr:
    lda sfr_msg_full,y
    beq @wait
    sta ROW0_SCR,y
    lda #COL_NOT_FOUND
    sta ROW0_COL,y
    iny
    bne @wr
@wait:
    lda JIFFY_LO
    clc
    adc #45
    sta sfr_jtmp
@sp:
    lda JIFFY_LO
    cmp sfr_jtmp
    bne @sp
    ; Status bar stays "BUFFER FULL" until module exits — editor restores it.
    rts

sfr_msg_found:
    .byte $06,$0F,$15,$0E,$04,$20,$20,$20,$20,$20,$20, 0   ; FOUND
sfr_msg_nf:
    .byte $0E,$0F,$14,$20,$06,$0F,$15,$0E,$04,$20,$20, 0   ; NOT FOUND
sfr_msg_full:
    .byte $02,$15,$06,$06,$05,$12,$20,$06,$15,$0C,$0C, 0   ; BUFFER FULL

; =============================================================================
.segment "BSS"

sfr_buf_lo:     .res 1
sfr_buf_hi:     .res 1
sfr_gs_lo:      .res 1
sfr_gs_hi:      .res 1
sfr_ge_lo:      .res 1
sfr_ge_hi:      .res 1
sfr_be_lo:      .res 1
sfr_be_hi:      .res 1
sfr_pre_lo:     .res 1
sfr_pre_hi:     .res 1
sfr_total_lo:   .res 1
sfr_total_hi:   .res 1

sfr_find_buf:   .res FIND_MAXLEN+1
sfr_find_len:   .res 1
sfr_repl_buf:   .res REPL_MAXLEN+1
sfr_repl_len:   .res 1

sfr_case_mode:  .res 1
sfr_cur_field:  .res 1
sfr_have_match: .res 1
sfr_did_move:   .res 1

sfr_match_lo:   .res 1
sfr_match_hi:   .res 1
sfr_srch_lo:    .res 1
sfr_srch_hi:    .res 1

sfr_i_lo:       .res 1
sfr_i_hi:       .res 1
sfr_j:          .res 1
sfr_voff_lo:    .res 1
sfr_voff_hi:    .res 1
sfr_tmp_lo:     .res 1
sfr_tmp_hi:     .res 1
sfr_tmp_val:    .res 1

sfr_src_lo:     .res 1
sfr_src_hi:     .res 1
sfr_dst_lo:     .res 1
sfr_dst_hi:     .res 1
sfr_mv_sz_lo:   .res 1
sfr_mv_sz_hi:   .res 1
sfr_mv_cnt_lo:  .res 1
sfr_mv_cnt_hi:  .res 1

sfr_toggle_sc:  .res 1
sfr_jtmp:       .res 1
