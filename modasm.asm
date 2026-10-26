; ============================================================================
; modasm.asm  -  Two-pass 6502 assembler module for PETProject
;
; Loaded at $A000 by the editor (BASIC ROM paged out: $01=$36).
; Kernal remains mapped throughout  -  channel I/O works normally.
; ($36 = LORAM=0, HIRAM=1, CHAREN=1: RAM at $A000, Kernal+I/O in)
; Entry: JSR $A000 (first 3 bytes = JMP assemble)
;
; Input:  Plain text in editor gap buffer (via MOD_BUF/GAP params).
;         Source lines: [label:] MNEMONIC [operand] [;comment] CR
;         Labels: up to 8 chars, alphanumeric + underscore, end with ':'
;         Mnemonics: uppercase, all official 6502
;         Operands: #val  val  val,X  val,Y  (val)  (val,X)  (val),Y  A
;         Values: $xx/$xxxx hex, decimal, label, label+N, label-N, <expr, >expr
;         Directives: .org / *= addr    .byte val[,val...]    .word val[,val...]
;                     .text "string"    .include "filename"
;
; Output: PRG file written directly to disk via Kernal channel I/O.
;         Filename: editor prompts for output name via status bar before assembly.
;         PRG header: the address of the first output byte ($0801 by default).
;         The file is one contiguous image: a later forward .org is padded
;         with $00 bytes, a backward one is an error (ORG BACKWARDS).
;
; Symbol table: ASM_STATE+$60 .. ASM_STATE+$FFF, 10 bytes/entry (8-char name + 2-byte value).
;               Up to 409 symbols. Linear scan  -  fast enough for casual use.
;
; Error reporting: first error message written to ASM_ERR_MSG area,
;                  line number in ASM_ERR_LINE_LO/HI. MOD_STATUS=$01.
;
; Zero page (saved/restored; addresses come from zp.inc):
;   ZP_PTR2    = SRC_PTR   walks source (gap-aware)
;   ZP_PTR3    = not used by modasm, but saved/restored with the pool
;   ZP_SCRATCH = TMP/TMP2/TMP3
;
; State variables at $0200-$0257 (page 2, Kernal-safe zones):
;   $0200-$0211: before MOD_* param block  -  ZP_SAVE + core state
;   $0223-$0257: after MOD_* param block  -  err info, fname, gap ptrs, parse scratch
;   Deliberately avoids $0259-$027C (Kernal open-file device/SA/name tables)
;   which are overwritten by OPEN/CHKOUT during output file creation.
;
; Mode constants (opcode table encoding):
;   IMP=0 ACC=1 IMM=2 ZP=3 ZPX=4 ZPY=5 ABS=6 ABX=7 ABY=8 IND=9 IZX=10 IZY=11 REL=12
; ============================================================================

.setcpu "6502"

; ---- Parameter block ($0212-$0220) ----
MOD_MAGIC        = $0212
MOD_MAGIC_VAL    = $4D
MOD_COMMAND      = $0213

; ---- Batch invocation (MOD_COMMAND = ASM_CMD_BATCH) ----
; Set by MODSCRH's ASSEMBLE keyword handler. In batch mode there is no
; keyboard and no status-bar prompt: the output filename is passed in the
; unused page-2 area $02C0-$02D0 instead. Keep these three definitions in
; sync with modscrh.asm.
ASM_CMD_BATCH       = $01
ASM_BATCH_FNAME_LEN = $02C0   ; output filename length (1-16)
ASM_BATCH_FNAME     = $02C1   ; output filename (16 bytes max)
MOD_BUF_LO       = $0214
MOD_BUF_HI       = $0215
MOD_GAP_START_LO = $0216
MOD_GAP_START_HI = $0217
MOD_GAP_END_LO   = $0218
MOD_GAP_END_HI   = $0219
MOD_BUF_END_LO   = $021A
MOD_BUF_END_HI   = $021B
MOD_DRIVE        = $021C
MOD_STATUS       = $021E

; ---- Kernal routines ----
SETLFS  = $FFBA
SETNAM  = $FFBD
OPEN    = $FFC0
CHKIN   = $FFC6
CHKOUT  = $FFC9
CHRIN   = $FFCF
CHROUT  = $FFD2
CLOSE   = $FFC3
CLRCHN  = $FFCC
GETIN   = $FFE4
READST  = $FFB7

; ---- Screen/color RAM ----
SCREEN      = $0400
COLOR       = $D800
STATUS_ROW  = SCREEN        ; row 0 = status bar
COLS        = 40
DEFAULT_COLOR = 14          ; light blue

; ---- ZP ----
; Addresses come from zp.inc (see docs/c128-port-notes.md).
.include "zp.inc"
.include "layout.inc"   ; MOD_LO_BASE / MOD_LO_SIZE for the ASM_STATE block
.ifdef TARGET_C128
.include "c128.inc"     ; MMU session config
.endif

SRC_PTR  = ZP_PTR2       ; lo (hi=+1)  -  source walker, gap-aware
TMP      = ZP_SCRATCH+0  ; general scratch (hi=+1)
TMP2     = ZP_SCRATCH+2  ; (hi=+3)
TMP3     = ZP_SCRATCH+4  ; (hi=+5)

; ---- Mode constants ----
MODE_IMP = 0
MODE_ACC = 1
MODE_IMM = 2
MODE_ZP  = 3
MODE_ZPX = 4
MODE_ZPY = 5
MODE_ABS = 6
MODE_ABX = 7
MODE_ABY = 8
MODE_IND = 9
MODE_IZX = 10
MODE_IZY = 11
MODE_REL = 12

; ---- Assembler state (page 2, always RAM regardless of banking) ----

; All working state lives in a 4 K block at ASM_STATE (= MOD_LO_BASE from
; layout.inc: $C000 on the C64, $9000 on the C128). The symbol table at
; ASM_STATE+$60 with SYM_MAX entries of 10 bytes fills the block exactly.
ASM_STATE       = MOD_LO_BASE
ASM_PC_LO       = ASM_STATE + $00   ; current program counter lo
ASM_PC_HI       = ASM_STATE + $01   ; current program counter hi
ASM_PASS        = ASM_STATE + $02   ; 0=pass1, 1=pass2
ASM_SYM_LO      = ASM_STATE + $03   ; symbol count lo
ASM_SYM_HI      = ASM_STATE + $04   ; symbol count hi
ASM_LINE_LO     = ASM_STATE + $05   ; current line number lo
ASM_LINE_HI     = ASM_STATE + $06   ; current line number hi
ASM_ERR         = ASM_STATE + $07   ; $FF = error encountered
ASM_ERR_LINE_LO = ASM_STATE + $08   ; line number of first error lo
ASM_ERR_LINE_HI = ASM_STATE + $09   ; line number of first error hi
ASM_ERR_MSG     = ASM_STATE + $0A   ; 20-byte error message (screen codes, zero-terminated)
ASM_OUT_LA      = ASM_STATE + $1E   ; logical file number for output
ASM_OUT_OPEN    = ASM_STATE + $1F   ; $FF = output file is open
ASM_EMITTED     = ASM_STATE + $20   ; $FF = this pass has placed an output byte
ASM_FNAME_LEN   = ASM_STATE + $21   ; output filename length
ASM_FNAME       = ASM_STATE + $22   ; output filename (16 bytes)

; ---- ZP save area ----
; ZP_SAVE_LEN (10) bytes: the ZP_SCRATCH block plus ZP_PTR2/ZP_PTR3.
; (Not zero page itself — module scratch RAM above the $A000 image.)
ZP_SAVE         = ASM_STATE + $3A
.assert ZP_SAVE + ZP_SAVE_LEN <= ASM_MNEM, error, "modasm: ZP_SAVE overruns into ASM_MNEM"

; ---- Gap pointers (copied from params) ----
ASM_GAP_S_LO    = ASM_STATE + $32
ASM_GAP_S_HI    = ASM_STATE + $33
ASM_GAP_E_LO    = ASM_STATE + $34
ASM_GAP_E_HI    = ASM_STATE + $35
ASM_BUF_LO      = ASM_STATE + $36
ASM_BUF_HI      = ASM_STATE + $37
ASM_END_LO      = ASM_STATE + $38
ASM_END_HI      = ASM_STATE + $39

; ---- Scratch for mnemonic/operand parsing ----
ASM_MNEM        = ASM_STATE + $44   ; 4 bytes: current mnemonic/directive name
ASM_MODE        = ASM_STATE + $48   ; resolved addressing mode
ASM_OPCODE      = ASM_STATE + $49   ; resolved opcode byte
ASM_VAL_LO      = ASM_STATE + $4A   ; operand value lo
ASM_VAL_HI      = ASM_STATE + $4B   ; operand value hi
ASM_INSTR_SIZE  = ASM_STATE + $4C   ; total instruction size (1+operand bytes)
ASM_LABEL       = ASM_STATE + $4D   ; 8 bytes: current label (space-padded)
ASM_YPEEK       = ASM_STATE + $55   ; scratch: src_peek Y save (1 byte, at end of state block)
ASM_OPC_PTR_LO  = ASM_STATE + $56   ; saved opcode table pointer lo (preserved across parse_operand)
ASM_OPC_PTR_HI  = ASM_STATE + $57   ; saved opcode table pointer hi

; PRG load address = the PC at the first output byte (mark_emit, pass 1),
; or $0801 if nothing is emitted.  Used by open_output for the PRG header.
; Lives in the gap between ASM_OPC_PTR_HI (+$57) and SYM_TABLE (+$60).
ASM_LOAD_LO     = ASM_STATE + $58   ; PRG load address lo
ASM_LOAD_HI     = ASM_STATE + $59   ; PRG load address hi
ASM_DS_CODE     = ASM_MNEM          ; close_output scratch: drive status digit

; Activity spinner — same corner cell and toggle mechanic as MODDIS.
ASM_SPINNER     = ASM_STATE + $5A   ; 8-bit line counter; every 16 lines → color flip
ASM_SPIN_IDX    = ASM_STATE + $5B   ; current color value written to SPIN_CELL

; parse_decimal ×10 scratch.  Deliberately NOT TMP2: parse_expr saves the
; base of a "label+N" / "label-N" expression in TMP2 across parse_number,
; so parse_decimal must not touch it.
ASM_MUL_LO      = ASM_STATE + $5C   ; ×10 partial (value*2) lo
ASM_MUL_HI      = ASM_STATE + $5D   ; ×10 partial (value*2) hi

; End-of-pass-1 PC, for the pass-2 phase check.  If the two passes end at
; different PCs (e.g. a forward reference sized as 16-bit in pass 1 that
; resolved to zero page in pass 2), the emitted PRG is silently misaligned
; from the point of divergence on — report PHASE ERROR instead.
ASM_P1END_LO    = ASM_STATE + $5E
ASM_P1END_HI    = ASM_STATE + $5F

SPIN_CELL       = $D800   ; color RAM col 0, row 0 (top-left corner)
SPIN_COLOR_A    = $01     ; white
SPIN_COLOR_B    = $00     ; black

; ---- Symbol table ----
SYM_TABLE       = ASM_STATE + $60   ; 10 bytes/entry: 8-char name + 2-byte value
SYM_ENTRY_SIZE  = 10
SYM_MAX         = 400
.assert SYM_TABLE + SYM_MAX * 10 <= MOD_LO_BASE + MOD_LO_SIZE, error, "modasm: symbol table overruns the MOD_LO region"

; ---- Output file ----
ASM_OUT_LA_VAL  = 4       ; logical file 4 for output
ASM_DS_LA       = 15      ; logical file for the drive's error channel

; ============================================================================
; Include / source-stack state
; ----------------------------------------------------------------------------
; The assembler reads source through a stack of "frames". Frame 0 is the
; editor's in-memory gap buffer (the normal, no-include case). A .include
; directive pushes a FILE frame that streams the included file from disk one
; line at a time into LINE_BUF, so SRC_PTR always points at real RAM and the
; parser's rewind-on-lookahead (check_for_label) keeps working unchanged.
;
; Placed at fixed addresses high in MAIN ($BFxx). The code ends well below
; that and SYM_HASH (the link fails if it doesn't, see MODASM_CODE_END), so this free RAM is in the same always-visible bank ($01=$36) as the code —
; no banking concerns, and it doesn't touch the packed $C0xx state or the
; symbol table.
;
; Frame layout (SRC_FRAME_SIZE bytes each):
;   +0  KIND      0 = buffer (frame 0 only), 1 = file
;   +1  LFN       KERNAL logical file number (file frames)
;   +2  SRC_LO    saved SRC_PTR lo  (resume position)
;   +3  SRC_HI    saved SRC_PTR hi
;   +4  LINE_LO   saved ASM_LINE counter lo (per-file line numbers)
;   +5  LINE_HI   saved ASM_LINE counter hi
; ============================================================================
SRC_FRAME_SIZE  = 6
SRC_MAX_DEPTH   = 8       ; >=8 deep .include nesting -> ?INCLUDE TOO DEEP

SRC_DEPTH       = $BF00   ; current top frame index (0 = buffer only)
SRC_STACK       = $BF01   ; SRC_MAX_DEPTH * SRC_FRAME_SIZE = 48 bytes ($BF01..$BF30)

SRC_FRAME_KIND  = 0       ; field offsets within a frame
SRC_FRAME_LFN   = 1
SRC_FRAME_SLO   = 2
SRC_FRAME_SHI   = 3
SRC_FRAME_LLO   = 4
SRC_FRAME_LHI   = 5

SRC_KIND_BUFFER = 0
SRC_KIND_FILE   = 1
SRC_KIND_FEOF   = 2       ; file frame whose final line has been read.  The
                          ; last byte of a serial file arrives WITH the EOF
                          ; status (EOI), so EOF is known one fill early;
                          ; this latch makes the next fill_line_buf report
                          ; EOF without touching the bus again (re-reading a
                          ; drained channel would raise a timeout error).

LINE_BUF        = $BF40   ; one shared line buffer for the active file frame
LINE_BUF_MAX    = 80      ; 80 content bytes ($BF40..$BF8F); longer lines
                          ; truncate with LINE TOO LONG.  fill_line_buf
                          ; appends CR + NUL after the content, so the
                          ; buffer proper extends to $BF91.
LINE_BUF_END    = $BF31   ; lo byte of address past last content byte (hi=$BF always)
                          ; set by fill_line_buf (points at the CR terminator)
INC_LFN_BASE    = 5       ; LFN for depth-1 include; depth-N uses LFN (INC_LFN_BASE+N-1)

; Frame addresses never carry into the next page, so src_frame_ptr can
; leave the hi byte constant.
.assert >(SRC_STACK + SRC_MAX_DEPTH * SRC_FRAME_SIZE - 1) = >SRC_STACK, error, "modasm: SRC_STACK crosses a page"

; ---- Symbol-table hash index ----
; SYM_HASH[i] is an 8-bit hash of symbol i's name (sym_hash), written by
; sym_define next to SYM_TABLE entry i.  sym_lookup sweeps these bytes —
; one compare per symbol — and does the full 8-byte name compare only on
; a hash match, instead of walking every 10-byte entry.  The hash is a
; pure function of the 8 name bytes, so equal names always hash equal:
; the index only filters and can never hide a match.  Page-aligned so
; each 256 symbols are one (ptr),y sweep.  Like SRC_STACK it is free RAM
; above the module image (MODASM_CODE_END guards the overlap).
SYM_HASH        = $BD00   ; SYM_MAX bytes: $BD00..$BE8F
SYM_HCUR        = $BF32   ; hash of ASM_LABEL, set by sym_lookup
SYM_IDX         = $BF33   ; sym_lookup: sweep index saved around a candidate
SYM_T0          = $BF34   ; sym_entry_addr scratch (2 bytes)
.assert <SYM_HASH = 0, error, "modasm: SYM_HASH must be page-aligned"
.assert SYM_HASH + SYM_MAX <= SRC_DEPTH, error, "modasm: SYM_HASH overruns SRC_DEPTH"
.assert LINE_BUF_END < SYM_HCUR && SYM_T0 + 2 <= LINE_BUF, error, "modasm: symbol scratch overlaps the include state"

; ---- Per-line label state (the packed ASM_STATE block is full) ----
; ASM_LBL_FLAG is cleared at the start of every line.  Pass 1 sets it to
; $FF when the line defined a label, so that an origin directive on the
; same line ("start: *= $C000") moves the label to the new PC.  Pass 2
; sets it when the line's label does not match the PC (ASM_LBL_VAL = the
; label's pass-1 value); an origin on the line that lands on the label
; clears it again, and if it is still set at the end of the line the
; passes have diverged: PHASE ERROR.
ASM_LBL_FLAG    = $BF36
; @local label scope: the number of global (non-@) labels seen so far in
; this pass.  read_name stores a local "@name" as '@', SCOPE lo, SCOPE hi,
; then the first 5 name characters, so the same @name under different
; global labels is a different symbol.  Globals cannot start with '@', and
; two locals in different scopes differ in the SCOPE bytes: no collisions.
ASM_SCOPE_LO    = $BF37
ASM_SCOPE_HI    = $BF38
ASM_LBL_VAL     = $BF39             ; 2 bytes
.assert ASM_LBL_VAL + 2 <= LINE_BUF, error, "modasm: line state overlaps LINE_BUF"


; ============================================================================
; Module entry point
; ============================================================================

; PRG load address comes from the linker config (MAIN start) and must
; agree with layout.inc, which the module loader in modules.asm uses.
.import __MAIN_START__
.include "layout.inc"
.assert __MAIN_START__ = MOD_HI_BASE, lderror, "modasm: linker config load address disagrees with layout.inc MOD_HI_BASE"
.segment "LOADADDR"
    .word __MAIN_START__

.segment "CODE"

    jmp assemble            ; $A000: module entry (JMP convention)

; ============================================================================
; assemble  -  main entry point
; ============================================================================

assemble:
    ; Disable IRQ for the duration of assembly. This is a precaution, not a
    ; zero-page requirement: the C64 Kernal IRQ handler does not touch the
    ; module pool (see zp_c64.inc) — moddet/modtok run on the same pointer
    ; bytes with IRQs enabled.
    sei

    ; Ensure the memory map we need: Kernal+I/O in, RAM at $A000-$BFFF visible
    ; (C64: $01=$36, BASIC ROM out; C128: the session config in the MMU).
    ; Do this FIRST before touching any state  -  if caller failed to set banking,
    ; our code here would be unreadable (BASIC ROM at $A000). But since we're
    ; already executing (caller's JMP got us here), banking must be at least
    ; partially working. Belt-and-suspenders: force it explicitly.
.ifdef TARGET_C128
    lda #C128_CFG_SESSION
    sta C128_MMU_CR
.else
    ; Must set $00 first to make bits 0-2 outputs, then write $01.
    lda $00
    ora #$07
    sta $00
    lda #$36
    sta $01
.endif

    ; Save ZP
    zp_save ZP_SAVE

    ; Copy gap/buffer params
    lda MOD_GAP_START_LO
    sta ASM_GAP_S_LO
    lda MOD_GAP_START_HI
    sta ASM_GAP_S_HI
    lda MOD_GAP_END_LO
    sta ASM_GAP_E_LO
    lda MOD_GAP_END_HI
    sta ASM_GAP_E_HI
    lda MOD_BUF_LO
    sta ASM_BUF_LO
    lda MOD_BUF_HI
    sta ASM_BUF_HI
    lda MOD_BUF_END_LO
    sta ASM_END_LO
    lda MOD_BUF_END_HI
    sta ASM_END_HI

    ; Init state
    lda #0
    sta ASM_PC_LO
    sta ASM_PC_HI
    sta ASM_SYM_LO
    sta ASM_SYM_HI
    sta ASM_LINE_LO
    sta ASM_LINE_HI
    sta ASM_ERR
    sta ASM_OUT_OPEN
    sta ASM_FNAME_LEN

    ; Default PC = $0801
    lda #$01
    sta ASM_PC_LO
    lda #$08
    sta ASM_PC_HI

    ; Default load address = $0801.  Pass 1 replaces it with the PC at
    ; the first output byte (mark_emit).
    lda #$01
    sta ASM_LOAD_LO
    lda #$08
    sta ASM_LOAD_HI

    ; Output filename: interactive prompt, or batch param area when invoked
    ; by the script runner (MODSCRH ASSEMBLE keyword - no keyboard available).
    lda MOD_COMMAND
    cmp #ASM_CMD_BATCH
    bne @name_interactive

    ; ---- Batch: filename was placed at ASM_BATCH_FNAME by the caller ----
    lda ASM_BATCH_FNAME_LEN
    beq @name_bad               ; empty name  -  refuse
    cmp #17
    bcs @name_bad               ; >16 chars won't fit ASM_FNAME
    sta ASM_FNAME_LEN
    tay
@name_copy:
    dey
    lda ASM_BATCH_FNAME,y
    sta ASM_FNAME,y
    cpy #0
    bne @name_copy
    jmp @name_done

@name_bad:
    lda #$01
    sta MOD_STATUS              ; report error to caller
    jmp @restore_zp

@name_interactive:
    ; Prompt for output filename  -  needs IRQ for keyboard scan (GETIN)
    cli
    jsr prompt_outfile          ; fills ASM_FNAME/ASM_FNAME_LEN; C=1 if cancelled
    sei
    bcc @name_done
    lda #$00                    ; cancelled  -  no change, nothing to report
    sta MOD_STATUS
    jmp @restore_zp
@name_done:

    ; ---- Pass 1: build symbol table ----
    lda #0
    sta ASM_PASS
    jsr run_pass

    ; Record where pass 1 ended for the pass-2 phase check below.
    lda ASM_PC_LO
    sta ASM_P1END_LO
    lda ASM_PC_HI
    sta ASM_P1END_HI

    ; ---- Pass 2: emit code ----
    ; Only if no errors in pass 1
    lda ASM_ERR
    bne @done_err

    lda #1
    sta ASM_PASS

    ; Reset PC for pass 2.  (open_output writes ASM_LOAD, set by pass 1.)
    lda #$01
    sta ASM_PC_LO
    lda #$08
    sta ASM_PC_HI
    lda #0
    sta ASM_LINE_LO
    sta ASM_LINE_HI

    ; Open output file  -  needs IRQ for serial bus
    cli
    jsr open_output
    sei
    bcc :+
    jmp @done_err               ; open failed  -  error already set
:

    jsr run_pass

    ; Phase check: both passes must end at the same PC, or the sizes the
    ; two passes assigned diverged somewhere and every byte after that
    ; point is misplaced in the output.  set_err keeps only the first
    ; error, so a real pass-2 error still takes precedence.
    lda ASM_PC_LO
    cmp ASM_P1END_LO
    bne @phase_err
    lda ASM_PC_HI
    cmp ASM_P1END_HI
    beq @phase_ok
@phase_err:
    jsr set_err_phase
@phase_ok:

    ; Close output file  -  needs IRQ for serial bus
    cli
    jsr close_output
    sei

    lda ASM_ERR
    bne @done_err

    ; Success
    lda #$00
    sta MOD_STATUS
    jmp @restore_zp

@done_err:
    ; Copy error info to params area for editor to display
    jsr copy_error_to_status
    lda #$01
    sta MOD_STATUS

@restore_zp:
    ; Restore spinner cell to default color before returning
    lda #SPIN_COLOR_A
    sta SPIN_CELL
    ; NOTE: Do NOT restore $01 here  -  we're still executing in $A000-$BFFF range.
    ; Restoring BASIC ROM ($01=$37) while executing here would immediately
    ; put BASIC ROM under the CPU, causing a JAM on the very next fetch.
    ; modules.asm restores $01=$37 after our RTS returns to it.
    zp_restore ZP_SAVE
    cli                         ; re-enable IRQ before returning
    rts

; ============================================================================
; run_pass  -  walk entire source buffer, parse and process each line.
; ============================================================================

run_pass:
    ; Reset SRC_PTR to start of buffer
    lda ASM_BUF_LO
    sta SRC_PTR
    lda ASM_BUF_HI
    sta SRC_PTR+1

    ; Init activity spinner (once per pass; two passes = two blink cycles)
    lda #0
    sta ASM_SPINNER
    lda #SPIN_COLOR_A
    sta ASM_SPIN_IDX
    sta SPIN_CELL               ; show initial color immediately

    ; Init source frame stack: depth=0, frame 0 = buffer kind.
    ; Frame 0 is never popped; the SRC/LINE fields are unused for it.
    ; This lays the groundwork for .include without changing behaviour.
    lda #0
    sta ASM_SCOPE_LO            ; @local scopes are numbered from 0 each pass
    sta ASM_SCOPE_HI
    sta ASM_EMITTED             ; no output byte placed yet
    sta SRC_DEPTH
    sta SRC_STACK + SRC_FRAME_LFN
    sta SRC_STACK + SRC_FRAME_SLO
    sta SRC_STACK + SRC_FRAME_SHI
    sta SRC_STACK + SRC_FRAME_LLO
    sta SRC_STACK + SRC_FRAME_LHI
    lda #SRC_KIND_BUFFER
    sta SRC_STACK + SRC_FRAME_KIND

@line_loop:
    ; Bounds check: done if SRC_PTR >= BUF_END (or GAP_START, skipping gap)
    jsr src_at_end
    bne @done_pass

    ; Secondary check: treat a NUL byte as end-of-source.
    ; The editor buffer tail past the last CR may be NUL-filled.
    ; src_at_end only checks the address bounds; without this, the line loop
    ; would spin forever on NUL bytes between the last CR and BUF_END.
    ; Only applies to the depth-0 editor buffer: a NUL inside an included
    ; file is just junk content — ending the pass on it would silently
    ; truncate the output.  parse_line treats a leading NUL as a blank
    ; line, and skip_to_next_line still consumes one file line per
    ; iteration, so the loop cannot spin.
    jsr src_peek
    bne :+
    lda SRC_DEPTH
    beq @done_pass
:

    ; Increment line counter
    inc ASM_LINE_LO
    bne :+
    inc ASM_LINE_HI
:

    ; Activity spinner: tick every 16 lines, toggle color cell
    inc ASM_SPINNER
    lda ASM_SPINNER
    and #$0F
    bne :+
    lda ASM_SPIN_IDX
    eor #(SPIN_COLOR_A ^ SPIN_COLOR_B)
    sta ASM_SPIN_IDX
    sta SPIN_CELL
:

    ; Save SRC_PTR before parse_line (not needed now, remove later)

    ; Parse and process one line
    jsr parse_line

    ; Advance SRC_PTR to next line (past CR)
    jsr skip_to_next_line

    jmp @line_loop

@done_pass:
    ; Safety net: if the loop ended with include frames still open (only
    ; possible via an abnormal exit), close them so their LFNs are free
    ; for the next pass.
    lda SRC_DEPTH
    beq @pass_done
    jsr pop_src_frame
    jmp @done_pass
@pass_done:
    rts

; ============================================================================
; parse_line  -  parse one source line at SRC_PTR.
; ============================================================================

parse_line:
    lda #0
    sta ASM_LBL_FLAG            ; no label on this line (yet)

    ; Skip leading spaces; blank and comment-only lines are done
    jsr at_eol
    bcs :+
    jmp @done
:
    ; A label, if any, comes first.  The statement after it (directive,
    ; "*=", mnemonic) goes through the same dispatch as an unlabelled one.
    jsr check_for_label         ; C=1 if label found, label in ASM_LABEL
    bcc @stmt

    ; Process label.  A global one opens a new @local scope (in both
    ; passes, so the scope numbers agree).
    lda ASM_LABEL
    cmp #'@'
    beq @local
    inc ASM_SCOPE_LO
    bne @local
    inc ASM_SCOPE_HI
@local:
    lda ASM_PASS
    bne @label_pass2
    ; Pass 1: add label to symbol table with current PC
    jsr sym_define
    bcc :+
    jmp @err_sym                ; symbol table full or duplicate
:   lda #$FF
    sta ASM_LBL_FLAG            ; an origin on this line re-points it
    bne @skip_label_def         ; (always)
@label_pass2:
    ; Pass 2: the label's pass-1 value must be the PC here (or, on an
    ; origin line, the new PC: set_org settles that).  Otherwise the two
    ; passes sized something differently and the output is misplaced.
    ; Checked per label because an .org re-synchronises the PC, which
    ; would hide the divergence from the end-of-pass check.
    jsr sym_lookup              ; TMP = the label's value
    bcc :+
    jmp @err_phase              ; (pass 1 defined every label)
:   lda TMP
    sta ASM_LBL_VAL
    lda TMP+1
    sta ASM_LBL_VAL+1
    jsr lbl_vs_pc
    beq @skip_label_def
    lda #$FF
    sta ASM_LBL_FLAG            ; mismatch, unless an origin fixes it
@skip_label_def:

    ; Label-only line?
    jsr at_eol
    bcs @stmt
    jmp @done

@stmt:
    jsr src_peek                ; A = first char of the statement

    ; Check for '*=' (origin set)
    cmp #'*'
    bne @not_star
    jsr src_advance
    jsr src_peek
    cmp #'='
    beq :+
    jmp @err_syntax
    :
    jsr src_advance
    jsr skip_spaces
    jsr parse_value             ; result in TMP/TMP+1
    bcc :+
    jmp @err_val
    :
    jsr at_eol                  ; nothing may follow but a comment
    bcc :+
    jmp @err_syntax
    :
    jsr set_org
    jmp @done

@not_star:
    ; Check for directive ('.')
    cmp #'.'
    bne @no_label
    jsr parse_directive
    jmp @done

@no_label:
    ; Parse mnemonic (3 uppercase chars)
    jsr parse_mnemonic          ; fills ASM_MNEM, C=1 on error
    bcs @err_mnem

    ; Look up in opcode table
    jsr lookup_mnemonic         ; C=1 = not found
    bcs @err_unknown

    ; Skip space between mnemonic and operand
    jsr skip_spaces

    ; Save opcode table pointer (TMP2) before parse_operand, which may
    ; call sym_lookup and corrupt TMP2.
    lda TMP2
    sta ASM_OPC_PTR_LO
    lda TMP2+1
    sta ASM_OPC_PTR_HI

    ; Parse operand → ASM_MODE, ASM_VAL_LO/HI
    jsr parse_operand           ; C=1 on error
    bcs @err_operand
    ; The operand must end the statement: "LDA #1 2" or "LDA (P),Y Z"
    ; is an error, not "LDA #1" / "LDA (P),Y" with the rest ignored.
    jsr at_eol
    bcs @err_trail

    ; Restore opcode table pointer after parse_operand may have clobbered TMP2
    lda ASM_OPC_PTR_LO
    sta TMP2
    lda ASM_OPC_PTR_HI
    sta TMP2+1

    ; Find opcode for this mnemonic+mode combination
    jsr find_opcode             ; C=1 = mode not valid for this mnemonic
    bcs @err_mode

    ; Compute instruction size
    lda ASM_MODE
    tax
    lda op_size_tab,x           ; operand bytes
    clc
    adc #1                      ; +1 for opcode
    sta ASM_INSTR_SIZE

    ; Pass 1: just advance PC
    lda ASM_PASS
    beq @pass1_advance

    ; Pass 2: emit opcode + operand
    jsr emit_instruction
    bcs @err_emit
    jmp @done

@pass1_advance:
    jsr mark_emit               ; may fix the load address
    lda ASM_INSTR_SIZE
    clc
    adc ASM_PC_LO
    sta ASM_PC_LO
    bcc @done
    inc ASM_PC_HI
    jmp @done

@err_trail:
@err_syntax:
    jsr set_err_syntax
    jmp @done
@err_val:
    jsr set_err_value
    jmp @done
@err_sym:
    jsr set_err_symbol
    jmp @done
@err_mnem:
    jsr set_err_mnemonic
    jmp @done
@err_unknown:
    jsr set_err_unknown
    jmp @done
@err_operand:
    jsr set_err_operand
    jmp @done
@err_mode:
    jsr set_err_mode
    jmp @done
@err_emit:
    jsr set_err_io
@done:
    ; Pass 2: a label that never matched its PC (see @label_pass2)
    lda ASM_PASS
    beq @rts
    bit ASM_LBL_FLAG
    bpl @rts
@err_phase:
    jmp set_err_phase
@rts:
    rts

; ============================================================================
; check_for_label  -  scan ahead to see if current token ends with ':'
; If yes: consume the label, store 8-char padded name in ASM_LABEL, C=1.
; If no: leave SRC_PTR unchanged, C=0.
; ============================================================================

check_for_label:
    ; Save SRC_PTR
    lda SRC_PTR
    sta TMP2
    lda SRC_PTR+1
    sta TMP2+1

    jsr read_name               ; Z=1: no name characters
    beq @no_label
    jsr src_peek
    cmp #':'
    bne @no_label
    jsr src_advance             ; consume ':'
    sec
    rts

@no_label:
    ; Restore SRC_PTR
    lda TMP2
    sta SRC_PTR
    lda TMP2+1
    sta SRC_PTR+1
    clc
    rts

; ============================================================================
; read_name  -  read a label name at SRC_PTR into ASM_LABEL: upcased,
; space-padded to 8 bytes, characters past the 8th consumed but ignored.
; Name characters are A-Z, a-z, 0-9 and _.  A leading '@' makes the name
; local to the current global label: it is stored as '@', ASM_SCOPE lo/hi,
; then up to 5 name characters (see ASM_SCOPE_LO).
; Returns X = number of name characters read (not counting '@'), with
; Z=1 if there were none.  Clobbers A, Y.  Does not touch TMP/TMP2.
; ============================================================================

read_name:
    ldy #7
    lda #' '
@pad:
    sta ASM_LABEL,y
    dey
    bpl @pad
    iny                         ; Y = 0: store index
    ldx #0                      ; X = name characters read
    jsr src_peek
    cmp #'@'
    bne @read
    sta ASM_LABEL+0
    lda ASM_SCOPE_LO
    sta ASM_LABEL+1
    lda ASM_SCOPE_HI
    sta ASM_LABEL+2
    ldy #3
    jsr src_advance             ; consume '@'
@read:
    jsr src_peek
    jsr is_alnum_or_under       ; C=1 if a name character
    bcc @done
    jsr upcase_a
    cpy #8
    bcs @skip                   ; past 8 bytes: keep scanning, don't store
    sta ASM_LABEL,y
    iny
@skip:
    jsr src_advance
    inx
    bne @read                   ; (a 256-char name just ends there)
@done:
    cpx #0
    rts

; ============================================================================
; parse_mnemonic  -  read 3 uppercase chars into ASM_MNEM. C=1 on error.
; ============================================================================

parse_mnemonic:
    ldy #0
@loop:
    jsr src_peek
    beq @err
    cmp #$0D
    beq @err
    cmp #' '
    beq @err
    ; Convert lowercase PETSCII (a-z = $61-$7A) to uppercase (A-Z = $41-$5A)
    cmp #$61
    bcc @not_lower
    cmp #$7B
    bcs @not_lower
    sec
    sbc #$20                    ; lowercase ? uppercase
@not_lower:
    ; Now accept A-Z only
    cmp #'A'
    bcc @err
    cmp #'Z'+1
    bcs @err
    sta ASM_MNEM,y
    jsr src_advance
    iny
    cpy #3
    bne @loop
    ; The mnemonic must end here: "STA1 $D020" is not "STA $01..."
    jmp at_delim                ; C=1 if a 4th character follows
@err:
    sec
    rts

; ============================================================================
; lookup_mnemonic  -  search opcode_table for ASM_MNEM match.
; On success: C=0, TMP2 = pointer to first mode/opcode pair in table entry.
; On failure: C=1.
; ============================================================================

lookup_mnemonic:
    lda #<opcode_table
    sta TMP2
    lda #>opcode_table
    sta TMP2+1

@entry:
    ; Read 3-char mnemonic from table
    ldy #0
    lda (TMP2),y
    beq @not_found              ; $00 = end of table
    cmp ASM_MNEM+0
    bne @next
    iny
    lda (TMP2),y
    cmp ASM_MNEM+1
    bne @next
    iny
    lda (TMP2),y
    cmp ASM_MNEM+2
    bne @next
    ; Match! Advance TMP2 past the 3-char name to first mode/opcode pair
    lda TMP2
    clc
    adc #3
    sta TMP2
    bcc :+
    inc TMP2+1
:
    clc
    rts

@next:
    ; Skip to next entry: advance past 3-char name, then scan for $FF terminator
    lda TMP2
    clc
    adc #3
    sta TMP2
    bcc :+
    inc TMP2+1
:
@scan_ff:
    ldy #0
    lda (TMP2),y
    cmp #$FF
    beq @skip_ff
    lda TMP2
    clc
    adc #2
    sta TMP2
    bcc @scan_ff
    inc TMP2+1
    jmp @scan_ff
@skip_ff:
    ; Advance past $FF
    inc TMP2
    bne @entry
    inc TMP2+1
    jmp @entry

@not_found:
    sec
    rts

; ============================================================================
; find_opcode  -  given ASM_MODE and TMP2 pointing to mode/opcode pairs,
; find matching opcode. C=0 on success (ASM_OPCODE set). C=1 on failure.
; Also handles ZP?ABS promotion if ZP mode not available.
; ============================================================================

find_opcode:
    ; TMP2 points to first mode/opcode pair of matched mnemonic entry
    ; Save TMP2 for potential retry
    lda TMP2
    sta TMP3
    lda TMP2+1
    sta TMP3+1

    ; First try: exact mode match
    jsr @scan_for_mode
    bcc @done

    ; If mode was ZP and not found, try ABS
    lda ASM_MODE
    cmp #MODE_ZP
    bne @try_zpx_abx
    lda #MODE_ABS
    sta ASM_MODE
    ; Restore TMP2
    lda TMP3
    sta TMP2
    lda TMP3+1
    sta TMP2+1
    jsr @scan_for_mode
    bcc @done
    ; ABS also not found - fall through to try REL
    lda #MODE_ZP      ; restore original mode for @no_promo check
    sta ASM_MODE
    jmp @no_promo

@try_zpx_abx:
    cmp #MODE_ZPX
    bne @try_zpy_aby
    lda #MODE_ABX
    sta ASM_MODE
    lda TMP3
    sta TMP2
    lda TMP3+1
    sta TMP2+1
    jsr @scan_for_mode
    bcc @done
    lda #MODE_ZPX
    sta ASM_MODE
    jmp @no_promo

@try_zpy_aby:
    cmp #MODE_ZPY
    bne @no_promo
    lda #MODE_ABY
    sta ASM_MODE
    lda TMP3
    sta TMP2
    lda TMP3+1
    sta TMP2+1
    jsr @scan_for_mode
    bcc @done
    lda #MODE_ZPY
    sta ASM_MODE
    ; fall through to @no_promo

@no_promo:
    ; If mode is ZP or ABS, also try REL (for branch instructions)
    lda ASM_MODE
    cmp #MODE_ZP
    beq @try_rel
    cmp #MODE_ABS
    bne @fail
@try_rel:
    lda #MODE_REL
    sta ASM_MODE
    lda TMP3
    sta TMP2
    lda TMP3+1
    sta TMP2+1
    jsr @scan_for_mode
    bcc @done
    ; Restore original mode for error message
    lda #MODE_ABS
    sta ASM_MODE
@fail:
    sec
@done:
    rts

@scan_for_mode:
    ldy #0
    lda (TMP2),y
    cmp #$FF
    beq @sfm_miss
    cmp ASM_MODE
    beq @sfm_hit
    ; Advance 2 bytes
    lda TMP2
    clc
    adc #2
    sta TMP2
    bcc @scan_for_mode
    inc TMP2+1
    jmp @scan_for_mode
@sfm_hit:
    iny
    lda (TMP2),y
    sta ASM_OPCODE
    clc
    rts
@sfm_miss:
    sec
    rts

; ============================================================================
; parse_operand  -  determine addressing mode and value from source.
; Sets ASM_MODE, ASM_VAL_LO, ASM_VAL_HI. C=1 on error.
; ============================================================================

parse_operand:
    ; Check for end of line ? IMP
    jsr at_eol                  ; C=0 at CR / NUL / ';'
    bcs :+
    jmp @imp
    :

    ; 'A' or 'a' alone ? ACC
    jsr upcase_a
    cmp #'A'
    bne @not_acc
    ; Look ahead: it's accumulator mode only if the char AFTER the 'A'
    ; ends the operand (space, CR, ';', or NUL).  Anything else means a
    ; label/value that merely starts with A ("LSR AVAL", "LDA ARG,X") —
    ; rewind and parse it as a value.  The rewind is safe: src_advance
    ; only increments SRC_PTR, and any gap warp already happened at the
    ; src_peek above, so restoring the saved pointer is exact.
    lda SRC_PTR
    sta ASM_MUL_LO              ; free scratch outside parse_decimal
    lda SRC_PTR+1
    sta ASM_MUL_HI
    jsr src_advance
    jsr src_peek
    beq @acc_ok                 ; NUL — end of source
    cmp #' '
    beq @acc_ok
    cmp #$0D
    beq @acc_ok
    cmp #';'
    beq @acc_ok
    ; Not a bare 'A': rewind to the 'A' and fall into the value paths
    ; ('#' and '(' checks fail on 'A', landing in the label/value parse).
    ; @not_acc expects A = upcased first operand char, so re-peek it.
    lda ASM_MUL_LO
    sta SRC_PTR
    lda ASM_MUL_HI
    sta SRC_PTR+1
    jsr src_peek
    jsr upcase_a
    jmp @not_acc
@acc_ok:
    lda #MODE_ACC
    sta ASM_MODE
    clc
    rts

@not_acc:
    ; '#' ? IMM
    cmp #'#'
    bne @not_imm
    jsr src_advance
    jsr parse_expr              ; C=1 on error
    bcc :+
    jmp @err
    :
    ; Force to 1 byte
    lda #MODE_IMM
    sta ASM_MODE
    clc
    rts

@not_imm:
    ; '(' ? IND, IZX, or IZY
    cmp #'('
    bne @not_ind
    jsr src_advance
    jsr parse_expr
    bcc :+
    jmp @err
    :
    jsr skip_spaces
    jsr src_peek
    cmp #','
    bne @not_izx
    ; (val,X) ? IZX
    jsr src_advance             ; consume ','
    jsr src_peek
    jsr upcase_a
    cmp #'X'
    beq :+
    jmp @err
    :
    jsr src_advance             ; consume 'X'
    jsr src_peek
    cmp #')'
    beq :+
    jmp @err
    :
    jsr src_advance             ; consume ')'
    lda #MODE_IZX
    sta ASM_MODE
    clc
    rts
@not_izx:
    ; (val) or (val),Y
    cmp #')'
    beq :+
    jmp @err
    :
    jsr src_advance             ; consume ')'
    jsr src_peek
    cmp #','
    bne @ind_abs
    ; (val),Y ? IZY
    jsr src_advance             ; consume ','
    jsr src_peek
    jsr upcase_a
    cmp #'Y'
    bne @err
    jsr src_advance             ; consume 'Y'
    lda #MODE_IZY
    sta ASM_MODE
    clc
    rts
@ind_abs:
    ; (val) ? IND (absolute indirect, JMP only)
    lda #MODE_IND
    sta ASM_MODE
    clc
    rts

@not_ind:
    ; Otherwise: value [,X] [,Y]
    jsr parse_expr
    bcs @err
    jsr skip_spaces
    jsr src_peek
    cmp #','
    bne @no_index
    jsr src_advance             ; consume ','
    jsr src_peek
    jsr upcase_a
    cmp #'X'
    bne @try_y
    jsr src_advance             ; consume 'X'
    ; ZPX or ABX based on value size
    lda ASM_VAL_HI
    bne @abx
    lda #MODE_ZPX
    sta ASM_MODE
    clc
    rts
@abx:
    lda #MODE_ABX
    sta ASM_MODE
    clc
    rts
@try_y:
    jsr upcase_a
    cmp #'Y'
    bne @err
    jsr src_advance             ; consume 'Y'
    lda ASM_VAL_HI
    bne @aby
    lda #MODE_ZPY
    sta ASM_MODE
    clc
    rts
@aby:
    lda #MODE_ABY
    sta ASM_MODE
    clc
    rts

@no_index:
    ; ZP or ABS based on value size
    lda ASM_VAL_HI
    bne @abs_mode
    lda #MODE_ZP
    sta ASM_MODE
    clc
    rts
@abs_mode:
    lda #MODE_ABS
    sta ASM_MODE
    clc
    rts

@imp:
    lda #MODE_IMP
    sta ASM_MODE
    clc
    rts
@err:
    sec
    rts

; ============================================================================
; parse_expr  -  parse a value expression.
; CONTRACT: on success the result is ALWAYS in BOTH TMP/TMP+1 and
; ASM_VAL_LO/HI — every path.  Directives (.byte/.word/.org/*=) consume
; TMP via parse_value; instruction operands consume ASM_VAL.  The two must
; never diverge, or ".byte >label" and ".word label+2" silently emit the
; wrong bytes while instructions look fine.
; Supports: $hex, decimal, label, each optionally followed by +N / -N
; offsets (spaces around the operator allowed), and <sum, >sum, <(sum),
; >(sum) for the lo / hi byte of the whole sum.  C=1 on error.
; ============================================================================

parse_expr:
    jsr src_peek

    ; '<' / '>': lo / hi byte of the WHOLE following sum, "<table+10"
    ; meaning <(table+10).  Parentheses are allowed: "<(table+10)".
    cmp #'<'
    beq @lohi
    cmp #'>'
    bne @plain
@lohi:
    pha                         ; remember which operator
    jsr src_advance
    jsr src_peek
    cmp #'('
    bne @bare
    jsr src_advance             ; consume '('
    jsr skip_spaces
    jsr parse_sum               ; (skips spaces after the sum)
    bcs @err_pla
    cmp #')'                    ; A = next char, from parse_sum
    bne @err_pla
    jsr src_advance             ; consume ')'
    jmp @apply
@bare:
    jsr parse_sum
    bcs @err_pla
@apply:
    pla
    cmp #'<'
    beq @lo
    lda TMP+1                   ; '>': hi byte becomes the result
    sta TMP
@lo:
    lda #0
    sta TMP+1
    beq @store                  ; (always)

@plain:
    jsr parse_sum
    bcs @err
@store:
    lda TMP                     ; ASM_VAL = TMP (see contract above)
    sta ASM_VAL_LO
    lda TMP+1
    sta ASM_VAL_HI
    clc
    rts

@err_pla:
    pla
@err:
    sec
    rts

; parse_sum: base { [spaces] +|- [spaces] number } [spaces] -> TMP/TMP+1.
; Offsets are numeric literals; any number of them may follow the base.
; Returns with the spaces after the sum skipped and A = the next char.
; C=1 on error.
parse_sum:
    jsr parse_expr_base
    bcs @done
@loop:
    jsr skip_spaces             ; A = next char
    cmp #'+'
    beq @op
    cmp #'-'
    bne @ok
@op:
    pha                         ; remember the operator
    jsr src_advance
    jsr skip_spaces
    ; Save the running value.  parse_number/parse_decimal must NOT touch
    ; TMP2 — parse_decimal uses ASM_MUL for its x10 scratch for exactly
    ; this reason.
    lda TMP
    sta TMP2
    lda TMP+1
    sta TMP2+1
    jsr parse_number            ; literal offset -> TMP/TMP+1
    pla                         ; (PLA leaves C alone)
    bcs @done
    cmp #'-'
    beq @sub                    ; C=1 from the equal compare
    clc
    lda TMP2
    adc TMP
    sta TMP
    lda TMP2+1
    adc TMP+1
    sta TMP+1
    jmp @loop
@sub:
    lda TMP2
    sbc TMP
    sta TMP
    lda TMP2+1
    sbc TMP+1
    sta TMP+1
    jmp @loop
@ok:
    clc
@done:
    rts

; parse_expr_base: $hex, decimal, or label ? TMP/TMP+1
parse_expr_base:
    jsr src_peek
    cmp #'$'
    beq @hex
    ; Is it a digit? ? decimal
    cmp #'0'
    bcc @label
    cmp #'9'+1
    bcs @label
    jsr parse_decimal
    rts
@hex:
    jsr src_advance
    jsr parse_hex
    rts
@label:
    jsr parse_label_ref         ; look up label in symbol table ? TMP/TMP+1
    rts

; ============================================================================
; parse_number  -  parse $hex or decimal literal ? TMP/TMP+1. C=1 on error.
; ============================================================================

parse_number:
    jsr src_peek
    cmp #'$'
    bne @dec
    jsr src_advance
    jmp parse_hex
@dec:
    jmp parse_decimal

; ============================================================================
; parse_hex  -  parse hex digits at SRC_PTR ? TMP/TMP+1. C=1 if no digits.
; ============================================================================

parse_hex:
    lda #0
    sta TMP
    sta TMP+1
    ldx #0                      ; digit count
@loop:
    jsr src_peek
    jsr hex_digit               ; C=1 if not hex digit, A=nibble value if valid
    bcs @done_hex
    ; Shift TMP left 4
    asl TMP
    rol TMP+1
    asl TMP
    rol TMP+1
    asl TMP
    rol TMP+1
    asl TMP
    rol TMP+1
    ora TMP
    sta TMP
    jsr src_advance
    inx
    jmp @loop
@done_hex:
    cpx #0
    beq @err                    ; no digits at all
    clc
    rts
@err:
    sec
    rts

; hex_digit: A=char ? C=1 if not hex, C=0 and A=nibble if hex
hex_digit:
    cmp #'0'
    bcc @not_hex
    cmp #'9'+1
    bcs @try_af
    sec
    sbc #'0'
    clc
    rts
@try_af:
    cmp #'A'
    bcc @not_hex
    cmp #'F'+1
    bcs @not_hex
    sec
    sbc #'A'-10
    clc
    rts
@not_hex:
    sec
    rts

; ============================================================================
; parse_decimal  -  parse decimal digits ? TMP/TMP+1. C=1 if no digits.
; ============================================================================

parse_decimal:
    lda #0
    sta TMP
    sta TMP+1
    ldx #0
@loop:
    jsr src_peek
    cmp #'0'
    bcc @done
    cmp #'9'+1
    bcs @done
    sec
    sbc #'0'
    pha
    ; TMP = TMP*10 = TMP*8 + TMP*2, via 16-bit in-memory shifts.
    ; Each doubling must be a paired "asl TMP / rol TMP+1" so the carry
    ; propagates between the bytes.  (The old code shifted the lo byte
    ; three times in A, which kept only the LAST shift's carry — any
    ; value >= ~1024 parsed to garbage: ".word 53280" miscompiled.)
    ; Scratch is ASM_MUL, NOT TMP2: parse_expr keeps the base of a
    ; "label+N" expression in TMP2 across this routine.
    asl TMP
    rol TMP+1                   ; TMP*2
    lda TMP
    sta ASM_MUL_LO
    lda TMP+1
    sta ASM_MUL_HI              ; save TMP*2 for the sum
    asl TMP
    rol TMP+1                   ; TMP*4
    asl TMP
    rol TMP+1                   ; TMP*8
    lda TMP
    clc
    adc ASM_MUL_LO
    sta TMP
    lda TMP+1
    adc ASM_MUL_HI
    sta TMP+1                   ; TMP*10
    pla                         ; digit
    clc
    adc TMP
    sta TMP
    bcc :+
    inc TMP+1
:
    jsr src_advance
    inx
    jmp @loop
@done:
    cpx #0
    beq @err
    clc
    rts
@err:
    sec
    rts

; ============================================================================
; parse_label_ref  -  read label name, look up in symbol table ? TMP/TMP+1.
; Pass 1: if not found, use 0 (forward reference OK in pass 1).
; Pass 2: if not found, error.
; ============================================================================

parse_label_ref:
    jsr read_name               ; name (or scoped @local) into ASM_LABEL
    beq @err                    ; empty label

    ; Search symbol table
    jsr sym_lookup              ; C=0: found, TMP/TMP+1=value. C=1: not found.
    bcc @found
    ; Not found
    lda ASM_PASS
    bne @err                    ; pass 2: error
    ; Pass 1: forward reference. Return a placeholder with NON-ZERO hi byte so
    ; that parse_operand sizes the instruction as ABS/ABX/ABY (3 bytes) rather
    ; than ZP/ZPX/ZPY (2 bytes).  Pass 2 resolves the real value, so the lo/hi
    ; placeholder here is only used for mode selection during pass-1 sizing.
    ; Without this, a forward ref to a non-ZP address (e.g. MSG = $0825) sizes
    ; as 2 bytes in pass 1 but emits 3 bytes in pass 2, shifting all later
    ; label addresses by 1.
    lda #$00
    sta TMP
    lda #$FF
    sta TMP+1
    clc
    rts
@found:
    clc
    rts
@err:
    sec
    rts

; ============================================================================
; parse_directive  -  handle .org, .byte, .word, .text
; ============================================================================

parse_directive:
    jsr src_advance             ; consume '.'

    ; Read the directive name's letters (first 4 kept) into ASM_MNEM,
    ; normalized to uppercase and zero-padded, so a short name can't
    ; match on stale bytes of an earlier one.
    ldy #3
    lda #0
@clr:
    sta ASM_MNEM,y
    dey
    bpl @clr
    iny                         ; Y = 0
@rd:
    jsr src_peek
    jsr upcase_a
    cmp #'A'
    bcc @rd_done
    cmp #'Z'+1
    bcs @rd_done
    cpy #4
    bcs @rd_skip
    sta ASM_MNEM,y
@rd_skip:
    jsr src_advance
    iny
    bne @rd                     ; (a 256-letter name just ends there)
@rd_done:
    ; The name must end at a space or the end of the statement.
    jsr at_delim
    bcc :+
    jmp @err
:
    jsr skip_spaces

    ; Compare against known directives
    ; .org
    lda ASM_MNEM+0
    cmp #'O'
    bne @try_byte
    lda ASM_MNEM+1
    cmp #'R'
    bne @try_byte
    lda ASM_MNEM+2
    cmp #'G'
    bne @try_byte
    jsr parse_value
    bcc :+
    jmp @err
    :
    jsr at_eol                  ; nothing may follow but a comment
    bcc :+
    jmp @err
    :
    jmp set_org

@try_byte:
    lda ASM_MNEM+0
    cmp #'B'
    bne @try_word
    lda ASM_MNEM+1
    cmp #'Y'
    bne @try_word
    lda ASM_MNEM+2
    cmp #'T'
    bne @try_word
    ; .byte: comma-separated values
@byte_loop:
    jsr parse_value
    bcc :+
    jmp @err
    :
    lda TMP
    jsr emit_byte               ; (pass 1: only notes the position)
    bcc :+
    jmp @io
:
    ; Always advance PC by 1, in BOTH passes.
    ; Previously pass 2 skipped this, leaving ASM_PC stale for later branches.
    inc ASM_PC_LO
    bne @byte_next
    inc ASM_PC_HI
@byte_next:
    jsr skip_spaces
    cmp #','
    bne @values_done
    jsr src_advance
    jsr skip_spaces
    jmp @byte_loop

@try_word:
    lda ASM_MNEM+0
    cmp #'W'
    bne @try_text
    lda ASM_MNEM+1
    cmp #'O'
    bne @try_text
    lda ASM_MNEM+2
    cmp #'R'
    bne @try_text
    ; .word: comma-separated 16-bit values
@word_loop:
    jsr parse_value
    bcc :+
    jmp @err
    :
    lda TMP
    jsr emit_byte               ; (pass 1: only notes the position)
    bcc :+
    jmp @io
:   lda TMP+1
    jsr emit_byte
    bcc :+
    jmp @io
:
    ; Always advance PC by 2, in BOTH passes.
    lda ASM_PC_LO
    clc
    adc #2
    sta ASM_PC_LO
    bcc @word_next
    inc ASM_PC_HI
@word_next:
    jsr skip_spaces
    cmp #','
    bne @values_done
    jsr src_advance
    jsr skip_spaces
    jmp @word_loop

; End of a .byte / .word value list (or of a .text string): the statement
; must end here.  "1 2" is an error, not 1 with the "2" ignored.
@values_done:
    jsr at_eol
    bcc :+
    jmp @err
:   rts

@try_text:
    lda ASM_MNEM+0
    cmp #'T'
    bne @try_include
    lda ASM_MNEM+1
    cmp #'E'
    bne @try_include
    lda ASM_MNEM+2
    cmp #'X'
    bne @try_include
    ; .text "string": emit PETSCII bytes
    jsr src_peek
    cmp #'"'
    bne @dir_err_near
    jsr src_advance             ; consume opening '"'
@text_loop:
    jsr src_peek
    beq @dir_err_near
    cmp #$0D
    beq @dir_err_near
    cmp #'"'
    beq @text_done
    jsr emit_byte               ; (pass 1: only notes the position)
    bcc :+
    jmp @io
:
    ; Always advance both source and PC, in BOTH passes.
    jsr src_advance
    inc ASM_PC_LO
    bne @text_loop
    inc ASM_PC_HI
    jmp @text_loop
@text_done:
    jsr src_advance             ; consume closing '"'
    jmp @values_done

; Local trampoline: .text section error targets can't reach the bottom @err
@dir_err_near:
    jmp @err

@try_include:
    ; .include "filename"  -  dispatch key is first 4 chars = INCL
    lda ASM_MNEM+0
    cmp #'I'
    bne @inc_bad_dir
    lda ASM_MNEM+1
    cmp #'N'
    bne @inc_bad_dir
    lda ASM_MNEM+2
    cmp #'C'
    bne @inc_bad_dir
    lda ASM_MNEM+3
    cmp #'L'
    bne @inc_bad_dir

    ; Expect opening '"'
    jsr src_peek
    cmp #'"'
    bne @inc_bad_syn
    jsr src_advance             ; consume '"'

    ; Read filename into LINE_BUF (max 16 chars).
    ; LINE_BUF is safe scratch here: fill_line_buf overwrites it only
    ; AFTER SETNAM+OPEN have already consumed the pointer.
    ldx #0                      ; X = filename length
@inc_fname:
    jsr src_peek
    beq @inc_bad_syn            ; NUL = unterminated
    cmp #$0D
    beq @inc_bad_syn            ; CR  = unterminated
    cmp #'"'
    beq @inc_fname_done         ; closing quote
    cpx #16
    bcs @inc_bad_syn            ; filename > 16 chars = syntax error
    sta LINE_BUF,x
    jsr src_advance
    inx
    jmp @inc_fname
@inc_fname_done:
    jsr src_advance             ; consume closing '"'
    cpx #0
    beq @inc_bad_syn            ; empty filename = syntax error
    ; Only a comment may follow.  Checked before the file is opened:
    ; once SRC_DEPTH moves, src_peek no longer reads this line.
    jsr at_eol                  ; (preserves X = filename length)
    bcs @inc_bad_syn
    ; Depth check: frame 0 is the editor buffer, so the stack holds at
    ; most SRC_MAX_DEPTH-1 file frames.  The new frame goes at index
    ; SRC_DEPTH+1, which must stay below SRC_MAX_DEPTH.
    lda SRC_DEPTH
    cmp #SRC_MAX_DEPTH-1
    bcc @inc_push
    jsr set_err_deep
    rts
@inc_bad_dir:
    jmp @unknown_dir
@inc_bad_syn:
    jmp @err

@inc_push:
    ; Compute address of the NEW frame (at index SRC_DEPTH+1) into TMP2.
    ; SRC_DEPTH itself is incremented only after the file is open, so an
    ; OPEN failure leaves the stack untouched.
    lda SRC_DEPTH
    clc
    adc #1                      ; new frame index = current top + 1
    jsr src_frame_ptr           ; TMP2 = base of new frame (X preserved)

    ; Fill frame fields
    lda #SRC_KIND_FILE
    ldy #SRC_FRAME_KIND
    sta (TMP2),y

    ; LFN = INC_LFN_BASE + SRC_DEPTH  (depth 1 -> LFN 5, depth 2 -> LFN 6, ...)
    lda SRC_DEPTH
    clc
    adc #INC_LFN_BASE
    ldy #SRC_FRAME_LFN
    sta (TMP2),y                ; save LFN in frame
    sta TMP3                    ; keep LFN in TMP3 for SETLFS

    ; Save current SRC_PTR (resume position after .include line is done)
    lda SRC_PTR
    ldy #SRC_FRAME_SLO
    sta (TMP2),y
    lda SRC_PTR+1
    ldy #SRC_FRAME_SHI
    sta (TMP2),y

    ; Save current ASM_LINE (so error messages show correct line in parent)
    lda ASM_LINE_LO
    ldy #SRC_FRAME_LLO
    sta (TMP2),y
    lda ASM_LINE_HI
    ldy #SRC_FRAME_LHI
    sta (TMP2),y

    ; SETLFS: LFN=TMP3, device=MOD_DRIVE, SA=2 (sequential read)
    ; X holds filename length from parse loop — save it before SETLFS clobbers X
    stx TMP2                    ; TMP2 lo = filename length (hi not needed)
    lda TMP3                    ; LFN
    ldx MOD_DRIVE               ; device number
    ldy #2                      ; SA=2: read channel
    jsr SETLFS

    ; SETNAM: length from saved TMP2, addr=LINE_BUF
    lda TMP2                    ; filename length
    ldx #<LINE_BUF
    ldy #>LINE_BUF
    jsr SETNAM

    ; OPEN sends commands on the serial bus, which drops any active
    ; LISTEN — in pass 2 that is the output file's channel.  Release it
    ; cleanly first, re-select it after (resume_output).
    jsr CLRCHN

    ; OPEN the file
    jsr OPEN
    bcc @inc_opened
    ; OPEN failed (device not present, too many files, ...).  Release the
    ; LFN in case OPEN half-registered it, restore the output channel,
    ; and report.
    lda TMP3                    ; LFN (still intact — Kernal leaves ZP_SCRATCH alone)
    jsr CLOSE
    jsr resume_output
    jsr set_err_io
    rts

@inc_opened:
    ; Increment depth now that the frame is fully set up and file is open.
    ; The first line is NOT loaded here: run_pass unconditionally calls
    ; skip_to_next_line after this directive's line is parsed, and its
    ; file-frame path does the first fill_line_buf.  Filling here too
    ; would load line 1 and then immediately discard it.
    inc SRC_DEPTH

    ; Included file gets its own 1-based line numbers: run_pass increments
    ; ASM_LINE at the top of its loop, so 0 here makes the include's first
    ; line report as line 1.  (The parent's counter was saved in the frame.)
    lda #0
    sta ASM_LINE_LO
    sta ASM_LINE_HI

    jsr resume_output
    rts

@dir_unknown:
@dir_err:
@unknown_dir:
@err:
    jmp set_err_syntax
@io:
    jmp set_err_io

; ============================================================================
; set_org  -  ".org" / "*=": set the PC to TMP/TMP+1.
;
; The output file is one contiguous image starting at the load address
; (the PC of the first output byte, see mark_emit), so once a byte has
; been placed the PC may only move forward: pass 2 fills the gap with $00
; bytes so that everything after it loads where its labels say.  Moving
; back is ORG BACKWARDS (caught in pass 1, before any file is written).
; Before the first output byte an origin just moves the PC.
;
; A label defined on the same line ("start: *= $C000") names the new
; address: pass 1 just appended it to the symbol table, so its entry is
; the last one — re-point it here.  Pass 2 clears a phase mismatch flagged
; for such a label once the new PC matches (see parse_line).
; Errors are recorded here.
; ============================================================================

set_org:
    bit ASM_EMITTED
    bpl @move                   ; nothing placed yet: any address goes
    lda TMP
    sec
    sbc ASM_PC_LO
    sta TMP2
    lda TMP+1
    sbc ASM_PC_HI
    sta TMP2+1                  ; TMP2 = gap size
    bcc @back
    lda ASM_PASS
    beq @move                   ; pass 1: only the PC moves
@fill:
    lda TMP2
    ora TMP2+1
    beq @move
    lda #0
    jsr emit_raw
    bcs @io
    lda TMP2
    bne :+
    dec TMP2+1
:   dec TMP2
    jmp @fill

@move:
    lda TMP
    sta ASM_PC_LO
    lda TMP+1
    sta ASM_PC_HI
    bit ASM_LBL_FLAG
    bpl @done
    lda ASM_PASS
    bne @pass2
    lda ASM_SYM_LO
    sec
    sbc #1
    sta TMP2
    lda ASM_SYM_HI
    sbc #0
    sta TMP2+1                  ; TMP2 = index of the last symbol
    jsr sym_entry_addr
    ldy #8                      ; value field
    lda ASM_PC_LO
    sta (TMP2),y
    iny
    lda ASM_PC_HI
    sta (TMP2),y
@done:
    rts
@pass2:
    jsr lbl_vs_pc
    bne @done
    lda #0
    sta ASM_LBL_FLAG            ; the label is the new PC: in phase
    rts
@back:
    jmp set_err_org
@io:
    jmp set_err_io

; lbl_vs_pc  -  Z=1 if ASM_LBL_VAL equals the PC.  Clobbers A.
lbl_vs_pc:
    lda ASM_LBL_VAL
    cmp ASM_PC_LO
    bne :+
    lda ASM_LBL_VAL+1
    cmp ASM_PC_HI
:   rts

; ============================================================================
; parse_value  -  wrapper: parse_expr into TMP/TMP+1
; ============================================================================

parse_value:
    jmp parse_expr

; ============================================================================
; emit_instruction  -  pass 2: write opcode + operand bytes to output file.
; ============================================================================

emit_instruction:
    lda ASM_OPCODE
    jsr emit_byte
    bcs @err

    lda ASM_MODE
    tax
    lda op_size_tab,x
    beq @done                   ; IMP/ACC: no operand bytes

    cmp #1
    bne @two_bytes

    ; 1 operand byte
    lda ASM_MODE
    cmp #MODE_REL
    bne @emit_lo

    ; FIX (branch offset): compute signed relative offset as a proper 16-bit
    ; subtraction: offset = target - (PC + 2).
    ; PC still points to the branch opcode (not yet advanced).
    ; The hi byte of the result must be $00 (forward) or $FF (backward), and
    ; the lo byte's sign must agree with it: $00xx needs bit 7 of xx clear
    ; (offset 0..+127), $FFxx needs it set (offset -128..-1).  Checking the
    ; hi byte alone accepted +128..+255 and -129..-256 and emitted an offset
    ; that branched to the wrong place.
    ;
    ; Compute PC+2 into TMP2
    lda ASM_PC_LO
    clc
    adc #2
    sta TMP2
    lda ASM_PC_HI
    adc #0
    sta TMP2+1
    ; 16-bit: target - (PC+2)
    lda ASM_VAL_LO
    sec
    sbc TMP2
    sta TMP                     ; lo byte = branch offset to emit
    lda ASM_VAL_HI
    sbc TMP2+1                  ; hi byte: $00=forward, $FF=backward
    beq @rel_fwd
    cmp #$FF
    bne @rel_range_err
    lda TMP                     ; backward: lo must be $80..$FF
    bpl @rel_range_err          ; $FF00..$FF7F = -256..-129
    bmi @rel_ok
@rel_fwd:
    lda TMP                     ; forward: lo must be $00..$7F
    bmi @rel_range_err          ; $0080..$00FF = +128..+255
@rel_ok:
    jsr emit_byte               ; A = offset lo byte
    bcs @err
    jmp @done

@rel_range_err:
    jsr set_err_range           ; branch target out of -128..+127 range
    jmp @done

@emit_lo:
    lda ASM_VAL_LO
    jsr emit_byte
    bcs @err
    jmp @done

@two_bytes:
    lda ASM_VAL_LO
    jsr emit_byte
    bcs @err
    lda ASM_VAL_HI
    jsr emit_byte
    bcs @err

@done:
    ; Advance PC by instruction size
    lda ASM_INSTR_SIZE
    clc
    adc ASM_PC_LO
    sta ASM_PC_LO
    bcc :+
    inc ASM_PC_HI
:
    clc
    rts
@err:
    sec
    rts

; emit_byte  -  place the output byte A at the PC, in either pass.
; Pass 1 only notes the position (mark_emit); pass 2 also writes it.
; C=1 on an output error.  Clobbers A.
emit_byte:
    pha
    jsr mark_emit
    lda ASM_PASS
    bne @write
    pla
    clc
    rts
@write:
    pla
    ; fall through
; emit_raw  -  pass 2: write A to the output file.  C=1 on an I/O error.
emit_raw:
    jsr CHROUT
    jsr READST
    and #$83                    ; device not present, or a timeout
    beq :+
    sec
    rts
:   clc
    rts

; mark_emit  -  an output byte is about to be placed at the PC.  The
; first one in pass 1 fixes the PRG load address: the file image starts
; there, so code before a leading .org loads where its labels say.
; Clobbers A.
mark_emit:
    bit ASM_EMITTED
    bmi @done
    lda #$FF
    sta ASM_EMITTED
    lda ASM_PASS
    bne @done
    lda ASM_PC_LO
    sta ASM_LOAD_LO
    lda ASM_PC_HI
    sta ASM_LOAD_HI
@done:
    rts

; ============================================================================
; Symbol table routines
; ============================================================================

; sym_define  -  add ASM_LABEL with current PC value to symbol table.
; C=1 if table full or duplicate.
sym_define:
    ; Check for duplicate (only warn  -  allow redefinition in pass 1 context)
    jsr sym_lookup              ; also leaves ASM_LABEL's hash in SYM_HCUR
    bcs @not_dup                ; not found  -  good
    ; Duplicate: set error and return
    sec
    rts
@not_dup:

    ; Check table full
    lda ASM_SYM_LO
    cmp #<SYM_MAX
    lda ASM_SYM_HI
    sbc #>SYM_MAX
    bcs @full

    ; TMP2 = entry address = SYM_TABLE + count * 10
    lda ASM_SYM_LO
    sta TMP2
    lda ASM_SYM_HI
    sta TMP2+1
    jsr sym_entry_addr

    ; Write 8-char name
    ldy #0
@name:
    lda ASM_LABEL,y
    sta (TMP2),y
    iny
    cpy #8
    bne @name

    ; Write 2-byte value (current PC)
    lda ASM_PC_LO
    sta (TMP2),y
    iny
    lda ASM_PC_HI
    sta (TMP2),y

    ; Index the name's hash: SYM_HASH[count] = SYM_HCUR
    lda ASM_SYM_LO
    sta TMP3                    ; SYM_HASH is page-aligned: lo = count lo
    lda ASM_SYM_HI
    clc
    adc #>SYM_HASH
    sta TMP3+1
    ldy #0
    lda SYM_HCUR
    sta (TMP3),y

    ; Increment symbol count
    inc ASM_SYM_LO
    bne :+
    inc ASM_SYM_HI
:
    clc
    rts
@full:
    sec
    rts

; sym_lookup  -  search for ASM_LABEL in symbol table.
; C=0: found, TMP/TMP+1 = value. C=1: not found.
; Either way SYM_HCUR = hash of ASM_LABEL (sym_define stores it).
; Clobbers A, Y, TMP2, TMP3; preserves X.
;
; Sweeps the SYM_HASH bytes (14 cycles per symbol), one 256-symbol page at
; a time, from the page's last symbol down.  Only a hash match costs a
; full name compare.  Names in the table are unique (sym_define rejects
; duplicates, pass 2 defines nothing), so the sweep order does not matter.
sym_lookup:
    jsr sym_hash                ; SYM_HCUR = hash (clobbers Y)
    lda #<SYM_HASH
    sta TMP3
    lda #>SYM_HASH
    sta TMP3+1                  ; TMP3 = hash bytes of page 0 (symbols 0..255)
@page:
    ; Y = number of symbols in this page (0 = a full 256)
    lda TMP3+1
    sec
    sbc #>SYM_HASH              ; A = page number (symbol index hi)
    cmp ASM_SYM_HI
    bcs @last_page
    ldy #0                      ; below the last page: all 256 symbols
    beq @sweep                  ; (always)
@last_page:
    ldy ASM_SYM_LO              ; the last page holds count lo symbols
    beq @not_found
@sweep:
    lda SYM_HCUR
@scan:
    dey
    cmp (TMP3),y
    beq @cand
@resume:
    cpy #0
    bne @scan
    ; Page done: move on unless it was the last one.
    lda TMP3+1
    sec
    sbc #>SYM_HASH
    cmp ASM_SYM_HI
    bcs @not_found
    inc TMP3+1
    bne @page                   ; (always)

@cand:
    ; Hash match on symbol (page, Y): compare the full 8-char name.
    sty SYM_IDX
    sty TMP2
    lda TMP3+1
    sec
    sbc #>SYM_HASH
    sta TMP2+1                  ; TMP2 = symbol index
    jsr sym_entry_addr          ; TMP2 = its SYM_TABLE entry
    ldy #0
@cmp:
    lda (TMP2),y
    cmp ASM_LABEL,y
    bne @miss
    iny
    cpy #8
    bne @cmp
    ; Match  -  read value
    lda (TMP2),y                ; y=8 = value lo
    sta TMP
    iny
    lda (TMP2),y                ; y=9 = value hi
    sta TMP+1
    clc
    rts

@miss:
    ldy SYM_IDX                 ; resume the sweep below this symbol
    lda SYM_HCUR
    jmp @resume

@not_found:
    sec
    rts

; sym_hash  -  A = SYM_HCUR = 8-bit hash of the 8 bytes of ASM_LABEL:
; h = h*5 + c over the bytes from last to first.  (Of the cheap 6502
; mixes tried, this one spread both random names and L0001-style
; numbered names well.)  Clobbers Y; preserves X.
sym_hash:
    lda #0
    ldy #7
@loop:
    sta SYM_HCUR
    asl
    asl
    clc
    adc SYM_HCUR                ; h*5
    clc
    adc ASM_LABEL,y             ; + c
    dey
    bpl @loop
    sta SYM_HCUR
    rts

; sym_entry_addr  -  TMP2 = SYM_TABLE + TMP2 * SYM_ENTRY_SIZE (10).
; Clobbers A and SYM_T0; preserves X and Y.
sym_entry_addr:
    lda TMP2
    sta SYM_T0
    lda TMP2+1
    sta SYM_T0+1
    asl TMP2
    rol TMP2+1                  ; *2
    asl TMP2
    rol TMP2+1                  ; *4
    lda TMP2
    clc
    adc SYM_T0
    sta TMP2
    lda TMP2+1
    adc SYM_T0+1
    sta TMP2+1                  ; *5
    asl TMP2
    rol TMP2+1                  ; *10
    lda TMP2
    clc
    adc #<SYM_TABLE
    sta TMP2
    lda TMP2+1
    adc #>SYM_TABLE
    sta TMP2+1
    rts

; ============================================================================
; Source pointer routines (gap-aware)
; ============================================================================

; src_peek  -  A = byte at SRC_PTR, skipping gap. 0 if at end.
; Frame-aware: depth 0 reads the editor gap buffer (original logic below);
; depth >0 means the top frame is an include file whose current line sits
; in LINE_BUF, so no gap or bounds logic applies — just return the byte.
; fill_line_buf terminates every line with CR + NUL, so a scan can never
; run past the line into garbage: the NUL reads as end-of-source, exactly
; like the buffer path's end check.
src_peek:
    lda SRC_DEPTH
    bne @file_peek
    ; Preserves Y via stack  -  callers (check_for_label, parse_label_ref) use Y as index.
    ; If SRC_PTR is in gap: jump to GAP_END
    lda SRC_PTR+1
    cmp ASM_GAP_S_HI
    bne @check_end
    lda SRC_PTR
    cmp ASM_GAP_S_LO
    bne @check_end
    ; At gap start: update SRC_PTR to gap end
    lda ASM_GAP_E_LO
    sta SRC_PTR
    lda ASM_GAP_E_HI
    sta SRC_PTR+1

@check_end:
    ; If SRC_PTR >= BUF_END: return 0
    lda SRC_PTR
    cmp ASM_END_LO
    lda SRC_PTR+1
    sbc ASM_END_HI
    bcs @at_end
    sty ASM_YPEEK               ; save Y (dedicated scratch, never shared)
    ldy #0
    buf_lda SRC_PTR
    ldy ASM_YPEEK               ; restore Y — NOTE: this clobbers Z flag!
    ora #0                      ; re-assert Z based on A (Z=1 iff A=0)
    rts
@at_end:
    lda #0
    rts

@file_peek:
    sty ASM_YPEEK               ; same Y-preservation contract as above
    ldy #0
    lda (SRC_PTR),y             ; LINE_BUF is module RAM, not the buffer: native on every target
    ldy ASM_YPEEK
    ora #0                      ; re-assert Z based on A
    rts

; src_advance  -  advance SRC_PTR by 1
src_advance:
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   rts

; src_at_end  -  returns A=$FF if current source frame is exhausted, else A=0.
; Frame-aware: checks SRC_DEPTH and current frame KIND.
;   KIND=BUFFER (frame 0): gap-buffer end check (original logic).
;   KIND=FILE: LINE_BUF end check (step 2+; placeholder for now).
src_at_end:
    lda SRC_DEPTH
    beq @buf_frame               ; depth=0 is always the buffer frame (fast path)
    jsr src_frame_ptr            ; TMP2 = base of current top frame
    ; Read KIND field (FILE or FEOF — both are file frames)
    ldy #SRC_FRAME_KIND
    lda (TMP2),y
    cmp #SRC_KIND_FILE
    bcs @file_frame

@buf_frame:
    ; Original gap-buffer end logic (inline, no JSR overhead):
    ; First: if SRC_PTR == gap_s, jump to gap_e
    lda SRC_PTR+1
    cmp ASM_GAP_S_HI
    bne :+
    lda SRC_PTR
    cmp ASM_GAP_S_LO
    bne :+
    lda ASM_GAP_E_LO
    sta SRC_PTR
    lda ASM_GAP_E_HI
    sta SRC_PTR+1
:
    ; 16-bit: if SRC_PTR >= ASM_END → at end
    lda SRC_PTR+1
    cmp ASM_END_HI
    bcc @not_end
    bne @at_end
    lda SRC_PTR
    cmp ASM_END_LO
    bcc @not_end
@at_end:
    lda #$FF
    rts
@not_end:
    lda #0
    rts

@file_frame:
    ; A file frame always has a parsed-or-parseable line in LINE_BUF:
    ; EOF is detected in skip_to_next_line, which pops the frame before
    ; control returns to run_pass.  So a file frame is never "at end".
    lda #0
    rts

skip_spaces:
@loop:
    jsr src_peek
    cmp #' '
    bne @done
    jsr src_advance
    jmp @loop
@done:
    rts

; at_delim  -  C=0 if the char at SRC_PTR ends a word (a space, or the
; end of the statement as at_eol defines it), else C=1.  A = that char.
at_delim:
    jsr src_peek
    cmp #' '
    bne at_eol                  ; not a space: at_eol has none to skip
    clc
    rts

; at_eol  -  skip spaces, then C=0 if the statement has ended (CR, NUL =
; end of source, or a ';' comment), C=1 if anything else follows.
; A = that next character either way.
at_eol:
    jsr skip_spaces
    cmp #$0D
    beq @eol
    cmp #';'
    beq @eol
    cmp #1                      ; NUL: C=0; any other char: C=1
    rts
@eol:
    clc
    rts

; skip_to_next_line  -  advance SRC_PTR past the current line's CR.
; Frame-aware: KIND=BUFFER uses gap-buffer scan (original logic).
;              KIND=FILE uses LINE_BUF (step 2+; placeholder for now).
skip_to_next_line:
    ; Fast path: depth=0 is always the buffer frame.
    lda SRC_DEPTH
    beq @buf_skip
    jsr src_frame_ptr           ; TMP2 = base of current top frame
    ldy #SRC_FRAME_KIND
    lda (TMP2),y
    cmp #SRC_KIND_FILE
    bcs @file_skip              ; FILE or FEOF

@buf_skip:
    ; Original scan-for-CR logic:
@loop:
    jsr src_peek
    beq @done
    cmp #$0D
    beq @found_cr
    jsr src_advance
    jmp @loop
@found_cr:
    jsr src_advance             ; consume CR
@done:
    rts

@file_skip:
    ; A line from an included file was just parsed.  Load the next one.
    ; If the file is exhausted, close it, pop the frame, and finish
    ; skipping the parent's .include line:
    ;   - a FILE parent's copy of that line in the shared LINE_BUF was
    ;     overwritten by the child's lines, so "skip" there means loading
    ;     the parent's next line from disk — and popping again if THAT
    ;     hits EOF (the .include was the parent's last line), hence the
    ;     loop back to @file_skip;
    ;   - the depth-0 buffer parent's line is intact in the editor
    ;     buffer, so scan past its CR like any other line.
    jsr fill_line_buf           ; C=0: line ready, SRC_PTR = LINE_BUF
    bcc @file_done              ; C=1: EOF
    jsr pop_src_frame           ; close file, restore parent SRC_PTR/line
    lda SRC_DEPTH
    bne @file_skip              ; parent is a file frame: fetch its next line
    jmp @buf_skip               ; parent is the editor buffer: normal CR scan
@file_done:
    rts

; upcase_a: if A is lowercase PETSCII (a-z), convert to uppercase. Preserves flags except N/Z.
upcase_a:
    cmp #$61
    bcc @done
    cmp #$7B
    bcs @done
    sec
    sbc #$20
@done:
    rts

; is_alnum_or_under: A=char ? C=1 if A-Z, a-z, 0-9, or _. Does NOT modify A.
is_alnum_or_under:
    cmp #'A'
    bcc @try_lower
    cmp #'Z'+1
    bcc @yes
@try_lower:
    cmp #$61                    ; 'a' in PETSCII
    bcc @try_digit
    cmp #$7B                    ; 'z'+1
    bcc @yes
@try_digit:
    cmp #'0'
    bcc @try_under
    cmp #'9'+1
    bcc @yes
@try_under:
    cmp #'_'
    beq @yes
    clc
    rts
@yes:
    sec
    rts

; ============================================================================
; Output file routines
; ============================================================================

open_output:
    lda ASM_FNAME_LEN
    beq @err                    ; no filename

    lda #ASM_OUT_LA_VAL
    ldx MOD_DRIVE
    ldy #1                      ; SA=1 = write
    jsr SETLFS

    ; Open as "@0:<name>" so re-assembling replaces the old file; a bare
    ; name fails with 63 FILE EXISTS, reported only on the error channel.
    ; LINE_BUF is idle until pass 2 reads an include, and OPEN has sent the
    ; name by the time it returns.
    lda #'@'
    sta LINE_BUF
    lda #'0'
    sta LINE_BUF+1
    lda #':'
    sta LINE_BUF+2
    ldy #0
:   lda ASM_FNAME,y
    sta LINE_BUF+3,y
    iny
    cpy ASM_FNAME_LEN
    bne :-
    tya
    clc
    adc #3
    ldx #<LINE_BUF
    ldy #>LINE_BUF
    jsr SETNAM

    jsr OPEN
    bcs @err_close              ; LFN is registered even when OPEN fails

    ldx #ASM_OUT_LA_VAL
    jsr CHKOUT
    bcs @err_close

    ; PRG header from ASM_LOAD_LO/HI: the address of the first output
    ; byte, recorded by mark_emit in pass 1 ($0801 if nothing is emitted).
    lda ASM_LOAD_LO
    jsr CHROUT
    lda ASM_LOAD_HI
    jsr CHROUT

    lda #$FF
    sta ASM_OUT_OPEN
    clc
    rts

@err_close:
    ; The Kernal registers the logical file before the serial OPEN can fail
    ; (DEVICE NOT PRESENT etc.): without this CLOSE every later assembly in
    ; the session fails with FILE OPEN on LFN 4.  The caller expects an
    ; error to have been recorded, so record I/O ERROR here.
    lda #ASM_OUT_LA_VAL
    jsr CLOSE
    jsr set_err_io
@err:
    sec
    rts

close_output:
    lda ASM_OUT_OPEN
    beq @done
    jsr CLRCHN
    lda #ASM_OUT_LA_VAL
    jsr CLOSE
    lda #0
    sta ASM_OUT_OPEN
    ; Disk full, write protect and the like reach us only through the
    ; drive's error channel: read the status code's tens digit.
    lda #0
    jsr SETNAM
    lda #ASM_DS_LA
    ldx MOD_DRIVE
    ldy #15
    jsr SETLFS
    lda #'0'
    sta ASM_DS_CODE
    jsr OPEN
    bcs @ds_close
    ldx #ASM_DS_LA
    jsr CHKIN
    bcs @ds_close
    jsr CHRIN
    sta ASM_DS_CODE
@ds_close:
    jsr CLRCHN
    lda #ASM_DS_LA
    jsr CLOSE
    lda ASM_DS_CODE
    cmp #'2'                    ; codes 20-99 are errors
    bcc @done
    jsr set_err_io
@done:
    rts

; resume_output  -  re-select the output file as the active output channel.
; Pass 2 relies on the channel set once by open_output staying active for
; every emit_byte (a bare CHROUT); any include-file I/O in between must
; CLRCHN to switch serial bus roles, then call this to put it back.
; No-op when the output file isn't open (pass 1). Clobbers A, X.
resume_output:
    lda ASM_OUT_OPEN
    beq @done
    ldx #ASM_OUT_LA_VAL
    jsr CHKOUT
    bcc @done
    jsr set_err_io
@done:
    rts

; ============================================================================
; prompt_outfile  -  show "OUTPUT: " on status bar, get filename.
; Stores in ASM_FNAME / ASM_FNAME_LEN. C=1 if cancelled.
; ============================================================================

prompt_outfile:
    ; Display "OUTPUT: " on status row
    ldy #0
@lbl:
    lda outfile_prompt,y
    beq @flush
    sta STATUS_ROW,y
    lda #DEFAULT_COLOR
    sta COLOR,y
    iny
    jmp @lbl

@flush:
    jsr GETIN
    bne @flush

    lda #0
    sta ASM_FNAME_LEN

@inp:
    ; Blink cursor
    ldy ASM_FNAME_LEN
    lda #$20 | $80              ; reverse space as cursor
    sta STATUS_ROW+8,y          ; after "OUTPUT: " (8 chars)

@wait:
    jsr GETIN
    beq @wait

    cmp #$0D                    ; RETURN = confirm
    beq @confirm
    cmp #$03                    ; STOP/RUN-STOP
    beq @cancel
    cmp #$14                    ; DEL
    bne @char
    lda ASM_FNAME_LEN
    beq @inp
    ldy ASM_FNAME_LEN
    dey
    lda #$20
    sta STATUS_ROW+8,y
    dec ASM_FNAME_LEN
    jmp @inp
@char:
    cmp #$20
    bcc @inp
    ldy ASM_FNAME_LEN
    cpy #16
    bcs @inp
    sta ASM_FNAME,y
    ; Display char (petscii?screen code simple: subtract $40 for A-Z)
    jsr petscii_to_sc
    sta STATUS_ROW+8,y
    inc ASM_FNAME_LEN
    jmp @inp

@confirm:
    lda ASM_FNAME_LEN
    beq @inp                    ; don't accept empty name
    ; Clear cursor
    ldy ASM_FNAME_LEN
    lda #$20
    sta STATUS_ROW+8,y
    clc
    rts
@cancel:
    sec
    rts

petscii_to_sc:
    cmp #$40
    bcc @done
    cmp #$60
    bcc @s40
    and #$7F
    rts
@s40: sec
    sbc #$40
@done: rts

outfile_prompt:
    ; "OUTPUT: " in screen codes
    .byte $0F,$15,$14,$10,$15,$14,$3A,$20, 0

; ============================================================================
; fill_line_buf  -  read one line from the current include file into LINE_BUF.
;
; The current top frame must be KIND=FILE with an open LFN.
; Reads via CHKIN/CHRIN until CR, EOF, or LINE_BUF_MAX chars.
; Appends a CR terminator so the parser sees a normal line ending.
; Sets SRC_PTR = LINE_BUF (start of new line).
; Sets LINE_BUF_END = lo byte of address past last content char (points at CR).
;
; Returns: C=0 line ready; C=1 EOF (file exhausted, nothing written).
;
; Clobbers: A, X, Y, TMP, TMP2 (TMP2 = frame pointer, recomputed here so the
;           routine is self-contained).
;
; IRQ is disabled throughout (SEI is in effect from assemble entry).
; CHKIN/CHRIN are Kernal calls that need IRQ OFF — already satisfied.
; ============================================================================

fill_line_buf:
    jsr src_top_frame_ptr       ; TMP2 = base of top frame

    ; If a previous fill saw the EOF status arrive with the file's final
    ; byte, the frame was latched to FEOF: the file is fully consumed.
    ; Report EOF without touching the bus (no channel was selected yet,
    ; so nothing to release or restore).
    ldy #SRC_FRAME_KIND
    lda (TMP2),y
    cmp #SRC_KIND_FEOF
    bne :+
    sec
    rts
:

    ; Release whatever channel is active before switching the serial bus
    ; to TALK for this file.  In pass 2 that is the output file's LISTEN;
    ; resume_output re-selects it on every exit path below.
    jsr CLRCHN

    ; Get LFN from frame
    ldy #SRC_FRAME_LFN
    lda (TMP2),y                ; A = LFN

    ; CHKIN: direct the input channel to this file.
    ; Needs IRQ enabled for serial bus timing — but we're running with SEI.
    ; On real hardware the Kernal uses the CIA timer, not IRQ, for serial;
    ; CHKIN itself just sets the input flag in the Kernal tables and returns.
    ; Serial byte transfer happens in CHRIN.  Both work with SEI on the C64.
    tax                         ; CHKIN takes LFN in X
    jsr CHKIN
    bcs @io_err                 ; C=1 = Kernal error (file not open etc.)

    ; Read loop: fill LINE_BUF one char at a time
    ldy #0                      ; Y = index into LINE_BUF
@read_loop:
    jsr CHRIN                   ; A = next byte from file
    ; Check status immediately after each byte
    pha
    jsr READST                  ; A = serial status byte
    and #$42                    ; bit 6 = EOF, bit 1 = read error
    sta TMP                     ; save status
    pla                         ; restore char
    ldx TMP                     ; X = status; Z reflects it (BIT would test
                                ; A&status — wrong: a final CR has no bits
                                ; in common with $42 and EOF would be missed)
    bne @check_eof_or_err       ; non-zero status: EOF or error

    ; Normal byte
    cmp #$0D                    ; CR = end of line
    beq @end_of_line

    ; Store byte if room remains
    cpy #LINE_BUF_MAX
    bcs @overflow               ; Y >= 80: line too long, keep draining
    sta LINE_BUF,y
    iny
    jmp @read_loop

@overflow:
    ; Line exceeds LINE_BUF_MAX: drain chars until CR/EOF, report error.
    ; set_err_common's copy loop clobbers Y (our line index) — preserve it
    ; so the drain keeps draining instead of resuming stores mid-buffer.
    tya
    pha
    jsr set_err_truncate
    pla
    tay
    ; keep reading to consume the rest of the line
    jmp @read_loop

@check_eof_or_err:
    tax                         ; X = the byte that arrived with the status
    lda TMP
    and #$02                    ; bit 1 = read error / timeout
    bne @io_err
    ; bit 6 = EOF.  On the serial bus the drive delivers the file's FINAL
    ; byte together with the EOF status (EOI), so the byte in X is real
    ; content — unless it's the line's own CR terminator.  Latch the
    ; frame to FEOF so the next fill reports EOF without re-reading a
    ; drained channel (which would raise a spurious timeout).
    sty TMP                     ; save line index (status no longer needed)
    lda #SRC_KIND_FEOF
    ldy #SRC_FRAME_KIND
    sta (TMP2),y
    ldy TMP                     ; restore line index
    txa
    cmp #$0D
    beq @eof_have_line          ; file ended with CR: line complete as-is
    cpy #LINE_BUF_MAX
    bcs @eof_have_line          ; no room: drop (LINE TOO LONG already set)
    sta LINE_BUF,y              ; keep the final byte
    iny
@eof_have_line:
    cpy #0
    beq @eof_empty              ; nothing read at all → pure EOF
    ; fall through: flush final (possibly CR-less) line as a valid line

@end_of_line:
    ; Terminate LINE_BUF with CR (parser expects it), then a NUL sentinel
    ; so a runaway scan reads end-of-source instead of stale bytes.
    lda #0
    sta LINE_BUF+1,y
    lda #$0D
    sta LINE_BUF,y              ; write CR terminator
    ; LINE_BUF_END = lo byte of &LINE_BUF[y] (hi is always $BF)
    tya
    clc
    adc #<LINE_BUF
    sta LINE_BUF_END            ; points at the CR byte

    jsr CLRCHN                  ; release input channel
    jsr resume_output           ; pass 2: re-select the output file

    ; Point SRC_PTR at start of LINE_BUF
    lda #<LINE_BUF
    sta SRC_PTR
    lda #>LINE_BUF
    sta SRC_PTR+1

    clc                         ; C=0: line ready
    rts

@eof_empty:
    jsr CLRCHN
    jsr resume_output
    sec                         ; C=1: EOF, no line
    rts

@io_err:
    ; A failure before any line of this file was read (a missing file
    ; times out on the very first byte) would report "line 0" — point it
    ; at the parent's .include line, saved in this frame, instead.
    lda ASM_LINE_LO
    ora ASM_LINE_HI
    bne :+
    ldy #SRC_FRAME_LLO
    lda (TMP2),y
    sta ASM_LINE_LO
    ldy #SRC_FRAME_LHI
    lda (TMP2),y
    sta ASM_LINE_HI
:
    jsr CLRCHN
    jsr resume_output
    jsr set_err_io
    sec                         ; treat I/O error as EOF to avoid infinite loop
    rts

; ============================================================================
; src_top_frame_ptr  -  TMP2 = base of the top frame (index SRC_DEPTH).
; src_frame_ptr      -  TMP2 = base of frame A (0..SRC_MAX_DEPTH-1).
; TMP2 = SRC_STACK + index * SRC_FRAME_SIZE.  Clobbers A only (X and Y are
; preserved: the .include push keeps the filename length in X across it).
; The frames never cross a page (asserted), so the hi byte is constant.
; ============================================================================

src_top_frame_ptr:
    lda SRC_DEPTH
src_frame_ptr:
    asl                         ; *2 (index < 128, so C=0 after)
    sta TMP2
    asl                         ; *4, C=0
    adc TMP2                    ; *6, C=0 (result < 256)
    adc #<SRC_STACK             ; no carry: asserted not to cross a page
    sta TMP2
    lda #>SRC_STACK
    sta TMP2+1
    rts

; ============================================================================
; pop_src_frame  -  close current include file, pop the frame stack,
; restore SRC_PTR and ASM_LINE from the parent frame's saved values.
;
; Called when fill_line_buf returns C=1 (EOF on include file).
; After return, SRC_PTR points back into the parent source (buffer or outer
; include) at the instruction after the .include directive.
; ============================================================================

pop_src_frame:
    jsr src_top_frame_ptr       ; TMP2 = base of top frame

    ; Close the file: CLOSE(LFN).  CLOSE talks on the serial bus, which
    ; drops any active LISTEN — release channels first and re-select the
    ; output file after (pass 2).
    jsr CLRCHN
    ldy #SRC_FRAME_LFN
    lda (TMP2),y
    jsr CLOSE                   ; Kernal CLOSE — always succeeds (ignores bad LFN)
    jsr resume_output

    ; Restore ASM_LINE from frame (per-file line counter)
    ldy #SRC_FRAME_LLO
    lda (TMP2),y
    sta ASM_LINE_LO
    ldy #SRC_FRAME_LHI
    lda (TMP2),y
    sta ASM_LINE_HI

    ; Restore SRC_PTR from frame (resume position in parent source)
    ldy #SRC_FRAME_SLO
    lda (TMP2),y
    sta SRC_PTR
    ldy #SRC_FRAME_SHI
    lda (TMP2),y
    sta SRC_PTR+1

    ; Decrement depth
    dec SRC_DEPTH
    rts

; ============================================================================
; Error helpers
; ============================================================================

; set_err_*  -  record error if none already recorded.
; Only the first error is kept: set_err_common returns at once if ASM_ERR
; is already set.
;
; Each entry point is LDA #(offset of its message in err_msgs) followed by
; a $2C byte, which turns the next entry's 2-byte LDA into the operand of a
; harmless BIT abs (it only reads RAM at $xxA9, xx = a message offset, kept
; below $A0 by the assert at err_msgs) — so every entry falls through to
; set_err_common with its own offset in A.  A is clobbered (as before);
; X is untouched, and Y is clobbered only when the error is recorded
; (set_err_common's copy loop), exactly as before.

set_err_org:
    lda #err_org_txt - err_msgs ; first in the chain: its own offset is
    .byte $2C                   ; never a BIT operand (see the asserts)

set_err_deep:
    lda #err_deep_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_phase:
    lda #err_phase_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_truncate:
    lda #err_truncate_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_syntax:
    lda #err_syntax_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_value:
    lda #err_value_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_symbol:
    lda #err_symbol_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_mnemonic:
    lda #err_mnem_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_unknown:
    lda #err_unknown_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_operand:
    lda #err_operand_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_mode:
    lda #err_mode_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_range:
    lda #err_range_txt - err_msgs
    .byte $2C                   ; BIT abs: skip the next LDA #

set_err_io:
    lda #err_io_txt - err_msgs
    ; fall through

set_err_common:
    ; A = offset of the message in err_msgs.  ASM_ERR is only ever $00 or
    ; $FF, so BIT tests it without disturbing A.
    bit ASM_ERR
    bmi @already                ; only record first error
    clc
    adc #<err_msgs
    sta TMP
    lda #>err_msgs
    adc #0
    sta TMP+1
    lda #$FF
    sta ASM_ERR
    lda ASM_LINE_LO
    sta ASM_ERR_LINE_LO
    lda ASM_LINE_HI
    sta ASM_ERR_LINE_HI
    ; Copy message string to ASM_ERR_MSG
    ldy #0
@copy:
    lda (TMP),y
    beq @done
    sta ASM_ERR_MSG,y
    iny
    cpy #20
    bne @copy
@done:
    lda #0
    sta ASM_ERR_MSG,y           ; ensure zero terminator
@already:
    rts

; copy_error_to_status  -  show error on screen status row
copy_error_to_status:
    ldy #0
@loop:
    lda ASM_ERR_MSG,y
    beq @done
    sta STATUS_ROW,y
    lda #2                      ; red
    sta COLOR,y
    iny
    bne @loop
@done:
    rts

; Error message strings (screen codes, zero-terminated, max 20 chars).
; One contiguous block: set_err_* address a message by its offset in it.
err_msgs:
err_syntax_txt:
    .byte $13,$19,$0E,$14,$01,$18,$20,$05,$12,$12,$0F,$12, 0        ; SYNTAX ERROR
err_value_txt:
    .byte $16,$01,$0C,$15,$05,$20,$05,$12,$12,$0F,$12, 0            ; VALUE ERROR
err_symbol_txt:
    .byte $13,$19,$0D,$02,$0F,$0C,$20,$05,$12,$12,$0F,$12, 0       ; SYMBOL ERROR
err_mnem_txt:
    .byte $02,$01,$04,$20,$0D,$0E,$05,$0D,$0F,$0E,$09,$03, 0       ; BAD MNEMONIC
err_unknown_txt:
    .byte $15,$0E,$0B,$0E,$17,$0E,$20,$0F,$10, 0                    ; UNKNWN OP
err_operand_txt:
    .byte $02,$01,$04,$20,$0F,$10,$05,$12,$01,$0E,$04, 0            ; BAD OPERAND
err_mode_txt:
    .byte $02,$01,$04,$20,$01,$04,$04,$12,$20,$0D,$0F,$04,$05, 0   ; BAD ADDR MODE
err_range_txt:
    .byte $02,$12,$01,$0E,$03,$08,$20,$12,$01,$0E,$07,$05, 0       ; BRANCH RANGE
err_io_txt:
    .byte $09,$2F,$0F,$20,$05,$12,$12,$0F,$12, 0                    ; I/O ERROR
err_truncate_txt:
    .byte $0C,$09,$0E,$05,$20,$14,$0F,$0F,$20,$0C,$0F,$0E,$07, 0   ; LINE TOO LONG
err_deep_txt:
    .byte $09,$0E,$03,$0C,$15,$04,$05,$20,$14,$0F,$0F,$20,$04,$05,$05,$10, 0   ; INCLUDE TOO DEEP
err_phase_txt:
    .byte $10,$08,$01,$13,$05,$20,$05,$12,$12,$0F,$12, 0            ; PHASE ERROR
; err_org_txt is last: set_err_org heads the chain, so its offset is never
; the hi byte of a BIT operand and may exceed $A0.
err_org_txt:
    .byte $0F,$12,$07,$20,$02,$01,$03,$0B,$17,$01,$12,$04,$13, 0    ; ORG BACKWARDS
err_msgs_end:
.assert err_org_txt - err_msgs <= $A0, error, "modasm: err_msgs too long for the set_err_* offsets / BIT skip"
.assert err_msgs_end - err_msgs <= $100, error, "modasm: err_msgs offsets must fit in a byte"

; ============================================================================
; Opcode table (526 bytes)
; Format per entry: 3 ASCII bytes (mnemonic) + (mode,opcode) pairs + $FF
; End: $00 $00 $00
; ============================================================================

op_size_tab:
    .byte 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1
    ; IMP ACC IMM ZP  ZPX ZPY ABS ABX ABY IND IZX IZY REL

opcode_table:
    .byte "ADC", $02,$69, $03,$65, $04,$75, $06,$6D, $07,$7D, $08,$79, $0A,$61, $0B,$71, $FF
    .byte "AND", $02,$29, $03,$25, $04,$35, $06,$2D, $07,$3D, $08,$39, $0A,$21, $0B,$31, $FF
    .byte "ASL", $01,$0A, $03,$06, $04,$16, $06,$0E, $07,$1E, $FF
    .byte "BCC", $0C,$90, $FF
    .byte "BCS", $0C,$B0, $FF
    .byte "BEQ", $0C,$F0, $FF
    .byte "BIT", $03,$24, $06,$2C, $FF
    .byte "BMI", $0C,$30, $FF
    .byte "BNE", $0C,$D0, $FF
    .byte "BPL", $0C,$10, $FF
    .byte "BRK", $00,$00, $FF
    .byte "BVC", $0C,$50, $FF
    .byte "BVS", $0C,$70, $FF
    .byte "CLC", $00,$18, $FF
    .byte "CLD", $00,$D8, $FF
    .byte "CLI", $00,$58, $FF
    .byte "CLV", $00,$B8, $FF
    .byte "CMP", $02,$C9, $03,$C5, $04,$D5, $06,$CD, $07,$DD, $08,$D9, $0A,$C1, $0B,$D1, $FF
    .byte "CPX", $02,$E0, $03,$E4, $06,$EC, $FF
    .byte "CPY", $02,$C0, $03,$C4, $06,$CC, $FF
    .byte "DEC", $03,$C6, $04,$D6, $06,$CE, $07,$DE, $FF
    .byte "DEX", $00,$CA, $FF
    .byte "DEY", $00,$88, $FF
    .byte "EOR", $02,$49, $03,$45, $04,$55, $06,$4D, $07,$5D, $08,$59, $0A,$41, $0B,$51, $FF
    .byte "INC", $03,$E6, $04,$F6, $06,$EE, $07,$FE, $FF
    .byte "INX", $00,$E8, $FF
    .byte "INY", $00,$C8, $FF
    .byte "JMP", $06,$4C, $09,$6C, $FF
    .byte "JSR", $06,$20, $FF
    .byte "LDA", $02,$A9, $03,$A5, $04,$B5, $06,$AD, $07,$BD, $08,$B9, $0A,$A1, $0B,$B1, $FF
    .byte "LDX", $02,$A2, $03,$A6, $05,$B6, $06,$AE, $08,$BE, $FF
    .byte "LDY", $02,$A0, $03,$A4, $04,$B4, $06,$AC, $07,$BC, $FF
    .byte "LSR", $01,$4A, $03,$46, $04,$56, $06,$4E, $07,$5E, $FF
    .byte "NOP", $00,$EA, $FF
    .byte "ORA", $02,$09, $03,$05, $04,$15, $06,$0D, $07,$1D, $08,$19, $0A,$01, $0B,$11, $FF
    .byte "PHA", $00,$48, $FF
    .byte "PHP", $00,$08, $FF
    .byte "PLA", $00,$68, $FF
    .byte "PLP", $00,$28, $FF
    .byte "ROL", $01,$2A, $03,$26, $04,$36, $06,$2E, $07,$3E, $FF
    .byte "ROR", $01,$6A, $03,$66, $04,$76, $06,$6E, $07,$7E, $FF
    .byte "RTI", $00,$40, $FF
    .byte "RTS", $00,$60, $FF
    .byte "SBC", $02,$E9, $03,$E5, $04,$F5, $06,$ED, $07,$FD, $08,$F9, $0A,$E1, $0B,$F1, $FF
    .byte "SEC", $00,$38, $FF
    .byte "SED", $00,$F8, $FF
    .byte "SEI", $00,$78, $FF
    .byte "STA", $03,$85, $04,$95, $06,$8D, $07,$9D, $08,$99, $0A,$81, $0B,$91, $FF
    .byte "STX", $03,$86, $05,$96, $06,$8E, $FF
    .byte "STY", $03,$84, $04,$94, $06,$8C, $FF
    .byte "TAX", $00,$AA, $FF
    .byte "TAY", $00,$A8, $FF
    .byte "TSX", $00,$BA, $FF
    .byte "TXA", $00,$8A, $FF
    .byte "TXS", $00,$9A, $FF
    .byte "TYA", $00,$98, $FF
    .byte $00,$00,$00                ; end of table

; The module image must stay below the fixed-address RAM it uses at run
; time (SYM_HASH at $BD00, then SRC_DEPTH/SRC_STACK/LINE_BUF at $BFxx).
; modasm.cfg's MAIN area runs to $BFFF, so the linker alone would let the
; code grow into it.
MODASM_CODE_END:
.assert MODASM_CODE_END <= SYM_HASH, lderror, "modasm: code overruns the fixed RAM at SYM_HASH"

; ============================================================================
; Linker config note: use modasm.cfg with
;   MEMORY { LOADADDR: start=$A000, size=2; CODE: start=$A000, size=$2000; }
;   SEGMENTS { LOADADDR: load=LOADADDR; CODE: load=CODE; }
; ============================================================================
