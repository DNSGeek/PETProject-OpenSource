                                * = $E000
E000   85 56                    STA $56
E002   20 0F BC                 JSR $BC0F
E005   A5 61                    LDA $61
E007   C9 88                    CMP #$88
E009   90 03                    BCC LE00E
E00B   20 D4 BA   LE00B         JSR $BAD4
E00E   20 CC BC   LE00E         JSR $BCCC
E011   A5 07                    LDA $07
E013   18                       CLC
E014   69 81                    ADC #$81
E016   F0 F3                    BEQ LE00B
E018   38                       SEC
E019   E9 01                    SBC #$01
E01B   48                       PHA
E01C   A2 05                    LDX #$05
E01E   B5 69      LE01E         LDA $69,X
E020   B4 61                    LDY $61,X
E022   95 61                    STA $61,X
E024   94 69                    STY $69,X
E026   CA                       DEX
E027   10 F5                    BPL LE01E
E029   A5 56                    LDA $56
E02B   85 70                    STA $70
E02D   20 53 B8                 JSR $B853
E030   20 B4 BF                 JSR $BFB4
E033   A9 C4                    LDA #$C4
E035   A0 BF                    LDY #$BF
E037   20 59 E0                 JSR LE059
E03A   A9 00                    LDA #$00
E03C   85 6F                    STA $6F
E03E   68                       PLA
E03F   20 B9 BA                 JSR $BAB9
E042   60                       RTS
E043   85 71      LE043         STA $71
E045   84 72                    STY $72
E047   20 CA BB                 JSR $BBCA
E04A   A9 57                    LDA #$57
E04C   20 28 BA                 JSR $BA28
E04F   20 5D E0                 JSR LE05D
E052   A9 57                    LDA #$57
E054   A0 00                    LDY #$00
E056   4C 28 BA                 JMP $BA28
E059   85 71      LE059         STA $71
E05B   84 72                    STY $72
E05D   20 C7 BB   LE05D         JSR $BBC7
E060   B1 71                    LDA ($71),Y
E062   85 67                    STA $67
E064   A4 71                    LDY $71
E066   C8                       INY
E067   98                       TYA
E068   D0 02                    BNE LE06C
E06A   E6 72                    INC $72
E06C   85 71      LE06C         STA $71
E06E   A4 72                    LDY $72
E070   20 28 BA   LE070         JSR $BA28
E073   A5 71                    LDA $71
E075   A4 72                    LDY $72
E077   18                       CLC
E078   69 05                    ADC #$05
E07A   90 01                    BCC LE07D
E07C   C8                       INY
E07D   85 71      LE07D         STA $71
E07F   84 72                    STY $72
E081   20 67 B8                 JSR $B867
E084   A9 5C                    LDA #$5C
E086   A0 00                    LDY #$00
E088   C6 67                    DEC $67
E08A   D0 E4                    BNE LE070
E08C   60                       RTS
E08D   98                       TYA
E08E   35 44                    AND $44,X
E090   7A                       ???               ;%01111010 'z'
E091   00                       BRK
E092   68                       PLA
E093   28                       PLP
E094   B1 46                    LDA ($46),Y
E096   00                       BRK
E097   20 2B BC                 JSR $BC2B
E09A   30 37                    BMI LE0D3
E09C   D0 20                    BNE LE0BE
E09E   20 F3 FF                 JSR LFFF3
E0A1   86 22                    STX $22
E0A3   84 23                    STY $23
E0A5   A0 04                    LDY #$04
E0A7   B1 22                    LDA ($22),Y
E0A9   85 62                    STA $62
E0AB   C8                       INY
E0AC   B1 22                    LDA ($22),Y
E0AE   85 64                    STA $64
E0B0   A0 08                    LDY #$08
E0B2   B1 22                    LDA ($22),Y
E0B4   85 63                    STA $63
E0B6   C8                       INY
E0B7   B1 22                    LDA ($22),Y
E0B9   85 65                    STA $65
E0BB   4C E3 E0                 JMP LE0E3
E0BE   A9 8B      LE0BE         LDA #$8B
E0C0   A0 00                    LDY #$00
E0C2   20 A2 BB                 JSR $BBA2
E0C5   A9 8D                    LDA #$8D
E0C7   A0 E0                    LDY #$E0
E0C9   20 28 BA                 JSR $BA28
E0CC   A9 92                    LDA #$92
E0CE   A0 E0                    LDY #$E0
E0D0   20 67 B8                 JSR $B867
E0D3   A6 65      LE0D3         LDX $65
E0D5   A5 62                    LDA $62
E0D7   85 65                    STA $65
E0D9   86 62                    STX $62
E0DB   A6 63                    LDX $63
E0DD   A5 64                    LDA $64
E0DF   85 63                    STA $63
E0E1   86 64                    STX $64
E0E3   A9 00      LE0E3         LDA #$00
E0E5   85 66                    STA $66
E0E7   A5 61                    LDA $61
E0E9   85 70                    STA $70
E0EB   A9 80                    LDA #$80
E0ED   85 61                    STA $61
E0EF   20 D7 B8                 JSR $B8D7
E0F2   A2 8B                    LDX #$8B
E0F4   A0 00                    LDY #$00
E0F6   4C D4 BB   LE0F6         JMP $BBD4
E0F9   C9 F0      LE0F9         CMP #$F0
E0FB   D0 07                    BNE LE104
E0FD   84 38                    STY $38
E0FF   86 37                    STX $37
E101   4C 63 A6                 JMP $A663
E104   AA         LE104         TAX
E105   D0 02                    BNE LE109
E107   A2 1E                    LDX #$1E
E109   4C 37 A4   LE109         JMP $A437
E10C   20 D2 FF                 JSR LFFD2
E10F   B0 E8                    BCS LE0F9
E111   60                       RTS
E112   20 CF FF                 JSR LFFCF
E115   B0 E2                    BCS LE0F9
E117   60                       RTS
E118   20 AD E4                 JSR LE4AD
E11B   B0 DC                    BCS LE0F9
E11D   60                       RTS
E11E   20 C6 FF                 JSR LFFC6
E121   B0 D6                    BCS LE0F9
E123   60                       RTS
E124   20 E4 FF                 JSR LFFE4
E127   B0 D0                    BCS LE0F9
E129   60                       RTS
E12A   20 8A AD                 JSR $AD8A
E12D   20 F7 B7                 JSR $B7F7
E130   A9 E1                    LDA #$E1
E132   48                       PHA
E133   A9 46                    LDA #$46
E135   48                       PHA
E136   AD 0F 03                 LDA $030F
E139   48                       PHA
E13A   AD 0C 03                 LDA $030C
E13D   AE 0D 03                 LDX $030D
E140   AC 0E 03                 LDY $030E
E143   28                       PLP
E144   6C 14 00                 JMP ($0014)
E147   08                       PHP
E148   8D 0C 03                 STA $030C
E14B   8E 0D 03                 STX $030D
E14E   8C 0E 03                 STY $030E
E151   68                       PLA
E152   8D 0F 03                 STA $030F
E155   60                       RTS
E156   20 D4 E1                 JSR LE1D4
E159   A6 2D                    LDX $2D
E15B   A4 2E                    LDY $2E
E15D   A9 2B                    LDA #$2B
E15F   20 D8 FF                 JSR LFFD8
E162   B0 95                    BCS LE0F9
E164   60                       RTS
E165   A9 01                    LDA #$01
E167   2C A9 00                 BIT $00A9
E16A   85 0A                    STA $0A
E16C   20 D4 E1                 JSR LE1D4
E16F   A5 0A                    LDA $0A
E171   A6 2B                    LDX $2B
E173   A4 2C                    LDY $2C
E175   20 D5 FF                 JSR LFFD5
E178   B0 57                    BCS LE1D1
E17A   A5 0A                    LDA $0A
E17C   F0 17                    BEQ LE195
E17E   A2 1C                    LDX #$1C
E180   20 B7 FF                 JSR LFFB7
E183   29 10                    AND #$10
E185   D0 17                    BNE LE19E
E187   A5 7A                    LDA $7A
E189   C9 02                    CMP #$02
E18B   F0 07                    BEQ LE194
E18D   A9 64                    LDA #$64
E18F   A0 A3                    LDY #$A3
E191   4C 1E AB                 JMP $AB1E
E194   60         LE194         RTS
E195   20 B7 FF   LE195         JSR LFFB7
E198   29 BF                    AND #$BF
E19A   F0 05                    BEQ LE1A1
E19C   A2 1D                    LDX #$1D
E19E   4C 37 A4   LE19E         JMP $A437
E1A1   A5 7B      LE1A1         LDA $7B
E1A3   C9 02                    CMP #$02
E1A5   D0 0E                    BNE LE1B5
E1A7   86 2D                    STX $2D
E1A9   84 2E                    STY $2E
E1AB   A9 76                    LDA #$76
E1AD   A0 A3                    LDY #$A3
E1AF   20 1E AB                 JSR $AB1E
E1B2   4C 2A A5                 JMP $A52A
E1B5   20 8E A6   LE1B5         JSR $A68E
E1B8   20 33 A5                 JSR $A533
E1BB   4C 77 A6                 JMP $A677
E1BE   20 19 E2                 JSR LE219
E1C1   20 C0 FF                 JSR LFFC0
E1C4   B0 0B                    BCS LE1D1
E1C6   60                       RTS
E1C7   20 19 E2                 JSR LE219
E1CA   A5 49                    LDA $49
E1CC   20 C3 FF                 JSR LFFC3
E1CF   90 C3                    BCC LE194
E1D1   4C F9 E0   LE1D1         JMP LE0F9
E1D4   A9 00      LE1D4         LDA #$00
E1D6   20 BD FF                 JSR LFFBD
E1D9   A2 01                    LDX #$01
E1DB   A0 00                    LDY #$00
E1DD   20 BA FF                 JSR LFFBA
E1E0   20 06 E2                 JSR LE206
E1E3   20 57 E2                 JSR LE257
E1E6   20 06 E2                 JSR LE206
E1E9   20 00 E2                 JSR LE200
E1EC   A0 00                    LDY #$00
E1EE   86 49                    STX $49
E1F0   20 BA FF                 JSR LFFBA
E1F3   20 06 E2                 JSR LE206
E1F6   20 00 E2                 JSR LE200
E1F9   8A                       TXA
E1FA   A8                       TAY
E1FB   A6 49                    LDX $49
E1FD   4C BA FF                 JMP LFFBA
E200   20 0E E2   LE200         JSR LE20E
E203   4C 9E B7                 JMP $B79E
E206   20 79 00   LE206         JSR $0079
E209   D0 02                    BNE LE20D
E20B   68                       PLA
E20C   68                       PLA
E20D   60         LE20D         RTS
E20E   20 FD AE   LE20E         JSR $AEFD
E211   20 79 00   LE211         JSR $0079
E214   D0 F7                    BNE LE20D
E216   4C 08 AF                 JMP $AF08
E219   A9 00      LE219         LDA #$00
E21B   20 BD FF                 JSR LFFBD
E21E   20 11 E2                 JSR LE211
E221   20 9E B7                 JSR $B79E
E224   86 49                    STX $49
E226   8A                       TXA
E227   A2 01                    LDX #$01
E229   A0 00                    LDY #$00
E22B   20 BA FF                 JSR LFFBA
E22E   20 06 E2                 JSR LE206
E231   20 00 E2                 JSR LE200
E234   86 4A                    STX $4A
E236   A0 00                    LDY #$00
E238   A5 49                    LDA $49
E23A   E0 03                    CPX #$03
E23C   90 01                    BCC LE23F
E23E   88                       DEY
E23F   20 BA FF   LE23F         JSR LFFBA
E242   20 06 E2                 JSR LE206
E245   20 00 E2                 JSR LE200
E248   8A                       TXA
E249   A8                       TAY
E24A   A6 4A                    LDX $4A
E24C   A5 49                    LDA $49
E24E   20 BA FF                 JSR LFFBA
E251   20 06 E2                 JSR LE206
E254   20 0E E2                 JSR LE20E
E257   20 9E AD   LE257         JSR $AD9E
E25A   20 A3 B6                 JSR $B6A3
E25D   A6 22                    LDX $22
E25F   A4 23                    LDY $23
E261   4C BD FF                 JMP LFFBD
E264   A9 E0                    LDA #$E0
E266   A0 E2                    LDY #$E2
E268   20 67 B8                 JSR $B867
E26B   20 0C BC   LE26B         JSR $BC0C
E26E   A9 E5                    LDA #$E5
E270   A0 E2                    LDY #$E2
E272   A6 6E                    LDX $6E
E274   20 07 BB                 JSR $BB07
E277   20 0C BC                 JSR $BC0C
E27A   20 CC BC                 JSR $BCCC
E27D   A9 00                    LDA #$00
E27F   85 6F                    STA $6F
E281   20 53 B8                 JSR $B853
E284   A9 EA                    LDA #$EA
E286   A0 E2                    LDY #$E2
E288   20 50 B8                 JSR $B850
E28B   A5 66                    LDA $66
E28D   48                       PHA
E28E   10 0D                    BPL LE29D
E290   20 49 B8                 JSR $B849
E293   A5 66                    LDA $66
E295   30 09                    BMI LE2A0
E297   A5 12                    LDA $12
E299   49 FF                    EOR #$FF
E29B   85 12                    STA $12
E29D   20 B4 BF   LE29D         JSR $BFB4
E2A0   A9 EA      LE2A0         LDA #$EA
E2A2   A0 E2                    LDY #$E2
E2A4   20 67 B8                 JSR $B867
E2A7   68                       PLA
E2A8   10 03                    BPL LE2AD
E2AA   20 B4 BF                 JSR $BFB4
E2AD   A9 EF      LE2AD         LDA #$EF
E2AF   A0 E2                    LDY #$E2
E2B1   4C 43 E0                 JMP LE043
E2B4   20 CA BB                 JSR $BBCA
E2B7   A9 00                    LDA #$00
E2B9   85 12                    STA $12
E2BB   20 6B E2                 JSR LE26B
E2BE   A2 4E                    LDX #$4E
E2C0   A0 00                    LDY #$00
E2C2   20 F6 E0                 JSR LE0F6
E2C5   A9 57                    LDA #$57
E2C7   A0 00                    LDY #$00
E2C9   20 A2 BB                 JSR $BBA2
E2CC   A9 00                    LDA #$00
E2CE   85 66                    STA $66
E2D0   A5 12                    LDA $12
E2D2   20 DC E2                 JSR LE2DC
E2D5   A9 4E                    LDA #$4E
E2D7   A0 00                    LDY #$00
E2D9   4C 0F BB                 JMP $BB0F
E2DC   48         LE2DC         PHA
E2DD   4C 9D E2                 JMP LE29D
E2E0   81 49                    STA ($49,X)
E2E2   0F                       ???               ;%00001111
E2E3   DA                       ???               ;%11011010
E2E4   A2 83                    LDX #$83
E2E6   49 0F                    EOR #$0F
E2E8   DA                       ???               ;%11011010
E2E9   A2 7F                    LDX #$7F
E2EB   00                       BRK
E2EC   00                       BRK
E2ED   00                       BRK
E2EE   00                       BRK
E2EF   05 84                    ORA $84
E2F1   E6 1A                    INC $1A
E2F3   2D 1B 86                 AND $861B
E2F6   28                       PLP
E2F7   07                       ???               ;%00000111
E2F8   FB                       ???               ;%11111011
E2F9   F8                       SED
E2FA   87                       ???               ;%10000111
E2FB   99 68 89                 STA $8968,Y
E2FE   01 87                    ORA ($87,X)
E300   23                       ???               ;%00100011 '#'
E301   35 DF                    AND $DF,X
E303   E1 86                    SBC ($86,X)
E305   A5 5D                    LDA $5D
E307   E7                       ???               ;%11100111
E308   28                       PLP
E309   83                       ???               ;%10000011
E30A   49 0F                    EOR #$0F
E30C   DA                       ???               ;%11011010
E30D   A2 A5                    LDX #$A5
E30F   66 48                    ROR $48
E311   10 03                    BPL LE316
E313   20 B4 BF                 JSR $BFB4
E316   A5 61      LE316         LDA $61
E318   48                       PHA
E319   C9 81                    CMP #$81
E31B   90 07                    BCC LE324
E31D   A9 BC                    LDA #$BC
E31F   A0 B9                    LDY #$B9
E321   20 0F BB                 JSR $BB0F
E324   A9 3E      LE324         LDA #$3E
E326   A0 E3                    LDY #$E3
E328   20 43 E0                 JSR LE043
E32B   68                       PLA
E32C   C9 81                    CMP #$81
E32E   90 07                    BCC LE337
E330   A9 E0                    LDA #$E0
E332   A0 E2                    LDY #$E2
E334   20 50 B8                 JSR $B850
E337   68         LE337         PLA
E338   10 03                    BPL LE33D
E33A   4C B4 BF                 JMP $BFB4
E33D   60         LE33D         RTS
E33E   0B                       ???               ;%00001011
E33F   76 B3                    ROR $B3,X
E341   83                       ???               ;%10000011
E342   BD D3 79                 LDA $79D3,X
E345   1E F4 A6                 ASL $A6F4,X
E348   F5 7B                    SBC $7B,X
E34A   83                       ???               ;%10000011
E34B   FC                       ???               ;%11111100
E34C   B0 10                    BCS LE35E
E34E   7C                       ???               ;%01111100 '|'
E34F   0C                       ???               ;%00001100
E350   1F                       ???               ;%00011111
E351   67                       ???               ;%01100111 'g'
E352   CA                       DEX
E353   7C                       ???               ;%01111100 '|'
E354   DE 53 CB                 DEC $CB53,X
E357   C1 7D                    CMP ($7D,X)
E359   14                       ???               ;%00010100
E35A   64                       ???               ;%01100100 'd'
E35B   70 4C                    BVS LE3A9
E35D   7D B7 EA                 ADC $EAB7,X
E360   51 7A                    EOR ($7A),Y
E362   7D 63 30                 ADC $3063,X
E365   88                       DEY
E366   7E 7E 92                 ROR $927E,X
E369   44                       ???               ;%01000100 'D'
E36A   99 3A 7E                 STA $7E3A,Y
E36D   4C CC 91                 JMP $91CC
E370   C7                       ???               ;%11000111
E371   7F                       ???               ;%01111111
E372   AA                       TAX
E373   AA                       TAX
E374   AA                       TAX
E375   13                       ???               ;%00010011
E376   81 00                    STA ($00,X)
E378   00                       BRK
E379   00                       BRK
E37A   00                       BRK
E37B   20 CC FF                 JSR LFFCC
E37E   A9 00                    LDA #$00
E380   85 13                    STA $13
E382   20 7A A6                 JSR $A67A
E385   58                       CLI
E386   A2 80      LE386         LDX #$80
E388   6C 00 03                 JMP ($0300)
E38B   8A                       TXA
E38C   30 03                    BMI LE391
E38E   4C 3A A4                 JMP $A43A
E391   4C 74 A4   LE391         JMP $A474
E394   20 53 E4                 JSR LE453
E397   20 BF E3                 JSR LE3BF
E39A   20 22 E4                 JSR LE422
E39D   A2 FB                    LDX #$FB
E39F   9A                       TXS
E3A0   D0 E4                    BNE LE386
E3A2   E6 7A      LE3A2         INC $7A
E3A4   D0 02                    BNE LE3A8
E3A6   E6 7B                    INC $7B
E3A8   AD 60 EA   LE3A8         LDA $EA60
E3AB   C9 3A                    CMP #$3A
E3AD   B0 0A                    BCS LE3B9
E3AF   C9 20                    CMP #$20
E3B1   F0 EF                    BEQ LE3A2
E3B3   38                       SEC
E3B4   E9 30                    SBC #$30
E3B6   38                       SEC
E3B7   E9 D0                    SBC #$D0
E3B9   60         LE3B9         RTS
E3BA   80                       ???               ;%10000000
E3BB   4F                       ???               ;%01001111 'O'
E3BC   C7                       ???               ;%11000111
E3BD   52                       ???               ;%01010010 'R'
E3BE   58                       CLI
E3BF   A9 4C      LE3BF         LDA #$4C
E3C1   85 54                    STA $54
E3C3   8D 10 03                 STA $0310
E3C6   A9 48                    LDA #$48
E3C8   A0 B2                    LDY #$B2
E3CA   8D 11 03                 STA $0311
E3CD   8C 12 03                 STY $0312
E3D0   A9 91                    LDA #$91
E3D2   A0 B3                    LDY #$B3
E3D4   85 05                    STA $05
E3D6   84 06                    STY $06
E3D8   A9 AA                    LDA #$AA
E3DA   A0 B1                    LDY #$B1
E3DC   85 03                    STA $03
E3DE   84 04                    STY $04
E3E0   A2 1C                    LDX #$1C
E3E2   BD A2 E3   LE3E2         LDA LE3A2,X
E3E5   95 73                    STA $73,X
E3E7   CA                       DEX
E3E8   10 F8                    BPL LE3E2
E3EA   A9 03                    LDA #$03
E3EC   85 53                    STA $53
E3EE   A9 00                    LDA #$00
E3F0   85 68                    STA $68
E3F2   85 13                    STA $13
E3F4   85 18                    STA $18
E3F6   A2 01                    LDX #$01
E3F8   8E FD 01                 STX $01FD
E3FB   8E FC 01                 STX $01FC
E3FE   A2 19                    LDX #$19
E400   86 16                    STX $16
E402   38                       SEC
E403   20 9C FF                 JSR LFF9C
E406   86 2B                    STX $2B
E408   84 2C                    STY $2C
E40A   38                       SEC
E40B   20 99 FF                 JSR LFF99
E40E   86 37                    STX $37
E410   84 38                    STY $38
E412   86 33                    STX $33
E414   84 34                    STY $34
E416   A0 00                    LDY #$00
E418   98                       TYA
E419   91 2B                    STA ($2B),Y
E41B   E6 2B                    INC $2B
E41D   D0 02                    BNE LE421
E41F   E6 2C                    INC $2C
E421   60         LE421         RTS
E422   A5 2B      LE422         LDA $2B
E424   A4 2C                    LDY $2C
E426   20 08 A4                 JSR $A408
E429   A9 73                    LDA #$73
E42B   A0 E4                    LDY #$E4
E42D   20 1E AB                 JSR $AB1E
E430   A5 37                    LDA $37
E432   38                       SEC
E433   E5 2B                    SBC $2B
E435   AA                       TAX
E436   A5 38                    LDA $38
E438   E5 2C                    SBC $2C
E43A   20 CD BD                 JSR $BDCD
E43D   A9 60                    LDA #$60
E43F   A0 E4                    LDY #$E4
E441   20 1E AB                 JSR $AB1E
E444   4C 44 A6                 JMP $A644
E447   8B                       ???               ;%10001011
E448   E3                       ???               ;%11100011
E449   83                       ???               ;%10000011
E44A   A4 7C                    LDY $7C
E44C   A5 1A                    LDA $1A
E44E   A7                       ???               ;%10100111
E44F   E4 A7                    CPX $A7
E451   86 AE                    STX $AE
E453   A2 0B      LE453         LDX #$0B
E455   BD 47 E4   LE455         LDA $E447,X
E458   9D 00 03                 STA $0300,X
E45B   CA                       DEX
E45C   10 F7                    BPL LE455
E45E   60                       RTS
E45F   00                       BRK
E460   20 42 41                 JSR $4142
E463   53                       ???               ;%01010011 'S'
E464   49 43                    EOR #$43
E466   20 42 59                 JSR $5942
E469   54                       ???               ;%01010100 'T'
E46A   45 53                    EOR $53
E46C   20 46 52                 JSR $5246
E46F   45 45                    EOR $45
E471   0D 00 93                 ORA $9300
E474   0D 20 20                 ORA $2020
E477   20 20 2A                 JSR $2A20
E47A   2A                       ROL A
E47B   2A                       ROL A
E47C   2A                       ROL A
E47D   20 43 4F                 JSR $4F43
E480   4D 4D 4F                 EOR $4F4D
E483   44                       ???               ;%01000100 'D'
E484   4F                       ???               ;%01001111 'O'
E485   52                       ???               ;%01010010 'R'
E486   45 20                    EOR $20
E488   36 34                    ROL $34,X
E48A   20 42 41                 JSR $4142
E48D   53                       ???               ;%01010011 'S'
E48E   49 43                    EOR #$43
E490   20 56 32                 JSR $3256
E493   20 2A 2A                 JSR $2A2A
E496   2A                       ROL A
E497   2A                       ROL A
E498   0D 0D 20                 ORA $200D
E49B   36 34                    ROL $34,X
E49D   4B                       ???               ;%01001011 'K'
E49E   20 52 41                 JSR $4152
E4A1   4D 20 53                 EOR $5320
E4A4   59 53 54                 EOR $5453,Y
E4A7   45 4D                    EOR $4D
E4A9   20 20 00                 JSR $0020
E4AC   81 48                    STA ($48,X)
E4AE   20 C9 FF                 JSR LFFC9
E4B1   AA                       TAX
E4B2   68                       PLA
E4B3   90 01                    BCC LE4B6
E4B5   8A                       TXA
E4B6   60         LE4B6         RTS
E4B7   AA                       TAX
E4B8   AA                       TAX
E4B9   AA                       TAX
E4BA   AA                       TAX
E4BB   AA                       TAX
E4BC   AA                       TAX
E4BD   AA                       TAX
E4BE   AA                       TAX
E4BF   AA                       TAX
E4C0   AA                       TAX
E4C1   AA                       TAX
E4C2   AA                       TAX
E4C3   AA                       TAX
E4C4   AA                       TAX
E4C5   AA                       TAX
E4C6   AA                       TAX
E4C7   AA                       TAX
E4C8   AA                       TAX
E4C9   AA                       TAX
E4CA   AA                       TAX
E4CB   AA                       TAX
E4CC   AA                       TAX
E4CD   AA                       TAX
E4CE   AA                       TAX
E4CF   AA                       TAX
E4D0   AA                       TAX
E4D1   AA                       TAX
E4D2   AA                       TAX
E4D3   85 A9      LE4D3         STA $A9
E4D5   A9 01                    LDA #$01
E4D7   85 AB                    STA $AB
E4D9   60                       RTS
E4DA   AD 86 02   LE4DA         LDA $0286
E4DD   91 F3                    STA ($F3),Y
E4DF   60                       RTS
E4E0   69 02      LE4E0         ADC #$02
E4E2   A4 91      LE4E2         LDY $91
E4E4   C8                       INY
E4E5   D0 04                    BNE LE4EB
E4E7   C5 A1                    CMP $A1
E4E9   D0 F7                    BNE LE4E2
E4EB   60         LE4EB         RTS
E4EC   19 26 44                 ORA $4426,Y
E4EF   19 1A 11                 ORA $111A,Y
E4F2   E8                       INX
E4F3   0D 70 0C                 ORA $0C70
E4F6   06 06                    ASL $06
E4F8   D1 02                    CMP ($02),Y
E4FA   37                       ???               ;%00110111 '7'
E4FB   01 AE                    ORA ($AE,X)
E4FD   00                       BRK
E4FE   69 00                    ADC #$00
E500   A2 00      LE500         LDX #$00
E502   A0 DC                    LDY #$DC
E504   60                       RTS
E505   A2 28      LE505         LDX #$28
E507   A0 19                    LDY #$19
E509   60                       RTS
E50A   B0 07      LE50A         BCS LE513
E50C   86 D6                    STX $D6
E50E   84 D3                    STY $D3
E510   20 6C E5                 JSR LE56C
E513   A6 D6      LE513         LDX $D6
E515   A4 D3                    LDY $D3
E517   60                       RTS
E518   20 A0 E5   LE518         JSR LE5A0
E51B   A9 00                    LDA #$00
E51D   8D 91 02                 STA $0291
E520   85 CF                    STA $CF
E522   A9 48                    LDA #$48
E524   8D 8F 02                 STA $028F
E527   A9 EB                    LDA #$EB
E529   8D 90 02                 STA $0290
E52C   A9 0A                    LDA #$0A
E52E   8D 89 02                 STA $0289
E531   8D 8C 02                 STA $028C
E534   A9 0E                    LDA #$0E
E536   8D 86 02                 STA $0286
E539   A9 04                    LDA #$04
E53B   8D 8B 02                 STA $028B
E53E   A9 0C                    LDA #$0C
E540   85 CD                    STA $CD
E542   85 CC                    STA $CC
E544   AD 88 02   LE544         LDA $0288
E547   09 80                    ORA #$80
E549   A8                       TAY
E54A   A9 00                    LDA #$00
E54C   AA                       TAX
E54D   94 D9      LE54D         STY $D9,X
E54F   18                       CLC
E550   69 28                    ADC #$28
E552   90 01                    BCC LE555
E554   C8                       INY
E555   E8         LE555         INX
E556   E0 1A                    CPX #$1A
E558   D0 F3                    BNE LE54D
E55A   A9 FF                    LDA #$FF
E55C   95 D9                    STA $D9,X
E55E   A2 18                    LDX #$18
E560   20 FF E9   LE560         JSR LE9FF
E563   CA                       DEX
E564   10 FA                    BPL LE560
E566   A0 00      LE566         LDY #$00
E568   84 D3                    STY $D3
E56A   84 D6                    STY $D6
E56C   A6 D6      LE56C         LDX $D6
E56E   A5 D3                    LDA $D3
E570   B4 D9      LE570         LDY $D9,X
E572   30 08                    BMI LE57C
E574   18                       CLC
E575   69 28                    ADC #$28
E577   85 D3                    STA $D3
E579   CA                       DEX
E57A   10 F4                    BPL LE570
E57C   20 F0 E9   LE57C         JSR LE9F0
E57F   A9 27                    LDA #$27
E581   E8                       INX
E582   B4 D9      LE582         LDY $D9,X
E584   30 06                    BMI LE58C
E586   18                       CLC
E587   69 28                    ADC #$28
E589   E8                       INX
E58A   10 F6                    BPL LE582
E58C   85 D5      LE58C         STA $D5
E58E   4C 24 EA                 JMP LEA24
E591   E4 C9      LE591         CPX $C9
E593   F0 03                    BEQ LE598
E595   4C ED E6                 JMP LE6ED
E598   60         LE598         RTS
E599   EA                       NOP
E59A   20 A0 E5                 JSR LE5A0
E59D   4C 66 E5                 JMP LE566
E5A0   A9 03      LE5A0         LDA #$03
E5A2   85 9A                    STA $9A
E5A4   A9 00                    LDA #$00
E5A6   85 99                    STA $99
E5A8   A2 2F                    LDX #$2F
E5AA   BD B8 EC   LE5AA         LDA $ECB8,X
E5AD   9D FF CF                 STA $CFFF,X
E5B0   CA                       DEX
E5B1   D0 F7                    BNE LE5AA
E5B3   60                       RTS
E5B4   AC 77 02   LE5B4         LDY $0277
E5B7   A2 00                    LDX #$00
E5B9   BD 78 02   LE5B9         LDA $0278,X
E5BC   9D 77 02                 STA $0277,X
E5BF   E8                       INX
E5C0   E4 C6                    CPX $C6
E5C2   D0 F5                    BNE LE5B9
E5C4   C6 C6                    DEC $C6
E5C6   98                       TYA
E5C7   58                       CLI
E5C8   18                       CLC
E5C9   60                       RTS
E5CA   20 16 E7   LE5CA         JSR LE716
E5CD   A5 C6      LE5CD         LDA $C6
E5CF   85 CC                    STA $CC
E5D1   8D 92 02                 STA $0292
E5D4   F0 F7                    BEQ LE5CD
E5D6   78                       SEI
E5D7   A5 CF                    LDA $CF
E5D9   F0 0C                    BEQ LE5E7
E5DB   A5 CE                    LDA $CE
E5DD   AE 87 02                 LDX $0287
E5E0   A0 00                    LDY #$00
E5E2   84 CF                    STY $CF
E5E4   20 13 EA                 JSR LEA13
E5E7   20 B4 E5   LE5E7         JSR LE5B4
E5EA   C9 83                    CMP #$83
E5EC   D0 10                    BNE LE5FE
E5EE   A2 09                    LDX #$09
E5F0   78                       SEI
E5F1   86 C6                    STX $C6
E5F3   BD E6 EC   LE5F3         LDA $ECE6,X
E5F6   9D 76 02                 STA $0276,X
E5F9   CA                       DEX
E5FA   D0 F7                    BNE LE5F3
E5FC   F0 CF                    BEQ LE5CD
E5FE   C9 0D      LE5FE         CMP #$0D
E600   D0 C8                    BNE LE5CA
E602   A4 D5                    LDY $D5
E604   84 D0                    STY $D0
E606   B1 D1      LE606         LDA ($D1),Y
E608   C9 20                    CMP #$20
E60A   D0 03                    BNE LE60F
E60C   88                       DEY
E60D   D0 F7                    BNE LE606
E60F   C8         LE60F         INY
E610   84 C8                    STY $C8
E612   A0 00                    LDY #$00
E614   8C 92 02                 STY $0292
E617   84 D3                    STY $D3
E619   84 D4                    STY $D4
E61B   A5 C9                    LDA $C9
E61D   30 1B                    BMI LE63A
E61F   A6 D6                    LDX $D6
E621   20 91 E5                 JSR LE591
E624   E4 C9                    CPX $C9
E626   D0 12                    BNE LE63A
E628   A5 CA                    LDA $CA
E62A   85 D3                    STA $D3
E62C   C5 C8                    CMP $C8
E62E   90 0A                    BCC LE63A
E630   B0 2B                    BCS LE65D
E632   98         LE632         TYA
E633   48                       PHA
E634   8A                       TXA
E635   48                       PHA
E636   A5 D0                    LDA $D0
E638   F0 93                    BEQ LE5CD
E63A   A4 D3      LE63A         LDY $D3
E63C   B1 D1                    LDA ($D1),Y
E63E   85 D7                    STA $D7
E640   29 3F                    AND #$3F
E642   06 D7                    ASL $D7
E644   24 D7                    BIT $D7
E646   10 02                    BPL LE64A
E648   09 80                    ORA #$80
E64A   90 04      LE64A         BCC LE650
E64C   A6 D4                    LDX $D4
E64E   D0 04                    BNE LE654
E650   70 02      LE650         BVS LE654
E652   09 40                    ORA #$40
E654   E6 D3      LE654         INC $D3
E656   20 84 E6                 JSR LE684
E659   C4 C8                    CPY $C8
E65B   D0 17                    BNE LE674
E65D   A9 00      LE65D         LDA #$00
E65F   85 D0                    STA $D0
E661   A9 0D                    LDA #$0D
E663   A6 99                    LDX $99
E665   E0 03                    CPX #$03
E667   F0 06                    BEQ LE66F
E669   A6 9A                    LDX $9A
E66B   E0 03                    CPX #$03
E66D   F0 03                    BEQ LE672
E66F   20 16 E7   LE66F         JSR LE716
E672   A9 0D      LE672         LDA #$0D
E674   85 D7      LE674         STA $D7
E676   68                       PLA
E677   AA                       TAX
E678   68                       PLA
E679   A8                       TAY
E67A   A5 D7                    LDA $D7
E67C   C9 DE                    CMP #$DE
E67E   D0 02                    BNE LE682
E680   A9 FF                    LDA #$FF
E682   18         LE682         CLC
E683   60                       RTS
E684   C9 22      LE684         CMP #$22
E686   D0 08                    BNE LE690
E688   A5 D4                    LDA $D4
E68A   49 01                    EOR #$01
E68C   85 D4                    STA $D4
E68E   A9 22                    LDA #$22
E690   60         LE690         RTS
E691   09 40      LE691         ORA #$40
E693   A6 C7      LE693         LDX $C7
E695   F0 02                    BEQ LE699
E697   09 80      LE697         ORA #$80
E699   A6 D8      LE699         LDX $D8
E69B   F0 02                    BEQ LE69F
E69D   C6 D8                    DEC $D8
E69F   AE 86 02   LE69F         LDX $0286
E6A2   20 13 EA                 JSR LEA13
E6A5   20 B6 E6                 JSR LE6B6
E6A8   68         LE6A8         PLA
E6A9   A8                       TAY
E6AA   A5 D8                    LDA $D8
E6AC   F0 02                    BEQ LE6B0
E6AE   46 D4                    LSR $D4
E6B0   68         LE6B0         PLA
E6B1   AA                       TAX
E6B2   68                       PLA
E6B3   18                       CLC
E6B4   58                       CLI
E6B5   60                       RTS
E6B6   20 B3 E8   LE6B6         JSR LE8B3
E6B9   E6 D3                    INC $D3
E6BB   A5 D5                    LDA $D5
E6BD   C5 D3                    CMP $D3
E6BF   B0 3F                    BCS LE700
E6C1   C9 4F                    CMP #$4F
E6C3   F0 32                    BEQ LE6F7
E6C5   AD 92 02                 LDA $0292
E6C8   F0 03                    BEQ LE6CD
E6CA   4C 67 E9                 JMP LE967
E6CD   A6 D6      LE6CD         LDX $D6
E6CF   E0 19                    CPX #$19
E6D1   90 07                    BCC LE6DA
E6D3   20 EA E8                 JSR LE8EA
E6D6   C6 D6                    DEC $D6
E6D8   A6 D6                    LDX $D6
E6DA   16 D9      LE6DA         ASL $D9,X
E6DC   56 D9                    LSR $D9,X
E6DE   E8                       INX
E6DF   B5 D9                    LDA $D9,X
E6E1   09 80                    ORA #$80
E6E3   95 D9                    STA $D9,X
E6E5   CA                       DEX
E6E6   A5 D5                    LDA $D5
E6E8   18                       CLC
E6E9   69 28                    ADC #$28
E6EB   85 D5                    STA $D5
E6ED   B5 D9      LE6ED         LDA $D9,X
E6EF   30 03                    BMI LE6F4
E6F1   CA                       DEX
E6F2   D0 F9                    BNE LE6ED
E6F4   4C F0 E9   LE6F4         JMP LE9F0
E6F7   C6 D6      LE6F7         DEC $D6
E6F9   20 7C E8                 JSR LE87C
E6FC   A9 00                    LDA #$00
E6FE   85 D3                    STA $D3
E700   60         LE700         RTS
E701   A6 D6      LE701         LDX $D6
E703   D0 06                    BNE LE70B
E705   86 D3                    STX $D3
E707   68                       PLA
E708   68                       PLA
E709   D0 9D                    BNE LE6A8
E70B   CA         LE70B         DEX
E70C   86 D6                    STX $D6
E70E   20 6C E5                 JSR LE56C
E711   A4 D5                    LDY $D5
E713   84 D3                    STY $D3
E715   60                       RTS
E716   48         LE716         PHA
E717   85 D7                    STA $D7
E719   8A                       TXA
E71A   48                       PHA
E71B   98                       TYA
E71C   48                       PHA
E71D   A9 00                    LDA #$00
E71F   85 D0                    STA $D0
E721   A4 D3                    LDY $D3
E723   A5 D7                    LDA $D7
E725   10 03                    BPL LE72A
E727   4C D4 E7                 JMP LE7D4
E72A   C9 0D      LE72A         CMP #$0D
E72C   D0 03                    BNE LE731
E72E   4C 91 E8                 JMP LE891
E731   C9 20      LE731         CMP #$20
E733   90 10                    BCC LE745
E735   C9 60                    CMP #$60
E737   90 04                    BCC LE73D
E739   29 DF                    AND #$DF
E73B   D0 02                    BNE LE73F
E73D   29 3F      LE73D         AND #$3F
E73F   20 84 E6   LE73F         JSR LE684
E742   4C 93 E6                 JMP LE693
E745   A6 D8      LE745         LDX $D8
E747   F0 03                    BEQ LE74C
E749   4C 97 E6                 JMP LE697
E74C   C9 14      LE74C         CMP #$14
E74E   D0 2E                    BNE LE77E
E750   98                       TYA
E751   D0 06                    BNE LE759
E753   20 01 E7                 JSR LE701
E756   4C 73 E7                 JMP LE773
E759   20 A1 E8   LE759         JSR LE8A1
E75C   88                       DEY
E75D   84 D3                    STY $D3
E75F   20 24 EA                 JSR LEA24
E762   C8         LE762         INY
E763   B1 D1                    LDA ($D1),Y
E765   88                       DEY
E766   91 D1                    STA ($D1),Y
E768   C8                       INY
E769   B1 F3                    LDA ($F3),Y
E76B   88                       DEY
E76C   91 F3                    STA ($F3),Y
E76E   C8                       INY
E76F   C4 D5                    CPY $D5
E771   D0 EF                    BNE LE762
E773   A9 20      LE773         LDA #$20
E775   91 D1                    STA ($D1),Y
E777   AD 86 02                 LDA $0286
E77A   91 F3                    STA ($F3),Y
E77C   10 4D                    BPL LE7CB
E77E   A6 D4      LE77E         LDX $D4
E780   F0 03                    BEQ LE785
E782   4C 97 E6                 JMP LE697
E785   C9 12      LE785         CMP #$12
E787   D0 02                    BNE LE78B
E789   85 C7                    STA $C7
E78B   C9 13      LE78B         CMP #$13
E78D   D0 03                    BNE LE792
E78F   20 66 E5                 JSR LE566
E792   C9 1D      LE792         CMP #$1D
E794   D0 17                    BNE LE7AD
E796   C8                       INY
E797   20 B3 E8                 JSR LE8B3
E79A   84 D3                    STY $D3
E79C   88                       DEY
E79D   C4 D5                    CPY $D5
E79F   90 09                    BCC LE7AA
E7A1   C6 D6                    DEC $D6
E7A3   20 7C E8                 JSR LE87C
E7A6   A0 00                    LDY #$00
E7A8   84 D3      LE7A8         STY $D3
E7AA   4C A8 E6   LE7AA         JMP LE6A8
E7AD   C9 11      LE7AD         CMP #$11
E7AF   D0 1D                    BNE LE7CE
E7B1   18                       CLC
E7B2   98                       TYA
E7B3   69 28                    ADC #$28
E7B5   A8                       TAY
E7B6   E6 D6                    INC $D6
E7B8   C5 D5                    CMP $D5
E7BA   90 EC                    BCC LE7A8
E7BC   F0 EA                    BEQ LE7A8
E7BE   C6 D6                    DEC $D6
E7C0   E9 28      LE7C0         SBC #$28
E7C2   90 04                    BCC LE7C8
E7C4   85 D3                    STA $D3
E7C6   D0 F8                    BNE LE7C0
E7C8   20 7C E8   LE7C8         JSR LE87C
E7CB   4C A8 E6   LE7CB         JMP LE6A8
E7CE   20 CB E8   LE7CE         JSR LE8CB
E7D1   4C 44 EC                 JMP LEC44
E7D4   29 7F      LE7D4         AND #$7F
E7D6   C9 7F                    CMP #$7F
E7D8   D0 02                    BNE LE7DC
E7DA   A9 5E                    LDA #$5E
E7DC   C9 20      LE7DC         CMP #$20
E7DE   90 03                    BCC LE7E3
E7E0   4C 91 E6                 JMP LE691
E7E3   C9 0D      LE7E3         CMP #$0D
E7E5   D0 03                    BNE LE7EA
E7E7   4C 91 E8                 JMP LE891
E7EA   A6 D4      LE7EA         LDX $D4
E7EC   D0 3F                    BNE LE82D
E7EE   C9 14                    CMP #$14
E7F0   D0 37                    BNE LE829
E7F2   A4 D5                    LDY $D5
E7F4   B1 D1                    LDA ($D1),Y
E7F6   C9 20                    CMP #$20
E7F8   D0 04                    BNE LE7FE
E7FA   C4 D3                    CPY $D3
E7FC   D0 07                    BNE LE805
E7FE   C0 4F      LE7FE         CPY #$4F
E800   F0 24                    BEQ LE826
E802   20 65 E9                 JSR LE965
E805   A4 D5      LE805         LDY $D5
E807   20 24 EA                 JSR LEA24
E80A   88         LE80A         DEY
E80B   B1 D1                    LDA ($D1),Y
E80D   C8                       INY
E80E   91 D1                    STA ($D1),Y
E810   88                       DEY
E811   B1 F3                    LDA ($F3),Y
E813   C8                       INY
E814   91 F3                    STA ($F3),Y
E816   88                       DEY
E817   C4 D3                    CPY $D3
E819   D0 EF                    BNE LE80A
E81B   A9 20                    LDA #$20
E81D   91 D1                    STA ($D1),Y
E81F   AD 86 02                 LDA $0286
E822   91 F3                    STA ($F3),Y
E824   E6 D8                    INC $D8
E826   4C A8 E6   LE826         JMP LE6A8
E829   A6 D8      LE829         LDX $D8
E82B   F0 05                    BEQ LE832
E82D   09 40      LE82D         ORA #$40
E82F   4C 97 E6                 JMP LE697
E832   C9 11      LE832         CMP #$11
E834   D0 16                    BNE LE84C
E836   A6 D6                    LDX $D6
E838   F0 37                    BEQ LE871
E83A   C6 D6                    DEC $D6
E83C   A5 D3                    LDA $D3
E83E   38                       SEC
E83F   E9 28                    SBC #$28
E841   90 04                    BCC LE847
E843   85 D3                    STA $D3
E845   10 2A                    BPL LE871
E847   20 6C E5   LE847         JSR LE56C
E84A   D0 25                    BNE LE871
E84C   C9 12      LE84C         CMP #$12
E84E   D0 04                    BNE LE854
E850   A9 00                    LDA #$00
E852   85 C7                    STA $C7
E854   C9 1D      LE854         CMP #$1D
E856   D0 12                    BNE LE86A
E858   98                       TYA
E859   F0 09                    BEQ LE864
E85B   20 A1 E8                 JSR LE8A1
E85E   88                       DEY
E85F   84 D3                    STY $D3
E861   4C A8 E6                 JMP LE6A8
E864   20 01 E7   LE864         JSR LE701
E867   4C A8 E6                 JMP LE6A8
E86A   C9 13      LE86A         CMP #$13
E86C   D0 06                    BNE LE874
E86E   20 44 E5                 JSR LE544
E871   4C A8 E6   LE871         JMP LE6A8
E874   09 80      LE874         ORA #$80
E876   20 CB E8                 JSR LE8CB
E879   4C 4F EC                 JMP LEC4F
E87C   46 C9      LE87C         LSR $C9
E87E   A6 D6                    LDX $D6
E880   E8         LE880         INX
E881   E0 19                    CPX #$19
E883   D0 03                    BNE LE888
E885   20 EA E8                 JSR LE8EA
E888   B5 D9      LE888         LDA $D9,X
E88A   10 F4                    BPL LE880
E88C   86 D6                    STX $D6
E88E   4C 6C E5                 JMP LE56C
E891   A2 00      LE891         LDX #$00
E893   86 D8                    STX $D8
E895   86 C7                    STX $C7
E897   86 D4                    STX $D4
E899   86 D3                    STX $D3
E89B   20 7C E8                 JSR LE87C
E89E   4C A8 E6                 JMP LE6A8
E8A1   A2 02      LE8A1         LDX #$02
E8A3   A9 00                    LDA #$00
E8A5   C5 D3      LE8A5         CMP $D3
E8A7   F0 07                    BEQ LE8B0
E8A9   18                       CLC
E8AA   69 28                    ADC #$28
E8AC   CA                       DEX
E8AD   D0 F6                    BNE LE8A5
E8AF   60                       RTS
E8B0   C6 D6      LE8B0         DEC $D6
E8B2   60                       RTS
E8B3   A2 02      LE8B3         LDX #$02
E8B5   A9 27                    LDA #$27
E8B7   C5 D3      LE8B7         CMP $D3
E8B9   F0 07                    BEQ LE8C2
E8BB   18                       CLC
E8BC   69 28                    ADC #$28
E8BE   CA                       DEX
E8BF   D0 F6                    BNE LE8B7
E8C1   60                       RTS
E8C2   A6 D6      LE8C2         LDX $D6
E8C4   E0 19                    CPX #$19
E8C6   F0 02                    BEQ LE8CA
E8C8   E6 D6                    INC $D6
E8CA   60         LE8CA         RTS
E8CB   A2 0F      LE8CB         LDX #$0F
E8CD   DD DA E8   LE8CD         CMP $E8DA,X
E8D0   F0 04                    BEQ LE8D6
E8D2   CA                       DEX
E8D3   10 F8                    BPL LE8CD
E8D5   60                       RTS
E8D6   8E 86 02   LE8D6         STX $0286
E8D9   60                       RTS
E8DA   90 05                    BCC LE8E1
E8DC   1C                       ???               ;%00011100
E8DD   9F                       ???               ;%10011111
E8DE   9C                       ???               ;%10011100
E8DF   1E 1F 9E                 ASL $9E1F,X
E8E2   81 95                    STA ($95,X)
E8E4   96 97                    STX $97,Y
E8E6   98                       TYA
E8E7   99 9A 9B                 STA $9B9A,Y
E8EA   A5 AC      LE8EA         LDA $AC
E8EC   48                       PHA
E8ED   A5 AD                    LDA $AD
E8EF   48                       PHA
E8F0   A5 AE                    LDA $AE
E8F2   48                       PHA
E8F3   A5 AF                    LDA $AF
E8F5   48                       PHA
E8F6   A2 FF      LE8F6         LDX #$FF
E8F8   C6 D6                    DEC $D6
E8FA   C6 C9                    DEC $C9
E8FC   CE A5 02                 DEC $02A5
E8FF   E8         LE8FF         INX
E900   20 F0 E9                 JSR LE9F0
E903   E0 18                    CPX #$18
E905   B0 0C                    BCS LE913
E907   BD F1 EC                 LDA $ECF1,X
E90A   85 AC                    STA $AC
E90C   B5 DA                    LDA $DA,X
E90E   20 C8 E9                 JSR LE9C8
E911   30 EC                    BMI LE8FF
E913   20 FF E9   LE913         JSR LE9FF
E916   A2 00                    LDX #$00
E918   B5 D9      LE918         LDA $D9,X
E91A   29 7F                    AND #$7F
E91C   B4 DA                    LDY $DA,X
E91E   10 02                    BPL LE922
E920   09 80                    ORA #$80
E922   95 D9      LE922         STA $D9,X
E924   E8                       INX
E925   E0 18                    CPX #$18
E927   D0 EF                    BNE LE918
E929   A5 F1                    LDA $F1
E92B   09 80                    ORA #$80
E92D   85 F1                    STA $F1
E92F   A5 D9                    LDA $D9
E931   10 C3                    BPL LE8F6
E933   E6 D6                    INC $D6
E935   EE A5 02                 INC $02A5
E938   A9 7F                    LDA #$7F
E93A   8D 00 DC                 STA $DC00
E93D   AD 01 DC                 LDA $DC01
E940   C9 FB                    CMP #$FB
E942   08                       PHP
E943   A9 7F                    LDA #$7F
E945   8D 00 DC                 STA $DC00
E948   28                       PLP
E949   D0 0B                    BNE LE956
E94B   A0 00                    LDY #$00
E94D   EA         LE94D         NOP
E94E   CA                       DEX
E94F   D0 FC                    BNE LE94D
E951   88                       DEY
E952   D0 F9                    BNE LE94D
E954   84 C6                    STY $C6
E956   A6 D6      LE956         LDX $D6
E958   68         LE958         PLA
E959   85 AF                    STA $AF
E95B   68                       PLA
E95C   85 AE                    STA $AE
E95E   68                       PLA
E95F   85 AD                    STA $AD
E961   68                       PLA
E962   85 AC                    STA $AC
E964   60                       RTS
E965   A6 D6      LE965         LDX $D6
E967   E8         LE967         INX
E968   B5 D9                    LDA $D9,X
E96A   10 FB                    BPL LE967
E96C   8E A5 02                 STX $02A5
E96F   E0 18                    CPX #$18
E971   F0 0E                    BEQ LE981
E973   90 0C                    BCC LE981
E975   20 EA E8                 JSR LE8EA
E978   AE A5 02                 LDX $02A5
E97B   CA                       DEX
E97C   C6 D6                    DEC $D6
E97E   4C DA E6                 JMP LE6DA
E981   A5 AC      LE981         LDA $AC
E983   48                       PHA
E984   A5 AD                    LDA $AD
E986   48                       PHA
E987   A5 AE                    LDA $AE
E989   48                       PHA
E98A   A5 AF                    LDA $AF
E98C   48                       PHA
E98D   A2 19                    LDX #$19
E98F   CA         LE98F         DEX
E990   20 F0 E9                 JSR LE9F0
E993   EC A5 02                 CPX $02A5
E996   90 0E                    BCC LE9A6
E998   F0 0C                    BEQ LE9A6
E99A   BD EF EC                 LDA $ECEF,X
E99D   85 AC                    STA $AC
E99F   B5 D8                    LDA $D8,X
E9A1   20 C8 E9                 JSR LE9C8
E9A4   30 E9                    BMI LE98F
E9A6   20 FF E9   LE9A6         JSR LE9FF
E9A9   A2 17                    LDX #$17
E9AB   EC A5 02   LE9AB         CPX $02A5
E9AE   90 0F                    BCC LE9BF
E9B0   B5 DA                    LDA $DA,X
E9B2   29 7F                    AND #$7F
E9B4   B4 D9                    LDY $D9,X
E9B6   10 02                    BPL LE9BA
E9B8   09 80                    ORA #$80
E9BA   95 DA      LE9BA         STA $DA,X
E9BC   CA                       DEX
E9BD   D0 EC                    BNE LE9AB
E9BF   AE A5 02   LE9BF         LDX $02A5
E9C2   20 DA E6                 JSR LE6DA
E9C5   4C 58 E9                 JMP LE958
E9C8   29 03      LE9C8         AND #$03
E9CA   0D 88 02                 ORA $0288
E9CD   85 AD                    STA $AD
E9CF   20 E0 E9                 JSR LE9E0
E9D2   A0 27                    LDY #$27
E9D4   B1 AC      LE9D4         LDA ($AC),Y
E9D6   91 D1                    STA ($D1),Y
E9D8   B1 AE                    LDA ($AE),Y
E9DA   91 F3                    STA ($F3),Y
E9DC   88                       DEY
E9DD   10 F5                    BPL LE9D4
E9DF   60                       RTS
E9E0   20 24 EA   LE9E0         JSR LEA24
E9E3   A5 AC                    LDA $AC
E9E5   85 AE                    STA $AE
E9E7   A5 AD                    LDA $AD
E9E9   29 03                    AND #$03
E9EB   09 D8                    ORA #$D8
E9ED   85 AF                    STA $AF
E9EF   60                       RTS
E9F0   BD F0 EC   LE9F0         LDA $ECF0,X
E9F3   85 D1                    STA $D1
E9F5   B5 D9                    LDA $D9,X
E9F7   29 03                    AND #$03
E9F9   0D 88 02                 ORA $0288
E9FC   85 D2                    STA $D2
E9FE   60                       RTS
E9FF   A0 27      LE9FF         LDY #$27
EA01   20 F0 E9                 JSR LE9F0
EA04   20 24 EA                 JSR LEA24
EA07   20 DA E4   LEA07         JSR LE4DA
EA0A   A9 20                    LDA #$20
EA0C   91 D1                    STA ($D1),Y
EA0E   88                       DEY
EA0F   10 F6                    BPL LEA07
EA11   60                       RTS
EA12   EA                       NOP
EA13   A8         LEA13         TAY
EA14   A9 02                    LDA #$02
EA16   85 CD                    STA $CD
EA18   20 24 EA                 JSR LEA24
EA1B   98                       TYA
EA1C   A4 D3      LEA1C         LDY $D3
EA1E   91 D1                    STA ($D1),Y
EA20   8A                       TXA
EA21   91 F3                    STA ($F3),Y
EA23   60                       RTS
EA24   A5 D1      LEA24         LDA $D1
EA26   85 F3                    STA $F3
EA28   A5 D2                    LDA $D2
EA2A   29 03                    AND #$03
EA2C   09 D8                    ORA #$D8
EA2E   85 F4                    STA $F4
EA30   60                       RTS
EA31   20 EA FF                 JSR LFFEA
EA34   A5 CC                    LDA $CC
EA36   D0 29                    BNE LEA61
EA38   C6 CD                    DEC $CD
EA3A   D0 25                    BNE LEA61
EA3C   A9 14                    LDA #$14
EA3E   85 CD                    STA $CD
EA40   A4 D3                    LDY $D3
EA42   46 CF                    LSR $CF
EA44   AE 87 02                 LDX $0287
EA47   B1 D1                    LDA ($D1),Y
EA49   B0 11                    BCS LEA5C
EA4B   E6 CF                    INC $CF
EA4D   85 CE                    STA $CE
EA4F   20 24 EA                 JSR LEA24
EA52   B1 F3                    LDA ($F3),Y
EA54   8D 87 02                 STA $0287
EA57   AE 86 02                 LDX $0286
EA5A   A5 CE                    LDA $CE
EA5C   49 80      LEA5C         EOR #$80
EA5E   20 1C EA                 JSR LEA1C
EA61   A5 01      LEA61         LDA $01
EA63   29 10                    AND #$10
EA65   F0 0A                    BEQ LEA71
EA67   A0 00                    LDY #$00
EA69   84 C0                    STY $C0
EA6B   A5 01                    LDA $01
EA6D   09 20                    ORA #$20
EA6F   D0 08                    BNE LEA79
EA71   A5 C0      LEA71         LDA $C0
EA73   D0 06                    BNE LEA7B
EA75   A5 01                    LDA $01
EA77   29 1F                    AND #$1F
EA79   85 01      LEA79         STA $01
EA7B   20 87 EA   LEA7B         JSR LEA87
EA7E   AD 0D DC                 LDA $DC0D
EA81   68                       PLA
EA82   A8                       TAY
EA83   68                       PLA
EA84   AA                       TAX
EA85   68                       PLA
EA86   40                       RTI
EA87   A9 00      LEA87         LDA #$00
EA89   8D 8D 02                 STA $028D
EA8C   A0 40                    LDY #$40
EA8E   84 CB                    STY $CB
EA90   8D 00 DC                 STA $DC00
EA93   AE 01 DC                 LDX $DC01
EA96   E0 FF                    CPX #$FF
EA98   F0 61                    BEQ LEAFB
EA9A   A8                       TAY
EA9B   A9 81                    LDA #$81
EA9D   85 F5                    STA $F5
EA9F   A9 EB                    LDA #$EB
EAA1   85 F6                    STA $F6
EAA3   A9 FE                    LDA #$FE
EAA5   8D 00 DC                 STA $DC00
EAA8   A2 08      LEAA8         LDX #$08
EAAA   48                       PHA
EAAB   AD 01 DC   LEAAB         LDA $DC01
EAAE   CD 01 DC                 CMP $DC01
EAB1   D0 F8                    BNE LEAAB
EAB3   4A         LEAB3         LSR A
EAB4   B0 16                    BCS LEACC
EAB6   48                       PHA
EAB7   B1 F5                    LDA ($F5),Y
EAB9   C9 05                    CMP #$05
EABB   B0 0C                    BCS LEAC9
EABD   C9 03                    CMP #$03
EABF   F0 08                    BEQ LEAC9
EAC1   0D 8D 02                 ORA $028D
EAC4   8D 8D 02                 STA $028D
EAC7   10 02                    BPL LEACB
EAC9   84 CB      LEAC9         STY $CB
EACB   68         LEACB         PLA
EACC   C8         LEACC         INY
EACD   C0 41                    CPY #$41
EACF   B0 0B                    BCS LEADC
EAD1   CA                       DEX
EAD2   D0 DF                    BNE LEAB3
EAD4   38                       SEC
EAD5   68                       PLA
EAD6   2A                       ROL A
EAD7   8D 00 DC                 STA $DC00
EADA   D0 CC                    BNE LEAA8
EADC   68         LEADC         PLA
EADD   6C 8F 02                 JMP ($028F)
EAE0   A4 CB      LEAE0         LDY $CB
EAE2   B1 F5                    LDA ($F5),Y
EAE4   AA                       TAX
EAE5   C4 C5                    CPY $C5
EAE7   F0 07                    BEQ LEAF0
EAE9   A0 10                    LDY #$10
EAEB   8C 8C 02                 STY $028C
EAEE   D0 36                    BNE LEB26
EAF0   29 7F      LEAF0         AND #$7F
EAF2   2C 8A 02                 BIT $028A
EAF5   30 16                    BMI LEB0D
EAF7   70 49                    BVS LEB42
EAF9   C9 7F                    CMP #$7F
EAFB   F0 29      LEAFB         BEQ LEB26
EAFD   C9 14                    CMP #$14
EAFF   F0 0C                    BEQ LEB0D
EB01   C9 20                    CMP #$20
EB03   F0 08                    BEQ LEB0D
EB05   C9 1D                    CMP #$1D
EB07   F0 04                    BEQ LEB0D
EB09   C9 11                    CMP #$11
EB0B   D0 35                    BNE LEB42
EB0D   AC 8C 02   LEB0D         LDY $028C
EB10   F0 05                    BEQ LEB17
EB12   CE 8C 02                 DEC $028C
EB15   D0 2B                    BNE LEB42
EB17   CE 8B 02   LEB17         DEC $028B
EB1A   D0 26                    BNE LEB42
EB1C   A0 04                    LDY #$04
EB1E   8C 8B 02                 STY $028B
EB21   A4 C6                    LDY $C6
EB23   88                       DEY
EB24   10 1C                    BPL LEB42
EB26   A4 CB      LEB26         LDY $CB
EB28   84 C5                    STY $C5
EB2A   AC 8D 02                 LDY $028D
EB2D   8C 8E 02                 STY $028E
EB30   E0 FF                    CPX #$FF
EB32   F0 0E                    BEQ LEB42
EB34   8A                       TXA
EB35   A6 C6                    LDX $C6
EB37   EC 89 02                 CPX $0289
EB3A   B0 06                    BCS LEB42
EB3C   9D 77 02                 STA $0277,X
EB3F   E8                       INX
EB40   86 C6                    STX $C6
EB42   A9 7F      LEB42         LDA #$7F
EB44   8D 00 DC                 STA $DC00
EB47   60                       RTS
EB48   AD 8D 02                 LDA $028D
EB4B   C9 03                    CMP #$03
EB4D   D0 15                    BNE LEB64
EB4F   CD 8E 02                 CMP $028E
EB52   F0 EE                    BEQ LEB42
EB54   AD 91 02                 LDA $0291
EB57   30 1D                    BMI LEB76
EB59   AD 18 D0                 LDA $D018
EB5C   49 02                    EOR #$02
EB5E   8D 18 D0                 STA $D018
EB61   4C 76 EB                 JMP LEB76
EB64   0A         LEB64         ASL A
EB65   C9 08                    CMP #$08
EB67   90 02                    BCC LEB6B
EB69   A9 06                    LDA #$06
EB6B   AA         LEB6B         TAX
EB6C   BD 79 EB                 LDA $EB79,X
EB6F   85 F5                    STA $F5
EB71   BD 7A EB                 LDA $EB7A,X
EB74   85 F6                    STA $F6
EB76   4C E0 EA   LEB76         JMP LEAE0
EB79   81 EB                    STA ($EB,X)
EB7B   C2                       ???               ;%11000010
EB7C   EB                       ???               ;%11101011
EB7D   03                       ???               ;%00000011
EB7E   EC 78 EC                 CPX $EC78
EB81   14                       ???               ;%00010100
EB82   0D 1D 88                 ORA $881D
EB85   85 86                    STA $86
EB87   87                       ???               ;%10000111
EB88   11 33                    ORA ($33),Y
EB8A   57                       ???               ;%01010111 'W'
EB8B   41 34                    EOR ($34,X)
EB8D   5A                       ???               ;%01011010 'Z'
EB8E   53                       ???               ;%01010011 'S'
EB8F   45 01                    EOR $01
EB91   35 52                    AND $52,X
EB93   44                       ???               ;%01000100 'D'
EB94   36 43                    ROL $43,X
EB96   46 54                    LSR $54
EB98   58                       CLI
EB99   37                       ???               ;%00110111 '7'
EB9A   59 47 38                 EOR $3847,Y
EB9D   42                       ???               ;%01000010 'B'
EB9E   48                       PHA
EB9F   55 56                    EOR $56,X
EBA1   39 49 4A                 AND $4A49,Y
EBA4   30 4D                    BMI LEBF3
EBA6   4B         LEBA6         ???               ;%01001011 'K'
EBA7   4F                       ???               ;%01001111 'O'
EBA8   4E 2B 50                 LSR $502B
EBAB   4C 2D 2E                 JMP $2E2D
EBAE   3A                       ???               ;%00111010 ':'
EBAF   40                       RTI
EBB0   2C 5C 2A                 BIT $2A5C
EBB3   3B                       ???               ;%00111011 ';'
EBB4   13         LEBB4         ???               ;%00010011
EBB5   01 3D                    ORA ($3D,X)
EBB7   5E 2F 31                 LSR $312F,X
EBBA   5F                       ???               ;%01011111 '_'
EBBB   04                       ???               ;%00000100
EBBC   32                       ???               ;%00110010 '2'
EBBD   20 02 51                 JSR $5102
EBC0   03                       ???               ;%00000011
EBC1   FF                       ???               ;%11111111
EBC2   94 8D                    STY $8D,X
EBC4   9D 8C 89                 STA $898C,X
EBC7   8A                       TXA
EBC8   8B                       ???               ;%10001011
EBC9   91 23                    STA ($23),Y
EBCB   D7                       ???               ;%11010111
EBCC   C1 24                    CMP ($24,X)
EBCE   DA                       ???               ;%11011010
EBCF   D3                       ???               ;%11010011
EBD0   C5 01                    CMP $01
EBD2   25 D2                    AND $D2
EBD4   C4 26                    CPY $26
EBD6   C3                       ???               ;%11000011
EBD7   C6 D4                    DEC $D4
EBD9   D8                       CLD
EBDA   27                       ???               ;%00100111 '''
EBDB   D9 C7 28                 CMP $28C7,Y
EBDE   C2                       ???               ;%11000010
EBDF   C8                       INY
EBE0   D5 D6                    CMP $D6,X
EBE2   29 C9                    AND #$C9
EBE4   CA                       DEX
EBE5   30 CD                    BMI LEBB4
EBE7   CB                       ???               ;%11001011
EBE8   CF                       ???               ;%11001111
EBE9   CE DB D0                 DEC $D0DB
EBEC   CC DD 3E                 CPY $3EDD
EBEF   5B                       ???               ;%01011011 '['
EBF0   BA                       TSX
EBF1   3C                       ???               ;%00111100 '<'
EBF2   A9 C0                    LDA #$C0
EBF4   5D 93 01                 EOR $0193,X
EBF7   3D DE 3F                 AND $3FDE,X
EBFA   21 5F                    AND ($5F,X)
EBFC   04                       ???               ;%00000100
EBFD   22                       ???               ;%00100010 '"'
EBFE   A0 02                    LDY #$02
EC00   D1 83                    CMP ($83),Y
EC02   FF                       ???               ;%11111111
EC03   94 8D                    STY $8D,X
EC05   9D 8C 89                 STA $898C,X
EC08   8A                       TXA
EC09   8B                       ???               ;%10001011
EC0A   91 96                    STA ($96),Y
EC0C   B3                       ???               ;%10110011
EC0D   B0 97                    BCS LEBA6
EC0F   AD AE B1                 LDA $B1AE
EC12   01 98                    ORA ($98,X)
EC14   B2                       ???               ;%10110010
EC15   AC 99 BC                 LDY $BC99
EC18   BB                       ???               ;%10111011
EC19   A3                       ???               ;%10100011
EC1A   BD 9A B7                 LDA $B79A,X
EC1D   A5 9B                    LDA $9B
EC1F   BF                       ???               ;%10111111
EC20   B4 B8                    LDY $B8,X
EC22   BE 29 A2                 LDX $A229,Y
EC25   B5 30                    LDA $30,X
EC27   A7                       ???               ;%10100111
EC28   A1 B9                    LDA ($B9,X)
EC2A   AA                       TAX
EC2B   A6 AF                    LDX $AF
EC2D   B6 DC                    LDX $DC,Y
EC2F   3E 5B A4                 ROL $A45B,X
EC32   3C                       ???               ;%00111100 '<'
EC33   A8                       TAY
EC34   DF                       ???               ;%11011111
EC35   5D 93 01                 EOR $0193,X
EC38   3D DE 3F                 AND $3FDE,X
EC3B   81 5F                    STA ($5F,X)
EC3D   04                       ???               ;%00000100
EC3E   95 A0                    STA $A0,X
EC40   02                       ???               ;%00000010
EC41   AB                       ???               ;%10101011
EC42   83                       ???               ;%10000011
EC43   FF                       ???               ;%11111111
EC44   C9 0E      LEC44         CMP #$0E
EC46   D0 07                    BNE LEC4F
EC48   AD 18 D0                 LDA $D018
EC4B   09 02                    ORA #$02
EC4D   D0 09                    BNE LEC58
EC4F   C9 8E      LEC4F         CMP #$8E
EC51   D0 0B                    BNE LEC5E
EC53   AD 18 D0                 LDA $D018
EC56   29 FD                    AND #$FD
EC58   8D 18 D0   LEC58         STA $D018
EC5B   4C A8 E6   LEC5B         JMP LE6A8
EC5E   C9 08      LEC5E         CMP #$08
EC60   D0 07                    BNE LEC69
EC62   A9 80                    LDA #$80
EC64   0D 91 02                 ORA $0291
EC67   30 09                    BMI LEC72
EC69   C9 09      LEC69         CMP #$09
EC6B   D0 EE                    BNE LEC5B
EC6D   A9 7F                    LDA #$7F
EC6F   2D 91 02                 AND $0291
EC72   8D 91 02   LEC72         STA $0291
EC75   4C A8 E6                 JMP LE6A8
EC78   FF                       ???               ;%11111111
EC79   FF                       ???               ;%11111111
EC7A   FF                       ???               ;%11111111
EC7B   FF                       ???               ;%11111111
EC7C   FF                       ???               ;%11111111
EC7D   FF                       ???               ;%11111111
EC7E   FF                       ???               ;%11111111
EC7F   FF                       ???               ;%11111111
EC80   1C                       ???               ;%00011100
EC81   17                       ???               ;%00010111
EC82   01 9F                    ORA ($9F,X)
EC84   1A                       ???               ;%00011010
EC85   13                       ???               ;%00010011
EC86   05 FF                    ORA $FF
EC88   9C                       ???               ;%10011100
EC89   12                       ???               ;%00010010
EC8A   04                       ???               ;%00000100
EC8B   1E 03 06                 ASL $0603,X
EC8E   14                       ???               ;%00010100
EC8F   18                       CLC
EC90   1F                       ???               ;%00011111
EC91   19 07 9E                 ORA $9E07,Y
EC94   02                       ???               ;%00000010
EC95   08                       PHP
EC96   15 16                    ORA $16,X
EC98   12                       ???               ;%00010010
EC99   09 0A                    ORA #$0A
EC9B   92                       ???               ;%10010010
EC9C   0D 0B 0F                 ORA $0F0B
EC9F   0E FF 10                 ASL $10FF
ECA2   0C                       ???               ;%00001100
ECA3   FF                       ???               ;%11111111
ECA4   FF                       ???               ;%11111111
ECA5   1B                       ???               ;%00011011
ECA6   00                       BRK
ECA7   FF                       ???               ;%11111111
ECA8   1C                       ???               ;%00011100
ECA9   FF                       ???               ;%11111111
ECAA   1D FF FF                 ORA $FFFF,X
ECAD   1F                       ???               ;%00011111
ECAE   1E FF 90                 ASL $90FF,X
ECB1   06 FF                    ASL $FF
ECB3   05 FF                    ORA $FF
ECB5   FF                       ???               ;%11111111
ECB6   11 FF                    ORA ($FF),Y
ECB8   FF                       ???               ;%11111111
ECB9   00                       BRK
ECBA   00                       BRK
ECBB   00                       BRK
ECBC   00                       BRK
ECBD   00                       BRK
ECBE   00                       BRK
ECBF   00                       BRK
ECC0   00                       BRK
ECC1   00                       BRK
ECC2   00                       BRK
ECC3   00                       BRK
ECC4   00                       BRK
ECC5   00                       BRK
ECC6   00                       BRK
ECC7   00                       BRK
ECC8   00                       BRK
ECC9   00                       BRK
ECCA   9B                       ???               ;%10011011
ECCB   37                       ???               ;%00110111 '7'
ECCC   00                       BRK
ECCD   00                       BRK
ECCE   00                       BRK
ECCF   08                       PHP
ECD0   00                       BRK
ECD1   14                       ???               ;%00010100
ECD2   0F                       ???               ;%00001111
ECD3   00                       BRK
ECD4   00                       BRK
ECD5   00                       BRK
ECD6   00                       BRK
ECD7   00                       BRK
ECD8   00                       BRK
ECD9   0E 06 01                 ASL $0106
ECDC   02                       ???               ;%00000010
ECDD   03                       ???               ;%00000011
ECDE   04                       ???               ;%00000100
ECDF   00                       BRK
ECE0   01 02                    ORA ($02,X)
ECE2   03                       ???               ;%00000011
ECE3   04                       ???               ;%00000100
ECE4   05 06                    ORA $06
ECE6   07                       ???               ;%00000111
ECE7   4C 4F 41                 JMP $414F
ECEA   44                       ???               ;%01000100 'D'
ECEB   0D 52 55                 ORA $5552
ECEE   4E 0D 00                 LSR $000D
ECF1   28                       PLP
ECF2   50 78                    BVC LED6C
ECF4   A0 C8                    LDY #$C8
ECF6   F0 18                    BEQ LED10
ECF8   40                       RTI
ECF9   68                       PLA
ECFA   90 B8                    BCC LECB4
ECFC   E0 08      LECFC         CPX #$08
ECFE   30 58                    BMI LED58
ED00   80                       ???               ;%10000000
ED01   A8                       TAY
ED02   D0 F8                    BNE LECFC
ED04   20 48 70                 JSR $7048
ED07   98                       TYA
ED08   C0 09                    CPY #$09
ED0A   40                       RTI
ED0B   2C 09 20                 BIT $2009
ED0E   20 A4 F0                 JSR LF0A4
ED11   48         LED11         PHA
ED12   24 94                    BIT $94
ED14   10 0A                    BPL LED20
ED16   38                       SEC
ED17   66 A3                    ROR $A3
ED19   20 40 ED                 JSR LED40
ED1C   46 94                    LSR $94
ED1E   46 A3                    LSR $A3
ED20   68         LED20         PLA
ED21   85 95                    STA $95
ED23   78                       SEI
ED24   20 97 EE                 JSR LEE97
ED27   C9 3F                    CMP #$3F
ED29   D0 03                    BNE LED2E
ED2B   20 85 EE                 JSR LEE85
ED2E   AD 00 DD   LED2E         LDA $DD00
ED31   09 08                    ORA #$08
ED33   8D 00 DD                 STA $DD00
ED36   78         LED36         SEI
ED37   20 8E EE                 JSR LEE8E
ED3A   20 97 EE                 JSR LEE97
ED3D   20 B3 EE                 JSR LEEB3
ED40   78         LED40         SEI
ED41   20 97 EE                 JSR LEE97
ED44   20 A9 EE                 JSR LEEA9
ED47   B0 64                    BCS LEDAD
ED49   20 85 EE                 JSR LEE85
ED4C   24 A3                    BIT $A3
ED4E   10 0A                    BPL LED5A
ED50   20 A9 EE   LED50         JSR LEEA9
ED53   90 FB                    BCC LED50
ED55   20 A9 EE   LED55         JSR LEEA9
ED58   B0 FB      LED58         BCS LED55
ED5A   20 A9 EE   LED5A         JSR LEEA9
ED5D   90 FB                    BCC LED5A
ED5F   20 8E EE                 JSR LEE8E
ED62   A9 08                    LDA #$08
ED64   85 A5                    STA $A5
ED66   AD 00 DD   LED66         LDA $DD00
ED69   CD 00 DD                 CMP $DD00
ED6C   D0 F8      LED6C         BNE LED66
ED6E   0A                       ASL A
ED6F   90 3F                    BCC LEDB0
ED71   66 95                    ROR $95
ED73   B0 05                    BCS LED7A
ED75   20 A0 EE                 JSR LEEA0
ED78   D0 03                    BNE LED7D
ED7A   20 97 EE   LED7A         JSR LEE97
ED7D   20 85 EE   LED7D         JSR LEE85
ED80   EA                       NOP
ED81   EA                       NOP
ED82   EA                       NOP
ED83   EA                       NOP
ED84   AD 00 DD                 LDA $DD00
ED87   29 DF                    AND #$DF
ED89   09 10                    ORA #$10
ED8B   8D 00 DD                 STA $DD00
ED8E   C6 A5                    DEC $A5
ED90   D0 D4                    BNE LED66
ED92   A9 04                    LDA #$04
ED94   8D 07 DC                 STA $DC07
ED97   A9 19                    LDA #$19
ED99   8D 0F DC                 STA $DC0F
ED9C   AD 0D DC                 LDA $DC0D
ED9F   AD 0D DC   LED9F         LDA $DC0D
EDA2   29 02                    AND #$02
EDA4   D0 0A                    BNE LEDB0
EDA6   20 A9 EE                 JSR LEEA9
EDA9   B0 F4                    BCS LED9F
EDAB   58                       CLI
EDAC   60                       RTS
EDAD   A9 80      LEDAD         LDA #$80
EDAF   2C A9 03                 BIT $03A9
EDB2   20 1C FE   LEDB2         JSR LFE1C
EDB5   58                       CLI
EDB6   18                       CLC
EDB7   90 4A                    BCC LEE03
EDB9   85 95      LEDB9         STA $95
EDBB   20 36 ED                 JSR LED36
EDBE   AD 00 DD   LEDBE         LDA $DD00
EDC1   29 F7                    AND #$F7
EDC3   8D 00 DD                 STA $DD00
EDC6   60                       RTS
EDC7   85 95      LEDC7         STA $95
EDC9   20 36 ED                 JSR LED36
EDCC   78         LEDCC         SEI
EDCD   20 A0 EE                 JSR LEEA0
EDD0   20 BE ED                 JSR LEDBE
EDD3   20 85 EE                 JSR LEE85
EDD6   20 A9 EE   LEDD6         JSR LEEA9
EDD9   30 FB                    BMI LEDD6
EDDB   58                       CLI
EDDC   60                       RTS
EDDD   24 94      LEDDD         BIT $94
EDDF   30 05                    BMI LEDE6
EDE1   38                       SEC
EDE2   66 94                    ROR $94
EDE4   D0 05                    BNE LEDEB
EDE6   48         LEDE6         PHA
EDE7   20 40 ED                 JSR LED40
EDEA   68                       PLA
EDEB   85 95      LEDEB         STA $95
EDED   18                       CLC
EDEE   60                       RTS
EDEF   78         LEDEF         SEI
EDF0   20 8E EE                 JSR LEE8E
EDF3   AD 00 DD                 LDA $DD00
EDF6   09 08                    ORA #$08
EDF8   8D 00 DD                 STA $DD00
EDFB   A9 5F                    LDA #$5F
EDFD   2C A9 3F                 BIT $3FA9
EE00   20 11 ED                 JSR LED11
EE03   20 BE ED   LEE03         JSR LEDBE
EE06   8A         LEE06         TXA
EE07   A2 0A                    LDX #$0A
EE09   CA         LEE09         DEX
EE0A   D0 FD                    BNE LEE09
EE0C   AA                       TAX
EE0D   20 85 EE                 JSR LEE85
EE10   4C 97 EE                 JMP LEE97
EE13   78         LEE13         SEI
EE14   A9 00                    LDA #$00
EE16   85 A5                    STA $A5
EE18   20 85 EE                 JSR LEE85
EE1B   20 A9 EE   LEE1B         JSR LEEA9
EE1E   10 FB                    BPL LEE1B
EE20   A9 01      LEE20         LDA #$01
EE22   8D 07 DC                 STA $DC07
EE25   A9 19                    LDA #$19
EE27   8D 0F DC                 STA $DC0F
EE2A   20 97 EE                 JSR LEE97
EE2D   AD 0D DC                 LDA $DC0D
EE30   AD 0D DC   LEE30         LDA $DC0D
EE33   29 02                    AND #$02
EE35   D0 07                    BNE LEE3E
EE37   20 A9 EE                 JSR LEEA9
EE3A   30 F4                    BMI LEE30
EE3C   10 18                    BPL LEE56
EE3E   A5 A5      LEE3E         LDA $A5
EE40   F0 05                    BEQ LEE47
EE42   A9 02                    LDA #$02
EE44   4C B2 ED                 JMP LEDB2
EE47   20 A0 EE   LEE47         JSR LEEA0
EE4A   20 85 EE                 JSR LEE85
EE4D   A9 40                    LDA #$40
EE4F   20 1C FE                 JSR LFE1C
EE52   E6 A5                    INC $A5
EE54   D0 CA                    BNE LEE20
EE56   A9 08      LEE56         LDA #$08
EE58   85 A5                    STA $A5
EE5A   AD 00 DD   LEE5A         LDA $DD00
EE5D   CD 00 DD                 CMP $DD00
EE60   D0 F8                    BNE LEE5A
EE62   0A                       ASL A
EE63   10 F5                    BPL LEE5A
EE65   66 A4                    ROR $A4
EE67   AD 00 DD   LEE67         LDA $DD00
EE6A   CD 00 DD                 CMP $DD00
EE6D   D0 F8                    BNE LEE67
EE6F   0A                       ASL A
EE70   30 F5                    BMI LEE67
EE72   C6 A5                    DEC $A5
EE74   D0 E4                    BNE LEE5A
EE76   20 A0 EE                 JSR LEEA0
EE79   24 90                    BIT $90
EE7B   50 03                    BVC LEE80
EE7D   20 06 EE                 JSR LEE06
EE80   A5 A4      LEE80         LDA $A4
EE82   58                       CLI
EE83   18                       CLC
EE84   60                       RTS
EE85   AD 00 DD   LEE85         LDA $DD00
EE88   29 EF                    AND #$EF
EE8A   8D 00 DD                 STA $DD00
EE8D   60                       RTS
EE8E   AD 00 DD   LEE8E         LDA $DD00
EE91   09 10                    ORA #$10
EE93   8D 00 DD                 STA $DD00
EE96   60                       RTS
EE97   AD 00 DD   LEE97         LDA $DD00
EE9A   29 DF                    AND #$DF
EE9C   8D 00 DD                 STA $DD00
EE9F   60                       RTS
EEA0   AD 00 DD   LEEA0         LDA $DD00
EEA3   09 20                    ORA #$20
EEA5   8D 00 DD                 STA $DD00
EEA8   60                       RTS
EEA9   AD 00 DD   LEEA9         LDA $DD00
EEAC   CD 00 DD                 CMP $DD00
EEAF   D0 F8                    BNE LEEA9
EEB1   0A                       ASL A
EEB2   60                       RTS
EEB3   8A         LEEB3         TXA
EEB4   A2 B8                    LDX #$B8
EEB6   CA         LEEB6         DEX
EEB7   D0 FD                    BNE LEEB6
EEB9   AA                       TAX
EEBA   60                       RTS
EEBB   A5 B4      LEEBB         LDA $B4
EEBD   F0 47                    BEQ LEF06
EEBF   30 3F                    BMI LEF00
EEC1   46 B6                    LSR $B6
EEC3   A2 00                    LDX #$00
EEC5   90 01                    BCC LEEC8
EEC7   CA                       DEX
EEC8   8A         LEEC8         TXA
EEC9   45 BD                    EOR $BD
EECB   85 BD                    STA $BD
EECD   C6 B4                    DEC $B4
EECF   F0 06                    BEQ LEED7
EED1   8A         LEED1         TXA
EED2   29 04                    AND #$04
EED4   85 B5                    STA $B5
EED6   60                       RTS
EED7   A9 20      LEED7         LDA #$20
EED9   2C 94 02                 BIT $0294
EEDC   F0 14                    BEQ LEEF2
EEDE   30 1C                    BMI LEEFC
EEE0   70 14                    BVS LEEF6
EEE2   A5 BD                    LDA $BD
EEE4   D0 01                    BNE LEEE7
EEE6   CA         LEEE6         DEX
EEE7   C6 B4      LEEE7         DEC $B4
EEE9   AD 93 02                 LDA $0293
EEEC   10 E3                    BPL LEED1
EEEE   C6 B4                    DEC $B4
EEF0   D0 DF                    BNE LEED1
EEF2   E6 B4      LEEF2         INC $B4
EEF4   D0 F0                    BNE LEEE6
EEF6   A5 BD      LEEF6         LDA $BD
EEF8   F0 ED                    BEQ LEEE7
EEFA   D0 EA                    BNE LEEE6
EEFC   70 E9      LEEFC         BVS LEEE7
EEFE   50 E6                    BVC LEEE6
EF00   E6 B4      LEF00         INC $B4
EF02   A2 FF                    LDX #$FF
EF04   D0 CB                    BNE LEED1
EF06   AD 94 02   LEF06         LDA $0294
EF09   4A                       LSR A
EF0A   90 07                    BCC LEF13
EF0C   2C 01 DD                 BIT $DD01
EF0F   10 1D                    BPL LEF2E
EF11   50 1E                    BVC LEF31
EF13   A9 00      LEF13         LDA #$00
EF15   85 BD                    STA $BD
EF17   85 B5                    STA $B5
EF19   AE 98 02                 LDX $0298
EF1C   86 B4                    STX $B4
EF1E   AC 9D 02                 LDY $029D
EF21   CC 9E 02                 CPY $029E
EF24   F0 13                    BEQ LEF39
EF26   B1 F9                    LDA ($F9),Y
EF28   85 B6                    STA $B6
EF2A   EE 9D 02                 INC $029D
EF2D   60                       RTS
EF2E   A9 40      LEF2E         LDA #$40
EF30   2C A9 10                 BIT $10A9
EF33   0D 97 02                 ORA $0297
EF36   8D 97 02                 STA $0297
EF39   A9 01      LEF39         LDA #$01
EF3B   8D 0D DD   LEF3B         STA $DD0D
EF3E   4D A1 02                 EOR $02A1
EF41   09 80                    ORA #$80
EF43   8D A1 02                 STA $02A1
EF46   8D 0D DD                 STA $DD0D
EF49   60                       RTS
EF4A   A2 09      LEF4A         LDX #$09
EF4C   A9 20                    LDA #$20
EF4E   2C 93 02                 BIT $0293
EF51   F0 01                    BEQ LEF54
EF53   CA                       DEX
EF54   50 02      LEF54         BVC LEF58
EF56   CA                       DEX
EF57   CA                       DEX
EF58   60         LEF58         RTS
EF59   A6 A9      LEF59         LDX $A9
EF5B   D0 33                    BNE LEF90
EF5D   C6 A8                    DEC $A8
EF5F   F0 36                    BEQ LEF97
EF61   30 0D                    BMI LEF70
EF63   A5 A7                    LDA $A7
EF65   45 AB                    EOR $AB
EF67   85 AB                    STA $AB
EF69   46 A7                    LSR $A7
EF6B   66 AA                    ROR $AA
EF6D   60         LEF6D         RTS
EF6E   C6 A8      LEF6E         DEC $A8
EF70   A5 A7      LEF70         LDA $A7
EF72   F0 67                    BEQ LEFDB
EF74   AD 93 02                 LDA $0293
EF77   0A                       ASL A
EF78   A9 01                    LDA #$01
EF7A   65 A8                    ADC $A8
EF7C   D0 EF                    BNE LEF6D
EF7E   A9 90      LEF7E         LDA #$90
EF80   8D 0D DD                 STA $DD0D
EF83   0D A1 02                 ORA $02A1
EF86   8D A1 02                 STA $02A1
EF89   85 A9                    STA $A9
EF8B   A9 02                    LDA #$02
EF8D   4C 3B EF                 JMP LEF3B
EF90   A5 A7      LEF90         LDA $A7
EF92   D0 EA                    BNE LEF7E
EF94   4C D3 E4                 JMP LE4D3
EF97   AC 9B 02   LEF97         LDY $029B
EF9A   C8                       INY
EF9B   CC 9C 02                 CPY $029C
EF9E   F0 2A                    BEQ LEFCA
EFA0   8C 9B 02                 STY $029B
EFA3   88                       DEY
EFA4   A5 AA                    LDA $AA
EFA6   AE 98 02                 LDX $0298
EFA9   E0 09      LEFA9         CPX #$09
EFAB   F0 04                    BEQ LEFB1
EFAD   4A                       LSR A
EFAE   E8                       INX
EFAF   D0 F8                    BNE LEFA9
EFB1   91 F7      LEFB1         STA ($F7),Y
EFB3   A9 20                    LDA #$20
EFB5   2C 94 02                 BIT $0294
EFB8   F0 B4                    BEQ LEF6E
EFBA   30 B1                    BMI LEF6D
EFBC   A5 A7                    LDA $A7
EFBE   45 AB                    EOR $AB
EFC0   F0 03                    BEQ LEFC5
EFC2   70 A9                    BVS LEF6D
EFC4   2C 50 A6                 BIT $A650
EFC7   A9 01                    LDA #$01
EFC9   2C A9 04                 BIT $04A9
EFCC   2C A9 80                 BIT $80A9
EFCF   2C A9 02                 BIT $02A9
EFD2   0D 97 02                 ORA $0297
EFD5   8D 97 02                 STA $0297
EFD8   4C 7E EF                 JMP LEF7E
EFDB   A5 AA      LEFDB         LDA $AA
EFDD   D0 F1                    BNE LEFD0
EFDF   F0 EC                    BEQ LEFCD
EFE1   85 9A      LEFE1         STA $9A
EFE3   AD 94 02                 LDA $0294
EFE6   4A                       LSR A
EFE7   90 29                    BCC LF012
EFE9   A9 02                    LDA #$02
EFEB   2C 01 DD                 BIT $DD01
EFEE   10 1D                    BPL LF00D
EFF0   D0 20                    BNE LF012
EFF2   AD A1 02   LEFF2         LDA $02A1
EFF5   29 02                    AND #$02
EFF7   D0 F9                    BNE LEFF2
EFF9   2C 01 DD   LEFF9         BIT $DD01
EFFC   70 FB                    BVS LEFF9
EFFE   AD 01 DD                 LDA $DD01
F001   09 02                    ORA #$02
F003   8D 01 DD                 STA $DD01
F006   2C 01 DD   LF006         BIT $DD01
F009   70 07                    BVS LF012
F00B   30 F9                    BMI LF006
F00D   A9 40      LF00D         LDA #$40
F00F   8D 97 02                 STA $0297
F012   18         LF012         CLC
F013   60                       RTS
F014   20 28 F0   LF014         JSR LF028
F017   AC 9E 02   LF017         LDY $029E
F01A   C8                       INY
F01B   CC 9D 02                 CPY $029D
F01E   F0 F4                    BEQ LF014
F020   8C 9E 02                 STY $029E
F023   88                       DEY
F024   A5 9E                    LDA $9E
F026   91 F9                    STA ($F9),Y
F028   AD A1 02   LF028         LDA $02A1
F02B   4A                       LSR A
F02C   B0 1E                    BCS LF04C
F02E   A9 10                    LDA #$10
F030   8D 0E DD                 STA $DD0E
F033   AD 99 02                 LDA $0299
F036   8D 04 DD                 STA $DD04
F039   AD 9A 02                 LDA $029A
F03C   8D 05 DD                 STA $DD05
F03F   A9 81                    LDA #$81
F041   20 3B EF                 JSR LEF3B
F044   20 06 EF                 JSR LEF06
F047   A9 11                    LDA #$11
F049   8D 0E DD                 STA $DD0E
F04C   60         LF04C         RTS
F04D   85 99      LF04D         STA $99
F04F   AD 94 02                 LDA $0294
F052   4A                       LSR A
F053   90 28                    BCC LF07D
F055   29 08                    AND #$08
F057   F0 24                    BEQ LF07D
F059   A9 02                    LDA #$02
F05B   2C 01 DD                 BIT $DD01
F05E   10 AD                    BPL LF00D
F060   F0 22                    BEQ LF084
F062   AD A1 02   LF062         LDA $02A1
F065   4A                       LSR A
F066   B0 FA                    BCS LF062
F068   AD 01 DD                 LDA $DD01
F06B   29 FD                    AND #$FD
F06D   8D 01 DD                 STA $DD01
F070   AD 01 DD   LF070         LDA $DD01
F073   29 04                    AND #$04
F075   F0 F9                    BEQ LF070
F077   A9 90      LF077         LDA #$90
F079   18                       CLC
F07A   4C 3B EF                 JMP LEF3B
F07D   AD A1 02   LF07D         LDA $02A1
F080   29 12                    AND #$12
F082   F0 F3                    BEQ LF077
F084   18         LF084         CLC
F085   60                       RTS
F086   AD 97 02   LF086         LDA $0297
F089   AC 9C 02                 LDY $029C
F08C   CC 9B 02                 CPY $029B
F08F   F0 0B                    BEQ LF09C
F091   29 F7                    AND #$F7
F093   8D 97 02                 STA $0297
F096   B1 F7                    LDA ($F7),Y
F098   EE 9C 02                 INC $029C
F09B   60                       RTS
F09C   09 08      LF09C         ORA #$08
F09E   8D 97 02                 STA $0297
F0A1   A9 00                    LDA #$00
F0A3   60                       RTS
F0A4   48         LF0A4         PHA
F0A5   AD A1 02                 LDA $02A1
F0A8   F0 11                    BEQ LF0BB
F0AA   AD A1 02   LF0AA         LDA $02A1
F0AD   29 03                    AND #$03
F0AF   D0 F9                    BNE LF0AA
F0B1   A9 10                    LDA #$10
F0B3   8D 0D DD                 STA $DD0D
F0B6   A9 00                    LDA #$00
F0B8   8D A1 02                 STA $02A1
F0BB   68         LF0BB         PLA
F0BC   60                       RTS
F0BD   0D 49 2F                 ORA $2F49
F0C0   4F                       ???               ;%01001111 'O'
F0C1   20 45 52                 JSR $5245
F0C4   52                       ???               ;%01010010 'R'
F0C5   4F                       ???               ;%01001111 'O'
F0C6   52                       ???               ;%01010010 'R'
F0C7   20 A3 0D                 JSR $0DA3
F0CA   53                       ???               ;%01010011 'S'
F0CB   45 41      LF0CB         EOR $41
F0CD   52                       ???               ;%01010010 'R'
F0CE   43                       ???               ;%01000011 'C'
F0CF   48                       PHA
F0D0   49 4E                    EOR #$4E
F0D2   47                       ???               ;%01000111 'G'
F0D3   A0 46                    LDY #$46
F0D5   4F                       ???               ;%01001111 'O'
F0D6   52                       ???               ;%01010010 'R'
F0D7   A0 0D                    LDY #$0D
F0D9   50 52                    BVC LF12D
F0DB   45 53                    EOR $53
F0DD   53                       ???               ;%01010011 'S'
F0DE   20 50 4C                 JSR $4C50
F0E1   41 59                    EOR ($59,X)
F0E3   20 4F 4E                 JSR $4E4F
F0E6   20 54 41                 JSR $4154
F0E9   50 C5                    BVC LF0B0
F0EB   50 52                    BVC LF13F
F0ED   45 53                    EOR $53
F0EF   53                       ???               ;%01010011 'S'
F0F0   20 52 45                 JSR $4552
F0F3   43                       ???               ;%01000011 'C'
F0F4   4F                       ???               ;%01001111 'O'
F0F5   52                       ???               ;%01010010 'R'
F0F6   44                       ???               ;%01000100 'D'
F0F7   20 26 20                 JSR $2026
F0FA   50 4C                    BVC LF148
F0FC   41 59                    EOR ($59,X)
F0FE   20 4F 4E                 JSR $4E4F
F101   20 54 41                 JSR $4154
F104   50 C5                    BVC LF0CB
F106   0D 4C 4F                 ORA $4F4C
F109   41 44                    EOR ($44,X)
F10B   49 4E                    EOR #$4E
F10D   C7                       ???               ;%11000111
F10E   0D 53 41                 ORA $4153
F111   56 49                    LSR $49,X
F113   4E 47 A0                 LSR $A047
F116   0D 56 45                 ORA $4556
F119   52                       ???               ;%01010010 'R'
F11A   49 46                    EOR #$46
F11C   59 49 4E                 EOR $4E49,Y
F11F   C7                       ???               ;%11000111
F120   0D 46 4F                 ORA $4F46
F123   55 4E                    EOR $4E,X
F125   44                       ???               ;%01000100 'D'
F126   A0 0D                    LDY #$0D
F128   4F                       ???               ;%01001111 'O'
F129   4B                       ???               ;%01001011 'K'
F12A   8D 24 9D                 STA $9D24
F12D   10 0D      LF12D         BPL LF13C
F12F   B9 BD F0   LF12F         LDA $F0BD,Y
F132   08                       PHP
F133   29 7F                    AND #$7F
F135   20 D2 FF                 JSR LFFD2
F138   C8                       INY
F139   28                       PLP
F13A   10 F3                    BPL LF12F
F13C   18         LF13C         CLC
F13D   60                       RTS
F13E   A5 99                    LDA $99
F140   D0 08                    BNE LF14A
F142   A5 C6                    LDA $C6
F144   F0 0F                    BEQ LF155
F146   78                       SEI
F147   4C B4 E5                 JMP LE5B4
F14A   C9 02      LF14A         CMP #$02
F14C   D0 18                    BNE LF166
F14E   84 97      LF14E         STY $97
F150   20 86 F0                 JSR LF086
F153   A4 97                    LDY $97
F155   18         LF155         CLC
F156   60                       RTS
F157   A5 99                    LDA $99
F159   D0 0B                    BNE LF166
F15B   A5 D3                    LDA $D3
F15D   85 CA                    STA $CA
F15F   A5 D6                    LDA $D6
F161   85 C9                    STA $C9
F163   4C 32 E6                 JMP LE632
F166   C9 03      LF166         CMP #$03
F168   D0 09                    BNE LF173
F16A   85 D0                    STA $D0
F16C   A5 D5                    LDA $D5
F16E   85 C8                    STA $C8
F170   4C 32 E6                 JMP LE632
F173   B0 38      LF173         BCS LF1AD
F175   C9 02                    CMP #$02
F177   F0 3F                    BEQ LF1B8
F179   86 97                    STX $97
F17B   20 99 F1                 JSR LF199
F17E   B0 16                    BCS LF196
F180   48                       PHA
F181   20 99 F1                 JSR LF199
F184   B0 0D                    BCS LF193
F186   D0 05                    BNE LF18D
F188   A9 40                    LDA #$40
F18A   20 1C FE                 JSR LFE1C
F18D   C6 A6      LF18D         DEC $A6
F18F   A6 97                    LDX $97
F191   68                       PLA
F192   60                       RTS
F193   AA         LF193         TAX
F194   68                       PLA
F195   8A                       TXA
F196   A6 97      LF196         LDX $97
F198   60                       RTS
F199   20 0D F8   LF199         JSR LF80D
F19C   D0 0B                    BNE LF1A9
F19E   20 41 F8                 JSR LF841
F1A1   B0 11                    BCS LF1B4
F1A3   A9 00                    LDA #$00
F1A5   85 A6                    STA $A6
F1A7   F0 F0                    BEQ LF199
F1A9   B1 B2      LF1A9         LDA ($B2),Y
F1AB   18                       CLC
F1AC   60                       RTS
F1AD   A5 90      LF1AD         LDA $90
F1AF   F0 04                    BEQ LF1B5
F1B1   A9 0D      LF1B1         LDA #$0D
F1B3   18         LF1B3         CLC
F1B4   60         LF1B4         RTS
F1B5   4C 13 EE   LF1B5         JMP LEE13
F1B8   20 4E F1   LF1B8         JSR LF14E
F1BB   B0 F7                    BCS LF1B4
F1BD   C9 00                    CMP #$00
F1BF   D0 F2                    BNE LF1B3
F1C1   AD 97 02                 LDA $0297
F1C4   29 60                    AND #$60
F1C6   D0 E9                    BNE LF1B1
F1C8   F0 EE                    BEQ LF1B8
F1CA   48                       PHA
F1CB   A5 9A                    LDA $9A
F1CD   C9 03                    CMP #$03
F1CF   D0 04                    BNE LF1D5
F1D1   68                       PLA
F1D2   4C 16 E7                 JMP LE716
F1D5   90 04      LF1D5         BCC LF1DB
F1D7   68                       PLA
F1D8   4C DD ED                 JMP LEDDD
F1DB   4A         LF1DB         LSR A
F1DC   68                       PLA
F1DD   85 9E      LF1DD         STA $9E
F1DF   8A                       TXA
F1E0   48                       PHA
F1E1   98                       TYA
F1E2   48                       PHA
F1E3   90 23                    BCC LF208
F1E5   20 0D F8                 JSR LF80D
F1E8   D0 0E                    BNE LF1F8
F1EA   20 64 F8                 JSR LF864
F1ED   B0 0E                    BCS LF1FD
F1EF   A9 02                    LDA #$02
F1F1   A0 00                    LDY #$00
F1F3   91 B2                    STA ($B2),Y
F1F5   C8                       INY
F1F6   84 A6                    STY $A6
F1F8   A5 9E      LF1F8         LDA $9E
F1FA   91 B2                    STA ($B2),Y
F1FC   18         LF1FC         CLC
F1FD   68         LF1FD         PLA
F1FE   A8                       TAY
F1FF   68                       PLA
F200   AA                       TAX
F201   A5 9E                    LDA $9E
F203   90 02                    BCC LF207
F205   A9 00                    LDA #$00
F207   60         LF207         RTS
F208   20 17 F0   LF208         JSR LF017
F20B   4C FC F1                 JMP LF1FC
F20E   20 0F F3                 JSR LF30F
F211   F0 03                    BEQ LF216
F213   4C 01 F7                 JMP LF701
F216   20 1F F3   LF216         JSR LF31F
F219   A5 BA                    LDA $BA
F21B   F0 16                    BEQ LF233
F21D   C9 03                    CMP #$03
F21F   F0 12                    BEQ LF233
F221   B0 14                    BCS LF237
F223   C9 02                    CMP #$02
F225   D0 03                    BNE LF22A
F227   4C 4D F0                 JMP LF04D
F22A   A6 B9      LF22A         LDX $B9
F22C   E0 60                    CPX #$60
F22E   F0 03                    BEQ LF233
F230   4C 0A F7                 JMP LF70A
F233   85 99      LF233         STA $99
F235   18                       CLC
F236   60                       RTS
F237   AA         LF237         TAX
F238   20 09 ED                 JSR LED09
F23B   A5 B9                    LDA $B9
F23D   10 06                    BPL LF245
F23F   20 CC ED                 JSR LEDCC
F242   4C 48 F2                 JMP LF248
F245   20 C7 ED   LF245         JSR LEDC7
F248   8A         LF248         TXA
F249   24 90                    BIT $90
F24B   10 E6                    BPL LF233
F24D   4C 07 F7                 JMP LF707
F250   20 0F F3                 JSR LF30F
F253   F0 03                    BEQ LF258
F255   4C 01 F7                 JMP LF701
F258   20 1F F3   LF258         JSR LF31F
F25B   A5 BA                    LDA $BA
F25D   D0 03                    BNE LF262
F25F   4C 0D F7   LF25F         JMP LF70D
F262   C9 03      LF262         CMP #$03
F264   F0 0F                    BEQ LF275
F266   B0 11                    BCS LF279
F268   C9 02                    CMP #$02
F26A   D0 03                    BNE LF26F
F26C   4C E1 EF                 JMP LEFE1
F26F   A6 B9      LF26F         LDX $B9
F271   E0 60                    CPX #$60
F273   F0 EA                    BEQ LF25F
F275   85 9A      LF275         STA $9A
F277   18                       CLC
F278   60                       RTS
F279   AA         LF279         TAX
F27A   20 0C ED                 JSR LED0C
F27D   A5 B9                    LDA $B9
F27F   10 05                    BPL LF286
F281   20 BE ED                 JSR LEDBE
F284   D0 03                    BNE LF289
F286   20 B9 ED   LF286         JSR LEDB9
F289   8A         LF289         TXA
F28A   24 90                    BIT $90
F28C   10 E7                    BPL LF275
F28E   4C 07 F7                 JMP LF707
F291   20 14 F3                 JSR LF314
F294   F0 02                    BEQ LF298
F296   18                       CLC
F297   60                       RTS
F298   20 1F F3   LF298         JSR LF31F
F29B   8A                       TXA
F29C   48                       PHA
F29D   A5 BA                    LDA $BA
F29F   F0 50                    BEQ LF2F1
F2A1   C9 03                    CMP #$03
F2A3   F0 4C                    BEQ LF2F1
F2A5   B0 47                    BCS LF2EE
F2A7   C9 02                    CMP #$02
F2A9   D0 1D                    BNE LF2C8
F2AB   68                       PLA
F2AC   20 F2 F2                 JSR LF2F2
F2AF   20 83 F4                 JSR LF483
F2B2   20 27 FE                 JSR LFE27
F2B5   A5 F8                    LDA $F8
F2B7   F0 01                    BEQ LF2BA
F2B9   C8                       INY
F2BA   A5 FA      LF2BA         LDA $FA
F2BC   F0 01                    BEQ LF2BF
F2BE   C8                       INY
F2BF   A9 00      LF2BF         LDA #$00
F2C1   85 F8                    STA $F8
F2C3   85 FA                    STA $FA
F2C5   4C 7D F4                 JMP LF47D
F2C8   A5 B9      LF2C8         LDA $B9
F2CA   29 0F                    AND #$0F
F2CC   F0 23                    BEQ LF2F1
F2CE   20 D0 F7                 JSR LF7D0
F2D1   A9 00                    LDA #$00
F2D3   38                       SEC
F2D4   20 DD F1                 JSR LF1DD
F2D7   20 64 F8                 JSR LF864
F2DA   90 04                    BCC LF2E0
F2DC   68                       PLA
F2DD   A9 00                    LDA #$00
F2DF   60                       RTS
F2E0   A5 B9      LF2E0         LDA $B9
F2E2   C9 62                    CMP #$62
F2E4   D0 0B                    BNE LF2F1
F2E6   A9 05                    LDA #$05
F2E8   20 6A F7                 JSR LF76A
F2EB   4C F1 F2                 JMP LF2F1
F2EE   20 42 F6   LF2EE         JSR LF642
F2F1   68         LF2F1         PLA
F2F2   AA         LF2F2         TAX
F2F3   C6 98                    DEC $98
F2F5   E4 98                    CPX $98
F2F7   F0 14                    BEQ LF30D
F2F9   A4 98                    LDY $98
F2FB   B9 59 02                 LDA $0259,Y
F2FE   9D 59 02                 STA $0259,X
F301   B9 63 02                 LDA $0263,Y
F304   9D 63 02                 STA $0263,X
F307   B9 6D 02                 LDA $026D,Y
F30A   9D 6D 02                 STA $026D,X
F30D   18         LF30D         CLC
F30E   60                       RTS
F30F   A9 00      LF30F         LDA #$00
F311   85 90                    STA $90
F313   8A                       TXA
F314   A6 98      LF314         LDX $98
F316   CA         LF316         DEX
F317   30 15                    BMI LF32E
F319   DD 59 02                 CMP $0259,X
F31C   D0 F8                    BNE LF316
F31E   60                       RTS
F31F   BD 59 02   LF31F         LDA $0259,X
F322   85 B8                    STA $B8
F324   BD 63 02                 LDA $0263,X
F327   85 BA                    STA $BA
F329   BD 6D 02                 LDA $026D,X
F32C   85 B9                    STA $B9
F32E   60         LF32E         RTS
F32F   A9 00                    LDA #$00
F331   85 98                    STA $98
F333   A2 03                    LDX #$03
F335   E4 9A                    CPX $9A
F337   B0 03                    BCS LF33C
F339   20 FE ED                 JSR LEDFE
F33C   E4 99      LF33C         CPX $99
F33E   B0 03                    BCS LF343
F340   20 EF ED                 JSR LEDEF
F343   86 9A      LF343         STX $9A
F345   A9 00                    LDA #$00
F347   85 99                    STA $99
F349   60                       RTS
F34A   A6 B8                    LDX $B8
F34C   D0 03                    BNE LF351
F34E   4C 0A F7                 JMP LF70A
F351   20 0F F3   LF351         JSR LF30F
F354   D0 03                    BNE LF359
F356   4C FE F6                 JMP LF6FE
F359   A6 98      LF359         LDX $98
F35B   E0 0A                    CPX #$0A
F35D   90 03                    BCC LF362
F35F   4C FB F6                 JMP LF6FB
F362   E6 98      LF362         INC $98
F364   A5 B8                    LDA $B8
F366   9D 59 02                 STA $0259,X
F369   A5 B9                    LDA $B9
F36B   09 60                    ORA #$60
F36D   85 B9                    STA $B9
F36F   9D 6D 02                 STA $026D,X
F372   A5 BA                    LDA $BA
F374   9D 63 02                 STA $0263,X
F377   F0 5A                    BEQ LF3D3
F379   C9 03                    CMP #$03
F37B   F0 56                    BEQ LF3D3
F37D   90 05                    BCC LF384
F37F   20 D5 F3                 JSR LF3D5
F382   90 4F                    BCC LF3D3
F384   C9 02      LF384         CMP #$02
F386   D0 03                    BNE LF38B
F388   4C 09 F4                 JMP LF409
F38B   20 D0 F7   LF38B         JSR LF7D0
F38E   B0 03                    BCS LF393
F390   4C 13 F7                 JMP LF713
F393   A5 B9      LF393         LDA $B9
F395   29 0F                    AND #$0F
F397   D0 1F                    BNE LF3B8
F399   20 17 F8                 JSR LF817
F39C   B0 36                    BCS LF3D4
F39E   20 AF F5                 JSR LF5AF
F3A1   A5 B7                    LDA $B7
F3A3   F0 0A                    BEQ LF3AF
F3A5   20 EA F7                 JSR LF7EA
F3A8   90 18                    BCC LF3C2
F3AA   F0 28                    BEQ LF3D4
F3AC   4C 04 F7   LF3AC         JMP LF704
F3AF   20 2C F7   LF3AF         JSR LF72C
F3B2   F0 20                    BEQ LF3D4
F3B4   90 0C                    BCC LF3C2
F3B6   B0 F4                    BCS LF3AC
F3B8   20 38 F8   LF3B8         JSR LF838
F3BB   B0 17                    BCS LF3D4
F3BD   A9 04                    LDA #$04
F3BF   20 6A F7                 JSR LF76A
F3C2   A9 BF      LF3C2         LDA #$BF
F3C4   A4 B9                    LDY $B9
F3C6   C0 60                    CPY #$60
F3C8   F0 07                    BEQ LF3D1
F3CA   A0 00                    LDY #$00
F3CC   A9 02                    LDA #$02
F3CE   91 B2                    STA ($B2),Y
F3D0   98                       TYA
F3D1   85 A6      LF3D1         STA $A6
F3D3   18         LF3D3         CLC
F3D4   60         LF3D4         RTS
F3D5   A5 B9      LF3D5         LDA $B9
F3D7   30 FA                    BMI LF3D3
F3D9   A4 B7                    LDY $B7
F3DB   F0 F6                    BEQ LF3D3
F3DD   A9 00                    LDA #$00
F3DF   85 90                    STA $90
F3E1   A5 BA                    LDA $BA
F3E3   20 0C ED                 JSR LED0C
F3E6   A5 B9                    LDA $B9
F3E8   09 F0                    ORA #$F0
F3EA   20 B9 ED                 JSR LEDB9
F3ED   A5 90                    LDA $90
F3EF   10 05                    BPL LF3F6
F3F1   68                       PLA
F3F2   68                       PLA
F3F3   4C 07 F7                 JMP LF707
F3F6   A5 B7      LF3F6         LDA $B7
F3F8   F0 0C                    BEQ LF406
F3FA   A0 00                    LDY #$00
F3FC   B1 BB      LF3FC         LDA ($BB),Y
F3FE   20 DD ED                 JSR LEDDD
F401   C8                       INY
F402   C4 B7                    CPY $B7
F404   D0 F6                    BNE LF3FC
F406   4C 54 F6   LF406         JMP LF654
F409   20 83 F4   LF409         JSR LF483
F40C   8C 97 02                 STY $0297
F40F   C4 B7      LF40F         CPY $B7
F411   F0 0A                    BEQ LF41D
F413   B1 BB                    LDA ($BB),Y
F415   99 93 02                 STA $0293,Y
F418   C8                       INY
F419   C0 04                    CPY #$04
F41B   D0 F2                    BNE LF40F
F41D   20 4A EF   LF41D         JSR LEF4A
F420   8E 98 02                 STX $0298
F423   AD 93 02                 LDA $0293
F426   29 0F                    AND #$0F
F428   F0 1C                    BEQ LF446
F42A   0A                       ASL A
F42B   AA                       TAX
F42C   AD A6 02                 LDA $02A6
F42F   D0 09                    BNE LF43A
F431   BC C1 FE                 LDY $FEC1,X
F434   BD C0 FE                 LDA $FEC0,X
F437   4C 40 F4                 JMP LF440
F43A   BC EB E4   LF43A         LDY LE4EB,X
F43D   BD EA E4                 LDA $E4EA,X
F440   8C 96 02   LF440         STY $0296
F443   8D 95 02                 STA $0295
F446   AD 95 02   LF446         LDA $0295
F449   0A                       ASL A
F44A   20 2E FF                 JSR LFF2E
F44D   AD 94 02                 LDA $0294
F450   4A                       LSR A
F451   90 09                    BCC LF45C
F453   AD 01 DD                 LDA $DD01
F456   0A                       ASL A
F457   B0 03                    BCS LF45C
F459   20 0D F0                 JSR LF00D
F45C   AD 9B 02   LF45C         LDA $029B
F45F   8D 9C 02                 STA $029C
F462   AD 9E 02                 LDA $029E
F465   8D 9D 02                 STA $029D
F468   20 27 FE                 JSR LFE27
F46B   A5 F8                    LDA $F8
F46D   D0 05                    BNE LF474
F46F   88                       DEY
F470   84 F8                    STY $F8
F472   86 F7                    STX $F7
F474   A5 FA      LF474         LDA $FA
F476   D0 05                    BNE LF47D
F478   88                       DEY
F479   84 FA                    STY $FA
F47B   86 F9                    STX $F9
F47D   38         LF47D         SEC
F47E   A9 F0                    LDA #$F0
F480   4C 2D FE                 JMP LFE2D
F483   A9 7F      LF483         LDA #$7F
F485   8D 0D DD                 STA $DD0D
F488   A9 06                    LDA #$06
F48A   8D 03 DD                 STA $DD03
F48D   8D 01 DD                 STA $DD01
F490   A9 04                    LDA #$04
F492   0D 00 DD                 ORA $DD00
F495   8D 00 DD                 STA $DD00
F498   A0 00                    LDY #$00
F49A   8C A1 02                 STY $02A1
F49D   60                       RTS
F49E   86 C3      LF49E         STX $C3
F4A0   84 C4                    STY $C4
F4A2   6C 30 03                 JMP ($0330)
F4A5   85 93                    STA $93
F4A7   A9 00                    LDA #$00
F4A9   85 90                    STA $90
F4AB   A5 BA                    LDA $BA
F4AD   D0 03                    BNE LF4B2
F4AF   4C 13 F7   LF4AF         JMP LF713
F4B2   C9 03      LF4B2         CMP #$03
F4B4   F0 F9                    BEQ LF4AF
F4B6   90 7B                    BCC LF533
F4B8   A4 B7                    LDY $B7
F4BA   D0 03                    BNE LF4BF
F4BC   4C 10 F7                 JMP LF710
F4BF   A6 B9      LF4BF         LDX $B9
F4C1   20 AF F5                 JSR LF5AF
F4C4   A9 60                    LDA #$60
F4C6   85 B9                    STA $B9
F4C8   20 D5 F3                 JSR LF3D5
F4CB   A5 BA                    LDA $BA
F4CD   20 09 ED                 JSR LED09
F4D0   A5 B9                    LDA $B9
F4D2   20 C7 ED                 JSR LEDC7
F4D5   20 13 EE                 JSR LEE13
F4D8   85 AE                    STA $AE
F4DA   A5 90                    LDA $90
F4DC   4A                       LSR A
F4DD   4A                       LSR A
F4DE   B0 50                    BCS LF530
F4E0   20 13 EE                 JSR LEE13
F4E3   85 AF                    STA $AF
F4E5   8A                       TXA
F4E6   D0 08                    BNE LF4F0
F4E8   A5 C3                    LDA $C3
F4EA   85 AE                    STA $AE
F4EC   A5 C4                    LDA $C4
F4EE   85 AF                    STA $AF
F4F0   20 D2 F5   LF4F0         JSR LF5D2
F4F3   A9 FD      LF4F3         LDA #$FD
F4F5   25 90                    AND $90
F4F7   85 90                    STA $90
F4F9   20 E1 FF                 JSR LFFE1
F4FC   D0 03                    BNE LF501
F4FE   4C 33 F6                 JMP LF633
F501   20 13 EE   LF501         JSR LEE13
F504   AA                       TAX
F505   A5 90                    LDA $90
F507   4A                       LSR A
F508   4A                       LSR A
F509   B0 E8                    BCS LF4F3
F50B   8A                       TXA
F50C   A4 93                    LDY $93
F50E   F0 0C                    BEQ LF51C
F510   A0 00                    LDY #$00
F512   D1 AE                    CMP ($AE),Y
F514   F0 08                    BEQ LF51E
F516   A9 10                    LDA #$10
F518   20 1C FE                 JSR LFE1C
F51B   2C 91 AE                 BIT $AE91
F51E   E6 AE      LF51E         INC $AE
F520   D0 02                    BNE LF524
F522   E6 AF                    INC $AF
F524   24 90      LF524         BIT $90
F526   50 CB                    BVC LF4F3
F528   20 EF ED                 JSR LEDEF
F52B   20 42 F6                 JSR LF642
F52E   90 79                    BCC LF5A9
F530   4C 04 F7   LF530         JMP LF704
F533   4A         LF533         LSR A
F534   B0 03                    BCS LF539
F536   4C 13 F7                 JMP LF713
F539   20 D0 F7   LF539         JSR LF7D0
F53C   B0 03                    BCS LF541
F53E   4C 13 F7                 JMP LF713
F541   20 17 F8   LF541         JSR LF817
F544   B0 68                    BCS LF5AE
F546   20 AF F5                 JSR LF5AF
F549   A5 B7      LF549         LDA $B7
F54B   F0 09                    BEQ LF556
F54D   20 EA F7                 JSR LF7EA
F550   90 0B                    BCC LF55D
F552   F0 5A                    BEQ LF5AE
F554   B0 DA                    BCS LF530
F556   20 2C F7   LF556         JSR LF72C
F559   F0 53                    BEQ LF5AE
F55B   B0 D3                    BCS LF530
F55D   A5 90      LF55D         LDA $90
F55F   29 10                    AND #$10
F561   38                       SEC
F562   D0 4A                    BNE LF5AE
F564   E0 01                    CPX #$01
F566   F0 11                    BEQ LF579
F568   E0 03                    CPX #$03
F56A   D0 DD                    BNE LF549
F56C   A0 01      LF56C         LDY #$01
F56E   B1 B2                    LDA ($B2),Y
F570   85 C3                    STA $C3
F572   C8                       INY
F573   B1 B2                    LDA ($B2),Y
F575   85 C4                    STA $C4
F577   B0 04                    BCS LF57D
F579   A5 B9      LF579         LDA $B9
F57B   D0 EF                    BNE LF56C
F57D   A0 03      LF57D         LDY #$03
F57F   B1 B2                    LDA ($B2),Y
F581   A0 01                    LDY #$01
F583   F1 B2                    SBC ($B2),Y
F585   AA                       TAX
F586   A0 04                    LDY #$04
F588   B1 B2                    LDA ($B2),Y
F58A   A0 02                    LDY #$02
F58C   F1 B2                    SBC ($B2),Y
F58E   A8                       TAY
F58F   18                       CLC
F590   8A                       TXA
F591   65 C3                    ADC $C3
F593   85 AE                    STA $AE
F595   98                       TYA
F596   65 C4                    ADC $C4
F598   85 AF                    STA $AF
F59A   A5 C3                    LDA $C3
F59C   85 C1                    STA $C1
F59E   A5 C4                    LDA $C4
F5A0   85 C2                    STA $C2
F5A2   20 D2 F5                 JSR LF5D2
F5A5   20 4A F8                 JSR LF84A
F5A8   24 18                    BIT $18
F5AA   A6 AE                    LDX $AE
F5AC   A4 AF                    LDY $AF
F5AE   60         LF5AE         RTS
F5AF   A5 9D      LF5AF         LDA $9D
F5B1   10 1E                    BPL LF5D1
F5B3   A0 0C                    LDY #$0C
F5B5   20 2F F1                 JSR LF12F
F5B8   A5 B7                    LDA $B7
F5BA   F0 15                    BEQ LF5D1
F5BC   A0 17                    LDY #$17
F5BE   20 2F F1                 JSR LF12F
F5C1   A4 B7      LF5C1         LDY $B7
F5C3   F0 0C                    BEQ LF5D1
F5C5   A0 00                    LDY #$00
F5C7   B1 BB      LF5C7         LDA ($BB),Y
F5C9   20 D2 FF                 JSR LFFD2
F5CC   C8                       INY
F5CD   C4 B7                    CPY $B7
F5CF   D0 F6                    BNE LF5C7
F5D1   60         LF5D1         RTS
F5D2   A0 49      LF5D2         LDY #$49
F5D4   A5 93                    LDA $93
F5D6   F0 02                    BEQ LF5DA
F5D8   A0 59                    LDY #$59
F5DA   4C 2B F1   LF5DA         JMP LF12B
F5DD   86 AE      LF5DD         STX $AE
F5DF   84 AF                    STY $AF
F5E1   AA                       TAX
F5E2   B5 00                    LDA $00,X
F5E4   85 C1                    STA $C1
F5E6   B5 01                    LDA $01,X
F5E8   85 C2                    STA $C2
F5EA   6C 32 03                 JMP ($0332)
F5ED   A5 BA                    LDA $BA
F5EF   D0 03                    BNE LF5F4
F5F1   4C 13 F7   LF5F1         JMP LF713
F5F4   C9 03      LF5F4         CMP #$03
F5F6   F0 F9                    BEQ LF5F1
F5F8   90 5F                    BCC LF659
F5FA   A9 61                    LDA #$61
F5FC   85 B9                    STA $B9
F5FE   A4 B7                    LDY $B7
F600   D0 03                    BNE LF605
F602   4C 10 F7                 JMP LF710
F605   20 D5 F3   LF605         JSR LF3D5
F608   20 8F F6                 JSR LF68F
F60B   A5 BA                    LDA $BA
F60D   20 0C ED                 JSR LED0C
F610   A5 B9                    LDA $B9
F612   20 B9 ED                 JSR LEDB9
F615   A0 00                    LDY #$00
F617   20 8E FB                 JSR LFB8E
F61A   A5 AC                    LDA $AC
F61C   20 DD ED                 JSR LEDDD
F61F   A5 AD                    LDA $AD
F621   20 DD ED                 JSR LEDDD
F624   20 D1 FC   LF624         JSR LFCD1
F627   B0 16                    BCS LF63F
F629   B1 AC                    LDA ($AC),Y
F62B   20 DD ED                 JSR LEDDD
F62E   20 E1 FF                 JSR LFFE1
F631   D0 07                    BNE LF63A
F633   20 42 F6   LF633         JSR LF642
F636   A9 00                    LDA #$00
F638   38                       SEC
F639   60                       RTS
F63A   20 DB FC   LF63A         JSR LFCDB
F63D   D0 E5                    BNE LF624
F63F   20 FE ED   LF63F         JSR LEDFE
F642   24 B9      LF642         BIT $B9
F644   30 11                    BMI LF657
F646   A5 BA                    LDA $BA
F648   20 0C ED                 JSR LED0C
F64B   A5 B9                    LDA $B9
F64D   29 EF                    AND #$EF
F64F   09 E0                    ORA #$E0
F651   20 B9 ED                 JSR LEDB9
F654   20 FE ED   LF654         JSR LEDFE
F657   18         LF657         CLC
F658   60                       RTS
F659   4A         LF659         LSR A
F65A   B0 03                    BCS LF65F
F65C   4C 13 F7                 JMP LF713
F65F   20 D0 F7   LF65F         JSR LF7D0
F662   90 8D                    BCC LF5F1
F664   20 38 F8                 JSR LF838
F667   B0 25                    BCS LF68E
F669   20 8F F6                 JSR LF68F
F66C   A2 03                    LDX #$03
F66E   A5 B9                    LDA $B9
F670   29 01                    AND #$01
F672   D0 02                    BNE LF676
F674   A2 01                    LDX #$01
F676   8A         LF676         TXA
F677   20 6A F7                 JSR LF76A
F67A   B0 12                    BCS LF68E
F67C   20 67 F8                 JSR LF867
F67F   B0 0D                    BCS LF68E
F681   A5 B9                    LDA $B9
F683   29 02                    AND #$02
F685   F0 06                    BEQ LF68D
F687   A9 05                    LDA #$05
F689   20 6A F7                 JSR LF76A
F68C   24 18                    BIT $18
F68E   60         LF68E         RTS
F68F   A5 9D      LF68F         LDA $9D
F691   10 FB                    BPL LF68E
F693   A0 51                    LDY #$51
F695   20 2F F1                 JSR LF12F
F698   4C C1 F5                 JMP LF5C1
F69B   A2 00      LF69B         LDX #$00
F69D   E6 A2                    INC $A2
F69F   D0 06                    BNE LF6A7
F6A1   E6 A1                    INC $A1
F6A3   D0 02                    BNE LF6A7
F6A5   E6 A0                    INC $A0
F6A7   38         LF6A7         SEC
F6A8   A5 A2                    LDA $A2
F6AA   E9 01                    SBC #$01
F6AC   A5 A1                    LDA $A1
F6AE   E9 1A                    SBC #$1A
F6B0   A5 A0                    LDA $A0
F6B2   E9 4F                    SBC #$4F
F6B4   90 06                    BCC LF6BC
F6B6   86 A0                    STX $A0
F6B8   86 A1                    STX $A1
F6BA   86 A2                    STX $A2
F6BC   AD 01 DC   LF6BC         LDA $DC01
F6BF   CD 01 DC                 CMP $DC01
F6C2   D0 F8                    BNE LF6BC
F6C4   AA                       TAX
F6C5   30 13                    BMI LF6DA
F6C7   A2 BD                    LDX #$BD
F6C9   8E 00 DC                 STX $DC00
F6CC   AE 01 DC   LF6CC         LDX $DC01
F6CF   EC 01 DC                 CPX $DC01
F6D2   D0 F8                    BNE LF6CC
F6D4   8D 00 DC                 STA $DC00
F6D7   E8                       INX
F6D8   D0 02                    BNE LF6DC
F6DA   85 91      LF6DA         STA $91
F6DC   60         LF6DC         RTS
F6DD   78         LF6DD         SEI
F6DE   A5 A2                    LDA $A2
F6E0   A6 A1                    LDX $A1
F6E2   A4 A0                    LDY $A0
F6E4   78         LF6E4         SEI
F6E5   85 A2                    STA $A2
F6E7   86 A1                    STX $A1
F6E9   84 A0                    STY $A0
F6EB   58                       CLI
F6EC   60                       RTS
F6ED   A5 91                    LDA $91
F6EF   C9 7F                    CMP #$7F
F6F1   D0 07                    BNE LF6FA
F6F3   08                       PHP
F6F4   20 CC FF                 JSR LFFCC
F6F7   85 C6                    STA $C6
F6F9   28                       PLP
F6FA   60         LF6FA         RTS
F6FB   A9 01      LF6FB         LDA #$01
F6FD   2C A9 02                 BIT $02A9
F700   2C A9 03                 BIT $03A9
F703   2C A9 04                 BIT $04A9
F706   2C A9 05                 BIT $05A9
F709   2C A9 06                 BIT $06A9
F70C   2C A9 07                 BIT $07A9
F70F   2C A9 08                 BIT $08A9
F712   2C A9 09                 BIT $09A9
F715   48                       PHA
F716   20 CC FF                 JSR LFFCC
F719   A0 00                    LDY #$00
F71B   24 9D                    BIT $9D
F71D   50 0A                    BVC LF729
F71F   20 2F F1                 JSR LF12F
F722   68                       PLA
F723   48                       PHA
F724   09 30                    ORA #$30
F726   20 D2 FF                 JSR LFFD2
F729   68         LF729         PLA
F72A   38                       SEC
F72B   60                       RTS
F72C   A5 93      LF72C         LDA $93
F72E   48                       PHA
F72F   20 41 F8                 JSR LF841
F732   68                       PLA
F733   85 93                    STA $93
F735   B0 32                    BCS LF769
F737   A0 00                    LDY #$00
F739   B1 B2                    LDA ($B2),Y
F73B   C9 05                    CMP #$05
F73D   F0 2A                    BEQ LF769
F73F   C9 01                    CMP #$01
F741   F0 08                    BEQ LF74B
F743   C9 03                    CMP #$03
F745   F0 04                    BEQ LF74B
F747   C9 04                    CMP #$04
F749   D0 E1                    BNE LF72C
F74B   AA         LF74B         TAX
F74C   24 9D                    BIT $9D
F74E   10 17                    BPL LF767
F750   A0 63                    LDY #$63
F752   20 2F F1                 JSR LF12F
F755   A0 05                    LDY #$05
F757   B1 B2      LF757         LDA ($B2),Y
F759   20 D2 FF                 JSR LFFD2
F75C   C8                       INY
F75D   C0 15                    CPY #$15
F75F   D0 F6                    BNE LF757
F761   A5 A1                    LDA $A1
F763   20 E0 E4                 JSR LE4E0
F766   EA                       NOP
F767   18         LF767         CLC
F768   88                       DEY
F769   60         LF769         RTS
F76A   85 9E      LF76A         STA $9E
F76C   20 D0 F7                 JSR LF7D0
F76F   90 5E                    BCC LF7CF
F771   A5 C2                    LDA $C2
F773   48                       PHA
F774   A5 C1                    LDA $C1
F776   48                       PHA
F777   A5 AF                    LDA $AF
F779   48                       PHA
F77A   A5 AE                    LDA $AE
F77C   48                       PHA
F77D   A0 BF                    LDY #$BF
F77F   A9 20                    LDA #$20
F781   91 B2      LF781         STA ($B2),Y
F783   88                       DEY
F784   D0 FB                    BNE LF781
F786   A5 9E                    LDA $9E
F788   91 B2                    STA ($B2),Y
F78A   C8                       INY
F78B   A5 C1                    LDA $C1
F78D   91 B2                    STA ($B2),Y
F78F   C8                       INY
F790   A5 C2                    LDA $C2
F792   91 B2                    STA ($B2),Y
F794   C8                       INY
F795   A5 AE                    LDA $AE
F797   91 B2                    STA ($B2),Y
F799   C8                       INY
F79A   A5 AF                    LDA $AF
F79C   91 B2                    STA ($B2),Y
F79E   C8                       INY
F79F   84 9F                    STY $9F
F7A1   A0 00                    LDY #$00
F7A3   84 9E                    STY $9E
F7A5   A4 9E      LF7A5         LDY $9E
F7A7   C4 B7                    CPY $B7
F7A9   F0 0C                    BEQ LF7B7
F7AB   B1 BB                    LDA ($BB),Y
F7AD   A4 9F                    LDY $9F
F7AF   91 B2                    STA ($B2),Y
F7B1   E6 9E                    INC $9E
F7B3   E6 9F                    INC $9F
F7B5   D0 EE                    BNE LF7A5
F7B7   20 D7 F7   LF7B7         JSR LF7D7
F7BA   A9 69                    LDA #$69
F7BC   85 AB                    STA $AB
F7BE   20 6B F8                 JSR LF86B
F7C1   A8                       TAY
F7C2   68                       PLA
F7C3   85 AE                    STA $AE
F7C5   68                       PLA
F7C6   85 AF                    STA $AF
F7C8   68                       PLA
F7C9   85 C1                    STA $C1
F7CB   68                       PLA
F7CC   85 C2                    STA $C2
F7CE   98                       TYA
F7CF   60         LF7CF         RTS
F7D0   A6 B2      LF7D0         LDX $B2
F7D2   A4 B3                    LDY $B3
F7D4   C0 02                    CPY #$02
F7D6   60                       RTS
F7D7   20 D0 F7   LF7D7         JSR LF7D0
F7DA   8A                       TXA
F7DB   85 C1                    STA $C1
F7DD   18                       CLC
F7DE   69 C0                    ADC #$C0
F7E0   85 AE                    STA $AE
F7E2   98                       TYA
F7E3   85 C2                    STA $C2
F7E5   69 00                    ADC #$00
F7E7   85 AF                    STA $AF
F7E9   60                       RTS
F7EA   20 2C F7   LF7EA         JSR LF72C
F7ED   B0 1D                    BCS LF80C
F7EF   A0 05                    LDY #$05
F7F1   84 9F                    STY $9F
F7F3   A0 00                    LDY #$00
F7F5   84 9E                    STY $9E
F7F7   C4 B7      LF7F7         CPY $B7
F7F9   F0 10                    BEQ LF80B
F7FB   B1 BB                    LDA ($BB),Y
F7FD   A4 9F                    LDY $9F
F7FF   D1 B2                    CMP ($B2),Y
F801   D0 E7                    BNE LF7EA
F803   E6 9E                    INC $9E
F805   E6 9F                    INC $9F
F807   A4 9E                    LDY $9E
F809   D0 EC                    BNE LF7F7
F80B   18         LF80B         CLC
F80C   60         LF80C         RTS
F80D   20 D0 F7   LF80D         JSR LF7D0
F810   E6 A6                    INC $A6
F812   A4 A6                    LDY $A6
F814   C0 C0                    CPY #$C0
F816   60                       RTS
F817   20 2E F8   LF817         JSR LF82E
F81A   F0 1A                    BEQ LF836
F81C   A0 1B                    LDY #$1B
F81E   20 2F F1   LF81E         JSR LF12F
F821   20 D0 F8   LF821         JSR LF8D0
F824   20 2E F8                 JSR LF82E
F827   D0 F8                    BNE LF821
F829   A0 6A                    LDY #$6A
F82B   4C 2F F1                 JMP LF12F
F82E   A9 10      LF82E         LDA #$10
F830   24 01                    BIT $01
F832   D0 02                    BNE LF836
F834   24 01                    BIT $01
F836   18         LF836         CLC
F837   60                       RTS
F838   20 2E F8   LF838         JSR LF82E
F83B   F0 F9                    BEQ LF836
F83D   A0 2E                    LDY #$2E
F83F   D0 DD                    BNE LF81E
F841   A9 00      LF841         LDA #$00
F843   85 90                    STA $90
F845   85 93                    STA $93
F847   20 D7 F7                 JSR LF7D7
F84A   20 17 F8   LF84A         JSR LF817
F84D   B0 1F                    BCS LF86E
F84F   78                       SEI
F850   A9 00                    LDA #$00
F852   85 AA                    STA $AA
F854   85 B4                    STA $B4
F856   85 B0                    STA $B0
F858   85 9E                    STA $9E
F85A   85 9F                    STA $9F
F85C   85 9C                    STA $9C
F85E   A9 90                    LDA #$90
F860   A2 0E                    LDX #$0E
F862   D0 11                    BNE LF875
F864   20 D7 F7   LF864         JSR LF7D7
F867   A9 14      LF867         LDA #$14
F869   85 AB                    STA $AB
F86B   20 38 F8   LF86B         JSR LF838
F86E   B0 6C      LF86E         BCS LF8DC
F870   78                       SEI
F871   A9 82                    LDA #$82
F873   A2 08                    LDX #$08
F875   A0 7F      LF875         LDY #$7F
F877   8C 0D DC                 STY $DC0D
F87A   8D 0D DC                 STA $DC0D
F87D   AD 0E DC                 LDA $DC0E
F880   09 19                    ORA #$19
F882   8D 0F DC                 STA $DC0F
F885   29 91                    AND #$91
F887   8D A2 02                 STA $02A2
F88A   20 A4 F0                 JSR LF0A4
F88D   AD 11 D0                 LDA $D011
F890   29 EF                    AND #$EF
F892   8D 11 D0                 STA $D011
F895   AD 14 03                 LDA $0314
F898   8D 9F 02                 STA $029F
F89B   AD 15 03                 LDA $0315
F89E   8D A0 02                 STA $02A0
F8A1   20 BD FC                 JSR LFCBD
F8A4   A9 02                    LDA #$02
F8A6   85 BE                    STA $BE
F8A8   20 97 FB                 JSR LFB97
F8AB   A5 01                    LDA $01
F8AD   29 1F                    AND #$1F
F8AF   85 01                    STA $01
F8B1   85 C0                    STA $C0
F8B3   A2 FF                    LDX #$FF
F8B5   A0 FF      LF8B5         LDY #$FF
F8B7   88         LF8B7         DEY
F8B8   D0 FD                    BNE LF8B7
F8BA   CA                       DEX
F8BB   D0 F8                    BNE LF8B5
F8BD   58                       CLI
F8BE   AD A0 02   LF8BE         LDA $02A0
F8C1   CD 15 03                 CMP $0315
F8C4   18                       CLC
F8C5   F0 15                    BEQ LF8DC
F8C7   20 D0 F8                 JSR LF8D0
F8CA   20 BC F6                 JSR LF6BC
F8CD   4C BE F8                 JMP LF8BE
F8D0   20 E1 FF   LF8D0         JSR LFFE1
F8D3   18                       CLC
F8D4   D0 0B                    BNE LF8E1
F8D6   20 93 FC                 JSR LFC93
F8D9   38                       SEC
F8DA   68                       PLA
F8DB   68                       PLA
F8DC   A9 00      LF8DC         LDA #$00
F8DE   8D A0 02                 STA $02A0
F8E1   60         LF8E1         RTS
F8E2   86 B1      LF8E2         STX $B1
F8E4   A5 B0                    LDA $B0
F8E6   0A                       ASL A
F8E7   0A                       ASL A
F8E8   18                       CLC
F8E9   65 B0                    ADC $B0
F8EB   18                       CLC
F8EC   65 B1                    ADC $B1
F8EE   85 B1                    STA $B1
F8F0   A9 00                    LDA #$00
F8F2   24 B0                    BIT $B0
F8F4   30 01                    BMI LF8F7
F8F6   2A                       ROL A
F8F7   06 B1      LF8F7         ASL $B1
F8F9   2A                       ROL A
F8FA   06 B1                    ASL $B1
F8FC   2A                       ROL A
F8FD   AA                       TAX
F8FE   AD 06 DC   LF8FE         LDA $DC06
F901   C9 16                    CMP #$16
F903   90 F9                    BCC LF8FE
F905   65 B1                    ADC $B1
F907   8D 04 DC                 STA $DC04
F90A   8A                       TXA
F90B   6D 07 DC                 ADC $DC07
F90E   8D 05 DC                 STA $DC05
F911   AD A2 02                 LDA $02A2
F914   8D 0E DC                 STA $DC0E
F917   8D A4 02                 STA $02A4
F91A   AD 0D DC                 LDA $DC0D
F91D   29 10                    AND #$10
F91F   F0 09                    BEQ LF92A
F921   A9 F9                    LDA #$F9
F923   48                       PHA
F924   A9 2A                    LDA #$2A
F926   48                       PHA
F927   4C 43 FF                 JMP LFF43
F92A   58         LF92A         CLI
F92B   60                       RTS
F92C   AE 07 DC   LF92C         LDX $DC07
F92F   A0 FF                    LDY #$FF
F931   98                       TYA
F932   ED 06 DC                 SBC $DC06
F935   EC 07 DC                 CPX $DC07
F938   D0 F2                    BNE LF92C
F93A   86 B1                    STX $B1
F93C   AA                       TAX
F93D   8C 06 DC                 STY $DC06
F940   8C 07 DC                 STY $DC07
F943   A9 19                    LDA #$19
F945   8D 0F DC                 STA $DC0F
F948   AD 0D DC                 LDA $DC0D
F94B   8D A3 02                 STA $02A3
F94E   98                       TYA
F94F   E5 B1                    SBC $B1
F951   86 B1                    STX $B1
F953   4A                       LSR A
F954   66 B1                    ROR $B1
F956   4A                       LSR A
F957   66 B1                    ROR $B1
F959   A5 B0                    LDA $B0
F95B   18                       CLC
F95C   69 3C                    ADC #$3C
F95E   C5 B1                    CMP $B1
F960   B0 4A                    BCS LF9AC
F962   A6 9C                    LDX $9C
F964   F0 03                    BEQ LF969
F966   4C 60 FA                 JMP LFA60
F969   A6 A3      LF969         LDX $A3
F96B   30 1B                    BMI LF988
F96D   A2 00                    LDX #$00
F96F   69 30                    ADC #$30
F971   65 B0                    ADC $B0
F973   C5 B1                    CMP $B1
F975   B0 1C                    BCS LF993
F977   E8                       INX
F978   69 26                    ADC #$26
F97A   65 B0                    ADC $B0
F97C   C5 B1                    CMP $B1
F97E   B0 17                    BCS LF997
F980   69 2C                    ADC #$2C
F982   65 B0                    ADC $B0
F984   C5 B1                    CMP $B1
F986   90 03                    BCC LF98B
F988   4C 10 FA   LF988         JMP LFA10
F98B   A5 B4      LF98B         LDA $B4
F98D   F0 1D                    BEQ LF9AC
F98F   85 A8                    STA $A8
F991   D0 19                    BNE LF9AC
F993   E6 A9      LF993         INC $A9
F995   B0 02                    BCS LF999
F997   C6 A9      LF997         DEC $A9
F999   38         LF999         SEC
F99A   E9 13                    SBC #$13
F99C   E5 B1                    SBC $B1
F99E   65 92                    ADC $92
F9A0   85 92                    STA $92
F9A2   A5 A4                    LDA $A4
F9A4   49 01                    EOR #$01
F9A6   85 A4                    STA $A4
F9A8   F0 2B                    BEQ LF9D5
F9AA   86 D7                    STX $D7
F9AC   A5 B4      LF9AC         LDA $B4
F9AE   F0 22                    BEQ LF9D2
F9B0   AD A3 02                 LDA $02A3
F9B3   29 01                    AND #$01
F9B5   D0 05                    BNE LF9BC
F9B7   AD A4 02                 LDA $02A4
F9BA   D0 16                    BNE LF9D2
F9BC   A9 00      LF9BC         LDA #$00
F9BE   85 A4                    STA $A4
F9C0   8D A4 02                 STA $02A4
F9C3   A5 A3                    LDA $A3
F9C5   10 30                    BPL LF9F7
F9C7   30 BF                    BMI LF988
F9C9   A2 A6      LF9C9         LDX #$A6
F9CB   20 E2 F8                 JSR LF8E2
F9CE   A5 9B                    LDA $9B
F9D0   D0 B9                    BNE LF98B
F9D2   4C BC FE   LF9D2         JMP LFEBC
F9D5   A5 92      LF9D5         LDA $92
F9D7   F0 07                    BEQ LF9E0
F9D9   30 03                    BMI LF9DE
F9DB   C6 B0                    DEC $B0
F9DD   2C E6 B0                 BIT $B0E6
F9E0   A9 00      LF9E0         LDA #$00
F9E2   85 92                    STA $92
F9E4   E4 D7                    CPX $D7
F9E6   D0 0F                    BNE LF9F7
F9E8   8A                       TXA
F9E9   D0 A0                    BNE LF98B
F9EB   A5 A9                    LDA $A9
F9ED   30 BD                    BMI LF9AC
F9EF   C9 10                    CMP #$10
F9F1   90 B9                    BCC LF9AC
F9F3   85 96                    STA $96
F9F5   B0 B5                    BCS LF9AC
F9F7   8A         LF9F7         TXA
F9F8   45 9B                    EOR $9B
F9FA   85 9B                    STA $9B
F9FC   A5 B4                    LDA $B4
F9FE   F0 D2                    BEQ LF9D2
FA00   C6 A3                    DEC $A3
FA02   30 C5                    BMI LF9C9
FA04   46 D7                    LSR $D7
FA06   66 BF                    ROR $BF
FA08   A2 DA                    LDX #$DA
FA0A   20 E2 F8                 JSR LF8E2
FA0D   4C BC FE                 JMP LFEBC
FA10   A5 96      LFA10         LDA $96
FA12   F0 04                    BEQ LFA18
FA14   A5 B4                    LDA $B4
FA16   F0 07                    BEQ LFA1F
FA18   A5 A3      LFA18         LDA $A3
FA1A   30 03                    BMI LFA1F
FA1C   4C 97 F9                 JMP LF997
FA1F   46 B1      LFA1F         LSR $B1
FA21   A9 93                    LDA #$93
FA23   38                       SEC
FA24   E5 B1                    SBC $B1
FA26   65 B0                    ADC $B0
FA28   0A                       ASL A
FA29   AA                       TAX
FA2A   20 E2 F8                 JSR LF8E2
FA2D   E6 9C                    INC $9C
FA2F   A5 B4                    LDA $B4
FA31   D0 11                    BNE LFA44
FA33   A5 96                    LDA $96
FA35   F0 26                    BEQ LFA5D
FA37   85 A8                    STA $A8
FA39   A9 00                    LDA #$00
FA3B   85 96                    STA $96
FA3D   A9 81                    LDA #$81
FA3F   8D 0D DC                 STA $DC0D
FA42   85 B4                    STA $B4
FA44   A5 96      LFA44         LDA $96
FA46   85 B5                    STA $B5
FA48   F0 09                    BEQ LFA53
FA4A   A9 00                    LDA #$00
FA4C   85 B4                    STA $B4
FA4E   A9 01                    LDA #$01
FA50   8D 0D DC                 STA $DC0D
FA53   A5 BF      LFA53         LDA $BF
FA55   85 BD                    STA $BD
FA57   A5 A8                    LDA $A8
FA59   05 A9                    ORA $A9
FA5B   85 B6                    STA $B6
FA5D   4C BC FE   LFA5D         JMP LFEBC
FA60   20 97 FB   LFA60         JSR LFB97
FA63   85 9C                    STA $9C
FA65   A2 DA                    LDX #$DA
FA67   20 E2 F8                 JSR LF8E2
FA6A   A5 BE                    LDA $BE
FA6C   F0 02                    BEQ LFA70
FA6E   85 A7                    STA $A7
FA70   A9 0F      LFA70         LDA #$0F
FA72   24 AA                    BIT $AA
FA74   10 17                    BPL LFA8D
FA76   A5 B5                    LDA $B5
FA78   D0 0C                    BNE LFA86
FA7A   A6 BE                    LDX $BE
FA7C   CA                       DEX
FA7D   D0 0B                    BNE LFA8A
FA7F   A9 08                    LDA #$08
FA81   20 1C FE                 JSR LFE1C
FA84   D0 04                    BNE LFA8A
FA86   A9 00      LFA86         LDA #$00
FA88   85 AA                    STA $AA
FA8A   4C BC FE   LFA8A         JMP LFEBC
FA8D   70 31      LFA8D         BVS LFAC0
FA8F   D0 18                    BNE LFAA9
FA91   A5 B5                    LDA $B5
FA93   D0 F5                    BNE LFA8A
FA95   A5 B6                    LDA $B6
FA97   D0 F1                    BNE LFA8A
FA99   A5 A7                    LDA $A7
FA9B   4A                       LSR A
FA9C   A5 BD                    LDA $BD
FA9E   30 03                    BMI LFAA3
FAA0   90 18                    BCC LFABA
FAA2   18                       CLC
FAA3   B0 15      LFAA3         BCS LFABA
FAA5   29 0F                    AND #$0F
FAA7   85 AA                    STA $AA
FAA9   C6 AA      LFAA9         DEC $AA
FAAB   D0 DD                    BNE LFA8A
FAAD   A9 40                    LDA #$40
FAAF   85 AA                    STA $AA
FAB1   20 8E FB                 JSR LFB8E
FAB4   A9 00                    LDA #$00
FAB6   85 AB                    STA $AB
FAB8   F0 D0                    BEQ LFA8A
FABA   A9 80      LFABA         LDA #$80
FABC   85 AA                    STA $AA
FABE   D0 CA                    BNE LFA8A
FAC0   A5 B5      LFAC0         LDA $B5
FAC2   F0 0A                    BEQ LFACE
FAC4   A9 04                    LDA #$04
FAC6   20 1C FE                 JSR LFE1C
FAC9   A9 00                    LDA #$00
FACB   4C 4A FB                 JMP LFB4A
FACE   20 D1 FC   LFACE         JSR LFCD1
FAD1   90 03                    BCC LFAD6
FAD3   4C 48 FB                 JMP LFB48
FAD6   A6 A7      LFAD6         LDX $A7
FAD8   CA                       DEX
FAD9   F0 2D                    BEQ LFB08
FADB   A5 93                    LDA $93
FADD   F0 0C                    BEQ LFAEB
FADF   A0 00                    LDY #$00
FAE1   A5 BD                    LDA $BD
FAE3   D1 AC                    CMP ($AC),Y
FAE5   F0 04                    BEQ LFAEB
FAE7   A9 01                    LDA #$01
FAE9   85 B6                    STA $B6
FAEB   A5 B6      LFAEB         LDA $B6
FAED   F0 4B                    BEQ LFB3A
FAEF   A2 3D                    LDX #$3D
FAF1   E4 9E                    CPX $9E
FAF3   90 3E                    BCC LFB33
FAF5   A6 9E                    LDX $9E
FAF7   A5 AD                    LDA $AD
FAF9   9D 01 01                 STA $0101,X
FAFC   A5 AC                    LDA $AC
FAFE   9D 00 01                 STA $0100,X
FB01   E8                       INX
FB02   E8                       INX
FB03   86 9E                    STX $9E
FB05   4C 3A FB                 JMP LFB3A
FB08   A6 9F      LFB08         LDX $9F
FB0A   E4 9E                    CPX $9E
FB0C   F0 35                    BEQ LFB43
FB0E   A5 AC                    LDA $AC
FB10   DD 00 01                 CMP $0100,X
FB13   D0 2E                    BNE LFB43
FB15   A5 AD                    LDA $AD
FB17   DD 01 01                 CMP $0101,X
FB1A   D0 27                    BNE LFB43
FB1C   E6 9F                    INC $9F
FB1E   E6 9F                    INC $9F
FB20   A5 93                    LDA $93
FB22   F0 0B                    BEQ LFB2F
FB24   A5 BD                    LDA $BD
FB26   A0 00                    LDY #$00
FB28   D1 AC                    CMP ($AC),Y
FB2A   F0 17                    BEQ LFB43
FB2C   C8                       INY
FB2D   84 B6                    STY $B6
FB2F   A5 B6      LFB2F         LDA $B6
FB31   F0 07                    BEQ LFB3A
FB33   A9 10      LFB33         LDA #$10
FB35   20 1C FE                 JSR LFE1C
FB38   D0 09                    BNE LFB43
FB3A   A5 93      LFB3A         LDA $93
FB3C   D0 05                    BNE LFB43
FB3E   A8                       TAY
FB3F   A5 BD                    LDA $BD
FB41   91 AC                    STA ($AC),Y
FB43   20 DB FC   LFB43         JSR LFCDB
FB46   D0 43                    BNE LFB8B
FB48   A9 80      LFB48         LDA #$80
FB4A   85 AA      LFB4A         STA $AA
FB4C   78                       SEI
FB4D   A2 01                    LDX #$01
FB4F   8E 0D DC                 STX $DC0D
FB52   AE 0D DC                 LDX $DC0D
FB55   A6 BE                    LDX $BE
FB57   CA                       DEX
FB58   30 02                    BMI LFB5C
FB5A   86 BE                    STX $BE
FB5C   C6 A7      LFB5C         DEC $A7
FB5E   F0 08                    BEQ LFB68
FB60   A5 9E                    LDA $9E
FB62   D0 27                    BNE LFB8B
FB64   85 BE                    STA $BE
FB66   F0 23                    BEQ LFB8B
FB68   20 93 FC   LFB68         JSR LFC93
FB6B   20 8E FB                 JSR LFB8E
FB6E   A0 00                    LDY #$00
FB70   84 AB                    STY $AB
FB72   B1 AC      LFB72         LDA ($AC),Y
FB74   45 AB                    EOR $AB
FB76   85 AB                    STA $AB
FB78   20 DB FC                 JSR LFCDB
FB7B   20 D1 FC                 JSR LFCD1
FB7E   90 F2                    BCC LFB72
FB80   A5 AB                    LDA $AB
FB82   45 BD                    EOR $BD
FB84   F0 05                    BEQ LFB8B
FB86   A9 20                    LDA #$20
FB88   20 1C FE                 JSR LFE1C
FB8B   4C BC FE   LFB8B         JMP LFEBC
FB8E   A5 C2      LFB8E         LDA $C2
FB90   85 AD                    STA $AD
FB92   A5 C1                    LDA $C1
FB94   85 AC                    STA $AC
FB96   60                       RTS
FB97   A9 08      LFB97         LDA #$08
FB99   85 A3                    STA $A3
FB9B   A9 00                    LDA #$00
FB9D   85 A4                    STA $A4
FB9F   85 A8                    STA $A8
FBA1   85 9B                    STA $9B
FBA3   85 A9                    STA $A9
FBA5   60                       RTS
FBA6   A5 BD      LFBA6         LDA $BD
FBA8   4A                       LSR A
FBA9   A9 60                    LDA #$60
FBAB   90 02                    BCC LFBAF
FBAD   A9 B0      LFBAD         LDA #$B0
FBAF   A2 00      LFBAF         LDX #$00
FBB1   8D 06 DC   LFBB1         STA $DC06
FBB4   8E 07 DC                 STX $DC07
FBB7   AD 0D DC                 LDA $DC0D
FBBA   A9 19                    LDA #$19
FBBC   8D 0F DC                 STA $DC0F
FBBF   A5 01                    LDA $01
FBC1   49 08                    EOR #$08
FBC3   85 01                    STA $01
FBC5   29 08                    AND #$08
FBC7   60                       RTS
FBC8   38         LFBC8         SEC
FBC9   66 B6                    ROR $B6
FBCB   30 3C                    BMI LFC09
FBCD   A5 A8                    LDA $A8
FBCF   D0 12                    BNE LFBE3
FBD1   A9 10                    LDA #$10
FBD3   A2 01                    LDX #$01
FBD5   20 B1 FB                 JSR LFBB1
FBD8   D0 2F                    BNE LFC09
FBDA   E6 A8                    INC $A8
FBDC   A5 B6                    LDA $B6
FBDE   10 29                    BPL LFC09
FBE0   4C 57 FC                 JMP LFC57
FBE3   A5 A9      LFBE3         LDA $A9
FBE5   D0 09                    BNE LFBF0
FBE7   20 AD FB                 JSR LFBAD
FBEA   D0 1D                    BNE LFC09
FBEC   E6 A9                    INC $A9
FBEE   D0 19                    BNE LFC09
FBF0   20 A6 FB   LFBF0         JSR LFBA6
FBF3   D0 14                    BNE LFC09
FBF5   A5 A4                    LDA $A4
FBF7   49 01                    EOR #$01
FBF9   85 A4                    STA $A4
FBFB   F0 0F                    BEQ LFC0C
FBFD   A5 BD                    LDA $BD
FBFF   49 01                    EOR #$01
FC01   85 BD                    STA $BD
FC03   29 01                    AND #$01
FC05   45 9B                    EOR $9B
FC07   85 9B                    STA $9B
FC09   4C BC FE   LFC09         JMP LFEBC
FC0C   46 BD      LFC0C         LSR $BD
FC0E   C6 A3                    DEC $A3
FC10   A5 A3                    LDA $A3
FC12   F0 3A                    BEQ LFC4E
FC14   10 F3                    BPL LFC09
FC16   20 97 FB   LFC16         JSR LFB97
FC19   58                       CLI
FC1A   A5 A5                    LDA $A5
FC1C   F0 12                    BEQ LFC30
FC1E   A2 00                    LDX #$00
FC20   86 D7                    STX $D7
FC22   C6 A5                    DEC $A5
FC24   A6 BE                    LDX $BE
FC26   E0 02                    CPX #$02
FC28   D0 02                    BNE LFC2C
FC2A   09 80                    ORA #$80
FC2C   85 BD      LFC2C         STA $BD
FC2E   D0 D9                    BNE LFC09
FC30   20 D1 FC   LFC30         JSR LFCD1
FC33   90 0A                    BCC LFC3F
FC35   D0 91                    BNE LFBC8
FC37   E6 AD                    INC $AD
FC39   A5 D7                    LDA $D7
FC3B   85 BD                    STA $BD
FC3D   B0 CA                    BCS LFC09
FC3F   A0 00      LFC3F         LDY #$00
FC41   B1 AC                    LDA ($AC),Y
FC43   85 BD                    STA $BD
FC45   45 D7                    EOR $D7
FC47   85 D7                    STA $D7
FC49   20 DB FC                 JSR LFCDB
FC4C   D0 BB                    BNE LFC09
FC4E   A5 9B      LFC4E         LDA $9B
FC50   49 01                    EOR #$01
FC52   85 BD                    STA $BD
FC54   4C BC FE   LFC54         JMP LFEBC
FC57   C6 BE      LFC57         DEC $BE
FC59   D0 03                    BNE LFC5E
FC5B   20 CA FC                 JSR LFCCA
FC5E   A9 50      LFC5E         LDA #$50
FC60   85 A7                    STA $A7
FC62   A2 08                    LDX #$08
FC64   78                       SEI
FC65   20 BD FC                 JSR LFCBD
FC68   D0 EA                    BNE LFC54
FC6A   A9 78                    LDA #$78
FC6C   20 AF FB                 JSR LFBAF
FC6F   D0 E3                    BNE LFC54
FC71   C6 A7                    DEC $A7
FC73   D0 DF                    BNE LFC54
FC75   20 97 FB                 JSR LFB97
FC78   C6 AB                    DEC $AB
FC7A   10 D8                    BPL LFC54
FC7C   A2 0A                    LDX #$0A
FC7E   20 BD FC                 JSR LFCBD
FC81   58                       CLI
FC82   E6 AB                    INC $AB
FC84   A5 BE                    LDA $BE
FC86   F0 30                    BEQ LFCB8
FC88   20 8E FB                 JSR LFB8E
FC8B   A2 09                    LDX #$09
FC8D   86 A5                    STX $A5
FC8F   86 B6                    STX $B6
FC91   D0 83                    BNE LFC16
FC93   08         LFC93         PHP
FC94   78                       SEI
FC95   AD 11 D0                 LDA $D011
FC98   09 10                    ORA #$10
FC9A   8D 11 D0                 STA $D011
FC9D   20 CA FC                 JSR LFCCA
FCA0   A9 7F                    LDA #$7F
FCA2   8D 0D DC                 STA $DC0D
FCA5   20 DD FD                 JSR LFDDD
FCA8   AD A0 02                 LDA $02A0
FCAB   F0 09                    BEQ LFCB6
FCAD   8D 15 03                 STA $0315
FCB0   AD 9F 02                 LDA $029F
FCB3   8D 14 03                 STA $0314
FCB6   28         LFCB6         PLP
FCB7   60                       RTS
FCB8   20 93 FC   LFCB8         JSR LFC93
FCBB   F0 97                    BEQ LFC54
FCBD   BD 93 FD   LFCBD         LDA $FD93,X
FCC0   8D 14 03                 STA $0314
FCC3   BD 94 FD                 LDA $FD94,X
FCC6   8D 15 03                 STA $0315
FCC9   60                       RTS
FCCA   A5 01      LFCCA         LDA $01
FCCC   09 20                    ORA #$20
FCCE   85 01                    STA $01
FCD0   60                       RTS
FCD1   38         LFCD1         SEC
FCD2   A5 AC                    LDA $AC
FCD4   E5 AE                    SBC $AE
FCD6   A5 AD                    LDA $AD
FCD8   E5 AF                    SBC $AF
FCDA   60                       RTS
FCDB   E6 AC      LFCDB         INC $AC
FCDD   D0 02                    BNE LFCE1
FCDF   E6 AD                    INC $AD
FCE1   60         LFCE1         RTS
FCE2   A2 FF                    LDX #$FF
FCE4   78                       SEI
FCE5   9A                       TXS
FCE6   D8                       CLD
FCE7   20 02 FD                 JSR LFD02
FCEA   D0 03                    BNE LFCEF
FCEC   6C 00 80                 JMP ($8000)
FCEF   8E 16 D0   LFCEF         STX $D016
FCF2   20 A3 FD                 JSR LFDA3
FCF5   20 50 FD                 JSR LFD50
FCF8   20 15 FD                 JSR LFD15
FCFB   20 5B FF                 JSR LFF5B
FCFE   58                       CLI
FCFF   6C 00 A0                 JMP ($A000)
FD02   A2 05      LFD02         LDX #$05
FD04   BD 0F FD   LFD04         LDA LFD0F,X
FD07   DD 03 80                 CMP $8003,X
FD0A   D0 03                    BNE LFD0F
FD0C   CA                       DEX
FD0D   D0 F5                    BNE LFD04
FD0F   60         LFD0F         RTS
FD10   C3                       ???               ;%11000011
FD11   C2                       ???               ;%11000010
FD12   CD 38 30                 CMP $3038
FD15   A2 30      LFD15         LDX #$30
FD17   A0 FD                    LDY #$FD
FD19   18                       CLC
FD1A   86 C3      LFD1A         STX $C3
FD1C   84 C4                    STY $C4
FD1E   A0 1F                    LDY #$1F
FD20   B9 14 03   LFD20         LDA $0314,Y
FD23   B0 02                    BCS LFD27
FD25   B1 C3                    LDA ($C3),Y
FD27   91 C3      LFD27         STA ($C3),Y
FD29   99 14 03                 STA $0314,Y
FD2C   88                       DEY
FD2D   10 F1                    BPL LFD20
FD2F   60                       RTS
FD30   31 EA                    AND ($EA),Y
FD32   66 FE                    ROR $FE
FD34   47                       ???               ;%01000111 'G'
FD35   FE 4A F3                 INC $F34A,X
FD38   91 F2                    STA ($F2),Y
FD3A   0E F2 50                 ASL $50F2
FD3D   F2                       ???               ;%11110010
FD3E   33                       ???               ;%00110011 '3'
FD3F   F3                       ???               ;%11110011
FD40   57                       ???               ;%01010111 'W'
FD41   F1 CA                    SBC ($CA),Y
FD43   F1 ED                    SBC ($ED),Y
FD45   F6 3E                    INC $3E,X
FD47   F1 2F                    SBC ($2F),Y
FD49   F3                       ???               ;%11110011
FD4A   66 FE                    ROR $FE
FD4C   A5 F4                    LDA $F4
FD4E   ED F5 A9                 SBC $A9F5
FD51   00                       BRK
FD52   A8                       TAY
FD53   99 02 00   LFD53         STA $0002,Y
FD56   99 00 02                 STA $0200,Y
FD59   99 00 03                 STA $0300,Y
FD5C   C8                       INY
FD5D   D0 F4                    BNE LFD53
FD5F   A2 3C                    LDX #$3C
FD61   A0 03                    LDY #$03
FD63   86 B2                    STX $B2
FD65   84 B3                    STY $B3
FD67   A8                       TAY
FD68   A9 03                    LDA #$03
FD6A   85 C2                    STA $C2
FD6C   E6 C2      LFD6C         INC $C2
FD6E   B1 C1      LFD6E         LDA ($C1),Y
FD70   AA                       TAX
FD71   A9 55                    LDA #$55
FD73   91 C1                    STA ($C1),Y
FD75   D1 C1                    CMP ($C1),Y
FD77   D0 0F                    BNE LFD88
FD79   2A                       ROL A
FD7A   91 C1                    STA ($C1),Y
FD7C   D1 C1                    CMP ($C1),Y
FD7E   D0 08                    BNE LFD88
FD80   8A                       TXA
FD81   91 C1                    STA ($C1),Y
FD83   C8                       INY
FD84   D0 E8                    BNE LFD6E
FD86   F0 E4                    BEQ LFD6C
FD88   98         LFD88         TYA
FD89   AA                       TAX
FD8A   A4 C2                    LDY $C2
FD8C   18                       CLC
FD8D   20 2D FE                 JSR LFE2D
FD90   A9 08                    LDA #$08
FD92   8D 82 02                 STA $0282
FD95   A9 04                    LDA #$04
FD97   8D 88 02                 STA $0288
FD9A   60                       RTS
FD9B   6A                       ROR A
FD9C   FC                       ???               ;%11111100
FD9D   CD FB 31                 CMP $31FB
FDA0   EA                       NOP
FDA1   2C F9 A9                 BIT $A9F9
FDA4   7F                       ???               ;%01111111
FDA5   8D 0D DC                 STA $DC0D
FDA8   8D 0D DD                 STA $DD0D
FDAB   8D 00 DC                 STA $DC00
FDAE   A9 08                    LDA #$08
FDB0   8D 0E DC                 STA $DC0E
FDB3   8D 0E DD                 STA $DD0E
FDB6   8D 0F DC                 STA $DC0F
FDB9   8D 0F DD                 STA $DD0F
FDBC   A2 00                    LDX #$00
FDBE   8E 03 DC                 STX $DC03
FDC1   8E 03 DD                 STX $DD03
FDC4   8E 18 D4                 STX $D418
FDC7   CA                       DEX
FDC8   8E 02 DC                 STX $DC02
FDCB   A9 07                    LDA #$07
FDCD   8D 00 DD                 STA $DD00
FDD0   A9 3F                    LDA #$3F
FDD2   8D 02 DD                 STA $DD02
FDD5   A9 E7                    LDA #$E7
FDD7   85 01                    STA $01
FDD9   A9 2F                    LDA #$2F
FDDB   85 00                    STA $00
FDDD   AD A6 02   LFDDD         LDA $02A6
FDE0   F0 0A                    BEQ LFDEC
FDE2   A9 25                    LDA #$25
FDE4   8D 04 DC                 STA $DC04
FDE7   A9 40                    LDA #$40
FDE9   4C F3 FD                 JMP LFDF3
FDEC   A9 95      LFDEC         LDA #$95
FDEE   8D 04 DC                 STA $DC04
FDF1   A9 42                    LDA #$42
FDF3   8D 05 DC   LFDF3         STA $DC05
FDF6   4C 6E FF                 JMP LFF6E
FDF9   85 B7      LFDF9         STA $B7
FDFB   86 BB                    STX $BB
FDFD   84 BC                    STY $BC
FDFF   60                       RTS
FE00   85 B8      LFE00         STA $B8
FE02   86 BA                    STX $BA
FE04   84 B9                    STY $B9
FE06   60                       RTS
FE07   A5 BA      LFE07         LDA $BA
FE09   C9 02                    CMP #$02
FE0B   D0 0D                    BNE LFE1A
FE0D   AD 97 02                 LDA $0297
FE10   48                       PHA
FE11   A9 00                    LDA #$00
FE13   8D 97 02                 STA $0297
FE16   68                       PLA
FE17   60                       RTS
FE18   85 9D      LFE18         STA $9D
FE1A   A5 90      LFE1A         LDA $90
FE1C   05 90      LFE1C         ORA $90
FE1E   85 90                    STA $90
FE20   60                       RTS
FE21   8D 85 02   LFE21         STA $0285
FE24   60                       RTS
FE25   90 06      LFE25         BCC LFE2D
FE27   AE 83 02   LFE27         LDX $0283
FE2A   AC 84 02                 LDY $0284
FE2D   8E 83 02   LFE2D         STX $0283
FE30   8C 84 02                 STY $0284
FE33   60                       RTS
FE34   90 06      LFE34         BCC LFE3C
FE36   AE 81 02                 LDX $0281
FE39   AC 82 02                 LDY $0282
FE3C   8E 81 02   LFE3C         STX $0281
FE3F   8C 82 02                 STY $0282
FE42   60                       RTS
FE43   78                       SEI
FE44   6C 18 03                 JMP ($0318)
FE47   48                       PHA
FE48   8A                       TXA
FE49   48                       PHA
FE4A   98                       TYA
FE4B   48                       PHA
FE4C   A9 7F                    LDA #$7F
FE4E   8D 0D DD                 STA $DD0D
FE51   AC 0D DD                 LDY $DD0D
FE54   30 1C                    BMI LFE72
FE56   20 02 FD                 JSR LFD02
FE59   D0 03                    BNE LFE5E
FE5B   6C 02 80                 JMP ($8002)
FE5E   20 BC F6   LFE5E         JSR LF6BC
FE61   20 E1 FF                 JSR LFFE1
FE64   D0 0C                    BNE LFE72
FE66   20 15 FD                 JSR LFD15
FE69   20 A3 FD                 JSR LFDA3
FE6C   20 18 E5                 JSR LE518
FE6F   6C 02 A0                 JMP ($A002)
FE72   98         LFE72         TYA
FE73   2D A1 02                 AND $02A1
FE76   AA                       TAX
FE77   29 01                    AND #$01
FE79   F0 28                    BEQ LFEA3
FE7B   AD 00 DD                 LDA $DD00
FE7E   29 FB                    AND #$FB
FE80   05 B5                    ORA $B5
FE82   8D 00 DD                 STA $DD00
FE85   AD A1 02                 LDA $02A1
FE88   8D 0D DD                 STA $DD0D
FE8B   8A                       TXA
FE8C   29 12                    AND #$12
FE8E   F0 0D                    BEQ LFE9D
FE90   29 02                    AND #$02
FE92   F0 06                    BEQ LFE9A
FE94   20 D6 FE                 JSR LFED6
FE97   4C 9D FE                 JMP LFE9D
FE9A   20 07 FF   LFE9A         JSR LFF07
FE9D   20 BB EE   LFE9D         JSR LEEBB
FEA0   4C B6 FE                 JMP LFEB6
FEA3   8A         LFEA3         TXA
FEA4   29 02                    AND #$02
FEA6   F0 06                    BEQ LFEAE
FEA8   20 D6 FE                 JSR LFED6
FEAB   4C B6 FE                 JMP LFEB6
FEAE   8A         LFEAE         TXA
FEAF   29 10                    AND #$10
FEB1   F0 03                    BEQ LFEB6
FEB3   20 07 FF                 JSR LFF07
FEB6   AD A1 02   LFEB6         LDA $02A1
FEB9   8D 0D DD                 STA $DD0D
FEBC   68         LFEBC         PLA
FEBD   A8                       TAY
FEBE   68                       PLA
FEBF   AA                       TAX
FEC0   68                       PLA
FEC1   40                       RTI
FEC2   C1 27                    CMP ($27,X)
FEC4   3E 1A C5                 ROL $C51A,X
FEC7   11 74                    ORA ($74),Y
FEC9   0E ED 0C                 ASL $0CED
FECC   45 06                    EOR $06
FECE   F0 02                    BEQ LFED2
FED0   46 01                    LSR $01
FED2   B8         LFED2         CLV
FED3   00                       BRK
FED4   71 00                    ADC ($00),Y
FED6   AD 01 DD   LFED6         LDA $DD01
FED9   29 01                    AND #$01
FEDB   85 A7                    STA $A7
FEDD   AD 06 DD                 LDA $DD06
FEE0   E9 1C                    SBC #$1C
FEE2   6D 99 02                 ADC $0299
FEE5   8D 06 DD                 STA $DD06
FEE8   AD 07 DD                 LDA $DD07
FEEB   6D 9A 02                 ADC $029A
FEEE   8D 07 DD                 STA $DD07
FEF1   A9 11                    LDA #$11
FEF3   8D 0F DD                 STA $DD0F
FEF6   AD A1 02                 LDA $02A1
FEF9   8D 0D DD                 STA $DD0D
FEFC   A9 FF                    LDA #$FF
FEFE   8D 06 DD                 STA $DD06
FF01   8D 07 DD                 STA $DD07
FF04   4C 59 EF                 JMP LEF59
FF07   AD 95 02   LFF07         LDA $0295
FF0A   8D 06 DD                 STA $DD06
FF0D   AD 96 02                 LDA $0296
FF10   8D 07 DD                 STA $DD07
FF13   A9 11                    LDA #$11
FF15   8D 0F DD                 STA $DD0F
FF18   A9 12                    LDA #$12
FF1A   4D A1 02                 EOR $02A1
FF1D   8D A1 02                 STA $02A1
FF20   A9 FF                    LDA #$FF
FF22   8D 06 DD                 STA $DD06
FF25   8D 07 DD                 STA $DD07
FF28   AE 98 02                 LDX $0298
FF2B   86 A8                    STX $A8
FF2D   60                       RTS
FF2E   AA         LFF2E         TAX
FF2F   AD 96 02                 LDA $0296
FF32   2A                       ROL A
FF33   A8                       TAY
FF34   8A                       TXA
FF35   69 C8                    ADC #$C8
FF37   8D 99 02                 STA $0299
FF3A   98                       TYA
FF3B   69 00                    ADC #$00
FF3D   8D 9A 02                 STA $029A
FF40   60                       RTS
FF41   EA                       NOP
FF42   EA                       NOP
FF43   08         LFF43         PHP
FF44   68                       PLA
FF45   29 EF                    AND #$EF
FF47   48                       PHA
FF48   48                       PHA
FF49   8A                       TXA
FF4A   48                       PHA
FF4B   98                       TYA
FF4C   48                       PHA
FF4D   BA                       TSX
FF4E   BD 04 01                 LDA $0104,X
FF51   29 10                    AND #$10
FF53   F0 03                    BEQ LFF58
FF55   6C 16 03                 JMP ($0316)
FF58   6C 14 03   LFF58         JMP ($0314)
FF5B   20 18 E5   LFF5B         JSR LE518
FF5E   AD 12 D0   LFF5E         LDA $D012
FF61   D0 FB                    BNE LFF5E
FF63   AD 19 D0                 LDA $D019
FF66   29 01                    AND #$01
FF68   8D A6 02                 STA $02A6
FF6B   4C DD FD                 JMP LFDDD
FF6E   A9 81      LFF6E         LDA #$81
FF70   8D 0D DC                 STA $DC0D
FF73   AD 0E DC                 LDA $DC0E
FF76   29 80                    AND #$80
FF78   09 11                    ORA #$11
FF7A   8D 0E DC                 STA $DC0E
FF7D   4C 8E EE                 JMP LEE8E
FF80   03                       ???               ;%00000011
FF81   4C 5B FF                 JMP LFF5B
FF84   4C A3 FD                 JMP LFDA3
FF87   4C 50 FD                 JMP LFD50
FF8A   4C 15 FD                 JMP LFD15
FF8D   4C 1A FD                 JMP LFD1A
FF90   4C 18 FE                 JMP LFE18
FF93   4C B9 ED                 JMP LEDB9
FF96   4C C7 ED                 JMP LEDC7
FF99   4C 25 FE   LFF99         JMP LFE25
FF9C   4C 34 FE   LFF9C         JMP LFE34
FF9F   4C 87 EA                 JMP LEA87
FFA2   4C 21 FE                 JMP LFE21
FFA5   4C 13 EE                 JMP LEE13
FFA8   4C DD ED                 JMP LEDDD
FFAB   4C EF ED                 JMP LEDEF
FFAE   4C FE ED                 JMP LEDFE
FFB1   4C 0C ED                 JMP LED0C
FFB4   4C 09 ED                 JMP LED09
FFB7   4C 07 FE   LFFB7         JMP LFE07
FFBA   4C 00 FE   LFFBA         JMP LFE00
FFBD   4C F9 FD   LFFBD         JMP LFDF9
FFC0   6C 1A 03   LFFC0         JMP ($031A)
FFC3   6C 1C 03   LFFC3         JMP ($031C)
FFC6   6C 1E 03   LFFC6         JMP ($031E)
FFC9   6C 20 03   LFFC9         JMP ($0320)
FFCC   6C 22 03   LFFCC         JMP ($0322)
FFCF   6C 24 03   LFFCF         JMP ($0324)
FFD2   6C 26 03   LFFD2         JMP ($0326)
FFD5   4C 9E F4   LFFD5         JMP LF49E
FFD8   4C DD F5   LFFD8         JMP LF5DD
FFDB   4C E4 F6                 JMP LF6E4
FFDE   4C DD F6                 JMP LF6DD
FFE1   6C 28 03   LFFE1         JMP ($0328)
FFE4   6C 2A 03   LFFE4         JMP ($032A)
FFE7   6C 2C 03                 JMP ($032C)
FFEA   4C 9B F6   LFFEA         JMP LF69B
FFED   4C 05 E5                 JMP LE505
FFF0   4C 0A E5                 JMP LE50A
FFF3   4C 00 E5   LFFF3         JMP LE500
FFF6   52                       ???               ;%01010010 'R'
FFF7   52                       ???               ;%01010010 'R'
FFF8   42                       ???               ;%01000010 'B'
FFF9   59 43 FE                 EOR $FE43,Y
FFFC   E2                       ???               ;%11100010
FFFD   FC                       ???               ;%11111100
FFFE   48                       PHA
FFFF   FF                       ???               ;%11111111
                                .END

;auto-generated symbols and labels
 LE00E        $E00E
 LE00B        $E00B
 LE01E        $E01E
 LE059        $E059
 LE05D        $E05D
 LE06C        $E06C
 LE07D        $E07D
 LE070        $E070
 LE0D3        $E0D3
 LE0BE        $E0BE
 LFFF3        $FFF3
 LE0E3        $E0E3
 LE104        $E104
 LE109        $E109
 LFFD2        $FFD2
 LE0F9        $E0F9
 LFFCF        $FFCF
 LE4AD        $E4AD
 LFFC6        $FFC6
 LFFE4        $FFE4
 LE1D4        $E1D4
 LFFD8        $FFD8
 LFFD5        $FFD5
 LE1D1        $E1D1
 LE195        $E195
 LFFB7        $FFB7
 LE19E        $E19E
 LE194        $E194
 LE1A1        $E1A1
 LE1B5        $E1B5
 LE219        $E219
 LFFC0        $FFC0
 LFFC3        $FFC3
 LFFBD        $FFBD
 LFFBA        $FFBA
 LE206        $E206
 LE257        $E257
 LE200        $E200
 LE20E        $E20E
 LE20D        $E20D
 LE211        $E211
 LE23F        $E23F
 LE29D        $E29D
 LE2A0        $E2A0
 LE2AD        $E2AD
 LE043        $E043
 LE26B        $E26B
 LE0F6        $E0F6
 LE2DC        $E2DC
 LE316        $E316
 LE324        $E324
 LE337        $E337
 LE33D        $E33D
 LE35E        $E35E
 LE3A9        $E3A9
 LFFCC        $FFCC
 LE391        $E391
 LE453        $E453
 LE3BF        $E3BF
 LE422        $E422
 LE386        $E386
 LE3A8        $E3A8
 LE3B9        $E3B9
 LE3A2        $E3A2
 LE3E2        $E3E2
 LFF9C        $FF9C
 LFF99        $FF99
 LE421        $E421
 LE455        $E455
 LFFC9        $FFC9
 LE4B6        $E4B6
 LE4EB        $E4EB
 LE4E2        $E4E2
 LE513        $E513
 LE56C        $E56C
 LE5A0        $E5A0
 LE555        $E555
 LE54D        $E54D
 LE9FF        $E9FF
 LE560        $E560
 LE57C        $E57C
 LE570        $E570
 LE9F0        $E9F0
 LE58C        $E58C
 LE582        $E582
 LEA24        $EA24
 LE598        $E598
 LE6ED        $E6ED
 LE566        $E566
 LE5AA        $E5AA
 LE5B9        $E5B9
 LE716        $E716
 LE5CD        $E5CD
 LE5E7        $E5E7
 LEA13        $EA13
 LE5B4        $E5B4
 LE5FE        $E5FE
 LE5F3        $E5F3
 LE5CA        $E5CA
 LE60F        $E60F
 LE606        $E606
 LE63A        $E63A
 LE591        $E591
 LE65D        $E65D
 LE64A        $E64A
 LE650        $E650
 LE654        $E654
 LE684        $E684
 LE674        $E674
 LE66F        $E66F
 LE672        $E672
 LE682        $E682
 LE690        $E690
 LE699        $E699
 LE69F        $E69F
 LE6B6        $E6B6
 LE6B0        $E6B0
 LE8B3        $E8B3
 LE700        $E700
 LE6F7        $E6F7
 LE6CD        $E6CD
 LE967        $E967
 LE6DA        $E6DA
 LE8EA        $E8EA
 LE6F4        $E6F4
 LE87C        $E87C
 LE70B        $E70B
 LE6A8        $E6A8
 LE72A        $E72A
 LE7D4        $E7D4
 LE731        $E731
 LE891        $E891
 LE745        $E745
 LE73D        $E73D
 LE73F        $E73F
 LE693        $E693
 LE74C        $E74C
 LE697        $E697
 LE77E        $E77E
 LE759        $E759
 LE701        $E701
 LE773        $E773
 LE8A1        $E8A1
 LE762        $E762
 LE7CB        $E7CB
 LE785        $E785
 LE78B        $E78B
 LE792        $E792
 LE7AD        $E7AD
 LE7AA        $E7AA
 LE7CE        $E7CE
 LE7A8        $E7A8
 LE7C8        $E7C8
 LE7C0        $E7C0
 LE8CB        $E8CB
 LEC44        $EC44
 LE7DC        $E7DC
 LE7E3        $E7E3
 LE691        $E691
 LE7EA        $E7EA
 LE82D        $E82D
 LE829        $E829
 LE7FE        $E7FE
 LE805        $E805
 LE826        $E826
 LE965        $E965
 LE80A        $E80A
 LE832        $E832
 LE84C        $E84C
 LE871        $E871
 LE847        $E847
 LE854        $E854
 LE86A        $E86A
 LE864        $E864
 LE874        $E874
 LE544        $E544
 LEC4F        $EC4F
 LE888        $E888
 LE880        $E880
 LE8B0        $E8B0
 LE8A5        $E8A5
 LE8C2        $E8C2
 LE8B7        $E8B7
 LE8CA        $E8CA
 LE8D6        $E8D6
 LE8CD        $E8CD
 LE8E1        $E8E1
 LE913        $E913
 LE9C8        $E9C8
 LE8FF        $E8FF
 LE922        $E922
 LE918        $E918
 LE8F6        $E8F6
 LE956        $E956
 LE94D        $E94D
 LE981        $E981
 LE9A6        $E9A6
 LE98F        $E98F
 LE9BF        $E9BF
 LE9BA        $E9BA
 LE9AB        $E9AB
 LE958        $E958
 LE9E0        $E9E0
 LE9D4        $E9D4
 LE4DA        $E4DA
 LEA07        $EA07
 LFFEA        $FFEA
 LEA61        $EA61
 LEA5C        $EA5C
 LEA1C        $EA1C
 LEA71        $EA71
 LEA79        $EA79
 LEA7B        $EA7B
 LEA87        $EA87
 LEAFB        $EAFB
 LEAAB        $EAAB
 LEACC        $EACC
 LEAC9        $EAC9
 LEACB        $EACB
 LEADC        $EADC
 LEAB3        $EAB3
 LEAA8        $EAA8
 LEAF0        $EAF0
 LEB26        $EB26
 LEB0D        $EB0D
 LEB42        $EB42
 LEB17        $EB17
 LEB64        $EB64
 LEB76        $EB76
 LEB6B        $EB6B
 LEAE0        $EAE0
 LEBF3        $EBF3
 LEBB4        $EBB4
 LEBA6        $EBA6
 LEC58        $EC58
 LEC5E        $EC5E
 LEC69        $EC69
 LEC72        $EC72
 LEC5B        $EC5B
 LED6C        $ED6C
 LED10        $ED10
 LECB4        $ECB4
 LED58        $ED58
 LECFC        $ECFC
 LF0A4        $F0A4
 LED20        $ED20
 LED40        $ED40
 LEE97        $EE97
 LED2E        $ED2E
 LEE85        $EE85
 LEE8E        $EE8E
 LEEB3        $EEB3
 LEEA9        $EEA9
 LEDAD        $EDAD
 LED5A        $ED5A
 LED50        $ED50
 LED55        $ED55
 LED66        $ED66
 LEDB0        $EDB0
 LED7A        $ED7A
 LEEA0        $EEA0
 LED7D        $ED7D
 LED9F        $ED9F
 LFE1C        $FE1C
 LEE03        $EE03
 LED36        $ED36
 LEDBE        $EDBE
 LEDD6        $EDD6
 LEDE6        $EDE6
 LEDEB        $EDEB
 LED11        $ED11
 LEE09        $EE09
 LEE1B        $EE1B
 LEE3E        $EE3E
 LEE30        $EE30
 LEE56        $EE56
 LEE47        $EE47
 LEDB2        $EDB2
 LEE20        $EE20
 LEE5A        $EE5A
 LEE67        $EE67
 LEE80        $EE80
 LEE06        $EE06
 LEEB6        $EEB6
 LEF06        $EF06
 LEF00        $EF00
 LEEC8        $EEC8
 LEED7        $EED7
 LEEF2        $EEF2
 LEEFC        $EEFC
 LEEF6        $EEF6
 LEEE7        $EEE7
 LEED1        $EED1
 LEEE6        $EEE6
 LEF13        $EF13
 LEF2E        $EF2E
 LEF31        $EF31
 LEF39        $EF39
 LEF54        $EF54
 LEF58        $EF58
 LEF90        $EF90
 LEF97        $EF97
 LEF70        $EF70
 LEFDB        $EFDB
 LEF6D        $EF6D
 LEF3B        $EF3B
 LEF7E        $EF7E
 LE4D3        $E4D3
 LEFCA        $EFCA
 LEFB1        $EFB1
 LEFA9        $EFA9
 LEF6E        $EF6E
 LEFC5        $EFC5
 LEFD0        $EFD0
 LEFCD        $EFCD
 LF012        $F012
 LF00D        $F00D
 LEFF2        $EFF2
 LEFF9        $EFF9
 LF006        $F006
 LF028        $F028
 LF014        $F014
 LF04C        $F04C
 LF07D        $F07D
 LF084        $F084
 LF062        $F062
 LF070        $F070
 LF077        $F077
 LF09C        $F09C
 LF0BB        $F0BB
 LF0AA        $F0AA
 LF12D        $F12D
 LF0B0        $F0B0
 LF13F        $F13F
 LF148        $F148
 LF0CB        $F0CB
 LF13C        $F13C
 LF12F        $F12F
 LF14A        $F14A
 LF155        $F155
 LF166        $F166
 LF086        $F086
 LE632        $E632
 LF173        $F173
 LF1AD        $F1AD
 LF1B8        $F1B8
 LF199        $F199
 LF196        $F196
 LF193        $F193
 LF18D        $F18D
 LF80D        $F80D
 LF1A9        $F1A9
 LF841        $F841
 LF1B4        $F1B4
 LF1B5        $F1B5
 LEE13        $EE13
 LF14E        $F14E
 LF1B3        $F1B3
 LF1B1        $F1B1
 LF1D5        $F1D5
 LF1DB        $F1DB
 LEDDD        $EDDD
 LF208        $F208
 LF1F8        $F1F8
 LF864        $F864
 LF1FD        $F1FD
 LF207        $F207
 LF017        $F017
 LF1FC        $F1FC
 LF30F        $F30F
 LF216        $F216
 LF701        $F701
 LF31F        $F31F
 LF233        $F233
 LF237        $F237
 LF22A        $F22A
 LF04D        $F04D
 LF70A        $F70A
 LED09        $ED09
 LF245        $F245
 LEDCC        $EDCC
 LF248        $F248
 LEDC7        $EDC7
 LF707        $F707
 LF258        $F258
 LF262        $F262
 LF70D        $F70D
 LF275        $F275
 LF279        $F279
 LF26F        $F26F
 LEFE1        $EFE1
 LF25F        $F25F
 LED0C        $ED0C
 LF286        $F286
 LF289        $F289
 LEDB9        $EDB9
 LF314        $F314
 LF298        $F298
 LF2F1        $F2F1
 LF2EE        $F2EE
 LF2C8        $F2C8
 LF2F2        $F2F2
 LF483        $F483
 LFE27        $FE27
 LF2BA        $F2BA
 LF2BF        $F2BF
 LF47D        $F47D
 LF7D0        $F7D0
 LF1DD        $F1DD
 LF2E0        $F2E0
 LF76A        $F76A
 LF642        $F642
 LF30D        $F30D
 LF32E        $F32E
 LF316        $F316
 LF33C        $F33C
 LEDFE        $EDFE
 LF343        $F343
 LEDEF        $EDEF
 LF351        $F351
 LF359        $F359
 LF6FE        $F6FE
 LF362        $F362
 LF6FB        $F6FB
 LF3D3        $F3D3
 LF384        $F384
 LF3D5        $F3D5
 LF38B        $F38B
 LF409        $F409
 LF393        $F393
 LF713        $F713
 LF3B8        $F3B8
 LF817        $F817
 LF3D4        $F3D4
 LF5AF        $F5AF
 LF3AF        $F3AF
 LF7EA        $F7EA
 LF3C2        $F3C2
 LF704        $F704
 LF72C        $F72C
 LF3AC        $F3AC
 LF838        $F838
 LF3D1        $F3D1
 LF3F6        $F3F6
 LF406        $F406
 LF3FC        $F3FC
 LF654        $F654
 LF41D        $F41D
 LF40F        $F40F
 LEF4A        $EF4A
 LF446        $F446
 LF43A        $F43A
 LF440        $F440
 LFF2E        $FF2E
 LF45C        $F45C
 LF474        $F474
 LFE2D        $FE2D
 LF4B2        $F4B2
 LF4AF        $F4AF
 LF533        $F533
 LF4BF        $F4BF
 LF710        $F710
 LF530        $F530
 LF4F0        $F4F0
 LF5D2        $F5D2
 LFFE1        $FFE1
 LF501        $F501
 LF633        $F633
 LF4F3        $F4F3
 LF51C        $F51C
 LF51E        $F51E
 LF524        $F524
 LF5A9        $F5A9
 LF539        $F539
 LF541        $F541
 LF5AE        $F5AE
 LF556        $F556
 LF55D        $F55D
 LF579        $F579
 LF549        $F549
 LF57D        $F57D
 LF56C        $F56C
 LF84A        $F84A
 LF5D1        $F5D1
 LF5C7        $F5C7
 LF5DA        $F5DA
 LF12B        $F12B
 LF5F4        $F5F4
 LF5F1        $F5F1
 LF659        $F659
 LF605        $F605
 LF68F        $F68F
 LFB8E        $FB8E
 LFCD1        $FCD1
 LF63F        $F63F
 LF63A        $F63A
 LFCDB        $FCDB
 LF624        $F624
 LF657        $F657
 LF65F        $F65F
 LF68E        $F68E
 LF676        $F676
 LF867        $F867
 LF68D        $F68D
 LF5C1        $F5C1
 LF6A7        $F6A7
 LF6BC        $F6BC
 LF6DA        $F6DA
 LF6CC        $F6CC
 LF6DC        $F6DC
 LF6FA        $F6FA
 LF729        $F729
 LF769        $F769
 LF74B        $F74B
 LF767        $F767
 LF757        $F757
 LE4E0        $E4E0
 LF7CF        $F7CF
 LF781        $F781
 LF7B7        $F7B7
 LF7A5        $F7A5
 LF7D7        $F7D7
 LF86B        $F86B
 LF80C        $F80C
 LF80B        $F80B
 LF7F7        $F7F7
 LF82E        $F82E
 LF836        $F836
 LF8D0        $F8D0
 LF821        $F821
 LF81E        $F81E
 LF86E        $F86E
 LF875        $F875
 LF8DC        $F8DC
 LFCBD        $FCBD
 LFB97        $FB97
 LF8B7        $F8B7
 LF8B5        $F8B5
 LF8BE        $F8BE
 LF8E1        $F8E1
 LFC93        $FC93
 LF8F7        $F8F7
 LF8FE        $F8FE
 LF92A        $F92A
 LFF43        $FF43
 LF92C        $F92C
 LF9AC        $F9AC
 LF969        $F969
 LFA60        $FA60
 LF988        $F988
 LF993        $F993
 LF997        $F997
 LF98B        $F98B
 LFA10        $FA10
 LF999        $F999
 LF9D5        $F9D5
 LF9D2        $F9D2
 LF9BC        $F9BC
 LF9F7        $F9F7
 LF8E2        $F8E2
 LFEBC        $FEBC
 LF9E0        $F9E0
 LF9DE        $F9DE
 LF9C9        $F9C9
 LFA18        $FA18
 LFA1F        $FA1F
 LFA44        $FA44
 LFA5D        $FA5D
 LFA53        $FA53
 LFA70        $FA70
 LFA8D        $FA8D
 LFA86        $FA86
 LFA8A        $FA8A
 LFAC0        $FAC0
 LFAA9        $FAA9
 LFAA3        $FAA3
 LFABA        $FABA
 LFACE        $FACE
 LFB4A        $FB4A
 LFAD6        $FAD6
 LFB48        $FB48
 LFB08        $FB08
 LFAEB        $FAEB
 LFB3A        $FB3A
 LFB33        $FB33
 LFB43        $FB43
 LFB2F        $FB2F
 LFB8B        $FB8B
 LFB5C        $FB5C
 LFB68        $FB68
 LFB72        $FB72
 LFBAF        $FBAF
 LFC09        $FC09
 LFBE3        $FBE3
 LFBB1        $FBB1
 LFC57        $FC57
 LFBF0        $FBF0
 LFBAD        $FBAD
 LFBA6        $FBA6
 LFC0C        $FC0C
 LFC4E        $FC4E
 LFC30        $FC30
 LFC2C        $FC2C
 LFC3F        $FC3F
 LFBC8        $FBC8
 LFC5E        $FC5E
 LFCCA        $FCCA
 LFC54        $FC54
 LFCB8        $FCB8
 LFC16        $FC16
 LFDDD        $FDDD
 LFCB6        $FCB6
 LFCE1        $FCE1
 LFD02        $FD02
 LFCEF        $FCEF
 LFDA3        $FDA3
 LFD50        $FD50
 LFD15        $FD15
 LFF5B        $FF5B
 LFD0F        $FD0F
 LFD04        $FD04
 LFD27        $FD27
 LFD20        $FD20
 LFD53        $FD53
 LFD88        $FD88
 LFD6E        $FD6E
 LFD6C        $FD6C
 LFDEC        $FDEC
 LFDF3        $FDF3
 LFF6E        $FF6E
 LFE1A        $FE1A
 LFE3C        $FE3C
 LFE72        $FE72
 LFE5E        $FE5E
 LE518        $E518
 LFEA3        $FEA3
 LFE9D        $FE9D
 LFE9A        $FE9A
 LFED6        $FED6
 LFF07        $FF07
 LEEBB        $EEBB
 LFEB6        $FEB6
 LFEAE        $FEAE
 LFED2        $FED2
 LEF59        $EF59
 LFF58        $FF58
 LFF5E        $FF5E
 LFD1A        $FD1A
 LFE18        $FE18
 LFE25        $FE25
 LFE34        $FE34
 LFE21        $FE21
 LFE07        $FE07
 LFE00        $FE00
 LFDF9        $FDF9
 LF49E        $F49E
 LF5DD        $F5DD
 LF6E4        $F6E4
 LF6DD        $F6DD
 LF69B        $F69B
 LE505        $E505
 LE50A        $E50A
 LE500        $E500
