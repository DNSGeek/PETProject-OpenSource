; ============================================================================
; moddsk.asm — Disk Utility module for PETProject
;
; Loaded at $C000 by the editor (standard module slot, module.cfg).
; Entry: JSR $C000 (first 3 bytes = JMP disk_main)
;
; Features:
;   - Reads up to DSK_MAX_ENTRIES (34) directory entries per page into
;     module RAM; F2/F4 page backward/forward through larger directories
;   - Displays 20 entries at a time in a scrollable popup
;   - RETURN  = open selected file (writes FNAME_BUF/FNAME_LEN, MOD_STATUS=$04)
;   - F       = format disk (prompt for name + 2-char id; result reported)
;   - @       = raw drive command (scratch/rename via S0:/R0: etc.)
;   - STOP/F8 = close, MOD_STATUS=$00 (no change)
;
; NOTE: there are no dedicated delete/rename keys — use the '@' raw
; command channel for those (this header used to promise D/R handlers
; that were never implemented).
;
; Return values (MOD_STATUS):
;   $00 = cancelled / no action
;   $04 = open file: FNAME_BUF/FNAME_LEN set, editor must load
;
; Parameter block ($0212-$0220) — standard module convention:
;   MOD_MAGIC        $0212
;   MOD_COMMAND      $0213
;   MOD_DRIVE        $021C   device number (8-11)
;   MOD_STATUS       $021E   module writes result here
;
; Memory layout (within module at $C000):
;   $C000-$C002  JMP disk_main (entry trampoline)
;   $C003+       Code (BSS follows after code, placed by linker)
;
; Directory cache entry (DSK_ENTRY_SIZE = 20 bytes):
;   Bytes  0-15  filename (PETSCII, space-padded, NOT NUL-terminated)
;   Byte   16    file type (raw CBM type byte: PRG=$82, SEQ=$81, USR=$83, DEL=$80)
;   Byte   17    block count lo
;   Byte   18    block count hi
;   Byte   19    pad (reserved, = 0)
;
; Disk command channel: LA=15, SA=15 (standard CBM command channel)
; Directory read:       LA=2,  SA=0  (sequential read)
;
; Zero page: uses $FB/$FC (DSK_PTR) and $FD/$FE (DSK_PTR2) — saved/restored.
; ============================================================================

.setcpu "6502"

; ============================================================================
; Parameter block
; ============================================================================

MOD_MAGIC        = $0212
MOD_MAGIC_VAL    = $4D
MOD_COMMAND      = $0213
MOD_DRIVE        = $021C
MOD_STATUS       = $021E

; ============================================================================
; Editor BSS symbols — hardcoded addresses.
; These must match the BSS layout in editor.asm exactly.
; The editor's BSS is in work_buf's segment starting just after IO_SCRATCH.
; From editor.asm BSS order:
;   FNAME_BUF  (16 bytes)
;   FNAME_LEN  (1 byte)
; ============================================================================

; FNAME_BUF in module RAM — staging area for the selected filename.
; Copied to the editor's FNAME_BUF (address passed via DSK_FNAME_BUF_LO/HI)
; after the user confirms an action.  The editor's BSS address is not fixed
; (it depends on code size), so the editor passes its FNAME_BUF and FNAME_LEN
; addresses via the extended parameter block at $0223-$0226 before calling
; this module.  See DSK_FNAME_BUF_LO/HI below.
FNAME_BUF        = $C800    ; 16-byte filename staging buffer (module RAM)

; Extended parameter block ($0223-$0226) — editor populates before calling module.
; These carry the runtime addresses of the editor's own FNAME_BUF and FNAME_LEN
; variables, whose locations depend on the editor binary's code size.
DSK_FNAME_BUF_LO = $0223   ; lo byte of address of editor's FNAME_BUF
DSK_FNAME_BUF_HI = $0224   ; hi byte of address of editor's FNAME_BUF
DSK_FNAME_LEN_LO = $0225   ; lo byte of address of editor's FNAME_LEN
DSK_FNAME_LEN_HI = $0226   ; hi byte of address of editor's FNAME_LEN

; ============================================================================
; Kernal routines
; ============================================================================

SETLFS   = $FFBA
SETNAM   = $FFBD
OPEN     = $FFC0
CLOSE    = $FFC3
CHKIN    = $FFC6
CHKOUT   = $FFC9
CLRCHN   = $FFCC
CHRIN    = $FFCF
CHROUT   = $FFD2
READST   = $FFB7
GETIN    = $FFE4

; ============================================================================
; Screen / VIC
; ============================================================================

SCREEN      = $0400
COLOR       = $D800
STATUS_ROW  = SCREEN
COLS        = 40
TOTAL_ROWS  = 25

JIFFY_LO    = $A2

; ============================================================================
; Color constants
; ============================================================================

CLR_CHROME  = $0B   ; dark grey  — box border
CLR_TITLE   = $01   ; white      — title row
CLR_NORMAL  = $0E   ; light blue — unselected items
CLR_SEL     = $01   ; white      — selected item (highlighted)
CLR_LEGEND  = $0B   ; dark grey  — key legend row
CLR_ERROR   = $02   ; red        — error display
CLR_PROMPT  = $0E   ; light blue — @CMD: prompt label (was dark grey, invisible)
CLR_INPUT   = $01   ; white      — command input characters

; ============================================================================
; Popup geometry
; ============================================================================

; Box occupies rows 0-24 (full screen overlay):
;   Row 0   = title bar      "DISK UTILITY    F8=CLOSE"
;   Row 1   = disk info      "NN BLOCKS FREE  DISKNAME"
;   Row 2   = separator      "────────────────────────"
;   Rows 3-22 = 20 file entries
;   Row 23  = separator
;   Row 24  = legend         "RETURN=OPEN  D=DEL  R=REN  F=FMT"

DSK_VIEW_TOP    = 3         ; first visible item row
DSK_VIEW_ROWS   = 20        ; number of visible rows
DSK_VIEW_BOT    = (DSK_VIEW_TOP + DSK_VIEW_ROWS - 1)   ; = 22
DSK_LEGEND_ROW  = 24

; ============================================================================
; Directory cache layout
; ============================================================================

DSK_MAX_ENTRIES = 34       ; cache cap: 34×20=680 bytes — fits 4K module with rawcmd code
DSK_ENTRY_SIZE  = 20        ; 16 name + 1 type + 2 blocks + 1 pad

; Directory cache: 34 entries × 20 bytes = 680 bytes, placed by linker in BSS.
; Reduced from 50 to make room for DSK_CMD_BUF (32 bytes) added for the @
; raw-command feature. 34 entries covers all practical project disk layouts;
; the 1541 directory track holds 144 slots but real disks rarely approach that.
; All state variables are in BSS (after code), allocated by the linker.
; DSK_CACHE is the largest BSS item; it follows the scalar state vars.
;
; NOTE: the old design hardcoded these to $C003-$C0FF, which overlapped
; disk_main's own code. That caused dsk_cache_ptr to read instruction opcodes
; instead of the actual entry count, corrupting the cache pointer.
; BSS placement fixes this -- the linker puts BSS after all CODE bytes.

.segment "BSS"
DSK_ENTRY_COUNT: .res 1     ; number of entries actually read (0-100)
DSK_SEL:         .res 1     ; currently selected entry index (0..COUNT-1)
DSK_VIEW_START:  .res 1     ; index of entry at top of viewport (0..COUNT-1)
DSK_DRIVE:       .res 1     ; device number copy
DSK_FREE_LO:     .res 1     ; blocks free lo
DSK_FREE_HI:     .res 1     ; blocks free hi
DSK_DISKNAME:    .res 16    ; disk name, 16 bytes PETSCII
DSK_DISKID:      .res 2     ; disk id, 2 bytes
DSK_ZP_SAVE:     .res 4     ; saved ZP $FB-$FE
DSK_TMP:         .res 1     ; general scratch byte
DSK_TMP2:        .res 1     ; second scratch byte
DSK_NAMELEN_TMP: .res 1     ; scratch for rename/format input length
DSK_INPUT_BUF:   .res 16    ; input buffer for prompts
DSK_TRUNCATED:   .res 1     ; $FF if cache hit 100-entry cap
DSK_ERROR_CODE:  .res 1     ; CBM error code from status channel
DSK_CMD_BUF:     .res 32    ; raw command input buffer (@-key feature)
DSK_CMD_LEN:     .res 1     ; length of raw command in DSK_CMD_BUF
DSK_PAGE:        .res 1     ; current page number (0-based); each page = DSK_MAX_ENTRIES
DSK_SKIP:        .res 1     ; entries to skip on next dsk_read_entries call (= PAGE × MAX)
DSK_SKIP_HI:     .res 1     ; hi byte — page 3+ of a big (CMD/SD2IEC) dir exceeds 255
DSK_CACHE:       .res 680   ; directory cache: 34 entries × 20 bytes

.segment "CODE"
; DSK_CACHE is now a label rather than a constant -- references to it
; throughout the code will resolve correctly via the linker.

; Zero page pointers (saved/restored)
DSK_PTR         = $FB       ; lo (hi = $FC)
DSK_PTR2        = $FD       ; lo (hi = $FE)

; ============================================================================
; Module entry point
; ============================================================================

.segment "LOADADDR"
    .word $C000

.segment "CODE"

    jmp disk_main               ; $C000: standard JMP-entry convention

; ============================================================================
; disk_main — module entry point
; ============================================================================

disk_main:
    ; Ensure normal C64 memory map: BASIC+Kernal+I/O all mapped in.
    ; The editor may have left $01 in any state; Kernal calls will crash
    ; if it isn't $37. Set direction register first (bits 0-2 must be outputs).
    lda $00
    ora #$07
    sta $00
    lda #$37
    sta $01

    ; Save ZP
    lda $FB
    sta DSK_ZP_SAVE+0
    lda $FC
    sta DSK_ZP_SAVE+1
    lda $FD
    sta DSK_ZP_SAVE+2
    lda $FE
    sta DSK_ZP_SAVE+3

    ; Copy drive from parameter block
    lda MOD_DRIVE
    sta DSK_DRIVE

    ; Default status = no action
    lda #$00
    sta MOD_STATUS

    ; Init state
    lda #0
    sta DSK_ENTRY_COUNT
    sta DSK_SEL
    sta DSK_VIEW_START
    sta DSK_TRUNCATED
    sta DSK_PAGE
    sta DSK_SKIP
    sta DSK_SKIP_HI

    ; Read directory into cache
    jsr dsk_read_directory
    bcc @dir_ok

    ; Error reading directory — show message and bail
    jsr dsk_show_error
    jmp dsk_exit

@dir_ok:
    ; Draw full popup
    jsr dsk_draw_full

    ; Flush keyboard buffer
@flush:
    jsr GETIN
    bne @flush

; ============================================================================
; Main interaction loop
; ============================================================================

@loop:
    jsr GETIN
    beq @loop

    ; STOP or F8 = close
    cmp #$03                    ; RUN/STOP
    beq @close
    cmp #$8C                    ; F8
    beq @close

    ; Cursor up
    cmp #$91
    bne @try_dn
    jsr dsk_cursor_up
    jmp @loop

@try_dn:
    cmp #$11
    bne @try_ret
    jsr dsk_cursor_down
    jmp @loop

@try_ret:
    cmp #$0D                    ; RETURN = open
    bne @try_f4
    jsr dsk_do_open
    bcs @loop                   ; C=1: cancelled or error, stay in loop
    jmp dsk_exit                ; C=0: FNAME set, exit with status $04

@try_f4:
    cmp #$8A                    ; F4 = next page (page down)
    bne @try_f2
    jsr dsk_page_next
    jmp @loop

@try_f2:
    cmp #$89                    ; F2 = prev page (page up)
    bne @try_fmt
    jsr dsk_page_prev
    jmp @loop

@try_fmt:
    cmp #$06                    ; 'F' PETSCII lowercase
    bne @try_fmt2
    jsr dsk_do_format
    jmp @loop
@try_fmt2:
    cmp #$46                    ; 'F' uppercase PETSCII
    bne @try_rawcmd
    jsr dsk_do_format
    jmp @loop

@try_rawcmd:
    cmp #$40                    ; '@' — raw command
    bne @loop
    jsr dsk_do_rawcmd
    jmp @loop

@close:
    lda #$00
    sta MOD_STATUS

dsk_exit:
    ; Restore ZP
    lda DSK_ZP_SAVE+0
    sta $FB
    lda DSK_ZP_SAVE+1
    sta $FC
    lda DSK_ZP_SAVE+2
    sta $FD
    lda DSK_ZP_SAVE+3
    sta $FE
    rts

; ============================================================================
; dsk_read_directory
;
; Opens "$" on the drive, reads and parses all PRG directory entries.
; Populates DSK_DISKNAME, DSK_DISKID, DSK_FREE_LO/HI, DSK_CACHE, DSK_ENTRY_COUNT.
; On exit: C=0 OK, C=1 error.
;
; The 1541 directory is a standard SEQ file named "$".
; Opening with SA=0 gives us the raw BASIC-tokenized listing.
; Format of each directory line (as BASIC tokenized bytes):
;   2 bytes: link to next line (ignore)
;   2 bytes: block count (lo, hi)
;   1 byte:  $20 (space) or $12 (reverse for selected)  — skip
;   then:    PETSCII content including filename in quotes
;
; We skip the first line (disk header) after extracting disk name/id/free.
; Subsequent lines: block count then parse for filename and file type marker.
; ============================================================================

; ============================================================================
; dsk_read_directory — open "$", read header then entries.
; Split into dsk_read_header + dsk_read_entries to keep branch ranges short.
; On exit: C=0 OK, C=1 error (channel already closed on error).
;
; Entry layout in cache (DSK_ENTRY_SIZE = 20 bytes):
;   0-15  filename (PETSCII, space-padded)
;   16    file type ($82=PRG $81=SEQ $83=USR $80=DEL $84=REL)
;   17    block count lo
;   18    block count hi
;   19    pad
;
; Scratch register convention (stable throughout):
;   DSK_TMP        = block count lo  (set in entry loop, never reused for type)
;   DSK_TMP2       = block count hi
;   DSK_NAMELEN_TMP = file type byte (set during type scan)
; ============================================================================

dsk_read_directory:
    lda #2
    ldx DSK_DRIVE
    ldy #0
    jsr SETLFS
    lda #1
    ldx #<dsk_dir_name
    ldy #>dsk_dir_name
    jsr SETNAM
    jsr OPEN
    bcc @open_ok
    sec
    rts
@open_ok:
    ldx #2
    jsr CHKIN
    bcc @chkin_ok
    lda #2
    jsr CLOSE
    sec
    rts
@chkin_ok:
    ; Skip 2-byte PRG load-address header
    jsr dsk_chrin_safe
    jsr dsk_chrin_safe
    ; Parse header line, then all entries
    jsr dsk_read_header         ; C=1 → bail
    bcc @entries_ok
    jmp @err_close
@entries_ok:
    jsr dsk_read_entries        ; C=1 → bail (channel already drained)
    bcc @ok
    jmp @err_close
@ok:
    ; Read blocks-free by re-scanning the directory channel from current position.
    ; After all entries, the channel is at/near EOF. Drain whatever remains
    ; to find the BLOCKS FREE line number (it follows the last entry).
    ; Use a tight drain loop looking for the null link pointer.
    jsr dsk_read_blocks_free    ; sets DSK_FREE_LO/HI if found; ignores errors
    jsr CLRCHN
    lda #2
    jsr CLOSE
    clc
    rts
@err_close:
    jsr CLRCHN
    lda #2
    jsr CLOSE
    sec
    rts

; ============================================================================
; dsk_read_header — consume and parse the first directory line.
; Extracts DSK_DISKNAME and DSK_DISKID. Leaves stream at start of entry lines.
; C=0 OK, C=1 EOF/error.
; ============================================================================

dsk_read_header:
    ; Skip link (2) and block count (2) of header line
    jsr dsk_chrin_safe
    bcs @eof
    jsr dsk_chrin_safe
    bcs @eof
    jsr dsk_chrin_safe
    bcs @eof
    jsr dsk_chrin_safe
    bcs @eof

    ; Skip bytes until opening quote
@pre:
    jsr dsk_chrin_safe
    bcs @eof
    cmp #$22
    bne @pre

    ; Read disk name
    ldy #0
@name:
    jsr dsk_chrin_safe
    bcs @eof
    cmp #$22                    ; closing quote
    beq @after_name
    cmp #$00                    ; premature end of line ($00 in BASIC token stream)
    beq @name_done_cr
    cpy #16
    bcs @name                   ; past 16 chars: keep reading, don't store
    sta DSK_DISKNAME,y
    iny
    jmp @name

@after_name:
    ; Pad diskname with spaces
    lda #$20
@pad:
    cpy #16
    beq @read_id
    sta DSK_DISKNAME,y
    iny
    jmp @pad

@read_id:
    ; Skip the space between closing quote and ID
    jsr dsk_chrin_safe
    bcs @eof
    ; Read 2-char disk ID
    jsr dsk_chrin_safe
    bcs @eof
    sta DSK_DISKID+0
    jsr dsk_chrin_safe
    bcs @eof
    sta DSK_DISKID+1
    ; Drain to end of header line
@eol:
    jsr dsk_chrin_safe
    bcs @eof
    cmp #$00
    bne @eol
    clc
    rts

@name_done_cr:
    ; Pad diskname, set blank ID, done (CR already consumed)
    lda #$20
@pad_cr:
    cpy #16
    beq @blank_id
    sta DSK_DISKNAME,y
    iny
    jmp @pad_cr
@blank_id:
    lda #$20
    sta DSK_DISKID+0
    sta DSK_DISKID+1
    clc
    rts

@eof:
    sec
    rts

; ============================================================================
; dsk_read_entries — read all file entries into DSK_CACHE.
; Called after dsk_read_header; stream positioned at first entry line.
; Populates DSK_ENTRY_COUNT. DSK_FREE_LO/HI set to $FF (unknown).
; If DSK_SKIP > 0, that many entries are consumed and discarded first
; (used by the paging system to reach entries beyond page 0).
; C=0 always (errors silently truncate the listing).
; ============================================================================

dsk_read_entries:
    lda #$FF
    sta DSK_FREE_LO
    sta DSK_FREE_HI

    ; --- Skip phase: drain DSK_SKIP (16-bit) entries without caching ---
    ; DSK_TMP/DSK_TMP2 hold the countdown; both are free until the entry
    ; loop, which re-initializes them before use.
    lda DSK_SKIP
    sta DSK_TMP
    lda DSK_SKIP_HI
    sta DSK_TMP2
    ora DSK_TMP
    beq @entry_loop             ; nothing to skip
@skip_loop:
    ; Read and discard one complete directory entry line.
    ; Structure: link(2) + blocks(2) + spaces/reverse + "filename" + type + EOL($00)
    jsr READST
    and #$02
    bne @skip_done              ; hard error: give up skipping, proceed with what we have
    jsr CHRIN
    cmp #$00
    beq @skip_done              ; null link = BLOCKS FREE line: no more entries
    ; link hi
    jsr dsk_chrin_safe
    bcs @skip_done
    ; blocks lo, hi
    jsr dsk_chrin_safe
    bcs @skip_done
    jsr dsk_chrin_safe
    bcs @skip_done
    ; drain to end of line ($00 terminator)
@skip_eol:
    jsr dsk_chrin_safe
    bcs @skip_done
    cmp #$00
    bne @skip_eol
    ; one entry consumed — 16-bit countdown
    lda DSK_TMP
    bne :+
    dec DSK_TMP2
:   dec DSK_TMP
    lda DSK_TMP
    ora DSK_TMP2
    bne @skip_loop
    ; Note: do NOT set DSK_TRUNCATED here.  It means "more entries exist
    ; AFTER this page" (dsk_page_next's gate) and is set only when the
    ; entry cap below is actually hit.  Setting it just because we skipped
    ; (i.e. "a previous page exists" — which DSK_PAGE>0 already encodes)
    ; made F4 page forever into empty pages.
    jmp @entry_loop

@skip_done:
    clc
    rts

@entry_loop:
    ; Read link lo using raw CHRIN to handle the case where the 1541 sets
    ; EOI (EOF) simultaneously with the last data byte. dsk_chrin_safe would
    ; abort early leaving us unable to detect the $00 link pointer.
    jsr READST
    and #$02                    ; check error bit only (not EOF $40)
    bne @done                   ; hard error: bail
    jsr CHRIN
    cmp #$00
    bne @not_eof
    ; link_lo=$00: this is the BLOCKS FREE line's null next-pointer.
    ; Read blocks-free via dsk_read_blocks_free (which also uses raw CHRIN).
    jmp @done
@not_eof:
    ; Read link hi (non-zero link = more entries follow)
    jsr dsk_chrin_safe
    bcs @done

    ; Read block count
    jsr dsk_chrin_safe
    bcs @done
    sta DSK_TMP                 ; block lo
    jsr dsk_chrin_safe
    bcs @done
    sta DSK_TMP2                ; block hi

    ; Skip pre-quote bytes (spaces, reverse-field)
@pre:
    jsr dsk_chrin_safe
    bcs @done
    cmp #$00
    beq @entry_loop             ; blank line — try next
    cmp #$22
    bne @pre

    ; Hit entry cap?
    lda DSK_ENTRY_COUNT
    cmp #DSK_MAX_ENTRIES
    bcc @store
    ; Truncated — drain and exit
    lda #$FF
    sta DSK_TRUNCATED
@drain:
    jsr dsk_chrin_safe
    bcs @done
    cmp #$00
    bne @drain
@done:
    clc
    rts

@store:
    ; Point DSK_PTR at this cache slot
    jsr dsk_cache_ptr

    ; Read filename bytes
    ldy #0
@fname:
    jsr dsk_chrin_safe
    bcc :+
    jmp @abort
:
    cmp #$22                    ; closing quote
    beq @fname_done
    cmp #$00
    bne :+
    jmp @skip_entry             ; malformed
:
    cpy #16
    bcs @fname                  ; overflow: keep reading
    sta (DSK_PTR),y
    iny
    jmp @fname

@fname_done:
    ; Pad to 16 chars
    lda #$20
@pad:
    cpy #16
    beq @scan_type
    sta (DSK_PTR),y
    iny
    jmp @pad

@scan_type:
    ; DSK_TMP=blocks lo, DSK_TMP2=blocks hi — preserved.
    ; DSK_NAMELEN_TMP = file type (default SEQ).
    lda #$81
    sta DSK_NAMELEN_TMP

@type_loop:
    jsr dsk_chrin_safe
    bcs @commit
    cmp #$00
    beq @commit
    cmp #$50                    ; 'P' PRG
    bne @t_seq
    lda #$82
    sta DSK_NAMELEN_TMP
    jmp @drain_line
@t_seq:
    cmp #$53                    ; 'S' SEQ
    bne @t_usr
    lda #$81
    sta DSK_NAMELEN_TMP
    jmp @drain_line
@t_usr:
    cmp #$55                    ; 'U' USR
    bne @t_del
    lda #$83
    sta DSK_NAMELEN_TMP
    jmp @drain_line
@t_del:
    cmp #$44                    ; 'D' DEL
    bne @t_rel
    lda #$80
    sta DSK_NAMELEN_TMP
    jmp @drain_line
@t_rel:
    cmp #$52                    ; 'R' REL
    bne @type_loop
    lda #$84
    sta DSK_NAMELEN_TMP
    ; fall through to drain_line

@drain_line:
    jsr dsk_chrin_safe
    bcs @commit
    cmp #$00
    bne @drain_line

@commit:
    ; Store: type at [16], blocks lo at [17], blocks hi at [18]
    ldy #16
    lda DSK_NAMELEN_TMP
    sta (DSK_PTR),y
    ldy #17
    lda DSK_TMP
    sta (DSK_PTR),y
    ldy #18
    lda DSK_TMP2
    sta (DSK_PTR),y
    inc DSK_ENTRY_COUNT
    jmp @entry_loop

@skip_entry:
    jmp @entry_loop

@abort:
    clc
    rts

; ============================================================================
; dsk_read_blocks_free — drain remaining bytes after last file entry to find
; the BLOCKS FREE line number. Called after dsk_read_entries with channel
; still open and positioned after the last entry's $00 terminator.
; The next bytes should be: $00 (link_lo) $00 (link_hi) lo hi "BLOCKS FREE."$00
; Uses raw CHRIN (no READST check) since EOF may already be set.
; Sets DSK_FREE_LO/HI if found. Harmless if channel is already exhausted.
; ============================================================================

dsk_read_blocks_free:
    ; Read free block count from 1541 internal RAM via M-R (memory-read) command.
    ; The 1541 caches the BAM at $0700. Free-sector counts are at:
    ;   $0704 + (track-1)*4  for tracks 1-35 (one byte per track, skip T18).
    ; We read all 140 bytes (35 tracks * 4 bytes starting at $0704),
    ; sum every 4th byte, skipping track 18 (directory track).
    lda #15
    ldx DSK_DRIVE
    ldy #15
    jsr SETLFS
    lda #0
    ldx #0
    ldy #0
    jsr SETNAM
    jsr OPEN
    bcc @cmd_ok
    rts
@cmd_ok:
    ldx #15
    jsr CHKOUT
    bcc @send_ok
    lda #15
    jsr CLOSE
    rts
@send_ok:
    lda #$4D                    ; 'M'
    jsr CHROUT
    lda #$2D                    ; '-'
    jsr CHROUT
    lda #$52                    ; 'R'
    jsr CHROUT
    lda #$04                    ; lo of $0704
    jsr CHROUT
    lda #$07                    ; hi of $0704
    jsr CHROUT
    lda #140                    ; 35 * 4
    jsr CHROUT
    jsr CLRCHN
    ldx #15
    jsr CHKIN
    bcc @read_ok
    lda #15
    jsr CLOSE
    rts
@read_ok:
    lda #0
    sta DSK_FREE_LO
    sta DSK_FREE_HI
    ldy #0                      ; byte index 0..139
@mr_loop:
    jsr CHRIN
    sta DSK_TMP                 ; save the byte read
    ; Is this a free-count position? (Y mod 4 == 0) AND not track 18 (Y != 68)
    tya
    and #$03
    bne @mr_next                ; not a count byte
    tya
    cmp #68                     ; (18-1)*4 = 68 = directory track offset
    beq @mr_next                ; skip T18
    ; Add DSK_TMP to DSK_FREE 16-bit
    lda DSK_FREE_LO
    clc
    adc DSK_TMP
    sta DSK_FREE_LO
    bcc @mr_next
    inc DSK_FREE_HI
@mr_next:
    iny
    cpy #140
    bne @mr_loop
    jsr CLRCHN
    lda #15
    jsr CLOSE
    rts

; ============================================================================
; dsk_chrin_safe — read one byte from current input channel.
; Returns byte in A. C=1 if EOF or error, C=0 OK.
; ============================================================================

dsk_chrin_safe:
    jsr READST
    and #$42                    ; EOF ($40) or error ($02)
    bne @eof
    jsr CHRIN
    clc
    rts
@eof:
    sec
    rts

; ============================================================================
; dsk_cache_ptr — set DSK_PTR to address of cache entry DSK_ENTRY_COUNT.
; DSK_ENTRY_COUNT × 20 + DSK_CACHE.
; Clobbers A, X. Result in DSK_PTR/$FC.
; ============================================================================

dsk_cache_ptr:
    lda #0
    sta DSK_PTR
    sta DSK_PTR+1
    ldx DSK_ENTRY_COUNT
    beq @done
@mul:
    ; add 20 to DSK_PTR
    lda DSK_PTR
    clc
    adc #DSK_ENTRY_SIZE
    sta DSK_PTR
    bcc :+
    inc DSK_PTR+1
:   dex
    bne @mul
@done:
    lda DSK_PTR
    clc
    adc #<DSK_CACHE
    sta DSK_PTR
    lda DSK_PTR+1
    adc #>DSK_CACHE
    sta DSK_PTR+1
    rts

; ============================================================================
; dsk_entry_ptr — set DSK_PTR to address of cache entry in A.
; Same math as dsk_cache_ptr but index comes from A, not DSK_ENTRY_COUNT.
; ============================================================================

dsk_entry_ptr:
    sta DSK_TMP                 ; save index
    lda #0
    sta DSK_PTR
    sta DSK_PTR+1
    ldx DSK_TMP
    beq @done
@mul:
    lda DSK_PTR
    clc
    adc #DSK_ENTRY_SIZE
    sta DSK_PTR
    bcc :+
    inc DSK_PTR+1
:   dex
    bne @mul
@done:
    lda DSK_PTR
    clc
    adc #<DSK_CACHE
    sta DSK_PTR
    lda DSK_PTR+1
    adc #>DSK_CACHE
    sta DSK_PTR+1
    rts

; ============================================================================
; dsk_draw_full — draw the complete disk utility overlay.
; Repaints all 25 rows.
; ============================================================================

dsk_draw_full:
    jsr dsk_draw_title
    jsr dsk_draw_info
    jsr dsk_draw_separator_top
    jsr dsk_draw_entries
    jsr dsk_draw_separator_bot
    jsr dsk_draw_legend
    rts

; ============================================================================
; dsk_draw_title — row 0
; "DISK UTILITY  DEV:N  F8=CLOSE"
; ============================================================================

dsk_draw_title:
    ; Clear row 0
    ldx #0
    lda #$20
@clr:
    sta SCREEN,x
    lda #CLR_TITLE
    sta COLOR,x
    lda #$20
    inx
    cpx #COLS
    bne @clr

    ; Write title string
    ldy #0
@wr:
    lda dsk_title_text,y
    beq @dev
    sta SCREEN,y
    iny
    bne @wr
@dev:
    ; Write device number after "DEV:" — col 18 for single digit, 17-18 for two.
    ; "DISK UTILITY  DEV:  " — colon is at col 17, digits go at 18 (and 17 for tens).
    lda DSK_DRIVE
    cmp #10
    bcc @one_digit
    ; Two-digit device (10, 11): write '1' at col 17, units at col 18
    lda #$31                    ; '1' screen code
    sta SCREEN+17
    lda DSK_DRIVE
    sec
    sbc #10
    clc
    adc #$30
    sta SCREEN+18
    jmp @done_dev
@one_digit:
    lda DSK_DRIVE
    clc
    adc #$30
    sta SCREEN+18
@done_dev:
    rts

; Title: "DISK UTILITY  DEV:  " (screen codes)
; D=$04 I=$09 S=$13 K=$0B  U=$15 T=$14 I=$09 L=$0C I=$09 T=$14 Y=$19
; space=$20 space=$20 D=$04 E=$05 V=$16 :=$3A space=$20 space=$20
dsk_title_text:
    .byte $04,$09,$13,$0B,$20,$15,$14,$09,$0C,$09,$14,$19,$20,$20
    .byte $04,$05,$16,$3A,$20,$20
    .byte 0

; ============================================================================
; dsk_draw_info — row 1: disk name, ID, free blocks
; ============================================================================

dsk_draw_info:
    ldy #0
    lda #$20
@clr:
    sta SCREEN+COLS,y
    lda #CLR_CHROME
    sta COLOR+COLS,y
    lda #$20
    iny
    cpy #COLS
    bne @clr

    ; Write disk name (16 chars), converting PETSCII to screen codes
    ldy #0
@name:
    lda DSK_DISKNAME,y
    jsr dsk_petscii_to_sc
    sta SCREEN+COLS,y
    lda #CLR_TITLE
    sta COLOR+COLS,y
    iny
    cpy #16
    bne @name

    ; Write " / " separator at col 16
    lda #$20
    sta SCREEN+COLS+16
    lda #$2F                    ; '/'
    sta SCREEN+COLS+17
    lda #$20
    sta SCREEN+COLS+18

    ; Write 2-char disk ID at col 19-20
    lda DSK_DISKID+0
    jsr dsk_petscii_to_sc
    sta SCREEN+COLS+19
    lda DSK_DISKID+1
    jsr dsk_petscii_to_sc
    sta SCREEN+COLS+20

    ; Write "  FREE:" at col 22-28 and block count
    ldy #0
@free_lbl:
    lda dsk_free_label,y
    beq @free_count
    sta SCREEN+COLS+22,y
    lda #CLR_CHROME
    sta COLOR+COLS+22,y
    iny
    bne @free_lbl
@free_count:
    ; Display free block count or "???" if unknown ($FFFF)
    lda DSK_FREE_LO
    and DSK_FREE_HI
    cmp #$FF
    bne @show_free
    lda #$3F                    ; '?'
    sta SCREEN+COLS+29
    sta SCREEN+COLS+30
    sta SCREEN+COLS+31
    rts
@show_free:
    ; Convert 16-bit block count to decimal (max 664 on 1541)
    ; Simple: convert to 3 decimal digits
    lda DSK_FREE_LO
    sta DSK_TMP
    lda DSK_FREE_HI
    sta DSK_TMP2
    jsr dsk_print_decimal       ; prints 4 digits into SCREEN+COLS+29

    ; Page indicator at cols 33-39: "PG:N" where N is DSK_PAGE+1.
    ; Always shown so user has a reference point even on page 1.
    ; P=$10 G=$07 :=$3A
    lda #$10
    sta SCREEN+COLS+33
    lda #$07
    sta SCREEN+COLS+34
    lda #$3A
    sta SCREEN+COLS+35
    lda DSK_PAGE
    clc
    adc #1                      ; display 1-based page number
    cmp #10
    bcc @pg_one_digit
    ; Two-digit page (10+): write tens at col 36, units at col 37
    ; Simple: subtract 10 repeatedly (page numbers stay small in practice)
    ldx #0
@pg_tens:
    sec
    sbc #10
    inx
    cmp #10
    bcs @pg_tens
    pha                         ; save units
    txa
    clc
    adc #$30
    sta SCREEN+COLS+36
    pla
    clc
    adc #$30
    sta SCREEN+COLS+37
    jmp @pg_color
@pg_one_digit:
    clc
    adc #$30
    sta SCREEN+COLS+36
@pg_color:
    lda #CLR_CHROME
    sta COLOR+COLS+33
    sta COLOR+COLS+34
    sta COLOR+COLS+35
    sta COLOR+COLS+36
    sta COLOR+COLS+37
    rts

; "FREE:" in screen codes: F=$06 R=$12 E=$05 E=$05 :=$3A
dsk_free_label:
    .byte $06,$12,$05,$05,$3A,$20, 0

; ============================================================================
; dsk_draw_separator_top — row 2: horizontal line
; ============================================================================

dsk_draw_separator_top:
    ldy #0
@loop:
    lda #$40                    ; horizontal bar screen code
    sta SCREEN + (2*COLS),y
    lda #CLR_CHROME
    sta COLOR + (2*COLS),y
    iny
    cpy #COLS
    bne @loop
    rts

; ============================================================================
; dsk_draw_separator_bot — row 23: horizontal line
; ============================================================================

dsk_draw_separator_bot:
    ldy #0
@loop:
    lda #$40
    sta SCREEN + (23*COLS),y
    lda #CLR_CHROME
    sta COLOR + (23*COLS),y
    iny
    cpy #COLS
    bne @loop
    rts

; ============================================================================
; dsk_draw_legend — row 24
; ============================================================================

dsk_draw_legend:
    ldy #0
@clr:
    lda #$20
    sta SCREEN + (24*COLS),y
    lda #CLR_LEGEND
    sta COLOR + (24*COLS),y
    iny
    cpy #COLS
    bne @clr
    ldy #0
@wr:
    lda dsk_legend_text,y
    beq @done
    sta SCREEN + (24*COLS),y
    iny
    bne @wr
@done:
    rts

; "RET=OPEN F=FMT @=CMD F2=PG+ F4=PG-" screen codes
; Each token hand-encoded in PETSCII screen codes.
; R=$12 E=$05 T=$14 ==$3D O=$0F P=$10 E=$05 N=$0E space=$20
; F=$06 ==$3D F=$06 M=$0D T=$14 space=$20
; @=$00 ==$3D C=$03 M=$0D D=$04 space=$20
; F=$06 2=$32 ==$3D P=$10 G=$07 +=$2B space=$20
; F=$06 4=$34 ==$3D P=$10 G=$07 -=$2D
dsk_legend_text:
    ; F2 = previous page, F4 = next page (matches the editor's F2=up /
    ; F4=down convention and the handlers below — the old legend had
    ; the two swapped).
    .byte $12,$05,$14,$3D,$0F,$10,$05,$0E,$20   ; RET=OPEN
    .byte $06,$3D,$06,$0D,$14,$20               ; F=FMT
    .byte $00,$3D,$03,$0D,$04,$20               ; @=CMD
    .byte $06,$32,$3D,$10,$07,$2D,$20           ; F2=PG-
    .byte $06,$34,$3D,$10,$07,$2B               ; F4=PG+
    .byte 0

; ============================================================================
; dsk_draw_entries — draw all 20 visible entry rows (rows 3-22)
; ============================================================================

dsk_draw_entries:
    ; Loop counter on the stack. DSK_TMP and DSK_TMP2 are both clobbered
    ; by routines called from dsk_draw_one_entry, so we can't use them here.
    lda #0
@loop:
    pha                         ; save loop counter (0..19)
    jsr dsk_draw_one_entry      ; A = viewport row
    pla                         ; restore loop counter
    clc
    adc #1
    cmp #DSK_VIEW_ROWS
    bne @loop
    rts

; ============================================================================
; dsk_draw_one_entry — draw one row. A = viewport row (0..19).
;
; Computes entry index = DSK_VIEW_START + A.
; If entry index >= DSK_ENTRY_COUNT, draws blank row.
; Row on screen = DSK_VIEW_TOP + A.
; ============================================================================

dsk_draw_one_entry:
    ; A = viewport row (0..19) on entry.
    ; Entry index = A + DSK_VIEW_START. Stored in X throughout to survive
    ; calls to dsk_color_row (which clobbers DSK_TMP/DSK_TMP2/$FB/$FC).
    ; dsk_row_ptr and dsk_entry_ptr both clobber X, so we save/restore X
    ; around those calls using DSK_ERROR_CODE as a 1-byte X spill
    ; (safe: only written here during draw, never mid-ISR).

    pha                         ; save viewport row

    ; Compute entry index and keep it in X
    clc
    adc DSK_VIEW_START
    tax                         ; X = entry index (survives dsk_color_row)

    ; Compute screen row = viewport_row + DSK_VIEW_TOP
    pla
    pha                         ; restore viewport row in A (keep on stack)
    clc
    adc #DSK_VIEW_TOP
    stx DSK_ERROR_CODE          ; spill X (entry index) before dsk_row_ptr clobbers it
    jsr dsk_row_ptr             ; DSK_PTR2 = screen RAM of this row
    ldx DSK_ERROR_CODE          ; restore entry index to X

    ; Determine highlight color
    txa                         ; A = entry index
    cmp DSK_SEL
    beq @is_sel
    lda #CLR_NORMAL
    jmp @got_color
@is_sel:
    lda #CLR_SEL
@got_color:
    sta DSK_TMP2                ; color byte for dsk_color_row

    ; Clear screen row to spaces
    ldy #0
    lda #$20
@clr:
    sta (DSK_PTR2),y
    iny
    cpy #COLS
    bne @clr

    ; Paint color RAM row — clobbers DSK_TMP, $FB/$FC, AND X.
    pla
    pha
    clc
    adc #DSK_VIEW_TOP
    jsr dsk_color_row           ; X is now garbage

    ; Restore entry index to X (dsk_color_row clobbered it)
    ldx DSK_ERROR_CODE

    ; Recompute DSK_PTR2 (dsk_color_row used $FB/$FC as scratch, clobbering DSK_PTR2)
    pla
    pha
    clc
    adc #DSK_VIEW_TOP
    stx DSK_ERROR_CODE          ; spill restored X before dsk_row_ptr clobbers it
    jsr dsk_row_ptr
    ldx DSK_ERROR_CODE

    ; Bounds check: is entry X within the loaded directory?
    pla                         ; done with viewport row
    txa                         ; A = entry index
    cmp DSK_ENTRY_COUNT
    bcs @blank                  ; entry index >= count: blank row, done

    ; Load cache pointer for this entry
    stx DSK_ERROR_CODE
    jsr dsk_entry_ptr           ; DSK_PTR → cache entry (A = entry index)
    ldx DSK_ERROR_CODE
                                ; but we need DSK_PTR2 for screen, DSK_PTR for cache
                                ; Problem: dsk_entry_ptr clobbers DSK_PTR which we
                                ; need for screen! Use DSK_PTR2 for screen, DSK_PTR for cache.
                                ; BUT dsk_row_ptr used DSK_PTR2... we need to recompute.
                                ; Refactor: store screen row address in a fixed location first.

    ; The above has a register collision. Reorganize:
    ; Step 1: compute entry index into DSK_TMP (done above)
    ; Step 2: get screen row pointer into DSK_PTR2 (done above via dsk_row_ptr)
    ; Step 3: get cache entry pointer into DSK_PTR (via dsk_entry_ptr)
    ; dsk_entry_ptr uses DSK_PTR. dsk_row_ptr result was in DSK_PTR2.
    ; So we're OK as long as dsk_entry_ptr doesn't touch DSK_PTR2.
    ; Let's make dsk_entry_ptr use DSK_PTR only and verify.
    ; dsk_row_ptr: result → DSK_PTR2 (we'll write a separate version below)
    ; The issue: earlier dsk_row_ptr wrote to DSK_PTR. Fix: make dsk_row_ptr
    ; write to DSK_PTR2, and dsk_entry_ptr write to DSK_PTR.
    ; See implementations below — this is settled there.

    ; Write filename (bytes 0-15 of entry), converting PETSCII to screen codes
    ldy #0
@fname:
    lda (DSK_PTR),y             ; cache entry byte y (filename char)
    jsr dsk_petscii_to_sc
    sta (DSK_PTR2),y            ; screen RAM
    iny
    cpy #16
    bne @fname

    ; Write type indicator at col 17
    ldy #16
    lda (DSK_PTR),y             ; file type byte
    jsr dsk_type_char           ; → A = single screen-code char
    ldy #17
    sta (DSK_PTR2),y

    ; Write block count at cols 20-23 (right side)
    ldy #17
    lda (DSK_PTR),y             ; blocks lo
    sta DSK_TMP                 ; reuse DSK_TMP (entry index is stale now, ok)
    ldy #18
    lda (DSK_PTR),y             ; blocks hi
    sta DSK_TMP2
    ; print decimal at screen col 20
    jsr dsk_print_blk_count
    rts

@blank:
    rts

; ============================================================================
; dsk_type_char — convert CBM file type byte to a screen code indicator char.
; $82=PRG → 'P', $81=SEQ → 'S', $83=USR → 'U', $80=DEL → 'D', else → '?'
; ============================================================================

dsk_type_char:
    cmp #$82
    bne @try_seq
    lda #$10                    ; 'P'
    rts
@try_seq:
    cmp #$81
    bne @try_usr
    lda #$13                    ; 'S'
    rts
@try_usr:
    cmp #$83
    bne @try_del2
    lda #$15                    ; 'U'
    rts
@try_del2:
    cmp #$80
    bne @unk
    lda #$04                    ; 'D'
    rts
@unk:
    lda #$3F                    ; '?'
    rts

; ============================================================================
; dsk_row_ptr — set DSK_PTR2 to screen RAM start of row A.
; Clobbers A, X.
; ============================================================================

dsk_row_ptr:
    tax
    lda #0
    sta DSK_PTR2
    sta DSK_PTR2+1
    cpx #0
    beq @base
@mul:
    lda DSK_PTR2
    clc
    adc #COLS
    sta DSK_PTR2
    bcc :+
    inc DSK_PTR2+1
:   dex
    bne @mul
@base:
    lda #<SCREEN
    clc
    adc DSK_PTR2
    sta DSK_PTR2
    lda #>SCREEN
    adc DSK_PTR2+1
    sta DSK_PTR2+1
    rts

; ============================================================================
; dsk_color_row — paint color RAM row A with color in DSK_TMP2.
; Clobbers A, X, Y.
; ============================================================================

dsk_color_row:
    ; Compute color RAM row address using DSK_PTR ($FB/$FC) as scratch.
    ; Reads color from DSK_TMP2. Clobbers A, X, DSK_PTR/$FB/$FC.
    ; Does NOT touch DSK_TMP ($CAF2) -- callers rely on DSK_TMP being preserved.
    tax
    lda #0
    sta DSK_PTR
    sta DSK_PTR+1
    cpx #0
    beq @base
@mul:
    lda DSK_PTR
    clc
    adc #COLS
    sta DSK_PTR
    bcc :+
    inc DSK_PTR+1
:   dex
    bne @mul
@base:
    lda #<COLOR
    clc
    adc DSK_PTR
    sta DSK_PTR
    lda #>COLOR
    adc DSK_PTR+1
    sta DSK_PTR+1
    ldy #0
    lda DSK_TMP2
@paint:
    sta (DSK_PTR),y
    iny
    cpy #COLS
    bne @paint
    rts

; ============================================================================
; dsk_cursor_up — move selection up one entry, scroll if needed.
; ============================================================================

dsk_cursor_up:
    lda DSK_SEL
    beq @wrap                   ; at top — wrap to bottom
    dec DSK_SEL
    ; Scroll viewport if selection moved above view
    lda DSK_SEL
    cmp DSK_VIEW_START
    bcs @redraw                 ; sel >= view_start: no scroll
    dec DSK_VIEW_START
    jmp @redraw
@wrap:
    ; Wrap to last entry
    lda DSK_ENTRY_COUNT
    beq @redraw                 ; no entries
    sec
    sbc #1
    sta DSK_SEL
    ; Set view_start so last entry is visible
    lda DSK_ENTRY_COUNT
    cmp #DSK_VIEW_ROWS
    bcc @wrap_fit               ; fewer than 20 entries
    sec
    sbc #DSK_VIEW_ROWS
    sta DSK_VIEW_START
    jmp @redraw
@wrap_fit:
    lda #0
    sta DSK_VIEW_START
@redraw:
    jsr dsk_draw_entries
    rts

; ============================================================================
; dsk_cursor_down — move selection down one entry, scroll if needed.
; ============================================================================

dsk_cursor_down:
    lda DSK_ENTRY_COUNT
    beq @done                   ; no entries
    lda DSK_SEL
    clc
    adc #1
    cmp DSK_ENTRY_COUNT
    bcc @not_wrap
    ; Wrap to top
    lda #0
    sta DSK_SEL
    sta DSK_VIEW_START
    jsr dsk_draw_entries
    rts
@not_wrap:
    sta DSK_SEL
    ; Scroll down if selection moved below visible window.
    ; Last visible index is view_start + ROWS - 1; comparing against
    ; view_start + ROWS counted sel == view_start+ROWS as "in view" and
    ; left the highlight off-screen for one keypress at the bottom row.
    lda DSK_VIEW_START
    clc
    adc #DSK_VIEW_ROWS-1
    cmp DSK_SEL
    bcs @redraw                 ; view_start + ROWS - 1 >= sel: in view
    ; sel is below window: advance view_start
    lda DSK_SEL
    sec
    sbc #(DSK_VIEW_ROWS - 1)
    sta DSK_VIEW_START
@redraw:
    jsr dsk_draw_entries
@done:
    rts

; ============================================================================
; dsk_do_open — RETURN handler.
;
; Copies selected entry's filename into editor's FNAME_BUF/FNAME_LEN via
; the extended parameter block pointers (DSK_FNAME_BUF_LO/HI etc).
; Sets MOD_STATUS=$04 and returns C=0 (signal to exit loop and return).
; If no entries, returns C=1 (stay in loop).
; ============================================================================

dsk_do_open:
    lda DSK_ENTRY_COUNT
    beq @no_entries

    ; Get pointer to selected entry
    lda DSK_SEL
    jsr dsk_entry_ptr           ; DSK_PTR → selected cache entry

    ; Set up DSK_PTR2 → editor's FNAME_BUF (from extended param block)
    lda DSK_FNAME_BUF_LO
    sta DSK_PTR2
    lda DSK_FNAME_BUF_HI
    sta DSK_PTR2+1

    ; Copy 16 bytes of filename
    ldy #0
@copy:
    lda (DSK_PTR),y
    sta (DSK_PTR2),y
    iny
    cpy #16
    bne @copy

    ; Trim trailing spaces to get true length
    ldy #15
@trim:
    lda (DSK_PTR2),y
    cmp #$20
    bne @trimmed
    dey
    bpl @trim
@trimmed:
    iny                         ; y = length (0 if all spaces, but that won't happen)

    ; Write FNAME_LEN via its pointer
    lda DSK_FNAME_LEN_LO
    sta DSK_PTR2
    lda DSK_FNAME_LEN_HI
    sta DSK_PTR2+1
    tya
    ldy #0
    sta (DSK_PTR2),y

    ; Signal editor to load
    lda #$04
    sta MOD_STATUS
    clc
    rts

@no_entries:
    sec
    rts

; ============================================================================
; dsk_do_format — F handler.
;
; Shows "FORMAT? Y/N" confirm, then prompts for disk name (max 16) and 2-char ID.
; Sends "N0:<name>,<id>" to command channel.
; Redraws after (will show empty directory).
; ============================================================================

dsk_do_format:
    ; Confirm
    jsr dsk_clear_legend
    ldy #0
@lbl:
    lda dsk_fmt_confirm,y
    beq @wait
    sta SCREEN+(24*COLS),y
    iny
    bne @lbl
@wait:
    jsr GETIN
    beq @wait
    cmp #$03
    beq @cancel
    cmp #$59                    ; 'Y'
    beq @get_name
    cmp #$79
    beq @get_name
    jmp @cancel

@get_name:
    ; Prompt for disk name
    jsr dsk_clear_legend
    ldy #0
@namelbl:
    lda dsk_fmt_name_prompt,y
    beq @name_input
    sta SCREEN+(24*COLS),y
    iny
    bne @namelbl
@name_input:
    lda #0
    sta DSK_NAMELEN_TMP
@flush2:
    jsr GETIN
    bne @flush2
@ninp:
    lda JIFFY_LO
    and #$10
    beq @ncur_off
    lda #$20 | $80
    jmp @ncur_draw
@ncur_off:
    lda #$20
@ncur_draw:
    ldy DSK_NAMELEN_TMP
    sta SCREEN+(24*COLS)+10,y
    jsr GETIN
    beq @ninp
    cmp #$03
    beq @cancel
    cmp #$0D
    beq @got_name
    cmp #$14
    bne @nchar
    lda DSK_NAMELEN_TMP
    beq @ninp
    ldy DSK_NAMELEN_TMP
    dey
    lda #$20
    sta SCREEN+(24*COLS)+10,y
    dec DSK_NAMELEN_TMP
    jmp @ninp
@nchar:
    cmp #$20
    bcc @ninp
    ldy DSK_NAMELEN_TMP
    cpy #16
    bcs @ninp
    sta DSK_INPUT_BUF,y
    jsr dsk_petscii_to_sc
    sta SCREEN+(24*COLS)+10,y
    inc DSK_NAMELEN_TMP
    jmp @ninp

@got_name:
    jsr dsk_do_format_id        ; prompt for ID then send command; C=1 = cancel
    bcc @fmt_refresh
@cancel:
    jsr dsk_draw_legend
    rts

@fmt_refresh:
    lda #0
    sta DSK_PAGE
    sta DSK_SKIP
    sta DSK_SKIP_HI
    sta DSK_ENTRY_COUNT
    sta DSK_SEL
    sta DSK_VIEW_START
    sta DSK_TRUNCATED
    jsr dsk_read_directory
    jsr dsk_draw_full
    rts

; ============================================================================
; dsk_do_format_id — second half of format: ID prompt + send command + poll.
; Called from dsk_do_format after disk name is collected in DSK_INPUT_BUF.
; DSK_NAMELEN_TMP holds the disk name length on entry.
; C=0 format sent OK, C=1 cancelled.
; ============================================================================

dsk_do_format_id:
    ; Prompt for 2-char disk ID
    jsr dsk_clear_legend
    ldy #0
@idlbl:
    lda dsk_fmt_id_prompt,y
    beq @id_input
    sta SCREEN+(24*COLS),y
    iny
    bne @idlbl
@id_input:
    lda #$20
    sta DSK_INPUT_BUF+16
    sta DSK_INPUT_BUF+17
    lda #0
    sta DSK_TMP                 ; id chars entered
@idinp:
    lda JIFFY_LO
    and #$10
    beq @icur_off
    lda #$20 | $80
    jmp @icur_draw
@icur_off:
    lda #$20
@icur_draw:
    ldy DSK_TMP
    sta SCREEN+(24*COLS)+9,y
    jsr GETIN
    beq @idinp
    cmp #$03
    beq @cancel
    cmp #$0D
    beq @do_format
    cmp #$14
    bne @idchar
    lda DSK_TMP
    beq @idinp
    ldy DSK_TMP
    dey
    lda #$20
    sta SCREEN+(24*COLS)+9,y
    dec DSK_TMP
    jmp @idinp
@idchar:
    cmp #$20
    bcc @idinp
    ldy DSK_TMP
    cpy #2
    bcs @idinp
    sta DSK_INPUT_BUF+16,y
    jsr dsk_petscii_to_sc
    sta SCREEN+(24*COLS)+9,y
    inc DSK_TMP
    jmp @idinp

@do_format:
    lda DSK_TMP                 ; CBM DOS requires exactly a 2-char ID
    cmp #2
    bcs :+
@cancel:
    sec
    rts
:
    ; Show "FORMATTING..." on title row
    ldy #0
@fmting:
    lda dsk_formatting_msg,y
    beq @send_fmt
    sta SCREEN,y
    lda #CLR_ERROR
    sta COLOR,y
    iny
    bne @fmting

@send_fmt:
    lda #15
    ldx DSK_DRIVE
    ldy #15
    jsr SETLFS
    lda #0
    ldx #0
    ldy #0
    jsr SETNAM
    jsr OPEN
    bcc @cmd_ok
    sec
    rts
@cmd_ok:
    ldx #15
    jsr CHKOUT
    bcc @send
    lda #15
    jsr CLOSE
    sec
    rts

@send:
    ; "N0:<name>,<id>,P\r"
    lda #$4E                    ; 'N'
    jsr CHROUT
    lda #$30                    ; '0'
    jsr CHROUT
    lda #$3A                    ; ':'
    jsr CHROUT
    ldy #0
@fmt_name:
    cpy DSK_NAMELEN_TMP
    beq @fmt_comma
    lda DSK_INPUT_BUF,y
    jsr CHROUT
    iny
    jmp @fmt_name
@fmt_comma:
    ; "N0:<name>,<id>" — note: NO ",P" suffix.  ",P" is a LOAD/SAVE
    ; file-type suffix, not part of the NEW command; some DOSes answer it
    ; with 30,SYNTAX ERROR and silently skip the format.
    lda #$2C
    jsr CHROUT
    lda DSK_INPUT_BUF+16
    jsr CHROUT
    lda DSK_INPUT_BUF+17        ; always present — 2-char ID enforced above
    jsr CHROUT
    lda #$0D
    jsr CHROUT
    jsr CLRCHN
    lda #15
    jsr CLOSE

    ; Poll status channel until format completes
    lda #15
    ldx DSK_DRIVE
    ldy #15
    jsr SETLFS
    lda #0
    ldx #0
    ldy #0
    jsr SETNAM
    jsr OPEN
    bcc @poll_ok
    clc                         ; format was sent; poll failure is non-fatal
    rts
@poll_ok:
    ldx #15
    jsr CHKIN
    bcc @poll_loop
    lda #15
    jsr CLOSE
    clc
    rts
@poll_loop:
    ; The drive answers the status channel only once the format finishes
    ; (~40 s on a real 1541).  Capture the two-digit DOS code — it was
    ; previously discarded, so failures like 26,WRITE PROTECT ON looked
    ; identical to success (the user just saw an empty directory).
    jsr CHRIN
    sta DSK_TMP2                ; first status digit (PETSCII '0'-'9')
    jsr CHRIN
    sta DSK_NAMELEN_TMP         ; second status digit
@drain_status:
    jsr CHRIN
    cmp #$0D
    bne @drain_status
    jsr CLRCHN
    lda #15
    jsr CLOSE
    ; "00, OK" = success; anything else is a DOS error — surface it.
    lda DSK_TMP2
    cmp #$30
    bne @fmt_failed
    lda DSK_NAMELEN_TMP
    cmp #$30
    bne @fmt_failed
    clc
    rts
@fmt_failed:
    ; Show "FORMAT ERROR NN" (NN = DOS code) on the title row, hold ~1.5s.
    ldy #0
@fe_wr:
    lda dsk_fmt_err_text,y
    beq @fe_code
    sta SCREEN,y
    lda #CLR_ERROR
    sta COLOR,y
    iny
    bne @fe_wr
@fe_code:
    ; Digit PETSCII $30-$39 == digit screen codes, so store directly.
    lda DSK_TMP2
    sta SCREEN,y
    lda #CLR_ERROR
    sta COLOR,y
    iny
    lda DSK_NAMELEN_TMP
    sta SCREEN,y
    lda #CLR_ERROR
    sta COLOR,y
    iny
    lda #$20                    ; blank the leftover "FORMATTING..." tail
    sta SCREEN,y
    sta SCREEN+1,y
    lda JIFFY_LO
    clc
    adc #90
    sta DSK_TMP
@fe_spin:
    lda JIFFY_LO
    cmp DSK_TMP
    bne @fe_spin
    clc                         ; still C=0: caller refreshes the directory
    rts

; "FORMAT? Y/N " in screen codes
dsk_fmt_confirm:
    .byte $06,$0F,$12,$0D,$01,$14,$3F,$20,$19,$2F,$0E,$20, 0

; "DISK NAME: " in screen codes
dsk_fmt_name_prompt:
    .byte $04,$09,$13,$0B,$20,$0E,$01,$0D,$05,$3A,$20, 0

; "DISK ID: " in screen codes  (2 chars)
dsk_fmt_id_prompt:
    .byte $04,$09,$13,$0B,$20,$09,$04,$3A,$20, 0

; "FORMATTING...   " in screen codes
dsk_formatting_msg:
    .byte $06,$0F,$12,$0D,$01,$14,$14,$09,$0E,$07,$2E,$2E,$2E,$20,$20,$20, 0

; "FORMAT ERROR " screen codes (DOS code digits appended at runtime)
dsk_fmt_err_text:
    .byte $06,$0F,$12,$0D,$01,$14,$20,$05,$12,$12,$0F,$12,$20, 0

; ============================================================================
; dsk_page_next — F4 handler: advance to the next page of directory entries.
;
; Only acts if DSK_TRUNCATED=$FF (meaning there are more entries beyond the
; current cache).  Increments DSK_PAGE, recomputes DSK_SKIP, resets the
; viewport and selection, re-reads the directory, and redraws.
; ============================================================================

dsk_page_next:
    lda DSK_TRUNCATED
    cmp #$FF
    bne @at_end                 ; not truncated: already on last page
    inc DSK_PAGE
    jmp dsk_page_reload
@at_end:
    rts

; ============================================================================
; dsk_page_prev — F2 handler: go back to the previous page.
;
; Only acts if DSK_PAGE > 0.  Decrements DSK_PAGE, recomputes DSK_SKIP,
; resets viewport and selection, re-reads, redraws.
; ============================================================================

dsk_page_prev:
    lda DSK_PAGE
    beq @at_start               ; already on page 0
    dec DSK_PAGE
    jmp dsk_page_reload
@at_start:
    rts

; ============================================================================
; dsk_page_reload — common tail for page_next/page_prev.
;
; Computes DSK_SKIP = DSK_PAGE × DSK_MAX_ENTRIES via repeated addition,
; resets cache state, and re-reads + redraws the directory.
; ============================================================================

dsk_page_reload:
    ; Compute DSK_SKIP (16-bit) = DSK_PAGE * DSK_MAX_ENTRIES.
    ; 8-bit math wrapped at page 3 (300 entries) on big CMD/SD2IEC dirs.
    lda #0
    sta DSK_SKIP
    sta DSK_SKIP_HI
    ldx DSK_PAGE
    beq @skip_done              ; page 0: skip = 0
@mul_loop:
    lda DSK_SKIP
    clc
    adc #DSK_MAX_ENTRIES
    sta DSK_SKIP
    bcc :+
    inc DSK_SKIP_HI
:   dex
    bne @mul_loop
@skip_done:
    ; Reset viewport and cache; preserve DSK_PAGE and DSK_SKIP
    lda #0
    sta DSK_ENTRY_COUNT
    sta DSK_SEL
    sta DSK_VIEW_START
    sta DSK_TRUNCATED
    jsr dsk_read_directory
    jsr dsk_draw_full
    rts

; ============================================================================
; dsk_do_rawcmd — @ handler: send a raw command string to the drive.
;
; Shows "@CMD:" prompt on the legend row and reads up to 32 PETSCII chars
; from the keyboard.  On RETURN the string is sent verbatim to LA=15/SA=15
; followed by CR.  The status channel is then read back and displayed on
; row 0 for ~2 seconds.  The directory is always reloaded afterwards,
; whether the command succeeded or not (a CD changes the directory; a UI
; reset, I initialize, etc. all warrant a fresh listing).
;
; Useful for CMD HD / FD / RAMLink path navigation:
;   CD/GAMES        — change into sub-directory GAMES
;   CD//            — back to root
;   CD←             — up one level  (← = $5F PETSCII, left-arrow)
;   /               — query current path (result shown on row 0)
;   UI              — soft reset drive
;   I               — initialize
;
; Input is raw PETSCII stored in DSK_CMD_BUF (32 bytes).
; The screen shows screen-code equivalents so the user can see what they
; typed; the buffer holds the original PETSCII for transmission.
;
; Cancel with STOP — restores legend, does NOT reload directory.
; ============================================================================

dsk_do_rawcmd:
    ; Show "@CMD: " prompt on legend row in CLR_PROMPT color.
    ; Written inline (not loop) because '@' screen code = $00 which
    ; collides with the null terminator a loop would use.
    jsr dsk_clear_legend
    lda #$00                    ; '@' screen code
    sta SCREEN+(24*COLS)+0
    lda #$03                    ; 'C'
    sta SCREEN+(24*COLS)+1
    lda #$0D                    ; 'M'
    sta SCREEN+(24*COLS)+2
    lda #$04                    ; 'D'
    sta SCREEN+(24*COLS)+3
    lda #$3A                    ; ':'
    sta SCREEN+(24*COLS)+4
    lda #$20                    ; ' '
    sta SCREEN+(24*COLS)+5
    ; Paint all 6 prompt chars CLR_PROMPT in color RAM
    lda #CLR_PROMPT
    sta COLOR+(24*COLS)+0
    sta COLOR+(24*COLS)+1
    sta COLOR+(24*COLS)+2
    sta COLOR+(24*COLS)+3
    sta COLOR+(24*COLS)+4
    sta COLOR+(24*COLS)+5

@setup_input:
    lda #0
    sta DSK_CMD_LEN

    ; Flush keyboard buffer
@flush:
    jsr GETIN
    bne @flush

    ; Input loop — cursor blinks at legend col 6 + DSK_CMD_LEN
@inp_loop:
    lda JIFFY_LO
    and #$10
    beq @cur_off
    lda #$20 | $80              ; reverse-space = blinking cursor
    jmp @cur_draw
@cur_off:
    lda #$20
@cur_draw:
    ldy DSK_CMD_LEN
    sta SCREEN+(24*COLS)+6,y
    lda #CLR_INPUT
    sta COLOR+(24*COLS)+6,y

    jsr GETIN
    beq @inp_loop

    cmp #$03                    ; STOP = cancel
    bne :+
    jmp @cancel
:
    cmp #$0D                    ; RETURN = execute
    bne :+
    jmp @execute
:
    cmp #$14                    ; DEL = backspace
    bne @inp_char
    lda DSK_CMD_LEN
    beq @inp_loop               ; nothing to delete
    ldy DSK_CMD_LEN
    dey
    lda #$20
    sta SCREEN+(24*COLS)+6,y   ; erase char on screen
    dec DSK_CMD_LEN
    jmp @inp_loop

@inp_char:
    ; Accept printable chars ($20-$FE) up to 32 chars.
    cmp #$20
    bcc @inp_loop               ; control chars: ignore
    ldy DSK_CMD_LEN
    cpy #32
    bcs @inp_loop               ; buffer full: ignore
    ; Store raw PETSCII in buffer, display as screen code in CLR_INPUT
    sta DSK_CMD_BUF,y
    jsr dsk_petscii_to_sc
    sta SCREEN+(24*COLS)+6,y
    lda #CLR_INPUT
    sta COLOR+(24*COLS)+6,y
    inc DSK_CMD_LEN
    jmp @inp_loop

@execute:
    lda DSK_CMD_LEN
    bne @send                   ; non-empty: proceed
    jmp @cancel                 ; empty command: cancel silently

@send:
    ; Open command channel LA=15, device=DSK_DRIVE, SA=15
    lda #15
    ldx DSK_DRIVE
    ldy #15
    jsr SETLFS
    lda #0
    ldx #0
    ldy #0
    jsr SETNAM
    jsr OPEN
    bcc @cmd_ok
    jmp @reload                 ; OPEN failed — reload anyway

@cmd_ok:
    ldx #15
    jsr CHKOUT
    bcc @send_bytes
    lda #15
    jsr CLOSE
    jmp @reload

@send_bytes:
    ; Send DSK_CMD_BUF[0..DSK_CMD_LEN-1] then CR
    ldy #0
@send_loop:
    cpy DSK_CMD_LEN
    beq @send_cr
    lda DSK_CMD_BUF,y
    jsr CHROUT
    iny
    bne @send_loop
@send_cr:
    lda #$0D
    jsr CHROUT
    jsr CLRCHN

    ; Read status response from command channel into row 0.
    ; Status format: "NN,message,TT,SS" e.g. "00, OK,00,00"
    ; We display raw bytes as screen codes until CR ($0D) or 40 chars.
    ldx #15
    jsr CHKIN
    bcc @read_status
    lda #15
    jsr CLOSE
    jmp @reload

@read_status:
    ; Clear row 0 first
    ldy #0
    lda #$20
@clr_row0:
    sta SCREEN,y
    lda #CLR_CHROME
    sta COLOR,y
    lda #$20
    iny
    cpy #COLS
    bne @clr_row0

    ; Read status bytes, display as screen codes on row 0
    ldy #0
@read_loop:
    cpy #COLS
    beq @read_drain             ; row full — drain rest silently
    jsr CHRIN
    cmp #$0D                    ; CR = end of status line
    beq @status_done
    pha
    jsr dsk_petscii_to_sc
    sta SCREEN,y
    lda #CLR_TITLE
    sta COLOR,y
    pla
    iny
    jmp @read_loop

@read_drain:
    jsr CHRIN
    cmp #$0D
    bne @read_drain

@status_done:
    jsr CLRCHN
    lda #15
    jsr CLOSE

    ; Pause ~2 seconds (120 jiffies) so user can read the status.
    ; Use BNE comparison: works correctly even when target wraps past $FF
    ; because we're comparing for inequality until the jiffy clock catches up.
    lda JIFFY_LO
    clc
    adc #120
    sta DSK_TMP
@pause:
    lda JIFFY_LO
    cmp DSK_TMP
    bne @pause

@reload:
    ; After any raw command, always reset to page 0 and reload.
    ; A CD command changes the directory entirely so the old page offset
    ; is meaningless. UI/I/format also warrant a fresh listing from the top.
    lda #0
    sta DSK_PAGE
    sta DSK_SKIP
    sta DSK_SKIP_HI
    sta DSK_ENTRY_COUNT
    sta DSK_SEL
    sta DSK_VIEW_START
    sta DSK_TRUNCATED
    jsr dsk_read_directory
    jsr dsk_draw_full
    rts

@cancel:
    jsr dsk_draw_legend
    rts

; ============================================================================
; dsk_clear_legend — blank the legend row before showing a prompt.
; ============================================================================

dsk_clear_legend:
    ldy #0
    lda #$20
@loop:
    sta SCREEN+(24*COLS),y
    lda #CLR_LEGEND
    sta COLOR+(24*COLS),y
    lda #$20
    iny
    cpy #COLS
    bne @loop
    rts

; ============================================================================
; dsk_show_error — show "DISK ERROR" on row 0, wait ~1.5s, return.
; ============================================================================

dsk_show_error:
    ldy #0
@wr:
    lda dsk_err_text,y
    beq @wait
    sta SCREEN,y
    lda #CLR_ERROR
    sta COLOR,y
    iny
    bne @wr
@wait:
    lda JIFFY_LO
    clc
    adc #90
    sta DSK_TMP
@spin:
    lda JIFFY_LO
    cmp DSK_TMP
    bne @spin
    rts

; "DISK ERROR        " screen codes
dsk_err_text:
    .byte $04,$09,$13,$0B,$20,$05,$12,$12,$0F,$12,$20,$20,$20,$20,$20,$20,$20,$20, 0

; ============================================================================
; dsk_print_decimal — print DSK_TMP/DSK_TMP2 (16-bit) as decimal on row 1.
; Writes up to 3 digits at SCREEN+COLS+29..+31.
; 16-bit subtract: handles up to 664 blocks (1541 max).
; Uses 16-bit subtraction of 100 and 10 via carry.
; ============================================================================

dsk_print_decimal:
    lda #$20
    sta SCREEN+COLS+29
    sta SCREEN+COLS+30
    sta SCREEN+COLS+31
    ; Count hundreds via 16-bit subtraction of 100
    lda #0
    sta DSK_NAMELEN_TMP
@h:
    ; 16-bit compare DSK_TMP2:DSK_TMP >= 100
    lda DSK_TMP2
    bne @h_sub              ; hi byte non-zero means >= 256 >= 100
    lda DSK_TMP
    cmp #100
    bcc @h_done
@h_sub:
    lda DSK_TMP
    sec
    sbc #100
    sta DSK_TMP
    lda DSK_TMP2
    sbc #0
    sta DSK_TMP2
    inc DSK_NAMELEN_TMP
    jmp @h
@h_done:
    lda DSK_NAMELEN_TMP
    beq @no_hundreds
    clc
    adc #$30
    sta SCREEN+COLS+29
@no_hundreds:
    ; Count tens (DSK_TMP2 must be 0 here, value < 100)
    lda #0
    sta DSK_NAMELEN_TMP
    lda DSK_TMP
@t:
    cmp #10
    bcc @t_done
    sec
    sbc #10
    inc DSK_NAMELEN_TMP
    jmp @t
@t_done:
    pha
    lda DSK_NAMELEN_TMP
    clc
    adc #$30
    sta SCREEN+COLS+30
    pla
    clc
    adc #$30
    sta SCREEN+COLS+31
    rts

; ============================================================================
; dsk_print_blk_count — print block count (DSK_TMP/DSK_TMP2) right-justified
; in a 4-char field at screen column 33-36 of the current entry row.
; Uses DSK_PTR2 as screen row base (set by dsk_draw_one_entry).
; ============================================================================

dsk_print_blk_count:
    ; For 1541: max blocks per file is about 664.
    ; Just print as 3-digit decimal at cols 20-22 of the entry row.
    ldy #20
    lda #$20
    sta (DSK_PTR2),y
    ldy #21
    sta (DSK_PTR2),y
    ldy #22
    sta (DSK_PTR2),y

    ; Hundreds
    lda DSK_TMP
    sta DSK_NAMELEN_TMP              ; save
    lda #0
    sta DSK_TMP2
@bh:
    lda DSK_NAMELEN_TMP
    cmp #100
    bcc @bh_done
    sec
    sbc #100
    sta DSK_NAMELEN_TMP
    inc DSK_TMP2
    jmp @bh
@bh_done:
    lda DSK_TMP2
    beq @bt
    clc
    adc #$30
    ldy #20
    sta (DSK_PTR2),y

    ; Tens
@bt:
    lda #0
    sta DSK_TMP2
@bt_loop:
    lda DSK_NAMELEN_TMP
    cmp #10
    bcc @bt_done
    sec
    sbc #10
    sta DSK_NAMELEN_TMP
    inc DSK_TMP2
    jmp @bt_loop
@bt_done:
    lda DSK_TMP2
    clc
    adc #$30
    ldy #21
    sta (DSK_PTR2),y
    ; Units
    lda DSK_NAMELEN_TMP
    clc
    adc #$30
    ldy #22
    sta (DSK_PTR2),y
    rts

; ============================================================================
; dsk_petscii_to_sc — convert PETSCII byte in A to screen code.
; Same logic as loadsave.asm's petscii_to_screen.
; Clobbers A only.
; ============================================================================

dsk_petscii_to_sc:
    cmp #$40
    bcc @keep
    cmp #$60
    bcc @sub40
    cmp #$80
    bcc @sub20
    and #$7F
    rts
@keep:   rts
@sub40:  sec
         sbc #$40
         rts
@sub20:  sec
         sbc #$20
         rts

; ============================================================================
; Data
; ============================================================================

dsk_dir_name:
    .byte "$"

; ============================================================================
; Integration notes (all patches below are already applied in the codebase):
;
; modules.asm holds MODDSK as index 3 in all mod_fname_*/mod_desc_*/mod_load_*
; tables.  run_module_by_index populates DSK_FNAME_BUF_LO/HI and
; DSK_FNAME_LEN_LO/HI in the extended parameter block before calling the module.
;
; MOD_STATUS=$04 (open selected file) is handled in run_selected_module:
; it calls do_load_file_from_fname in loadsave.asm, which loads the file
; named in FNAME_BUF/FNAME_LEN without showing a filename prompt.
; ============================================================================

