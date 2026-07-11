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
;         PRG header: $01,$08 (or .org address if specified before any code).
;
; Symbol table: $C000-$CFFF, 10 bytes/entry (8-char name + 2-byte value).
;               Up to 409 symbols. Linear scan  -  fast enough for casual use.
;
; Error reporting: first error message written to ASM_ERR_MSG area,
;                  line number in ASM_ERR_LINE_LO/HI. MOD_STATUS=$01.
;
; Zero page (saved/restored):
;   $FB/$FC = SRC_PTR   walks source (gap-aware)
;   $FD/$FE = unused (available)
;   $3A-$3F = scratch
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
SRC_PTR  = $FB   ; lo (hi=$FC)  -  source walker, gap-aware
TMP      = $3A   ; general scratch (hi=$3B)
TMP2     = $3C   ; (hi=$3D)
TMP3     = $3E   ; (hi=$3F)

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

ASM_PC_LO       = $C000   ; current program counter lo
ASM_PC_HI       = $C001   ; current program counter hi
ASM_PASS        = $C002   ; 0=pass1, 1=pass2
ASM_SYM_LO      = $C003   ; symbol count lo
ASM_SYM_HI      = $C004   ; symbol count hi
ASM_LINE_LO     = $C005   ; current line number lo
ASM_LINE_HI     = $C006   ; current line number hi
ASM_ERR         = $C007   ; $FF = error encountered
ASM_ERR_LINE_LO = $C008   ; line number of first error lo
ASM_ERR_LINE_HI = $C009   ; line number of first error hi
ASM_ERR_MSG     = $C00A   ; 20-byte error message (screen codes, zero-terminated)
ASM_OUT_LA      = $C01E   ; logical file number for output
ASM_OUT_OPEN    = $C01F   ; $FF = output file is open
ASM_ORG_SET     = $C020   ; $FF = .org has been seen (affects PRG header)
ASM_FNAME_LEN   = $C021   ; output filename length
ASM_FNAME       = $C022   ; output filename (16 bytes)

; ---- ZP save area ----
ZP_SAVE         = $C03A   ; 10 bytes: saves $3A-$3F, $FB-$FE

; ---- Gap pointers (copied from params) ----
ASM_GAP_S_LO    = $C032
ASM_GAP_S_HI    = $C033
ASM_GAP_E_LO    = $C034
ASM_GAP_E_HI    = $C035
ASM_BUF_LO      = $C036
ASM_BUF_HI      = $C037
ASM_END_LO      = $C038
ASM_END_HI      = $C039

; ---- Scratch for mnemonic/operand parsing ----
ASM_MNEM        = $C044   ; 4 bytes: current mnemonic/directive name
ASM_MODE        = $C048   ; resolved addressing mode
ASM_OPCODE      = $C049   ; resolved opcode byte
ASM_VAL_LO      = $C04A   ; operand value lo
ASM_VAL_HI      = $C04B   ; operand value hi
ASM_INSTR_SIZE  = $C04C   ; total instruction size (1+operand bytes)
ASM_LABEL       = $C04D   ; 8 bytes: current label (space-padded)
ASM_YPEEK       = $C055   ; scratch: src_peek Y save (1 byte, at end of state block)
ASM_OPC_PTR_LO  = $C056   ; saved opcode table pointer lo (preserved across parse_operand)
ASM_OPC_PTR_HI  = $C057   ; saved opcode table pointer hi

; FIX (load address): PRG load address = address of first .org/.* seen, or $0801.
; Stored here during pass 1; used by open_output for the PRG header.
; Lives in the gap between ASM_OPC_PTR_HI ($C057) and SYM_TABLE ($C060).
ASM_LOAD_LO     = $C058   ; PRG load address lo
ASM_LOAD_HI     = $C059   ; PRG load address hi

; Activity spinner — same corner cell and toggle mechanic as MODDIS.
ASM_SPINNER     = $C05A   ; 8-bit line counter; every 16 lines → color flip
ASM_SPIN_IDX    = $C05B   ; current color value written to SPIN_CELL

; parse_decimal ×10 scratch.  Deliberately NOT TMP2: parse_expr saves the
; base of a "label+N" / "label-N" expression in TMP2 across parse_number,
; so parse_decimal must not touch it.
ASM_MUL_LO      = $C05C   ; ×10 partial (value*2) lo
ASM_MUL_HI      = $C05D   ; ×10 partial (value*2) hi

; End-of-pass-1 PC, for the pass-2 phase check.  If the two passes end at
; different PCs (e.g. a forward reference sized as 16-bit in pass 1 that
; resolved to zero page in pass 2), the emitted PRG is silently misaligned
; from the point of divergence on — report PHASE ERROR instead.
ASM_P1END_LO    = $C05E
ASM_P1END_HI    = $C05F

SPIN_CELL       = $D800   ; color RAM col 0, row 0 (top-left corner)
SPIN_COLOR_A    = $01     ; white
SPIN_COLOR_B    = $00     ; black

; ---- Symbol table ----
SYM_TABLE       = $C060   ; 10 bytes/entry: 8-char name + 2-byte value
SYM_ENTRY_SIZE  = 10
SYM_MAX         = 400

; ---- Output file ----
ASM_OUT_LA_VAL  = 4       ; logical file 4 for output

; ============================================================================
; Include / source-stack state
; ----------------------------------------------------------------------------
; The assembler reads source through a stack of "frames". Frame 0 is the
; editor's in-memory gap buffer (the normal, no-include case). A .include
; directive pushes a FILE frame that streams the included file from disk one
; line at a time into LINE_BUF, so SRC_PTR always points at real RAM and the
; parser's rewind-on-lookahead (check_for_label) keeps working unchanged.
;
; Placed at fixed addresses high in MAIN ($BFxx). Code ends well below $B000,
; so this free RAM is in the same always-visible bank ($01=$36) as the code —
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


; ============================================================================
; Module entry point
; ============================================================================

.segment "LOADADDR"
    .word $A000

.segment "CODE"

    jmp assemble            ; $A000: module entry (JMP convention)

; ============================================================================
; assemble  -  main entry point
; ============================================================================

assemble:
    ; Disable IRQ for the duration of assembly.
    ; The C64 Kernal IRQ handler uses $FB/$FC as a scratch pointer for
    ; cursor blink, which would corrupt SRC_PTR mid-assembly.
    sei

    ; Ensure $01=$36 (BASIC ROM out, Kernal+I/O in, RAM at $A000-$BFFF visible).
    ; Do this FIRST before touching any state  -  if caller failed to set banking,
    ; our code here would be unreadable (BASIC ROM at $A000). But since we're
    ; already executing (caller's JMP got us here), banking must be at least
    ; partially working. Belt-and-suspenders: force it explicitly.
    ; Must set $00 first to make bits 0-2 outputs, then write $01.
    lda $00
    ora #$07
    sta $00
    lda #$36
    sta $01

    ; Save ZP
    ldx #0
@zpsave:
    lda $3A,x
    sta ZP_SAVE,x
    inx
    cpx #6
    bne @zpsave
    lda $FB
    sta ZP_SAVE+6
    lda $FC
    sta ZP_SAVE+7
    lda $FD
    sta ZP_SAVE+8
    lda $FE
    sta ZP_SAVE+9

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
    sta ASM_ORG_SET
    sta ASM_FNAME_LEN

    ; Default PC = $0801
    lda #$01
    sta ASM_PC_LO
    lda #$08
    sta ASM_PC_HI

    ; FIX (load address): default load address = $0801.
    ; Updated to first .org/.* address seen during pass 1.
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
    jmp @restore_zp             ; cancelled  -  return with MOD_STATUS unchanged ($FF)
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

    ; FIX (load address): reset PC for pass 2 BEFORE opening the output file,
    ; so that open_output reads ASM_LOAD_LO/HI (set during pass 1) not ASM_PC
    ; (which held the end-of-pass-1 address).
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
    ldx #0
@zprest:
    lda ZP_SAVE,x
    sta $3A,x
    inx
    cpx #6
    bne @zprest
    lda ZP_SAVE+6
    sta $FB
    lda ZP_SAVE+7
    sta $FC
    lda ZP_SAVE+8
    sta $FD
    lda ZP_SAVE+9
    sta $FE
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
    ; Skip leading spaces/tabs
    jsr skip_spaces

    ; Peek at first char
    jsr src_peek                ; A = current char (or 0 at end)
    bne :+
    jmp @done
    :
    cmp #$0D
    bne :+
    jmp @done
    :
    cmp #';'
    bne :+
    jmp @done
    :

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
    lda TMP
    sta ASM_PC_LO
    lda TMP+1
    sta ASM_PC_HI
    ; FIX (load address): capture load address from first *= seen
    lda ASM_ORG_SET
    bne :+
    lda TMP
    sta ASM_LOAD_LO
    lda TMP+1
    sta ASM_LOAD_HI
:
    lda #$FF
    sta ASM_ORG_SET
    jmp @done

@not_star:
    ; Check for directive ('.')
    cmp #'.'
    bne @not_directive
    jsr parse_directive
    jmp @done

@not_directive:
    ; Check if this is a label (contains ':' before space/end)
    jsr check_for_label         ; C=1 if label found, label in ASM_LABEL
    bcc @no_label

    ; Process label
    lda ASM_PASS
    bne @skip_label_def         ; pass 2: ignore label definitions
    ; Pass 1: add label to symbol table with current PC
    jsr sym_define
    bcs @err_sym                ; symbol table full or duplicate
@skip_label_def:

    ; Skip spaces after label
    jsr skip_spaces
    ; Peek: might be end of line (label-only line)
    jsr src_peek
    bne :+
    jmp @done
:   cmp #$0D
    bne :+
    jmp @done
:   cmp #';'
    bne :+
    jmp @done
:

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
    lda ASM_INSTR_SIZE
    clc
    adc ASM_PC_LO
    sta ASM_PC_LO
    bcc @done
    inc ASM_PC_HI
    jmp @done

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

    ; Init ASM_LABEL to spaces
    ldy #0
@pad:
    lda #' '
    sta ASM_LABEL,y
    iny
    cpy #8
    bne @pad

    ; Read up to 8 chars, stop at non-alphanumeric/underscore
    ldy #0
@read:
    jsr src_peek
    beq @no_label
    cmp #':'
    beq @found_label
    cmp #' '
    beq @no_label
    cmp #$0D
    beq @no_label
    ; Check valid label char: A-Z, a-z, 0-9, _
    jsr is_alnum_or_under       ; C=1 if valid
    bcc @no_label
    ; Normalize to uppercase
    cmp #$61
    bcc @store
    cmp #$7B
    bcs @store
    sec
    sbc #$20
@store:
    cpy #8
    bcs @skip_char              ; >8 chars: keep scanning but don't store
    sta ASM_LABEL,y
    iny
@skip_char:
    jsr src_advance
    jmp @read

@found_label:
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
    clc
    rts
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
    jsr src_peek
    bne :+
    jmp @imp
    :
    cmp #$0D
    bne :+
    jmp @imp
    :
    cmp #';'
    bne :+
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
; Supports: $hex, decimal, label, <expr, >expr, expr+N, expr-N
; C=1 on error.
; ============================================================================

parse_expr:
    lda #0
    sta TMP
    sta TMP+1

    jsr src_peek

    ; '<' ? lo byte of following expression
    cmp #'<'
    bne @not_lo
    jsr src_advance
    jsr parse_expr_base
    bcc :+
    jmp @err
    :
    lda TMP                     ; lo byte only
    sta ASM_VAL_LO
    lda #0
    sta ASM_VAL_HI
    sta TMP+1                   ; TMP = result too (see contract above)
    clc
    rts

@not_lo:
    ; '>' ? hi byte of following expression
    cmp #'>'
    bne @not_hi
    jsr src_advance
    jsr parse_expr_base
    bcs @err
    lda TMP+1                   ; hi byte ? becomes lo byte of result
    sta ASM_VAL_LO
    sta TMP                     ; TMP = result too (see contract above)
    lda #0
    sta ASM_VAL_HI
    sta TMP+1
    clc
    rts

@not_hi:
    jsr parse_expr_base
    bcs @err
    ; Check for +/- offset
    jsr src_peek
    cmp #'+'
    beq @add
    cmp #'-'
    beq @sub
    lda TMP
    sta ASM_VAL_LO
    lda TMP+1
    sta ASM_VAL_HI
    clc
    rts

@add:
    jsr src_advance
    ; Save base value.  parse_number/parse_decimal must NOT touch TMP2 —
    ; parse_decimal uses ASM_MUL for its ×10 scratch for exactly this reason.
    lda TMP
    sta TMP2
    lda TMP+1
    sta TMP2+1
    jsr parse_number            ; parse literal offset into TMP/TMP+1
    bcs @err
    lda TMP2
    clc
    adc TMP
    sta ASM_VAL_LO
    sta TMP                     ; TMP = result too (see contract above)
    lda TMP2+1
    adc TMP+1
    sta ASM_VAL_HI
    sta TMP+1
    clc
    rts

@sub:
    jsr src_advance
    lda TMP
    sta TMP2
    lda TMP+1
    sta TMP2+1
    jsr parse_number
    bcs @err
    lda TMP2
    sec
    sbc TMP
    sta ASM_VAL_LO
    sta TMP                     ; TMP = result too (see contract above)
    lda TMP2+1
    sbc TMP+1
    sta ASM_VAL_HI
    sta TMP+1
    clc
    rts

@err:
    sec
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
    ; Read label name into ASM_LABEL (space-padded, 8 chars)
    ldy #0
@pad:
    lda #' '
    sta ASM_LABEL,y
    iny
    cpy #8
    bne @pad

    ldy #0
@read:
    jsr src_peek
    jsr is_alnum_or_under
    bcc @done_read
    ; Normalize to uppercase
    cmp #$61
    bcc @store
    cmp #$7B
    bcs @store
    sec
    sbc #$20
@store:
    cpy #8
    bcs @skip
    sta ASM_LABEL,y
@skip:
    jsr src_advance
    iny
    jmp @read
@done_read:
    cpy #0
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

    ; Read directive name (up to 4 chars) into ASM_MNEM, normalized to uppercase
    ldy #0
@rd:
    jsr src_peek
    cmp #' '
    beq @rd_done
    cmp #$0D
    beq @rd_done
    ; Upcase
    cmp #$61
    bcc @rd_store
    cmp #$7B
    bcs @rd_store
    sec
    sbc #$20
@rd_store:
    cpy #4
    bcs @rd_skip
    sta ASM_MNEM,y
@rd_skip:
    jsr src_advance
    iny
    jmp @rd
@rd_done:

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
    lda TMP
    sta ASM_PC_LO
    lda TMP+1
    sta ASM_PC_HI
    ; FIX (load address): capture load address from first .org seen
    lda ASM_ORG_SET
    bne :+
    lda TMP
    sta ASM_LOAD_LO
    lda TMP+1
    sta ASM_LOAD_HI
:
    lda #$FF
    sta ASM_ORG_SET
    rts

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
    ; Pass 2: emit byte (don't advance PC here — happens unconditionally below)
    lda ASM_PASS
    beq @byte_advance
    lda TMP
    jsr emit_byte
    bcc @byte_advance
    jmp @err
@byte_advance:
    ; Always advance PC by 1, in BOTH passes.
    ; Previously pass 2 skipped this, leaving ASM_PC stale for later branches.
    inc ASM_PC_LO
    bne @byte_next
    inc ASM_PC_HI
@byte_next:
    jsr src_peek
    cmp #','
    bne @byte_done
    jsr src_advance
    jsr skip_spaces
    jmp @byte_loop
@byte_done:
    rts

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
    ; Pass 2: emit two bytes (lo, hi). PC advance happens below in BOTH passes.
    lda ASM_PASS
    beq @word_advance
    lda TMP
    jsr emit_byte
    bcc :+
    jmp @err
:   lda TMP+1
    jsr emit_byte
    bcc :+
    jmp @err
:
@word_advance:
    ; Always advance PC by 2, in BOTH passes.
    lda ASM_PC_LO
    clc
    adc #2
    sta ASM_PC_LO
    bcc @word_next
    inc ASM_PC_HI
@word_next:
    jsr src_peek
    cmp #','
    bne @word_done
    jsr src_advance
    jsr skip_spaces
    jmp @word_loop
@word_done:
    rts

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
    ; Pass 2: emit the byte. PC advance happens below in BOTH passes.
    lda ASM_PASS
    beq @text_advance
    jsr src_peek
    jsr emit_byte
    bcc :+
    jmp @dir_err_near
:
@text_advance:
    ; Always advance both source and PC, in BOTH passes.
    jsr src_advance
    inc ASM_PC_LO
    bne @text_loop
    inc ASM_PC_HI
    jmp @text_loop
@text_done:
    jsr src_advance             ; consume closing '"'
    rts

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
    ; Same N*6 multiply used in src_at_end / skip_to_next_line.
    ; SRC_DEPTH itself is incremented only after the file is open, so an
    ; OPEN failure leaves the stack untouched.
    lda SRC_DEPTH
    clc
    adc #1                      ; new frame index = current top + 1
    asl                         ; *2
    sta TMP2
    asl                         ; *4
    clc
    adc TMP2                    ; *6
    clc
    adc #<SRC_STACK
    sta TMP2
    lda #>SRC_STACK
    adc #0
    sta TMP2+1                  ; TMP2 = base of new frame

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
    lda TMP3                    ; LFN (still intact — Kernal leaves $3E alone)
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
    jsr set_err_syntax
    rts

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
    ; The hi byte of the result must be $00 (forward) or $FF (backward);
    ; anything else means the target is more than 128 bytes away.
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
    sbc TMP2+1                  ; hi byte: $00=forward in range, $FF=backward in range
    beq @rel_ok
    cmp #$FF
    bne @rel_range_err
@rel_ok:
    lda TMP
    jsr emit_byte
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

emit_byte:
    jsr CHROUT
    jsr READST
    and #$42                    ; error or EOF
    beq :+
    sec
    rts
:   clc
    rts

; ============================================================================
; Symbol table routines
; ============================================================================

; sym_define  -  add ASM_LABEL with current PC value to symbol table.
; C=1 if table full or duplicate.
sym_define:
    ; Check for duplicate (only warn  -  allow redefinition in pass 1 context)
    jsr sym_lookup
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

    ; Compute table entry address: SYM_TABLE + count * 10
    ; count * 10 = count * 8 + count * 2
    lda ASM_SYM_LO
    sta TMP
    lda ASM_SYM_HI
    sta TMP+1
    ; TMP * 10
    asl TMP
    rol TMP+1                   ; *2
    lda TMP
    sta TMP2
    lda TMP+1
    sta TMP2+1
    asl TMP
    rol TMP+1                   ; *4
    asl TMP
    rol TMP+1                   ; *8
    lda TMP
    clc
    adc TMP2
    sta TMP
    lda TMP+1
    adc TMP2+1
    sta TMP+1                   ; TMP = count*10
    lda TMP
    clc
    adc #<SYM_TABLE
    sta TMP2
    lda TMP+1
    adc #>SYM_TABLE
    sta TMP2+1                  ; TMP2 = entry address

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
sym_lookup:
    lda #<SYM_TABLE
    sta TMP2
    lda #>SYM_TABLE
    sta TMP2+1
    lda #0
    sta TMP3                    ; entry counter lo
    sta TMP3+1                  ; entry counter hi

@loop:
    ; Done if counter >= SYM_COUNT
    lda TMP3
    cmp ASM_SYM_LO
    lda TMP3+1
    sbc ASM_SYM_HI
    bcs @not_found

    ; Compare 8-char name
    ldy #0
@cmp:
    lda (TMP2),y
    cmp ASM_LABEL,y
    bne @next
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

@next:
    ; Advance TMP2 by 10
    lda TMP2
    clc
    adc #SYM_ENTRY_SIZE
    sta TMP2
    bcc :+
    inc TMP2+1
:
    inc TMP3
    bne @loop
    inc TMP3+1
    jmp @loop

@not_found:
    sec
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
    lda (SRC_PTR),y
    ldy ASM_YPEEK               ; restore Y — NOTE: this clobbers Z flag!
    ora #0                      ; re-assert Z based on A (Z=1 iff A=0)
    rts
@at_end:
    lda #0
    rts

@file_peek:
    sty ASM_YPEEK               ; same Y-preservation contract as above
    ldy #0
    lda (SRC_PTR),y
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
    ; Compute base address of current top frame into TMP3.
    ; TMP3 = SRC_STACK + SRC_DEPTH * SRC_FRAME_SIZE
    lda SRC_DEPTH
    beq @buf_frame               ; depth=0 is always the buffer frame (fast path)
    ; General case: index into stack.  Depth is small (<=8), so multiply by 6
    ; with shift-and-add: N*6 = N*4 + N*2.
    asl                          ; A = depth*2
    sta TMP3                     ; save depth*2
    asl                          ; A = depth*4
    clc
    adc TMP3                     ; A = depth*6
    clc
    adc #<SRC_STACK
    sta TMP3                     ; TMP3 lo = frame base lo
    lda #>SRC_STACK
    adc #0
    sta TMP3+1                   ; TMP3 hi = frame base hi
    ; Read KIND field (FILE or FEOF — both are file frames)
    ldy #SRC_FRAME_KIND
    lda (TMP3),y
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

; skip_to_next_line  -  advance SRC_PTR past the current line's CR.
; Frame-aware: KIND=BUFFER uses gap-buffer scan (original logic).
;              KIND=FILE uses LINE_BUF (step 2+; placeholder for now).
skip_to_next_line:
    ; Fast path: depth=0 is always the buffer frame.
    lda SRC_DEPTH
    beq @buf_skip
    ; Compute frame base into TMP3 (same multiply as src_at_end).
    asl
    sta TMP3
    asl
    clc
    adc TMP3
    clc
    adc #<SRC_STACK
    sta TMP3
    lda #>SRC_STACK
    adc #0
    sta TMP3+1
    ldy #SRC_FRAME_KIND
    lda (TMP3),y
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

    lda ASM_FNAME_LEN
    ldx #<ASM_FNAME
    ldy #>ASM_FNAME
    jsr SETNAM

    jsr OPEN
    bcs @err

    ldx #ASM_OUT_LA_VAL
    jsr CHKOUT
    bcs @err_close

    ; FIX (load address): write PRG header from ASM_LOAD_LO/HI, which holds
    ; the address of the first .org/.* seen during pass 1, or $0801 if none.
    ; Previously used ASM_PC_LO/HI here, which was the end-of-pass-1 PC.
    lda ASM_LOAD_LO
    jsr CHROUT
    lda ASM_LOAD_HI
    jsr CHROUT

    lda #$FF
    sta ASM_OUT_OPEN
    clc
    rts

@err_close:
    lda #ASM_OUT_LA_VAL
    jsr CLOSE
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
; Clobbers: A, X, Y, TMP, TMP2  (TMP3 = frame pointer, already set by caller
;           in skip_to_next_line; we recompute it here to be self-contained).
;
; IRQ is disabled throughout (SEI is in effect from assemble entry).
; CHKIN/CHRIN are Kernal calls that need IRQ OFF — already satisfied.
; ============================================================================

fill_line_buf:
    ; Compute current frame base into TMP2 (TMP3 may be in use by caller).
    lda SRC_DEPTH
    asl
    sta TMP2
    asl
    clc
    adc TMP2
    clc
    adc #<SRC_STACK
    sta TMP2
    lda #>SRC_STACK
    adc #0
    sta TMP2+1                  ; TMP2 = base of top frame

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
; pop_src_frame  -  close current include file, pop the frame stack,
; restore SRC_PTR and ASM_LINE from the parent frame's saved values.
;
; Called when fill_line_buf returns C=1 (EOF on include file).
; After return, SRC_PTR points back into the parent source (buffer or outer
; include) at the instruction after the .include directive.
; ============================================================================

pop_src_frame:
    ; Compute frame base of current top frame into TMP2
    lda SRC_DEPTH
    asl
    sta TMP2
    asl
    clc
    adc TMP2
    clc
    adc #<SRC_STACK
    sta TMP2
    lda #>SRC_STACK
    adc #0
    sta TMP2+1

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
; All check ASM_ERR first; only first error is kept.
; Each routine: loads message address into TMP/TMP+1, falls into set_err_common.

set_err_deep:
    lda #<err_deep_txt
    sta TMP
    lda #>err_deep_txt
    sta TMP+1
    jmp set_err_common

set_err_phase:
    lda #<err_phase_txt
    sta TMP
    lda #>err_phase_txt
    sta TMP+1
    jmp set_err_common

set_err_truncate:
    lda #<err_truncate_txt
    sta TMP
    lda #>err_truncate_txt
    sta TMP+1
    jmp set_err_common

set_err_syntax:
    lda #<err_syntax_txt
    sta TMP
    lda #>err_syntax_txt
    sta TMP+1
    jmp set_err_common

set_err_value:
    lda #<err_value_txt
    sta TMP
    lda #>err_value_txt
    sta TMP+1
    jmp set_err_common

set_err_symbol:
    lda #<err_symbol_txt
    sta TMP
    lda #>err_symbol_txt
    sta TMP+1
    jmp set_err_common

set_err_mnemonic:
    lda #<err_mnem_txt
    sta TMP
    lda #>err_mnem_txt
    sta TMP+1
    jmp set_err_common

set_err_unknown:
    lda #<err_unknown_txt
    sta TMP
    lda #>err_unknown_txt
    sta TMP+1
    jmp set_err_common

set_err_operand:
    lda #<err_operand_txt
    sta TMP
    lda #>err_operand_txt
    sta TMP+1
    jmp set_err_common

set_err_mode:
    lda #<err_mode_txt
    sta TMP
    lda #>err_mode_txt
    sta TMP+1
    jmp set_err_common

set_err_range:
    lda #<err_range_txt
    sta TMP
    lda #>err_range_txt
    sta TMP+1
    jmp set_err_common

set_err_io:
    lda #<err_io_txt
    sta TMP
    lda #>err_io_txt
    sta TMP+1
    ; fall through

set_err_common:
    lda ASM_ERR
    bne @already               ; only record first error
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

; Error message strings (screen codes, zero-terminated, max 20 chars)
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

; ============================================================================
; Linker config note: use modasm.cfg with
;   MEMORY { LOADADDR: start=$A000, size=2; CODE: start=$A000, size=$2000; }
;   SEGMENTS { LOADADDR: load=LOADADDR; CODE: load=CODE; }
; ============================================================================
