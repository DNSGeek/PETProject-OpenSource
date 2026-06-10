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
; Status: all 13 implemented. DRIVE, PAUSE, STATUS, RUNPROG, DELETE, SCRATCH,
; ONERR, DIR, RENAME, COPY, EXISTS, ASSEMBLE are live handlers; INCLUDE is a
; deliberate runtime no-op (resolved at tokenize time by MODSCT).
;
; BASIC ROM addresses used:
;   $A7AE : NEWSTT — jump here after handling a statement
;   $A7E7 : GONE   — original IGONE, for tokens $80-$CB
;   $B79E : GETBYT — evaluate expression, result byte in X
;   $7A/$7B : TXTPTR — current program text pointer
;
; REU layout for IDE restore (mirrors modscr.asm):
;   $009000 : IDE snapshot ($0801-$9FFF, written by modscr)
; REU regions claimed by ASSEMBLE (must stay clear of MODSCT/MODSCR usage):
;   $013000 : MODSCRH self-stash ($C000-$CFFF) while MODASM owns $C000
;   $014000 : running-script stash ($0801-$9FFF) while MODASM uses it as
;             the source gap buffer
; ASSEMBLE restores both via a trampoline in the cassette buffer ($033C) —
; the restore code can't live in $C000 since that's what it's restoring.
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
KERNAL_OPEN     = $FFC0
KERNAL_CLOSE    = $FFC3
KERNAL_CHKIN    = $FFC6
KERNAL_CLRCHN   = $FFCC
KERNAL_CHRIN    = $FFCF
KERNAL_CHROUT   = $FFD2
KERNAL_LOAD     = $FFD5
KERNAL_READST   = $FFB7

; ---- More BASIC ROM entries ----
BASIC_PTRGET    = $B08B   ; parse variable name at TXTPTR, create if needed;
                          ; returns descriptor/value pointer in $47/$48 (VARPNT)
BASIC_ERROR     = $A437   ; error dispatch: X = error code, JMP ($0300)
ERR_SYNTAX      = $0B     ; "?SYNTAX ERROR"
VARPNT          = $47     ; lo (hi=$48)

; ---- ASSEMBLE keyword support ----
; MODASM is loaded to $A000 (RAM under BASIC ROM) and called in batch mode
; (MOD_COMMAND=ASM_CMD_BATCH). It trashes $C000-$CFFF (its state + symbol
; table) - i.e. THIS module - so MODSCRH and the script RAM are stashed to
; spare REU space first and restored by a trampoline in the cassette buffer
; after MODASM returns. Keep the $02C0/$02C1 definitions in sync with
; modasm.asm.
ASM_CMD_BATCH       = $01
ASM_BATCH_FNAME_LEN = $02C0   ; output filename length passed to MODASM
ASM_BATCH_FNAME     = $02C1   ; output filename (16 bytes max)
ASM_RES_ERR         = $02D1   ; trampoline copy of ASM_ERR     ($C007)
ASM_RES_LINE_LO     = $02D2   ; trampoline copy of ASM_ERR_LINE ($C008)
ASM_RES_LINE_HI     = $02D3   ;                                 ($C009)

MODASM_ENTRY    = $A000   ; module entry (JMP assemble)
TRAMP_ADDR      = $033C   ; cassette buffer - free during a script
SRC_LOAD        = $0801   ; source file load target (script RAM is stashed)
SRC_LOAD_CAP_HI = $A0     ; refuse source reaching $A000

; REU stash regions for ASSEMBLE (bank 1 - clear of modsct/modscr usage:
;   $000000 tokenized script, $004000 include pool, $008100 metadata,
;   $009000-$0127FF IDE snapshot). Fits a 128KB 1700.
REU_BANK1        = $01
REU_HND_MED      = $30    ; $013000: MODSCRH stash ($C000-$CFFF, 4KB)
REU_SCRIPTRAM_MED = $40   ; $014000: script RAM stash ($0801-$9FFF)

REU_CMD_STASH = $90   ; C64 -> REU (EXECUTE | FF00-trigger-disable, immediate)


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

; ---- Module parameter block (mirrors modasm.asm / modules.asm) ----
; ASSEMBLE fills these before calling MODASM in batch mode.
MOD_MAGIC        = $0212
MOD_MAGIC_VAL    = $4D
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
hnd_arg1_len:    .byte 0      ; length of first string arg (RENAME/COPY/ASSEMBLE)
hnd_retry:       .byte 0      ; source-open retry flag (bare name -> ",S,R")

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
    jsr hnd_wait_x_jiffies
    jmp BASIC_NEWSTT

; hnd_wait_x_jiffies — busy-wait X jiffies (X=0 returns immediately).
; Clobbers hnd_scratch_lo/hi.
hnd_wait_x_jiffies:
    cpx #0              ; test the COUNT in X — not A
    beq @done           ; 0 → no wait
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
    rts

; ---- STATUS — read drive status string and print it ----
hnd_status:
    jsr hnd_read_drive_status
    bcs @done
    ; Print the captured status string, then a carriage return.
    ldy #0
@print:
    lda hnd_status_buf,y
    beq @print_done        ; null terminator
    jsr KERNAL_CHROUT
    iny
    cpy #40
    bcc @print
@print_done:
    lda #$0D
    jsr KERNAL_CHROUT      ; newline after status
@done:
    jmp BASIC_NEWSTT

; hnd_read_drive_status — open the command channel on the current drive,
; read the status string into hnd_status_buf (null-terminated), close.
; C=0: hnd_status_buf valid. C=1: channel could not be opened/selected.
hnd_read_drive_status:
    jsr hnd_open_cmd_ch     ; open command channel (LA=15)
    bcs @fail
    ldx #15
    jsr KERNAL_CHKIN        ; set input
    bcs @close_fail
    ldy #0
@read:
    jsr KERNAL_READST
    and #$42
    bne @eof                ; EOF/error
    jsr KERNAL_CHRIN
    cmp #$0D
    beq @eof                ; CR = end of status
    cpy #39
    bcs @skip
    sta hnd_status_buf,y
    iny
@skip:
    jmp @read
@eof:
    lda #0
    sta hnd_status_buf,y
    jsr KERNAL_CLRCHN
    lda #15
    jsr KERNAL_CLOSE
    clc
    rts
@close_fail:
    jsr KERNAL_CLRCHN
    lda #15
    jsr KERNAL_CLOSE
@fail:
    sec
    rts

; ---- DELETE "filename" / SCRATCH "pattern" — send S0:name to command channel ----
; NOTE: the digit in the DOS command string is the *DOS drive number* (always
; 0 on single-mechanism units like the 1541/1571/1581), NOT the IEC device
; number — that is selected via SETLFS in hnd_send_command. The old code put
; the device number here, which only worked for even device numbers because
; 1541 DOS masks the drive digit with 1 ("S8:" → drive 0 by luck; "S9:" →
; drive 1 → 'DRIVE NOT READY'). DRIVE 9/11 + DELETE now work.
hnd_delete:
hnd_scratch:
    lda #'S'
    sta hnd_cmd_buf
    lda #'0'
    sta hnd_cmd_buf+1
    lda #':'
    sta hnd_cmd_buf+2
    lda #3
    jsr hnd_read_str_arg  ; appends filename, sets hnd_cmd_len
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
    ; Loading failed — end the script and restore the IDE. hnd_end_script
    ; restores the IDE from the REU and never returns here.
    jmp hnd_end_script
@done:
    jmp BASIC_NEWSTT

; ---- RENAME "old" TO "new" — DOS R0:new=old ----
; ---- COPY   "src" TO "dst" — DOS C0:dst=src ----
; Shared body: only the command letter differs. Malformed arguments (missing
; string or missing TO) raise a real ?SYNTAX ERROR through the IERROR hook,
; so ONERR can catch them.
hnd_rename:
    lda #'R'
    .byte $2C               ; BIT abs — skip the next LDA
hnd_copy:
    lda #'C'
    sta hnd_cmd_buf
    lda #'0'                ; DOS drive number — always 0 (see hnd_delete note)
    sta hnd_cmd_buf+1
    lda #':'
    sta hnd_cmd_buf+2
    ; First arg (old/src) parks at hnd_cmd_buf+40 until we know the second
    lda #40
    jsr hnd_read_str_arg
    lda hnd_cmd_len
    sec
    sbc #40
    beq @syn                ; empty first arg
    sta hnd_arg1_len
    jsr hnd_expect_to       ; consume the TO token ($A4)
    bcc @syn
    ; Second arg (new/dst) lands right after the "x0:" prefix
    lda #3
    jsr hnd_read_str_arg
    lda hnd_cmd_len
    cmp #4
    bcc @syn                ; empty second arg
    ; Append '=' then the first arg: "x0:new=old"
    ldx hnd_cmd_len
    lda #'='
    sta hnd_cmd_buf,x
    inx
    ldy #0
@cp:
    lda hnd_cmd_buf+40,y
    sta hnd_cmd_buf,x
    inx
    iny
    cpy hnd_arg1_len
    bne @cp
    stx hnd_cmd_len
    jsr hnd_send_command
    jmp BASIC_NEWSTT
@syn:
    jmp hnd_syntax_err

; ---- EXISTS "file" — set BASIC variable EX to 1 (exists) or 0 (not) ----
; Opens the file for read with a bare name (default type P on CBM DOS, which
; matches editor-saved sources), then reads the drive's error channel:
;   00 = opened fine            → exists
;   64 = FILE TYPE MISMATCH     → exists (it's there, just SEQ/USR/REL)
;   62 = FILE NOT FOUND (etc.)  → does not exist
hnd_exists:
    lda #0
    jsr hnd_read_str_arg
    lda hnd_cmd_len
    beq @syn
    lda #2
    ldx hnd_cur_drive
    ldy #2                  ; SA=2 read
    jsr KERNAL_SETLFS
    lda hnd_cmd_len
    ldx #<hnd_cmd_buf
    ldy #>hnd_cmd_buf
    jsr KERNAL_SETNAM
    jsr KERNAL_OPEN
    php                     ; remember open result
    lda #2
    jsr KERNAL_CLOSE        ; close the probe channel either way
    plp
    bcs @no                 ; C64-side open failure → treat as not found
    jsr hnd_read_drive_status
    bcs @no
    lda hnd_status_buf
    cmp #'0'
    bne @chk64
    lda hnd_status_buf+1
    cmp #'0'
    beq @yes                ; "00, OK"
    bne @no
@chk64:
    cmp #'6'
    bne @no
    lda hnd_status_buf+1
    cmp #'4'
    beq @yes                ; "64, FILE TYPE MISMATCH" — present, wrong type
@no:
    lda #0
    beq @set
@yes:
    lda #1
@set:
    jsr hnd_set_ex
    jmp BASIC_NEWSTT
@syn:
    jmp hnd_syntax_err

; hnd_set_ex — store A (0 or 1) into BASIC numeric variable EX, creating it
; if needed. Uses PTRGET by temporarily pointing TXTPTR at a private "EX"
; string — exactly the parse LET performs — then restores TXTPTR and writes
; the 5-byte float directly through VARPNT.
hnd_set_ex:
    pha
    lda BASIC_TXTPTR
    sta hnd_scratch_lo
    lda BASIC_TXTPTR+1
    sta hnd_scratch_hi
    lda #<hnd_ex_name
    sta BASIC_TXTPTR
    lda #>hnd_ex_name
    sta BASIC_TXTPTR+1
    jsr BASIC_PTRGET        ; find/create EX; VARPNT ($47/$48) → value bytes
    lda hnd_scratch_lo
    sta BASIC_TXTPTR
    lda hnd_scratch_hi
    sta BASIC_TXTPTR+1
    pla
    ldy #0
    cmp #0
    beq @exp                ; 0.0: exponent byte 0 (mantissa irrelevant, zeroed)
    lda #$81                ; 1.0: exponent $81, mantissa $00 00 00 00
@exp:
    sta (VARPNT),y
    lda #0
@fill:
    iny
    sta (VARPNT),y
    cpy #4
    bne @fill
    rts

hnd_ex_name:
    .byte "EX",0            ; PTRGET stops at the non-alphanumeric terminator

; hnd_expect_to — skip spaces, require the TO token ($A4), advance past it.
; C=1: consumed. C=0: not found (TXTPTR left at the offending char).
hnd_expect_to:
    ldy #0
@skip:
    lda (BASIC_TXTPTR),y
    cmp #$20
    bne @chk
    inc BASIC_TXTPTR
    bne @skip
    inc BASIC_TXTPTR+1
    bne @skip               ; (always)
@chk:
    cmp #$A4                ; TO token
    bne @no
    inc BASIC_TXTPTR
    bne :+
    inc BASIC_TXTPTR+1
:   sec
    rts
@no:
    clc
    rts

; hnd_syntax_err — raise ?SYNTAX ERROR through BASIC's error dispatch.
; Flows through our IERROR hook, so ONERR catches it like any runtime error.
hnd_syntax_err:
    ldx #ERR_SYNTAX
    jmp BASIC_ERROR

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

    ; Print block count as 16-bit decimal, then a space separator.
    ; (Printer shared with ASSEMBLE's error-line report — see hnd_print_u16.)
    jsr hnd_print_u16
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

; ----------------------------------------------------------------------------
; hnd_print_u16 — print hnd_scratch_lo/hi as unsigned decimal (0..65535),
; no leading zeros. Shared by DIR (block counts) and ASSEMBLE (error line).
;   In:       hnd_scratch_lo/hi = value
;   Clobbers: A, X, Y, hnd_scratch_lo/hi (consumed as remainder),
;             hnd_jmp_lo/hi (current divisor), hnd_cmd_len (zero-suppress flag)
; ----------------------------------------------------------------------------
hnd_print_u16:
    lda #0
    sta hnd_cmd_len         ; 0 = still suppressing leading zeros
    ldx #0                  ; divisor table index 0..3 (10000,1000,100,10)
@digit:
    lda dir_div_lo,x
    sta hnd_jmp_lo
    lda dir_div_hi,x
    sta hnd_jmp_hi
    ldy #0                  ; Y = quotient digit for this position
@sub:
    ; if scratch < divisor, stop subtracting
    lda hnd_scratch_hi
    cmp hnd_jmp_hi
    bcc @emit               ; scratch_hi < div_hi → done
    bne @do_sub             ; scratch_hi > div_hi → subtract
    lda hnd_scratch_lo
    cmp hnd_jmp_lo
    bcc @emit               ; scratch_lo < div_lo → done
@do_sub:
    lda hnd_scratch_lo
    sec
    sbc hnd_jmp_lo
    sta hnd_scratch_lo
    lda hnd_scratch_hi
    sbc hnd_jmp_hi
    sta hnd_scratch_hi
    iny
    jmp @sub
@emit:
    tya
    bne @nonzero
    ; digit is zero
    lda hnd_cmd_len
    beq @skip               ; still suppressing
    lda #$30                ; emit '0' after a nonzero digit
    jsr $FFD2
    jmp @skip
@nonzero:
    lda #$FF
    sta hnd_cmd_len         ; mark: nonzero digit seen
    tya
    ora #$30
    jsr $FFD2               ; emit digit
@skip:
    inx
    cpx #4
    bne @digit
    ; Units digit — always emit (remainder 0..9 in hnd_scratch_lo)
    lda hnd_scratch_lo
    ora #$30
    jmp $FFD2               ; emit and return via CHROUT

; ============================================================================
; ASSEMBLE "source" TO "output" — run the MODASM assembler from a script.
;
; Why this is delicate: MODASM owns two regions a running script depends on.
;   * $A000-$BFFF — its own code (RAM under BASIC ROM; free during a script)
;   * $C000-$CFFF — its state + symbol table... which is THIS module.
; It also needs the source text in a RAM buffer, and the only space big
; enough is $0801-$9FFF — which currently holds the running BASIC script,
; its variables and strings.
;
; Sequence:
;   1. Parse "source" TO "output"; pass the output name to MODASM's batch
;      param area ($02C0) and set MOD_COMMAND=ASM_CMD_BATCH (no prompt).
;   2. STASH $C000-$CFFF → REU $013000 and $0801-$9FFF → REU $014000.
;   3. Load the source file from the current drive to $0801 (bare name
;      first — editor-saved sources are PRG-typed raw text — then retry
;      with ",S,R" for genuine SEQ files). Append a final CR if missing.
;   4. Load MODASM from device 8 to $A000 (writes land in RAM under ROM).
;   5. Copy a trampoline to the cassette buffer and jump to it. It banks
;      to $36, calls MODASM, captures the error info from $C007-$C009,
;      FETCHes both REU stashes back, banks to $37, and jumps to
;      hnd_asm_resume — which by then exists again. The trampoline is
;      needed because the code performing the $C000 restore cannot itself
;      live in $C000: after MODASM runs, that region is symbol-table soup
;      until the DMA completes.
;   6. hnd_asm_resume: MOD_STATUS=0 → next statement. Otherwise print
;      "?ASSEMBLE ERROR IN LINE n" and route through hnd_error, so ONERR
;      catches assembly failures like any other runtime error.
;
; The script program text, variables, strings, TXTPTR, and the CPU stack
; all survive byte-identically; the statement simply continues. Logical
; files 2 and 15 are used transiently (same convention as DIR/STATUS).
; ============================================================================

hnd_assemble:
    ; ---- Parse: source name at hnd_cmd_buf+0, output name at +40 ----
    lda #0
    jsr hnd_read_str_arg
    lda hnd_cmd_len
    beq @syn
    cmp #21
    bcs @syn                    ; name + ",S,R" retry must fit kernal's 16+4
    sta hnd_arg1_len            ; remember source name length
    jsr hnd_expect_to
    bcc @syn
    lda #40
    jsr hnd_read_str_arg
    lda hnd_cmd_len
    sec
    sbc #40
    beq @syn
    cmp #17
    bcs @syn                    ; output name >16 chars won't fit ASM_FNAME
    bcc @parse_ok               ; (always taken: cmp cleared carry)
@syn:
    jmp hnd_syntax_err          ; near trampoline — far targets out of range
@parse_ok:
    ; ---- Hand the output name to MODASM's batch area (survives in page 2) ----
    sta ASM_BATCH_FNAME_LEN
    tay
@ocopy:
    dey
    lda hnd_cmd_buf+40,y
    sta ASM_BATCH_FNAME,y
    cpy #0
    bne @ocopy
    lda hnd_arg1_len
    sta hnd_cmd_len             ; cmd_buf[0..len-1] = source name again

    ; ---- Stash MODSCRH ($C000-$CFFF) and script RAM ($0801-$9FFF) to REU ----
    ; STASH is a copy: we keep executing from intact $C000 RAM until MODASM
    ; tramples it.
    jsr hnd_asm_stash

    ; ---- Load the source file into the (now stashed) script RAM ----
    jsr hnd_load_source
    bcc @src_ok
    ; A/Y = error message pointer set by hnd_load_source
    jsr hnd_print_strz
    jmp hnd_asm_fail
@src_ok:

    ; ---- Parameter block for MODASM: linear buffer, empty gap ----
    lda #MOD_MAGIC_VAL
    sta MOD_MAGIC
    lda #ASM_CMD_BATCH
    sta MOD_COMMAND
    lda #<SRC_LOAD
    sta MOD_BUF_LO
    lda #>SRC_LOAD
    sta MOD_BUF_HI
    lda HND_TMP                 ; hnd_load_source left end-of-source here
    sta MOD_GAP_START_LO
    sta MOD_GAP_END_LO
    sta MOD_BUF_END_LO
    lda HND_TMP+1
    sta MOD_GAP_START_HI
    sta MOD_GAP_END_HI
    sta MOD_BUF_END_HI
    lda hnd_cur_drive
    sta MOD_DRIVE               ; MODASM writes the output PRG here
    lda #$FF
    sta MOD_STATUS

    ; ---- Load MODASM from device 8 (module home) to $A000 ----
    lda #2
    ldx #8
    ldy #1                      ; SA=1: honor PRG header load address ($A000)
    jsr KERNAL_SETLFS
    lda #6
    ldx #<hnd_modasm_name
    ldy #>hnd_modasm_name
    jsr KERNAL_SETNAM
    lda #0                      ; load, not verify
    jsr KERNAL_LOAD
    bcc @masm_ok
    lda #<msg_modasm_err
    ldy #>msg_modasm_err
    jsr hnd_print_strz
    jmp hnd_asm_fail
@masm_ok:

    ; ---- Trampoline to the cassette buffer and run the assembler ----
    ldx #(hnd_asm_tramp_end - hnd_asm_tramp - 1)
@tcopy:
    lda hnd_asm_tramp,x
    sta TRAMP_ADDR,x
    dex
    bpl @tcopy
    jmp TRAMP_ADDR

; ----------------------------------------------------------------------------
; hnd_asm_tramp — copied to TRAMP_ADDR ($033C) and executed there.
; Straight-line code only: no internal branches/JMPs, so it is position-
; independent except for the absolute references back into this module
; (valid again once the FETCH completes) and to ROM/REU registers.
; ----------------------------------------------------------------------------
hnd_asm_tramp:
    lda $00
    ora #$07
    sta $00
    lda #$36
    sta $01                     ; BASIC ROM out — $A000 is MODASM's RAM
    jsr MODASM_ENTRY            ; returns with $01=$36, IRQs enabled
    sei
    ; Capture error info before the restore wipes MODASM's state at $C000
    lda $C007                   ; ASM_ERR
    sta ASM_RES_ERR
    lda $C008                   ; ASM_ERR_LINE_LO
    sta ASM_RES_LINE_LO
    lda $C009                   ; ASM_ERR_LINE_HI
    sta ASM_RES_LINE_HI
    ; FETCH MODSCRH back: REU $013000 → $C000 ($1000 bytes)
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    sty REU_C64_LO
    lda #$C0
    sta REU_C64_HI
    sty REU_REU_LO
    lda #REU_HND_MED
    sta REU_REU_MED
    lda #REU_BANK1
    sta REU_REU_HI
    sty REU_LEN_LO
    lda #$10
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND
    ; FETCH script RAM back: REU $014000 → $0801
    ldy #0
    sty REU_C64_LO              ; (INTMASK/ADDCTL still 0)
    lda #<IDE_START
    sta REU_C64_LO
    lda #>IDE_START
    sta REU_C64_HI
    sty REU_REU_LO
    lda #REU_SCRIPTRAM_MED
    sta REU_REU_MED
    lda #REU_BANK1
    sta REU_REU_HI
    lda #IDE_LEN_LO
    sta REU_LEN_LO
    lda #IDE_LEN_HI
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND
    lda #$37
    sta $01                     ; BASIC ROM back in
    cli
    jmp hnd_asm_resume          ; restored along with the rest of MODSCRH
hnd_asm_tramp_end:

; ----------------------------------------------------------------------------
; hnd_asm_resume — everything is back in place; report the result.
; ----------------------------------------------------------------------------
hnd_asm_resume:
    lda MOD_STATUS
    beq @ok
    lda #<msg_asm_err
    ldy #>msg_asm_err
    jsr hnd_print_strz
    lda ASM_RES_LINE_LO
    sta hnd_scratch_lo
    lda ASM_RES_LINE_HI
    sta hnd_scratch_hi
    jsr hnd_print_u16
    lda #$0D
    jsr KERNAL_CHROUT
    jmp hnd_asm_err_out
@ok:
    jmp BASIC_NEWSTT

; hnd_asm_fail — a failure BEFORE MODASM ran (message already printed).
; $C000 is still intact, but $0801+ holds a partial source load — restore
; the script RAM, then route through the common error exit.
hnd_asm_fail:
    jsr hnd_restore_script_ram
hnd_asm_err_out:
    ; With ONERR set: branch immediately. Without it the script is about to
    ; end and the IDE repaint would eat the message — hold it on screen for
    ; two seconds first.
    lda hnd_onerr_lo
    ora hnd_onerr_hi
    bne @go
    ldx #120
    jsr hnd_wait_x_jiffies
@go:
    jmp hnd_error               ; ONERR target, or restore the IDE

; ----------------------------------------------------------------------------
; hnd_asm_stash — STASH $C000-$CFFF → REU $013000, $0801-$9FFF → REU $014000
; ----------------------------------------------------------------------------
hnd_asm_stash:
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    sty REU_C64_LO
    lda #$C0
    sta REU_C64_HI
    sty REU_REU_LO
    lda #REU_HND_MED
    sta REU_REU_MED
    lda #REU_BANK1
    sta REU_REU_HI
    sty REU_LEN_LO
    lda #$10
    sta REU_LEN_HI
    lda #REU_CMD_STASH
    sta REU_COMMAND
    ; fall through to script RAM stash
    ldy #0
    lda #<IDE_START
    sta REU_C64_LO
    lda #>IDE_START
    sta REU_C64_HI
    sty REU_REU_LO
    lda #REU_SCRIPTRAM_MED
    sta REU_REU_MED
    lda #REU_BANK1
    sta REU_REU_HI
    lda #IDE_LEN_LO
    sta REU_LEN_LO
    lda #IDE_LEN_HI
    sta REU_LEN_HI
    lda #REU_CMD_STASH
    sta REU_COMMAND
    rts

; hnd_restore_script_ram — FETCH REU $014000 → $0801-$9FFF
hnd_restore_script_ram:
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    lda #<IDE_START
    sta REU_C64_LO
    lda #>IDE_START
    sta REU_C64_HI
    sty REU_REU_LO
    lda #REU_SCRIPTRAM_MED
    sta REU_REU_MED
    lda #REU_BANK1
    sta REU_REU_HI
    lda #IDE_LEN_LO
    sta REU_LEN_LO
    lda #IDE_LEN_HI
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND
    rts

; ----------------------------------------------------------------------------
; hnd_load_source — read the source file (name in hnd_cmd_buf, length in
; hnd_cmd_len) from the current drive into $0801+.
; Tries the bare name first (matches editor-saved PRG-typed text), then
; retries once with ",S,R" appended for genuine SEQ files.
; C=0: success, HND_TMP = one past last byte (final CR guaranteed).
; C=1: failure, A/Y = error message pointer.
; ----------------------------------------------------------------------------
hnd_load_source:
    lda #0
    sta hnd_retry
@try:
    lda #2
    ldx hnd_cur_drive
    ldy #2                      ; SA=2 read
    jsr KERNAL_SETLFS
    lda hnd_cmd_len
    ldx #<hnd_cmd_buf
    ldy #>hnd_cmd_buf
    jsr KERNAL_SETNAM
    jsr KERNAL_OPEN
    bcs @fail_near
    ldx #2
    jsr KERNAL_CHKIN
    bcc @open_ok
@fail_near:
    jmp @fail_close             ; near trampoline — far target out of range
@open_ok:
    lda #<SRC_LOAD
    sta HND_TMP
    lda #>SRC_LOAD
    sta HND_TMP+1
@rd:
    jsr KERNAL_CHRIN
    ldy #0
    sta (HND_TMP),y
    jsr KERNAL_READST
    beq @adv                    ; clean byte — keep going
    cmp #$40
    beq @adv_done               ; clean EOF — keep this byte, finish
    jmp @rd_close               ; timeout/error — drop the byte, evaluate below
@adv:
    jsr @bump
    bcs @too_big
    jmp @rd
@adv_done:
    jsr @bump
    bcs @too_big
@rd_close:
    jsr KERNAL_CLRCHN
    lda #2
    jsr KERNAL_CLOSE
    ; Anything actually read? Not-found shows up as a zero-length read.
    lda HND_TMP
    cmp #<SRC_LOAD
    bne @got
    lda HND_TMP+1
    cmp #>SRC_LOAD
    bne @got
    ; Zero bytes — retry once with ",S,R"
    lda hnd_retry
    bne @not_found
    inc hnd_retry
    ldx hnd_cmd_len
    lda #','
    sta hnd_cmd_buf,x
    lda #'S'
    sta hnd_cmd_buf+1,x
    lda #','
    sta hnd_cmd_buf+2,x
    lda #'R'
    sta hnd_cmd_buf+3,x
    inx
    inx
    inx
    inx
    stx hnd_cmd_len
    jmp @try
@got:
    ; Guarantee the source ends with a CR (the parser is line-oriented)
    lda HND_TMP
    bne :+
    dec HND_TMP+1
:   dec HND_TMP
    ldy #0
    lda (HND_TMP),y
    pha
    inc HND_TMP
    bne :+
    inc HND_TMP+1
:   pla
    cmp #$0D
    beq @done
    lda #$0D
    sta (HND_TMP),y
    jsr @bump
    bcs @too_big
@done:
    clc
    rts
@bump:
    inc HND_TMP
    bne :+
    inc HND_TMP+1
:   lda HND_TMP+1
    cmp #SRC_LOAD_CAP_HI        ; reaching $A000 = too large
    rts                         ; C=1 if at/over the cap
@too_big:
    jsr KERNAL_CLRCHN
    lda #2
    jsr KERNAL_CLOSE
    lda #<msg_src_big
    ldy #>msg_src_big
    sec
    rts
@fail_close:
    jsr KERNAL_CLRCHN
    lda #2
    jsr KERNAL_CLOSE
@not_found:
    lda #<msg_src_nf
    ldy #>msg_src_nf
    sec
    rts

; hnd_print_strz — print null-terminated PETSCII string at A(lo)/Y(hi)
hnd_print_strz:
    sta HND_TMP
    sty HND_TMP+1
    ldy #0
@pl:
    lda (HND_TMP),y
    beq @pd
    jsr KERNAL_CHROUT
    iny
    bne @pl
@pd:
    rts

hnd_modasm_name:
    .byte $4D,$4F,$44,$41,$53,$4D   ; "MODASM" (matches modules.asm)

msg_src_nf:
    .byte "?ASSEMBLE: SOURCE NOT FOUND",$0D,0
msg_src_big:
    .byte "?ASSEMBLE: SOURCE TOO LARGE",$0D,0
msg_modasm_err:
    .byte "?ASSEMBLE: MODASM LOAD FAILED",$0D,0
msg_asm_err:
    .byte "?ASSEMBLE ERROR IN LINE ",0

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
