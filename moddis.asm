; ============================================================================
; moddis.asm  -  6502 disassembler module for PETProject
;
; Loaded at $A000 by the editor (BASIC ROM paged out: $01=$36).
; Entry: JMP $A000
;
; Input (via MOD_* param block at $0212-$0220):
;   MOD_BUF_LO/HI    = work_buf start (PRG binary, first 2 bytes = load addr)
;   MOD_GAP_START_*  = end of PRG content in work_buf
;   MOD_GAP_END_*    = work_buf_end (unused by MODDIS but passed in)
;   MOD_BUF_END_*    = work_buf_end
;
; Output:
;   work_buf overwritten with disassembly source text (PETSCII, CR-terminated lines)
;   MOD_NEW_END_LO/HI = end of output text
;   MOD_STATUS = $02 on success, $01 on error
;
; Source format per instruction (fits 40 cols):
;   "        MNEM OPERAND   ;XXXX:XX XX XX\r"
;    ^8sp    ^4   ^varies   ^comment
;
; Labels: not generated in v1 - branches/jumps show target address.
;
; Staging: $A300-$AFFF (~3.5KB). Output copied back to work_buf when done.
; ZP usage: $FB/$FC = SRC_PTR, $3A-$3F = scratch (saved/restored).
;
; Mode constants (matching modasm.asm):
;   IMP=0 ACC=1 IMM=2 ZP=3 ZPX=4 ZPY=5 ABS=6 ABX=7 ABY=8 IND=9 IZX=10 IZY=11 REL=12
; ============================================================================

.setcpu "6502"

; ---- Parameter block ($0212-$0220) ----
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
MOD_STATUS       = $021E
MOD_NEW_END_LO   = $021F
MOD_NEW_END_HI   = $0220

; ---- Kernal ----
CHROUT           = $FFD2

; ---- ZP ----
SRC_PTR          = $FB          ; lo (hi=$FC) - source walker
DST_PTR          = $FD          ; output pointer lo (hi at $FE); consecutive pair for (addr),y
TMP              = $3A          ; scratch (hi=$3B)
TMP2             = $3C          ; scratch (hi=$3D)
TMP3             = $3E          ; scratch (hi=$3F)

; ---- ZP save area and disassembler state ----
; CRITICAL: These MUST be placed outside the executable code area.
; The ZP save loop writes to ZP_SAVE,x which would corrupt code bytes
; if ZP_SAVE overlaps with instructions. MODDIS code ends around $A7A0,
; staging starts at $A800, so $A7C0-$A7FF is the safe zone.
ZP_SAVE          = $A7C0        ; 10 bytes: saves $3A-$3F, $FB-$FE

; ---- Disassembler state (same safe zone, past code end) ----
DIS_PC_LO        = $A7CA        ; current PC lo
DIS_PC_HI        = $A7CB        ; current PC hi
DIS_SRC_END_LO   = $A7CC        ; end of source binary lo (= GAP_START)
DIS_SRC_END_HI   = $A7CD        ; end of source binary hi
DIS_BUF_LO       = $A7CE        ; work_buf base lo
DIS_BUF_HI       = $A7CF        ; work_buf base hi
DIS_BUF_END_LO   = $A7D0        ; work_buf_end lo
DIS_BUF_END_HI   = $A7D1        ; work_buf_end hi
DIS_SPINNER      = $A7D2        ; 8-bit down-counter; wraps → color flip
DIS_SPIN_IDX     = $A7D3        ; current color: $01=white $07=yellow (toggles)

SPIN_COLOR_A     = $01          ; white  (status bar default)
SPIN_COLOR_B     = $00          ; black
SPIN_CELL        = $D800        ; color RAM: row 0, col 39 (top-right)

; ---- Staging buffer ----
; No longer used — disassembly is written directly to work_buf.
; DST_PTR (TMP2/TMP3) starts at work_buf and advances as text is emitted.
; Since text output >> binary input in size, DST always stays ahead of SRC.
STAGING          = $A800        ; kept as constant for reference only
STAGING_END      = $B000        ; kept as constant for reference only

; ---- Mode constants ----
MODE_IMP         = 0
MODE_ACC         = 1
MODE_IMM         = 2
MODE_ZP          = 3
MODE_ZPX         = 4
MODE_ZPY         = 5
MODE_ABS         = 6
MODE_ABX         = 7
MODE_ABY         = 8
MODE_IND         = 9
MODE_IZX         = 10
MODE_IZY         = 11
MODE_REL         = 12

; ============================================================================
.segment "LOADADDR"
    .word $A000

.segment "CODE"

    jmp disassemble

; ============================================================================
; disassemble - main entry point
; ============================================================================

disassemble:
    ; Disable IRQ immediately. The Kernal IRQ handler uses $FB/$FC as a scratch
    ; pointer for cursor blink — it would corrupt SRC_PTR mid-disassembly.
    sei

    ; Verify magic
    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq :+
    cli
    rts                         ; no magic - silent return
:
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

    ; Copy params
    lda MOD_BUF_LO
    sta DIS_BUF_LO
    lda MOD_BUF_HI
    sta DIS_BUF_HI
    lda MOD_BUF_END_LO
    sta DIS_BUF_END_LO
    lda MOD_BUF_END_HI
    sta DIS_BUF_END_HI

    ; Source ends at GAP_START (end of loaded PRG content)
    lda MOD_GAP_START_LO
    sta DIS_SRC_END_LO
    lda MOD_GAP_START_HI
    sta DIS_SRC_END_HI

    ; SRC_PTR = work_buf (start of PRG binary)
    lda DIS_BUF_LO
    sta SRC_PTR
    lda DIS_BUF_HI
    sta SRC_PTR+1

    ; Read 2-byte PRG load address from first two bytes
    ldy #0
    lda (SRC_PTR),y
    sta DIS_PC_LO
    iny
    lda (SRC_PTR),y
    sta DIS_PC_HI

    ; Advance SRC_PTR past the 2-byte header
    jsr inc_src_ptr
    jsr inc_src_ptr

    ; DST_PTR (TMP2/TMP3) starts at work_buf.
    ; We write disassembly output directly into work_buf, reading ahead of
    ; where we write (output text >> binary bytes, so no overlap possible).
    ; This eliminates the staging buffer and copy step entirely.
    lda DIS_BUF_LO
    sta DST_PTR
    lda DIS_BUF_HI
    sta DST_PTR+1

    ; Emit ".org $XXXX\r" as the first output line, using the PRG load address
    ; stored in DIS_PC_LO/HI.  This is essential: without it MODASM reassembles
    ; from PC=$0801, making every branch target wrong and out-of-range.
    ; Format: ".org $XXXX\r"  (10 bytes + CR)
    lda #$2E                    ; '.'
    jsr emit_dst
    lda #$4F                    ; 'O'
    jsr emit_dst
    lda #$52                    ; 'R'
    jsr emit_dst
    lda #$47                    ; 'G'
    jsr emit_dst
    lda #$20                    ; ' '
    jsr emit_dst
    lda #$24                    ; '$'
    jsr emit_dst
    lda DIS_PC_HI
    jsr emit_hex_byte           ; hi byte of load address
    lda DIS_PC_LO
    jsr emit_hex_byte           ; lo byte of load address
    lda #$0D                    ; CR
    jsr emit_dst

    ; Init activity spinner
    lda #0
    sta DIS_SPINNER
    lda #SPIN_COLOR_A
    sta DIS_SPIN_IDX
    ; ---- Main disassembly loop ----
@dis_loop:
    ; Check: SRC_PTR >= DIS_SRC_END? (reached end of binary)
    lda SRC_PTR+1
    cmp DIS_SRC_END_HI
    bcc @not_end
    bne @done                   ; hi byte: src > end
    lda SRC_PTR
    cmp DIS_SRC_END_LO
    bcs @done                   ; lo byte: src >= end
@not_end:

    ; Check: DST_PTR >= work_buf_end? (output buffer full)
    ; Also catch wrap-around: if TMP3 < DIS_BUF_HI, we've wrapped.
    lda DST_PTR+1
    cmp DIS_BUF_HI          ; TMP3 < work_buf hi → wrapped (impossible normally)
    bcc @done_overflow
    cmp DIS_BUF_END_HI      ; TMP3 >= work_buf_end hi → overflow
    bcs @done_overflow

    ; Activity spinner — toggle status-bar corner color every 256 instructions
    inc DIS_SPINNER
    lda DIS_SPINNER
    and #$0F
    bne @no_spin
    lda DIS_SPIN_IDX
    eor #(SPIN_COLOR_A ^ SPIN_COLOR_B)  ; $01 XOR $07 = $06 — toggles between the two
    sta DIS_SPIN_IDX
    sta SPIN_CELL
@no_spin:

    ; Fetch opcode
    ldy #0
    lda (SRC_PTR),y
    sta TMP                     ; TMP = opcode

    ; Look up mnemonic index and mode
    tax
    lda mnem_tab,x              ; mnemonic index
    sta TMP+1                   ; TMP+1 = mnem_idx
    lda mode_tab,x              ; addressing mode
    sta TMP2+1                  ; TMP2+1 = mode (TMP3 is DST_PTR hi - safe, mode < $10)

    ; Check for illegal opcode
    lda TMP+1
    cmp #$FF
    bne :+
    ; Illegal: emit as .BYTE $XX
    jsr emit_illegal
    jsr inc_src_ptr
    jmp @dis_loop
:
    ; Get instruction size from mode
    ldx TMP2+1                  ; mode
    lda size_tab,x
    sta TMP3+1                  ; TMP3+1 = size (1,2,3) - TMP3 is DST hi, TMP3+1 is separate

    ; Emit the line
    jsr emit_line

    ; Advance SRC_PTR by instruction size
    lda TMP3+1
    tax
@adv:
    jsr inc_src_ptr
    dex
    bne @adv

    ; Advance PC by instruction size
    lda TMP3+1
    clc
    adc DIS_PC_LO
    sta DIS_PC_LO
    bcc :+
    inc DIS_PC_HI
:
    jmp @dis_loop

@done_overflow:
    ; DST_PTR hit the limit. If it wrapped below work_buf hi, reset to
    ; work_buf so MOD_NEW_END is at least valid (empty output).
    lda DST_PTR+1
    cmp DIS_BUF_HI
    bcs @done                   ; TMP3 >= work_buf hi → valid, use as-is
    lda DIS_BUF_LO
    sta DST_PTR
    lda DIS_BUF_HI
    sta DST_PTR+1

@done:
    ; Restore status-bar corner color before returning
    lda #SPIN_COLOR_A
    sta SPIN_CELL
    jsr set_new_end

    ; Restore ZP
    ldx #0
@zprestore:
    lda ZP_SAVE,x
    sta $3A,x
    inx
    cpx #6
    bne @zprestore
    lda ZP_SAVE+6
    sta $FB
    lda ZP_SAVE+7
    sta $FC
    lda ZP_SAVE+8
    sta $FD
    lda ZP_SAVE+9
    sta $FE

    ; Report success
    lda #$02
    sta MOD_STATUS
    cli
    rts

; ============================================================================
; emit_line - emit one disassembly line to staging
;
; TMP     = opcode byte
; TMP+1   = mnemonic index
; TMP2+1  = addressing mode
; TMP3+1  = instruction size
; SRC_PTR = points at opcode byte
; DIS_PC_LO/HI = current PC
; TMP2/TMP3 = DST_PTR
; ============================================================================

emit_line:
    ; 4 spaces indent
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst

    ; Mnemonic (3 chars from mnem_strs table)
    lda TMP+1                   ; mnemonic index
    asl                         ; *2
    adc TMP+1                   ; *3 (C clear since index <= 55, *3 <= 165 < 256)
    tax
    lda mnem_strs,x
    jsr emit_dst
    lda mnem_strs+1,x
    jsr emit_dst
    lda mnem_strs+2,x
    jsr emit_dst

    ; Space after mnemonic
    lda #$20
    jsr emit_dst

    ; Operand based on mode
    lda TMP2+1                  ; mode
    cmp #MODE_IMP
    bne :+
    jmp @op_imp
:   cmp #MODE_ACC
    bne :+
    jmp @op_acc
:   cmp #MODE_IMM
    bne :+
    jmp @op_imm
:   cmp #MODE_ZP
    bne :+
    jmp @op_zp
:   cmp #MODE_ZPX
    bne :+
    jmp @op_zpx
:   cmp #MODE_ZPY
    bne :+
    jmp @op_zpy
:   cmp #MODE_ABS
    bne :+
    jmp @op_abs
:   cmp #MODE_ABX
    bne :+
    jmp @op_abx
:   cmp #MODE_ABY
    bne :+
    jmp @op_aby
:   cmp #MODE_IND
    bne :+
    jmp @op_ind
:   cmp #MODE_IZX
    bne :+
    jmp @op_izx
:   cmp #MODE_IZY
    bne :+
    jmp @op_izy
:   cmp #MODE_REL
    bne :+
    jmp @op_rel
:   jmp @op_done                ; should not reach

@op_imp:
    ; implied: no operand, 3 spaces to align
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jmp @op_done

@op_acc:
    ; accumulator: "A  "
    lda #$41                    ; 'A'
    jsr emit_dst
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jmp @op_done

@op_imm:
    ; immediate: "#$XX"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$23                    ; '#'
    jsr emit_dst
    lda #$24                    ; '$'
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jmp @op_done

@op_zp:
    ; zero page: "$XX"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$24                    ; '$'
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jmp @op_done

@op_zpx:
    ; zero page,X: "$XX,X"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$2C                    ; ','
    jsr emit_dst
    lda #$58                    ; 'X'
    jsr emit_dst
    jmp @op_done

@op_zpy:
    ; zero page,Y: "$XX,Y"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$2C
    jsr emit_dst
    lda #$59                    ; 'Y'
    jsr emit_dst
    jmp @op_done

@op_abs:
    ; absolute: "$XXXX"
    ldy #1
    lda (SRC_PTR),y
    sta TMP+1                   ; save lo (reuse, mnem_idx no longer needed)
    iny
    lda (SRC_PTR),y
    tax                         ; hi
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte           ; hi byte first
    lda TMP+1
    jsr emit_hex_byte           ; then lo byte
    lda #$20
    jsr emit_dst
    jmp @op_done

@op_abx:
    ; absolute,X: "$XXXX,X"
    ldy #1
    lda (SRC_PTR),y
    sta TMP+1
    iny
    lda (SRC_PTR),y
    tax
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda TMP+1
    jsr emit_hex_byte
    lda #$2C
    jsr emit_dst
    lda #$58
    jsr emit_dst
    jmp @op_done

@op_aby:
    ; absolute,Y: "$XXXX,Y"
    ldy #1
    lda (SRC_PTR),y
    sta TMP+1
    iny
    lda (SRC_PTR),y
    tax
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda TMP+1
    jsr emit_hex_byte
    lda #$2C
    jsr emit_dst
    lda #$59
    jsr emit_dst
    jmp @op_done

@op_ind:
    ; indirect: "($XXXX)"
    ldy #1
    lda (SRC_PTR),y
    sta TMP+1
    iny
    lda (SRC_PTR),y
    tax
    lda #$28                    ; '('
    jsr emit_dst
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda TMP+1
    jsr emit_hex_byte
    lda #$29                    ; ')'
    jsr emit_dst
    jmp @op_done

@op_izx:
    ; (indirect,X): "($XX,X)"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$28
    jsr emit_dst
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$2C
    jsr emit_dst
    lda #$58
    jsr emit_dst
    lda #$29
    jsr emit_dst
    jmp @op_done

@op_izy:
    ; (indirect),Y: "($XX),Y"
    ldy #1
    lda (SRC_PTR),y
    tax
    lda #$28
    jsr emit_dst
    lda #$24
    jsr emit_dst
    txa
    jsr emit_hex_byte
    lda #$29
    jsr emit_dst
    lda #$2C
    jsr emit_dst
    lda #$59
    jsr emit_dst
    jmp @op_done

@op_rel:
    ldy #1
    lda (SRC_PTR),y             ; signed offset
    sta TMP+1                   ; save offset
    ; target = PC + 2 + signed_offset
    lda DIS_PC_LO
    clc
    adc #2
    sta TMP2+1                  ; target lo temp
    lda DIS_PC_HI
    adc #0
    pha                         ; push target hi — do NOT use TMP3+1 (= instr size!)
    ; add signed offset
    lda TMP+1
    bpl @rel_pos
    ; negative: extend sign
    lda TMP2+1
    adc TMP+1
    sta TMP2+1
    pla
    adc #$FF                    ; propagate borrow
    pha
    jmp @rel_emit
@rel_pos:
    lda TMP2+1
    adc TMP+1
    sta TMP2+1
    pla
    adc #0
    pha
@rel_emit:
    lda #$24
    jsr emit_dst
    pla                         ; pop target hi (TMP3+1 = instr size stays intact)
    jsr emit_hex_byte
    lda TMP2+1                  ; lo
    jsr emit_hex_byte
    lda #$20
    jsr emit_dst
    ; fall through to @op_done

@op_done:
    ; Pad operand field to fixed width, then emit comment with PC and bytes
    ; Comment: " ;XXXX:XX [XX [XX]]"
    lda #$20
    jsr emit_dst
    lda #$3B                    ; ';'
    jsr emit_dst
    ; PC (4 hex digits)
    lda DIS_PC_HI
    jsr emit_hex_byte
    lda DIS_PC_LO
    jsr emit_hex_byte
    lda #$3A                    ; ':'
    jsr emit_dst
    ; Raw bytes (1, 2, or 3)
    ldy #0
    lda (SRC_PTR),y             ; opcode
    jsr emit_hex_byte
    lda TMP3+1                  ; size
    cmp #1
    beq @emit_cr
    lda #$20
    jsr emit_dst
    ldy #1
    lda (SRC_PTR),y
    jsr emit_hex_byte
    lda TMP3+1
    cmp #2
    beq @emit_cr
    lda #$20
    jsr emit_dst
    ldy #2
    lda (SRC_PTR),y
    jsr emit_hex_byte
@emit_cr:
    lda #$0D
    jsr emit_dst
    rts

; ============================================================================
; emit_illegal - emit ".BYTE $XX" for an unrecognised opcode
; ============================================================================

emit_illegal:
    ; Save instr size = 1 for caller's advance
    lda #1
    sta TMP3+1

    ldy #0
    lda (SRC_PTR),y
    sta TMP                     ; opcode byte

    ; "    .BYTE $XX           ;XXXX:XX\r"
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    lda #$2E                    ; '.'
    jsr emit_dst
    lda #$42                    ; 'B'
    jsr emit_dst
    lda #$59                    ; 'Y'
    jsr emit_dst
    lda #$54                    ; 'T'
    jsr emit_dst
    lda #$45                    ; 'E'
    jsr emit_dst
    lda #$20
    jsr emit_dst
    lda #$24
    jsr emit_dst
    lda TMP
    jsr emit_hex_byte
    ; pad + comment
    lda #$20
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    jsr emit_dst
    lda #$3B                    ; ';'
    jsr emit_dst
    lda DIS_PC_HI
    jsr emit_hex_byte
    lda DIS_PC_LO
    jsr emit_hex_byte
    lda #$3A
    jsr emit_dst
    lda TMP
    jsr emit_hex_byte
    ; advance PC by 1
    inc DIS_PC_LO
    bne :+
    inc DIS_PC_HI
:   lda #$0D
    jsr emit_dst
    rts

; ============================================================================
; emit_trunc_notice - emit a comment line indicating output was truncated
; ============================================================================

emit_trunc_notice:
    ldx #0
@loop:
    lda trunc_msg,x
    beq @done
    jsr emit_dst
    inx
    bne @loop
@done:
    rts

trunc_msg:
    ; "; *** DISASSEMBLY TRUNCATED ***\r" in PETSCII
    .byte $3B,$20,$2A,$2A,$2A,$20
    .byte $44,$49,$53,$41,$53,$53,$45,$4D,$42,$4C,$59,$20  ; DISASSEMBLY
    .byte $54,$52,$55,$4E,$43,$41,$54,$45,$44,$20           ; TRUNCATED
    .byte $2A,$2A,$2A,$0D,$00

; ============================================================================
; set_new_end - set MOD_NEW_END from current DST_PTR (TMP2/TMP3)
; Called from @done and @done_overflow after disassembly completes.
; Since we write directly to work_buf (no staging), no copy is needed.
; ============================================================================

set_new_end:
    lda DST_PTR
    sta MOD_NEW_END_LO
    lda DST_PTR+1
    sta MOD_NEW_END_HI
    rts

; ============================================================================
; emit_hex_byte - emit A as two uppercase hex digits to staging
; Clobbers: A, X (Y preserved)
; ============================================================================

emit_hex_byte:
    tax
    lsr
    lsr
    lsr
    lsr
    jsr emit_hex_nib
    txa
    and #$0F
    ; fall through

emit_hex_nib:
    cmp #10
    bcc @digit
    adc #6                      ; 'A'-'0'-10 = 7, but carry set so +6+1=7 -> 'A'
@digit:
    adc #$30                    ; '0'
    jmp emit_dst

; ============================================================================
; emit_dst - write byte A to staging at TMP2/TMP3, advance pointer
; Clobbers: nothing (preserves A, X, Y via stack)
; ============================================================================

emit_dst:
    ; Guard: only write if TMP3 is within work_buf range.
    ; Prevents runaway writes if overflow check fires one iteration late.
    ldy DST_PTR+1
    cpy DIS_BUF_HI
    bcc @emit_discard           ; TMP3 < work_buf hi → below buffer (wrapped)
    cpy DIS_BUF_END_HI
    bcs @emit_discard           ; TMP3 >= work_buf_end hi → past end
    pha
    ldy #0
    sta (DST_PTR),y
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:   pla
    rts
@emit_discard:
    rts

; ============================================================================
; inc_src_ptr - advance SRC_PTR by 1, warping across gap
; ============================================================================

inc_src_ptr:
    inc SRC_PTR
    bne @check_gap
    inc SRC_PTR+1
@check_gap:
    lda SRC_PTR
    cmp MOD_GAP_START_LO
    bne @done
    lda SRC_PTR+1
    cmp MOD_GAP_START_HI
    bne @done
    ; At gap start - warp to gap end
    lda MOD_GAP_END_LO
    sta SRC_PTR
    lda MOD_GAP_END_HI
    sta SRC_PTR+1
@done:
    rts

; ============================================================================
; Opcode decode tables (256 bytes each)
; ============================================================================

; mnemonic index table: opcode -> index into mnem_strs (FF = illegal)
mnem_tab:
    .byte $0A,$22,$FF,$FF,$FF,$22,$02,$FF,$24,$22,$02,$FF,$FF,$22,$02,$FF  ; $00-$0F
    .byte $09,$22,$FF,$FF,$FF,$22,$02,$FF,$0D,$22,$FF,$FF,$FF,$22,$02,$FF  ; $10-$1F
    .byte $1C,$01,$FF,$FF,$06,$01,$27,$FF,$26,$01,$27,$FF,$06,$01,$27,$FF  ; $20-$2F
    .byte $07,$01,$FF,$FF,$FF,$01,$27,$FF,$2C,$01,$FF,$FF,$FF,$01,$27,$FF  ; $30-$3F
    .byte $29,$17,$FF,$FF,$FF,$17,$20,$FF,$23,$17,$20,$FF,$1B,$17,$20,$FF  ; $40-$4F
    .byte $0B,$17,$FF,$FF,$FF,$17,$20,$FF,$0F,$17,$FF,$FF,$FF,$17,$20,$FF  ; $50-$5F
    .byte $2A,$00,$FF,$FF,$FF,$00,$28,$FF,$25,$00,$28,$FF,$1B,$00,$28,$FF  ; $60-$6F
    .byte $0C,$00,$FF,$FF,$FF,$00,$28,$FF,$2E,$00,$FF,$FF,$FF,$00,$28,$FF  ; $70-$7F
    .byte $FF,$2F,$FF,$FF,$31,$2F,$30,$FF,$16,$FF,$35,$FF,$31,$2F,$30,$FF  ; $80-$8F
    .byte $03,$2F,$FF,$FF,$31,$2F,$30,$FF,$37,$2F,$36,$FF,$FF,$2F,$FF,$FF  ; $90-$9F
    .byte $1F,$1D,$1E,$FF,$1F,$1D,$1E,$FF,$33,$1D,$32,$FF,$1F,$1D,$1E,$FF  ; $A0-$AF
    .byte $04,$1D,$FF,$FF,$1F,$1D,$1E,$FF,$10,$1D,$34,$FF,$1F,$1D,$1E,$FF  ; $B0-$BF
    .byte $13,$11,$FF,$FF,$13,$11,$14,$FF,$1A,$11,$15,$FF,$13,$11,$14,$FF  ; $C0-$CF
    .byte $08,$11,$FF,$FF,$FF,$11,$14,$FF,$0E,$11,$FF,$FF,$FF,$11,$14,$FF  ; $D0-$DF
    .byte $12,$2B,$FF,$FF,$12,$2B,$18,$FF,$19,$2B,$21,$FF,$12,$2B,$18,$FF  ; $E0-$EF
    .byte $05,$2B,$FF,$FF,$FF,$2B,$18,$FF,$2D,$2B,$FF,$FF,$FF,$2B,$18,$FF  ; $F0-$FF

; addressing mode table: opcode -> mode constant
mode_tab:
    .byte $00,$0A,$FF,$FF,$FF,$03,$03,$FF,$00,$02,$01,$FF,$FF,$06,$06,$FF  ; $00-$0F
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $10-$1F
    .byte $06,$0A,$FF,$FF,$03,$03,$03,$FF,$00,$02,$01,$FF,$06,$06,$06,$FF  ; $20-$2F
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $30-$3F
    .byte $00,$0A,$FF,$FF,$FF,$03,$03,$FF,$00,$02,$01,$FF,$06,$06,$06,$FF  ; $40-$4F
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $50-$5F
    .byte $00,$0A,$FF,$FF,$FF,$03,$03,$FF,$00,$02,$01,$FF,$09,$06,$06,$FF  ; $60-$6F
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $70-$7F
    .byte $FF,$0A,$FF,$FF,$03,$03,$03,$FF,$00,$FF,$00,$FF,$06,$06,$06,$FF  ; $80-$8F
    .byte $0C,$0B,$FF,$FF,$04,$04,$05,$FF,$00,$08,$00,$FF,$FF,$07,$FF,$FF  ; $90-$9F
    .byte $02,$0A,$02,$FF,$03,$03,$03,$FF,$00,$02,$00,$FF,$06,$06,$06,$FF  ; $A0-$AF
    .byte $0C,$0B,$FF,$FF,$04,$04,$05,$FF,$00,$08,$00,$FF,$07,$07,$08,$FF  ; $B0-$BF
    .byte $02,$0A,$FF,$FF,$03,$03,$03,$FF,$00,$02,$00,$FF,$06,$06,$06,$FF  ; $C0-$CF
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $D0-$DF
    .byte $02,$0A,$FF,$FF,$03,$03,$03,$FF,$00,$02,$00,$FF,$06,$06,$06,$FF  ; $E0-$EF
    .byte $0C,$0B,$FF,$FF,$FF,$04,$04,$FF,$00,$08,$FF,$FF,$FF,$07,$07,$FF  ; $F0-$FF

; instruction size by addressing mode
; IMP=0 ACC=1 IMM=2 ZP=3 ZPX=4 ZPY=5 ABS=6 ABX=7 ABY=8 IND=9 IZX=10 IZY=11 REL=12
size_tab:
    .byte 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2

; mnemonic strings: 56 * 3 bytes, uppercase PETSCII (= ASCII for A-Z)
mnem_strs:
    .byte "ADC","AND","ASL","BCC","BCS","BEQ","BIT","BMI"
    .byte "BNE","BPL","BRK","BVC","BVS","CLC","CLD","CLI"
    .byte "CLV","CMP","CPX","CPY","DEC","DEX","DEY","EOR"
    .byte "INC","INX","INY","JMP","JSR","LDA","LDX","LDY"
    .byte "LSR","NOP","ORA","PHA","PHP","PLA","PLP","ROL"
    .byte "ROR","RTI","RTS","SBC","SEC","SED","SEI","STA"
    .byte "STX","STY","TAX","TAY","TSX","TXA","TXS","TYA"
