; ============================================================================
; boot128.asm — C128 boot sector for the PETProject disk (track 1, sector 0)
;
; Assembled with -D TARGET_C128 and linked with boot128.cfg into a raw
; 256-byte image; make_disk.py --boot-sector writes it to track 1 sector 0.
;
; What the C128 KERNAL does on reset (BASIC's cold start calls BOOT_CALL,
; $FF53; disassembled from the 318020-05 KERNAL at $F890):
;   1. reads track 1 sector 0 into $0B00 and checks for "CBM";
;   2. copies bytes 3-6 (load address, bank, count) and loads `count`
;      further sectors there — we use none;
;   3. prints "BOOTING ", the message string, "...";
;   4. if the filename string is non-empty, loads that file — we leave it
;      empty and load ourselves, so the relaunch check below runs BEFORE
;      the 29 K load rather than after it;
;   5. calls the code that follows the filename through JSRFAR ($02CD) in
;      bank 15: BASIC + KERNAL ROM in, I/O in, RAM below $4000 — so the
;      KERNAL jump table is callable and an RTS returns to BASIC's READY.
;
; Relaunch guard: the editor's quit path returns to BASIC via its cold
; start, which runs this boot sector again. The quit path leaves
; C128_BOOT_FLAG_QUIT at C128_BOOT_FLAG; we see it, clear it and return,
; so the user lands at READY. A reset afterwards boots normally because
; the flag is clear; a power cycle randomises it (see c128.inc).
; ============================================================================

.include "layout.inc"
.include "c128.inc"

SETLFS  = $FFBA
SETNAM  = $FFBD
LOAD    = $FFD5
FA      = $BA               ; current device number — the drive we booted from

.segment "CODE"

    .byte "CBM"             ; boot-sector signature
    .word $0000             ; load address for additional sectors (unused)
    .byte $00               ; bank for additional sectors (unused)
    .byte $00               ; number of additional sectors: none
    .byte "PETPROJECT", $00 ; KERNAL prints: BOOTING PETPROJECT...
    .byte $00               ; no filename — loaded below instead

boot:
    lda C128_BOOT_FLAG
    cmp #C128_BOOT_FLAG_QUIT
    bne load
    lda #$00
    sta C128_BOOT_FLAG      ; one-shot: the next reset boots normally
    rts                     ; the editor just quit — back to BASIC's READY

load:
    lda #$00                ; data bank 0
    tax                     ; filename bank 0
    jsr C128_SETBNK
    lda #$01                ; logical file 1
    ldx FA                  ; the boot device
    ldy #$01                ; secondary address 1: use the file's own load address
    jsr SETLFS
    lda #fname_len
    ldx #<fname
    ldy #>fname
    jsr SETNAM
    lda #$00                ; LOAD, not VERIFY
    jsr LOAD
    bcs fail
    jmp EDITOR_LOAD + 12    ; the editor's entry point; it sets the session MMU config first
fail:
    rts                     ; leave the KERNAL's error status; BASIC shows READY

fname:
    .byte "PETPROJECT128"
fname_len = * - fname

.assert * <= $0C00, error, "boot128: boot sector overflows 256 bytes"
