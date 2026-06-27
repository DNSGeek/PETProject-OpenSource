; ============================================================================
; modules.asm — Module loader framework for PETProject
;
; Included by editor.asm. Provides the F8 module picker popup and
; module load/call infrastructure.
;
; Loader strategy: standard Kernal LOAD ($FFD5) with A=0 so the PRG file's
; load address determines where the module is placed.  Each module's
; linker config (module.cfg / modscr.cfg) puts CODE at $C000 or $A000 with
; a matching 2-byte LOADADDR segment, so the entry point is the first byte
; of the file's content (no header offset).  A fastloader cartridge or
; JiffyDOS transparently accelerates LOAD; no resident driver of our own.
;
; Bank switching is only needed around module *execution*, not the load
; itself: writes to $A000-$BFFF always go to underlying RAM regardless of
; $01.  $A000 modules execute with $01=$36 (BASIC out, kernal in);
; $C000 modules execute with normal $37.
;
; Parameter block at $0212-$0222 (page 2, after warm boot block):
;   $0212  MOD_MAGIC        $4D = valid
;   $0213  MOD_COMMAND      0 = run interactive
;   $0214  MOD_BUF_LO       work_buf lo
;   $0215  MOD_BUF_HI       work_buf hi
;   $0216  MOD_GAP_START_LO
;   $0217  MOD_GAP_START_HI
;   $0218  MOD_GAP_END_LO
;   $0219  MOD_GAP_END_HI
;   $021A  MOD_BUF_END_LO   work_buf_end lo
;   $021B  MOD_BUF_END_HI   work_buf_end hi
;   $021C  MOD_DRIVE        device number
;   $021D  MOD_DIALECT      0 = BASIC 2
;   $021E  MOD_STATUS       module writes result here
;   $021F  MOD_NEW_END_LO   new content end lo (if MOD_STATUS=$02)
;   $0220  MOD_NEW_END_HI   new content end hi
;   $0221  MOD_LOAD_LO      load address of this module (lo)
;   $0222  MOD_LOAD_HI      load address of this module (hi)
;
; MOD_STATUS values:
;   $00  OK, buffer unchanged
;   $01  Error
;   $02  Buffer replaced — editor resets gap from MOD_NEW_END
;   $03  Output written to disk
;   $04  Gap repositioned (MODSFR) or filename written (MODDSK)
;   $05  MODSCT: tokenization to REU succeeded
;
; Required additions in editor.asm:
;
;   Main loop: change KEY_F8 handler to "jmp @do_modules"
;   Add: @do_modules: jsr do_modules_popup / jmp main_loop
;   Update status_text to include "F8=MOD"
;   After .include "loadsave.asm": .include "modules.asm"
;
;   .segment "BSS":
;     MOD_LOADED:            .res 1
;     SETTING_TOKENIZE_SAVE: .res 1
;     MOD_SEL_ROW:           .res 1
;     MOD_ITEM_TMP:          .res 1   ; item index scratch (distinct from MOD_TMP)
;     MOD_TMP:               .res 1   ; general popup scratch
;
;   init_settings: lda #$FF / sta MOD_LOADED / lda #0 / sta SETTING_TOKENIZE_SAVE
; ============================================================================

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
MOD_LOAD_LO      = $0221             ; load address for this module (lo)
MOD_LOAD_HI      = $0222             ; load address for this module (hi)
MOD_SAVED_SP     = $0227             ; SP saved across module call (avoids stack overflow)

MOD_MAGIC_VAL    = $4D
MOD_LOAD_ADDR    = $C000
MOD_LA           = 3                 ; logical file number for module load

; Popup geometry
MPOP_TOP         = 3                 ; top row of box (avoids status row 0)
MPOP_LEFT        = 1
MPOP_WIDTH       = 36                ; inner width (cols 2..38, bars at 1 and 39)
MPOP_INNER_LEFT  = 2                 ; first text column inside box
MPOP_NUM_ITEMS   = 5
MPOP_ITEM_ROW0   = (MPOP_TOP + 3)   ; screen row of first item (title at TOP+1, blank at TOP+2)
; Module load-address holding bytes — survive across kernal LOAD.
; These are normal ZP locations not touched by LOAD's internal use.
MOD_LOAD_SAVE_LO = $38
MOD_LOAD_SAVE_HI = $39

; ============================================================================
; Module table — filenames and description strings
; ============================================================================

; 6-byte PETSCII filenames (exact, no padding needed for SETNAM).
; MODSCRH is the only 7-byte name; mod_fname_lens carries the per-entry length.
;
; Index   Name      Visibility / invoker
;   0     MODASM    visible (F8 popup row 0) — assemble
;   1     MODDIS    visible (F8 popup row 1) — disassemble
;   2     MODREN    visible (F8 popup row 2) — BASIC renumber
;   3     MODDSK    visible (F8 popup row 3) — disk utility
;   4     MODDET    hidden — called by loadsave.asm (detokenize on load)
;   5     MODTOK    hidden — called by loadsave.asm (tokenize on save)
;   6     MODSFR    hidden — called by CTRL+F (search/replace)
;   7     MODSCT    hidden — called by do_run_script phase 1 (script tokenize)
;   8     MODSCRH   hidden — called by do_run_script phase 2 (script handler)
;   9     MODSCR    hidden — called by do_run_script phase 3 (script runner)
;
; F8 popup row 4 is "RUN SCRIPT" which routes to do_run_script, not a single
; module load — so it doesn't appear in this table.
mod_fname_lens: .byte 6, 6, 6, 6, 6, 6, 6, 6, 7, 6

mod_fname_0: .byte $4D,$4F,$44,$41,$53,$4D  ; MODASM
mod_fname_1: .byte $4D,$4F,$44,$44,$49,$53  ; MODDIS
mod_fname_2: .byte $4D,$4F,$44,$52,$45,$4E  ; MODREN
mod_fname_3: .byte $4D,$4F,$44,$44,$53,$4B  ; MODDSK
mod_fname_4: .byte $4D,$4F,$44,$44,$45,$54  ; MODDET
mod_fname_5: .byte $4D,$4F,$44,$54,$4F,$4B  ; MODTOK
mod_fname_6: .byte $4D,$4F,$44,$53,$46,$52  ; MODSFR
mod_fname_7: .byte $4D,$4F,$44,$53,$43,$54  ; MODSCT
mod_fname_8: .byte $4D,$4F,$44,$53,$43,$52,$48  ; MODSCRH (7 chars)
mod_fname_9: .byte $4D,$4F,$44,$53,$43,$52  ; MODSCR

mod_fname_lo: .byte <mod_fname_0, <mod_fname_1, <mod_fname_2, <mod_fname_3, <mod_fname_4, <mod_fname_5, <mod_fname_6, <mod_fname_7, <mod_fname_8, <mod_fname_9
mod_fname_hi: .byte >mod_fname_0, >mod_fname_1, >mod_fname_2, >mod_fname_3, >mod_fname_4, >mod_fname_5, >mod_fname_6, >mod_fname_7, >mod_fname_8, >mod_fname_9

; Load addresses: MODASM, MODDIS, MODSCT, MODSCR at $A000; MODSCRH and all others at $C000.
mod_load_lo: .byte <$A000, <$A000, <$C000, <$C000, <$C000, <$C000, <$C000, <$A000, <$C000, <$A000
mod_load_hi: .byte >$A000, >$A000, >$C000, >$C000, >$C000, >$C000, >$C000, >$A000, >$C000, >$A000

; Description strings — C64 screen codes, zero-terminated
; Letters: A=$01 B=$02 C=$03 D=$04 E=$05 F=$06 G=$07 H=$08 I=$09
;          J=$0A K=$0B L=$0C M=$0D N=$0E O=$0F P=$10 Q=$11 R=$12
;          S=$13 T=$14 U=$15 V=$16 W=$17 X=$18 Y=$19 Z=$1A  Space=$20

mod_desc_0:
    .byte $01,$13,$13,$05,$0D,$02,$0C,$05, 0
    ; ASSEMBLE

mod_desc_1:
    .byte $04,$09,$13,$01,$13,$13,$05,$0D,$02,$0C,$05, 0
    ; DISASSEMBLE

mod_desc_2:
    .byte $12,$05,$0E,$15,$0D,$02,$05,$12, 0
    ; RENUMBER

mod_desc_3:
    .byte $04,$09,$13,$0B,$20,$15,$14,$09,$0C,$09,$14,$19, 0
    ; DISK UTILITY

mod_desc_4:
    .byte $12,$15,$0E,$20,$13,$03,$12,$09,$10,$14, 0
    ; RUN SCRIPT  (R=$12 U=$15 N=$0E sp=$20 S=$13 C=$03 R=$12 I=$09 P=$10 T=$14)
    ; Note: selecting this item calls do_run_script, not run_module_by_index(4).
    ; Index 4 in the fname table (MODDET) is still invoked directly by loadsave.asm.

mod_desc_5: .byte 0   ; MODDET — hidden, no display string needed
mod_desc_6: .byte 0   ; MODTOK — hidden, no display string needed
mod_desc_7: .byte 0   ; MODSFR — hidden, no display string needed
mod_desc_8: .byte 0   ; MODSCT — hidden, no display string needed
mod_desc_9: .byte 0   ; MODSCR — hidden, no display string needed

mod_desc_lo: .byte <mod_desc_0, <mod_desc_1, <mod_desc_2, <mod_desc_3, <mod_desc_4, <mod_desc_5, <mod_desc_6, <mod_desc_7, <mod_desc_8, <mod_desc_9
mod_desc_hi: .byte >mod_desc_0, >mod_desc_1, >mod_desc_2, >mod_desc_3, >mod_desc_4, >mod_desc_5, >mod_desc_6, >mod_desc_7, >mod_desc_8, >mod_desc_9

; ============================================================================
; do_modules_popup — F8 handler entry point
; ============================================================================

; ============================================================================
; do_search_replace — CTRL+F handler: load MODSFR and run it.
; On return the editor's gap/cursor may have moved (MOD_STATUS=$04).
; The caller (@do_search in main_loop) jumps straight back to main_loop;
; all viewport refresh is handled here before returning.
; ============================================================================
do_search_replace:
    ldx #6                      ; MODSFR is index 6 in the module tables
    jsr run_module_by_index
    ; run_module_by_index already handled $04 (gap updated from param block).
    ; Now ensure the cursor is on screen and redraw.
    jsr ensure_cursor_visible
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
    rts

; ============================================================================
; do_run_script — F8 "RUN SCRIPT" handler (also callable from a key binding).
;
; Phase 1: MODSCT  (index 7) — tokenize script + includes → REU. Returns $05.
; Phase 2: MODSCRH (index 8) — load handler to $C000 via module loader.
;          execute stub returns $00; code stays resident.
; Phase 3: MODSCR  (index 9) — stash IDE, patch BASIC vectors, hand off.
;          On script completion MODSCRH restores IDE; run_module_by_index
;          returns here via the saved stack frame.
;
; run_module_by_index already shows MODULE ERROR for any $01 return,
; so we just bail on any non-expected status.
; ============================================================================
do_run_script:
    ; Phase 1: tokenize script to REU
    ldx #7                      ; MODSCT
    jsr run_module_by_index
    lda MOD_STATUS
    cmp #$05                    ; $05 = tokenized OK
    bne @done                   ; error already shown by run_module_by_index

    ; Phase 2: load MODSCRH handler to $C000
    ldx #8                      ; MODSCRH
    jsr run_module_by_index
    lda MOD_STATUS
    cmp #$00                    ; $00 = stub ran OK, handler resident
    bne @done

    ; Phase 3: stash IDE, deploy script, run BASIC
    ldx #9                      ; MODSCR
    jsr run_module_by_index
    ; IDE is now fully restored. Re-render editor.
    jsr ensure_cursor_visible
    jsr render_status
    jsr render_viewport
    jsr draw_cursor

@done:
    rts

; ============================================================================
; do_modules_popup — F8 handler entry point
; ============================================================================
do_modules_popup:
    lda #0
    sta MOD_SEL_ROW

    jsr mpop_draw_all

@flush:
    jsr GETIN
    bne @flush

@loop:
    jsr GETIN
    beq @loop

    cmp #KEY_F8
    beq @close
    cmp #PET_STOP
    beq @close

    cmp #KEY_CRSR_UP
    bne @try_dn
    lda MOD_SEL_ROW
    beq @wrap_bot
    dec MOD_SEL_ROW
    jmp @redraw
@wrap_bot:
    lda #(MPOP_NUM_ITEMS - 1)
    sta MOD_SEL_ROW
    jmp @redraw

@try_dn:
    cmp #KEY_CRSR_DN
    bne @try_ret
    lda MOD_SEL_ROW
    cmp #(MPOP_NUM_ITEMS - 1)
    beq @wrap_top
    inc MOD_SEL_ROW
    jmp @redraw
@wrap_top:
    lda #0
    sta MOD_SEL_ROW

@redraw:
    jsr mpop_draw_items_only        ; redraw just the item rows — no need to redraw box
    jmp @loop

@try_ret:
    cmp #PET_CR
    bne @loop
    jsr run_selected_module
    jmp @restore

@close:
@restore:
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
    rts

; ============================================================================
; mpop_draw_all — draw box + title + all items
; ============================================================================

mpop_draw_all:
    jsr mpop_draw_box
    jsr mpop_draw_title
    jsr mpop_draw_items_only
    rts

; ============================================================================
; mpop_draw_items_only — redraw just the 5 item rows
; ============================================================================

mpop_draw_items_only:
    lda #0
@loop:
    sta MOD_ITEM_TMP
    jsr mpop_draw_item              ; A = item index
    lda MOD_ITEM_TMP
    clc
    adc #1
    cmp #MPOP_NUM_ITEMS
    bne @loop
    rts

; ============================================================================
; mpop_draw_box — draw PETSCII border, rows MPOP_TOP .. MPOP_TOP+8
; Box has: title row, blank row, 5 item rows, blank row = 8 inner rows + 2 borders
; ============================================================================

mpop_draw_box:
    ; Top border row
    lda #MPOP_TOP
    jsr mpop_row_ptr
    ldy #MPOP_LEFT
    lda #$70                        ; top-left corner
    sta (WORK_PTR),y
    iny
@top_bar:
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1)
    beq @top_right
    lda #$40
    sta (WORK_PTR),y
    iny
    bne @top_bar
@top_right:
    lda #$6E                        ; top-right corner
    sta (WORK_PTR),y
    lda #MPOP_TOP
    jsr mpop_color_chrome

    ; Side borders: rows MPOP_TOP+1 .. MPOP_TOP+8
    lda #(MPOP_TOP + 1)
    sta MOD_TMP
@sides:
    lda MOD_TMP
    cmp #(MPOP_TOP + 8)
    beq @bot_border
    jsr mpop_row_ptr
    ldy #MPOP_LEFT
    lda #$5D
    sta (WORK_PTR),y
    ldy #(MPOP_LEFT + MPOP_WIDTH + 1)
    sta (WORK_PTR),y
    ; Clear inner content of this row
    ldy #(MPOP_LEFT + 1)
    lda #$20
@clr:
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1)
    beq @clr_done
    sta (WORK_PTR),y
    iny
    bne @clr
@clr_done:
    lda MOD_TMP
    jsr mpop_color_chrome
    inc MOD_TMP
    jmp @sides

@bot_border:
    lda #(MPOP_TOP + 8)
    jsr mpop_row_ptr
    ldy #MPOP_LEFT
    lda #$6D                        ; bot-left
    sta (WORK_PTR),y
    iny
@bot_bar:
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1)
    beq @bot_right
    lda #$40
    sta (WORK_PTR),y
    iny
    bne @bot_bar
@bot_right:
    lda #$7D
    sta (WORK_PTR),y
    lda #(MPOP_TOP + 8)
    jsr mpop_color_chrome
    rts

; ============================================================================
; mpop_draw_title — row MPOP_TOP+1
; ============================================================================

mpop_draw_title:
    lda #(MPOP_TOP + 1)
    jsr mpop_row_ptr
    ldy #MPOP_INNER_LEFT
    ldx #0
@loop:
    lda mpop_title_text,x
    beq @done
    sta (WORK_PTR),y
    iny
    inx
    bne @loop
@done:
    lda #(MPOP_TOP + 1)
    jsr mpop_color_white
    rts

mpop_title_text:
    ; "MODULES   F8=CLOSE" in screen codes
    .byte $0D,$0F,$04,$15,$0C,$05,$13,$20,$20,$20
    .byte $06,$38,$3D,$03,$0C,$0F,$13,$05, 0
    ; F8 screen code: $06=F $38=8 (digit 8 = $38) $3D==

; ============================================================================
; mpop_draw_item — draw one item row. A = item index (0..4).
; Uses LPTR for description pointer. Preserves MOD_ITEM_TMP.
; Screen row for item A = MPOP_ITEM_ROW0 + A
; ============================================================================

mpop_draw_item:
    ; Stash item index — we'll need it multiple times
    pha                             ; [stack: item_index]

    ; Compute screen row = MPOP_ITEM_ROW0 + item_index
    clc
    adc #MPOP_ITEM_ROW0
    jsr mpop_row_ptr                ; WORK_PTR = screen addr of this row
                                    ; (mpop_row_ptr clobbers A, X but not stack)
    pla                             ; restore item_index
    pha                             ; keep a copy on stack

    tax                             ; X = item index

    ; Clear inner content of this row first
    ldy #(MPOP_LEFT + 1)
    lda #$20
@clr_row:
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1)
    beq @clr_done
    sta (WORK_PTR),y
    iny
    bne @clr_row
@clr_done:

    ; Draw "N. " prefix at MPOP_INNER_LEFT
    ldy #MPOP_INNER_LEFT
    txa
    clc
    adc #$31                        ; screen code for '1'..'5' ($31..$35)
    sta (WORK_PTR),y
    iny
    lda #$2E                        ; '.' screen code
    sta (WORK_PTR),y
    iny
    lda #$20                        ; space
    sta (WORK_PTR),y
    iny                             ; Y = MPOP_INNER_LEFT + 3 = first desc char column

    ; Point LPTR at description string for this item
    lda mod_desc_lo,x
    sta LPTR
    lda mod_desc_hi,x
    sta LPTR+1

    ; Draw description — Y is the screen column, advances as we write
    ; LPTR index via a separate counter in X (reuse X, we're done with item index for now)
    ldx #0
@desc_loop:
    lda (LPTR,x)                    ; read desc byte — X=0 so this is (LPTR),0
    ; ca65: (LPTR,x) with X=0 is indexed indirect, not what we want.
    ; Use (LPTR),y won't work since Y is the screen col.
    ; Solution: use a temp register. Save Y, use Y=0 to read, restore Y.
    sty MOD_TMP                     ; save screen col in MOD_TMP
    ldy #0
    lda (LPTR),y                    ; read next desc byte
    tax                             ; preserve in X — ldy would clobber Z flag
    ldy MOD_TMP                     ; restore screen col (clobbers flags)
    txa                             ; restore A and set Z correctly
    beq @desc_done                  ; zero terminator

    sta (WORK_PTR),y                ; write to screen RAM
    iny                             ; advance screen col
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1) ; don't overflow row
    beq @desc_done

    ; Advance LPTR by 1
    inc LPTR
    bne @desc_loop
    inc LPTR+1
    jmp @desc_loop

@desc_done:
    ; Pad remainder of row with spaces so no stale chars remain
    lda #$20
@pad:
    cpy #(MPOP_LEFT + MPOP_WIDTH + 1)
    beq @pad_done
    sta (WORK_PTR),y
    iny
    bne @pad
@pad_done:
    ; Color this row: white if selected, chrome otherwise
    pla                             ; restore item_index
    clc
    adc #MPOP_ITEM_ROW0             ; screen row of this item
    sta MOD_TMP                     ; stash screen row
    ; Compare item_index (A - MPOP_ITEM_ROW0) with MOD_SEL_ROW
    sec
    sbc #MPOP_ITEM_ROW0             ; back to item_index
    cmp MOD_SEL_ROW
    bne @chrome
    lda MOD_TMP
    jsr mpop_color_white
    rts
@chrome:
    lda MOD_TMP
    jsr mpop_color_chrome
    rts

; ============================================================================
; run_selected_module — F8 popup entry: load X from MOD_SEL_ROW, delegate.
; ============================================================================

run_selected_module:
    ; Row 4 = RUN SCRIPT — handled by do_run_script, not a single module load.
    lda MOD_SEL_ROW
    cmp #4
    bne @normal
    jsr do_run_script
    rts
@normal:
    ldx MOD_SEL_ROW
    jsr run_module_by_index

    ; run_module_by_index has ALREADY handled the gap/viewport for $02 (buffer
    ; replaced) and $04 (gap repositioned). Do NOT re-handle $02 here: a second
    ; gap reset previously set a zero-size gap at work_buf, which do_insert
    ; treats as "full" — silently dropping every keystroke after a renumber.
    ;
    ; We only need to handle the cases run_module_by_index does not: $04 here
    ; means MODDSK wants the editor to load a file (its own convention, distinct
    ; from the gap-reposition $04 that run_module_by_index consumes for other
    ; modules — MODDSK sets FNAME_BUF/LEN), and error reporting.
    lda MOD_STATUS
    cmp #$02
    beq @done                   ; buffer replace fully handled downstream

    cmp #$04
    bne @check_err
    ; $04 — MODDSK set FNAME_BUF/LEN: ask editor to load the file
    jsr do_load_file_from_fname
    rts

@check_err:
    lda MOD_STATUS
    cmp #$FF                ; module never set status
    beq @show_err
    cmp #$01
    beq @show_err
@done:
    rts
@show_err:
    jsr mpop_show_error
    rts

; ============================================================================
; run_module_by_index — populate params, load and call module X.
;
; X = module index (0=MODDET, 1=MODTOK, 2=MODASM, 3=MODDIS, 4=MODREN).
; On return: MOD_STATUS set by module.
; Clobbers: A, X, Y, LPTR, FNAME_BUF, FNAME_LEN.
; Safe to call from load/save context — no I/O left open on entry or exit.
; ============================================================================

run_module_by_index:
    ; In: X = module index (0..9)
    ;
    ; NOTE: Do NOT populate MOD_BUF/GAP/STATUS here.
    ; The kernal LOAD routine uses page-2 ZP and may also touch FN/IO
    ; areas; the param block at $0212-$0222 is filled at run_sel_loaded,
    ; after the load completes, so the module always sees correct buffer
    ; geometry.

    ; Save module index — we need it again after SETLFS clobbers X.
    stx MOD_TMP

    ; Stash module load address.  These two BSS bytes are NOT touched by
    ; any kernal call (they live at $38/$39 = LPTR/WORK_PTR area; nothing
    ; in kernal LOAD uses these specifically — they're our ZP).
    lda mod_load_lo,x
    sta MOD_LOAD_SAVE_LO
    lda mod_load_hi,x
    sta MOD_LOAD_SAVE_HI

    lda #$FF
    sta MOD_STATUS              ; pre-mark as incomplete

    ; MODDSK shim parameters at $0223-$0226: where MODDSK should write
    ; the chosen filename when it returns MOD_STATUS=$04.
    lda #<FNAME_BUF
    sta $0223                   ; DSK_FNAME_BUF_LO
    lda #>FNAME_BUF
    sta $0224                   ; DSK_FNAME_BUF_HI
    lda #<FNAME_LEN
    sta $0225                   ; DSK_FNAME_LEN_LO
    lda #>FNAME_LEN
    sta $0226                   ; DSK_FNAME_LEN_HI

    ; ---- Module load via Kernal LOAD ($FFD5) ----
    ; Module binaries always load from drive 8 (where PETPROJECT is booted).
    ; Each module's PRG header carries its correct load address ($A000 or
    ; $C000), so LOAD with A=0 places it where it belongs.
    ;
    ; Writes to $A000-$BFFF always go to underlying RAM regardless of $01,
    ; so for $A000 modules we do NOT need to bank BASIC out for the load
    ; itself — only for execution.  No SEI/CLI dance, no bank fiddling.
    ; Any fastloader cartridge / JiffyDOS transparently accelerates LOAD.

    ; ---- SETLFS: LA=MOD_LA, device=8, SA=1 (use PRG header load addr) ----
    ; SA convention for LOAD:
    ;   SA=0 → ignore PRG header, use X/Y as load address
    ;   SA=1 → use PRG header's load address (what we want for modules)
    lda #MOD_LA
    ldx #8
    ldy #1
    jsr SETLFS

    ; ---- SETNAM: filename pointer from module table ----
    ldx MOD_TMP                 ; restore module index
    lda mod_fname_lens,x        ; A = filename length
    ldy mod_fname_hi,x          ; Y = filename ptr hi
    pha
    lda mod_fname_lo,x          ; A = filename ptr lo
    tax                         ; X = filename ptr lo
    pla                         ; A = filename length
    jsr SETNAM

    ; ---- LOAD: A=0 → load (not verify); SA=1 from SETLFS uses PRG header ----
    lda #0
    jsr LOAD
    bcc :+
    jmp run_sel_load_err        ; bcs branch was out of range (>127 bytes)
:
    jmp run_sel_loaded

run_sel_loaded:
    ; ---- Populate param block HERE (after all kernal I/O) ----
    ; Kernal LOAD touches page-2 areas during its work.  Filling the param
    ; block after the load completes ensures the module sees correct
    ; buffer geometry.
    lda #MOD_MAGIC_VAL
    sta MOD_MAGIC
    lda #0
    sta MOD_COMMAND
    sta MOD_DIALECT

    lda #<work_buf
    sta MOD_BUF_LO
    lda #>work_buf
    sta MOD_BUF_HI

    lda GAP_START
    sta MOD_GAP_START_LO
    lda GAP_START+1
    sta MOD_GAP_START_HI

    lda GAP_END
    sta MOD_GAP_END_LO
    lda GAP_END+1
    sta MOD_GAP_END_HI

    lda #<work_buf_end
    sta MOD_BUF_END_LO
    lda #>work_buf_end
    sta MOD_BUF_END_HI

    lda SETTING_DRIVE
    sta MOD_DRIVE

    lda #$FF
    sta MOD_STATUS

    ; ---- Set up LPTR for the indirect JMP to the module entry point ----
    ; With Kernal LOAD, the load address IS the module's entry point —
    ; there's no PRG header sitting at the load address (LOAD stripped it).
    ; So we use the stashed load address directly, no +2 skip.
    lda MOD_LOAD_SAVE_LO
    sta LPTR
    sta MOD_LOAD_LO
    lda MOD_LOAD_SAVE_HI
    sta LPTR+1
    sta MOD_LOAD_HI

    ; ---- Bank-switch for execution only ----
    ; $A000 modules need BASIC ROM out so their code is visible.
    ; Reads from $A000-$BFFF go to RAM when $01 = $36 (BASIC out, kernal in).
    lda LPTR+1
    cmp #$A0
    bne @no_page_out
    lda $00
    ora #$07
    sta $00
    lda #$36                ; BASIC RAM, Kernal ROM, I/O
    sta $01
@no_page_out:
    jsr mod_call_trampoline
    lda LPTR+1
    cmp #$A0
    bne @no_page_in
    lda #$37                ; normal: BASIC ROM, Kernal ROM, I/O
    sta $01
@no_page_in:
    ; Handle return status
    lda MOD_STATUS
    cmp #$02
    bne @check_reposition

    ; Buffer replaced. The module wrote linear content from work_buf up to
    ; MOD_NEW_END, with free space above. In this editor the cursor IS
    ; GAP_START, so the gap must be placed at the cursor position with real
    ; free space in it (GAP_START must NOT equal GAP_END — do_insert treats an
    ; empty gap as "full" and silently drops the keystroke).
    ;
    ; We place the gap at the END of the content: GAP_START = MOD_NEW_END,
    ; GAP_END = work_buf_end. The content (work_buf .. MOD_NEW_END) is all
    ; pre-gap; the cursor lands at the end of the renumbered text, which is the
    ; natural place to resume editing. ensure_cursor_visible (run on the next
    ; redraw) scrolls so the cursor is on screen.
    ;
    ; Place the gap at MOD_NEW_END. Content occupies work_buf..MOD_NEW_END-1;
    ; the gap (free space) runs from MOD_NEW_END to work_buf_end. BUF_PTR is
    ; set equal to GAP_START so buf_ptr_warp fires immediately in render_viewport
    ; and the renderer sees EOF at the correct position.
    lda MOD_NEW_END_LO
    sta GAP_START
    sta BUF_PTR
    lda MOD_NEW_END_HI
    sta GAP_START+1
    sta BUF_PTR+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    ; The gap (= cursor) is at the end of the renumbered content. Reconcile the
    ; viewport NOW so the displayed cursor matches the real position on the
    ; first redraw — otherwise the cursor is drawn at row 0 and then snaps to
    ; the true position on the user's first keypress (a visible jump).
    ; Start TOP_LINE at the top of the document; ensure_cursor_visible scrolls
    ; down as needed and computes CURSOR_ROW/COL to match GAP_START.
    lda #<work_buf
    sta TOP_LINE
    lda #>work_buf
    sta TOP_LINE+1
    lda #0
    sta LEFT_COL
    sta CURSOR_ROW
    sta CURSOR_COL
    jsr ensure_cursor_visible   ; scroll/compute so display agrees with the gap
    rts

@check_reposition:
    cmp #$04
    bne @check_err
    ; Gap repositioned by module (e.g. MODSFR after a find/replace).
    ; Module has already updated ZP_GAP_START/END directly; also copy from
    ; param block in case this path is taken via a future module that only
    ; writes the param block (belt-and-suspenders).
    lda MOD_GAP_START_LO
    sta GAP_START
    lda MOD_GAP_START_HI
    sta GAP_START+1
    lda MOD_GAP_END_LO
    sta GAP_END
    lda MOD_GAP_END_HI
    sta GAP_END+1
    ; TOP_LINE intentionally not reset — ensure_cursor_visible (called by
    ; do_search_replace after we return) will scroll as needed.
    rts

@check_err:
    cmp #$01
    bne @ok
    jsr mpop_show_error
    rts
@ok:
    rts

run_sel_load_err:
    jsr mpop_show_load_error
    rts

; ============================================================================
; Error message helpers
; ============================================================================

mpop_show_error:
    ; If MODASM set ASM_ERR ($C007=$FF), show rich "ERR NNNN: MSGTEXT" display.
    ; Other modules don't touch $C007, so $FF unambiguously means MODASM failed.
    lda $C007                       ; ASM_ERR flag written by MODASM's set_err_common
    cmp #$FF
    beq asm_show_err                ; MODASM error → rich display, includes wait
    ; Generic "MODULE ERROR" for all other module failures
    ldy #0
@wr:
    lda mpop_err_text,y
    beq @wait
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
    jmp @wr
@wait:
    lda JIFFY_LO
    clc
    adc #90
    sta IO_SCRATCH
@spin:
    lda JIFFY_LO
    cmp IO_SCRATCH
    bne @spin
    rts

; ============================================================================
; asm_show_err — rich MODASM error display.
;
; Reads ASM_ERR_LINE_LO/HI ($C008/$C009) and ASM_ERR_MSG ($C00A, screen codes,
; zero-terminated) written by MODASM's set_err_common, and formats:
;
;   ERR NNNN: MSGTEXT
;
; directly onto STATUS_ROW in red, then waits ~1.5 s.
;
; Uses: A, X, Y, TMP (ZP 2-byte), AN_CUR, AN_TMP, AN_NEXT (BSS).
; Does NOT call do_insert — writes screen codes straight to screen/color RAM.
; ============================================================================

; Screen-code constants for the fixed prefix "ERR "
; E=$05  R=$12  space=$20  colon=$3A (in $20-$5F range, ASCII=screen 1:1)
asm_err_prefix_txt:
    .byte $05,$12,$12,$20           ; "ERR "

ASM_ERR_LINE_LO = $C008
ASM_ERR_LINE_HI = $C009
ASM_ERR_MSG     = $C00A

asm_show_err:
    ; --- 1. Write "ERR " prefix ---
    ldy #0
@prefix:
    lda asm_err_prefix_txt,y
    sta STATUS_ROW,y
    lda #2                          ; red
    sta COLOR,y
    iny
    cpy #4
    bne @prefix
    ; Y = 4 (first digit position)

    ; --- 2. Write line number as decimal, no leading zeros ---
    ; Load 16-bit line number into AN_CUR (reuse existing BSS scratch).
    ; an_emit_number writes via do_insert; we can't use it here.
    ; Instead: same repeated-subtraction algorithm, writing to STATUS_ROW,Y.
    lda $C008                       ; ASM_ERR_LINE_LO
    sta AN_CUR
    lda $C009                       ; ASM_ERR_LINE_HI
    sta AN_CUR+1

    ; Reuse an_div_lo/an_div_hi table from editor.asm (same link unit).
    ; AN_LEADING: 0 = still suppressing leading zeros, $FF = digit emitted.
    lda #0
    sta AN_LEADING
    ldx #0                          ; divisor index 0..3 (10000,1000,100,10)
@digit:
    lda an_div_lo,x
    sta AN_NEXT
    lda an_div_hi,x
    sta AN_NEXT+1
    lda #0
    sta AN_TMP                      ; AN_TMP = quotient digit
@sub:
    lda AN_CUR+1
    cmp AN_NEXT+1
    bcc @emit
    bne @do_sub
    lda AN_CUR
    cmp AN_NEXT
    bcc @emit
@do_sub:
    lda AN_CUR
    sec
    sbc AN_NEXT
    sta AN_CUR
    lda AN_CUR+1
    sbc AN_NEXT+1
    sta AN_CUR+1
    inc AN_TMP
    jmp @sub
@emit:
    lda AN_TMP
    bne @nonzero
    lda AN_LEADING
    beq @skip_digit                 ; suppress leading zero
    lda #$30                        ; screen code '0'
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
    jmp @skip_digit
@nonzero:
    lda #$FF
    sta AN_LEADING
    lda AN_TMP
    ora #$30                        ; screen code for digit (digits $30-$39 same as PETSCII)
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
@skip_digit:
    inx
    cpx #4
    bne @digit
    ; Units digit — always emit (even if zero)
    lda AN_CUR
    ora #$30
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny

    ; --- 3. Write ": " separator ---
    lda #$3A                        ; ':' screen code ($3A, ASCII range → same)
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
    lda #$20                        ; space
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny

    ; --- 4. Copy ASM_ERR_MSG (screen codes, zero-terminated) ---
    ; TMP walks the message; Y is the screen column.
    ; Same trick as mpop_draw_item: save Y in MOD_TMP, use Y=0 to read (TMP),y,
    ; restore Y. Advance TMP after each byte.
    lda #<ASM_ERR_MSG
    sta TMP
    lda #>ASM_ERR_MSG
    sta TMP+1
@msg:
    cpy #COLS                       ; guard against overflow past col 39
    bcs @msg_done
    sty MOD_TMP                     ; save screen column
    ldy #0
    lda (TMP),y                     ; read next message byte
    tax                             ; stash char; tax sets Z flag correctly
    ldy MOD_TMP                     ; restore screen column
    txa                             ; restore A, Z flag now reflects char
    beq @msg_done                   ; zero terminator
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
    ; Advance TMP by 1
    inc TMP
    bne @msg
    inc TMP+1
    jmp @msg
@msg_done:

    ; --- 5. Clear remainder of status row ---
    lda #$20
@clr:
    cpy #COLS
    bcs @clr_done
    sta STATUS_ROW,y
    iny
    jmp @clr
@clr_done:

    ; --- 6. Wait ~1.5 s (90 jiffies) then return ---
    lda JIFFY_LO
    clc
    adc #90
    sta IO_SCRATCH
@wait:
    lda JIFFY_LO
    cmp IO_SCRATCH
    bne @wait
    rts

mpop_show_load_error:
    ldy #0
@wr:
    lda mpop_load_err_text,y
    beq @wait
    sta STATUS_ROW,y
    lda #2
    sta COLOR,y
    iny
    jmp @wr
@wait:
    lda JIFFY_LO
    clc
    adc #90
    sta IO_SCRATCH
@spin2:
    lda JIFFY_LO
    cmp IO_SCRATCH
    bne @spin2
    rts

mpop_err_text:
    ; "MODULE ERROR      " screen codes
    .byte $0D,$0F,$04,$15,$0C,$05,$20,$05,$12,$12,$0F,$12,$20,$20,$20,$20,$20,$20, 0

mpop_load_err_text:
    ; "MODULE NOT FOUND  " screen codes
    .byte $0D,$0F,$04,$15,$0C,$05,$20,$0E,$0F,$14,$20,$06,$0F,$15,$0E,$04,$20,$20, 0

; ============================================================================
; mod_call_trampoline — JSR to address in LPTR.
; 6502 has no JSR (indirect) so we use: JSR trampoline / JMP (LPTR).
; The JSR pushes return address, JMP (LPTR) transfers control.
; ============================================================================

mod_call_trampoline:
    jmp (LPTR)

; ============================================================================
; mpop_row_ptr — set WORK_PTR to screen RAM start of row A.
; Clobbers A, X. Does NOT touch MOD_TMP, MOD_ITEM_TMP, or stack.
; ============================================================================

mpop_row_ptr:
    tax
    lda #0
    sta TMP
    sta TMP+1
    cpx #0
    beq @base
@mul:
    lda TMP
    clc
    adc #COLS
    sta TMP
    bcc :+
    inc TMP+1
:   dex
    bne @mul
@base:
    lda #<SCREEN
    clc
    adc TMP
    sta WORK_PTR
    lda #>SCREEN
    adc TMP+1
    sta WORK_PTR+1
    rts

; ============================================================================
; mpop_color_ptr — set WORK_PTR to color RAM start of row A.
; ============================================================================

mpop_color_ptr:
    tax
    lda #0
    sta TMP
    sta TMP+1
    cpx #0
    beq @base
@mul:
    lda TMP
    clc
    adc #COLS
    sta TMP
    bcc :+
    inc TMP+1
:   dex
    bne @mul
@base:
    lda #<COLOR
    clc
    adc TMP
    sta WORK_PTR
    lda #>COLOR
    adc TMP+1
    sta WORK_PTR+1
    rts

; ============================================================================
; mpop_color_chrome — paint row A with POP_CHROME_CLR
; mpop_color_white  — paint row A with POP_HILITE_CLR (white)
; Both skip row 0 (status bar) as a safety guard.
; ============================================================================

mpop_color_chrome:
    cmp #0                          ; never touch status row
    beq @done
    jsr mpop_color_ptr
    ldy #0
    lda #POP_CHROME_CLR
@loop:
    sta (WORK_PTR),y
    iny
    cpy #COLS
    bne @loop
@done:
    rts

mpop_color_white:
    cmp #0
    beq @done
    jsr mpop_color_ptr
    ldy #0
    lda #POP_HILITE_CLR
@loop:
    sta (WORK_PTR),y
    iny
    cpy #COLS
    bne @loop
@done:
    rts
