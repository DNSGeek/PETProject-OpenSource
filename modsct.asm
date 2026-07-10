; ============================================================================
; modsct.asm — Script Tokenizer for PETProject
;
; Converts a BASIC-like script from the editor gap buffer into tokenized form
; and stores it in the REU. The companion module modscr.asm (Script Runner)
; reads the REU output, installs keyword handlers at $C000, stashes the IDE,
; and hands off to the BASIC interpreter.
;
; Loads at $A000 (up to 8KB: $A000-$BFFF).
; Requires: REU (1700/1764/1750 or compatible). Errors without one.
;
; Memory layout while active:
;   $A000-$AFFF : code + kwtab + linker-reserved scratch (REU param block,
;                 include table — see the .res block at end of file)
;   $B000-$BFFF : staging buffer — tokenized output before DMA to REU
;
; REU layout (linear addresses):
;   $000000-$003FFF : main tokenized script (up to 16KB)
;   $004000-$007FFF : include pool — packed tokenized includes (up to 16KB)
;   $008000-$0080DF : include table (16 entries × 14 bytes = 224 bytes)
;   $008100-$00810F : script metadata block (magic, lengths, counts, version)
;   $009000+        : IDE snapshot — written by modscr, not us
;
; MOD_STATUS return values:
;   $01 : Error (see status bar — REU absent, disk error, syntax)
;   $05 : Script tokenized to REU successfully
;
; Extended token assignments ($CC-$D8):
;   $CC ASSEMBLE  $CD INCLUDE  $CE RUNPROG  $CF SCRATCH
;   $D0 DELETE    $D1 EXISTS   $D2 RENAME   $D3 STATUS
;   $D4 DRIVE     $D5 ONERR    $D6 PAUSE    $D7 COPY  $D8 DIR
;
; kwtab ordering: longest-first within groups; prefix conflicts resolved:
;   RUNPROG (7) before RUN (3)  — RUN is a prefix of RUNPROG
;   ONERR   (5) before ON  (2)  — ON  is a prefix of ONERR
;
; Linker config (modsct.cfg):
;   MEMORY { LOADADDR: start=$A000, size=2; CODE: start=$A000, size=$2000; }
;   SEGMENTS { LOADADDR: load=LOADADDR; CODE: load=CODE; }
; ============================================================================

.setcpu "6502"

; ---- Module parameter block ----
MOD_MAGIC        = $0212
MOD_MAGIC_VAL    = $4D
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

; ---- Kernal ----
SETLFS  = $FFBA
SETNAM  = $FFBD
OPEN    = $FFC0
CHKIN   = $FFC6
CHRIN   = $FFCF
CLRCHN  = $FFCC
CLOSE   = $FFC3
READST  = $FFB7

; ---- REU registers ----
REU_STATUS  = $DF00
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

; REU commands: bit 7 = execute, bits 1-0 = type
REU_CMD_STASH = $90    ; C64 -> REU (EXECUTE | FF00-trigger-disable, immediate)
REU_CMD_FETCH = $91    ; REU -> C64 (EXECUTE | FF00-trigger-disable, immediate)

; ---- REU layout (linear addresses, 3-byte) ----
REU_SCRIPT_LO   = $00 ; $000000: main tokenized script
REU_SCRIPT_MED  = $00
REU_SCRIPT_HI   = $00

REU_IPOOL_LO    = $00 ; $004000: include pool start
REU_IPOOL_MED   = $40
REU_IPOOL_HI    = $00

REU_ITABLE_LO   = $00 ; $008000: include table (224 bytes)
REU_ITABLE_MED  = $80
REU_ITABLE_HI   = $00

REU_META_LO     = $00 ; $008100: metadata block
REU_META_MED    = $81
REU_META_HI     = $00

; ---- Metadata block offsets ----
META_MAGIC0     = 0   ; $53 'S'
META_MAGIC1     = 1   ; $43 'C'
META_SCLEN_LO   = 2   ; main script tokenized length lo
META_SCLEN_HI   = 3   ; main script tokenized length hi
META_ICOUNT     = 4   ; number of includes tokenized
META_VERSION    = 5   ; $01
META_SIZE       = 6

; ---- ZP — same layout as modtok (no conflict between phases) ----
LINENO      = $3A   ; line number lo (hi=$3B); = KW_TOKEN in try_keyword
KW_TOKEN    = $3A
KW_XSAVE    = $3B
TMP16       = $3C   ; general 16-bit scratch lo (hi=$3D)
IN_STRING   = $3E
AFTER_REM   = $3F
LINK_PTR    = $F7   ; lo (hi=$F8) — link word back-patch pointer / scan pointer
BASIC_ADDR  = $F9   ; lo (hi=$FA) — running C64 address tracker
SRC_PTR     = $FB   ; lo (hi=$FC) — source walker
DST_PTR     = $FD   ; lo (hi=$FE) — staging output pointer
OVFLAG      = $FF   ; staging overflow flag ($FF = overflowed, output invalid)

; ---- Module scratch RAM ----
; The REU parameter block and include table are RESERVED INSIDE THE IMAGE
; (see the .res block at the end of this file) instead of being fixed
; addresses "above the code".  The fixed-address scheme already failed
; once: the assembled binary grew past $A7F0 and the very first DMA
; overwrote the tail of kwtab and its sentinel, corrupting every later
; keyword lookup.  As linker-placed labels they can never overlap code,
; and the module.cfg size limit plus the .assert below catch any growth.
; INCL_ENTRY_SZ / INCL_MAX stay as constants:
INCL_ENTRY_SZ = 14
INCL_MAX      = 16

; Script staging buffer: tokenized output before DMA to REU
STAGING       = $B000   ; 4KB: $B000-$BFFF
STAGING_END   = $C000

; Include source load buffer: reuse gap buffer area after main tokenization
LOAD_BUF      = $0801
LOAD_BUF_END  = $9FFF

; Logical file number for disk I/O
MOD_LA        = 5

BASIC_START   = $0801

; ============================================================================

.segment "LOADADDR"
    .word $A000

.segment "CODE"

    jmp tokenize

; ============================================================================
; tokenize — main entry point
; ============================================================================

tokenize:
    sei                          ; protect ZP and REU setup from IRQ

    lda MOD_MAGIC
    cmp #MOD_MAGIC_VAL
    beq :+
    jmp @err_bad

:   ; Detect REU — required
    jsr reu_detect
    bcs :+
    jmp @err_noreu

:   ; Init include pool tracking
    lda #0
    sta INCL_COUNT
    lda #REU_IPOOL_LO
    sta INCL_POOL_LO
    lda #REU_IPOOL_MED
    sta INCL_POOL_MED
    lda #REU_IPOOL_HI
    sta INCL_POOL_HI

    ; ---- Phase 1: tokenize main script to STAGING ----
    jsr tok_main_script          ; tokenizes gap buffer → STAGING; sets TMP16=length
    bcc :+
    jmp @err_bad                 ; tokenization error (shouldn't normally happen)

:   ; Save script length for metadata
    lda TMP16
    sta tok_sclen_lo             ; stash for metadata
    lda TMP16+1
    sta tok_sclen_hi

    ; ---- Phase 2: DMA staging → REU script slot ----
    lda #<STAGING
    sta REU_PB_C64LO
    lda #>STAGING
    sta REU_PB_C64HI
    lda #REU_SCRIPT_LO
    sta REU_PB_REULO
    lda #REU_SCRIPT_MED
    sta REU_PB_REUME
    lda #REU_SCRIPT_HI
    sta REU_PB_REUHI
    lda TMP16
    sta REU_PB_LENLO
    lda TMP16+1
    sta REU_PB_LENHI
    lda #REU_CMD_STASH
    jsr reu_exec

    ; ---- Phase 3: scan staging for INCLUDE tokens, process each ----
    ; STAGING still has the tokenized main script; scan it in C64 RAM.
    jsr scan_for_includes
    bcc :+
    jmp @err_disk               ; disk error loading an include

:   ; ---- Phase 4: write include table and metadata to REU ----
    jsr write_include_table
    jsr write_metadata

    ; Success
    cli
    lda #$05                    ; MOD_STATUS $05 = script tokenized to REU
    sta MOD_STATUS
    rts

@err_noreu:
    cli
    jsr set_status_noreu
    lda #$01
    sta MOD_STATUS
    rts

@err_disk:
    cli
    jsr set_status_disk
    lda #$01
    sta MOD_STATUS
    rts

@err_bad:
    cli
    lda #$01
    sta MOD_STATUS
    rts

; Saved script length (used in metadata)
tok_sclen_lo: .byte 0
tok_sclen_hi: .byte 0

; ============================================================================
; tok_main_script — tokenize gap buffer to STAGING.
; Source: MOD_BUF_LO/HI .. MOD_GAP_START_LO/HI (text before gap = all content).
; Output: STAGING contains tokenized BASIC (no PRG load-address header).
;         TMP16 = byte count of tokenized output.
; C=0 on success, C=1 on error.
; ============================================================================

tok_main_script:
    ; Source: gap buffer start → gap start (text before gap = all content)
    lda MOD_BUF_LO
    sta SRC_PTR
    lda MOD_BUF_HI
    sta SRC_PTR+1

    ; End of source = gap start (text after gap is empty post-cursor space)
    ; Use MOD_GAP_START as the source end — it marks end of text content.
    ; If gap is at the very start (empty buffer), MOD_GAP_START = MOD_BUF.
    ; Also honor MOD_GAP_END to MOD_BUF_END for text after cursor.
    ; For now: source = [MOD_BUF .. MOD_GAP_START) ∪ [MOD_GAP_END .. MOD_BUF_END)
    ; Simple approach: walk SRC_PTR, skip gap in tok_src_peek (like modasm src_peek).

    ; Store gap bounds so tok_src_peek can skip them
    lda MOD_GAP_START_LO
    sta tok_gap_s_lo
    lda MOD_GAP_START_HI
    sta tok_gap_s_hi
    lda MOD_GAP_END_LO
    sta tok_gap_e_lo
    lda MOD_GAP_END_HI
    sta tok_gap_e_hi
    lda MOD_BUF_END_LO
    sta tok_src_end_lo
    lda MOD_BUF_END_HI
    sta tok_src_end_hi

    ; Output: staging buffer
    lda #<STAGING
    sta DST_PTR
    lda #>STAGING
    sta DST_PTR+1
    lda #0
    sta OVFLAG

    ; BASIC_ADDR tracks the runtime $0801-based address of each emitted byte
    lda #<BASIC_START
    sta BASIC_ADDR
    lda #>BASIC_START
    sta BASIC_ADDR+1

; ---- @line_loop ----
@line_loop:
    jsr tok_src_at_end
    beq :+                       ; zero = NOT at end → continue
    jmp @all_done
:
    ; Check for blank/empty line — skip bare CRs
    jsr tok_src_peek
    bne :+                       ; non-zero = not empty → continue
    jmp @all_done
:
    cmp #$0D
    bne @parse_lineno
    jsr tok_src_advance
    jmp @line_loop

@parse_lineno:
    lda #0
    sta LINENO
    sta LINENO+1

@digit_loop:
    jsr tok_src_peek
    cmp #'0'
    bcc @digits_done
    cmp #'9'+1
    bcs @digits_done
    sec
    sbc #'0'
    pha
    ; LINENO = LINENO*10 + digit  (same multiply as modtok)
    lda LINENO
    asl a
    sta TMP16
    lda LINENO+1
    rol a
    sta TMP16+1
    asl LINENO
    rol LINENO+1
    asl LINENO
    rol LINENO+1
    asl LINENO
    rol LINENO+1
    lda LINENO
    clc
    adc TMP16
    sta LINENO
    lda LINENO+1
    adc TMP16+1
    sta LINENO+1
    pla
    clc
    adc LINENO
    sta LINENO
    bcc :+
    inc LINENO+1
:   jsr tok_src_advance
    jmp @digit_loop

@digits_done:
@skip_spaces:
    jsr tok_src_peek
    cmp #$20
    bne @begin_line
    jsr tok_src_advance
    jmp @skip_spaces

@begin_line:
    ; Save DST_PTR as LINK_PTR for back-patching link word
    lda DST_PTR
    sta LINK_PTR
    lda DST_PTR+1
    sta LINK_PTR+1

    lda #0
    jsr emit_byte        ; link word lo placeholder
    jsr emit_byte        ; link word hi placeholder
    lda LINENO
    jsr emit_byte        ; line number lo
    lda LINENO+1
    jsr emit_byte        ; line number hi

    ; Advance BASIC_ADDR past the 4-byte header
    lda BASIC_ADDR
    clc
    adc #4
    sta BASIC_ADDR
    bcc :+
    inc BASIC_ADDR+1
:
    lda #0
    sta IN_STRING
    sta AFTER_REM
    sta tok_after_data

; ---- @token_loop ----
@token_loop:
    jsr tok_src_peek
    bne :+
    jmp @all_done
:   cmp #$0D
    bne :+
    jmp @end_line
:
    lda AFTER_REM
    bne @literal

    ; Track quote toggle
    jsr tok_src_peek
    cmp #$22
    bne @no_quote
    lda IN_STRING
    eor #$FF
    sta IN_STRING
    lda #$22
    jsr tok_src_advance
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop
@no_quote:

    lda IN_STRING
    bne @literal

    ; DATA statements: real CRUNCH copies everything after DATA literally
    ; until ':' (outside quotes) or end of line.  Tokenizing here corrupts
    ; the data — READ returns garbage token bytes at run time.
    lda tok_after_data
    beq @not_data
    jsr tok_src_peek
    cmp #':'
    bne @literal                ; still inside the DATA item list
    lda #0
    sta tok_after_data          ; ':' ends the statement...
    jmp @literal                ; ...and is itself emitted literally
@not_data:

    ; '?' is BASIC shorthand for PRINT — CRUNCH tokenizes it to $99.
    jsr tok_src_peek
    cmp #'?'
    bne @not_qmark
    jsr tok_src_advance
    lda #$99                    ; PRINT token
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop
@not_qmark:

    ; Attempt keyword match
    jsr try_keyword
    bcc @literal

    ; Keyword matched: A = token
    cmp #$CD              ; INCLUDE — not supported: the pipeline is
    bne :+                ; unfinished and corrupted the IDE image, so
    jmp @include_err      ; fail loudly at tokenize time instead
:   cmp #$8F              ; REM token — rest of LINE is literal
    bne :+
    ldx #$FF
    stx AFTER_REM
:   cmp #$83              ; DATA — rest of STATEMENT is literal
    bne :+
    ldx #$FF
    stx tok_after_data
:   jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@include_err:
    ; INCLUDE reached the interpreter only through this tokenizer, so
    ; refusing it here fully disables the feature: scan_for_includes
    ; never sees an INCLUDE token and phase 3 is a safe no-op.
    jsr set_status_incl
    sec
    rts

@literal:
    jsr tok_src_peek
    jsr tok_src_advance
    jsr emit_byte
    jsr inc_basic_addr
    jmp @token_loop

@end_line:
    jsr tok_src_advance   ; consume CR
    lda #0
    jsr emit_byte         ; null terminator
    jsr inc_basic_addr

    ; Back-patch link word with current BASIC_ADDR
    ldy #0
    lda BASIC_ADDR
    sta (LINK_PTR),y
    iny
    lda BASIC_ADDR+1
    sta (LINK_PTR),y

    jmp @line_loop

@all_done:
    lda #0
    jsr emit_byte
    jsr emit_byte         ; $00 $00 end-of-program marker

    ; NOTE: do NOT zero LINK_PTR here. The last line's link word was already
    ; back-patched in @end_line to point at this end-of-program marker. BASIC
    ; detects end-of-program by following that link and finding the $00 $00
    ; marker. Zeroing the last line's link word would orphan it and make BASIC
    ; stop one line early.

    ; Compute byte count: DST_PTR - STAGING
    lda DST_PTR
    sec
    sbc #<STAGING
    sta TMP16
    lda DST_PTR+1
    sbc #>STAGING
    sta TMP16+1

    ; If staging overflowed, the tokenized output is truncated and must not
    ; be deployed — report failure (C=1) so the caller errors out instead
    ; of stashing a broken script to the REU.
    lda OVFLAG
    beq :+
    sec
    rts
:
    clc
    rts

; Gap-skipping source walker state (set up before tok_main_script)
tok_gap_s_lo:   .byte 0
tok_gap_s_hi:   .byte 0
tok_gap_e_lo:   .byte 0
tok_gap_e_hi:   .byte 0
tok_src_end_lo: .byte 0
tok_src_end_hi: .byte 0

; ============================================================================
; tok_src_peek — read byte at SRC_PTR, skipping the gap. Returns A=0 at end.
; ============================================================================

tok_src_peek:
    ; If SRC_PTR == gap start: jump to gap end
    lda SRC_PTR+1
    cmp tok_gap_s_hi
    bne @check_end
    lda SRC_PTR
    cmp tok_gap_s_lo
    bne @check_end
    lda tok_gap_e_lo
    sta SRC_PTR
    lda tok_gap_e_hi
    sta SRC_PTR+1
@check_end:
    lda SRC_PTR+1
    cmp tok_src_end_hi
    bcc @read
    bne @at_end
    lda SRC_PTR
    cmp tok_src_end_lo
    bcs @at_end
@read:
    ldy #0
    lda (SRC_PTR),y
    ora #0               ; set Z correctly
    rts
@at_end:
    lda #0
    rts

; ============================================================================
; tok_src_advance — advance SRC_PTR by 1
; ============================================================================

tok_src_advance:
    inc SRC_PTR
    bne :+
    inc SRC_PTR+1
:   rts

; ============================================================================
; tok_src_at_end — returns A=$FF if at end, else $00
; ============================================================================

tok_src_at_end:
    ; Skip gap if at gap start
    lda SRC_PTR+1
    cmp tok_gap_s_hi
    bne :+
    lda SRC_PTR
    cmp tok_gap_s_lo
    bne :+
    lda tok_gap_e_lo
    sta SRC_PTR
    lda tok_gap_e_hi
    sta SRC_PTR+1
:
    lda SRC_PTR+1
    cmp tok_src_end_hi
    bcc @not_end
    bne @at_end
    lda SRC_PTR
    cmp tok_src_end_lo
    bcs @at_end
@not_end:
    lda #0
    rts
@at_end:
    lda #$FF
    rts

; ============================================================================
; scan_for_includes — walk STAGING for $CD (INCLUDE) tokens.
; For each one found: extract filename, check table, if new: load+tokenize.
; C=0 on success, C=1 on disk error.
; ============================================================================

scan_for_includes:
    ; Set up scan pointer at start of STAGING
    lda #<STAGING
    sta LINK_PTR
    lda #>STAGING
    sta LINK_PTR+1

    ; End of scan = DST_PTR (set by tok_main_script to one past last byte)
    ; DST_PTR was left pointing just past the $00 $00 end marker

@scan_line:
    ; Check if scan pointer >= DST_PTR (end of staging content)
    lda LINK_PTR+1
    cmp DST_PTR+1
    bcc @not_at_scan_end
    beq :+               ; hi bytes equal — check lo
    jmp @scan_done       ; hi > hi → done
:   lda LINK_PTR
    cmp DST_PTR
    bcc @not_at_scan_end ; lo < lo → not done
    jmp @scan_done       ; lo >= lo → done
@not_at_scan_end:

    ; Read link word lo/hi to advance to next line (skip link + line# = 4 bytes)
    ldy #2               ; byte offset 2 = line number lo (skip link word)
    ; Actually walk byte by byte to handle $00 end-of-line correctly.
    ; Skip 4-byte header (link+lineno)
    jsr scan_advance4

    ; Walk tokens in this line
@scan_token:
    ldy #0
    lda (LINK_PTR),y
    beq @scan_next_line  ; $00 = end of line, advance pointer past it
    cmp #$22             ; quote — skip string literal
    beq @scan_skip_string
    cmp #$8F             ; REM — skip rest of line
    beq @scan_skip_rem
    cmp #$CD             ; INCLUDE token!
    beq @found_include
    jsr scan_advance1
    jmp @scan_token

@scan_skip_string:
    jsr scan_advance1    ; skip opening quote
@scan_str_inner:
    ldy #0
    lda (LINK_PTR),y
    beq @scan_next_line  ; end of line inside string (malformed, skip)
    cmp #$22
    beq @scan_str_end
    jsr scan_advance1
    jmp @scan_str_inner
@scan_str_end:
    jsr scan_advance1    ; skip closing quote
    jmp @scan_token

@scan_skip_rem:
    jsr scan_advance1    ; skip past any remaining bytes until EOL
    ldy #0
    lda (LINK_PTR),y
    bne @scan_skip_rem
    ; fall into @scan_next_line

@scan_next_line:
    jsr scan_advance1    ; skip the $00 end-of-line byte
    jmp @scan_line

@found_include:
    ; LINK_PTR points at $CD. Advance past it.
    jsr scan_advance1
    ; Skip spaces
@skip_sp:
    ldy #0
    lda (LINK_PTR),y
    cmp #$20
    bne @expect_quote
    jsr scan_advance1
    jmp @skip_sp
@expect_quote:
    cmp #$22
    bne @scan_token      ; malformed INCLUDE — no quote, skip it
    jsr scan_advance1    ; skip opening quote
    ; Read filename into INCL_FNAME
    ldy #0
@read_fname:
    lda (LINK_PTR),y
    beq @fname_done      ; EOL — malformed, treat as end of filename
    cmp #$22
    beq @fname_done      ; closing quote
    cpy #7               ; max 8 chars (0-7)
    bcs @skip_fname_char
    sta INCL_FNAME,y
    iny
@skip_fname_char:
    jsr scan_advance1
    jmp @read_fname
@fname_done:
    ; Zero-pad INCL_FNAME to 8 bytes
    sty INCL_FLEN        ; save actual length
    lda #0
@pad_fname:
    cpy #8
    bcs @fname_padded
    sta INCL_FNAME,y
    iny
    bne @pad_fname
@fname_padded:
    ; Advance past closing quote if we stopped on one
    ldy #0
    lda (LINK_PTR),y
    cmp #$22
    bne :+
    jsr scan_advance1
:
    ; Check if already in include table
    jsr find_in_incl_table
    bcs :+               ; carry set = NOT found → process it
    jmp @scan_token      ; carry clear = already in table → skip
:
    ; New include — load, tokenize, store
    jsr load_and_tok_include
    bcs :+               ; carry set = disk error
    jmp @scan_token      ; carry clear = success → continue scan
:   ; Disk error
    sec
    rts

@scan_done:
    clc
    rts

; ============================================================================
; scan_advance1 — advance LINK_PTR by 1
; ============================================================================

scan_advance1:
    inc LINK_PTR
    bne :+
    inc LINK_PTR+1
:   rts

; ============================================================================
; scan_advance4 — advance LINK_PTR by 4 (skip link+lineno header)
; ============================================================================

scan_advance4:
    lda LINK_PTR
    clc
    adc #4
    sta LINK_PTR
    bcc :+
    inc LINK_PTR+1
:   rts

; ============================================================================
; find_in_incl_table — search INCL_TABLE for INCL_FNAME (8-byte padded).
; C=0: found (TMP16 = pointer to entry).
; C=1: not found.
; ============================================================================

find_in_incl_table:
    lda #<INCL_TABLE
    sta TMP16
    lda #>INCL_TABLE
    sta TMP16+1
    ldx INCL_COUNT
    beq @not_found
@loop:
    ldy #0
@cmp:
    lda (TMP16),y
    cmp INCL_FNAME,y
    bne @next
    iny
    cpy #8
    bne @cmp
    clc                  ; found
    rts
@next:
    lda TMP16
    clc
    adc #INCL_ENTRY_SZ
    sta TMP16
    bcc :+
    inc TMP16+1
:   dex
    bne @loop
@not_found:
    sec
    rts

; ============================================================================
; load_and_tok_include — load INCL_FNAME from disk, tokenize to STAGING,
; DMA to REU include pool, add entry to INCL_TABLE.
; C=0 success, C=1 disk error.
; ============================================================================

load_and_tok_include:
    ; Check table not full
    lda INCL_COUNT
    cmp #INCL_MAX
    bcc :+
    jmp @err_full
:
    ; ---- Load source file from disk into LOAD_BUF ----
    lda #MOD_LA
    ldx MOD_DRIVE
    ldy #2               ; SA=2 = read
    jsr SETLFS

    lda INCL_FLEN        ; filename length
    ldx #<INCL_FNAME
    ldy #>INCL_FNAME
    jsr SETNAM

    jsr OPEN
    bcc :+
    jmp @err_disk
:
    ldx #MOD_LA
    jsr CHKIN
    bcc :+
    jmp @err_close
:

    ; Read bytes into LOAD_BUF
    lda #<LOAD_BUF
    sta TMP16
    lda #>LOAD_BUF
    sta TMP16+1

@read_loop:
    jsr READST
    and #$42             ; EOF or error
    bne @read_done
    jsr CHRIN
    ldy #0
    sta (TMP16),y
    inc TMP16
    bne @read_loop
    inc TMP16+1
    jmp @read_loop

@read_done:
    jsr CLRCHN
    lda #MOD_LA
    jsr CLOSE

    ; Calculate source length in INCL_LOAD_LO/HI
    lda TMP16
    sec
    sbc #<LOAD_BUF
    sta INCL_LOAD_LO
    lda TMP16+1
    sbc #>LOAD_BUF
    sta INCL_LOAD_HI

    ; ---- Tokenize LOAD_BUF to STAGING ----
    ; Reuse tok_main_script machinery: point SRC_PTR at LOAD_BUF,
    ; set gap so it's entirely past the end (no gap in include source).
    lda #<LOAD_BUF
    sta SRC_PTR
    lda #>LOAD_BUF
    sta SRC_PTR+1

    ; Gap: set gap_start = gap_end = end of include source (no gap)
    lda TMP16            ; TMP16 still = LOAD_BUF + length (end address)
    sta tok_gap_s_lo
    sta tok_gap_e_lo
    lda TMP16+1
    sta tok_gap_s_hi
    sta tok_gap_e_hi
    sta tok_src_end_lo   ; same end
    lda TMP16+1
    sta tok_src_end_hi

    ; Rewind STAGING output
    lda #<STAGING
    sta DST_PTR
    lda #>STAGING
    sta DST_PTR+1

    lda #<BASIC_START
    sta BASIC_ADDR
    lda #>BASIC_START
    sta BASIC_ADDR+1

    ; Tokenize (reuse the same @line_loop code via a JSR — not possible inline).
    ; Call tok_main_script with current ZP state.
    ; tok_main_script uses SRC_PTR/DST_PTR/etc. that we've just set up.
    jsr tok_main_script  ; returns TMP16 = tokenized length

    ; ---- DMA STAGING → REU include pool ----
    lda #<STAGING
    sta REU_PB_C64LO
    lda #>STAGING
    sta REU_PB_C64HI
    lda INCL_POOL_LO
    sta REU_PB_REULO
    lda INCL_POOL_MED
    sta REU_PB_REUME
    lda INCL_POOL_HI
    sta REU_PB_REUHI
    lda TMP16
    sta REU_PB_LENLO
    lda TMP16+1
    sta REU_PB_LENHI
    lda #REU_CMD_STASH
    jsr reu_exec

    ; ---- Add to include table ----
    ; Compute entry address: INCL_TABLE + INCL_COUNT * INCL_ENTRY_SZ
    lda INCL_COUNT
    ; × 14 = × 8 + × 4 + × 2
    sta TMP16
    lda #0
    sta TMP16+1
    ; TMP16 = count; compute count * 14
    asl TMP16            ; ×2
    rol TMP16+1
    ; save ×2 in $3C (reuse KW_TOKEN area momentarily — done with tokenize phase)
    lda TMP16
    pha
    lda TMP16+1
    pha
    asl TMP16            ; ×4
    rol TMP16+1
    asl TMP16            ; ×8
    rol TMP16+1
    pla                  ; pop ×2 hi
    adc TMP16+1
    sta TMP16+1
    pla                  ; pop ×2 lo
    adc TMP16
    sta TMP16            ; TMP16 = count * 10... wait, need ×14 = ×8+×4+×2
    ; Actually: ×14 = ×8 + ×4 + ×2. Let me redo.
    ; TMP16 currently has count*8 (after the two ASLs above).
    ; We need count*8 + count*4 + count*2. We pulled ×2 from stack.
    ; And TMP16 = count*8 + count*2 now (after the adds above).
    ; That's count*10. Need count*14 = count*10 + count*4.
    ; To get count*4 we need to recompute. Let's just use a simpler approach.
    ; INCL_ENTRY_SZ = 14 — just multiply by repeated addition for small counts.
    ; INCL_COUNT <= 16 so at most 16 additions of 14.
    ; Restart: TMP16 = INCL_COUNT * 14 via loop.
    lda INCL_COUNT
    beq @zero_offset
    tax
    lda #0
    sta TMP16
    sta TMP16+1
@mul14:
    lda TMP16
    clc
    adc #INCL_ENTRY_SZ
    sta TMP16
    bcc :+
    inc TMP16+1
:   dex
    bne @mul14
@zero_offset:
    ; TMP16 now = INCL_COUNT * INCL_ENTRY_SZ
    lda TMP16
    clc
    adc #<INCL_TABLE
    sta TMP16
    lda TMP16+1
    adc #>INCL_TABLE
    sta TMP16+1          ; TMP16 = pointer to new entry

    ; Write 8-byte filename
    ldy #0
@wname:
    lda INCL_FNAME,y
    sta (TMP16),y
    iny
    cpy #8
    bne @wname

    ; Write 3-byte REU offset (current pool position before this include)
    lda INCL_POOL_LO
    sta (TMP16),y
    iny
    lda INCL_POOL_MED
    sta (TMP16),y
    iny
    lda INCL_POOL_HI
    sta (TMP16),y
    iny

    ; Write 2-byte tokenized length
    lda REU_PB_LENLO     ; = TMP16 saved length
    sta (TMP16),y
    iny
    lda REU_PB_LENHI
    sta (TMP16),y
    iny

    ; Write flags byte: $01 = tokenized
    lda #$01
    sta (TMP16),y

    ; Advance pool pointer by tokenized length
    lda INCL_POOL_LO
    clc
    adc REU_PB_LENLO
    sta INCL_POOL_LO
    lda INCL_POOL_MED
    adc REU_PB_LENHI
    sta INCL_POOL_MED
    bcc :+
    inc INCL_POOL_HI
:
    inc INCL_COUNT
    clc
    rts

@err_full:
    ; Table full — treat as soft error, just skip this include
    clc
    rts

@err_close:
    jsr CLRCHN
    lda #MOD_LA
    jsr CLOSE
@err_disk:
    sec
    rts

; ============================================================================
; write_include_table — DMA C64 include table to REU $008000
; ============================================================================

write_include_table:
    lda #<INCL_TABLE
    sta REU_PB_C64LO
    lda #>INCL_TABLE
    sta REU_PB_C64HI
    lda #REU_ITABLE_LO
    sta REU_PB_REULO
    lda #REU_ITABLE_MED
    sta REU_PB_REUME
    lda #REU_ITABLE_HI
    sta REU_PB_REUHI
    lda #<(INCL_ENTRY_SZ * INCL_MAX)
    sta REU_PB_LENLO
    lda #>(INCL_ENTRY_SZ * INCL_MAX)
    sta REU_PB_LENHI
    lda #REU_CMD_STASH
    jsr reu_exec
    rts

; ============================================================================
; write_metadata — build metadata block in STAGING[0..5], DMA to REU $008100
; ============================================================================

write_metadata:
    ; Build 6-byte metadata block at STAGING (reusing it — we're done tokenizing)
    lda #$53             ; 'S'
    sta STAGING+META_MAGIC0
    lda #$43             ; 'C'
    sta STAGING+META_MAGIC1
    lda tok_sclen_lo
    sta STAGING+META_SCLEN_LO
    lda tok_sclen_hi
    sta STAGING+META_SCLEN_HI
    lda INCL_COUNT
    sta STAGING+META_ICOUNT
    lda #$01             ; version
    sta STAGING+META_VERSION

    ; DMA to REU metadata slot
    lda #<STAGING
    sta REU_PB_C64LO
    lda #>STAGING
    sta REU_PB_C64HI
    lda #REU_META_LO
    sta REU_PB_REULO
    lda #REU_META_MED
    sta REU_PB_REUME
    lda #REU_META_HI
    sta REU_PB_REUHI
    lda #META_SIZE
    sta REU_PB_LENLO
    lda #0
    sta REU_PB_LENHI
    lda #REU_CMD_STASH
    jsr reu_exec
    rts

; ============================================================================
; reu_detect — test for REU presence via read/write check on $DF05.
; C=1: REU found. C=0: no REU.
; ============================================================================

reu_detect:
    lda $DF05            ; save current REU address mid register
    pha
    lda #$55
    sta $DF05
    lda $DF05
    tax                  ; save read-back #1
    lda #$AA
    sta $DF05
    lda $DF05
    tay                  ; save read-back #2
    pla
    sta $DF05            ; restore original value
    cpx #$55
    bne @no_reu
    cpy #$AA
    bne @no_reu
    sec
    rts
@no_reu:
    clc
    rts

; ============================================================================
; reu_exec — execute REU transfer using REU_PB_* parameter block.
; On entry: A = REU command ($90=stash, $91=fetch; bit7=execute, bit4=immediate).
; Clobbers A, Y.
; ============================================================================

reu_exec:
    sta REU_PB_CMD       ; command was passed in A by the caller — store it
    ldy #0
    sty REU_INTMASK      ; disable REU interrupts
    sty REU_ADDCTL       ; both C64 and REU addresses increment
    lda REU_PB_C64LO
    sta REU_C64_LO
    lda REU_PB_C64HI
    sta REU_C64_HI
    lda REU_PB_REULO
    sta REU_REU_LO
    lda REU_PB_REUME
    sta REU_REU_MED
    lda REU_PB_REUHI
    sta REU_REU_HI
    lda REU_PB_LENLO
    sta REU_LEN_LO
    lda REU_PB_LENHI
    sta REU_LEN_HI
    lda REU_PB_CMD
    sta REU_COMMAND      ; execute — CPU stalls until DMA complete
    rts

; ============================================================================
; try_keyword — extended version of modtok's try_keyword.
; Exactly the same algorithm; kwtab below includes our 13 new keywords.
; Returns carry set + A=token on match (SRC_PTR advanced).
;         carry clear on no match.
; ============================================================================

try_keyword:
    ; Fast paths — same rewrite as modtok's try_keyword (see there for
    ; the rationale): direct single-char operator dispatch, no scan for
    ; characters that can't start a keyword, first-char entry reject,
    ; Y-indexed walk with one pointer advance per entry.
    ldy #0
    lda (SRC_PTR),y
    sta KW_XSAVE                ; cache first source char for entry rejects
    ldx #7
@op_chk:
    cmp kw_op_chars,x
    beq @op_hit
    dex
    bpl @op_chk
    cmp #'A'
    bcc @kw_no_match
    cmp #'Z'+1
    bcs @kw_no_match

    lda #<kwtab
    sta TMP16
    lda #>kwtab
    sta TMP16+1

@kw_entry:
    ldy #0
    lda (TMP16),y               ; token byte, $FF = sentinel
    cmp #$FF
    beq @kw_no_match
    sta KW_TOKEN
    ldy #1
    lda (TMP16),y
    and #$7F
    cmp KW_XSAVE
    bne @kw_skip_entry

@kw_match:
    dey
    lda (SRC_PTR),y             ; source char at (kw index - 1)
    iny
    eor (TMP16),y               ; $00 = match; $80 = match on final char
    asl                         ; C = final-char flag, A = difference << 1
    bne @kw_skip_from_y
    bcs @kw_full_match
    iny
    bne @kw_match               ; always taken

@kw_skip_entry:
    ldy #1
@kw_skip_from_y:
    lda (TMP16),y
    bmi @kw_advance_entry
    iny
    bne @kw_skip_from_y         ; always taken
@kw_advance_entry:
    iny                         ; Y = offset of the next entry's token byte
    tya
    clc
    adc TMP16
    sta TMP16
    bcc @kw_entry
    inc TMP16+1
    jmp @kw_entry

@kw_full_match:
    tya                         ; Y = keyword length
    tax
@kw_advance:
    jsr tok_src_advance
    dex
    bne @kw_advance
    lda KW_TOKEN
    sec
    rts

@op_hit:
    lda kw_op_tokens,x
    sta KW_TOKEN
    jsr tok_src_advance         ; consume the operator char
    lda KW_TOKEN
    sec
    rts

@kw_no_match:
    clc
    rts

; Single-char operator dispatch — chars and their BASIC tokens (same
; encodings as the kwtab's 1-char entries, which are now unreachable and
; kept only as documentation).
kw_op_chars:  .byte $2A,$2B,$2D,$2F,$3C,$3D,$3E,$5E   ; * + - / < = > ^
kw_op_tokens: .byte $AC,$AA,$AB,$AD,$B3,$B2,$B1,$AE

; ============================================================================
; Helpers
; ============================================================================

inc_basic_addr:
    inc BASIC_ADDR
    bne :+
    inc BASIC_ADDR+1
:   rts

; emit_byte — write A to (DST_PTR), advance DST_PTR.  Bounds-checked: at
; STAGING_END ($C000) the byte is dropped and OVFLAG is set — without this,
; a script larger than the 4 KB staging buffer would write over the $C000
; module RAM and on through the $D000 I/O registers (including $DF01, the
; REU command register, where a stray byte executes a rogue DMA).
emit_byte:
    ldy DST_PTR+1
    cpy #>STAGING_END
    bcs @overflow
    ldy #0
    sta (DST_PTR),y
    inc DST_PTR
    bne :+
    inc DST_PTR+1
:   rts
@overflow:
    ldy #$FF
    sty OVFLAG
    rts

; ============================================================================
; Status bar messages (screen codes, zero-terminated)
; ============================================================================

set_status_noreu:
    ldy #0
@wr:
    lda msg_noreu,y
    beq @done
    sta $0400,y
    lda #2              ; red
    sta $D800,y
    iny
    jmp @wr
@done:
    rts

set_status_disk:
    ldy #0
@wr:
    lda msg_disk,y
    beq @done
    sta $0400,y
    lda #2
    sta $D800,y
    iny
    jmp @wr
@done:
    rts

msg_noreu:
    ; "REU NOT FOUND " in C64 screen codes
    .byte $12,$05,$15,$20,$0E,$0F,$14,$20,$06,$0F,$15,$0E,$04, 0

msg_disk:
    ; "INCLUDE DISK ERR" in C64 screen codes
    .byte $09,$0E,$03,$0C,$15,$04,$05,$20,$04,$09,$13,$0B,$20,$05,$12,$12, 0

set_status_incl:
    ldy #0
@wr:
    lda msg_incl,y
    beq @done
    sta $0400,y
    lda #2
    sta $D800,y
    iny
    jmp @wr
@done:
    rts

msg_incl:
    ; "INCLUDE UNSUPPORTED" in C64 screen codes
    .byte $09,$0E,$03,$0C,$15,$04,$05,$20,$15,$0E,$13,$15,$10,$10,$0F,$12,$14,$05,$04, 0

; tok_after_data — $FF while inside a DATA statement
tok_after_data:
    .byte 0

; ============================================================================
; kwtab — extended keyword table, longest-first.
; Format: [token][chars, last char has bit 7 set] ... $FF sentinel
;
; New keywords inserted at their correct length positions:
;   8-char: ASSEMBLE — before all existing entries
;   7-char: INCLUDE, RUNPROG, SCRATCH — before RESTORE
;             RUNPROG before RUN (RUN is a prefix of RUNPROG)
;   6-char: DELETE, EXISTS, RENAME, STATUS — before INPUT#
;   5-char: DRIVE, ONERR, PAUSE — before CLOSE
;             ONERR before ON (ON is a prefix of ONERR)
;   4-char: COPY — before CHR$
;   3-char: DIR — before ABS
; ============================================================================

kwtab:
    ; ---- 8-char ----
    .byte $CC,$41,$53,$53,$45,$4D,$42,$4C,$C5   ; ASSEMBLE

    ; ---- 7-char ----
    .byte $CD,$49,$4E,$43,$4C,$55,$44,$C5       ; INCLUDE
    .byte $CE,$52,$55,$4E,$50,$52,$4F,$C7       ; RUNPROG  (before RUN)
    .byte $CF,$53,$43,$52,$41,$54,$43,$C8       ; SCRATCH
    .byte $8C,$52,$45,$53,$54,$4F,$52,$C5       ; RESTORE

    ; ---- 6-char ----
    .byte $D0,$44,$45,$4C,$45,$54,$C5           ; DELETE
    .byte $D1,$45,$58,$49,$53,$54,$D3           ; EXISTS
    .byte $D2,$52,$45,$4E,$41,$4D,$C5           ; RENAME
    .byte $D3,$53,$54,$41,$54,$55,$D3           ; STATUS
    .byte $84,$49,$4E,$50,$55,$54,$A3           ; INPUT#
    .byte $98,$50,$52,$49,$4E,$54,$A3           ; PRINT#
    .byte $8E,$52,$45,$54,$55,$52,$CE           ; RETURN
    .byte $C9,$52,$49,$47,$48,$54,$A4           ; RIGHT$
    .byte $95,$56,$45,$52,$49,$46,$D9           ; VERIFY

    ; ---- 5-char ----
    .byte $D4,$44,$52,$49,$56,$C5               ; DRIVE
    .byte $D5,$4F,$4E,$45,$52,$D2               ; ONERR  (before ON)
    .byte $D6,$50,$41,$55,$53,$C5               ; PAUSE
    .byte $A0,$43,$4C,$4F,$53,$C5               ; CLOSE
    .byte $8D,$47,$4F,$53,$55,$C2               ; GOSUB
    .byte $85,$49,$4E,$50,$55,$D4               ; INPUT
    .byte $C8,$4C,$45,$46,$54,$A4               ; LEFT$
    .byte $99,$50,$52,$49,$4E,$D4               ; PRINT

    ; ---- 4-char ----
    .byte $D7,$43,$4F,$50,$D9                   ; COPY
    .byte $C7,$43,$48,$52,$A4                   ; CHR$
    .byte $9A,$43,$4F,$4E,$D4                   ; CONT
    .byte $83,$44,$41,$54,$C1                   ; DATA
    .byte $89,$47,$4F,$54,$CF                   ; GOTO
    .byte $9B,$4C,$49,$53,$D4                   ; LIST
    .byte $93,$4C,$4F,$41,$C4                   ; LOAD
    .byte $CA,$4D,$49,$44,$A4                   ; MID$
    .byte $82,$4E,$45,$58,$D4                   ; NEXT
    .byte $9F,$4F,$50,$45,$CE                   ; OPEN
    .byte $C2,$50,$45,$45,$CB                   ; PEEK
    .byte $97,$50,$4F,$4B,$C5                   ; POKE
    .byte $87,$52,$45,$41,$C4                   ; READ
    .byte $94,$53,$41,$56,$C5                   ; SAVE
    .byte $A6,$53,$50,$43,$A8                   ; SPC(
    .byte $A9,$53,$54,$45,$D0                   ; STEP
    .byte $90,$53,$54,$4F,$D0                   ; STOP
    .byte $C4,$53,$54,$52,$A4                   ; STR$
    .byte $A3,$54,$41,$42,$A8                   ; TAB(
    .byte $A7,$54,$48,$45,$CE                   ; THEN
    .byte $92,$57,$41,$49,$D4                   ; WAIT

    ; ---- 3-char ----
    .byte $D8,$44,$49,$D2                       ; DIR
    .byte $B6,$41,$42,$D3                       ; ABS
    .byte $AF,$41,$4E,$C4                       ; AND
    .byte $C6,$41,$53,$C3                       ; ASC
    .byte $C1,$41,$54,$CE                       ; ATN
    .byte $9C,$43,$4C,$D2                       ; CLR
    .byte $9D,$43,$4D,$C4                       ; CMD
    .byte $BE,$43,$4F,$D3                       ; COS
    .byte $96,$44,$45,$C6                       ; DEF
    .byte $86,$44,$49,$CD                       ; DIM
    .byte $80,$45,$4E,$C4                       ; END
    .byte $BD,$45,$58,$D0                       ; EXP
    .byte $81,$46,$4F,$D2                       ; FOR
    .byte $B8,$46,$52,$C5                       ; FRE
    .byte $A1,$47,$45,$D4                       ; GET
    .byte $B5,$49,$4E,$D4                       ; INT
    .byte $C3,$4C,$45,$CE                       ; LEN
    .byte $88,$4C,$45,$D4                       ; LET
    .byte $BC,$4C,$4F,$C7                       ; LOG
    .byte $A2,$4E,$45,$D7                       ; NEW
    .byte $A8,$4E,$4F,$D4                       ; NOT
    .byte $B9,$50,$4F,$D3                       ; POS
    .byte $8F,$52,$45,$CD                       ; REM
    .byte $BB,$52,$4E,$C4                       ; RND
    .byte $8A,$52,$55,$CE                       ; RUN  (after RUNPROG)
    .byte $B4,$53,$47,$CE                       ; SGN
    .byte $BF,$53,$49,$CE                       ; SIN
    .byte $BA,$53,$51,$D2                       ; SQR
    .byte $9E,$53,$59,$D3                       ; SYS
    .byte $C0,$54,$41,$CE                       ; TAN
    .byte $B7,$55,$53,$D2                       ; USR
    .byte $C5,$56,$41,$CC                       ; VAL

    ; ---- 2-char ----
    .byte $A5,$46,$CE                           ; FN
    .byte $CB,$47,$CF                           ; GO
    .byte $8B,$49,$C6                           ; IF
    .byte $91,$4F,$CE                           ; ON  (after ONERR)
    .byte $B0,$4F,$D2                           ; OR
    .byte $A4,$54,$CF                           ; TO

    ; ---- 1-char (operators) ----
    .byte $AC,$AA                               ; *
    .byte $AA,$AB                               ; +
    .byte $AB,$AD                               ; -
    .byte $AD,$AF                               ; /
    .byte $B3,$BC                               ; <
    .byte $B2,$BD                               ; =
    .byte $B1,$BE                               ; >
    .byte $AE,$DE                               ; ^

    .byte $FF                                   ; sentinel

; ============================================================================
; Linker config (modsct.cfg):
;
;   MEMORY {
;     LOADADDR: start = $A000, size = 2, type = ro, fill = yes;
;     CODE:     start = $A000, size = $2000, type = rw, fill = yes;
;   }
;   SEGMENTS {
;     LOADADDR: load = LOADADDR;
;     CODE:     load = CODE, run = CODE;
;   }
;
; Build:
;   ca65 -g modsct.asm -o modsct.o
;   ld65 -C modsct.cfg modsct.o -o MODSCT
; ============================================================================

; ============================================================================
; Reserved scratch — linker-placed so it can never overlap code or tables.
; (Runtime-only state; the .res bytes ship as zeroes in the PRG.)
; ============================================================================

; REU parameter block — filled before each reu_exec call
REU_PB_C64LO: .res 1
REU_PB_C64HI: .res 1
REU_PB_REULO: .res 1
REU_PB_REUME: .res 1
REU_PB_REUHI: .res 1
REU_PB_LENLO: .res 1
REU_PB_LENHI: .res 1
REU_PB_CMD:   .res 1

; Include table: 16 entries × 14 bytes = 224 bytes
; [+0..7]=name(8), [+8..10]=REU addr(3), [+11..12]=len(2), [+13]=flags
INCL_TABLE:   .res INCL_ENTRY_SZ * INCL_MAX
INCL_COUNT:   .res 1    ; number of entries in table
INCL_POOL_LO: .res 1    ; next free offset in REU include pool (3 bytes)
INCL_POOL_MED: .res 1
INCL_POOL_HI: .res 1
INCL_FNAME:   .res 8    ; filename buffer (current include lookup/store)
INCL_FLEN:    .res 1    ; current include filename length
INCL_LOAD_LO: .res 1    ; load length lo
INCL_LOAD_HI: .res 1    ; load length hi

; Link-time guard: everything above must end below the staging buffer.
.assert * <= STAGING, error, "modsct code/scratch overlaps STAGING buffer"
