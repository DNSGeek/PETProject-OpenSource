; ============================================================================
; modscr.asm — Script Runner setup stub for PETProject
;
; Loads at $A000 (standard module slot, same linker config as modasm).
; Companion: modscrh.asm (handler code, loads at $C000).
;
; Execution sequence:
;   1. Detect REU — bail if absent
;   2. Verify script metadata in REU (written by modsct.asm)
;   3. Deploy tokenized script to $0801 + patch BASIC vectors → JMP BASIC_RUN
;   4. Write MOD_SAVED_SP to HND_SAVED_SP ($C010) in modscrh state area
;   5. Save BASIC vector originals to modscrh state ($C011-$C016)
;   6. Stash IDE RAM ($0801-$9FFF) to REU $009000
;   7. DMA tokenized script from REU $000000 to $0801
;   8. Patch BASIC indirect vectors to modscrh entry points
;   9. Restore $01=$37, CLI, JMP BASIC_RUN
;
; modscrh.asm memory layout ($C000):
;   $C000 — execute stub (7 bytes: cli / lda #$00 / sta MOD_STATUS / rts)
;   $C007 — JMP hnd_dispatch    (IGONE: extended keyword dispatch)
;   $C00A — JMP hnd_end_script  (IMAIN: script ended, restore IDE)
;   $C00D — JMP hnd_error       (IERROR: BASIC runtime error)
;   $C010 — hnd_saved_sp  (1 byte:  SP saved before BASIC handoff)
;   $C011 — hnd_orig_igone  (2 bytes: original $0308)
;   $C013 — hnd_orig_imain  (2 bytes: original $0302)
;   $C015 — hnd_orig_ierror (2 bytes: original $0300)
;
; Linker config: same as modasm.cfg (no HANDLER segment needed).
; Build:
;   ca65 -g modscr.asm -o modscr.o
;   ld65 -C modasm.cfg modscr.o -o MODSCR
; ============================================================================

.setcpu "6502"

; ---- Module parameter block ----
MOD_MAGIC        = $0212
MOD_MAGIC_VAL    = $4D
MOD_DRIVE        = $021C
MOD_STATUS       = $021E
MOD_SAVED_SP     = $0227


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

REU_CMD_STASH = $90    ; EXECUTE | FF00-trigger-disable (immediate C64->REU)
REU_CMD_FETCH = $91    ; EXECUTE | FF00-trigger-disable (immediate REU->C64)

; ---- REU layout (mirrors modsct.asm) ----
REU_SCRIPT_MED  = $00 ; $000000: tokenized script
REU_META_MED    = $81 ; $008100: metadata
REU_IDE_MED     = $90 ; $009000: IDE snapshot

; ---- modscrh.asm state layout ($C000 = execute stub; JMP table at $C007) ----
HND_IGONE_ENTRY  = $C007   ; JMP hnd_dispatch
HND_IMAIN_ENTRY  = $C00A   ; JMP hnd_end_script
HND_IERROR_ENTRY = $C00D   ; JMP hnd_error
HND_SAVED_SP     = $C010   ; 1 byte: SP to restore on exit
HND_ORIG_IGONE   = $C011   ; 2 bytes: saved $0308
HND_ORIG_IMAIN   = $C013   ; 2 bytes: saved $0302
HND_ORIG_IERROR  = $C015   ; 2 bytes: saved $0300

; ---- BASIC indirect vectors ----
VEC_IERROR = $0300
VEC_IMAIN  = $0302
VEC_IGONE  = $0308

BASIC_RUN  = $A7AE    ; NEWSTT / execute next statement at TXTPTR
BASIC_RUNC = $A871    ; RUN entry: sets message mode, CLR (TXTPTR=TXTTAB-1), runs
BASIC_CLR  = $A659    ; CLR: reset vars/stack, set TXTPTR = TXTTAB-1
KERNAL_SETMSG = $FF90 ; control Kernal messages
KERNAL_CLRSCR = $E544 ; clear screen + home cursor (CLR/HOME routine)
TXTTAB     = $2B      ; start of BASIC program (lo/hi)
VARTAB     = $2D      ; start of variables = end of program (lo/hi)
MEMSIZ     = $37      ; top of BASIC RAM (lo/hi) — CLR copies this to FRETOP

; ---- IDE snapshot bounds ----
IDE_START  = $0801
IDE_LEN_LO = <($9FFF - $0801 + 1)
IDE_LEN_HI = >($9FFF - $0801 + 1)

; ---- Scratch ----
TMP16      = $3C      ; lo (hi=$3D)

; Metadata fetch buffer (module RAM, reused after verify)
META_BUF   = $B000

; ============================================================================

.segment "LOADADDR"
    .word $A000

.segment "CODE"

    jmp execute

; ============================================================================
; execute
; ============================================================================

execute:
    sei
    tsx
    stx HND_SAVED_SP
    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq :+
    jmp err_bad

:   jsr reu_detect
    bcs :+
    jmp err_noreu

:   jsr verify_script
    bcs :+
    jmp err_meta

    ; Save original BASIC vectors to modscrh state before patching
:   lda VEC_IGONE
    sta HND_ORIG_IGONE
    lda VEC_IGONE+1
    sta HND_ORIG_IGONE+1
    lda VEC_IMAIN
    sta HND_ORIG_IMAIN
    lda VEC_IMAIN+1
    sta HND_ORIG_IMAIN+1
    lda VEC_IERROR
    sta HND_ORIG_IERROR
    lda VEC_IERROR+1
    sta HND_ORIG_IERROR+1

    ; Stash IDE RAM to REU
    jsr stash_ide

    ; Deploy tokenized script to $0801
    jsr deploy_script

    ; Patch BASIC vectors to modscrh entry points
    lda #<HND_IGONE_ENTRY
    sta VEC_IGONE
    lda #>HND_IGONE_ENTRY
    sta VEC_IGONE+1

    lda #<HND_IMAIN_ENTRY
    sta VEC_IMAIN
    lda #>HND_IMAIN_ENTRY
    sta VEC_IMAIN+1

    lda #<HND_IERROR_ENTRY
    sta VEC_IERROR
    lda #>HND_IERROR_ENTRY
    sta VEC_IERROR+1

    ; Set up BASIC program pointers so RUN executes the deployed script.
    ; TXTTAB = $0801 (program start). VARTAB = TXTTAB + script length, i.e. the
    ; byte just past the program's terminating $00 $00 — this is where BASIC's
    ; variables begin. CLR (reached via the RUN entry below) uses VARTAB to
    ; reset the array/string pointers and sets TXTPTR = TXTTAB-1.
    lda #<IDE_START
    sta TXTTAB
    lda #>IDE_START
    sta TXTTAB+1
    clc
    lda #<IDE_START
    adc sclen_lo
    sta VARTAB
    lda #>IDE_START
    adc sclen_hi
    sta VARTAB+1

    ; MEMSIZ must be sane before the handoff stub's CLR runs: CLR copies
    ; MEMSIZ to FRETOP (top of the string heap).  Nothing since the IDE
    ; booted guarantees $37/$38 still hold a real value, and a garbage
    ; heap top makes the script's first string operation fail or corrupt
    ; zero page.  Scripts run with BASIC ROM banked in, so the top of
    ; BASIC RAM is $A000.
    lda #$00
    sta MEMSIZ
    lda #$A0
    sta MEMSIZ+1

    ; Restore BASIC ROM and hand off.
    ;
    ; CRITICAL: storing $37 to $01 banks BASIC ROM back in over $A000-$BFFF,
    ; which is exactly where THIS code lives. The instruction *after* the STA
    ; would be fetched from BASIC ROM, not our module — so we must run the
    ; bank-switch + JMP from RAM that is NOT overlaid by the ROM. Copy a tiny
    ; trampoline to the cassette buffer ($033C, free RAM) and jump to it.
    ldx #(handoff_stub_end - handoff_stub - 1)
:   lda handoff_stub,x
    sta $033C,x
    dex
    bpl :-
    jmp $033C

handoff_stub:
    lda #$37
    sta $01            ; BASIC ROM back in (safe: we're executing from $033C)
    cli
    jsr KERNAL_CLRSCR  ; clear the editor screen + MODULES popup before the
                       ; script paints its own output
    ; Start the program the way BASIC's main loop does, but WITHOUT going
    ; through the RUN keyword entry ($A871). RUN inspects the Z flag at entry
    ; to decide between "run from start" and "RUN <line>"; entered cold from
    ; here the flag state is unreliable and it wrongly takes the RUN <line>
    ; path, fetches the program's link word as a line number, and errors out.
    ; Instead: CLR (sets TXTPTR = TXTTAB-1, resets vars/stack) then jump
    ; straight into the statement loop at NEWSTT.
    jsr BASIC_CLR
    jmp BASIC_RUN
handoff_stub_end:

; ============================================================================
; Error exits
; ============================================================================

err_bad:
    cli
    lda #$01
    sta MOD_STATUS
    rts

err_noreu:
    cli
    ldy #0
@w: lda msg_noreu,y
    beq :+
    sta $0400,y
    lda #2
    sta $D800,y
    iny
    bne @w
:   lda #$01
    sta MOD_STATUS
    rts

err_meta:
    cli
    ldy #0
@w: lda msg_meta,y
    beq :+
    sta $0400,y
    lda #2
    sta $D800,y
    iny
    bne @w
:   lda #$01
    sta MOD_STATUS
    rts

; ============================================================================
; stash_ide — DMA $0801-$9FFF → REU $009000
; ============================================================================

stash_ide:
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
    lda #REU_CMD_STASH
    sta REU_COMMAND
    rts

; ============================================================================
; deploy_script — DMA REU $000000 → $0801 (sclen_lo/hi bytes)
; ============================================================================

deploy_script:
    ; The TXTPTR = TXTTAB-1 convention (CLR, GOTO, and modscrh's ONERR
    ; resume) requires the byte before the program — $0800 — to be $00.
    ; BASIC cold start normally leaves it that way; guarantee it.
    lda #0
    sta IDE_START-1
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    lda #<IDE_START
    sta REU_C64_LO
    lda #>IDE_START
    sta REU_C64_HI
    lda #0
    sta REU_REU_LO
    lda #0
    sta REU_REU_MED
    lda #0
    sta REU_REU_HI
    lda sclen_lo
    sta REU_LEN_LO
    lda sclen_hi
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND
    rts

; ============================================================================
; reu_detect — C=1: REU found. C=0: absent.
; ============================================================================

reu_detect:
    lda $DF05
    pha
    lda #$55
    sta $DF05
    lda $DF05
    tax
    lda #$AA
    sta $DF05
    lda $DF05
    tay
    pla
    sta $DF05
    cpx #$55
    bne @no
    cpy #$AA
    bne @no
    sec
    rts
@no:
    clc
    rts

; ============================================================================
; verify_script — fetch metadata from REU $008100, check magic, extract length.
; C=1 on success (magic OK), C=0 on failure.
; Sets sclen_lo/sclen_hi from metadata.
; ============================================================================
verify_script:
    ldy #0
    sty REU_INTMASK
    sty REU_ADDCTL
    lda #<META_BUF
    sta REU_C64_LO
    lda #>META_BUF
    sta REU_C64_HI
    lda #0
    sta REU_REU_LO
    lda #REU_META_MED       ; $81
    sta REU_REU_MED
    lda #0
    sta REU_REU_HI
    lda #6                  ; META_SIZE
    sta REU_LEN_LO
    lda #0
    sta REU_LEN_HI
    lda #REU_CMD_FETCH
    sta REU_COMMAND
    ; Check magic bytes
    lda META_BUF
    cmp #$53                ; 'S'
    bne @bad
    lda META_BUF+1
    cmp #$43                ; 'C'
    bne @bad
    ; Extract script length
    lda META_BUF+2
    sta sclen_lo
    lda META_BUF+3
    sta sclen_hi
    ; Sanity-clamp before this length drives a DMA over $0801+: stale REU
    ; contents from an earlier session can still pass the 2-byte magic
    ; check.  Valid script: >= 2 bytes (the $00 $00 end marker) and
    ; <= $97FF (deploy window $0801-$9FFF).  Note an REU length of 0
    ; would transfer 64 KB — over this module itself mid-handoff.
    lda sclen_hi
    cmp #$98
    bcs @bad                ; > $97FF — overruns the deploy window
    bne @len_ok             ; $01xx-$97xx — certainly >= 2
    lda sclen_lo
    cmp #2
    bcc @bad                ; 0 or 1 bytes — no valid script is that small
@len_ok:
    sec
    rts
@bad:
    clc
    rts

sclen_lo: .byte 0
sclen_hi: .byte 0

msg_noreu:
    ; "REU NOT FOUND " in C64 screen codes
    .byte $12,$05,$15,$20,$0E,$0F,$14,$20,$06,$0F,$15,$0E,$04,$20, 0

msg_meta:
    ; "SCRIPT META ERR" in C64 screen codes
    .byte $13,$03,$12,$09,$10,$14,$20,$0D,$05,$14,$01,$20,$05,$12,$12, 0
