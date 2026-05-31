; ============================================================================
; loadsave.asm — File I/O for PETProject
;
; All disk I/O uses the standard Kernal entry points (LOAD, SETNAM, SETLFS,
; OPEN, CHKIN/CHKOUT, CHRIN/CHROUT, CLOSE, CLRCHN).  No fast-loader code or
; resident driver — fastloader cartridges or JiffyDOS installed by the user
; accelerate LOAD transparently.
;
; User file load path: OPEN/CHRIN, NOT Kernal LOAD.  Reason: our save path
;   (below) writes raw bytes via OPEN/CHROUT with no PRG header.  Kernal
;   LOAD always consumes the first 2 bytes of a file as a load-address
;   header, which would corrupt header-less text files.  OPEN/CHRIN reads
;   every byte as data.  Cost: fastloader cartridges only hook LOAD, so
;   user file loads run at standard 1541 speed.  Module loads (which DO
;   have proper PRG headers) use Kernal LOAD in modules.asm and benefit
;   from any installed fastloader.
;
; User file save path: simple synchronous OPEN/CHKOUT/CHROUT with "@0:"
;   overwrite prefix.  BASIC files are tokenized via MODTOK before
;   writing, detokenized via MODDET after, to keep work_buf in plain text
;   throughout.
; ============================================================================

PROMPT_NAME_COL   = 6
PROMPT_MAX_LEN    = 16
PROMPT_BLINK_MASK = $10

IO_LA             = 2         ; logical file number we'll use for I/O

; ============================================================================
; do_load_file — F3 handler
; ============================================================================

do_load_file:
    lda #0
    sta FNAME_LEN
    sta PROMPT_IS_SAVE
    sta IS_BASIC            ; clear until we know otherwise

    lda #<prompt_lbl_load
    sta LPTR
    lda #>prompt_lbl_load
    sta LPTR+1
    jsr draw_filename_prompt        ; C=1 → cancelled
    bcc :+
    rts                             ; cancelled — nothing to redraw, just return
:
    ; fall through into load body

; ============================================================================
; do_load_file_from_fname — load body only, no filename prompt.
;
; Called by run_selected_module when MOD_STATUS=$04 (MODDSK has already
; written the chosen filename into FNAME_BUF/FNAME_LEN).
; On entry: FNAME_BUF and FNAME_LEN must already be set by the caller.
; ============================================================================

do_load_file_from_fname:
    lda #0
    sta IS_BASIC            ; clear until we know otherwise
    sta IS_NEW_FILE         ; file came from disk -- not new

    ; ---- User file load via OPEN/CHRIN ----
    ; Our save path writes raw bytes via OPEN/CHKOUT/CHROUT with no PRG
    ; header (the file is a SEQ-style raw byte stream).  We must read it
    ; back symmetrically — Kernal LOAD ($FFD5) consumes the first 2 bytes
    ; of the file as a "load address" header, which would mangle text
    ; files where those bytes are real content.
    ;
    ; Fastloader cartridges (Action Replay, Final Cartridge III, SS5,
    ; JiffyDOS) hook LOAD, not OPEN/CHRIN.  So we lose fastloader speedup
    ; on user file loads — but correctness wins over speed, and most user
    ; source files are small (a few KB) so this is fine in practice.
    ; Module loads (which DO have proper PRG headers) still use LOAD and
    ; benefit from fastloader acceleration.

    ; ---- SETLFS: LA=IO_LA, device=SETTING_DRIVE, SA=2 (open SEQ-style) ----
    lda #IO_LA
    ldx SETTING_DRIVE
    ldy #2
    jsr SETLFS

    ; ---- SETNAM ----
    lda FNAME_LEN
    ldx #<FNAME_BUF
    ldy #>FNAME_BUF
    jsr SETNAM

    ; ---- OPEN ----
    jsr OPEN
    bcc :+
    jmp @io_err
:
    ; Check drive status after OPEN
    jsr READST
    beq :+
    jmp @close_err
:
    ; ---- CHKIN: redirect input from our file ----
    ldx #IO_LA
    jsr CHKIN
    bcc :+
    jmp @close_err
:
    ; ---- Read bytes into work_buf ----
    lda #<work_buf
    sta BUF_PTR
    lda #>work_buf
    sta BUF_PTR+1

@read_loop:
    jsr READST
    bne @read_done              ; EOF or error

    jsr CHRIN                   ; A = next byte

    ; Some drives set EOF on the byte that holds valid data, so check
    ; status AFTER read and still store the byte if EOF is set.
    pha
    jsr READST
    and #$40                    ; bit 6 = EOF
    bne @read_eof_with_byte
    pla

    ; Store byte
    ldy #0
    sta (BUF_PTR),y

    ; Advance BUF_PTR
    inc BUF_PTR
    bne :+
    inc BUF_PTR+1
:
    ; Bounds check — don't overflow work_buf
    lda BUF_PTR+1
    cmp #>work_buf_end
    bcc @read_loop
    lda BUF_PTR
    cmp #<work_buf_end
    bcc @read_loop
    jmp @read_done              ; buffer full — truncate

@read_eof_with_byte:
    pla                         ; restore final byte
    ldy #0
    sta (BUF_PTR),y
    inc BUF_PTR
    bne @read_done
    inc BUF_PTR+1

@read_done:
    jsr CLRCHN
    lda #IO_LA
    jsr CLOSE

    ; BUF_PTR now one past the last loaded byte.

@basic_detect:
    ; Check first two bytes of work_buf for PRG load address $0801 ($01 $08).
    lda work_buf+0
    cmp #$01
    bne @not_basic
    lda work_buf+1
    cmp #$08
    bne @not_basic

    ; It's a BASIC PRG. Set flag and run MODDET to detokenize into plain text.
    lda #$FF
    sta IS_BASIC
    lda #0
    sta IS_NEW_FILE         ; it's an existing file
    sta IS_DIRTY            ; freshly loaded — not dirty
    ; Set gap so MODDET knows where tokenized content ends in work_buf.
    lda BUF_PTR
    sta GAP_START
    lda BUF_PTR+1
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    jsr load_run_moddet     ; detokenizes work_buf in place; sets GAP from MOD_NEW_END
    jmp @load_viewport

@not_basic:
    lda #0
    sta IS_BASIC
    sta IS_NEW_FILE         ; it's an existing file
    sta IS_DIRTY            ; freshly loaded — not dirty

    ; Set up gap: content = [work_buf..BUF_PTR), gap = [BUF_PTR..work_buf_end)
    lda BUF_PTR
    sta GAP_START
    lda BUF_PTR+1
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1

    ; Detect binary PRG vs text: a text assembly source file always starts
    ; with a printable character (>= $20). A binary PRG's first byte is the
    ; lo byte of the load address — common values ($00, $01) are all < $20.
    lda work_buf
    cmp #$20
    bcs @load_viewport      ; >= $20 → printable → text file, skip MODDIS

    ; Binary PRG: run MODDIS to disassemble into assembly source text.
    jsr load_run_moddis

@load_viewport:
    ; Reset viewport to top of file
    lda #<work_buf
    sta TOP_LINE
    lda #>work_buf
    sta TOP_LINE+1
    lda #0
    sta LEFT_COL
    sta CURSOR_ROW
    sta CURSOR_COL
    jmp @done

@close_err:
    jsr CLRCHN
    lda #IO_LA
    jsr CLOSE
    ; fall through to @io_err

@io_err:
    jsr READST
    sta IO_STATUS
    jsr show_io_error

@done:
    jsr render_status
    jsr ensure_cursor_visible
    jsr render_viewport
    jsr draw_cursor
    rts

; ============================================================================
; do_save_file — F5 handler
; ============================================================================

do_save_file:
    ; ---- Compact gap so content is contiguous ----
    jsr compact_gap                 ; WORK_PTR = one-past-end of content

; ---- Ensure content ends with CR ----
    lda WORK_PTR
    cmp #<work_buf
    bne @check_last_cr
    lda WORK_PTR+1
    cmp #>work_buf
    beq @no_append_cr           ; empty buffer

@check_last_cr:
    ; Read byte at WORK_PTR-1 using Y offset trick: set ptr to WORK_PTR-1
    ; Use TMP as the peek pointer to avoid corrupting WORK_PTR
    lda WORK_PTR
    sta TMP
    lda WORK_PTR+1
    sta TMP+1
    lda TMP
    bne :+
    dec TMP+1
:   dec TMP
    ldy #0
    lda (TMP),y                 ; read last byte — TMP untouched after this
    cmp #PET_CR
    beq @no_append_cr
    lda #PET_CR
    sta (WORK_PTR),y            ; Y is still 0
    inc WORK_PTR
    bne @no_append_cr
    inc WORK_PTR+1

@no_append_cr:
    lda WORK_PTR
    sta IO_END_LO
    lda WORK_PTR+1
    sta IO_END_HI

    ; Re-open gap at end of compacted content
    lda IO_END_LO
    sta GAP_START
    lda IO_END_HI
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1

    ; ---- If new file, ask BASIC or plain text? ----
    lda IS_NEW_FILE
    beq @skip_basic_prompt          ; $00 = not new, IS_BASIC already set
    jsr prompt_basic_or_text        ; sets IS_BASIC; C=1 if cancelled
    bcc @skip_basic_prompt
    jmp @done

@skip_basic_prompt:

    ; ---- Prompt for filename ----
    lda IS_NEW_FILE
    beq @have_name
    lda #0
    sta FNAME_LEN
@have_name:
    lda #1
    sta PROMPT_IS_SAVE

    lda #<prompt_lbl_save
    sta LPTR
    lda #>prompt_lbl_save
    sta LPTR+1
    jsr draw_filename_prompt        ; C=1 → cancelled
    bcc :+
    jmp @done
:
    ; ---- Build "@0:<filename>" in IO_NAME_BUF ----
    jsr build_save_name             ; A = total length

    ; ---- If BASIC, tokenize before writing ----
    lda IS_BASIC
    beq @skip_tokenize
    jsr save_run_modtok
    lda MOD_STATUS
    cmp #$02
    bne @tok_err
    lda MOD_NEW_END_LO
    sta IO_END_LO
    lda MOD_NEW_END_HI
    sta IO_END_HI
    jmp @skip_tokenize
@tok_err:
    jsr show_io_error
    jmp @restore_gap

@skip_tokenize:

    ; ---- SETLFS: LA=IO_LA, device=SETTING_DRIVE, SA=1 (write) ----
    lda #IO_LA
    ldx SETTING_DRIVE
    ldy #1
    jsr SETLFS

    ; ---- SETNAM with "@0:<filename>" ----
    lda IO_NAME_BUF_LEN
    ldx #<IO_NAME_BUF
    ldy #>IO_NAME_BUF
    jsr SETNAM

    ; ---- OPEN ----
    jsr OPEN
    bcc :+
    jmp @io_err
:
    jsr READST
    beq :+
    jmp @close_err
:
    ; ---- CHKOUT: redirect output to our file ----
    ldx #IO_LA
    jsr CHKOUT
    bcc :+
    jmp @close_err
:

    ; ---- Write bytes from work_buf to content end ----
    lda #<work_buf
    sta BUF_PTR
    lda #>work_buf
    sta BUF_PTR+1

@write_loop:
    lda BUF_PTR
    cmp IO_END_LO
    bne @write_byte
    lda BUF_PTR+1
    cmp IO_END_HI
    beq @write_done

@write_byte:
    ldy #0
    lda (BUF_PTR),y
    jsr CHROUT

    ; Check status after write
    jsr READST
    bne @write_err

    inc BUF_PTR
    bne @write_loop
    inc BUF_PTR+1
    jmp @write_loop

@write_err:
    sta IO_STATUS
    jsr CLRCHN
    lda #IO_LA
    jsr CLOSE
    jsr show_io_error
    jmp @done

@write_done:
    jsr CLRCHN
    lda #IO_LA
    jsr CLOSE

    lda #0
    sta IS_NEW_FILE
    sta IS_DIRTY

    lda IS_BASIC
    beq @done

    ; Save cursor/viewport state before re-detokenizing
    lda TOP_LINE
    sta IO_END_LO           ; repurpose — I/O is finished at this point
    lda TOP_LINE+1
    sta IO_END_HI
    lda CURSOR_ROW
    sta IO_SCRATCH

    jsr load_run_moddet

    lda IO_END_LO
    sta TOP_LINE
    lda IO_END_HI
    sta TOP_LINE+1
    lda IO_SCRATCH
    sta CURSOR_ROW

    jsr ensure_cursor_visible
    jmp @done

@restore_gap:
    ; Tokenize failed — restore gap pointers to plain-text content end
    lda WORK_PTR
    sta GAP_START
    lda WORK_PTR+1
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    jmp @done

@close_err:
    jsr CLRCHN
    lda #IO_LA
    jsr CLOSE
    jmp @show_err

@io_err:
@show_err:
    jsr READST
    sta IO_STATUS
    jsr show_io_error

@done:
    jsr render_status
    jsr render_viewport
    jsr draw_cursor
    rts

; ============================================================================
; load_run_moddet — auto-detokenize work_buf after loading a BASIC PRG.
;
; Populates the module parameter block and calls MODDET (module index 0).
; On return: GAP_START set from MOD_NEW_END, GAP_END = work_buf_end.
; Clobbers: A, X, Y, LPTR, FNAME_BUF, FNAME_LEN, MOD_* params.
; ============================================================================

load_run_moddet:
    ldx #4                          ; module index 4 = MODDET (hidden module)
    jsr run_module_by_index
    ; On return MOD_STATUS should be $02 (buffer replaced).
    ; If not, something went badly wrong — treat buffer as plain text.
    lda MOD_STATUS
    cmp #$02
    bne @plain                      ; fall back to treating whole buf as text

    ; Set gap from detokenized content end
    lda MOD_NEW_END_LO
    sta GAP_START
    lda MOD_NEW_END_HI
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    rts

@plain:
    ; Fallback: use BUF_PTR as content end (set by read loop)
    lda BUF_PTR
    sta GAP_START
    lda BUF_PTR+1
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    rts

; ============================================================================
; load_run_moddis — disassemble binary content in work_buf to assembly source.
;
; Calls MODDIS (module index 1) which reads the PRG binary starting at
; work_buf, disassembles it, and writes assembly source text back.
; On success: GAP_START set from MOD_NEW_END, GAP_END = work_buf_end.
; On failure: gap left as-is (caller's gap setup stays valid as raw text).
; Clobbers: A, X, Y, LPTR, FNAME_BUF, FNAME_LEN, MOD_* params.
; ============================================================================

load_run_moddis:
    ldx #1                          ; module index 1 = MODDIS
    jsr run_module_by_index
    lda MOD_STATUS
    cmp #$02
    bne @moddis_plain

    ; Write CONTENT_ROWS sentinel CRs after output end so scrolling past
    ; the last valid line shows blank rows instead of garbage.
    lda MOD_NEW_END_LO
    sta BUF_PTR
    lda MOD_NEW_END_HI
    sta BUF_PTR+1
    lda #CONTENT_ROWS
    sta TMP
@sentinel:
    lda BUF_PTR+1               ; stop if at or past work_buf_end
    cmp #>work_buf_end
    bcs @sent_done
    lda #PET_CR
    ldy #0
    sta (BUF_PTR),y
    inc BUF_PTR
    bne :+
    inc BUF_PTR+1
:   dec TMP
    bne @sentinel
@sent_done:
    ; Zero-size gap at work_buf → cursor at position 0.
    ; ensure_cursor_visible finds cursor on first comparison: O(1).
    lda #<work_buf
    sta GAP_START
    lda #>work_buf
    sta GAP_START+1
    lda #<work_buf
    sta GAP_END
    lda #>work_buf
    sta GAP_END+1
    rts

@moddis_plain:
    lda BUF_PTR
    sta GAP_START
    lda BUF_PTR+1
    sta GAP_START+1
    lda #<work_buf_end
    sta GAP_END
    lda #>work_buf_end
    sta GAP_END+1
    rts

; ============================================================================
; save_run_modtok — auto-tokenize work_buf before writing a BASIC save.
;
; Populates the module parameter block and calls MODTOK (module index 1).
; On return: MOD_NEW_END holds the end of the tokenized bytes in work_buf.
; MOD_STATUS = $02 on success, $01 on error.
; The gap buffer is NOT updated — caller restores it after the disk write.
; Clobbers: A, X, Y, LPTR, FNAME_BUF, FNAME_LEN, MOD_* params.
; ============================================================================

save_run_modtok:
    ; The gap must be compacted before this call (do_save_file already did it).
    ; GAP_START currently = IO_END = content end after compact_gap.
    ; We need to tell MODTOK where the content ends via MOD_GAP_START.
    ldx #5                          ; module index 5 = MODTOK (hidden module)
    jmp run_module_by_index         ; tail call — RTS from there returns to caller

; ============================================================================
; prompt_basic_or_text — show "BASIC (Y/N)?" on status bar for new files.
;
; Sets IS_BASIC ($FF=yes, $00=no) based on keypress.
; On exit: C=0 confirmed, C=1 cancelled (STOP key).
; Clobbers: A, Y.
; ============================================================================

prompt_basic_or_text:
    ; Print "BASIC (Y/N)?" in screen codes on status row
    ldy #0
@lbl:
    lda basic_yn_text,y
    beq @wait
    sta STATUS_ROW,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR,y
    iny
    jmp @lbl

@wait:
    jsr GETIN
    beq @wait

    cmp #PET_STOP
    beq @cancel

    ; 'Y' in PETSCII = $59 (uppercase), also accept $79 (shifted)
    cmp #'Y'
    beq @yes
    cmp #'y'
    beq @yes

    ; 'N' = $4E
    cmp #'N'
    beq @no
    cmp #'n'
    beq @no

    jmp @wait                       ; any other key: keep waiting

@yes:
    lda #$FF
    sta IS_BASIC
    lda #0
    sta IS_NEW_FILE
    clc
    rts

@no:
    lda #0
    sta IS_BASIC
    sta IS_NEW_FILE
    clc
    rts

@cancel:
    sec
    rts

; "BASIC (Y/N)?" in screen codes
basic_yn_text:
    .byte $02,$01,$13,$09,$03,$20,$28,$19,$2F,$0E,$29,$3F, 0

; ============================================================================
; compact_gap — copy [GAP_END..work_buf_end) down to GAP_START.
; Returns new content-end in WORK_PTR.
; Clobbers: WORK_PTR, BUF_PTR, A, Y
; ============================================================================

compact_gap:
    lda GAP_END
    sta WORK_PTR
    lda GAP_END+1
    sta WORK_PTR+1

    lda GAP_START
    sta BUF_PTR
    lda GAP_START+1
    sta BUF_PTR+1

@loop:
    lda WORK_PTR
    cmp #<work_buf_end
    bne @byte
    lda WORK_PTR+1
    cmp #>work_buf_end
    beq @done

@byte:
    ldy #0
    lda (WORK_PTR),y
    sta (BUF_PTR),y
    inc WORK_PTR
    bne :+
    inc WORK_PTR+1
:   inc BUF_PTR
    bne @loop
    inc BUF_PTR+1
    jmp @loop

@done:
    lda BUF_PTR
    sta WORK_PTR
    lda BUF_PTR+1
    sta WORK_PTR+1
    rts

; ============================================================================
; build_save_name — write "@0:<FNAME_BUF>" into IO_NAME_BUF.
; Stores total length in IO_NAME_BUF_LEN and returns it in A.
; ============================================================================

build_save_name:
    lda #'@'
    sta IO_NAME_BUF+0
    lda #'0'
    sta IO_NAME_BUF+1
    lda #':'
    sta IO_NAME_BUF+2
    ldy #0
@cp:
    cpy FNAME_LEN
    beq @done
    lda FNAME_BUF,y
    sta IO_NAME_BUF+3,y
    iny
    jmp @cp
@done:
    tya
    clc
    adc #3
    sta IO_NAME_BUF_LEN
    rts

; ============================================================================
; draw_filename_prompt
; On entry: LPTR → 6-byte screen-code label.
; On exit:  C=0 confirmed, C=1 cancelled.
; Uses Y as column index throughout — petscii_to_screen only clobbers A.
; ============================================================================

draw_filename_prompt:
    ldy #0
@lbl:
    lda (LPTR),y
    sta STATUS_ROW,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR,y
    iny
    cpy #6
    bne @lbl

    ; Blank cols 6..39
    ldy #PROMPT_NAME_COL
@blank:
    lda #$20
    sta STATUS_ROW,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR,y
    iny
    cpy #COLS
    bne @blank

    jsr prompt_draw_name

@flush:
    jsr GETIN
    bne @flush

@inp:
    lda JIFFY_LO
    and #PROMPT_BLINK_MASK
    beq @cur_off
    lda #$20 | $80
    jmp @cur_draw
@cur_off:
    lda #$20
@cur_draw:
    ldy FNAME_LEN
    sta STATUS_ROW + PROMPT_NAME_COL,y

    jsr GETIN
    beq @inp

    cmp #PET_CR
    beq @confirm

    cmp #PET_STOP
    beq @cancel

    cmp #$14                        ; INST/DEL
    bne @try_char
    lda FNAME_LEN
    beq @inp
    ldy FNAME_LEN
    dey
    lda #$20
    sta STATUS_ROW + PROMPT_NAME_COL,y
    sta COLOR + PROMPT_NAME_COL,y
    dec FNAME_LEN
    jmp @inp

@try_char:
    cmp #$20
    bcc @inp
    ldy FNAME_LEN
    cpy #PROMPT_MAX_LEN
    beq @inp
    sta FNAME_BUF,y
    jsr petscii_to_screen
    sta STATUS_ROW + PROMPT_NAME_COL,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR + PROMPT_NAME_COL,y
    inc FNAME_LEN
    jmp @inp

@confirm:
    ldy FNAME_LEN
    lda #$20
    sta STATUS_ROW + PROMPT_NAME_COL,y
    clc
    rts

@cancel:
    sec
    rts

; ============================================================================
; prompt_draw_name — paint FNAME_BUF onto status row name field.
; Uses Y as column index throughout.
; ============================================================================

prompt_draw_name:
    ldy #0
@draw:
    cpy FNAME_LEN
    beq @pad
    lda FNAME_BUF,y
    jsr petscii_to_screen
    sta STATUS_ROW + PROMPT_NAME_COL,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR + PROMPT_NAME_COL,y
    iny
    jmp @draw
@pad:
    cpy #PROMPT_MAX_LEN
    beq @done
    lda #$20
    sta STATUS_ROW + PROMPT_NAME_COL,y
    lda #DEFAULT_STATUS_COLOR
    sta COLOR + PROMPT_NAME_COL,y
    iny
    jmp @pad
@done:
    rts

; ============================================================================
; show_io_error — "I/O ERROR" on status row ~1.5 s.
; ============================================================================

show_io_error:
    ldy #0
@wr:
    lda io_error_text,y
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

io_error_text:
    .byte $09,$2F,$0F,$20,$05,$12,$12,$0F,$12,$20, 0

; ============================================================================
; petscii_to_screen — clobbers A only. Y and X preserved.
; ============================================================================

petscii_to_screen:
    cmp #$40
    bcc @keep
    cmp #$60
    bcc @sub40
    cmp #$80
    bcc @sub20
    and #$7F
    rts
@keep:  rts
@sub40: sec
        sbc #$40
        rts
@sub20: sec
        sbc #$20
        rts

; ============================================================================
; Prompt labels — 6 bytes each, screen codes
; ============================================================================

prompt_lbl_load:
    .byte $0C,$0F,$01,$04,$3A,$20   ; "LOAD: "

prompt_lbl_save:
    .byte $13,$01,$16,$05,$3A,$20   ; "SAVE: "

; ============================================================================
; Additional BSS variable — add to .segment "BSS" in editor.asm:
;   IO_NAME_BUF_LEN: .res 1
; ============================================================================
