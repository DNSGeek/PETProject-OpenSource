; ============================================================================
; modscrh.asm — Script Handler code for PETProject
;
; Loads at $C000. Loaded by the module loader (do_run_script) before MODSCR
; runs, so the handler code is resident before BASIC hands off.
; Survives the IDE stash (which covers only $0801-$9FFF).
;
; Layout at $C000:
;   $C000 execute stub (7 bytes) ← module loader calls here; just marks $00 and returns
;   $C007 JMP hnd_dispatch    ← $0308 (IGONE) points here
;   $C00A JMP hnd_end_script  ← $0302 (IMAIN) points here
;   $C00D JMP hnd_error       ← $0300 (IERROR) points here
;   $C010 hnd_saved_sp        ← modscr writes SP here before BASIC handoff
;   $C011 hnd_orig_igone      ← modscr writes original $0308 here
;   $C013 hnd_orig_imain      ← modscr writes original $0302 here
;   $C015 hnd_orig_ierror     ← modscr writes original $0300 here
;
; Extended token range: $CC-$D8 (13 keywords, must match modsct.asm kwtab).
;
; BASIC ROM addresses used:
;   $A7AE : NEWSTT — jump here after handling a statement
;   $A7E7 : GONE   — original IGONE, for tokens $80-$CB
;   $B79E : GETBYT — evaluate expression, result byte in X
;   $7A/$7B : TXTPTR — current program text pointer
;
; REU layout for IDE restore (mirrors modscr.asm):
;   $009000 : IDE snapshot ($0801-$9FFF, written by modscr)
;
; Linker config: module.cfg (loads at $C000, up to $0FFE bytes of code).
; Build:
;   ca65 -g modscrh.asm -o modscrh.o
;   ld65 -C module.cfg modscrh.o -o MODSCRH
; ============================================================================

.setcpu "6502"

; ---- BASIC ROM ----
BASIC_NEWSTT    = $A7AE
BASIC_GONE_ORIG = $A7E7
BASIC_GETBYT    = $B79E
BASIC_TXTPTR    = $7A     ; lo; hi at $7B

; ---- BASIC zero-page pointers / ROM entries used by RUNPROG ----
TXTTAB          = $2B     ; start of BASIC program (lo/hi) = $0801
VARTAB          = $2D     ; start of variables (lo/hi) = end of program
BASIC_RELINK    = $A533   ; rebuild line link pointers
BASIC_CLR       = $A659   ; CLR: reset variables/strings/stack to program start
BASIC_RUNC      = $A7AE   ; NEWSTT (run loop); reached after TXTPTR set + CLR

; ---- Kernal ----
KERNAL_SETLFS   = $FFBA
KERNAL_SETNAM   = $FFBD
KERNAL_LOAD     = $FFD5

; ---- REU registers ----
REU_COMMAND = $DF01
REU_C64_LO  = $DF02
REU_C64_HI  = $DF03
REU_REU_LO  = $DF04
REU_REU_MED = $DF05
REU_REU_HI  = $DF06
REU_LEN_LO  = $DF07
REU_LEN_HI  = $DF08
REU_INTMASK = $DF09
REU_ADDCTL  = $DF0A

REU_CMD_FETCH = $91   ; REU -> C64 (EXECUTE | FF00-trigger-disable, immediate)

; IDE restore parameters (match modscr.asm)
IDE_START   = $0801
IDE_LEN_LO  = <($9FFF - $0801 + 1)
IDE_LEN_HI  = >($9FFF - $0801 + 1)
REU_IDE_MED = $90     ; $009000 in REU

; IDE re-entry after script completion. The IDE's SYS-stub entry is at $080D.
; It resets the stack and dispatches on BOOT_MAGIC: RESUME_MAGIC means "image
; already restored in RAM — just repaint and resume", preserving the buffer.
IDE_ENTRY    = $080D
BOOT_MAGIC   = $0200
RESUME_MAGIC = $52

; BASIC indirect vectors
VEC_IERROR  = $0300
VEC_IMAIN   = $0302
VEC_IGONE   = $0308

; ZP scratch
HND_TMP     = $3C     ; lo (hi=$3D) — scratch pointer (no conflict during script)

; Module status
MOD_STATUS  = $021E

; ============================================================================

.segment "LOADADDR"
    .word $C000

.segment "CODE"

; ============================================================================
; EXECUTE STUB — $C000, called by module loader. 7 bytes.
; Marks success so MODSCRH stays resident; does not run handler logic.
; ============================================================================

    cli                          ; re-enable interrupts
    lda #$00
    sta MOD_STATUS               ; $00 = success
    rts

; ============================================================================
; FIXED ENTRY POINTS — $C007 (matches modscr.asm HND_* consts)
; ============================================================================

    jmp hnd_dispatch      ; $C007 — IGONE entry
    jmp hnd_end_script    ; $C00A — IMAIN entry
    jmp hnd_error         ; $C00D — IERROR entry

; ============================================================================
; STATE — written by modscr.asm before BASIC handoff ($C010-$C016)
; ============================================================================

hnd_saved_sp:    .byte 0      ; $C010: SP to restore when script ends
hnd_orig_igone:  .word 0      ; $C011: original $0308 (IGONE)
hnd_orig_imain:  .word 0      ; $C013: original $0302 (IMAIN)
hnd_orig_ierror: .word 0      ; $C015: original $0300 (IERROR)

; ---- Handler working state ----
hnd_cur_drive:   .byte 8      ; current drive for disk operations
hnd_onerr_lo:    .byte 0      ; ONERR target line number lo ($00 = no handler)
hnd_onerr_hi:    .byte 0
hnd_jmp_lo:      .byte 0      ; dispatch target lo (ZP-style temp)
hnd_jmp_hi:      .byte 0      ; dispatch target hi
hnd_scratch_lo:  .byte 0
hnd_scratch_hi:  .byte 0
hnd_cmd_len:     .byte 0
hnd_cmd_buf:     .res 64      ; command channel string buffer
hnd_status_buf:  .res 40      ; drive status string

; ============================================================================
; hnd_dispatch — IGONE handler.
; BASIC calls through ($0308) with A = current token.
; Routes $CC-$D8 to our handlers; everything else to original IGONE.
; ============================================================================

hnd_dispatch:
    ; IGONE is entered via JMP ($0308) BEFORE the token is fetched — A does
    ; NOT hold the token on entry. Fetch it ourselves first (exactly as the
    ; stock $0308 handler at $A7E4 does), then test the range.
    jsr $0073           ; CHRGET — fetch current token into A, advance TXTPTR
    cmp #$CC
    bcc @not_ours
    cmp #$D9            ; one past last extended token
    bcs @not_ours

    ; 0-index into jump table, 2 bytes per entry
    sec
    sbc #$CC
    asl                 ; ×2
    tax
    lda hnd_table,x
    sta hnd_jmp_lo
    lda hnd_table+1,x
    sta hnd_jmp_hi
    ; Advance past the keyword token to its first operand char, exactly as the
    ; stock dispatcher does (BASIC $A7ED ends with JMP $0073 before entering the
    ; handler). Without this, a handler that calls GETBYT/FRMNUM would back up
    ; one byte and re-read the keyword token itself instead of the argument.
    jsr $0073           ; CHRGET — TXTPTR now at first operand char
    jmp (hnd_jmp_lo)    ; handler reads its operands from the correct position

@not_ours:
    ; Token already fetched into A above, so enter GONE *proper* ($A7E7),
    ; NOT the saved $0308 original ($A7E4) which would CHRGET a second time
    ; and desync TXTPTR. $A7E7 dispatches on the token in A and loops back
    ; to NEWSTT itself.
    ;
    ; CRITICAL: $A7ED (reached from $A7E7) does `SBC #$80` to index the
    ; statement-vector table, which requires CARRY SET for a correct subtract.
    ; The stock entry guarantees this because CHRGET's tail leaves carry set.
    ; Our range test above ended with `cmp #$D9 / bcs` leaving carry CLEAR for
    ; an in-not-our-range token, which would make SBC subtract one too many and
    ; dispatch the WRONG handler. Force carry set first.
    sec
    jmp BASIC_GONE_ORIG

; Handler jump table (13 entries, $CC-$D8)
hnd_table:
    .word hnd_assemble  ; $CC ASSEMBLE
    .word hnd_include   ; $CD INCLUDE
    .word hnd_runprog   ; $CE RUNPROG
    .word hnd_scratch   ; $CF SCRATCH
    .word hnd_delete    ; $D0 DELETE
    .word hnd_exists    ; $D1 EXISTS
    .word hnd_rename    ; $D2 RENAME
    .word hnd_status    ; $D3 STATUS
    .word hnd_drive     ; $D4 DRIVE
    .word hnd_onerr     ; $D5 ONERR
    .word hnd_pause     ; $D6 PAUSE
    .word hnd_copy      ; $D7 COPY
    .word hnd_dir       ; $D8 DIR

; ============================================================================
; hnd_end_script — IMAIN handler (script ended normally).
; Restores original vectors, restores IDE RAM from REU, returns to module loader.
; ============================================================================

hnd_end_script:
    sei

    ; Restore original BASIC vectors
    lda hnd_orig_igone
    sta VEC_IGONE
    lda hnd_orig_igone+1
    sta VEC_IGONE+1
    lda hnd_orig_imain
    sta VEC_IMAIN
    lda hnd_orig_imain+1
    sta VEC_IMAIN+1
    lda hnd_orig_ierror
    sta VEC_IERROR
    lda hnd_orig_ierror+1
    sta VEC_IERROR+1

    ; Page out BASIC ROM so we can access $A000 RAM for REU param setup
    ; (REU registers at $DF00 are always accessible regardless of $01)
    ; We write directly to REU registers — no param block needed.
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    lda #<IDE_START
    sta REU_C64_LO
    lda #>IDE_START
    sta REU_C64_HI
    lda #0
    sta REU_REU_LO
    lda #REU_IDE_MED
    sta REU_REU_MED
    lda #0
    sta REU_REU_HI
    lda #IDE_LEN_LO
    sta REU_LEN_LO
    lda #IDE_LEN_HI
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND  ; IDE restored — $0801-$9FFF back

    ; Restore normal memory map
    lda #$37
    sta $01

    ; Re-enter the IDE cleanly. We do NOT restore MODSCR's saved SP and RTS:
    ; BASIC's RUN path executed CLR ($A659), which does LDX #$FA / TXS and
    ; destroyed the module loader's call frame, so that return address is gone.
    ; Instead, signal a resume boot and jump to the IDE's stub entry ($080D),
    ; which resets the stack itself and repaints without touching the buffer
    ; (already restored from the REU above).
    lda #RESUME_MAGIC
    sta BOOT_MAGIC
    lda #$00
    sta MOD_STATUS
    ldx #$FF
    txs                 ; clean stack for the re-entry
    cli
    jmp IDE_ENTRY       ; $080D — never returns here

; ============================================================================
; hnd_error — IERROR handler (BASIC runtime error).
; If ONERR is set, scan the BASIC program for the target line and resume
; execution there. Otherwise restore the IDE.
;
; BASIC program walk: each line = [link_lo][link_hi][lineno_lo][lineno_hi]
;   [tokens...][00]. Link word = address of next line. $0000 link = end.
; TXTPTR convention: points to the byte BEFORE the first token, so NEWSTT's
;   initial CHRGET increments it and loads the first real token byte.
;   → set TXTPTR = line_start + 3  (lineno_hi position; first token is at +4)
; ============================================================================

hnd_error:
    lda hnd_onerr_lo
    ora hnd_onerr_hi
    beq @no_onerr           ; ONERR not set → restore IDE

    ; Walk the BASIC program looking for the target line number.
    ; Use HND_TMP as the scan pointer (ZP $3C/$3D).
    lda TXTTAB
    sta HND_TMP
    lda TXTTAB+1
    sta HND_TMP+1

@search:
    ; Read link word lo/hi (offset 0/1 from line start)
    ldy #0
    lda (HND_TMP),y
    iny
    ora (HND_TMP),y         ; both zero = end-of-program
    beq @not_found

    ; Read line number lo/hi (offset 2/3)
    ldy #2
    lda (HND_TMP),y
    cmp hnd_onerr_lo
    bne @next_line
    ldy #3
    lda (HND_TMP),y
    cmp hnd_onerr_hi
    bne @next_line

    ; Found the target line. Set TXTPTR = line_start + 3.
    ; NEWSTT does CHRGET first (INC TXTPTR then LDA (TXTPTR),Y), so this
    ; positions TXTPTR one byte before the first token (at lineno_hi).
    lda HND_TMP
    clc
    adc #3
    sta BASIC_TXTPTR
    lda HND_TMP+1
    adc #0
    sta BASIC_TXTPTR+1
    jmp BASIC_NEWSTT        ; resume script at the ONERR target line

@next_line:
    ; Advance HND_TMP to next line via link word (stored at offset 0/1)
    ldy #0
    lda (HND_TMP),y
    tax                     ; save new lo
    ldy #1
    lda (HND_TMP),y         ; new hi
    sta HND_TMP+1
    stx HND_TMP
    jmp @search

@not_found:
@no_onerr:
    jmp hnd_end_script      ; restore IDE and re-enter; never returns here

; ============================================================================
; Implemented keyword handlers
; ============================================================================

; ---- DRIVE n — set current drive ----
hnd_drive:
    jsr BASIC_GETBYT    ; X = drive number (0-255)
    stx hnd_cur_drive
    jmp BASIC_NEWSTT

; ---- PAUSE n — wait n jiffies ($A2 = jiffy clock lo) ----
hnd_pause:
    jsr BASIC_GETBYT    ; X = jiffies to wait (A is left 0 by GETBYT)
    cpx #0              ; test the COUNT in X — not A, which GETBYT zeroes
    beq @done           ; PAUSE 0 → no wait
    stx hnd_scratch_lo
    lda $A2
    sta hnd_scratch_hi
@spin:
    lda $A2
    cmp hnd_scratch_hi
    beq @spin
    inc hnd_scratch_hi
    dec hnd_scratch_lo
    bne @spin
@done:
    jmp BASIC_NEWSTT

; ---- STATUS — read drive status string ----
hnd_status:
    jsr hnd_open_cmd_ch     ; open command channel (LA=15)
    bcs @done
    ldx #15
    jsr $FFC6               ; CHKIN (set input)
    bcs @close_err
    ldy #0
@read:
    jsr $FFB7
    and #$42
    bne @eof  ; READST — EOF/error
    jsr $FFCF                          ; CHRIN
    cmp #$0D
    beq @eof  ; CR = end of status
    cpy #39
    bcs @skip
    sta hnd_status_buf,y
    iny
@skip:
    jmp @read
@eof:
    lda #0
    sta hnd_status_buf,y
    jsr $FFCC               ; CLRCHN
    lda #15
    jsr $FFC3  ; CLOSE 15
    ; Print the captured status string, then a carriage return.
    ldy #0
@print:
    lda hnd_status_buf,y
    beq @print_done        ; null terminator
    jsr $FFD2              ; CHROUT
    iny
    cpy #40
    bcc @print
@print_done:
    lda #$0D
    jsr $FFD2              ; CHROUT — newline after status
@done:
    jmp BASIC_NEWSTT
@close_err:
    jsr $FFCC
    lda #15
    jsr $FFC3
    jmp BASIC_NEWSTT

; ---- DELETE "filename" — send S:name to command channel ----
hnd_delete:
    lda #'S'
    sta hnd_cmd_buf
    lda hnd_cur_drive
    clc
    adc #'0'
    sta hnd_cmd_buf+1
    lda #':'
    sta hnd_cmd_buf+2
    lda #3
    jsr hnd_read_str_arg  ; appends filename, sets hnd_cmd_len
    jsr hnd_send_command
    jmp BASIC_NEWSTT

; ---- SCRATCH "pattern" — wildcard scratch (same as DELETE) ----
hnd_scratch:
    lda #'S'
    sta hnd_cmd_buf
    lda hnd_cur_drive
    clc
    adc #'0'
    sta hnd_cmd_buf+1
    lda #':'
    sta hnd_cmd_buf+2
    lda #3
    jsr hnd_read_str_arg
    jsr hnd_send_command
    jmp BASIC_NEWSTT

; ---- ONERR line — set error-handler line number (16-bit) ----
; FRMNUM ($AD9E) evaluates the numeric expression into FAC1.
; AYINT ($B1AA) converts FAC1 to a signed 16-bit integer stored
; big-endian in $14 (hi) and $15 (lo). Range: 0-32767.
BASIC_FRMNUM    = $AD9E     ; evaluate numeric expression → FAC1
BASIC_AYINT     = $B1AA     ; convert FAC1 → 16-bit int: $14=hi, $15=lo
hnd_onerr:
    jsr BASIC_FRMNUM        ; evaluate argument into FAC1
    jsr BASIC_AYINT         ; convert to integer: $14=hi, $15=lo
    lda $15
    sta hnd_onerr_lo
    lda $14
    sta hnd_onerr_hi
    jmp BASIC_NEWSTT

; ============================================================================
; Stub handlers — consume arguments and continue; implement in v2
; ============================================================================

hnd_include:
    ; INCLUDE is resolved at tokenize time by MODSCT; at runtime it is a no-op.
    ; Consume the quoted filename argument and continue.
    lda #0
    jsr hnd_read_str_arg
    jmp BASIC_NEWSTT

; ---- RUNPROG "file" — load another BASIC program and run it (chain) ----
; Loads the named PRG to the BASIC start ($0801), relinks, clears variables,
; and re-enters the BASIC run loop at the new program's first line. Our
; IGONE/IMAIN/IERROR vectors stay hooked, so the chained program also gets the
; extended keywords and, when it ends, returns to the IDE normally.
hnd_runprog:
    lda #0
    jsr hnd_read_str_arg        ; filename -> hnd_cmd_buf, length -> hnd_cmd_len
    lda hnd_cmd_len
    beq @done                   ; no filename given: do nothing, continue

    ; SETLFS: LA=0, device=current drive, SA=0 (load to X/Y, treat as BASIC prog)
    lda #0
    ldx hnd_cur_drive
    ldy #0
    jsr KERNAL_SETLFS

    ; SETNAM: A=len, X/Y = ptr to filename
    lda hnd_cmd_len
    ldx #<hnd_cmd_buf
    ldy #>hnd_cmd_buf
    jsr KERNAL_SETNAM

    ; LOAD: A=0 (load, not verify); X/Y = load address = TXTTAB ($0801)
    lda #0
    ldx TXTTAB
    ldy TXTTAB+1
    jsr KERNAL_LOAD
    bcs @load_err               ; carry set = load error -> abort to IDE

    ; X/Y = end-of-load address + 1.  Store as VARTAB (start of variables).
    stx VARTAB
    sty VARTAB+1

    ; Rebuild BASIC line links for the freshly loaded program.
    jsr BASIC_RELINK

    ; CLR resets variable/string/stack pointers for a clean run, then point
    ; TXTPTR just before the start of program text and re-enter the run loop.
    jsr BASIC_CLR
    lda TXTTAB
    sec
    sbc #1
    sta BASIC_TXTPTR
    lda TXTTAB+1
    sbc #0
    sta BASIC_TXTPTR+1
    jmp BASIC_RUNC              ; NEWSTT: run the loaded program from line 1

@load_err:
    ; Loading failed — end the script and restore the IDE, flag error.
    jsr hnd_end_script
    lda #$01
    sta MOD_STATUS
    rts
@done:
    jmp BASIC_NEWSTT

hnd_rename:
hnd_copy:
    ; TODO: two-arg handlers (RENAME "old" TO "new", COPY "src" TO "dst")
    lda #0
    jsr hnd_read_str_arg
    jmp BASIC_NEWSTT

hnd_exists:
    lda #0
    jsr hnd_read_str_arg
    ; TODO: open file, set EX variable to 1 or 0
    jmp BASIC_NEWSTT

hnd_dir:
    ; Open the directory stream: SETLFS LA=2, device=hnd_cur_drive, SA=0
    lda #2
    ldx hnd_cur_drive
    ldy #0                  ; SA=0
    jsr $FFBA               ; SETLFS
    lda #1                  ; filename length = 1 ("$")
    ldx #<hnd_dir_fname
    ldy #>hnd_dir_fname
    jsr $FFBD               ; SETNAM
    jsr $FFC0               ; OPEN
    bcs @dir_open_err

    ldx #2
    jsr $FFC6               ; CHKIN — set LA=2 as input channel
    bcs @dir_close_err

    ; Discard the 2-byte PRG load address the drive sends first ($01 $08)
    jsr $FFCF               ; CHRIN — discard lo
    jsr $FFCF               ; CHRIN — discard hi

@line_loop:
    ; Each directory line = [link_lo][link_hi][blkcount_lo][blkcount_hi][PETSCII...][00]

    ; Read and discard link_lo
    jsr $FFB7               ; READST
    and #$42
    bne @dir_eof
    jsr $FFCF               ; discard link lo

    ; Read and discard link_hi
    jsr $FFB7
    and #$42
    bne @dir_eof
    jsr $FFCF               ; discard link hi

    ; Read blkcount_lo
    jsr $FFB7
    and #$42
    bne @dir_eof
    jsr $FFCF
    sta hnd_scratch_lo      ; block count lo

    ; Read blkcount_hi
    jsr $FFB7
    and #$42
    bne @dir_eof
    jsr $FFCF
    sta hnd_scratch_hi      ; block count hi
    jmp @blk_print          ; skip trampolines

    ; Local trampolines — all branch targets above that were out of range
@dir_eof:       jmp @dir_done
@dir_open_err:  jmp @open_err
@dir_close_err: jmp @close_err

@blk_print:

    ; Print block count as decimal (16-bit, up to 65535), no leading zeros,
    ; followed by a space.
    ; hnd_scratch_lo/hi = value to print (consumed as remainder).
    ; hnd_jmp_lo/hi     = current divisor (borrowed; both free here).
    ; hnd_cmd_len       = leading-zero suppress flag (0=suppressing, $FF=seen).
    lda #0
    sta hnd_cmd_len         ; 0 = still suppressing leading zeros
    ldx #0                  ; divisor table index 0..3 (10000,1000,100,10)
@blk_digit:
    lda dir_div_lo,x
    sta hnd_jmp_lo
    lda dir_div_hi,x
    sta hnd_jmp_hi
    ldy #0                  ; Y = quotient digit for this position
@blk_sub:
    ; if scratch < divisor, stop subtracting
    lda hnd_scratch_hi
    cmp hnd_jmp_hi
    bcc @blk_emit           ; scratch_hi < div_hi → done
    bne @blk_do_sub         ; scratch_hi > div_hi → subtract
    lda hnd_scratch_lo
    cmp hnd_jmp_lo
    bcc @blk_emit           ; scratch_lo < div_lo → done
@blk_do_sub:
    lda hnd_scratch_lo
    sec
    sbc hnd_jmp_lo
    sta hnd_scratch_lo
    lda hnd_scratch_hi
    sbc hnd_jmp_hi
    sta hnd_scratch_hi
    iny
    jmp @blk_sub
@blk_emit:
    tya
    bne @blk_nonzero
    ; digit is zero
    lda hnd_cmd_len
    beq @blk_skip           ; still suppressing
    lda #$30                ; emit '0' after a nonzero digit
    jsr $FFD2
    jmp @blk_skip
@blk_nonzero:
    lda #$FF
    sta hnd_cmd_len         ; mark: nonzero digit seen
    tya
    ora #$30
    jsr $FFD2               ; emit digit
@blk_skip:
    inx
    cpx #4
    bne @blk_digit
    ; Units digit — always emit (remainder 0..9 in hnd_scratch_lo)
    lda hnd_scratch_lo
    ora #$30
    jsr $FFD2
    ; Space separator after block count
    lda #$20
    jsr $FFD2

    ; Print PETSCII content bytes until $00 line terminator
@char_loop:
    jsr $FFB7               ; READST
    and #$42
    bne @dir_done           ; EOF/error — close and exit
    jsr $FFCF               ; CHRIN
    beq @end_of_line        ; $00 = end of this line
    jsr $FFD2               ; CHROUT
    jmp @char_loop

@end_of_line:
    lda #$0D
    jsr $FFD2               ; newline after each entry
    jmp @line_loop

@dir_done:
    jsr $FFCC               ; CLRCHN
    lda #2
    jsr $FFC3               ; CLOSE 2
    jmp BASIC_NEWSTT

@close_err:
    jsr $FFCC
@open_err:
    lda #2
    jsr $FFC3               ; CLOSE 2 (harmless if not open)
    jmp BASIC_NEWSTT

hnd_dir_fname:
    .byte "$"

dir_div_lo: .byte <10000, <1000, <100, <10
dir_div_hi: .byte >10000, >1000, >100, >10

hnd_assemble:
    ; TODO: load MODASM from disk, call it, reload MODSCRH handlers
    jmp BASIC_NEWSTT

; ============================================================================
; Disk I/O helpers
; ============================================================================

; hnd_open_cmd_ch — open command channel (LA=15, SA=15, device=hnd_cur_drive)
hnd_open_cmd_ch:
    lda #15
    ldx hnd_cur_drive
    ldy #15
    jsr $FFBA           ; SETLFS
    lda #0              ; empty filename
    jsr $FFBD           ; SETNAM
    jsr $FFC0           ; OPEN
    rts                 ; C=0: open, C=1: error

; hnd_send_command — send hnd_cmd_buf (hnd_cmd_len bytes) to command channel
hnd_send_command:
    lda #15
    ldx hnd_cur_drive
    ldy #15
    jsr $FFBA           ; SETLFS
    lda hnd_cmd_len
    ldx #<hnd_cmd_buf
    ldy #>hnd_cmd_buf
    jsr $FFBD           ; SETNAM
    jsr $FFC0           ; OPEN
    bcs @err
    lda #15
    jsr $FFC3  ; CLOSE 15
@err:
    rts

; hnd_read_str_arg — read quoted string from TXTPTR into hnd_cmd_buf at offset A.
; Sets hnd_cmd_len. Advances TXTPTR past the string.
hnd_read_str_arg:
    sta hnd_scratch_lo  ; save write offset
    ldy #0
    ; skip spaces
@skip:
    lda (BASIC_TXTPTR),y
    cmp #$20
    bne @q
    inc BASIC_TXTPTR
    bne :+
    inc BASIC_TXTPTR+1
:   jmp @skip
@q: cmp #$22
bne @no_str  ; expect opening quote
    inc BASIC_TXTPTR
    bne :+
    inc BASIC_TXTPTR+1
:   ldx hnd_scratch_lo
@chars:
    lda (BASIC_TXTPTR),y
    beq @end
    cmp #$22
    beq @end
    sta hnd_cmd_buf,x
    inx
    inc BASIC_TXTPTR
    bne :+
    inc BASIC_TXTPTR+1
:   jmp @chars
@end:
    lda (BASIC_TXTPTR),y   ; skip closing quote if present
    cmp #$22
    bne :+
    inc BASIC_TXTPTR
    bne :+
    inc BASIC_TXTPTR+1
:   txa
sta hnd_cmd_len
    rts
@no_str:
    lda hnd_scratch_lo
    sta hnd_cmd_len
    rts
