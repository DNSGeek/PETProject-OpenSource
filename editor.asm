;
; PETPROJECT v0.1 — Editor
;

.setcpu "6502"

; ============================================================================
; Kernal routines
; ============================================================================

GETIN        = $FFE4
SETLFS       = $FFBA
SETNAM       = $FFBD
OPEN         = $FFC0
CLOSE        = $FFC3
CHKIN        = $FFC6
CHKOUT       = $FFC9
CLRCHN       = $FFCC
CHRIN        = $FFCF
CHROUT       = $FFD2
LOAD         = $FFD5
SAVE         = $FFD8
READST       = $FFB7               ; read I/O status word into A

; Kernal zero-page variables
FA           = $BA                 ; current device number (kernal ZP)

; ============================================================================
; System locations
; ============================================================================

JIFFY_LO     = $A2                 ; jiffy counter low byte (updated by IRQ)
RPTFLG       = $028A               ; KERNAL key-repeat control: $80 = all keys
                                   ; repeat, $40 = none, $00 = cursor/space/del
                                   ; only (the power-on default)
RPTFLG_ALL   = $80                 ; value that makes every key auto-repeat
NMI_VEC      = $0318               ; NMI indirect vector (lo)
NMI_VEC_HI   = $0319               ; NMI indirect vector (hi)

; Warm-boot communication block. Lives at $0200 (start of page 2).
; On cold boot this area is uninitialised. On IDE-triggered warm boot
; (app finished / NMI stub fired) the stub writes WARM_MAGIC here before
; reloading us, so start: can tell the difference.
;
; Future: when config-file support is added, load_settings will read
; petproject.cfg from disk and overlay these defaults at boot time.
; Nothing else in the boot path needs to change.

BOOT_MAGIC   = $0200               ; 1 byte: $42 = warm boot, anything else = cold
BOOT_FNAME_LEN = $0201             ; 1 byte: length of source filename to reload
BOOT_FNAME   = $0202               ; 16 bytes: source filename ($0202–$0211)
WARM_MAGIC   = $42                 ; sentinel value
RESUME_MAGIC = $52                 ; script runner finished: re-enter, keep buffer intact

; ============================================================================
; Screen / VIC constants
; ============================================================================

SCREEN       = $0400
COLOR        = $D800
COLS         = 40
TOTAL_ROWS   = 25
CONTENT_ROWS = 24                  ; total rows minus the status row

STATUS_ROW   = SCREEN              ; row 0
CONTENT_TOP  = SCREEN + COLS       ; row 1, where the document starts

VIC_BORDER   = $D020
VIC_BG       = $D021

; ============================================================================
; PETSCII / key constants
; ============================================================================

PET_CR       = $0D
PET_STOP     = $03                 ; RUN/STOP key PETSCII value
PET_SPACE    = $20                 ; PETSCII space
PET_0        = $30                 ; PETSCII '0'
PET_9        = $39                 ; PETSCII '9'
SCR_SPACE    = $20

KEY_F1       = $85                 ; PETSCII for F1 key  (settings)
KEY_F2       = $89                 ; PETSCII for F2 key  (SHIFT+F1 — page up)
KEY_F3       = $86                 ; PETSCII for F3 key  (load)
KEY_F4       = $8A                 ; PETSCII for F4 key  (SHIFT+F3 — page down)
KEY_F5       = $87                 ; PETSCII for F5 key  (save)
KEY_F6       = $8B                 ; PETSCII for F6 key  (SHIFT+F5 — consumed, no action)
KEY_F7       = $88                 ; PETSCII for F7 key  (quit)
KEY_F8       = $8C                 ; PETSCII for F8 key  (SHIFT+F7 — module picker)
KEY_CRSR_RT  = $1D
KEY_CRSR_LT  = $9D
KEY_CRSR_DN  = $11
KEY_CRSR_UP  = $91
KEY_CTRL_F   = $06                 ; CTRL+F — search / replace (loads MODSFR)
KEY_CTRL_I   = $09                 ; CTRL+I — keyword tab completion
KEY_CTRL_N   = $0E                 ; CTRL+N — new file
KEY_CTRL_L   = $0C                 ; CTRL+L — force full screen redraw
KEY_CTRL_R   = $12                 ; CTRL+R - Run a script

; ============================================================================
; Default color values
; Stored in SETTING_BORDER / SETTING_BG / SETTING_FG at runtime so the
; user can change them from the settings popover without recompiling.
; ============================================================================

DEFAULT_FG_COLOR     = $0E        ; light blue
DEFAULT_STATUS_COLOR = $01        ; white  (status row — not user-adjustable yet)
DEFAULT_BORDER_COLOR = $06        ; blue
DEFAULT_BG_COLOR     = $00        ; black

; ---- Modal prompt ("attention") bar ------------------------------------
; A modal prompt repaints the whole status row as a reverse-video bar so it
; is impossible to mistake for the ambient (idle) status line. Reverse video
; (screen-code bit 7 set) renders each cell as a solid block in the color-RAM
; color with the glyph knocked out in the screen background color — i.e. a
; bright bar with dark lettering. modal_exit calls render_status to restore.
MODAL_BAR_COLOR      = $07        ; yellow — the alert bar color
SCR_REVERSE          = $80        ; OR into a screen code for reverse video

BUF_SIZE     = $6000              ; 24 K working buffer

; ============================================================================
; Zero-page allocations
; ============================================================================

.zeropage

GAP_START:    .res 2
GAP_END:      .res 2
BUF_PTR:      .res 2
SCREEN_PTR:   .res 2
TOP_LINE:     .res 2
LEFT_COL:     .res 1
TMP:          .res 2
SAVED_X:      .res 1        ; lookup_screen uses this to preserve X
CURSOR_ROW:   .res 1        ; visible row 0..23 in content area
CURSOR_COL:   .res 1        ; visible column 0..39 (after LEFT_COL applied)
COL_SAVE:     .res 1        ; saved column for up/down movement
WORK_PTR:     .res 2        ; scratch pointer for cursor walks
LPTR:         .res 2        ; load/save label pointer (loadsave.asm)
CLR_PTR:      .res 2        ; color RAM row pointer
CLR_KWLEN:    .res 1        ; keyword length returned by col_try_keyword
CLR_CTMP:     .res 2        ; colortab walk pointer (col_try_keyword internal)

; col_try_keyword uses ZP scratch at $3A for the matched token byte.
; This byte is above the editor's reserved ZP block ($02-$1B) and is
; the same address used by modtok.asm — safe to alias here since the
; editor never calls tokenizer code directly.
KW_TOKEN      = $3A          ; token byte from col_try_keyword (colorize scratch)


.segment "LOADADDR"
.export __LOADADDR__
__LOADADDR__:
    .word $0801

; ============================================================================
; BASIC stub: 10 SYS 2061  (jumps to $080D)
; ============================================================================

.segment "STARTUP"

; BASIC stub: 10 SYS 2061  (12 bytes at $0801, jumps to $080D = 2061)
; NOTE: uses non-local label _basic_end instead of @next.
; ca65 local labels (@foo) are scoped between non-local labels; with no
; non-local label preceding this segment, @next silently resolved to $0000,
; corrupting the next-line link and shifting start: 2 bytes forward so
; SYS 2061 landed on a BRK instead of the entry point.
    .word _basic_end                ; pointer to next BASIC line (= $080B)
    .word 10                        ; line number
    .byte $9E                       ; SYS token
    .byte "2061"                    ; argument: start: is at $080D = 2061 decimal
    .byte 0                         ; end-of-line
_basic_end:
    .word 0                         ; end-of-program

; ============================================================================
; Entry point — cold vs warm boot
; ============================================================================

.code

start:
    ; Verify the BASIC stub above is exactly 12 bytes so SYS 2061 lands here.
    ; If this assertion fires, the stub changed size — update "2061" to match.
    .assert * = $080D, error, "BASIC SYS address mismatch: start: must be at $080D"
    ; The editor never returns to BASIC's SYS handler.  Reset the stack now
    ; to discard BASIC's call frames so OPEN/CHKIN frames have room to run.
    ldx #$FF
    txs
    jsr build_screen_lookup

    ; Enable auto-repeat on ALL keys. The KERNAL default ($00) repeats only the
    ; cursor keys, space, and INST/DEL, so a held letter would emit just one
    ; character. An editor wants every key to repeat while held.
    lda #RPTFLG_ALL
    sta RPTFLG

    jsr load_settings

    ; Check for warm-boot magic written by the NMI/exit stub.
    lda BOOT_MAGIC
    cmp #RESUME_MAGIC
    beq @resume                    ; script runner finished — buffer already in RAM
    cmp #WARM_MAGIC
    beq warm_start
    jmp cold_start                 ; neither magic — cold start

@resume:
    ; MODSCRH's hnd_end_script restored the full IDE image (including the gap
    ; buffer the user was editing) from the REU before jumping here, and reset
    ; the stack above. Settings are still live in RAM. So we skip all init and
    ; just repaint + resume the input loop, preserving the buffer exactly.
    lda #0
    sta BOOT_MAGIC                 ; consume the magic so next boot is cold
    jmp editor_ready

    ; ------------------------------------------------------------------
    ; Cold start — blank buffer, default settings
    ; ------------------------------------------------------------------
cold_start:
    jsr init_settings              ; write defaults into SETTING_* bytes
    jsr setup_screen               ; clear display, init gap buffer
    jmp editor_ready

    ; ------------------------------------------------------------------
    ; Warm start — IDE was reloaded after running user's program.
    ; Restore the source file the user was editing.
    ; ------------------------------------------------------------------
warm_start:
    lda #0
    sta BOOT_MAGIC                 ; consume the magic so next boot is cold

    jsr init_settings              ; apply defaults (config file would overlay
                                   ; these in load_settings once implemented)
    jsr setup_screen_blank         ; clear display, empty gap buffer

    ; Future: if BOOT_FNAME_LEN > 0, call load_file with BOOT_FNAME/LEN.
    ; For now, warm boot just opens a blank buffer.
    lda BOOT_FNAME_LEN
    beq editor_ready               ; no filename recorded — start blank
    ; jsr load_source_file         ; (file I/O not yet implemented)

editor_ready:
    jsr apply_colors               ; push SETTING_* values to VIC + color RAM
    jsr render_status
    jsr ensure_cursor_visible
    jsr render_viewport
    jsr draw_cursor

; ============================================================================
; Main input loop
; ============================================================================

main_loop:
    jsr GETIN
    bne @has_key
    jmp @no_key
@has_key:
    ; ---- CTRL+I (TAB) — keyword completion --------------------------------
    ; Must be checked BEFORE clearing COMPL_ACTIVE so the cycling state
    ; survives to the next press.  Every other key goes through @not_tab,
    ; which clears COMPL_ACTIVE unconditionally.
    cmp #KEY_CTRL_I
    bne @not_tab
    jmp @do_tab
@not_tab:
    pha
    lda #$00
    sta COMPL_ACTIVE
    pla
    ; ---- Function keys ----
    ; Physical keys: F1=settings, F3=load, F5=save, F7=quit.
    ; Shifted variants (F2/F4/F6/F8) are consumed silently to prevent
    ; them falling through to do_insert and corrupting the buffer.
    cmp #KEY_F1
    bne @try_f2
    jmp @do_settings               ; F1 = settings
@try_f2:
    cmp #KEY_F2
    bne @try_f3
    jmp @do_page_up                ; SHIFT+F1 — page up
@try_f3:
    cmp #KEY_F3
    bne @try_f4
    jmp @do_load                   ; F3 = load
@try_f4:
    cmp #KEY_F4
    bne @try_f5
    jmp @do_page_down              ; SHIFT+F3 — page down
@try_f5:
    cmp #KEY_F5
    bne @try_f6
    jmp @do_save                   ; F5 = save
@try_f6:
    cmp #KEY_F6
    bne @try_f7
    jmp @do_load_source            ; F6 (SHIFT+F5) = load raw source (SEQ) file
@try_f7:
    cmp #KEY_F7
    bne @try_f8
    jmp @quit                      ; F7 = quit
@try_f8:
    cmp #KEY_F8
    bne @try_crsr_rt
    jmp @do_modules                  ; F8 (SHIFT+F7) — module picker
@try_crsr_rt:

    ; ---- CTRL+F — search / replace ----
    cmp #KEY_CTRL_F
    bne @try_ctrl_n
    jmp @do_search
@try_ctrl_n:
    ; ---- CTRL+N — new file ----
    cmp #KEY_CTRL_N
    bne @try_crsr_rt2
    jmp @do_new
@try_crsr_rt2:

    ; ---- Cursor movement ----
    cmp #KEY_CRSR_RT
    bne @try_lt
    jsr move_begin
    jsr cursor_right
    jmp @moved
@try_lt:
    cmp #KEY_CRSR_LT
    bne @try_dn
    jsr move_begin
    jsr cursor_left
    jmp @moved
@try_dn:
    cmp #KEY_CRSR_DN
    bne @try_up
    jsr move_begin
    jsr cursor_down
    jmp @moved
@try_up:
    cmp #KEY_CRSR_UP
    bne @try_return
    jsr move_begin
    jsr cursor_up
    jmp @moved

    ; ---- Text input ----
@try_return:
    cmp #$0D                       ; RETURN — insert newline
    bne @try_del
    jsr insert_return
    lda #$FF
    sta IS_DIRTY
    jmp @moved_render
@try_del:
    cmp #$14                       ; INST/DEL — backspace
    bne @try_ctrl_l
    jsr do_backspace
    lda #$FF
    sta IS_DIRTY
    jmp @moved_render
@try_ctrl_l:
    cmp #KEY_CTRL_L                 ; CTRL+L — force full screen redraw
    bne @try_ctrl_r
    jsr apply_colors
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
    jmp main_loop
@try_ctrl_r:
    cmp #KEY_CTRL_R
    bne @try_insert
    jsr do_run_script
    jmp main_loop
@try_insert:
    cmp #$80                       ; reject PETSCII >= $80 (token bytes)
    bcs @unhandled
    cmp #$20                       ; reject control chars below $20
    bcc @unhandled
    ; ---- Printable insert fast path ----
    ; A printable char only changes the current line. Snapshot the viewport
    ; origin, insert, reposition the cursor, and if the viewport did NOT scroll
    ; (TOP_LINE and LEFT_COL unchanged) repaint just the cursor's row instead
    ; of all 24. Falls back to a full redraw when a scroll was triggered.
    ldx TOP_LINE
    stx FP_TOP_SAVE
    ldx TOP_LINE+1
    stx FP_TOP_SAVE+1
    ldx LEFT_COL
    stx FP_LEFT_SAVE
    jsr do_insert                  ; A still holds the key
    ldx #$FF
    stx IS_DIRTY
    jsr ensure_cursor_visible
    ; Did the viewport scroll? Compare saved origin to current.
    lda TOP_LINE
    cmp FP_TOP_SAVE
    bne @moved_full
    lda TOP_LINE+1
    cmp FP_TOP_SAVE+1
    bne @moved_full
    lda LEFT_COL
    cmp FP_LEFT_SAVE
    bne @moved_full
    ; No scroll — repaint only the cursor's row.
    jsr render_cursor_row
    jsr draw_cursor
    jmp main_loop
@moved_full:
    jsr render_viewport
    jsr draw_cursor
    jmp main_loop

@unhandled:
    jmp main_loop

@moved:
    ; Cursor-movement fast path. A pure cursor move changes nothing on screen
    ; except which cell is highlighted, so when the viewport does not scroll we
    ; skip the full 24-row render+recolor entirely: the old cursor cell was
    ; already cleared by move_begin, the content rows are still correct, so we
    ; only need to draw the cursor at its new position. This is what made
    ; arrow-key movement slow (especially in asm mode, where the per-row
    ; colorizer cost is higher) — every keypress was repainting the whole screen.
    jsr ensure_cursor_visible
    lda TOP_LINE
    cmp FP_TOP_SAVE
    bne @cmoved_full
    lda TOP_LINE+1
    cmp FP_TOP_SAVE+1
    bne @cmoved_full
    lda LEFT_COL
    cmp FP_LEFT_SAVE
    bne @cmoved_full
    ; No scroll — just draw the cursor at the new cell. No re-render.
    jsr draw_cursor
    jmp main_loop
@cmoved_full:
    ; Viewport scrolled — full redraw (this also clears the old cursor cell).
    jsr render_viewport
    jsr draw_cursor
    jmp main_loop

; Unconditional full-render path for content-changing or always-scrolling keys
; (RETURN, INST/DEL, page up/down). These don't go through move_begin, so the
; scroll-detection snapshot isn't valid for them; they always repaint fully.
@moved_render:
    jsr ensure_cursor_visible
    jsr render_viewport
    jsr draw_cursor
    jmp main_loop

@no_key:
    ; Blink only if SETTING_BLINK is non-zero.
    lda SETTING_BLINK
    beq @blink_off_always
    lda JIFFY_LO
    and #$10                       ; ~2 Hz blink period
    beq @cursor_off
    jsr draw_cursor
    jmp main_loop
@cursor_off:
    jsr erase_cursor
    jmp main_loop
@blink_off_always:
    jsr draw_cursor                ; blink disabled — cursor always on
    jmp main_loop

    ; ---- Function key handlers (stubs until feature implemented) ----
@do_tab:
    jsr do_tab_complete
    jmp main_loop
@do_settings:
    jsr do_settings_popover
    jmp main_loop
@do_load:
    jsr do_load_file
    jmp main_loop
@do_load_source:
    jsr do_load_source_file
    jmp main_loop
@do_save:
    jsr do_save_file
    jmp main_loop

@do_modules:
    jsr do_modules_popup
    jmp main_loop

@do_search:
    jsr do_search_replace
    jmp main_loop

@do_new:
    jsr do_new_file
    jmp main_loop

@do_page_up:
    jsr page_up
    jmp @moved_render

@do_page_down:
    jsr page_down
    jmp @moved_render

@quit:
@check_is_dirty:
    ; If buffer is dirty, prompt "SAVE BEFORE QUIT (Y/N)?"
    lda IS_DIRTY
    beq @quit_now
    jsr quit_dirty_prompt           ; C=1 → cancelled (don't quit)
    bcc @quit_now
    jmp main_loop                   ; user cancelled — back to editing

@quit_now:
    ; Clear screen before handing back to BASIC.
    lda #$93                        ; PETSCII clear-screen character
    jsr $FFD2                       ; CHROUT
    ; Hand back to BASIC via its COLD-start entry ($E394), NOT warm start.
    ;
    ; At boot we did `ldx #$FF / txs`, discarding BASIC's call stack, and the
    ; editor has overwritten zero page (gap pointers, $3A, etc.) and page 2
    ; throughout the session. BASIC's warm start ($E37B) assumes its stack and
    ; ZP pointers are still valid, so resuming through it left BASIC with a
    ; corrupted expression stack — the next evaluation (e.g. LOAD"$",8) failed
    ; with ?FORMULA TOO COMPLEX. Cold start runs JSR $E3BF (re-init BASIC RAM:
    ; rebuilds the stack, ZP pointers, and vectors), giving a clean machine.
    ;
    ; Trade-off: this resets BASIC fully (banner shown, any BASIC program in
    ; memory is cleared). That is the correct, safe contract for a SYS-launched
    ; tool that took over the machine.
    jmp $E394                       ; BASIC cold start (per ($A000) in this ROM)

; ============================================================================
; move_begin — preamble shared by all cursor-movement keys.
; Snapshots the viewport origin (for scroll detection in the @moved fast path)
; and erases the cursor at its CURRENT cell BEFORE the move routine changes
; CURSOR_ROW/COL, so the no-scroll fast path leaves no stale highlight behind.
; Clobbers A, X, Y (erase_cursor), WORK_PTR.
; ============================================================================
move_begin:
    lda TOP_LINE
    sta FP_TOP_SAVE
    lda TOP_LINE+1
    sta FP_TOP_SAVE+1
    lda LEFT_COL
    sta FP_LEFT_SAVE
    jmp erase_cursor               ; tail-call: erases old cell, then rts

; ============================================================================
; do_new_file — CTRL+N handler: clear buffer, optionally saving first.
;
; If dirty: prompt "SAVE BEFORE NEW (Y/N)?". Y=save then new, N=new without
; saving, STOP=cancel.
; Resets gap buffer, cursor, viewport, IS_DIRTY, IS_BASIC, IS_NEW_FILE,
; and FNAME_LEN so the save prompt starts blank next time.
; ============================================================================

do_new_file:
    lda IS_DIRTY
    beq @clear
    ; Prompt — reverse-video alert bar so it can't be mistaken for idle status.
    lda #<new_dirty_text
    ldx #>new_dirty_text
    jsr modal_draw_text
@wait:
    jsr GETIN
    beq @wait
    cmp #PET_STOP
    beq @cancel
    cmp #'Y'
    beq @save
    cmp #'y'
    beq @save
    cmp #'N'
    beq @clear
    cmp #'n'
    beq @clear
    jmp @wait
@save:
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    jsr do_save_file            ; if save is cancelled, still proceed to clear
@clear:
    ; Reset gap buffer to empty
    lda #<work_buf
    sta GAP_START
    lda #>work_buf
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    ; Reset viewport and cursor
    lda #<work_buf
    sta TOP_LINE
    lda #>work_buf
    sta TOP_LINE+1
    lda #0
    sta LEFT_COL
    sta CURSOR_ROW
    sta CURSOR_COL
    ; Reset file state
    lda #0
    sta IS_DIRTY
    sta FNAME_LEN               ; blank filename for next save prompt
    lda #$FF
    sta IS_NEW_FILE
    sta IS_BASIC
    jsr ensure_cursor_visible
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
@cancel:
    jsr modal_exit              ; STOP: restore idle status bar before returning
    rts

new_dirty_text:
    ; "SAVE BEFORE NEW (Y/N)?" in screen codes
    .byte $13,$01,$16,$05,$20,$02,$05,$06,$0F,$12,$05,$20,$0E,$05,$17
    .byte $20,$28,$19,$2F,$0E,$29,$3F, 0

; ============================================================================
; quit_dirty_prompt — "SAVE BEFORE QUIT (Y/N)?" on status bar.
;
; If Y: calls do_save_file, then returns C=0 (proceed to quit).
; If N: returns C=0 (quit without saving).
; If STOP: returns C=1 (cancel quit, back to editor).
; Clobbers: A, X, Y.
; ============================================================================

quit_dirty_prompt:
    lda #<quit_dirty_text
    ldx #>quit_dirty_text
    jsr modal_draw_text
@wait:
    jsr GETIN
    beq @wait
    cmp #PET_STOP
    beq @cancel
    cmp #'Y'
    beq @save
    cmp #'y'
    beq @save
    cmp #'N'
    beq @nosave
    cmp #'n'
    beq @nosave
    jmp @wait
@save:
    jsr do_save_file                ; save — clears IS_DIRTY on success
    clc
    rts
@nosave:
    clc
    rts
@cancel:
    jsr modal_exit                  ; restore idle status bar (caller returns to editor)
    sec
    rts

quit_dirty_text:
    ; "SAVE BEFORE QUIT (Y/N)?" in screen codes
    .byte $13,$01,$16,$05,$20,$02,$05,$06,$0F,$12,$05,$20,$11,$15,$09,$14
    .byte $20,$28,$19,$2F,$0E,$29,$3F, 0

; ============================================================================
; init_settings — write compiled-in defaults into the SETTING_* BSS bytes.
; Called on both cold and warm start before load_settings overlays from disk.
; ============================================================================

init_settings:
    lda #DEFAULT_BORDER_COLOR
    sta SETTING_BORDER
    lda #DEFAULT_BG_COLOR
    sta SETTING_BG
    lda #DEFAULT_FG_COLOR
    sta SETTING_FG
    lda #1                         ; cursor blink on by default
    sta SETTING_BLINK
    lda #8                         ; default drive = 8
    sta SETTING_DRIVE
    lda #0
    sta FNAME_LEN
    lda #0
    sta IS_BASIC
    lda #$FF
    sta IS_NEW_FILE   ; new editor session starts with a new file
    lda #0
    sta IS_DIRTY
    rts

; ============================================================================
; load_settings — future: read petproject.cfg from disk and populate
; SETTING_* bytes. Currently a no-op stub.
;
; Implementation notes for when this is wired up:
;   - Use SETTING_DRIVE to open the file (drive may have been changed last
;     session, but we don't know it yet — always load cfg from drive 8).
;   - File format TBD; simplest is fixed-offset binary record matching the
;     SETTING_* layout so it can be read with a single sequential read.
;   - If file not found (ST=$42 after OPEN), silently return — defaults stand.
;   - Call apply_colors after returning so any stored colors take effect.
; ============================================================================

load_settings:
    rts                            ; stub — remove this rts when implemented

; ============================================================================
; save_settings — future: write SETTING_* bytes to petproject.cfg on disk.
; Currently a no-op stub.
;
; Implementation notes:
;   - Always save to drive 8 (so cfg is findable on cold boot before we
;     know the user's preferred drive).
;   - Write SETTING_DRIVE, SETTING_BORDER, SETTING_BG, SETTING_FG,
;     SETTING_BLINK as a fixed binary record (5 bytes).
;   - Call from settings popover on close (only if settings changed).
; ============================================================================

save_settings:
    rts                            ; stub — remove this rts when implemented

; ============================================================================
; apply_colors — push SETTING_BORDER / SETTING_BG / SETTING_FG to hardware.
; Call after changing any color setting to make it take effect immediately.
; ============================================================================

apply_colors:
    lda SETTING_BORDER
    sta VIC_BORDER
    lda SETTING_BG
    sta VIC_BG
    ; Repaint color RAM with SETTING_FG (leaves status row alone).
    ; We write all 1000 bytes; the status row gets overwritten but
    ; render_status repaints it white afterward.
    lda SETTING_FG
    ldx #0
@color_loop:
    sta COLOR+$000,x
    sta COLOR+$100,x
    sta COLOR+$200,x
    sta COLOR+$300,x
    inx
    bne @color_loop
    rts

; ============================================================================
; setup_screen — clear screen, set color RAM, init gap buffer with test content
; ============================================================================

setup_screen:
    ; Clear screen RAM
    ldx #0
    lda #SCR_SPACE
@clr:
    sta SCREEN+$000,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    inx
    bne @clr

    ; GAP_END = work_buf_end (entire buffer is gap to start with)
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1

    ; Copy test content into work_buf.
    lda #<test_buffer
    sta WORK_PTR
    lda #>test_buffer
    sta WORK_PTR+1
    lda #<work_buf
    sta BUF_PTR
    lda #>work_buf
    sta BUF_PTR+1
@copy:
    lda WORK_PTR
    cmp #<buffer_end
    bne @do_byte
    lda WORK_PTR+1
    cmp #>buffer_end
    beq @copy_done
@do_byte:
    ldy #0
    lda (WORK_PTR),y
    sta (BUF_PTR),y
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   inc BUF_PTR
    bne @copy
    inc BUF_PTR+1
    jmp @copy
@copy_done:
    lda BUF_PTR
    sta GAP_START
    lda BUF_PTR+1
    sta GAP_START+1

    lda #<work_buf
    sta TOP_LINE
    lda #>work_buf
    sta TOP_LINE+1
    lda #0
    sta LEFT_COL
    lda #$FF
    sta IS_BASIC
    rts

; ============================================================================
; setup_screen_blank — like setup_screen but initialises an empty gap buffer.
; Used on warm start before (optionally) loading a source file.
; ============================================================================

setup_screen_blank:
    ldx #0
    lda #SCR_SPACE
@clr:
    sta SCREEN+$000,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    inx
    bne @clr

    lda #<work_buf
    sta GAP_START
    lda #>work_buf
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1

    lda #<work_buf
    sta TOP_LINE
    lda #>work_buf
    sta TOP_LINE+1
    lda #0
    sta LEFT_COL
    lda #$FF
    sta IS_BASIC            ; test buffer is BASIC - colorize on launch
    rts

; ============================================================================
; modal_draw_text — paint the entire status row as a reverse-video alert bar.
;
; Used by every modal prompt (CTRL+N "save before new", quit confirm, etc.)
; so a blocking prompt is visually unmistakable from the idle status line.
;
; Entry:  A = lo byte, X = hi byte of a NUL-terminated *screen-code* string
;             (raw screen codes, NOT PETSCII — same format as new_dirty_text).
; Exit:   Whole status row painted: string chars + trailing fill, all in
;             reverse video, color MODAL_BAR_COLOR. A, X, Y clobbered.
;
; Pair with modal_exit (calls render_status) when the prompt is dismissed.
;
; Cursor parking hook: if you later want the editor's block cursor moved onto
; the prompt, do it in the caller after this returns — this routine owns the
; row's screen/color RAM only, not CURSOR_ROW/COL.
; ============================================================================
modal_draw_text:
    sta WORK_PTR
    stx WORK_PTR+1
    ldy #0
@mdt_str:
    lda (WORK_PTR),y
    beq @mdt_fill                 ; NUL -> fill remainder of the row
    ora #SCR_REVERSE              ; reverse video for the alert bar
    sta STATUS_ROW,y
    lda #MODAL_BAR_COLOR
    sta COLOR,y
    iny
    cpy #COLS
    bne @mdt_str
    rts                           ; string filled the whole row exactly
@mdt_fill:
    ; Remainder of the row: reversed space = solid color block.
    cpy #COLS
    beq @mdt_done
    lda #SCR_SPACE | SCR_REVERSE
    sta STATUS_ROW,y
    lda #MODAL_BAR_COLOR
    sta COLOR,y
    iny
    bne @mdt_fill                 ; Y < 40, always taken
@mdt_done:
    rts

; ============================================================================
; modal_exit — dismiss a modal prompt and restore the idle status bar.
; Single choke point so the restore (and any future cursor un-park) lives in
; one place. Clobbers A, X (via render_status).
; ============================================================================
modal_exit:
    jmp render_status             ; tail-call: repaints the whole status row

render_status:
    ldx #0
@loop:
    cpx #COLS                      ; never write past the 40-column row, even if
    beq @done                      ; status_text is too long (clamps overflow)
    lda status_text,x
    beq @pad
    jsr lookup_screen
    sta STATUS_ROW,x
    lda #DEFAULT_STATUS_COLOR
    sta COLOR,x
    inx
    bne @loop                      ; X < 40 always, so this is just "loop"
@pad:
    ; Blank the rest of the status row
    lda #SCR_SPACE
@pad_loop:
    cpx #COLS
    bcs @done                      ; stop at or past COLS (bcs, not beq: if X
    sta STATUS_ROW,x               ; somehow entered >= COLS we still terminate)
    lda #DEFAULT_STATUS_COLOR
    sta COLOR,x
    lda #SCR_SPACE
    inx
    bne @pad_loop
@done:
    rts

status_text:
    ; Must fit in COLS (40) columns. render_status now clamps overflow, but
    ; keep it short so nothing spills onto content row 1.
    .byte "f3=load f5=save f6=src f7=quit f8=mod", 0

; Add the load/save routines
.include "loadsave.asm"

; ============================================================================
; Settings popover — F2
;
; Layout (screen rows 2–11, cols 1–38):
;
;  row 2:  +------------------------------------+
;  row 3:  | petproject settings    f2=close   |
;  row 4:  |                                    |
;  row 5:  |  drive:        [  8]  < >          |
;  row 6:  |  border:       [  6]  < >   ##     |
;  row 7:  |  background:   [  0]  < >   ##     |
;  row 8:  |  text color:   [ 14]  < >   ##     |
;  row 9:  |  cursor blink: [ on]  < >          |
;  row 10: |                                    |
;  row 11: +------------------------------------+
;
; SETTINGS_ROW selects the highlighted row (0=drive .. 4=blink).
; Left/right arrows change the value with wraparound.
; Up/down arrows move between rows.
; F2 or RUN/STOP closes. Changes apply live and are saved on close.
;
; Screen-writing helpers use WORK_PTR as a screen RAM pointer and
; TMP as scratch — safe since no editor operations run while open.
; ============================================================================

; Row indices
SET_ROW_DRIVE  = 0
SET_ROW_BORDER = 1
SET_ROW_BG     = 2
SET_ROW_FG     = 3
SET_ROW_BLINK  = 4
SET_ROW_MAX    = 4                 ; highest valid row index

; Popover screen geometry (all 0-based, row 0 = status bar)
POP_TOP        = 2                 ; first row of popover box
POP_LEFT       = 0                 ; left edge column (bar at col 0)
POP_WIDTH      = 38                ; inner width (cols 1-38, right bar at col 39)
POP_INNER_LEFT = 1                 ; left edge of text inside box

; Color RAM color for popover chrome vs highlighted row
POP_CHROME_CLR = $0B               ; dark grey  — box lines, labels
POP_HILITE_CLR = $01               ; white      — selected row
POP_VALUE_CLR  = $03               ; cyan       — value fields
POP_SWATCH_COL = 32                ; screen column of color swatch (2 chars)

; ============================================================================
; do_settings_popover — entry point, called from main_loop F2 handler
; ============================================================================
do_settings_popover:
    lda #0
    sta SETTINGS_ROW               ; start on first row

    jsr settings_draw_all

    ; Flush keyboard buffer — without this, the F1 that opened the popover
    ; is still in the buffer and immediately closes it again.
@flush:
    jsr GETIN
    bne @flush

@pop_loop:
    jsr GETIN
    beq @pop_loop

    cmp #KEY_F1
    beq @pop_close
    cmp #PET_STOP
    beq @pop_close

    cmp #KEY_CRSR_UP
    bne @try_pop_dn
    jsr settings_row_up
    jmp @pop_redraw
@try_pop_dn:
    cmp #KEY_CRSR_DN
    bne @try_pop_lt
    jsr settings_row_down
    jmp @pop_redraw
@try_pop_lt:
    cmp #KEY_CRSR_LT
    bne @try_pop_rt
    jsr settings_dec
    jmp @pop_redraw
@try_pop_rt:
    cmp #KEY_CRSR_RT
    bne @pop_loop
    jsr settings_inc
    ; fall through to redraw

@pop_redraw:
    jsr apply_colors               ; live preview — VIC + color RAM update
    jsr settings_draw_all          ; redraw popover (apply_colors wiped swatches)
    jmp @pop_loop

@pop_close:
    jsr save_settings              ; persist (no-op stub until cfg implemented)
    ; Restore the editor display
    jsr apply_colors
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
    rts

; ============================================================================
; settings_row_up / settings_row_down — move selected row with wraparound
; ============================================================================
settings_row_up:
    lda SETTINGS_ROW
    beq @wrap_bottom
    dec SETTINGS_ROW
    rts
@wrap_bottom:
    lda #SET_ROW_MAX
    sta SETTINGS_ROW
    rts

settings_row_down:
    lda SETTINGS_ROW
    cmp #SET_ROW_MAX
    beq @wrap_top
    inc SETTINGS_ROW
    rts
@wrap_top:
    lda #0
    sta SETTINGS_ROW
    rts

; ============================================================================
; settings_inc / settings_dec — change value of current row with wraparound.
; Each row knows its own min/max via X-indexed dispatch.
; ============================================================================

; Min/max tables indexed by SETTINGS_ROW
settings_min_tab: .byte 8,  0,  0,  0,  0   ; drive=8-11, colors=0-15, blink=0-1
settings_max_tab: .byte 11, 15, 15, 15, 1

settings_inc:
    ldx SETTINGS_ROW
    jsr settings_get_val           ; A = current value
    clc
    adc #1
    cmp settings_max_tab,x
    bcc @store                     ; still within max
    beq @store
    lda settings_min_tab,x         ; wrapped past max — go to min
@store:
    jmp settings_set_val           ; tail call (X still = SETTINGS_ROW)

settings_dec:
    ldx SETTINGS_ROW
    jsr settings_get_val
    cmp settings_min_tab,x
    beq @wrap_to_max
    sec
    sbc #1
    jmp settings_set_val
@wrap_to_max:
    lda settings_max_tab,x
    jmp settings_set_val

; settings_get_val — return current setting value in A. X = row index.
settings_get_val:
    cpx #SET_ROW_DRIVE
    bne @try_border
    lda SETTING_DRIVE
    rts
@try_border:
    cpx #SET_ROW_BORDER
    bne @try_bg
    lda SETTING_BORDER
    rts
@try_bg:
    cpx #SET_ROW_BG
    bne @try_fg
    lda SETTING_BG
    rts
@try_fg:
    cpx #SET_ROW_FG
    bne @is_blink
    lda SETTING_FG
    rts
@is_blink:
    lda SETTING_BLINK
    rts

; settings_set_val — store A into the setting for row X.
settings_set_val:
    cpx #SET_ROW_DRIVE
    bne @try_border
    sta SETTING_DRIVE
    rts
@try_border:
    cpx #SET_ROW_BORDER
    bne @try_bg
    sta SETTING_BORDER
    rts
@try_bg:
    cpx #SET_ROW_BG
    bne @try_fg
    sta SETTING_BG
    rts
@try_fg:
    cpx #SET_ROW_FG
    bne @is_blink
    sta SETTING_FG
    rts
@is_blink:
    sta SETTING_BLINK
    rts

; ============================================================================
; settings_draw_all — redraw the entire popover.
; ============================================================================
settings_draw_all:
    jsr settings_draw_box
    jsr settings_draw_title

    ldx #SET_ROW_DRIVE
@draw_loop:
    stx SETTINGS_ROW_TMP
    txa
    jsr settings_draw_row
    ldx SETTINGS_ROW_TMP
    inx
    cpx #(SET_ROW_MAX + 1)
    bne @draw_loop
    rts

; ============================================================================
; settings_draw_box — draw the PETSCII box outline
; Uses screen rows POP_TOP..POP_TOP+9, cols POP_LEFT..POP_LEFT+POP_WIDTH+1
;
; PETSCII box chars (screen codes):
;   top-left=$70  top-right=$6E  bot-left=$6D  bot-right=$7D
;   horiz=$40     vert=$5D
; ============================================================================
settings_draw_box:
    ; --- top border (row POP_TOP) ---
    lda #POP_TOP
    jsr pop_row_ptr                ; WORK_PTR = screen addr of row start + POP_LEFT

    ldy #POP_LEFT
    lda #$70                       ; top-left corner
    sta (WORK_PTR),y
    iny
@top_line:
    cpy #(POP_LEFT + POP_WIDTH + 1)
    beq @top_right
    lda #$40                       ; horizontal bar
    sta (WORK_PTR),y
    iny
    bne @top_line
@top_right:
    lda #$6E                       ; top-right corner
    sta (WORK_PTR),y

    ; color the top border row
    lda #POP_TOP
    jsr pop_color_row

    ; --- side borders (rows POP_TOP+1 .. POP_TOP+8) ---
    lda #(POP_TOP + 1)
    sta POP_ROW_CTR
@side_loop:
    lda POP_ROW_CTR
    cmp #(POP_TOP + 9)
    beq @bottom_border
    jsr pop_row_ptr
    ldy #POP_LEFT
    lda #$5D                       ; vertical bar left
    sta (WORK_PTR),y
    ldy #(POP_LEFT + POP_WIDTH + 1)
    sta (WORK_PTR),y               ; vertical bar right

    lda POP_ROW_CTR
    jsr pop_color_row

    inc POP_ROW_CTR
    jmp @side_loop

@bottom_border:
    ; --- bottom border (row POP_TOP+9) ---
    lda #(POP_TOP + 9)
    jsr pop_row_ptr
    ldy #POP_LEFT
    lda #$6D                       ; bottom-left corner
    sta (WORK_PTR),y
    iny
@bot_line:
    cpy #(POP_LEFT + POP_WIDTH + 1)
    beq @bot_right
    lda #$40
    sta (WORK_PTR),y
    iny
    bne @bot_line
@bot_right:
    lda #$7D                       ; bottom-right corner
    sta (WORK_PTR),y

    lda #(POP_TOP + 9)
    jsr pop_color_row

    ; Blank the two inner padding rows (rows POP_TOP+1 and POP_TOP+8)
    lda #(POP_TOP + 1)
    jsr pop_clear_inner
    lda #(POP_TOP + 8)
    jsr pop_clear_inner
    rts

; ============================================================================
; settings_draw_title — draw header text on row POP_TOP+2
; ============================================================================
settings_draw_title:
    lda #(POP_TOP + 2)
    jsr pop_row_ptr
    ldy #POP_INNER_LEFT
    ldx #0
@loop:
    lda a:pop_title_text,x
    beq @done
    sta (WORK_PTR),y
    iny
    inx
    bne @loop
@done:
    ; Color title row all white
    lda #(POP_TOP + 2)
    jsr pop_color_row_white
    rts

pop_title_text:
    ; "PETPROJECT SETTINGS   F1=CLOSE" in C64 screen codes
    ; Uppercase letters: A=$01 B=$02 ... Z=$1A
    ; Space=$20, digits same as ASCII, '='=$3D
    .byte $10,$05,$14,$10,$12,$0F,$0A,$05,$03,$14  ; "PETPROJECT"
    .byte $20                                       ; space
    .byte $13,$05,$14,$14,$09,$0E,$07,$13           ; "SETTINGS"
    .byte $20,$20,$20                               ; padding
    .byte $06,$31,$3D,$03,$0C,$0F,$13,$05           ; "F1=CLOSE"
    .byte 0

; ============================================================================
; settings_draw_row — draw one settings row. A = row index (0..4).
; Screen row = POP_TOP + 3 + A (so rows 5..9 of the box).
; ============================================================================
settings_draw_row:
    pha                            ; save row index

    ; Compute screen row number: POP_TOP + 3 + row_index
    clc
    adc #(POP_TOP + 3)
    sta POP_ROW_TMP                ; remember for color pass

    jsr pop_row_ptr                ; WORK_PTR = screen addr of this row

    ; Clear inner content of this row (cols POP_INNER_LEFT..POP_LEFT+POP_WIDTH)
    ldy #POP_INNER_LEFT
    lda #$20                       ; screen space
@clr:
    cpy #(POP_LEFT + POP_WIDTH + 1)
    beq @clr_done
    sta (WORK_PTR),y
    iny
    bne @clr
@clr_done:

    pla                            ; restore row index
    tax                            ; X = row index for label/value lookups

    ; Write label
    ldy #POP_INNER_LEFT
    jsr settings_write_label       ; writes label at (WORK_PTR),Y; Y advances

    ; Write value field "[ xx]" at fixed column 16
    ldy #16
    lda #$5B                       ; "[" screen code
    sta (WORK_PTR),y
    iny
    lda #$20
    sta (WORK_PTR),y               ; leading space
    iny

    ; Get the current value and render it
    jsr settings_get_val           ; A = value, X still = row index

    cpx #SET_ROW_BLINK
    beq @render_blink

    ; Numeric value: render up to 2 digits
    cmp #10
    bcs @two_digits
    pha                            ; single digit — save value
    lda #$20                       ; pad with space
    sta (WORK_PTR),y
    iny
    pla
    jsr digit_to_screen            ; convert ones digit
    sta (WORK_PTR),y
    iny
    jmp @close_bracket
@two_digits:
    pha
    ; tens digit
    lda #0
    sta TMP
@div10:
    pla
    sec
    sbc #10
    bcc @div_done
    inc TMP
    pha
    jmp @div10
@div_done:
    clc
    adc #10                        ; restore remainder
    pha
    lda TMP
    jsr digit_to_screen
    sta (WORK_PTR),y
    iny
    pla
    jsr digit_to_screen
    sta (WORK_PTR),y
    iny
    jmp @close_bracket

@render_blink:
    ; BUG FIX: Z flag is STALE here — we arrived via "beq @render_blink" which
    ; only branches when Z=1, so Z is always 1 on entry regardless of A.
    ; Re-test A explicitly before branching on the blink value.
    cmp #0
    beq @blink_off
    ; " ON" — 3-char field: back up to col 17 to fill the leading-space slot too
    dey                            ; back to col 17 (leading space position)
    lda #$20                       ; ' '
    sta (WORK_PTR),y
    iny
    lda #$0F                       ; 'O'
    sta (WORK_PTR),y
    iny
    lda #$0E                       ; 'N'
    sta (WORK_PTR),y
    iny
    jmp @close_bracket
@blink_off:
    ; "OFF" — 3-char field: back up to col 17
    dey                            ; back to col 17
    lda #$0F                       ; 'O'
    sta (WORK_PTR),y
    iny
    lda #$06                       ; 'F'
    sta (WORK_PTR),y
    iny
    lda #$06                       ; 'F'
    sta (WORK_PTR),y
    iny

@close_bracket:
    lda #$5D                       ; "]" screen code
    sta (WORK_PTR),y

    ; Write "  < >" at cols 22-26
    ldy #22
    lda #$20
    sta (WORK_PTR),y
    iny
    lda #$20
    sta (WORK_PTR),y
    iny
    lda #$3C                       ; '<'
    sta (WORK_PTR),y
    iny
    lda #$20
    sta (WORK_PTR),y
    iny
    lda #$3E                       ; '>'
    sta (WORK_PTR),y

    ; Draw color swatch for color rows (border, bg, fg = rows 1, 2, 3)
    txa                            ; X = row index
    cmp #SET_ROW_BORDER
    beq @draw_swatch
    cmp #SET_ROW_BG
    beq @draw_swatch
    cmp #SET_ROW_FG
    bne @color_row

@draw_swatch:
    ; Write two solid block chars ($A0 screen code) at POP_SWATCH_COL.
    ; BUG FIX: do NOT write swatch color RAM here — @color_row calls
    ; pop_color_row / pop_color_row_white which floods all 40 color cells
    ; and would immediately overwrite whatever we set.  The swatch color
    ; repaint is deferred to @paint_swatch, after the full-row paint.
    ldy #POP_SWATCH_COL
    lda #$A0
    sta (WORK_PTR),y
    iny
    sta (WORK_PTR),y
    ; WORK_PTR still on screen RAM — no restoration step needed.

@color_row:
    ; Highlight selected row white, others chrome.
    ldx SETTINGS_ROW
    txa
    clc
    adc #(POP_TOP + 3)             ; A = screen row of selected settings row
    cmp POP_ROW_TMP
    bne @paint_chrome
    lda POP_ROW_TMP
    jsr pop_color_row_white
    jmp @paint_swatch
@paint_chrome:
    lda POP_ROW_TMP
    jsr pop_color_row
    ; fall through

@paint_swatch:
    ; Repaint the two swatch color RAM cells NOW, after the full-row paint.
    ; Recover the drawn-row index from POP_ROW_TMP — no extra scratch var needed.
    lda POP_ROW_TMP
    sec
    sbc #(POP_TOP + 3)
    tax                            ; X = row index (0-4)
    cpx #SET_ROW_BORDER
    beq @do_swatch
    cpx #SET_ROW_BG
    beq @do_swatch
    cpx #SET_ROW_FG
    bne @no_swatch
@do_swatch:
    stx SAVED_X                    ; pop_color_ptr clobbers X
    lda POP_ROW_TMP
    jsr pop_color_ptr              ; WORK_PTR = color RAM for this row
    ldx SAVED_X
    ldy #POP_SWATCH_COL
    jsr settings_get_val           ; A = color index for row X
    sta (WORK_PTR),y
    iny
    sta (WORK_PTR),y
@no_swatch:
    rts

; ============================================================================
; settings_write_label — write label for row index X to WORK_PTR row.
; Label bytes are screen codes, zero-terminated, pre-padded to 14 chars.
; Uses TMP as label data pointer; POP_LBL_IDX as byte index into label.
; WORK_PTR must already point to the screen row start.
; ============================================================================
settings_write_label:
    stx SAVED_X                    ; preserve row index

    ; Load label pointer for row X (sequential tables, index directly)
    lda pop_label_lo,x
    sta TMP
    lda pop_label_hi,x
    sta TMP+1

    ldx SAVED_X                    ; restore row index into X

    ldy #0
    sty POP_LBL_IDX                ; label byte index starts at 0
@lbl_loop:
    ldy POP_LBL_IDX
    lda (TMP),y                    ; read next label byte
    beq @lbl_done                  ; zero terminator = done
    ldy POP_LBL_IDX
    clc
    adc #0                         ; no-op, keep A
    pha                            ; save char
    lda POP_LBL_IDX
    clc
    adc #POP_INNER_LEFT            ; screen column = label_index + POP_INNER_LEFT
    tay                            ; Y = screen column offset into row
    pla
    sta (WORK_PTR),y
    inc POP_LBL_IDX
    jmp @lbl_loop
@lbl_done:
    rts

; ============================================================================
; pop_row_ptr — set WORK_PTR to screen RAM start of row A.
; Row 0 = $0400, each row = 40 bytes. Uses 16-bit TMP for multiply.
; Clobbers A, X. Does NOT preserve X — callers must save if needed.
; ============================================================================
pop_row_ptr:
    ; WORK_PTR = SCREEN + (A * 40), 16-bit result
    tax                            ; X = row number (loop counter)
    lda #0
    sta TMP                        ; TMP = $0000
    sta TMP+1
    cpx #0
    beq @add_base                  ; row 0: TMP stays 0
@mul40:
    lda TMP
    clc
    adc #40
    sta TMP
    bcc :+
    inc TMP+1                      ; carry into high byte
:   dex
    bne @mul40
@add_base:
    lda TMP
    clc
    adc #<SCREEN
    sta WORK_PTR
    lda TMP+1
    adc #>SCREEN
    sta WORK_PTR+1
    rts

; ============================================================================
; pop_color_ptr — set WORK_PTR to color RAM start of row A.
; Clobbers A, X. Does NOT preserve X — callers must save if needed.
; ============================================================================
pop_color_ptr:
    ; WORK_PTR = COLOR + (A * 40), 16-bit result
    tax                            ; X = row number
    lda #0
    sta TMP
    sta TMP+1
    cpx #0
    beq @add_base
@mul40:
    lda TMP
    clc
    adc #40
    sta TMP
    bcc :+
    inc TMP+1
:   dex
    bne @mul40
@add_base:
    lda TMP
    clc
    adc #<COLOR
    sta WORK_PTR
    lda TMP+1
    adc #>COLOR
    sta WORK_PTR+1
    rts

; ============================================================================
; pop_color_row — paint entire row A's color RAM with POP_CHROME_CLR
; ============================================================================
pop_color_row:
    jsr pop_color_ptr
    ldy #0
@loop:
    lda #POP_CHROME_CLR
    sta (WORK_PTR),y
    iny
    cpy #40
    bne @loop
    rts

; ============================================================================
; pop_color_row_white — paint entire row A's color RAM with POP_HILITE_CLR
; ============================================================================
pop_color_row_white:
    jsr pop_color_ptr
    ldy #0
@loop:
    lda #POP_HILITE_CLR
    sta (WORK_PTR),y
    iny
    cpy #40
    bne @loop
    rts

; ============================================================================
; pop_clear_inner — clear the inner content of row A (fill with spaces)
; ============================================================================
pop_clear_inner:
    jsr pop_row_ptr
    ldy #POP_INNER_LEFT
    lda #$20
@loop:
    cpy #(POP_LEFT + POP_WIDTH + 1)
    beq @done
    sta (WORK_PTR),y
    iny
    bne @loop
@done:
    rts

; ============================================================================
; digit_to_screen — convert single digit value in A (0–9) to screen code.
; Screen codes for digits: '0'=$30, '1'=$31 ... '9'=$39 (same as PETSCII).
; ============================================================================
digit_to_screen:
    clc
    adc #$30
    rts

; ============================================================================
; Label data for settings rows — stored as screen codes, zero-terminated,
; right-padded to 14 chars with spaces so value field lands at fixed column.
;
; Screen code map (uppercase PETSCII in lowercase chars):
;   a-z map to $41-$5A in screen RAM
;   space = $20  colon = $3A
; ============================================================================

; Label pointer tables (lo/hi byte pairs, indexed by row*2)
pop_label_lo:
    .byte <pop_lbl_drive, <pop_lbl_border, <pop_lbl_bg, <pop_lbl_fg, <pop_lbl_blink
pop_label_hi:
    .byte >pop_lbl_drive, >pop_lbl_border, >pop_lbl_bg, >pop_lbl_fg, >pop_lbl_blink

; Labels as screen codes. Uppercase letters in screen RAM = $01-$1A.
; Space=$20, colon=$3A.
; Each label is exactly 14 chars (padded with spaces) then zero.
pop_lbl_drive:
    .byte $04,$12,$09,$16,$05,$3A,$20,$20,$20,$20,$20,$20,$20,$20, 0  ; "drive:        "
pop_lbl_border:
    .byte $02,$0F,$12,$04,$05,$12,$3A,$20,$20,$20,$20,$20,$20,$20, 0  ; "border:       "
pop_lbl_bg:
    .byte $02,$01,$03,$0B,$07,$12,$0F,$15,$0E,$04,$3A,$20,$20,$20, 0  ; "background:   "
pop_lbl_fg:
    .byte $14,$05,$18,$14,$20,$03,$0F,$0C,$0F,$12,$3A,$20,$20,$20, 0  ; "text color:   "
pop_lbl_blink:
    .byte $03,$15,$12,$13,$0F,$12,$20,$02,$0C,$09,$0E,$0B,$3A,$20, 0  ; "cursor blink: "


.include "colorize.asm"

; ============================================================================
; render_cursor_row — repaint ONLY the row the cursor is on.
;
; Used as a fast path after a printable insert when the viewport did not
; scroll (TOP_LINE and LEFT_COL unchanged). A printable insert only changes
; the current line, so repainting all 24 rows — each running the full
; keyword-matching colorizer — is wasted work. The full render_viewport costs
; ~220K cycles (~0.2s at 1MHz) per keystroke regardless of cursor position;
; this repaints a single row for a fraction of that.
;
; Requires CURSOR_ROW (0..23) to be current — caller runs ensure_cursor_visible
; first. Positions BUF_PTR at the cursor line's start and SCREEN_PTR at the
; target content row, then renders exactly one row by entering the shared
; row-render body with the row counter X=1 (rv_next_row's dex/beq returns).
; ============================================================================

render_cursor_row:
    ; BUF_PTR = start of the cursor's logical line.
    jsr line_start_of_cursor       ; -> WORK_PTR = line start
    lda WORK_PTR
    sta BUF_PTR
    lda WORK_PTR+1
    sta BUF_PTR+1
    jsr buf_ptr_warp               ; warp if line start sits at the gap

    ; SCREEN_PTR = CONTENT_TOP + CURSOR_ROW * COLS
    lda #<CONTENT_TOP
    sta SCREEN_PTR
    lda #>CONTENT_TOP
    sta SCREEN_PTR+1
    ldy CURSOR_ROW
    beq @row_ready
@row_add:
    clc
    lda SCREEN_PTR
    adc #COLS
    sta SCREEN_PTR
    bcc :+
    inc SCREEN_PTR+1
:   dey
    bne @row_add
@row_ready:
    ldx #1                         ; render exactly one row, then rv_next_row rts
    jmp rv_row_loop

; ============================================================================
; render_viewport — redraw rows 1..24 from TOP_LINE / LEFT_COL
; ============================================================================

render_viewport:
    lda TOP_LINE
    sta BUF_PTR
    lda TOP_LINE+1
    sta BUF_PTR+1
    jsr buf_ptr_warp

    lda #<CONTENT_TOP
    sta SCREEN_PTR
    lda #>CONTENT_TOP
    sta SCREEN_PTR+1

    ldx #CONTENT_ROWS              ; row counter, counts down

rv_row_loop:
    txa        ; save row counter on stack
    pha
    jsr colorize_row
    pla
    tax
    ; ---- 1. Skip LEFT_COL chars ----
    lda LEFT_COL
    beq @done_skip
    sta TMP
@skip_loop:
    jsr at_eof
    bcs @done_skip
    ldy #0
    lda (BUF_PTR),y
    cmp #PET_CR
    beq @done_skip
    jsr advance_buf
    dec TMP
    bne @skip_loop
@done_skip:

    ; ---- 2. Render up to 40 chars ----
    ldy #0
@render_loop:
    cpy #COLS
    beq @row_done
    jsr at_eof
    bcs @pad
    sty TMP
    ldy #0
    lda (BUF_PTR),y
    ldy TMP
    cmp #PET_CR
    beq @pad
    ; Buffer is plain PETSCII text — render every byte as a literal character.
    ; (Keywords are not tokenized in the buffer; bytes >= $80 are legitimate
    ; PETSCII graphics/shifted glyphs, not tokens.)
@rl_normal:
    jsr lookup_screen              ; preserves X and Y
    sta (SCREEN_PTR),y
    iny
    sty TMP
    jsr advance_buf
    ldy TMP
    jmp @render_loop

@pad:
    ; ---- 3. Pad rest of row with screen-space ----
    lda #SCR_SPACE
@pad_loop:
    cpy #COLS
    beq @row_done
    sta (SCREEN_PTR),y
    iny
    bne @pad_loop                  ; always taken (Y < 40)

@row_done:
    ; ---- 4. Walk forward to next CR + 1 ----
@scan_loop:
    jsr at_eof
    bcc @rv_not_eof
    jmp rv_next_row
@rv_not_eof:
    ldy #0
    lda (BUF_PTR),y
    cmp #PET_CR
    beq @past_cr
    jsr advance_buf
    jmp @scan_loop
@past_cr:
    jsr advance_buf
    jmp rv_next_row          ; advance SCREEN_PTR and loop for next row


; ============================================================================
; expand_token — expand a BASIC token byte to screen chars in render_viewport.
;
; On entry: A = token byte ($80-$CA), Y = current screen column (0-39)
; On exit:  Y = updated screen column (advanced by keyword length)
;           BUF_PTR advanced by 1 (past the token byte)
; Clobbers: A, X, WORK_PTR, CLR_TMP
;
; Uses the C64 BASIC 2.0 ROM keyword table at $A09E (visible with $01=$37).
; Each entry: PETSCII chars, last char has bit 7 set. Token $80 = entry 0.
; ============================================================================
expand_token:
    ; Save screen col (Y) to TMP, use Y=0 for ROM reads
    sty TMP
    ; Compute entry offset: token - $80
    sec
    sbc #$80
    sta SAVED_X                 ; SAVED_X = entries to skip (not clobbered by lookup_screen)

    lda #<$A09E
    sta WORK_PTR
    lda #>$A09E
    sta WORK_PTR+1

    ; Skip SAVED_X entries
@et_skip:
    lda SAVED_X
    beq @et_found
@et_skip_char:
    ldy #0
    lda (WORK_PTR),y
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   asl a                       ; old bit7 → carry (INC clobbered N, not A)
    bcc @et_skip_char           ; carry=0 → bit7 was 0 (non-last char) → loop
    dec SAVED_X
    jmp @et_skip

@et_found:
    ; Output chars from WORK_PTR to (SCREEN_PTR)+col
    ; TMP = screen col
@et_char:
    ldy #0
    lda (WORK_PTR),y
    sta CLR_TMP                 ; save with bit7
    and #$7F                    ; strip bit7 → PETSCII
    jsr lookup_screen           ; → screen code in A; X unchanged; SAVED_X clobbered (ok)
    ldy TMP                     ; screen col
    cpy #COLS
    bcs @et_done
    sta (SCREEN_PTR),y
    inc TMP                     ; advance screen col
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   lda CLR_TMP
    bpl @et_char                ; bit7 clear = more chars

@et_done:
    jsr advance_buf             ; advance BUF_PTR past the 1-byte token
    ldy TMP                     ; return updated screen col
    rts

; ============================================================================
; expand_extended_token — expand a custom token byte ($CC-$D8) to screen chars.
;
; Same calling convention as expand_token:
; On entry: A = token byte ($CC-$D8), Y = current screen column (0-39)
; On exit:  Y = updated screen column, BUF_PTR advanced past token
; Clobbers: A, WORK_PTR, CLR_TMP, TMP, SAVED_X
; Uses kw_strtab/kw_len_tab from colorize.asm (included below).
; ============================================================================
expand_extended_token:
    stx EXT_X_SAVE      ; save X without touching A
    sty TMP
    sec
    sbc #$80                    ; 0-based index into kw_strtab/kw_len_tab
    sta SAVED_X

    lda #<kw_strtab
    sta WORK_PTR
    lda #>kw_strtab
    sta WORK_PTR+1

    ldx #0
@ee_skip:
    cpx SAVED_X
    beq @ee_emit
    lda kw_len_tab,x
    clc
    adc WORK_PTR
    sta WORK_PTR
    bcc :+
    inc WORK_PTR+1
:   inx
    jmp @ee_skip

@ee_emit:
    ldx SAVED_X
    lda kw_len_tab,x
    sta CLR_TMP             ; char count — CLR_TMP is $19 = CLR_KWLEN, a real .res
    lda #0
    sta COL_SAVE            ; COL_SAVE ($12) = keyword char index
@ee_char:
    ldy COL_SAVE            ; Y = char index
    lda (WORK_PTR),y        ; read keyword char
    jsr lookup_screen       ; Y preserved (lookup_screen only touches A, X, SAVED_X)
    ldy TMP                 ; Y = screen col
    cpy #COLS
    bcs @ee_done
    sta (SCREEN_PTR),y      ; write to screen — (zp),Y is legal
    inc TMP                 ; advance screen col
    inc COL_SAVE            ; advance char index
    dec CLR_TMP             ; decrement count
    beq @ee_done
    jmp @ee_char
@ee_done:
    jsr advance_buf
    ldy TMP
    ldx EXT_X_SAVE      ; restore X
    rts
 
rv_next_row:
    clc
    lda SCREEN_PTR
    adc #COLS
    sta SCREEN_PTR
    bcc :+
    inc SCREEN_PTR+1
:
    dex
    beq @done
    jmp rv_row_loop
@done:
    rts

; ============================================================================
; advance_buf — BUF_PTR++; if it lands on GAP_START, jump to GAP_END.
; Preserves X and Y.
; ============================================================================

advance_buf:
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

buf_ptr_warp:
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
; at_eof — C=1 if BUF_PTR >= work_buf_end. Preserves X, Y. Trashes A.
; ============================================================================

at_eof:
    lda BUF_PTR+1
    cmp #>work_buf_end
    bne @done               ; hi bytes differ — carry set correctly
    lda BUF_PTR
    cmp #<work_buf_end      ; hi equal — compare lo bytes
@done:
    rts

; ============================================================================
; lookup_screen — A = PETSCII -> A = screen code. Preserves X, Y.
; ============================================================================

lookup_screen:
    stx SAVED_X
    tax
    lda screen_lookup,x
    ldx SAVED_X
    rts

; ============================================================================
; build_screen_lookup — fill the 256-byte conversion table at boot
; ============================================================================

build_screen_lookup:
    ldx #0
@loop:
    txa
    jsr convert_petscii
    sta screen_lookup,x
    inx
    bne @loop
    rts

convert_petscii:
    cmp #$20
    bcc @nondisp
    cmp #$40
    bcc @done
    cmp #$60
    bcc @sub40
    cmp #$80
    bcc @sub20
    cmp #$a0
    bcc @nondisp
    cmp #$c0
    bcc @sub40
    cmp #$ff
    bcc @sub80
    lda #$5e                       ; $FF -> pi
@done:
    rts
@nondisp:
    lda #SCR_SPACE
    rts
@sub40:
    sec
    sbc #$40
    rts
@sub20:
    sec
    sbc #$20
    rts
@sub80:
    sec
    sbc #$80
    rts

; ============================================================================
; cursor_right — move cursor one position right (gap slides right).
; ============================================================================
cursor_right:
    lda GAP_END                    ; at end of document?
    cmp #<work_buf_end
    bne @not_eod
    lda GAP_END+1
    cmp #>work_buf_end
    beq @done
@not_eod:
    ldy #0                         ; slide char from post-gap to pre-gap
    lda (GAP_END),y
    sta (GAP_START),y
    inc GAP_START                  ; advance both pointers
    bne :+
    inc GAP_START+1
:   inc GAP_END
    bne @done
    inc GAP_END+1
@done:
    rts

; ============================================================================
; cursor_left — move cursor one position left (gap slides left).
; ============================================================================
cursor_left:
    lda GAP_START                  ; at beginning of buffer?
    cmp #<work_buf
    bne @not_bof
    lda GAP_START+1
    cmp #>work_buf
    beq @done
@not_bof:
    lda GAP_START                  ; decrement both pointers
    bne :+
    dec GAP_START+1
:   dec GAP_START
    lda GAP_END
    bne :+
    dec GAP_END+1
:   dec GAP_END
    ldy #0                         ; slide char from pre-gap to post-gap
    lda (GAP_START),y
    sta (GAP_END),y
@done:
    rts

; ============================================================================
; get_col — return current column (0-based) in A.
; Walks backward from GAP_START through pre-gap text to nearest CR or BOF.
; Trashes WORK_PTR, TMP. Preserves X, Y.
; ============================================================================
get_col:
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    lda #0
    sta TMP                        ; column counter
@loop:
    lda WORK_PTR                   ; at BOF?
    cmp #<work_buf
    bne @dec
    lda WORK_PTR+1
    cmp #>work_buf
    beq @done
@dec:
    lda WORK_PTR                   ; WORK_PTR--
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    beq @done                      ; found CR: column = TMP
    inc TMP
    jmp @loop
@done:
    lda TMP
    rts

; ============================================================================
; line_start_of_cursor — WORK_PTR = address of the first byte of the line the
; cursor (GAP_START) is on; i.e. one past the preceding CR, or work_buf at BOF.
; Bounded by the current line's length. Trashes A; preserves X, Y.
; ============================================================================
line_start_of_cursor:
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
@back:
    lda WORK_PTR                   ; at BOF? -> line starts at work_buf
    cmp #<work_buf
    bne @dec
    lda WORK_PTR+1
    cmp #>work_buf
    beq @done
@dec:
    lda WORK_PTR                   ; WORK_PTR--
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    bne @back                      ; not a CR: keep walking back
    inc WORK_PTR                   ; step past the CR onto the line start
    bne @done
    inc WORK_PTR+1
@done:
    rts

; ============================================================================
; cursor_down — move cursor to the same column on the next line.
; ============================================================================
cursor_down:
    jsr get_col
    sta COL_SAVE
@skip_rest:                        ; walk forward to CR or EOD
    lda GAP_END
    cmp #<work_buf_end
    bne :+
    lda GAP_END+1
    cmp #>work_buf_end
    beq @done                      ; at EOD, nowhere to go
:   ldy #0
    lda (GAP_END),y
    cmp #PET_CR
    beq @found_cr
    jsr cursor_right
    jmp @skip_rest
@found_cr:
    jsr cursor_right               ; step past the CR onto next line
    lda COL_SAVE
    beq @done
@advance:                          ; move right COL_SAVE chars on new line
    lda GAP_END
    cmp #<work_buf_end
    bne :+
    lda GAP_END+1
    cmp #>work_buf_end
    beq @done
:   ldy #0
    lda (GAP_END),y
    cmp #PET_CR
    beq @done
    jsr cursor_right
    dec COL_SAVE
    bne @advance
@done:
    rts

; ============================================================================
; cursor_up — move cursor to the same column on the previous line.
; ============================================================================
cursor_up:
    jsr get_col
    sta COL_SAVE
@find_cur_start:                   ; walk left to start of current line
    lda GAP_START                  ; at BOF? cursor is on line 0, can't go up
    cmp #<work_buf
    bne :+
    lda GAP_START+1
    cmp #>work_buf
    beq @done
:   lda GAP_START                  ; peek at char just before cursor
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    beq @at_cur_start              ; CR before cursor = we're at line start
    jsr cursor_left
    jmp @find_cur_start
@at_cur_start:
    jsr cursor_left                ; cross the CR into the previous line
@find_prev_start:                  ; walk left to start of previous line
    lda GAP_START
    cmp #<work_buf
    bne :+
    lda GAP_START+1
    cmp #>work_buf
    beq @at_prev_start             ; BOF = start of prev line
:   lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    beq @at_prev_start             ; CR before cursor = start of prev line
    jsr cursor_left
    jmp @find_prev_start
@at_prev_start:
    lda COL_SAVE
    beq @done
@advance_prev:                     ; move right COL_SAVE chars on prev line
    lda GAP_END
    cmp #<work_buf_end
    bne :+
    lda GAP_END+1
    cmp #>work_buf_end
    beq @done
:   ldy #0
    lda (GAP_END),y
    cmp #PET_CR
    beq @done
    jsr cursor_right
    dec COL_SAVE
    bne @advance_prev
@done:
    rts

; ============================================================================
; page_down — move cursor CONTENT_ROWS lines forward (page down).
; Uses TMP+1 as loop counter; cursor_down only touches TMP (lo), so safe.
; ============================================================================
page_down:
    lda #CONTENT_ROWS
    sta TMP+1
@loop:
    jsr cursor_down
    dec TMP+1
    bne @loop
    rts

; ============================================================================
; page_up — move cursor CONTENT_ROWS lines backward (page up).
; ============================================================================
page_up:
    lda #CONTENT_ROWS
    sta TMP+1
@loop:
    jsr cursor_up
    dec TMP+1
    bne @loop
    rts

; ============================================================================
; ensure_cursor_visible — adjust TOP_LINE/LEFT_COL so cursor is on-screen.
; Computes CURSOR_ROW (0..23) and CURSOR_COL (visual, 0..39).
; ============================================================================
; -----------------------------------------------------------------------------
; PERFORMANCE NOTE (cursor positioning):
;
; The original implementation walked forward from TOP_LINE to GAP_START one
; byte at a time on every call, counting rows and columns. That made the cost
; proportional to the amount of text ABOVE the cursor in the viewport, so each
; keystroke got slower the further down the screen the cursor sat — and typing
; a single line was quadratic in its length (every character re-walked all the
; preceding text). On a 1MHz 6510 this was visible as letters crawling onto the
; bottom rows.
;
; This version never walks the whole pre-cursor span. It does two bounded
; things instead:
;   1. CURSOR_COL comes from get_col, which walks back only to the nearest CR
;      (bounded by line length, ~0..line-length).
;   2. The row is found by walking BACKWARD from the cursor's line start,
;      counting line starts, stopping the instant we reach TOP_LINE (row = the
;      count) or exceed the viewport (re-anchor down). Worst case is one
;      screen-height of content, never the full document or the cursor's depth.
; The gap buffer (GAP_START/GAP_END) remains the single source of truth for the
; cursor; nothing here caches a parallel position that could desync.
; -----------------------------------------------------------------------------
ensure_cursor_visible:
    ; ---- Is cursor above TOP_LINE? (GAP_START < TOP_LINE, 16-bit) ----
    lda GAP_START+1
    cmp TOP_LINE+1
    bcc @cursor_above
    bne @find_row
    lda GAP_START
    cmp TOP_LINE
    bcc @cursor_above

@find_row:
    ; WORK_PTR = start of the cursor's current line (walk back to CR/BOF).
    ; This is bounded by the current line's length.
    jsr line_start_of_cursor       ; -> WORK_PTR = cursor line start
    ; If that line start is already <= TOP_LINE, the cursor line IS at/above
    ; the top; row 0 (the == case) is the normal "typing on the top line".
    lda WORK_PTR+1
    cmp TOP_LINE+1
    bcc @cursor_above              ; line start strictly above TOP_LINE
    bne @count_rows
    lda WORK_PTR
    cmp TOP_LINE
    bcc @cursor_above
    ; line start >= TOP_LINE: count line starts from TOP_LINE up to here.
@count_rows:
    lda #0
    sta CURSOR_ROW
    ; Walk WORK_PTR backward, counting CRs crossed, until it reaches TOP_LINE.
    ; Bounded by viewport height: if the count reaches CONTENT_ROWS the cursor
    ; is below the visible region and we re-anchor.
@cr_back:
    lda WORK_PTR                   ; at TOP_LINE? (done)
    cmp TOP_LINE
    bne @cr_step
    lda WORK_PTR+1
    cmp TOP_LINE+1
    beq @row_done
@cr_step:
    ; WORK_PTR-- ; if the byte we step onto is a CR, we've crossed a line.
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    bne @cr_back
    inc CURSOR_ROW
    lda CURSOR_ROW
    cmp #CONTENT_ROWS
    bcs @cursor_below              ; past last visible row — re-anchor down
    jmp @cr_back
@row_done:
    jsr get_col                    ; bounded: walks back to nearest CR only
    sta CURSOR_COL
    jmp @apply_hscroll

@cursor_above:
    ; Re-anchor TOP_LINE to start of cursor's line, then redo.
    jsr line_start_of_cursor
    lda WORK_PTR
    sta TOP_LINE
    lda WORK_PTR+1
    sta TOP_LINE+1
    jmp ensure_cursor_visible

@cursor_below:
    ; Walk backward from cursor (GAP_START) through pre-gap content to find
    ; the line that belongs at the top of the viewport. Bounded by
    ; CONTENT_ROWS lines of backward scanning.
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    lda #(CONTENT_ROWS - 1)
    sta TMP+1               ; TMP+1: line counter (this routine uses TMP lo only)
@cb_back:
    lda WORK_PTR            ; at BOF?
    cmp #<work_buf
    bne @cb_dec
    lda WORK_PTR+1
    cmp #>work_buf
    beq @cb_set_top         ; BOF = start of first line
@cb_dec:
    lda WORK_PTR            ; WORK_PTR--
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    bne @cb_back
    dec TMP+1
    bne @cb_back            ; need more lines
    ; Found the CR that precedes the target top line — step past it
    inc WORK_PTR
    bne @cb_set_top
    inc WORK_PTR+1
@cb_set_top:
    lda WORK_PTR
    sta TOP_LINE
    lda WORK_PTR+1
    sta TOP_LINE+1
    jmp ensure_cursor_visible

@apply_hscroll:
    lda CURSOR_COL
    cmp LEFT_COL
    bcs @check_right
    sta LEFT_COL
@check_right:
    lda LEFT_COL
    clc
    adc #(COLS - 1)
    cmp CURSOR_COL
    bcs @to_visual
    lda CURSOR_COL
    sec
    sbc #(COLS - 1)
    sta LEFT_COL
@to_visual:
    lda CURSOR_COL
    sec
    sbc LEFT_COL
    sta CURSOR_COL
    rts

; ============================================================================
; compute_cursor_addr — WORK_PTR = screen RAM address of cursor cell.
; ============================================================================
compute_cursor_addr:
    lda #0
    sta TMP
    sta TMP+1
    ldx CURSOR_ROW
    beq @add_col
@mul:
    lda TMP
    clc
    adc #COLS
    sta TMP
    bcc :+
    inc TMP+1
:   dex
    bne @mul
@add_col:
    lda TMP
    clc
    adc CURSOR_COL
    sta TMP
    bcc :+
    inc TMP+1
:   lda #<CONTENT_TOP
    clc
    adc TMP
    sta WORK_PTR
    lda #>CONTENT_TOP
    adc TMP+1
    sta WORK_PTR+1
    rts

; ============================================================================
; draw_cursor — invert cursor cell (set bit 7 = reverse-video glyph).
; ============================================================================
draw_cursor:
    jsr compute_cursor_addr
    ldy #0
    lda (WORK_PTR),y
    ora #$80
    sta (WORK_PTR),y
    rts

; ============================================================================
; erase_cursor — restore cursor cell (clear bit 7).
; ============================================================================
erase_cursor:
    jsr compute_cursor_addr
    ldy #0
    lda (WORK_PTR),y
    and #$7F
    sta (WORK_PTR),y
    rts

; ============================================================================
; do_insert — insert character in A at the cursor. Silently drops if gap full.
; ============================================================================
do_insert:
    pha                            ; save char across gap check
    lda GAP_START
    cmp GAP_END
    bne @has_room
    lda GAP_START+1
    cmp GAP_END+1
    beq @full
@has_room:
    pla
    ldy #0
    sta (GAP_START),y              ; write char into gap
    inc GAP_START
    bne @done
    inc GAP_START+1
@done:
    rts
@full:
    pla
    rts

; ============================================================================
; insert_return — insert a CR at the cursor, with BASIC auto-line-numbering.
;
; The buffer is kept in plain PETSCII text throughout (keywords are matched by
; the colorizer and tokenized only transiently by MODTOK at save time), so we
; do NOT tokenize the line here.
;
; Auto-numbering fires only when ALL of these hold:
;   - IS_BASIC is set (assembly source is never auto-numbered)
;   - the cursor is at end-of-line (char to the right is CR or EOF) — pressing
;     RETURN mid-line to split it must NOT inject a number
;   - the current line begins with a decimal line number N
; When it fires we compute the next number from N and the following line's
; number M (if any):
;   - no next line            -> N + 10
;   - gap (M-N) > 10          -> N + 10   (plenty of room, incl. huge gaps)
;   - gap <= 1                -> no room: plain CR, user must renumber
;   - otherwise               -> N + gap/2   (insert halfway)
; The number is inserted as PETSCII digits followed by a space, all via
; do_insert, so it is ordinary editable text (backspace removes it normally).
;
; ZP scratch used: AN_CUR (N), AN_NEXT (M / next), AN_TMP. These are BSS-backed
; 16-bit cells (see declarations near the editor's other scratch).
; ============================================================================
insert_return:
    ; Always insert the CR first; the cursor (GAP_START) advances past it.
    lda #PET_CR
    jsr do_insert

    ; Only auto-number BASIC programs.
    lda IS_BASIC
    beq @plain                      ; $00 = plain text → done

    ; End-of-line check: the char to the RIGHT of the cursor is at GAP_END
    ; (post-gap). If that's the buffer end, or a CR, we were at end-of-line.
    ; (After inserting the CR above, GAP_END is unchanged — it still points at
    ; the first post-gap byte, i.e. the original char to the right of cursor.)
    lda GAP_END
    cmp #<work_buf_end
    bne @check_right_char
    lda GAP_END+1
    cmp #>work_buf_end
    beq @at_eol                     ; cursor was at very end of buffer
@check_right_char:
    ldy #0
    lda (GAP_END),y
    cmp #PET_CR
    bne @plain                      ; mid-line split → no auto-number
@at_eol:
    ; Find the number N of the line we just finished. That line's text is the
    ; pre-gap run ending just before the CR we inserted. Walk WORK_PTR back from
    ; (GAP_START - 1) [the inserted CR] over the line body to its start (BOF or
    ; a preceding CR), then parse the leading digits.
    jsr an_find_cur_line_start      ; WORK_PTR = first byte of current line (pre-gap)
    jsr an_parse_number             ; C=0 and AN_CUR=N if a number was found
    bcs @plain                      ; no leading number → plain CR

    ; Find the next line's number M by scanning the post-gap text from GAP_END
    ; to the next CR, then parsing digits after it. C=1 → no next line.
    jsr an_find_next_number         ; C=0 and AN_NEXT=M, or C=1 (none)
    bcs @use_plus10                 ; last line → N + 10

    ; gap = M - N  (AN_NEXT - AN_CUR), 16-bit
    sec
    lda AN_NEXT
    sbc AN_CUR
    sta AN_TMP
    lda AN_NEXT+1
    sbc AN_CUR+1
    sta AN_TMP+1                     ; AN_TMP = gap

    ; gap <= 1 ? (hi==0 and lo<=1) → no room, plain CR
    lda AN_TMP+1
    bne @gap_big_or_mid             ; hi != 0 → gap >= 256, definitely > 10
    lda AN_TMP
    cmp #2
    bcc @plain                      ; gap 0 or 1 → no room
    ; gap < 256 here. > 10 ?
    cmp #11
    bcs @use_plus10                 ; gap > 10 → N + 10
    ; gap in 2..10 → halfway: N + gap/2
    lsr                              ; A = gap/2 (gap fits in one byte, hi=0)
    clc
    adc AN_CUR
    sta AN_CUR
    lda AN_CUR+1
    adc #0
    sta AN_CUR+1
    jmp @emit

@gap_big_or_mid:
    ; gap >= 256 → always plenty of room → N + 10
@use_plus10:
    clc
    lda AN_CUR
    adc #10
    sta AN_CUR
    lda AN_CUR+1
    adc #0
    sta AN_CUR+1
    ; fall through

@emit:
    ; Range guard: CBM BASIC line numbers max at 63999. If the computed number
    ; reached 64000+ (hi byte >= $FA), there's no valid number to insert — fall
    ; back to a plain CR (same ceiling MODREN uses).
    lda AN_CUR+1
    cmp #$FA
    bcs @plain
    ; Write AN_CUR as PETSCII decimal, then a trailing space, via do_insert.
    jsr an_emit_number
    lda #PET_SPACE
    jsr do_insert
@plain:
    rts

; ----------------------------------------------------------------------------
; an_find_cur_line_start — set WORK_PTR to the first byte of the line that ends
; at the CR just inserted (the byte right before GAP_START). Walks backward
; through pre-gap text to BOF or the CR that precedes this line.
; On return WORK_PTR points at the first character of the current line.
; Note: operates entirely in the pre-gap region, so no gap warp is needed.
; ----------------------------------------------------------------------------
an_find_cur_line_start:
    ; WORK_PTR = GAP_START - 1  (the CR we just inserted)
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    ; step back over the inserted CR
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
@back:
    ; at BOF? (WORK_PTR == work_buf)
    lda WORK_PTR
    cmp #<work_buf
    bne @dec
    lda WORK_PTR+1
    cmp #>work_buf
    beq @at_start                   ; reached beginning of buffer
@dec:
    ; peek the byte one to the left; if it's a CR, current line starts here
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    bne @back
    ; WORK_PTR is on the preceding CR — line starts one byte right
    inc WORK_PTR
    bne @at_start
    inc WORK_PTR+1
@at_start:
    rts

; ----------------------------------------------------------------------------
; an_parse_number — parse decimal digits at WORK_PTR (pre-gap) into AN_CUR.
; C=0 if at least one digit was parsed (AN_CUR = value), C=1 if no digit.
; Stops at first non-digit. 16-bit, handles up to 63999.
; ----------------------------------------------------------------------------
an_parse_number:
    lda #0
    sta AN_CUR
    sta AN_CUR+1
    ldy #0
    lda (WORK_PTR),y
    jsr an_is_digit
    bcc @nodigit
@loop:
    ldy #0
    lda (WORK_PTR),y
    jsr an_is_digit
    bcc @done
    ; AN_CUR = AN_CUR*10 + (A-'0')
    sec
    sbc #PET_0
    pha
    jsr an_cur_mul10
    pla
    clc
    adc AN_CUR
    sta AN_CUR
    bcc :+
    inc AN_CUR+1
:   ; advance WORK_PTR (pre-gap, no warp)
    inc WORK_PTR
    bne @loop
    inc WORK_PTR+1
    jmp @loop
@done:
    clc
    rts
@nodigit:
    sec
    rts

; AN_CUR *= 10  (= *8 + *2). Uses AN_TMP. Preserves A? No — caller saves A.
an_cur_mul10:
    lda AN_CUR
    sta AN_TMP
    lda AN_CUR+1
    sta AN_TMP+1
    asl AN_CUR
    rol AN_CUR+1                     ; *2
    asl AN_CUR
    rol AN_CUR+1                     ; *4
    asl AN_CUR
    rol AN_CUR+1                     ; *8
    asl AN_TMP
    rol AN_TMP+1                     ; AN_TMP = orig*2
    lda AN_CUR
    clc
    adc AN_TMP
    sta AN_CUR
    lda AN_CUR+1
    adc AN_TMP+1
    sta AN_CUR+1
    rts

; ----------------------------------------------------------------------------
; an_find_next_number — scan post-gap text from GAP_END to the next CR, then
; parse the digits immediately after it into AN_NEXT.
; C=0 and AN_NEXT = M if a following numbered line exists; C=1 if EOF reached
; first (no next line) or the next line has no leading digit.
; Uses BUF_PTR as a scratch walker (restored by caller's redraw path; the
; editor recomputes BUF_PTR via ensure_cursor_visible after RETURN).
; ----------------------------------------------------------------------------
an_find_next_number:
    lda GAP_END
    sta BUF_PTR
    lda GAP_END+1
    sta BUF_PTR+1
    jmp @scan
@none_tramp:                        ; near trampoline — @none is >127 bytes away
    jmp @none
@scan:
@find_cr:
    ; at EOF? (BUF_PTR == work_buf_end)
    lda BUF_PTR+1
    cmp #>work_buf_end
    bne @rd
    lda BUF_PTR
    cmp #<work_buf_end
    beq @none_tramp
@rd:
    ldy #0
    lda (BUF_PTR),y
    cmp #PET_CR
    beq @after_cr
    ; advance (post-gap only; no gap to cross going forward from GAP_END)
    inc BUF_PTR
    bne @find_cr
    inc BUF_PTR+1
    jmp @find_cr
@after_cr:
    ; step past the CR to the first char of the next line
    inc BUF_PTR
    bne :+
    inc BUF_PTR+1
:   ; at EOF right after CR? then no next line content
    lda BUF_PTR+1
    cmp #>work_buf_end
    bne @parse
    lda BUF_PTR
    cmp #<work_buf_end
    beq @none_tramp
@parse:
    ; parse digits at BUF_PTR into AN_NEXT
    lda #0
    sta AN_NEXT
    sta AN_NEXT+1
    ldy #0
    lda (BUF_PTR),y
    jsr an_is_digit
    bcc @none                       ; next line has no number
@nloop:
    ldy #0
    lda (BUF_PTR),y
    jsr an_is_digit
    bcc @ok
    sec
    sbc #PET_0
    pha
    ; AN_NEXT *= 10 via AN_TMP
    lda AN_NEXT
    sta AN_TMP
    lda AN_NEXT+1
    sta AN_TMP+1
    asl AN_NEXT
    rol AN_NEXT+1
    asl AN_NEXT
    rol AN_NEXT+1
    asl AN_NEXT
    rol AN_NEXT+1
    asl AN_TMP
    rol AN_TMP+1
    lda AN_NEXT
    clc
    adc AN_TMP
    sta AN_NEXT
    lda AN_NEXT+1
    adc AN_TMP+1
    sta AN_NEXT+1
    pla
    clc
    adc AN_NEXT
    sta AN_NEXT
    bcc :+
    inc AN_NEXT+1
:   inc BUF_PTR
    bne @nloop
    inc BUF_PTR+1
    jmp @nloop
@ok:
    clc
    rts
@none:
    sec
    rts

; ----------------------------------------------------------------------------
; an_emit_number — write AN_CUR as PETSCII decimal (no leading zeros) via
; do_insert. Range 0..63999. Uses AN_TMP, AN_NEXT as scratch (AN_NEXT free here).
; ----------------------------------------------------------------------------
an_emit_number:
    lda #0
    sta AN_LEADING                  ; 0 = still suppressing leading zeros
    ldx #0                          ; divisor index 0..3 (10000,1000,100,10)
@digit:
    ; AN_NEXT = current divisor
    lda an_div_lo,x
    sta AN_NEXT
    lda an_div_hi,x
    sta AN_NEXT+1
    lda #0
    sta AN_TMP                      ; AN_TMP = digit count (single byte; <10)
@sub:
    ; if AN_CUR < divisor, stop
    lda AN_CUR+1
    cmp AN_NEXT+1
    bcc @emit_digit
    bne @do_sub
    lda AN_CUR
    cmp AN_NEXT
    bcc @emit_digit
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
@emit_digit:
    lda AN_TMP
    bne @nonzero
    ; digit is zero — emit only if we've already emitted a nonzero digit
    lda AN_LEADING
    beq @skip
    lda #PET_0
    jsr do_insert
    jmp @skip
@nonzero:
    lda #$FF
    sta AN_LEADING
    lda AN_TMP
    ora #PET_0
    jsr do_insert
@skip:
    inx
    cpx #4
    bne @digit
    ; units digit always emitted
    lda AN_CUR                      ; remainder 0..9
    ora #PET_0
    jsr do_insert
    rts

an_div_lo: .byte <10000, <1000, <100, <10
an_div_hi: .byte >10000, >1000, >100, >10

; ----------------------------------------------------------------------------
; an_is_digit — C=1 if A is PETSCII '0'..'9', else C=0. Preserves A.
; ----------------------------------------------------------------------------
an_is_digit:
    cmp #PET_0
    bcc @no
    cmp #PET_9+1
    bcs @no
    sec
    rts
@no:
    clc
    rts

; ============================================================================
; do_backspace — delete the character to the left of the cursor.
; ============================================================================
do_backspace:
    lda GAP_START                  ; at BOF?
    cmp #<work_buf
    bne @not_bof
    lda GAP_START+1
    cmp #>work_buf
    beq @done
@not_bof:
    lda GAP_START
    bne :+
    dec GAP_START+1
:   dec GAP_START
@done:
    rts

; ============================================================================
; do_tab_complete — CTRL+I keyword completion
;
; Completes the alphabetic word immediately before the cursor to the next
; BASIC keyword whose name starts with that prefix (scanning kw_strtab in
; token order, $80..$D8).  Successive CTRL+I presses cycle through all
; matching keywords, wrapping at the end.  When the scan exhausts all
; matches the previously-completed keyword is silently restored and the
; cycling session ends (COMPL_ACTIVE cleared), so the next CTRL+I starts
; fresh from $80 again.
;
; Only completes when the cursor is immediately AFTER the partial word
; with no alphabetic char immediately to the right (guards against
; completing mid-word).
;
; State (BSS):
;   COMPL_ACTIVE  $FF = cycling; $00 = idle (cleared by main_loop on any
;                 non-CTRL+I key, so cursor moves, edits, etc. end a session)
;   COMPL_PFXLEN  length of the original typed prefix (1..8), preserved
;                 across cycling so the comparison stays anchored
;   COMPL_TOK     token of the last completion ($80..$D8)
;   TC_DELCNT     chars removed from GAP_START; used to restore on no-match
;
; ZP used:  WORK_PTR (backward scan + kw_strtab walk),
;           TMP      (pointer to prefix chars in gap, for comparison),
;           KW_TOKEN ($3A, current token during scan; safe to alias here
;                     because tab completion never overlaps colorization)
; Clobbers: A, X, Y
; ============================================================================

do_tab_complete:
    lda COMPL_ACTIVE
    bne @cycling

; ---- Fresh: count the alphabetic prefix immediately before GAP_START ------
@fresh:
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    lda #0
    sta COMPL_PFXLEN

@pfx_loop:
    ; Stop at BOF
    lda WORK_PTR
    cmp #<work_buf
    bne @pfx_dec
    lda WORK_PTR+1
    cmp #>work_buf
    beq @pfx_done
@pfx_dec:
    lda WORK_PTR
    bne @pfx_noh
    dec WORK_PTR+1
@pfx_noh:
    dec WORK_PTR
    ldy #0
    lda (WORK_PTR),y
    cmp #$41                    ; < 'A'?
    bcc @pfx_done
    cmp #$5B                    ; > 'Z' (i.e. $5A)?
    bcs @pfx_done
    inc COMPL_PFXLEN
    jmp @pfx_loop

@pfx_done:
    lda COMPL_PFXLEN
    bne @pfx_nonzero
    jmp @tc_rts                 ; nothing to complete
@pfx_nonzero:

    ; Guard: don't complete if cursor is mid-word (alpha char right of cursor)
    lda GAP_END
    cmp #<work_buf_end
    bne @chk_trail
    lda GAP_END+1
    cmp #>work_buf_end
    beq @fresh_go               ; at EOF, no trailing char
@chk_trail:
    ldy #0
    lda (GAP_END),y
    cmp #$41
    bcc @fresh_go
    cmp #$5B
    bcs @fresh_go               ; >= $5B: not a letter, proceed
    jmp @tc_rts                 ; $41..$5A: trailing letter, bail

@fresh_go:
    ; Rewind GAP_START by COMPL_PFXLEN to expose the prefix chars for comparison.
    ; They remain physically in the buffer at [new GAP_START .. GAP_START + PFXLEN - 1].
    lda COMPL_PFXLEN
    sta TC_DELCNT
    jsr tc_rewind_gap
    lda #$80
    sta COMPL_TOK
    jmp @do_scan

; ---- Cycling: undo current completion, step to the next token -------------
@cycling:
    ; Delete count = full length of the currently-displayed keyword.
    lda COMPL_TOK
    sec
    sbc #$80
    tax
    lda kw_len_tab,x
    sta TC_DELCNT
    jsr tc_rewind_gap
    ; Advance COMPL_TOK, wrapping $D8 -> $80.
    inc COMPL_TOK
    lda COMPL_TOK
    cmp #$D9
    bcc @do_scan
    lda #$80
    sta COMPL_TOK
    ; fall through into @do_scan

; ---- Scan kw_strtab from COMPL_TOK onward for a prefix match --------------
@do_scan:
    ; TMP = GAP_START = first byte of the exposed prefix (in the gap hole).
    lda GAP_START
    sta TMP
    lda GAP_START+1
    sta TMP+1

    ; WORK_PTR = kw_strtab base; KW_TOKEN ($3A) walks token bytes $80..$D8.
    lda #<kw_strtab
    sta WORK_PTR
    lda #>kw_strtab
    sta WORK_PTR+1
    lda #$80
    sta KW_TOKEN

    ; Skip entries that precede COMPL_TOK.
@scan_skip:
    lda KW_TOKEN
    cmp COMPL_TOK
    beq @scan_try
    sec
    sbc #$80
    tax
    lda kw_len_tab,x
    clc
    adc WORK_PTR
    sta WORK_PTR
    bcc @scan_skip_noh
    inc WORK_PTR+1
@scan_skip_noh:
    inc KW_TOKEN
    jmp @scan_skip

    ; Try matching KW_TOKEN's keyword against the prefix.
@scan_try:
    lda KW_TOKEN
    cmp #$D9                    ; past last keyword?
    bcc @scan_try_cont
    jmp @no_match
@scan_try_cont:
    sec
    sbc #$80
    tax
    lda kw_len_tab,x            ; keyword length
    cmp COMPL_PFXLEN
    bcs @scan_try_cmp           ; length >= pfxlen, proceed to compare
    jmp @scan_next              ; shorter than prefix — impossible match
@scan_try_cmp:

    ; Compare first COMPL_PFXLEN chars of keyword against prefix in gap.
    ; WORK_PTR -> keyword, TMP -> prefix chars (both uppercase PETSCII).
    ldy #0
@cmp_loop:
    cpy COMPL_PFXLEN
    beq @match                  ; all prefix chars matched
    lda (WORK_PTR),y            ; keyword char
    cmp (TMP),y                 ; prefix char in buffer
    bne @scan_next              ; mismatch
    iny
    jmp @cmp_loop

@scan_next:
    ; Advance WORK_PTR past this keyword's chars; bump token.
    ; X = KW_TOKEN - $80 is still valid from @scan_try_cont on both paths here.
    lda kw_len_tab,x
    clc
    adc WORK_PTR
    sta WORK_PTR
    bcc @scan_nxt_noh
    inc WORK_PTR+1
@scan_nxt_noh:
    inc KW_TOKEN
    jmp @scan_try

; ---- Match: insert the full keyword into the gap --------------------------
; WORK_PTR points to the keyword's start in kw_strtab; KW_TOKEN is the token.
; X = KW_TOKEN - $80 on entry (set by @scan_try_cont, not clobbered by @cmp_loop).
@match:
    lda KW_TOKEN
    sta COMPL_TOK
    lda kw_len_tab,x        ; X still = KW_TOKEN - $80; lda/sta below don't touch X
    sta TC_DELCNT               ; down-counter for insert loop
    lda #$FF
    sta COMPL_ACTIVE
    ; Insert loop: ldy #0 each iteration because do_insert clobbers Y.
@ins_loop:
    lda TC_DELCNT
    beq @ins_done
    ldy #0
    lda (WORK_PTR),y
    jsr do_insert
    inc WORK_PTR
    bne @ins_noh
    inc WORK_PTR+1
@ins_noh:
    dec TC_DELCNT
    jmp @ins_loop

@ins_done:
    lda #$FF
    sta IS_DIRTY
    ; Fast-path render: if LEFT_COL didn't change, repaint only the cursor row.
    lda LEFT_COL
    sta FP_LEFT_SAVE            ; borrow the existing scroll-detect scratch
    jsr ensure_cursor_visible
    lda LEFT_COL
    cmp FP_LEFT_SAVE
    bne @full_render
    jsr render_cursor_row
    jsr draw_cursor
    rts
@full_render:
    jsr render_viewport
    jsr draw_cursor
    rts

; ---- No match: restore GAP_START; reset cycling state ---------------------
@no_match:
    ; The chars are still physically in the buffer.  Re-advancing GAP_START
    ; by TC_DELCNT bytes restores the previous visible state with zero copies.
    lda TC_DELCNT
    clc
    adc GAP_START
    sta GAP_START
    bcc @nm_noh
    inc GAP_START+1
@nm_noh:
    lda #$00
    sta COMPL_ACTIVE
@tc_rts:
    rts

; ============================================================================
; tc_rewind_gap — decrement GAP_START by A bytes.
; Equivalent to A calls to do_backspace, no BOF check needed since
; COMPL_PFXLEN was measured from actual buffer content.
; Clobbers: A, X
; ============================================================================
tc_rewind_gap:
    beq @rw_done        ; A=0: nothing to rewind (guard against 256-decrement wrap)
    tax
@rw_loop:
    lda GAP_START
    bne @rw_noh
    dec GAP_START+1
@rw_noh:
    dec GAP_START
    dex
    bne @rw_loop
@rw_done:
    rts
    
.include "modules.asm"

; ============================================================================
; Hardcoded test buffer (cold-start content — remove once file load works)
; ============================================================================

; ============================================================================
; test_buffer — plain-PETSCII BASIC source used on cold start.
; The buffer is kept in plain text throughout; colorize_row matches keyword
; strings and render_viewport renders bytes literally.
; ============================================================================

test_buffer:
    .byte "10 print ", $22, "hello, petproject!", $22, PET_CR
    .byte "20 for i=1 to 10", PET_CR
    .byte "30   print i, i*i, i*i*i", PET_CR
    .byte "40 next i", PET_CR
    .byte "50 goto 10", PET_CR
    .byte PET_CR
    .byte "rem a longer line for testing horizontal scroll later on.", PET_CR
    .byte "60 end", PET_CR
    .byte PET_CR
buffer_end:

; ============================================================================
; Uninitialized data (BSS)
; ============================================================================

.segment "BSS"

; Screen code lookup table
screen_lookup:   .res 256

; ---- Settings block ----
; All runtime-mutable settings live here. init_settings writes defaults;
; load_settings will overlay from petproject.cfg once that is implemented.
; The order and offsets of this block are referenced in the save_settings
; implementation notes — keep them stable or update both together.

SETTING_DRIVE:  .res 1             ; device number for file I/O (default 8, range 8–11)
SETTING_BORDER: .res 1             ; border color (C64 color index 0–15)
SETTING_BG:     .res 1             ; background color (C64 color index 0–15)
SETTING_FG:     .res 1             ; foreground / text color (C64 color index 0–15)
SETTING_BLINK:  .res 1             ; cursor blink: 0=off, 1=on

MOD_LOADED:           .res 1   ; $FF = none loaded
SETTING_TOKENIZE_SAVE:.res 1   ; 0=plain text, 1=tokenize on save
MOD_SEL_ROW:          .res 1   ; currently selected row in picker
MOD_ITEM_TMP:         .res 1
MOD_TMP:              .res 1   ; scratch byte for module popup

; ---- Settings popover scratch ----
SETTINGS_ROW:     .res 1          ; currently highlighted row (0..SET_ROW_MAX)
SETTINGS_ROW_TMP: .res 1          ; loop counter in settings_draw_all
POP_ROW_CTR:      .res 1          ; row counter in settings_draw_box side loop
POP_ROW_TMP:      .res 1          ; screen row number of current settings row being drawn
POP_LBL_IDX:      .res 1          ; byte index into current label string
POP_CHAR_TMP:     .res 1          ; single-char scratch for settings renderer

; ---- File I/O scratch ----
FNAME_BUF:       .res 16            ; filename entered by user (PETSCII, not NUL-term)
FNAME_LEN:       .res 1             ; length of FNAME_BUF content
IO_STATUS:       .res 1             ; ST value captured after file operations
PROMPT_IS_SAVE:  .res 1
LOAD_AS_SOURCE:  .res 1             ; F6 load: 1 = force SEQ source (",S,R", no
                                   ; BASIC/ML detection); 0 = normal F3 behavior
IO_END_LO:       .res 1
IO_END_HI:       .res 1
IO_SCRATCH:      .res 1
IO_NAME_BUF:     .res 24            ; "@0:"+name(16)+",S,W" worst case = 23
IO_NAME_BUF_LEN: .res 1
IS_BASIC:        .res 1   ; $FF = BASIC program, $00 = plain text
IS_NEW_FILE:     .res 1   ; $FF = new unsaved file
IS_DIRTY:        .res 1   ; $FF = buffer modified since last save/load
EXT_X_SAVE:      .res 1     ; in BSS — render_viewport row counter save
FP_TOP_SAVE:     .res 2     ; saved TOP_LINE for fast-path scroll detection
FP_LEFT_SAVE:    .res 1     ; saved LEFT_COL for fast-path scroll detection
COL_PEEK:        .res 9     ; gap-aware lookahead buffer for col_match_kw (longest kw = 8)

; ---- Auto-line-numbering scratch (insert_return) ----
AN_CUR:          .res 2     ; current line number N (then computed next number)
AN_NEXT:         .res 2     ; next line number M (also divisor scratch in emit)
AN_TMP:          .res 2     ; 16-bit scratch (gap, mul10 temp)
AN_LEADING:      .res 1     ; 0 = suppressing leading zeros in an_emit_number

; ---- Tab completion state ----
COMPL_ACTIVE: .res 1    ; $FF = cycling in progress, $00 = idle
COMPL_PFXLEN: .res 1    ; length of the original typed prefix (1..8)
COMPL_TOK:    .res 1    ; BASIC token of the last completion ($80..$D8)
TC_DELCNT:    .res 1    ; chars removed from gap (used to restore on no-match)

; ---- Editor buffer ----
work_buf:      .res BUF_SIZE
work_buf_end:                      ; label sits immediately after work_buf
.segment "CODE"





; ============================================================================
; tokenize_line — tokenize the current line in-place in the gap buffer.
;
; Called before insert_return to convert typed keyword strings to BASIC
; token bytes in the content before the cursor (between line start and
; GAP_START).  Since tokens are 1 byte and keyword strings are 2-7 bytes,
; the content may shrink; GAP_START is updated accordingly.
;
; Algorithm (two-pointer in-place compaction):
;   SRC (WORK_PTR): scans forward from line start to GAP_START
;   DST (LPTR):     trails SRC, writes tokenized result
;   in_string (CLR_TMP): $00=normal, $FF=inside "..."
;
; On entry:  GAP_START points one past the last typed char on the line.
; On exit:   GAP_START = DST (adjusted for any keyword compression).
; Clobbers:  A, X, Y, WORK_PTR, LPTR, CLR_CTMP, CLR_TMP, KW_TOKEN, CLR_KWLEN
; ============================================================================
tokenize_line:
    ; ── Step 1: find start of current line ─────────────────────────────────
    ; Scan backwards from GAP_START-1 for a CR (or buffer start).
    lda GAP_START
    sta WORK_PTR
    lda GAP_START+1
    sta WORK_PTR+1
    ; Decrement WORK_PTR to GAP_START-1
    lda WORK_PTR
    bne @tl_gs_noborrow
    dec WORK_PTR+1
@tl_gs_noborrow:
    dec WORK_PTR

@tl_scan_back:
    ; Stop if WORK_PTR < work_buf
    lda WORK_PTR+1
    cmp #>work_buf
    bcc @tl_at_buf_start
    bne @tl_check_cr
    lda WORK_PTR
    cmp #<work_buf
    bcc @tl_at_buf_start
@tl_check_cr:
    ldy #0
    lda (WORK_PTR),y
    cmp #PET_CR
    beq @tl_found_cr
    lda WORK_PTR
    bne :+
    dec WORK_PTR+1
:   dec WORK_PTR
    jmp @tl_scan_back

@tl_found_cr:
    ; Step past the CR so WORK_PTR = first char of line
    inc WORK_PTR
    bne @tl_start_ok
    inc WORK_PTR+1
    jmp @tl_start_ok

@tl_at_buf_start:
    lda #<work_buf
    sta WORK_PTR
    lda #>work_buf
    sta WORK_PTR+1

@tl_start_ok:
    ; ── Step 2: init DST = SRC = line start, in_string = 0 ────────────────
    lda WORK_PTR
    sta LPTR
    lda WORK_PTR+1
    sta LPTR+1
    lda #0
    sta CLR_TMP             ; in_string flag

    ; ── Step 3: main tokenize loop ──────────────────────────────────────────
@tl_loop:
    ; Done when SRC >= GAP_START
    lda WORK_PTR+1
    cmp GAP_START+1
    bcc @tl_process
    beq @tl_check_lo
    jmp @tl_done
@tl_check_lo:
    lda WORK_PTR
    cmp GAP_START
    bcc @tl_process
    jmp @tl_done

@tl_process:
    lda CLR_TMP
    beq @tl_not_in_str
    jmp @tl_in_str          ; non-zero = inside string or REM
@tl_not_in_str:

    ; Normal mode: read next byte
    ldy #0
    lda (WORK_PTR),y

    cmp #$22                ; opening quote?
    bne @tl_not_quote
    lda #$FF
    sta CLR_TMP             ; enter string mode
    jmp @tl_copy

@tl_not_quote:
    ; Uppercase PETSCII letter? $41-$5A = A-Z
    cmp #$41
    bcc @tl_copy            ; < 'A', just copy
    cmp #$5B
    bcs @tl_copy            ; > 'Z', just copy

    ; It's a letter — try to match a BASIC keyword
    jsr tl_match_kw         ; C=1: KW_TOKEN=token, CLR_KWLEN=length
    bcc @tl_copy            ; no match, copy byte as-is

    ; ── Keyword matched ─────────────────────────────────────────────────────
    ldy #0
    sta (LPTR),y            ; write token byte to DST
    inc LPTR
    bne :+
    inc LPTR+1
:
    ; Advance SRC by keyword length
@tl_src_advance:
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   dec CLR_KWLEN
    bne @tl_src_advance

    ; REM ($8F): copy rest of line verbatim (comment body must not be tokenized)
    lda KW_TOKEN
    cmp #$8F
    bne @tl_loop
@tl_rem_body:
    lda WORK_PTR+1
    cmp GAP_START+1
    bcc @tl_rem_do
    bne @tl_done
    lda WORK_PTR
    cmp GAP_START
    bcs @tl_done
@tl_rem_do:
    ldy #0
    lda (WORK_PTR),y
    sta (LPTR),y
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   inc LPTR
    bne :+
    inc LPTR+1
:   jmp @tl_rem_body

@tl_in_str:
    ; Inside string literal — copy verbatim, watch for closing quote
    ldy #0
    lda (WORK_PTR),y
    cmp #$22
    bne @tl_copy
    lda #0
    sta CLR_TMP             ; closing quote: exit string mode
    jmp @tl_copy

@tl_copy:
    ; Copy one byte SRC→DST, advance both pointers
    ldy #0
    lda (WORK_PTR),y
    sta (LPTR),y
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   inc LPTR
    bne :+
    inc LPTR+1
:   jmp @tl_loop

@tl_done:
    ; GAP_START = DST (gap may have grown if keywords were compressed)
    lda LPTR
    sta GAP_START
    lda LPTR+1
    sta GAP_START+1
    rts


; ============================================================================
; ============================================================================
; tl_match_kw — match BASIC keyword at WORK_PTR against our own kw_strtab.
;
; Walks kw_strtab (token order $80-$CB), comparing each keyword against the
; buffer at WORK_PTR using kw_len_tab for lengths.  No ROM dependency, no
; bit-7 terminator tricks, no PHA/PLA stack gymnastics.
;
; On entry:  WORK_PTR points to candidate keyword start in buffer.
; On exit:   C=1 → KW_TOKEN = token byte ($80-$CB), CLR_KWLEN = char count
;            C=0 → no match
; Clobbers:  A, X, Y, CLR_CTMP ($1A/$1B), KW_TOKEN ($3A), CLR_KWLEN ($19)
; ============================================================================
tl_match_kw:
    lda #<kw_strtab
    sta CLR_CTMP            ; $1A/$1B — safe, not used during tokenize_line
    lda #>kw_strtab
    sta CLR_CTMP+1
    lda #$80
    sta SAVED_X             ; $0F — token counter

@tmk_try:
    lda SAVED_X
    cmp #$D9
    bcs @tmk_no_match

    sec
    sbc #$80
    tax
    lda kw_len_tab,x
    sta CLR_KWLEN           ; $19 — safe

    ldy #0
@tmk_cmp:
    lda (CLR_CTMP),y        ; kwtab pointer — now using $1A/$1B
    cmp (WORK_PTR),y
    bne @tmk_miss

    iny
    cpy CLR_KWLEN
    bcc @tmk_cmp

    lda SAVED_X
    sec
    rts

@tmk_miss:
    clc
    lda CLR_CTMP
    adc CLR_KWLEN
    sta CLR_CTMP
    bcc :+
    inc CLR_CTMP+1
:   inc SAVED_X
    jmp @tmk_try

@tmk_no_match:
    clc
    rts
