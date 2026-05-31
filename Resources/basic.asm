                                * = $A000
A000   94 E3                    STY $E3,X
A002   7B                       ???               ;%01111011 '{'
A003   E3                       ???               ;%11100011
A004   43                       ???               ;%01000011 'C'
A005   42                       ???               ;%01000010 'B'
A006   4D 42 41                 EOR $4142
A009   53                       ???               ;%01010011 'S'
A00A   49 43                    EOR #$43
A00C   30 A8                    BMI $9FB6
A00E   41 A7                    EOR ($A7,X)
A010   1D AD F7                 ORA $F7AD,X
A013   A8                       TAY
A014   A4 AB                    LDY $AB
A016   BE AB 80                 LDX $80AB,Y
A019   B0 05                    BCS LA020
A01B   AC A4 A9                 LDY $A9A4
A01E   9F                       ???               ;%10011111
A01F   A8                       TAY
A020   70 A8      LA020         BVS $9FCA
A022   27                       ???               ;%00100111 '''
A023   A9 1C                    LDA #$1C
A025   A8                       TAY
A026   82                       ???               ;%10000010
A027   A8                       TAY
A028   D1 A8                    CMP ($A8),Y
A02A   3A                       ???               ;%00111010 ':'
A02B   A9 2E                    LDA #$2E
A02D   A8                       TAY
A02E   4A                       LSR A
A02F   A9 2C                    LDA #$2C
A031   B8                       CLV
A032   67                       ???               ;%01100111 'g'
A033   E1 55                    SBC ($55,X)
A035   E1 64                    SBC ($64,X)
A037   E1 B2                    SBC ($B2,X)
A039   B3                       ???               ;%10110011
A03A   23                       ???               ;%00100011 '#'
A03B   B8                       CLV
A03C   7F                       ???               ;%01111111
A03D   AA                       TAX
A03E   9F                       ???               ;%10011111
A03F   AA                       TAX
A040   56 A8                    LSR $A8,X
A042   9B                       ???               ;%10011011
A043   A6 5D                    LDX $5D
A045   A6 85                    LDX $85
A047   AA                       TAX
A048   29 E1                    AND #$E1
A04A   BD E1 C6                 LDA $C6E1,X
A04D   E1 7A                    SBC ($7A,X)
A04F   AB                       ???               ;%10101011
A050   41 A6                    EOR ($A6,X)
A052   39 BC CC                 AND $CCBC,Y
A055   BC 58 BC                 LDY $BC58,X
A058   10 03                    BPL LA05D
A05A   7D B3 9E                 ADC $9EB3,X
A05D   B3         LA05D         ???               ;%10110011
A05E   71 BF                    ADC ($BF),Y
A060   97                       ???               ;%10010111
A061   E0 EA                    CPX #$EA
A063   B9 ED BF                 LDA LBFED,Y
A066   64                       ???               ;%01100100 'd'
A067   E2                       ???               ;%11100010
A068   6B                       ???               ;%01101011 'k'
A069   E2                       ???               ;%11100010
A06A   B4 E2                    LDY $E2,X
A06C   0E E3 0D                 ASL $0DE3
A06F   B8                       CLV
A070   7C                       ???               ;%01111100 '|'
A071   B7                       ???               ;%10110111
A072   65 B4                    ADC $B4
A074   AD B7 8B                 LDA $8BB7
A077   B7                       ???               ;%10110111
A078   EC B6 00                 CPX $00B6
A07B   B7                       ???               ;%10110111
A07C   2C B7 37                 BIT $37B7
A07F   B7                       ???               ;%10110111
A080   79 69 B8                 ADC $B869,Y
A083   79 52 B8                 ADC $B852,Y
A086   7B                       ???               ;%01111011 '{'
A087   2A                       ROL A
A088   BA                       TSX
A089   7B                       ???               ;%01111011 '{'
A08A   11 BB                    ORA ($BB),Y
A08C   7F                       ???               ;%01111111
A08D   7A                       ???               ;%01111010 'z'
A08E   BF                       ???               ;%10111111
A08F   50 E8                    BVC LA079
A091   AF                       ???               ;%10101111
A092   46 E5                    LSR $E5
A094   AF                       ???               ;%10101111
A095   7D B3 BF                 ADC $BFB3,X
A098   5A                       ???               ;%01011010 'Z'
A099   D3                       ???               ;%11010011
A09A   AE 64 15                 LDX $1564
A09D   B0 45                    BCS LA0E4
A09F   4E C4 46                 LSR $46C4
A0A2   4F                       ???               ;%01001111 'O'
A0A3   D2                       ???               ;%11010010
A0A4   4E 45 58                 LSR $5845
A0A7   D4                       ???               ;%11010100
A0A8   44                       ???               ;%01000100 'D'
A0A9   41 54                    EOR ($54,X)
A0AB   C1 49                    CMP ($49,X)
A0AD   4E 50 55                 LSR $5550
A0B0   54                       ???               ;%01010100 'T'
A0B1   A3                       ???               ;%10100011
A0B2   49 4E                    EOR #$4E
A0B4   50 55                    BVC LA10B
A0B6   D4                       ???               ;%11010100
A0B7   44                       ???               ;%01000100 'D'
A0B8   49 CD                    EOR #$CD
A0BA   52                       ???               ;%01010010 'R'
A0BB   45 41                    EOR $41
A0BD   C4 4C                    CPY $4C
A0BF   45 D4                    EOR $D4
A0C1   47                       ???               ;%01000111 'G'
A0C2   4F                       ???               ;%01001111 'O'
A0C3   54                       ???               ;%01010100 'T'
A0C4   CF                       ???               ;%11001111
A0C5   52                       ???               ;%01010010 'R'
A0C6   55 CE                    EOR $CE,X
A0C8   49 C6                    EOR #$C6
A0CA   52                       ???               ;%01010010 'R'
A0CB   45 53                    EOR $53
A0CD   54                       ???               ;%01010100 'T'
A0CE   4F                       ???               ;%01001111 'O'
A0CF   52                       ???               ;%01010010 'R'
A0D0   C5 47                    CMP $47
A0D2   4F                       ???               ;%01001111 'O'
A0D3   53                       ???               ;%01010011 'S'
A0D4   55 C2                    EOR $C2,X
A0D6   52                       ???               ;%01010010 'R'
A0D7   45 54                    EOR $54
A0D9   55 52                    EOR $52,X
A0DB   CE 52 45                 DEC $4552
A0DE   CD 53 54                 CMP $5453
A0E1   4F                       ???               ;%01001111 'O'
A0E2   D0 4F                    BNE LA133
A0E4   CE 57 41   LA0E4         DEC $4157
A0E7   49 D4                    EOR #$D4
A0E9   4C 4F 41                 JMP $414F
A0EC   C4 53                    CPY $53
A0EE   41 56                    EOR ($56,X)
A0F0   C5 56                    CMP $56
A0F2   45 52                    EOR $52
A0F4   49 46                    EOR #$46
A0F6   D9 44 45                 CMP $4544,Y
A0F9   C6 50                    DEC $50
A0FB   4F                       ???               ;%01001111 'O'
A0FC   4B                       ???               ;%01001011 'K'
A0FD   C5 50                    CMP $50
A0FF   52                       ???               ;%01010010 'R'
A100   49 4E                    EOR #$4E
A102   54                       ???               ;%01010100 'T'
A103   A3                       ???               ;%10100011
A104   50 52                    BVC LA158
A106   49 4E                    EOR #$4E
A108   D4                       ???               ;%11010100
A109   43                       ???               ;%01000011 'C'
A10A   4F                       ???               ;%01001111 'O'
A10B   4E D4 4C   LA10B         LSR $4CD4
A10E   49 53                    EOR #$53
A110   D4                       ???               ;%11010100
A111   43                       ???               ;%01000011 'C'
A112   4C D2 43                 JMP $43D2
A115   4D C4 53                 EOR $53C4
A118   59 D3 4F                 EOR $4FD3,Y
A11B   50 45                    BVC LA162
A11D   CE 43 4C                 DEC $4C43
A120   4F                       ???               ;%01001111 'O'
A121   53                       ???               ;%01010011 'S'
A122   C5 47                    CMP $47
A124   45 D4                    EOR $D4
A126   4E 45 D7                 LSR $D745
A129   54                       ???               ;%01010100 'T'
A12A   41 42                    EOR ($42,X)
A12C   A8                       TAY
A12D   54                       ???               ;%01010100 'T'
A12E   CF                       ???               ;%11001111
A12F   46 CE                    LSR $CE
A131   53                       ???               ;%01010011 'S'
A132   50 43                    BVC LA177
A134   A8                       TAY
A135   54                       ???               ;%01010100 'T'
A136   48                       PHA
A137   45 CE                    EOR $CE
A139   4E 4F D4                 LSR $D44F
A13C   53                       ???               ;%01010011 'S'
A13D   54                       ???               ;%01010100 'T'
A13E   45 D0                    EOR $D0
A140   AB                       ???               ;%10101011
A141   AD AA AF                 LDA $AFAA
A144   DE 41 4E                 DEC $4E41,X
A147   C4 4F                    CPY $4F
A149   D2                       ???               ;%11010010
A14A   BE BD BC                 LDX $BCBD,Y
A14D   53                       ???               ;%01010011 'S'
A14E   47                       ???               ;%01000111 'G'
A14F   CE 49 4E                 DEC $4E49
A152   D4                       ???               ;%11010100
A153   41 42                    EOR ($42,X)
A155   D3                       ???               ;%11010011
A156   55 53                    EOR $53,X
A158   D2         LA158         ???               ;%11010010
A159   46 52                    LSR $52
A15B   C5 50                    CMP $50
A15D   4F                       ???               ;%01001111 'O'
A15E   D3                       ???               ;%11010011
A15F   53                       ???               ;%01010011 'S'
A160   51 D2                    EOR ($D2),Y
A162   52         LA162         ???               ;%01010010 'R'
A163   4E C4 4C                 LSR $4CC4
A166   4F                       ???               ;%01001111 'O'
A167   C7                       ???               ;%11000111
A168   45 58                    EOR $58
A16A   D0 43                    BNE LA1AF
A16C   4F                       ???               ;%01001111 'O'
A16D   D3                       ???               ;%11010011
A16E   53                       ???               ;%01010011 'S'
A16F   49 CE                    EOR #$CE
A171   54                       ???               ;%01010100 'T'
A172   41 CE                    EOR ($CE,X)
A174   41 54                    EOR ($54,X)
A176   CE 50 45                 DEC $4550
A179   45 CB                    EOR $CB
A17B   4C 45 CE                 JMP $CE45
A17E   53                       ???               ;%01010011 'S'
A17F   54                       ???               ;%01010100 'T'
A180   52                       ???               ;%01010010 'R'
A181   A4 56                    LDY $56
A183   41 CC                    EOR ($CC,X)
A185   41 53                    EOR ($53,X)
A187   C3                       ???               ;%11000011
A188   43                       ???               ;%01000011 'C'
A189   48                       PHA
A18A   52                       ???               ;%01010010 'R'
A18B   A4 4C                    LDY $4C
A18D   45 46                    EOR $46
A18F   54                       ???               ;%01010100 'T'
A190   A4 52                    LDY $52
A192   49 47                    EOR #$47
A194   48                       PHA
A195   54                       ???               ;%01010100 'T'
A196   A4 4D                    LDY $4D
A198   49 44                    EOR #$44
A19A   A4 47                    LDY $47
A19C   CF                       ???               ;%11001111
A19D   00                       BRK
A19E   54                       ???               ;%01010100 'T'
A19F   4F                       ???               ;%01001111 'O'
A1A0   4F                       ???               ;%01001111 'O'
A1A1   20 4D 41                 JSR $414D
A1A4   4E 59 20                 LSR $2059
A1A7   46 49                    LSR $49
A1A9   4C 45 D3                 JMP $D345
A1AC   46 49                    LSR $49
A1AE   4C 45 20                 JMP $2045
A1B1   4F                       ???               ;%01001111 'O'
A1B2   50 45                    BVC LA1F9
A1B4   CE 46 49                 DEC $4946
A1B7   4C 45 20                 JMP $2045
A1BA   4E 4F 54                 LSR $544F
A1BD   20 4F 50                 JSR $504F
A1C0   45 CE                    EOR $CE
A1C2   46 49                    LSR $49
A1C4   4C 45 20                 JMP $2045
A1C7   4E 4F 54                 LSR $544F
A1CA   20 46 4F                 JSR $4F46
A1CD   55 4E                    EOR $4E,X
A1CF   C4 44                    CPY $44
A1D1   45 56                    EOR $56
A1D3   49 43                    EOR #$43
A1D5   45 20                    EOR $20
A1D7   4E 4F 54                 LSR $544F
A1DA   20 50 52                 JSR $5250
A1DD   45 53                    EOR $53
A1DF   45 4E                    EOR $4E
A1E1   D4                       ???               ;%11010100
A1E2   4E 4F 54                 LSR $544F
A1E5   20 49 4E                 JSR $4E49
A1E8   50 55                    BVC LA23F
A1EA   54                       ???               ;%01010100 'T'
A1EB   20 46 49                 JSR $4946
A1EE   4C C5 4E                 JMP $4EC5
A1F1   4F                       ???               ;%01001111 'O'
A1F2   54                       ???               ;%01010100 'T'
A1F3   20 4F 55                 JSR $554F
A1F6   54                       ???               ;%01010100 'T'
A1F7   50 55                    BVC LA24E
A1F9   54         LA1F9         ???               ;%01010100 'T'
A1FA   20 46 49                 JSR $4946
A1FD   4C C5 4D                 JMP $4DC5
A200   49 53                    EOR #$53
A202   53                       ???               ;%01010011 'S'
A203   49 4E                    EOR #$4E
A205   47                       ???               ;%01000111 'G'
A206   20 46 49                 JSR $4946
A209   4C 45 20                 JMP $2045
A20C   4E 41 4D                 LSR $4D41
A20F   C5 49                    CMP $49
A211   4C 4C 45                 JMP $454C
A214   47                       ???               ;%01000111 'G'
A215   41 4C                    EOR ($4C,X)
A217   20 44 45                 JSR $4544
A21A   56 49                    LSR $49,X
A21C   43                       ???               ;%01000011 'C'
A21D   45 20                    EOR $20
A21F   4E 55 4D                 LSR $4D55
A222   42                       ???               ;%01000010 'B'
A223   45 D2                    EOR $D2
A225   4E 45 58                 LSR $5845
A228   54                       ???               ;%01010100 'T'
A229   20 57 49                 JSR $4957
A22C   54                       ???               ;%01010100 'T'
A22D   48                       PHA
A22E   4F                       ???               ;%01001111 'O'
A22F   55 54                    EOR $54,X
A231   20 46 4F                 JSR $4F46
A234   D2                       ???               ;%11010010
A235   53                       ???               ;%01010011 'S'
A236   59 4E 54                 EOR $544E,Y
A239   41 D8                    EOR ($D8,X)
A23B   52                       ???               ;%01010010 'R'
A23C   45 54                    EOR $54
A23E   55 52                    EOR $52,X
A240   4E 20 57                 LSR $5720
A243   49 54                    EOR #$54
A245   48                       PHA
A246   4F                       ???               ;%01001111 'O'
A247   55 54                    EOR $54,X
A249   20 47 4F                 JSR $4F47
A24C   53                       ???               ;%01010011 'S'
A24D   55 C2                    EOR $C2,X
A24F   4F                       ???               ;%01001111 'O'
A250   55 54                    EOR $54,X
A252   20 4F 46                 JSR $464F
A255   20 44 41                 JSR $4144
A258   54                       ???               ;%01010100 'T'
A259   C1 49                    CMP ($49,X)
A25B   4C 4C 45                 JMP $454C
A25E   47                       ???               ;%01000111 'G'
A25F   41 4C                    EOR ($4C,X)
A261   20 51 55                 JSR $5551
A264   41 4E                    EOR ($4E,X)
A266   54                       ???               ;%01010100 'T'
A267   49 54                    EOR #$54
A269   D9 4F 56                 CMP $564F,Y
A26C   45 52                    EOR $52
A26E   46 4C                    LSR $4C
A270   4F                       ???               ;%01001111 'O'
A271   D7                       ???               ;%11010111
A272   4F                       ???               ;%01001111 'O'
A273   55 54                    EOR $54,X
A275   20 4F 46                 JSR $464F
A278   20 4D 45                 JSR $454D
A27B   4D 4F 52                 EOR $524F
A27E   D9 55 4E                 CMP $4E55,Y
A281   44                       ???               ;%01000100 'D'
A282   45 46                    EOR $46
A284   27                       ???               ;%00100111 '''
A285   44                       ???               ;%01000100 'D'
A286   20 53 54                 JSR $5453
A289   41 54                    EOR ($54,X)
A28B   45 4D                    EOR $4D
A28D   45 4E                    EOR $4E
A28F   D4                       ???               ;%11010100
A290   42                       ???               ;%01000010 'B'
A291   41 44                    EOR ($44,X)
A293   20 53 55                 JSR $5553
A296   42                       ???               ;%01000010 'B'
A297   53                       ???               ;%01010011 'S'
A298   43                       ???               ;%01000011 'C'
A299   52                       ???               ;%01010010 'R'
A29A   49 50                    EOR #$50
A29C   D4                       ???               ;%11010100
A29D   52                       ???               ;%01010010 'R'
A29E   45 44                    EOR $44
A2A0   49 4D                    EOR #$4D
A2A2   27                       ???               ;%00100111 '''
A2A3   44                       ???               ;%01000100 'D'
A2A4   20 41 52                 JSR $5241
A2A7   52                       ???               ;%01010010 'R'
A2A8   41 D9                    EOR ($D9,X)
A2AA   44                       ???               ;%01000100 'D'
A2AB   49 56                    EOR #$56
A2AD   49 53                    EOR #$53
A2AF   49 4F                    EOR #$4F
A2B1   4E 20 42                 LSR $4220
A2B4   59 20 5A                 EOR $5A20,Y
A2B7   45 52                    EOR $52
A2B9   CF                       ???               ;%11001111
A2BA   49 4C                    EOR #$4C
A2BC   4C 45 47                 JMP $4745
A2BF   41 4C                    EOR ($4C,X)
A2C1   20 44 49                 JSR $4944
A2C4   52                       ???               ;%01010010 'R'
A2C5   45 43                    EOR $43
A2C7   D4                       ???               ;%11010100
A2C8   54                       ???               ;%01010100 'T'
A2C9   59 50 45                 EOR $4550,Y
A2CC   20 4D 49                 JSR $494D
A2CF   53                       ???               ;%01010011 'S'
A2D0   4D 41 54                 EOR $5441
A2D3   43                       ???               ;%01000011 'C'
A2D4   C8                       INY
A2D5   53                       ???               ;%01010011 'S'
A2D6   54                       ???               ;%01010100 'T'
A2D7   52                       ???               ;%01010010 'R'
A2D8   49 4E                    EOR #$4E
A2DA   47                       ???               ;%01000111 'G'
A2DB   20 54 4F                 JSR $4F54
A2DE   4F                       ???               ;%01001111 'O'
A2DF   20 4C 4F                 JSR $4F4C
A2E2   4E C7 46                 LSR $46C7
A2E5   49 4C                    EOR #$4C
A2E7   45 20                    EOR $20
A2E9   44                       ???               ;%01000100 'D'
A2EA   41 54                    EOR ($54,X)
A2EC   C1 46                    CMP ($46,X)
A2EE   4F                       ???               ;%01001111 'O'
A2EF   52                       ???               ;%01010010 'R'
A2F0   4D 55 4C                 EOR $4C55
A2F3   41 20                    EOR ($20,X)
A2F5   54                       ???               ;%01010100 'T'
A2F6   4F                       ???               ;%01001111 'O'
A2F7   4F                       ???               ;%01001111 'O'
A2F8   20 43 4F                 JSR $4F43
A2FB   4D 50 4C                 EOR $4C50
A2FE   45 D8                    EOR $D8
A300   43                       ???               ;%01000011 'C'
A301   41 4E                    EOR ($4E,X)
A303   27                       ???               ;%00100111 '''
A304   54                       ???               ;%01010100 'T'
A305   20 43 4F                 JSR $4F43
A308   4E 54 49                 LSR $4954
A30B   4E 55 C5                 LSR $C555
A30E   55 4E                    EOR $4E,X
A310   44                       ???               ;%01000100 'D'
A311   45 46                    EOR $46
A313   27                       ???               ;%00100111 '''
A314   44                       ???               ;%01000100 'D'
A315   20 46 55                 JSR $5546
A318   4E 43 54                 LSR $5443
A31B   49 4F                    EOR #$4F
A31D   CE 56 45                 DEC $4556
A320   52                       ???               ;%01010010 'R'
A321   49 46                    EOR #$46
A323   D9 4C 4F                 CMP $4F4C,Y
A326   41 C4                    EOR ($C4,X)
A328   9E                       ???               ;%10011110
A329   A1 AC                    LDA ($AC,X)
A32B   A1 B5                    LDA ($B5,X)
A32D   A1 C2                    LDA ($C2,X)
A32F   A1 D0                    LDA ($D0,X)
A331   A1 E2                    LDA ($E2,X)
A333   A1 F0                    LDA ($F0,X)
A335   A1 FF                    LDA ($FF,X)
A337   A1 10                    LDA ($10,X)
A339   A2 25                    LDX #$25
A33B   A2 35                    LDX #$35
A33D   A2 3B                    LDX #$3B
A33F   A2 4F                    LDX #$4F
A341   A2 5A                    LDX #$5A
A343   A2 6A                    LDX #$6A
A345   A2 72                    LDX #$72
A347   A2 7F                    LDX #$7F
A349   A2 90                    LDX #$90
A34B   A2 9D                    LDX #$9D
A34D   A2 AA                    LDX #$AA
A34F   A2 BA                    LDX #$BA
A351   A2 C8                    LDX #$C8
A353   A2 D5                    LDX #$D5
A355   A2 E4                    LDX #$E4
A357   A2 ED                    LDX #$ED
A359   A2 00                    LDX #$00
A35B   A3                       ???               ;%10100011
A35C   0E A3 1E                 ASL $1EA3
A35F   A3                       ???               ;%10100011
A360   24 A3                    BIT $A3
A362   83                       ???               ;%10000011
A363   A3                       ???               ;%10100011
A364   0D 4F 4B                 ORA $4B4F
A367   0D 00 20                 ORA $2000
A36A   20 45 52                 JSR $5245
A36D   52                       ???               ;%01010010 'R'
A36E   4F                       ???               ;%01001111 'O'
A36F   52                       ???               ;%01010010 'R'
A370   00                       BRK
A371   20 49 4E                 JSR $4E49
A374   20 00 0D                 JSR $0D00
A377   0A                       ASL A
A378   52                       ???               ;%01010010 'R'
A379   45 41                    EOR $41
A37B   44                       ???               ;%01000100 'D'
A37C   59 2E 0D                 EOR $0D2E,Y
A37F   0A                       ASL A
A380   00                       BRK
A381   0D 0A 42                 ORA $420A
A384   52                       ???               ;%01010010 'R'
A385   45 41                    EOR $41
A387   4B                       ???               ;%01001011 'K'
A388   00                       BRK
A389   A0 BA                    LDY #$BA
A38B   E8                       INX
A38C   E8                       INX
A38D   E8                       INX
A38E   E8                       INX
A38F   BD 01 01   LA38F         LDA $0101,X
A392   C9 81                    CMP #$81
A394   D0 21                    BNE LA3B7
A396   A5 4A                    LDA $4A
A398   D0 0A                    BNE LA3A4
A39A   BD 02 01                 LDA $0102,X
A39D   85 49                    STA $49
A39F   BD 03 01                 LDA $0103,X
A3A2   85 4A                    STA $4A
A3A4   DD 03 01   LA3A4         CMP $0103,X
A3A7   D0 07                    BNE LA3B0
A3A9   A5 49                    LDA $49
A3AB   DD 02 01                 CMP $0102,X
A3AE   F0 07                    BEQ LA3B7
A3B0   8A         LA3B0         TXA
A3B1   18                       CLC
A3B2   69 12                    ADC #$12
A3B4   AA                       TAX
A3B5   D0 D8                    BNE LA38F
A3B7   60         LA3B7         RTS
A3B8   20 08 A4   LA3B8         JSR LA408
A3BB   85 31                    STA $31
A3BD   84 32                    STY $32
A3BF   38         LA3BF         SEC
A3C0   A5 5A                    LDA $5A
A3C2   E5 5F                    SBC $5F
A3C4   85 22                    STA $22
A3C6   A8                       TAY
A3C7   A5 5B                    LDA $5B
A3C9   E5 60                    SBC $60
A3CB   AA                       TAX
A3CC   E8                       INX
A3CD   98                       TYA
A3CE   F0 23                    BEQ LA3F3
A3D0   A5 5A                    LDA $5A
A3D2   38                       SEC
A3D3   E5 22                    SBC $22
A3D5   85 5A                    STA $5A
A3D7   B0 03                    BCS LA3DC
A3D9   C6 5B                    DEC $5B
A3DB   38                       SEC
A3DC   A5 58      LA3DC         LDA $58
A3DE   E5 22                    SBC $22
A3E0   85 58                    STA $58
A3E2   B0 08                    BCS LA3EC
A3E4   C6 59                    DEC $59
A3E6   90 04                    BCC LA3EC
A3E8   B1 5A      LA3E8         LDA ($5A),Y
A3EA   91 58                    STA ($58),Y
A3EC   88         LA3EC         DEY
A3ED   D0 F9                    BNE LA3E8
A3EF   B1 5A                    LDA ($5A),Y
A3F1   91 58                    STA ($58),Y
A3F3   C6 5B      LA3F3         DEC $5B
A3F5   C6 59                    DEC $59
A3F7   CA                       DEX
A3F8   D0 F2                    BNE LA3EC
A3FA   60                       RTS
A3FB   0A         LA3FB         ASL A
A3FC   69 3E                    ADC #$3E
A3FE   B0 35                    BCS LA435
A400   85 22                    STA $22
A402   BA                       TSX
A403   E4 22                    CPX $22
A405   90 2E                    BCC LA435
A407   60                       RTS
A408   C4 34      LA408         CPY $34
A40A   90 28                    BCC LA434
A40C   D0 04                    BNE LA412
A40E   C5 33                    CMP $33
A410   90 22                    BCC LA434
A412   48         LA412         PHA
A413   A2 09                    LDX #$09
A415   98                       TYA
A416   48         LA416         PHA
A417   B5 57                    LDA $57,X
A419   CA                       DEX
A41A   10 FA                    BPL LA416
A41C   20 26 B5                 JSR LB526
A41F   A2 F7                    LDX #$F7
A421   68         LA421         PLA
A422   95 61                    STA $61,X
A424   E8                       INX
A425   30 FA                    BMI LA421
A427   68                       PLA
A428   A8                       TAY
A429   68                       PLA
A42A   C4 34                    CPY $34
A42C   90 06                    BCC LA434
A42E   D0 05                    BNE LA435
A430   C5 33                    CMP $33
A432   B0 01                    BCS LA435
A434   60         LA434         RTS
A435   A2 10      LA435         LDX #$10
A437   6C 00 03   LA437         JMP ($0300)
A43A   8A                       TXA
A43B   0A                       ASL A
A43C   AA                       TAX
A43D   BD 26 A3                 LDA $A326,X
A440   85 22                    STA $22
A442   BD 27 A3                 LDA $A327,X
A445   85 23                    STA $23
A447   20 CC FF                 JSR $FFCC
A44A   A9 00                    LDA #$00
A44C   85 13                    STA $13
A44E   20 D7 AA                 JSR LAAD7
A451   20 45 AB                 JSR LAB45
A454   A0 00                    LDY #$00
A456   B1 22      LA456         LDA ($22),Y
A458   48                       PHA
A459   29 7F                    AND #$7F
A45B   20 47 AB                 JSR LAB47
A45E   C8                       INY
A45F   68                       PLA
A460   10 F4                    BPL LA456
A462   20 7A A6                 JSR LA67A
A465   A9 69                    LDA #$69
A467   A0 A3                    LDY #$A3
A469   20 1E AB   LA469         JSR LAB1E
A46C   A4 3A                    LDY $3A
A46E   C8                       INY
A46F   F0 03                    BEQ LA474
A471   20 C2 BD                 JSR LBDC2
A474   A9 76      LA474         LDA #$76
A476   A0 A3                    LDY #$A3
A478   20 1E AB                 JSR LAB1E
A47B   A9 80                    LDA #$80
A47D   20 90 FF                 JSR $FF90
A480   6C 02 03   LA480         JMP ($0302)
A483   20 60 A5                 JSR LA560
A486   86 7A                    STX $7A
A488   84 7B                    STY $7B
A48A   20 73 00                 JSR $0073
A48D   AA                       TAX
A48E   F0 F0                    BEQ LA480
A490   A2 FF                    LDX #$FF
A492   86 3A                    STX $3A
A494   90 06                    BCC LA49C
A496   20 79 A5                 JSR LA579
A499   4C E1 A7                 JMP LA7E1
A49C   20 6B A9   LA49C         JSR LA96B
A49F   20 79 A5                 JSR LA579
A4A2   84 0B                    STY $0B
A4A4   20 13 A6                 JSR LA613
A4A7   90 44                    BCC LA4ED
A4A9   A0 01                    LDY #$01
A4AB   B1 5F                    LDA ($5F),Y
A4AD   85 23                    STA $23
A4AF   A5 2D                    LDA $2D
A4B1   85 22                    STA $22
A4B3   A5 60                    LDA $60
A4B5   85 25                    STA $25
A4B7   A5 5F                    LDA $5F
A4B9   88                       DEY
A4BA   F1 5F                    SBC ($5F),Y
A4BC   18                       CLC
A4BD   65 2D                    ADC $2D
A4BF   85 2D                    STA $2D
A4C1   85 24                    STA $24
A4C3   A5 2E                    LDA $2E
A4C5   69 FF                    ADC #$FF
A4C7   85 2E                    STA $2E
A4C9   E5 60                    SBC $60
A4CB   AA                       TAX
A4CC   38                       SEC
A4CD   A5 5F                    LDA $5F
A4CF   E5 2D                    SBC $2D
A4D1   A8                       TAY
A4D2   B0 03                    BCS LA4D7
A4D4   E8                       INX
A4D5   C6 25                    DEC $25
A4D7   18         LA4D7         CLC
A4D8   65 22                    ADC $22
A4DA   90 03                    BCC LA4DF
A4DC   C6 23                    DEC $23
A4DE   18                       CLC
A4DF   B1 22      LA4DF         LDA ($22),Y
A4E1   91 24                    STA ($24),Y
A4E3   C8                       INY
A4E4   D0 F9                    BNE LA4DF
A4E6   E6 23                    INC $23
A4E8   E6 25                    INC $25
A4EA   CA                       DEX
A4EB   D0 F2                    BNE LA4DF
A4ED   20 59 A6   LA4ED         JSR LA659
A4F0   20 33 A5                 JSR LA533
A4F3   AD 00 02                 LDA $0200
A4F6   F0 88                    BEQ LA480
A4F8   18                       CLC
A4F9   A5 2D                    LDA $2D
A4FB   85 5A                    STA $5A
A4FD   65 0B                    ADC $0B
A4FF   85 58                    STA $58
A501   A4 2E                    LDY $2E
A503   84 5B                    STY $5B
A505   90 01                    BCC LA508
A507   C8                       INY
A508   84 59      LA508         STY $59
A50A   20 B8 A3                 JSR LA3B8
A50D   A5 14                    LDA $14
A50F   A4 15                    LDY $15
A511   8D FE 01                 STA $01FE
A514   8C FF 01                 STY $01FF
A517   A5 31                    LDA $31
A519   A4 32                    LDY $32
A51B   85 2D                    STA $2D
A51D   84 2E                    STY $2E
A51F   A4 0B                    LDY $0B
A521   88                       DEY
A522   B9 FC 01   LA522         LDA $01FC,Y
A525   91 5F                    STA ($5F),Y
A527   88                       DEY
A528   10 F8                    BPL LA522
A52A   20 59 A6                 JSR LA659
A52D   20 33 A5                 JSR LA533
A530   4C 80 A4                 JMP LA480
A533   A5 2B      LA533         LDA $2B
A535   A4 2C                    LDY $2C
A537   85 22                    STA $22
A539   84 23                    STY $23
A53B   18                       CLC
A53C   A0 01      LA53C         LDY #$01
A53E   B1 22                    LDA ($22),Y
A540   F0 1D                    BEQ LA55F
A542   A0 04                    LDY #$04
A544   C8         LA544         INY
A545   B1 22                    LDA ($22),Y
A547   D0 FB                    BNE LA544
A549   C8                       INY
A54A   98                       TYA
A54B   65 22                    ADC $22
A54D   AA                       TAX
A54E   A0 00                    LDY #$00
A550   91 22                    STA ($22),Y
A552   A5 23                    LDA $23
A554   69 00                    ADC #$00
A556   C8                       INY
A557   91 22                    STA ($22),Y
A559   86 22                    STX $22
A55B   85 23                    STA $23
A55D   90 DD                    BCC LA53C
A55F   60         LA55F         RTS
A560   A2 00      LA560         LDX #$00
A562   20 12 E1   LA562         JSR $E112
A565   C9 0D                    CMP #$0D
A567   F0 0D                    BEQ LA576
A569   9D 00 02                 STA $0200,X
A56C   E8                       INX
A56D   E0 59                    CPX #$59
A56F   90 F1                    BCC LA562
A571   A2 17                    LDX #$17
A573   4C 37 A4                 JMP LA437
A576   4C CA AA   LA576         JMP LAACA
A579   6C 04 03   LA579         JMP ($0304)
A57C   A6 7A                    LDX $7A
A57E   A0 04                    LDY #$04
A580   84 0F                    STY $0F
A582   BD 00 02   LA582         LDA $0200,X
A585   10 07                    BPL LA58E
A587   C9 FF                    CMP #$FF
A589   F0 3E                    BEQ LA5C9
A58B   E8                       INX
A58C   D0 F4                    BNE LA582
A58E   C9 20      LA58E         CMP #$20
A590   F0 37                    BEQ LA5C9
A592   85 08                    STA $08
A594   C9 22                    CMP #$22
A596   F0 56                    BEQ LA5EE
A598   24 0F                    BIT $0F
A59A   70 2D                    BVS LA5C9
A59C   C9 3F                    CMP #$3F
A59E   D0 04                    BNE LA5A4
A5A0   A9 99                    LDA #$99
A5A2   D0 25                    BNE LA5C9
A5A4   C9 30      LA5A4         CMP #$30
A5A6   90 04                    BCC LA5AC
A5A8   C9 3C                    CMP #$3C
A5AA   90 1D                    BCC LA5C9
A5AC   84 71      LA5AC         STY $71
A5AE   A0 00                    LDY #$00
A5B0   84 0B                    STY $0B
A5B2   88                       DEY
A5B3   86 7A                    STX $7A
A5B5   CA                       DEX
A5B6   C8         LA5B6         INY
A5B7   E8                       INX
A5B8   BD 00 02   LA5B8         LDA $0200,X
A5BB   38                       SEC
A5BC   F9 9E A0                 SBC $A09E,Y
A5BF   F0 F5                    BEQ LA5B6
A5C1   C9 80                    CMP #$80
A5C3   D0 30                    BNE LA5F5
A5C5   05 0B                    ORA $0B
A5C7   A4 71      LA5C7         LDY $71
A5C9   E8         LA5C9         INX
A5CA   C8                       INY
A5CB   99 FB 01                 STA $01FB,Y
A5CE   B9 FB 01                 LDA $01FB,Y
A5D1   F0 36                    BEQ LA609
A5D3   38                       SEC
A5D4   E9 3A                    SBC #$3A
A5D6   F0 04                    BEQ LA5DC
A5D8   C9 49                    CMP #$49
A5DA   D0 02                    BNE LA5DE
A5DC   85 0F      LA5DC         STA $0F
A5DE   38         LA5DE         SEC
A5DF   E9 55                    SBC #$55
A5E1   D0 9F                    BNE LA582
A5E3   85 08                    STA $08
A5E5   BD 00 02   LA5E5         LDA $0200,X
A5E8   F0 DF                    BEQ LA5C9
A5EA   C5 08                    CMP $08
A5EC   F0 DB                    BEQ LA5C9
A5EE   C8         LA5EE         INY
A5EF   99 FB 01                 STA $01FB,Y
A5F2   E8                       INX
A5F3   D0 F0                    BNE LA5E5
A5F5   A6 7A      LA5F5         LDX $7A
A5F7   E6 0B                    INC $0B
A5F9   C8         LA5F9         INY
A5FA   B9 9D A0                 LDA $A09D,Y
A5FD   10 FA                    BPL LA5F9
A5FF   B9 9E A0                 LDA $A09E,Y
A602   D0 B4                    BNE LA5B8
A604   BD 00 02                 LDA $0200,X
A607   10 BE                    BPL LA5C7
A609   99 FD 01   LA609         STA $01FD,Y
A60C   C6 7B                    DEC $7B
A60E   A9 FF                    LDA #$FF
A610   85 7A                    STA $7A
A612   60                       RTS
A613   A5 2B      LA613         LDA $2B
A615   A6 2C                    LDX $2C
A617   A0 01      LA617         LDY #$01
A619   85 5F                    STA $5F
A61B   86 60                    STX $60
A61D   B1 5F                    LDA ($5F),Y
A61F   F0 1F                    BEQ LA640
A621   C8                       INY
A622   C8                       INY
A623   A5 15                    LDA $15
A625   D1 5F                    CMP ($5F),Y
A627   90 18                    BCC LA641
A629   F0 03                    BEQ LA62E
A62B   88                       DEY
A62C   D0 09                    BNE LA637
A62E   A5 14      LA62E         LDA $14
A630   88                       DEY
A631   D1 5F                    CMP ($5F),Y
A633   90 0C                    BCC LA641
A635   F0 0A                    BEQ LA641
A637   88         LA637         DEY
A638   B1 5F                    LDA ($5F),Y
A63A   AA                       TAX
A63B   88                       DEY
A63C   B1 5F                    LDA ($5F),Y
A63E   B0 D7                    BCS LA617
A640   18         LA640         CLC
A641   60         LA641         RTS
A642   D0 FD                    BNE LA641
A644   A9 00                    LDA #$00
A646   A8                       TAY
A647   91 2B                    STA ($2B),Y
A649   C8                       INY
A64A   91 2B                    STA ($2B),Y
A64C   A5 2B                    LDA $2B
A64E   18                       CLC
A64F   69 02                    ADC #$02
A651   85 2D                    STA $2D
A653   A5 2C                    LDA $2C
A655   69 00                    ADC #$00
A657   85 2E                    STA $2E
A659   20 8E A6   LA659         JSR LA68E
A65C   A9 00                    LDA #$00
A65E   D0 2D                    BNE LA68D
A660   20 E7 FF   LA660         JSR $FFE7
A663   A5 37                    LDA $37
A665   A4 38                    LDY $38
A667   85 33                    STA $33
A669   84 34                    STY $34
A66B   A5 2D                    LDA $2D
A66D   A4 2E                    LDY $2E
A66F   85 2F                    STA $2F
A671   84 30                    STY $30
A673   85 31                    STA $31
A675   84 32                    STY $32
A677   20 1D A8                 JSR LA81D
A67A   A2 19      LA67A         LDX #$19
A67C   86 16                    STX $16
A67E   68                       PLA
A67F   A8                       TAY
A680   68                       PLA
A681   A2 FA                    LDX #$FA
A683   9A                       TXS
A684   48                       PHA
A685   98                       TYA
A686   48                       PHA
A687   A9 00                    LDA #$00
A689   85 3E                    STA $3E
A68B   85 10                    STA $10
A68D   60         LA68D         RTS
A68E   18         LA68E         CLC
A68F   A5 2B                    LDA $2B
A691   69 FF                    ADC #$FF
A693   85 7A                    STA $7A
A695   A5 2C                    LDA $2C
A697   69 FF                    ADC #$FF
A699   85 7B                    STA $7B
A69B   60                       RTS
A69C   90 06                    BCC LA6A4
A69E   F0 04                    BEQ LA6A4
A6A0   C9 AB                    CMP #$AB
A6A2   D0 E9                    BNE LA68D
A6A4   20 6B A9   LA6A4         JSR LA96B
A6A7   20 13 A6                 JSR LA613
A6AA   20 79 00                 JSR $0079
A6AD   F0 0C                    BEQ LA6BB
A6AF   C9 AB                    CMP #$AB
A6B1   D0 8E                    BNE LA641
A6B3   20 73 00                 JSR $0073
A6B6   20 6B A9                 JSR LA96B
A6B9   D0 86                    BNE LA641
A6BB   68         LA6BB         PLA
A6BC   68                       PLA
A6BD   A5 14                    LDA $14
A6BF   05 15                    ORA $15
A6C1   D0 06                    BNE LA6C9
A6C3   A9 FF                    LDA #$FF
A6C5   85 14                    STA $14
A6C7   85 15                    STA $15
A6C9   A0 01      LA6C9         LDY #$01
A6CB   84 0F                    STY $0F
A6CD   B1 5F                    LDA ($5F),Y
A6CF   F0 43                    BEQ LA714
A6D1   20 2C A8                 JSR LA82C
A6D4   20 D7 AA                 JSR LAAD7
A6D7   C8                       INY
A6D8   B1 5F                    LDA ($5F),Y
A6DA   AA                       TAX
A6DB   C8                       INY
A6DC   B1 5F                    LDA ($5F),Y
A6DE   C5 15                    CMP $15
A6E0   D0 04                    BNE LA6E6
A6E2   E4 14                    CPX $14
A6E4   F0 02                    BEQ LA6E8
A6E6   B0 2C      LA6E6         BCS LA714
A6E8   84 49      LA6E8         STY $49
A6EA   20 CD BD                 JSR LBDCD
A6ED   A9 20                    LDA #$20
A6EF   A4 49      LA6EF         LDY $49
A6F1   29 7F                    AND #$7F
A6F3   20 47 AB   LA6F3         JSR LAB47
A6F6   C9 22                    CMP #$22
A6F8   D0 06                    BNE LA700
A6FA   A5 0F                    LDA $0F
A6FC   49 FF                    EOR #$FF
A6FE   85 0F                    STA $0F
A700   C8         LA700         INY
A701   F0 11                    BEQ LA714
A703   B1 5F                    LDA ($5F),Y
A705   D0 10                    BNE LA717
A707   A8                       TAY
A708   B1 5F                    LDA ($5F),Y
A70A   AA                       TAX
A70B   C8                       INY
A70C   B1 5F                    LDA ($5F),Y
A70E   86 5F                    STX $5F
A710   85 60                    STA $60
A712   D0 B5                    BNE LA6C9
A714   4C 86 E3   LA714         JMP $E386
A717   6C 06 03   LA717         JMP ($0306)
A71A   10 D7                    BPL LA6F3
A71C   C9 FF                    CMP #$FF
A71E   F0 D3                    BEQ LA6F3
A720   24 0F                    BIT $0F
A722   30 CF                    BMI LA6F3
A724   38                       SEC
A725   E9 7F                    SBC #$7F
A727   AA                       TAX
A728   84 49                    STY $49
A72A   A0 FF                    LDY #$FF
A72C   CA         LA72C         DEX
A72D   F0 08                    BEQ LA737
A72F   C8         LA72F         INY
A730   B9 9E A0                 LDA $A09E,Y
A733   10 FA                    BPL LA72F
A735   30 F5                    BMI LA72C
A737   C8         LA737         INY
A738   B9 9E A0                 LDA $A09E,Y
A73B   30 B2                    BMI LA6EF
A73D   20 47 AB                 JSR LAB47
A740   D0 F5                    BNE LA737
A742   A9 80                    LDA #$80
A744   85 10                    STA $10
A746   20 A5 A9                 JSR LA9A5
A749   20 8A A3                 JSR LA38A
A74C   D0 05                    BNE LA753
A74E   8A                       TXA
A74F   69 0F                    ADC #$0F
A751   AA                       TAX
A752   9A                       TXS
A753   68         LA753         PLA
A754   68                       PLA
A755   A9 09                    LDA #$09
A757   20 FB A3                 JSR LA3FB
A75A   20 06 A9                 JSR LA906
A75D   18                       CLC
A75E   98                       TYA
A75F   65 7A                    ADC $7A
A761   48                       PHA
A762   A5 7B                    LDA $7B
A764   69 00                    ADC #$00
A766   48                       PHA
A767   A5 3A                    LDA $3A
A769   48                       PHA
A76A   A5 39                    LDA $39
A76C   48                       PHA
A76D   A9 A4                    LDA #$A4
A76F   20 FF AE                 JSR LAEFF
A772   20 8D AD                 JSR LAD8D
A775   20 8A AD                 JSR LAD8A
A778   A5 66                    LDA $66
A77A   09 7F                    ORA #$7F
A77C   25 62                    AND $62
A77E   85 62                    STA $62
A780   A9 8B                    LDA #$8B
A782   A0 A7                    LDY #$A7
A784   85 22                    STA $22
A786   84 23                    STY $23
A788   4C 43 AE                 JMP LAE43
A78B   A9 BC                    LDA #$BC
A78D   A0 B9                    LDY #$B9
A78F   20 A2 BB                 JSR LBBA2
A792   20 79 00                 JSR $0079
A795   C9 A9                    CMP #$A9
A797   D0 06                    BNE LA79F
A799   20 73 00                 JSR $0073
A79C   20 8A AD                 JSR LAD8A
A79F   20 2B BC   LA79F         JSR LBC2B
A7A2   20 38 AE                 JSR LAE38
A7A5   A5 4A                    LDA $4A
A7A7   48                       PHA
A7A8   A5 49                    LDA $49
A7AA   48                       PHA
A7AB   A9 81                    LDA #$81
A7AD   48                       PHA
A7AE   20 2C A8   LA7AE         JSR LA82C
A7B1   A5 7A                    LDA $7A
A7B3   A4 7B                    LDY $7B
A7B5   C0 02                    CPY #$02
A7B7   EA                       NOP
A7B8   F0 04                    BEQ LA7BE
A7BA   85 3D                    STA $3D
A7BC   84 3E                    STY $3E
A7BE   A0 00      LA7BE         LDY #$00
A7C0   B1 7A                    LDA ($7A),Y
A7C2   D0 43                    BNE LA807
A7C4   A0 02                    LDY #$02
A7C6   B1 7A                    LDA ($7A),Y
A7C8   18                       CLC
A7C9   D0 03                    BNE LA7CE
A7CB   4C 4B A8                 JMP LA84B
A7CE   C8         LA7CE         INY
A7CF   B1 7A                    LDA ($7A),Y
A7D1   85 39                    STA $39
A7D3   C8                       INY
A7D4   B1 7A                    LDA ($7A),Y
A7D6   85 3A                    STA $3A
A7D8   98                       TYA
A7D9   65 7A                    ADC $7A
A7DB   85 7A                    STA $7A
A7DD   90 02                    BCC LA7E1
A7DF   E6 7B                    INC $7B
A7E1   6C 08 03   LA7E1         JMP ($0308)
A7E4   20 73 00                 JSR $0073
A7E7   20 ED A7                 JSR LA7ED
A7EA   4C AE A7                 JMP LA7AE
A7ED   F0 3C      LA7ED         BEQ LA82B
A7EF   E9 80      LA7EF         SBC #$80
A7F1   90 11                    BCC LA804
A7F3   C9 23                    CMP #$23
A7F5   B0 17                    BCS LA80E
A7F7   0A                       ASL A
A7F8   A8                       TAY
A7F9   B9 0D A0                 LDA $A00D,Y
A7FC   48                       PHA
A7FD   B9 0C A0                 LDA $A00C,Y
A800   48                       PHA
A801   4C 73 00                 JMP $0073
A804   4C A5 A9   LA804         JMP LA9A5
A807   C9 3A      LA807         CMP #$3A
A809   F0 D6                    BEQ LA7E1
A80B   4C 08 AF   LA80B         JMP LAF08
A80E   C9 4B      LA80E         CMP #$4B
A810   D0 F9                    BNE LA80B
A812   20 73 00                 JSR $0073
A815   A9 A4                    LDA #$A4
A817   20 FF AE                 JSR LAEFF
A81A   4C A0 A8                 JMP LA8A0
A81D   38         LA81D         SEC
A81E   A5 2B                    LDA $2B
A820   E9 01                    SBC #$01
A822   A4 2C                    LDY $2C
A824   B0 01                    BCS LA827
A826   88                       DEY
A827   85 41      LA827         STA $41
A829   84 42                    STY $42
A82B   60         LA82B         RTS
A82C   20 E1 FF   LA82C         JSR $FFE1
A82F   B0 01                    BCS LA832
A831   18                       CLC
A832   D0 3C      LA832         BNE LA870
A834   A5 7A                    LDA $7A
A836   A4 7B                    LDY $7B
A838   A6 3A                    LDX $3A
A83A   E8                       INX
A83B   F0 0C                    BEQ LA849
A83D   85 3D                    STA $3D
A83F   84 3E                    STY $3E
A841   A5 39                    LDA $39
A843   A4 3A                    LDY $3A
A845   85 3B                    STA $3B
A847   84 3C                    STY $3C
A849   68         LA849         PLA
A84A   68                       PLA
A84B   A9 81      LA84B         LDA #$81
A84D   A0 A3                    LDY #$A3
A84F   90 03                    BCC LA854
A851   4C 69 A4                 JMP LA469
A854   4C 86 E3   LA854         JMP $E386
A857   D0 17                    BNE LA870
A859   A2 1A                    LDX #$1A
A85B   A4 3E                    LDY $3E
A85D   D0 03                    BNE LA862
A85F   4C 37 A4                 JMP LA437
A862   A5 3D      LA862         LDA $3D
A864   85 7A                    STA $7A
A866   84 7B                    STY $7B
A868   A5 3B                    LDA $3B
A86A   A4 3C                    LDY $3C
A86C   85 39                    STA $39
A86E   84 3A                    STY $3A
A870   60         LA870         RTS
A871   08                       PHP
A872   A9 00                    LDA #$00
A874   20 90 FF                 JSR $FF90
A877   28                       PLP
A878   D0 03                    BNE LA87D
A87A   4C 59 A6                 JMP LA659
A87D   20 60 A6   LA87D         JSR LA660
A880   4C 97 A8                 JMP LA897
A883   A9 03                    LDA #$03
A885   20 FB A3                 JSR LA3FB
A888   A5 7B                    LDA $7B
A88A   48                       PHA
A88B   A5 7A                    LDA $7A
A88D   48                       PHA
A88E   A5 3A                    LDA $3A
A890   48                       PHA
A891   A5 39                    LDA $39
A893   48                       PHA
A894   A9 8D                    LDA #$8D
A896   48                       PHA
A897   20 79 00   LA897         JSR $0079
A89A   20 A0 A8                 JSR LA8A0
A89D   4C AE A7                 JMP LA7AE
A8A0   20 6B A9   LA8A0         JSR LA96B
A8A3   20 09 A9                 JSR LA909
A8A6   38                       SEC
A8A7   A5 39                    LDA $39
A8A9   E5 14                    SBC $14
A8AB   A5 3A                    LDA $3A
A8AD   E5 15                    SBC $15
A8AF   B0 0B                    BCS LA8BC
A8B1   98                       TYA
A8B2   38                       SEC
A8B3   65 7A                    ADC $7A
A8B5   A6 7B                    LDX $7B
A8B7   90 07                    BCC LA8C0
A8B9   E8                       INX
A8BA   B0 04                    BCS LA8C0
A8BC   A5 2B      LA8BC         LDA $2B
A8BE   A6 2C                    LDX $2C
A8C0   20 17 A6   LA8C0         JSR LA617
A8C3   90 1E                    BCC LA8E3
A8C5   A5 5F                    LDA $5F
A8C7   E9 01                    SBC #$01
A8C9   85 7A                    STA $7A
A8CB   A5 60                    LDA $60
A8CD   E9 00                    SBC #$00
A8CF   85 7B                    STA $7B
A8D1   60         LA8D1         RTS
A8D2   D0 FD                    BNE LA8D1
A8D4   A9 FF                    LDA #$FF
A8D6   85 4A                    STA $4A
A8D8   20 8A A3                 JSR LA38A
A8DB   9A                       TXS
A8DC   C9 8D                    CMP #$8D
A8DE   F0 0B                    BEQ LA8EB
A8E0   A2 0C                    LDX #$0C
A8E2   2C A2 11                 BIT $11A2
A8E5   4C 37 A4                 JMP LA437
A8E8   4C 08 AF   LA8E8         JMP LAF08
A8EB   68         LA8EB         PLA
A8EC   68                       PLA
A8ED   85 39                    STA $39
A8EF   68                       PLA
A8F0   85 3A                    STA $3A
A8F2   68                       PLA
A8F3   85 7A                    STA $7A
A8F5   68                       PLA
A8F6   85 7B                    STA $7B
A8F8   20 06 A9   LA8F8         JSR LA906
A8FB   98         LA8FB         TYA
A8FC   18                       CLC
A8FD   65 7A                    ADC $7A
A8FF   85 7A                    STA $7A
A901   90 02                    BCC LA905
A903   E6 7B                    INC $7B
A905   60         LA905         RTS
A906   A2 3A      LA906         LDX #$3A
A908   2C A2 00                 BIT $00A2
A90B   86 07                    STX $07
A90D   A0 00                    LDY #$00
A90F   84 08                    STY $08
A911   A5 08      LA911         LDA $08
A913   A6 07                    LDX $07
A915   85 07                    STA $07
A917   86 08                    STX $08
A919   B1 7A      LA919         LDA ($7A),Y
A91B   F0 E8                    BEQ LA905
A91D   C5 08                    CMP $08
A91F   F0 E4                    BEQ LA905
A921   C8                       INY
A922   C9 22                    CMP #$22
A924   D0 F3                    BNE LA919
A926   F0 E9                    BEQ LA911
A928   20 9E AD                 JSR LAD9E
A92B   20 79 00                 JSR $0079
A92E   C9 89                    CMP #$89
A930   F0 05                    BEQ LA937
A932   A9 A7                    LDA #$A7
A934   20 FF AE                 JSR LAEFF
A937   A5 61      LA937         LDA $61
A939   D0 05                    BNE LA940
A93B   20 09 A9                 JSR LA909
A93E   F0 BB                    BEQ LA8FB
A940   20 79 00   LA940         JSR $0079
A943   B0 03                    BCS LA948
A945   4C A0 A8                 JMP LA8A0
A948   4C ED A7   LA948         JMP LA7ED
A94B   20 9E B7                 JSR LB79E
A94E   48                       PHA
A94F   C9 8D                    CMP #$8D
A951   F0 04                    BEQ LA957
A953   C9 89      LA953         CMP #$89
A955   D0 91                    BNE LA8E8
A957   C6 65      LA957         DEC $65
A959   D0 04                    BNE LA95F
A95B   68                       PLA
A95C   4C EF A7                 JMP LA7EF
A95F   20 73 00   LA95F         JSR $0073
A962   20 6B A9                 JSR LA96B
A965   C9 2C                    CMP #$2C
A967   F0 EE                    BEQ LA957
A969   68                       PLA
A96A   60         LA96A         RTS
A96B   A2 00      LA96B         LDX #$00
A96D   86 14                    STX $14
A96F   86 15                    STX $15
A971   B0 F7      LA971         BCS LA96A
A973   E9 2F                    SBC #$2F
A975   85 07                    STA $07
A977   A5 15                    LDA $15
A979   85 22                    STA $22
A97B   C9 19                    CMP #$19
A97D   B0 D4                    BCS LA953
A97F   A5 14                    LDA $14
A981   0A                       ASL A
A982   26 22                    ROL $22
A984   0A                       ASL A
A985   26 22                    ROL $22
A987   65 14                    ADC $14
A989   85 14                    STA $14
A98B   A5 22                    LDA $22
A98D   65 15                    ADC $15
A98F   85 15                    STA $15
A991   06 14                    ASL $14
A993   26 15                    ROL $15
A995   A5 14                    LDA $14
A997   65 07                    ADC $07
A999   85 14                    STA $14
A99B   90 02                    BCC LA99F
A99D   E6 15                    INC $15
A99F   20 73 00   LA99F         JSR $0073
A9A2   4C 71 A9                 JMP LA971
A9A5   20 8B B0   LA9A5         JSR LB08B
A9A8   85 49                    STA $49
A9AA   84 4A                    STY $4A
A9AC   A9 B2                    LDA #$B2
A9AE   20 FF AE                 JSR LAEFF
A9B1   A5 0E                    LDA $0E
A9B3   48                       PHA
A9B4   A5 0D                    LDA $0D
A9B6   48                       PHA
A9B7   20 9E AD                 JSR LAD9E
A9BA   68                       PLA
A9BB   2A                       ROL A
A9BC   20 90 AD                 JSR LAD90
A9BF   D0 18                    BNE LA9D9
A9C1   68                       PLA
A9C2   10 12      LA9C2         BPL LA9D6
A9C4   20 1B BC                 JSR LBC1B
A9C7   20 BF B1                 JSR LB1BF
A9CA   A0 00                    LDY #$00
A9CC   A5 64                    LDA $64
A9CE   91 49                    STA ($49),Y
A9D0   C8                       INY
A9D1   A5 65                    LDA $65
A9D3   91 49                    STA ($49),Y
A9D5   60                       RTS
A9D6   4C D0 BB   LA9D6         JMP LBBD0
A9D9   68         LA9D9         PLA
A9DA   A4 4A      LA9DA         LDY $4A
A9DC   C0 BF                    CPY #$BF
A9DE   D0 4C                    BNE LAA2C
A9E0   20 A6 B6                 JSR LB6A6
A9E3   C9 06                    CMP #$06
A9E5   D0 3D                    BNE LAA24
A9E7   A0 00                    LDY #$00
A9E9   84 61                    STY $61
A9EB   84 66                    STY $66
A9ED   84 71      LA9ED         STY $71
A9EF   20 1D AA                 JSR LAA1D
A9F2   20 E2 BA                 JSR LBAE2
A9F5   E6 71                    INC $71
A9F7   A4 71                    LDY $71
A9F9   20 1D AA                 JSR LAA1D
A9FC   20 0C BC                 JSR LBC0C
A9FF   AA                       TAX
AA00   F0 05                    BEQ LAA07
AA02   E8                       INX
AA03   8A                       TXA
AA04   20 ED BA                 JSR LBAED
AA07   A4 71      LAA07         LDY $71
AA09   C8                       INY
AA0A   C0 06                    CPY #$06
AA0C   D0 DF                    BNE LA9ED
AA0E   20 E2 BA                 JSR LBAE2
AA11   20 9B BC                 JSR LBC9B
AA14   A6 64                    LDX $64
AA16   A4 63                    LDY $63
AA18   A5 65                    LDA $65
AA1A   4C DB FF                 JMP $FFDB
AA1D   B1 22      LAA1D         LDA ($22),Y
AA1F   20 80 00                 JSR $0080
AA22   90 03                    BCC LAA27
AA24   4C 48 B2   LAA24         JMP LB248
AA27   E9 2F      LAA27         SBC #$2F
AA29   4C 7E BD                 JMP LBD7E
AA2C   A0 02      LAA2C         LDY #$02
AA2E   B1 64                    LDA ($64),Y
AA30   C5 34                    CMP $34
AA32   90 17                    BCC LAA4B
AA34   D0 07                    BNE LAA3D
AA36   88                       DEY
AA37   B1 64                    LDA ($64),Y
AA39   C5 33                    CMP $33
AA3B   90 0E                    BCC LAA4B
AA3D   A4 65      LAA3D         LDY $65
AA3F   C4 2E                    CPY $2E
AA41   90 08                    BCC LAA4B
AA43   D0 0D                    BNE LAA52
AA45   A5 64                    LDA $64
AA47   C5 2D                    CMP $2D
AA49   B0 07                    BCS LAA52
AA4B   A5 64      LAA4B         LDA $64
AA4D   A4 65                    LDY $65
AA4F   4C 68 AA                 JMP LAA68
AA52   A0 00      LAA52         LDY #$00
AA54   B1 64                    LDA ($64),Y
AA56   20 75 B4                 JSR LB475
AA59   A5 50                    LDA $50
AA5B   A4 51                    LDY $51
AA5D   85 6F                    STA $6F
AA5F   84 70                    STY $70
AA61   20 7A B6                 JSR LB67A
AA64   A9 61                    LDA #$61
AA66   A0 00                    LDY #$00
AA68   85 50      LAA68         STA $50
AA6A   84 51                    STY $51
AA6C   20 DB B6                 JSR LB6DB
AA6F   A0 00                    LDY #$00
AA71   B1 50                    LDA ($50),Y
AA73   91 49                    STA ($49),Y
AA75   C8                       INY
AA76   B1 50                    LDA ($50),Y
AA78   91 49                    STA ($49),Y
AA7A   C8                       INY
AA7B   B1 50                    LDA ($50),Y
AA7D   91 49                    STA ($49),Y
AA7F   60                       RTS
AA80   20 86 AA                 JSR LAA86
AA83   4C B5 AB                 JMP LABB5
AA86   20 9E B7   LAA86         JSR LB79E
AA89   F0 05                    BEQ LAA90
AA8B   A9 2C                    LDA #$2C
AA8D   20 FF AE                 JSR LAEFF
AA90   08         LAA90         PHP
AA91   86 13                    STX $13
AA93   20 18 E1                 JSR $E118
AA96   28                       PLP
AA97   4C A0 AA                 JMP LAAA0
AA9A   20 21 AB   LAA9A         JSR LAB21
AA9D   20 79 00   LAA9D         JSR $0079
AAA0   F0 35      LAAA0         BEQ LAAD7
AAA2   F0 43      LAAA2         BEQ LAAE7
AAA4   C9 A3                    CMP #$A3
AAA6   F0 50                    BEQ LAAF8
AAA8   C9 A6                    CMP #$A6
AAAA   18                       CLC
AAAB   F0 4B                    BEQ LAAF8
AAAD   C9 2C                    CMP #$2C
AAAF   F0 37                    BEQ LAAE8
AAB1   C9 3B                    CMP #$3B
AAB3   F0 5E                    BEQ LAB13
AAB5   20 9E AD                 JSR LAD9E
AAB8   24 0D                    BIT $0D
AABA   30 DE                    BMI LAA9A
AABC   20 DD BD                 JSR LBDDD
AABF   20 87 B4                 JSR LB487
AAC2   20 21 AB                 JSR LAB21
AAC5   20 3B AB                 JSR LAB3B
AAC8   D0 D3                    BNE LAA9D
AACA   A9 00      LAACA         LDA #$00
AACC   9D 00 02                 STA $0200,X
AACF   A2 FF                    LDX #$FF
AAD1   A0 01                    LDY #$01
AAD3   A5 13                    LDA $13
AAD5   D0 10                    BNE LAAE7
AAD7   A9 0D      LAAD7         LDA #$0D
AAD9   20 47 AB                 JSR LAB47
AADC   24 13                    BIT $13
AADE   10 05                    BPL LAAE5
AAE0   A9 0A                    LDA #$0A
AAE2   20 47 AB                 JSR LAB47
AAE5   49 FF      LAAE5         EOR #$FF
AAE7   60         LAAE7         RTS
AAE8   38         LAAE8         SEC
AAE9   20 F0 FF                 JSR $FFF0
AAEC   98                       TYA
AAED   38                       SEC
AAEE   E9 0A      LAAEE         SBC #$0A
AAF0   B0 FC                    BCS LAAEE
AAF2   49 FF                    EOR #$FF
AAF4   69 01                    ADC #$01
AAF6   D0 16                    BNE LAB0E
AAF8   08         LAAF8         PHP
AAF9   38                       SEC
AAFA   20 F0 FF                 JSR $FFF0
AAFD   84 09                    STY $09
AAFF   20 9B B7                 JSR LB79B
AB02   C9 29                    CMP #$29
AB04   D0 59                    BNE LAB5F
AB06   28                       PLP
AB07   90 06                    BCC LAB0F
AB09   8A                       TXA
AB0A   E5 09                    SBC $09
AB0C   90 05                    BCC LAB13
AB0E   AA         LAB0E         TAX
AB0F   E8         LAB0F         INX
AB10   CA         LAB10         DEX
AB11   D0 06                    BNE LAB19
AB13   20 73 00   LAB13         JSR $0073
AB16   4C A2 AA                 JMP LAAA2
AB19   20 3B AB   LAB19         JSR LAB3B
AB1C   D0 F2                    BNE LAB10
AB1E   20 87 B4   LAB1E         JSR LB487
AB21   20 A6 B6   LAB21         JSR LB6A6
AB24   AA                       TAX
AB25   A0 00                    LDY #$00
AB27   E8                       INX
AB28   CA         LAB28         DEX
AB29   F0 BC                    BEQ LAAE7
AB2B   B1 22                    LDA ($22),Y
AB2D   20 47 AB                 JSR LAB47
AB30   C8                       INY
AB31   C9 0D                    CMP #$0D
AB33   D0 F3                    BNE LAB28
AB35   20 E5 AA                 JSR LAAE5
AB38   4C 28 AB                 JMP LAB28
AB3B   A5 13      LAB3B         LDA $13
AB3D   F0 03                    BEQ LAB42
AB3F   A9 20                    LDA #$20
AB41   2C A9 1D                 BIT $1DA9
AB44   2C A9 3F                 BIT $3FA9
AB47   20 0C E1   LAB47         JSR $E10C
AB4A   29 FF                    AND #$FF
AB4C   60                       RTS
AB4D   A5 11      LAB4D         LDA $11
AB4F   F0 11                    BEQ LAB62
AB51   30 04                    BMI LAB57
AB53   A0 FF                    LDY #$FF
AB55   D0 04                    BNE LAB5B
AB57   A5 3F      LAB57         LDA $3F
AB59   A4 40                    LDY $40
AB5B   85 39      LAB5B         STA $39
AB5D   84 3A                    STY $3A
AB5F   4C 08 AF   LAB5F         JMP LAF08
AB62   A5 13      LAB62         LDA $13
AB64   F0 05                    BEQ LAB6B
AB66   A2 18                    LDX #$18
AB68   4C 37 A4                 JMP LA437
AB6B   A9 0C      LAB6B         LDA #$0C
AB6D   A0 AD                    LDY #$AD
AB6F   20 1E AB                 JSR LAB1E
AB72   A5 3D                    LDA $3D
AB74   A4 3E                    LDY $3E
AB76   85 7A                    STA $7A
AB78   84 7B                    STY $7B
AB7A   60                       RTS
AB7B   20 A6 B3                 JSR LB3A6
AB7E   C9 23                    CMP #$23
AB80   D0 10                    BNE LAB92
AB82   20 73 00                 JSR $0073
AB85   20 9E B7                 JSR LB79E
AB88   A9 2C                    LDA #$2C
AB8A   20 FF AE                 JSR LAEFF
AB8D   86 13                    STX $13
AB8F   20 1E E1                 JSR $E11E
AB92   A2 01      LAB92         LDX #$01
AB94   A0 02                    LDY #$02
AB96   A9 00                    LDA #$00
AB98   8D 01 02                 STA $0201
AB9B   A9 40                    LDA #$40
AB9D   20 0F AC                 JSR LAC0F
ABA0   A6 13                    LDX $13
ABA2   D0 13                    BNE LABB7
ABA4   60                       RTS
ABA5   20 9E B7                 JSR LB79E
ABA8   A9 2C                    LDA #$2C
ABAA   20 FF AE                 JSR LAEFF
ABAD   86 13                    STX $13
ABAF   20 1E E1                 JSR $E11E
ABB2   20 CE AB                 JSR LABCE
ABB5   A5 13      LABB5         LDA $13
ABB7   20 CC FF   LABB7         JSR $FFCC
ABBA   A2 00                    LDX #$00
ABBC   86 13                    STX $13
ABBE   60                       RTS
ABBF   C9 22                    CMP #$22
ABC1   D0 0B                    BNE LABCE
ABC3   20 BD AE                 JSR LAEBD
ABC6   A9 3B                    LDA #$3B
ABC8   20 FF AE                 JSR LAEFF
ABCB   20 21 AB                 JSR LAB21
ABCE   20 A6 B3   LABCE         JSR LB3A6
ABD1   A9 2C                    LDA #$2C
ABD3   8D FF 01                 STA $01FF
ABD6   20 F9 AB   LABD6         JSR LABF9
ABD9   A5 13                    LDA $13
ABDB   F0 0D                    BEQ LABEA
ABDD   20 B7 FF                 JSR $FFB7
ABE0   29 02                    AND #$02
ABE2   F0 06                    BEQ LABEA
ABE4   20 B5 AB                 JSR LABB5
ABE7   4C F8 A8                 JMP LA8F8
ABEA   AD 00 02   LABEA         LDA $0200
ABED   D0 1E                    BNE LAC0D
ABEF   A5 13                    LDA $13
ABF1   D0 E3                    BNE LABD6
ABF3   20 06 A9                 JSR LA906
ABF6   4C FB A8                 JMP LA8FB
ABF9   A5 13      LABF9         LDA $13
ABFB   D0 06                    BNE LAC03
ABFD   20 45 AB                 JSR LAB45
AC00   20 3B AB                 JSR LAB3B
AC03   4C 60 A5   LAC03         JMP LA560
AC06   A6 41                    LDX $41
AC08   A4 42                    LDY $42
AC0A   A9 98                    LDA #$98
AC0C   2C A9 00                 BIT $00A9
AC0F   85 11      LAC0F         STA $11
AC11   86 43                    STX $43
AC13   84 44                    STY $44
AC15   20 8B B0   LAC15         JSR LB08B
AC18   85 49                    STA $49
AC1A   84 4A                    STY $4A
AC1C   A5 7A                    LDA $7A
AC1E   A4 7B                    LDY $7B
AC20   85 4B                    STA $4B
AC22   84 4C                    STY $4C
AC24   A6 43                    LDX $43
AC26   A4 44                    LDY $44
AC28   86 7A                    STX $7A
AC2A   84 7B                    STY $7B
AC2C   20 79 00                 JSR $0079
AC2F   D0 20                    BNE LAC51
AC31   24 11                    BIT $11
AC33   50 0C                    BVC LAC41
AC35   20 24 E1                 JSR $E124
AC38   8D 00 02                 STA $0200
AC3B   A2 FF                    LDX #$FF
AC3D   A0 01                    LDY #$01
AC3F   D0 0C                    BNE LAC4D
AC41   30 75      LAC41         BMI LACB8
AC43   A5 13                    LDA $13
AC45   D0 03                    BNE LAC4A
AC47   20 45 AB                 JSR LAB45
AC4A   20 F9 AB   LAC4A         JSR LABF9
AC4D   86 7A      LAC4D         STX $7A
AC4F   84 7B                    STY $7B
AC51   20 73 00   LAC51         JSR $0073
AC54   24 0D                    BIT $0D
AC56   10 31                    BPL LAC89
AC58   24 11                    BIT $11
AC5A   50 09                    BVC LAC65
AC5C   E8                       INX
AC5D   86 7A                    STX $7A
AC5F   A9 00                    LDA #$00
AC61   85 07                    STA $07
AC63   F0 0C                    BEQ LAC71
AC65   85 07      LAC65         STA $07
AC67   C9 22                    CMP #$22
AC69   F0 07                    BEQ LAC72
AC6B   A9 3A                    LDA #$3A
AC6D   85 07                    STA $07
AC6F   A9 2C                    LDA #$2C
AC71   18         LAC71         CLC
AC72   85 08      LAC72         STA $08
AC74   A5 7A                    LDA $7A
AC76   A4 7B                    LDY $7B
AC78   69 00                    ADC #$00
AC7A   90 01                    BCC LAC7D
AC7C   C8                       INY
AC7D   20 8D B4   LAC7D         JSR LB48D
AC80   20 E2 B7                 JSR LB7E2
AC83   20 DA A9                 JSR LA9DA
AC86   4C 91 AC                 JMP LAC91
AC89   20 F3 BC   LAC89         JSR LBCF3
AC8C   A5 0E                    LDA $0E
AC8E   20 C2 A9                 JSR LA9C2
AC91   20 79 00   LAC91         JSR $0079
AC94   F0 07                    BEQ LAC9D
AC96   C9 2C                    CMP #$2C
AC98   F0 03                    BEQ LAC9D
AC9A   4C 4D AB                 JMP LAB4D
AC9D   A5 7A      LAC9D         LDA $7A
AC9F   A4 7B                    LDY $7B
ACA1   85 43                    STA $43
ACA3   84 44                    STY $44
ACA5   A5 4B                    LDA $4B
ACA7   A4 4C                    LDY $4C
ACA9   85 7A                    STA $7A
ACAB   84 7B                    STY $7B
ACAD   20 79 00                 JSR $0079
ACB0   F0 2D                    BEQ LACDF
ACB2   20 FD AE                 JSR LAEFD
ACB5   4C 15 AC                 JMP LAC15
ACB8   20 06 A9   LACB8         JSR LA906
ACBB   C8                       INY
ACBC   AA                       TAX
ACBD   D0 12                    BNE LACD1
ACBF   A2 0D                    LDX #$0D
ACC1   C8                       INY
ACC2   B1 7A                    LDA ($7A),Y
ACC4   F0 6C                    BEQ LAD32
ACC6   C8                       INY
ACC7   B1 7A                    LDA ($7A),Y
ACC9   85 3F                    STA $3F
ACCB   C8                       INY
ACCC   B1 7A                    LDA ($7A),Y
ACCE   C8                       INY
ACCF   85 40                    STA $40
ACD1   20 FB A8   LACD1         JSR LA8FB
ACD4   20 79 00                 JSR $0079
ACD7   AA                       TAX
ACD8   E0 83                    CPX #$83
ACDA   D0 DC                    BNE LACB8
ACDC   4C 51 AC                 JMP LAC51
ACDF   A5 43      LACDF         LDA $43
ACE1   A4 44                    LDY $44
ACE3   A6 11                    LDX $11
ACE5   10 03                    BPL LACEA
ACE7   4C 27 A8                 JMP LA827
ACEA   A0 00      LACEA         LDY #$00
ACEC   B1 43                    LDA ($43),Y
ACEE   F0 0B                    BEQ LACFB
ACF0   A5 13                    LDA $13
ACF2   D0 07                    BNE LACFB
ACF4   A9 FC                    LDA #$FC
ACF6   A0 AC                    LDY #$AC
ACF8   4C 1E AB                 JMP LAB1E
ACFB   60         LACFB         RTS
ACFC   3F                       ???               ;%00111111 '?'
ACFD   45 58                    EOR $58
ACFF   54                       ???               ;%01010100 'T'
AD00   52                       ???               ;%01010010 'R'
AD01   41 20                    EOR ($20,X)
AD03   49 47                    EOR #$47
AD05   4E 4F 52                 LSR $524F
AD08   45 44                    EOR $44
AD0A   0D 00 3F                 ORA $3F00
AD0D   52                       ???               ;%01010010 'R'
AD0E   45 44                    EOR $44
AD10   4F                       ???               ;%01001111 'O'
AD11   20 46 52                 JSR $5246
AD14   4F                       ???               ;%01001111 'O'
AD15   4D 20 53                 EOR $5320
AD18   54                       ???               ;%01010100 'T'
AD19   41 52                    EOR ($52,X)
AD1B   54                       ???               ;%01010100 'T'
AD1C   0D 00 D0                 ORA $D000
AD1F   04                       ???               ;%00000100
AD20   A0 00                    LDY #$00
AD22   F0 03                    BEQ LAD27
AD24   20 8B B0   LAD24         JSR LB08B
AD27   85 49      LAD27         STA $49
AD29   84 4A                    STY $4A
AD2B   20 8A A3                 JSR LA38A
AD2E   F0 05                    BEQ LAD35
AD30   A2 0A                    LDX #$0A
AD32   4C 37 A4   LAD32         JMP LA437
AD35   9A         LAD35         TXS
AD36   8A                       TXA
AD37   18                       CLC
AD38   69 04                    ADC #$04
AD3A   48                       PHA
AD3B   69 06                    ADC #$06
AD3D   85 24                    STA $24
AD3F   68                       PLA
AD40   A0 01                    LDY #$01
AD42   20 A2 BB                 JSR LBBA2
AD45   BA                       TSX
AD46   BD 09 01                 LDA $0109,X
AD49   85 66                    STA $66
AD4B   A5 49                    LDA $49
AD4D   A4 4A                    LDY $4A
AD4F   20 67 B8                 JSR LB867
AD52   20 D0 BB                 JSR LBBD0
AD55   A0 01                    LDY #$01
AD57   20 5D BC                 JSR LBC5D
AD5A   BA                       TSX
AD5B   38                       SEC
AD5C   FD 09 01                 SBC $0109,X
AD5F   F0 17                    BEQ LAD78
AD61   BD 0F 01                 LDA $010F,X
AD64   85 39                    STA $39
AD66   BD 10 01                 LDA $0110,X
AD69   85 3A                    STA $3A
AD6B   BD 12 01                 LDA $0112,X
AD6E   85 7A                    STA $7A
AD70   BD 11 01                 LDA $0111,X
AD73   85 7B                    STA $7B
AD75   4C AE A7   LAD75         JMP LA7AE
AD78   8A         LAD78         TXA
AD79   69 11                    ADC #$11
AD7B   AA                       TAX
AD7C   9A                       TXS
AD7D   20 79 00                 JSR $0079
AD80   C9 2C                    CMP #$2C
AD82   D0 F1                    BNE LAD75
AD84   20 73 00                 JSR $0073
AD87   20 24 AD                 JSR LAD24
AD8A   20 9E AD   LAD8A         JSR LAD9E
AD8D   18         LAD8D         CLC
AD8E   24 38                    BIT $38
AD90   24 0D      LAD90         BIT $0D
AD92   30 03                    BMI LAD97
AD94   B0 03                    BCS LAD99
AD96   60         LAD96         RTS
AD97   B0 FD      LAD97         BCS LAD96
AD99   A2 16      LAD99         LDX #$16
AD9B   4C 37 A4                 JMP LA437
AD9E   A6 7A      LAD9E         LDX $7A
ADA0   D0 02                    BNE LADA4
ADA2   C6 7B                    DEC $7B
ADA4   C6 7A      LADA4         DEC $7A
ADA6   A2 00                    LDX #$00
ADA8   24 48                    BIT $48
ADAA   8A                       TXA
ADAB   48                       PHA
ADAC   A9 01                    LDA #$01
ADAE   20 FB A3                 JSR LA3FB
ADB1   20 83 AE                 JSR LAE83
ADB4   A9 00                    LDA #$00
ADB6   85 4D                    STA $4D
ADB8   20 79 00   LADB8         JSR $0079
ADBB   38         LADBB         SEC
ADBC   E9 B1                    SBC #$B1
ADBE   90 17                    BCC LADD7
ADC0   C9 03                    CMP #$03
ADC2   B0 13                    BCS LADD7
ADC4   C9 01                    CMP #$01
ADC6   2A                       ROL A
ADC7   49 01                    EOR #$01
ADC9   45 4D                    EOR $4D
ADCB   C5 4D                    CMP $4D
ADCD   90 61                    BCC LAE30
ADCF   85 4D                    STA $4D
ADD1   20 73 00                 JSR $0073
ADD4   4C BB AD                 JMP LADBB
ADD7   A6 4D      LADD7         LDX $4D
ADD9   D0 2C                    BNE LAE07
ADDB   B0 7B                    BCS LAE58
ADDD   69 07                    ADC #$07
ADDF   90 77                    BCC LAE58
ADE1   65 0D                    ADC $0D
ADE3   D0 03                    BNE LADE8
ADE5   4C 3D B6                 JMP LB63D
ADE8   69 FF      LADE8         ADC #$FF
ADEA   85 22                    STA $22
ADEC   0A                       ASL A
ADED   65 22                    ADC $22
ADEF   A8                       TAY
ADF0   68         LADF0         PLA
ADF1   D9 80 A0                 CMP $A080,Y
ADF4   B0 67                    BCS LAE5D
ADF6   20 8D AD                 JSR LAD8D
ADF9   48         LADF9         PHA
ADFA   20 20 AE   LADFA         JSR LAE20
ADFD   68                       PLA
ADFE   A4 4B                    LDY $4B
AE00   10 17                    BPL LAE19
AE02   AA                       TAX
AE03   F0 56                    BEQ LAE5B
AE05   D0 5F                    BNE LAE66
AE07   46 0D      LAE07         LSR $0D
AE09   8A                       TXA
AE0A   2A                       ROL A
AE0B   A6 7A                    LDX $7A
AE0D   D0 02                    BNE LAE11
AE0F   C6 7B                    DEC $7B
AE11   C6 7A      LAE11         DEC $7A
AE13   A0 1B                    LDY #$1B
AE15   85 4D                    STA $4D
AE17   D0 D7                    BNE LADF0
AE19   D9 80 A0   LAE19         CMP $A080,Y
AE1C   B0 48                    BCS LAE66
AE1E   90 D9                    BCC LADF9
AE20   B9 82 A0   LAE20         LDA $A082,Y
AE23   48                       PHA
AE24   B9 81 A0                 LDA $A081,Y
AE27   48                       PHA
AE28   20 33 AE                 JSR LAE33
AE2B   A5 4D                    LDA $4D
AE2D   4C A9 AD                 JMP LADA9
AE30   4C 08 AF   LAE30         JMP LAF08
AE33   A5 66      LAE33         LDA $66
AE35   BE 80 A0                 LDX $A080,Y
AE38   A8         LAE38         TAY
AE39   68                       PLA
AE3A   85 22                    STA $22
AE3C   E6 22                    INC $22
AE3E   68                       PLA
AE3F   85 23                    STA $23
AE41   98                       TYA
AE42   48                       PHA
AE43   20 1B BC   LAE43         JSR LBC1B
AE46   A5 65                    LDA $65
AE48   48                       PHA
AE49   A5 64                    LDA $64
AE4B   48                       PHA
AE4C   A5 63                    LDA $63
AE4E   48                       PHA
AE4F   A5 62                    LDA $62
AE51   48                       PHA
AE52   A5 61                    LDA $61
AE54   48                       PHA
AE55   6C 22 00                 JMP ($0022)
AE58   A0 FF      LAE58         LDY #$FF
AE5A   68                       PLA
AE5B   F0 23      LAE5B         BEQ LAE80
AE5D   C9 64      LAE5D         CMP #$64
AE5F   F0 03                    BEQ LAE64
AE61   20 8D AD                 JSR LAD8D
AE64   84 4B      LAE64         STY $4B
AE66   68         LAE66         PLA
AE67   4A                       LSR A
AE68   85 12                    STA $12
AE6A   68                       PLA
AE6B   85 69                    STA $69
AE6D   68                       PLA
AE6E   85 6A                    STA $6A
AE70   68                       PLA
AE71   85 6B                    STA $6B
AE73   68                       PLA
AE74   85 6C                    STA $6C
AE76   68                       PLA
AE77   85 6D                    STA $6D
AE79   68                       PLA
AE7A   85 6E                    STA $6E
AE7C   45 66                    EOR $66
AE7E   85 6F                    STA $6F
AE80   A5 61      LAE80         LDA $61
AE82   60                       RTS
AE83   6C 0A 03   LAE83         JMP ($030A)
AE86   A9 00                    LDA #$00
AE88   85 0D                    STA $0D
AE8A   20 73 00   LAE8A         JSR $0073
AE8D   B0 03                    BCS LAE92
AE8F   4C F3 BC                 JMP LBCF3
AE92   20 13 B1   LAE92         JSR LB113
AE95   90 03                    BCC LAE9A
AE97   4C 28 AF                 JMP LAF28
AE9A   C9 FF      LAE9A         CMP #$FF
AE9C   D0 0F                    BNE LAEAD
AE9E   A9 A8                    LDA #$A8
AEA0   A0 AE                    LDY #$AE
AEA2   20 A2 BB                 JSR LBBA2
AEA5   4C 73 00                 JMP $0073
AEA8   82                       ???               ;%10000010
AEA9   49 0F                    EOR #$0F
AEAB   DA                       ???               ;%11011010
AEAC   A1 C9                    LDA ($C9,X)
AEAE   2E F0 DE                 ROL $DEF0
AEB1   C9 AB                    CMP #$AB
AEB3   F0 58                    BEQ LAF0D
AEB5   C9 AA                    CMP #$AA
AEB7   F0 D1                    BEQ LAE8A
AEB9   C9 22                    CMP #$22
AEBB   D0 0F                    BNE LAECC
AEBD   A5 7A      LAEBD         LDA $7A
AEBF   A4 7B                    LDY $7B
AEC1   69 00                    ADC #$00
AEC3   90 01                    BCC LAEC6
AEC5   C8                       INY
AEC6   20 87 B4   LAEC6         JSR LB487
AEC9   4C E2 B7                 JMP LB7E2
AECC   C9 A8      LAECC         CMP #$A8
AECE   D0 13                    BNE LAEE3
AED0   A0 18                    LDY #$18
AED2   D0 3B                    BNE LAF0F
AED4   20 BF B1                 JSR LB1BF
AED7   A5 65                    LDA $65
AED9   49 FF                    EOR #$FF
AEDB   A8                       TAY
AEDC   A5 64                    LDA $64
AEDE   49 FF                    EOR #$FF
AEE0   4C 91 B3                 JMP LB391
AEE3   C9 A5      LAEE3         CMP #$A5
AEE5   D0 03                    BNE LAEEA
AEE7   4C F4 B3                 JMP LB3F4
AEEA   C9 B4      LAEEA         CMP #$B4
AEEC   90 03                    BCC LAEF1
AEEE   4C A7 AF                 JMP LAFA7
AEF1   20 FA AE   LAEF1         JSR LAEFA
AEF4   20 9E AD                 JSR LAD9E
AEF7   A9 29      LAEF7         LDA #$29
AEF9   2C A9 28                 BIT $28A9
AEFC   2C A9 2C                 BIT $2CA9
AEFF   A0 00      LAEFF         LDY #$00
AF01   D1 7A                    CMP ($7A),Y
AF03   D0 03                    BNE LAF08
AF05   4C 73 00                 JMP $0073
AF08   A2 0B      LAF08         LDX #$0B
AF0A   4C 37 A4                 JMP LA437
AF0D   A0 15      LAF0D         LDY #$15
AF0F   68         LAF0F         PLA
AF10   68                       PLA
AF11   4C FA AD                 JMP LADFA
AF14   38         LAF14         SEC
AF15   A5 64                    LDA $64
AF17   E9 00                    SBC #$00
AF19   A5 65                    LDA $65
AF1B   E9 A0                    SBC #$A0
AF1D   90 08                    BCC LAF27
AF1F   A9 A2                    LDA #$A2
AF21   E5 64                    SBC $64
AF23   A9 E3                    LDA #$E3
AF25   E5 65                    SBC $65
AF27   60         LAF27         RTS
AF28   20 8B B0   LAF28         JSR LB08B
AF2B   85 64                    STA $64
AF2D   84 65                    STY $65
AF2F   A6 45                    LDX $45
AF31   A4 46                    LDY $46
AF33   A5 0D                    LDA $0D
AF35   F0 26                    BEQ LAF5D
AF37   A9 00                    LDA #$00
AF39   85 70                    STA $70
AF3B   20 14 AF                 JSR LAF14
AF3E   90 1C                    BCC LAF5C
AF40   E0 54                    CPX #$54
AF42   D0 18                    BNE LAF5C
AF44   C0 C9                    CPY #$C9
AF46   D0 14                    BNE LAF5C
AF48   20 84 AF                 JSR LAF84
AF4B   84 5E                    STY $5E
AF4D   88                       DEY
AF4E   84 71                    STY $71
AF50   A0 06                    LDY #$06
AF52   84 5D                    STY $5D
AF54   A0 24                    LDY #$24
AF56   20 68 BE                 JSR LBE68
AF59   4C 6F B4                 JMP LB46F
AF5C   60         LAF5C         RTS
AF5D   24 0E      LAF5D         BIT $0E
AF5F   10 0D                    BPL LAF6E
AF61   A0 00                    LDY #$00
AF63   B1 64                    LDA ($64),Y
AF65   AA                       TAX
AF66   C8                       INY
AF67   B1 64                    LDA ($64),Y
AF69   A8                       TAY
AF6A   8A                       TXA
AF6B   4C 91 B3                 JMP LB391
AF6E   20 14 AF   LAF6E         JSR LAF14
AF71   90 2D                    BCC LAFA0
AF73   E0 54                    CPX #$54
AF75   D0 1B                    BNE LAF92
AF77   C0 49                    CPY #$49
AF79   D0 25                    BNE LAFA0
AF7B   20 84 AF                 JSR LAF84
AF7E   98                       TYA
AF7F   A2 A0                    LDX #$A0
AF81   4C 4F BC                 JMP LBC4F
AF84   20 DE FF   LAF84         JSR $FFDE
AF87   86 64                    STX $64
AF89   84 63                    STY $63
AF8B   85 65                    STA $65
AF8D   A0 00                    LDY #$00
AF8F   84 62                    STY $62
AF91   60                       RTS
AF92   E0 53      LAF92         CPX #$53
AF94   D0 0A                    BNE LAFA0
AF96   C0 54                    CPY #$54
AF98   D0 06                    BNE LAFA0
AF9A   20 B7 FF                 JSR $FFB7
AF9D   4C 3C BC                 JMP LBC3C
AFA0   A5 64      LAFA0         LDA $64
AFA2   A4 65                    LDY $65
AFA4   4C A2 BB                 JMP LBBA2
AFA7   0A         LAFA7         ASL A
AFA8   48                       PHA
AFA9   AA                       TAX
AFAA   20 73 00                 JSR $0073
AFAD   E0 8F                    CPX #$8F
AFAF   90 20                    BCC LAFD1
AFB1   20 FA AE                 JSR LAEFA
AFB4   20 9E AD                 JSR LAD9E
AFB7   20 FD AE                 JSR LAEFD
AFBA   20 8F AD                 JSR LAD8F
AFBD   68                       PLA
AFBE   AA                       TAX
AFBF   A5 65                    LDA $65
AFC1   48                       PHA
AFC2   A5 64                    LDA $64
AFC4   48                       PHA
AFC5   8A                       TXA
AFC6   48                       PHA
AFC7   20 9E B7                 JSR LB79E
AFCA   68                       PLA
AFCB   A8                       TAY
AFCC   8A                       TXA
AFCD   48                       PHA
AFCE   4C D6 AF                 JMP LAFD6
AFD1   20 F1 AE   LAFD1         JSR LAEF1
AFD4   68                       PLA
AFD5   A8                       TAY
AFD6   B9 EA 9F   LAFD6         LDA $9FEA,Y
AFD9   85 55                    STA $55
AFDB   B9 EB 9F                 LDA $9FEB,Y
AFDE   85 56                    STA $56
AFE0   20 54 00                 JSR $0054
AFE3   4C 8D AD                 JMP LAD8D
AFE6   A0 FF                    LDY #$FF
AFE8   2C A0 00                 BIT $00A0
AFEB   84 0B                    STY $0B
AFED   20 BF B1                 JSR LB1BF
AFF0   A5 64                    LDA $64
AFF2   45 0B                    EOR $0B
AFF4   85 07                    STA $07
AFF6   A5 65                    LDA $65
AFF8   45 0B                    EOR $0B
AFFA   85 08                    STA $08
AFFC   20 FC BB                 JSR LBBFC
AFFF   20 BF B1                 JSR LB1BF
B002   A5 65                    LDA $65
B004   45 0B                    EOR $0B
B006   25 08                    AND $08
B008   45 0B                    EOR $0B
B00A   A8                       TAY
B00B   A5 64                    LDA $64
B00D   45 0B                    EOR $0B
B00F   25 07                    AND $07
B011   45 0B                    EOR $0B
B013   4C 91 B3                 JMP LB391
B016   20 90 AD                 JSR LAD90
B019   B0 13                    BCS LB02E
B01B   A5 6E                    LDA $6E
B01D   09 7F                    ORA #$7F
B01F   25 6A                    AND $6A
B021   85 6A                    STA $6A
B023   A9 69                    LDA #$69
B025   A0 00                    LDY #$00
B027   20 5B BC                 JSR LBC5B
B02A   AA                       TAX
B02B   4C 61 B0                 JMP LB061
B02E   A9 00      LB02E         LDA #$00
B030   85 0D                    STA $0D
B032   C6 4D                    DEC $4D
B034   20 A6 B6                 JSR LB6A6
B037   85 61                    STA $61
B039   86 62                    STX $62
B03B   84 63                    STY $63
B03D   A5 6C                    LDA $6C
B03F   A4 6D                    LDY $6D
B041   20 AA B6                 JSR LB6AA
B044   86 6C                    STX $6C
B046   84 6D                    STY $6D
B048   AA                       TAX
B049   38                       SEC
B04A   E5 61                    SBC $61
B04C   F0 08                    BEQ LB056
B04E   A9 01                    LDA #$01
B050   90 04                    BCC LB056
B052   A6 61                    LDX $61
B054   A9 FF                    LDA #$FF
B056   85 66      LB056         STA $66
B058   A0 FF                    LDY #$FF
B05A   E8                       INX
B05B   C8         LB05B         INY
B05C   CA                       DEX
B05D   D0 07                    BNE LB066
B05F   A6 66                    LDX $66
B061   30 0F      LB061         BMI LB072
B063   18                       CLC
B064   90 0C                    BCC LB072
B066   B1 6C      LB066         LDA ($6C),Y
B068   D1 62                    CMP ($62),Y
B06A   F0 EF                    BEQ LB05B
B06C   A2 FF                    LDX #$FF
B06E   B0 02                    BCS LB072
B070   A2 01                    LDX #$01
B072   E8         LB072         INX
B073   8A                       TXA
B074   2A                       ROL A
B075   25 12                    AND $12
B077   F0 02                    BEQ LB07B
B079   A9 FF                    LDA #$FF
B07B   4C 3C BC   LB07B         JMP LBC3C
B07E   20 FD AE   LB07E         JSR LAEFD
B081   AA                       TAX
B082   20 90 B0                 JSR LB090
B085   20 79 00                 JSR $0079
B088   D0 F4                    BNE LB07E
B08A   60                       RTS
B08B   A2 00      LB08B         LDX #$00
B08D   20 79 00                 JSR $0079
B090   86 0C      LB090         STX $0C
B092   85 45      LB092         STA $45
B094   20 79 00                 JSR $0079
B097   20 13 B1                 JSR LB113
B09A   B0 03                    BCS LB09F
B09C   4C 08 AF   LB09C         JMP LAF08
B09F   A2 00      LB09F         LDX #$00
B0A1   86 0D                    STX $0D
B0A3   86 0E                    STX $0E
B0A5   20 73 00                 JSR $0073
B0A8   90 05                    BCC LB0AF
B0AA   20 13 B1                 JSR LB113
B0AD   90 0B                    BCC LB0BA
B0AF   AA         LB0AF         TAX
B0B0   20 73 00   LB0B0         JSR $0073
B0B3   90 FB                    BCC LB0B0
B0B5   20 13 B1                 JSR LB113
B0B8   B0 F6                    BCS LB0B0
B0BA   C9 24      LB0BA         CMP #$24
B0BC   D0 06                    BNE LB0C4
B0BE   A9 FF                    LDA #$FF
B0C0   85 0D                    STA $0D
B0C2   D0 10                    BNE LB0D4
B0C4   C9 25      LB0C4         CMP #$25
B0C6   D0 13                    BNE LB0DB
B0C8   A5 10                    LDA $10
B0CA   D0 D0                    BNE LB09C
B0CC   A9 80                    LDA #$80
B0CE   85 0E                    STA $0E
B0D0   05 45                    ORA $45
B0D2   85 45                    STA $45
B0D4   8A         LB0D4         TXA
B0D5   09 80                    ORA #$80
B0D7   AA                       TAX
B0D8   20 73 00                 JSR $0073
B0DB   86 46      LB0DB         STX $46
B0DD   38                       SEC
B0DE   05 10                    ORA $10
B0E0   E9 28                    SBC #$28
B0E2   D0 03                    BNE LB0E7
B0E4   4C D1 B1                 JMP LB1D1
B0E7   A0 00      LB0E7         LDY #$00
B0E9   84 10                    STY $10
B0EB   A5 2D                    LDA $2D
B0ED   A6 2E                    LDX $2E
B0EF   86 60      LB0EF         STX $60
B0F1   85 5F      LB0F1         STA $5F
B0F3   E4 30                    CPX $30
B0F5   D0 04                    BNE LB0FB
B0F7   C5 2F                    CMP $2F
B0F9   F0 22                    BEQ LB11D
B0FB   A5 45      LB0FB         LDA $45
B0FD   D1 5F                    CMP ($5F),Y
B0FF   D0 08                    BNE LB109
B101   A5 46                    LDA $46
B103   C8                       INY
B104   D1 5F                    CMP ($5F),Y
B106   F0 7D                    BEQ LB185
B108   88                       DEY
B109   18         LB109         CLC
B10A   A5 5F                    LDA $5F
B10C   69 07                    ADC #$07
B10E   90 E1                    BCC LB0F1
B110   E8                       INX
B111   D0 DC                    BNE LB0EF
B113   C9 41      LB113         CMP #$41
B115   90 05                    BCC LB11C
B117   E9 5B                    SBC #$5B
B119   38                       SEC
B11A   E9 A5                    SBC #$A5
B11C   60         LB11C         RTS
B11D   68         LB11D         PLA
B11E   48                       PHA
B11F   C9 2A                    CMP #$2A
B121   D0 05                    BNE LB128
B123   A9 13      LB123         LDA #$13
B125   A0 BF                    LDY #$BF
B127   60         LB127         RTS
B128   A5 45      LB128         LDA $45
B12A   A4 46                    LDY $46
B12C   C9 54                    CMP #$54
B12E   D0 0B                    BNE LB13B
B130   C0 C9                    CPY #$C9
B132   F0 EF                    BEQ LB123
B134   C0 49                    CPY #$49
B136   D0 03                    BNE LB13B
B138   4C 08 AF   LB138         JMP LAF08
B13B   C9 53      LB13B         CMP #$53
B13D   D0 04                    BNE LB143
B13F   C0 54                    CPY #$54
B141   F0 F5                    BEQ LB138
B143   A5 2F      LB143         LDA $2F
B145   A4 30                    LDY $30
B147   85 5F                    STA $5F
B149   84 60                    STY $60
B14B   A5 31                    LDA $31
B14D   A4 32                    LDY $32
B14F   85 5A                    STA $5A
B151   84 5B                    STY $5B
B153   18                       CLC
B154   69 07                    ADC #$07
B156   90 01                    BCC LB159
B158   C8                       INY
B159   85 58      LB159         STA $58
B15B   84 59                    STY $59
B15D   20 B8 A3                 JSR LA3B8
B160   A5 58                    LDA $58
B162   A4 59                    LDY $59
B164   C8                       INY
B165   85 2F                    STA $2F
B167   84 30                    STY $30
B169   A0 00                    LDY #$00
B16B   A5 45                    LDA $45
B16D   91 5F                    STA ($5F),Y
B16F   C8                       INY
B170   A5 46                    LDA $46
B172   91 5F                    STA ($5F),Y
B174   A9 00                    LDA #$00
B176   C8                       INY
B177   91 5F                    STA ($5F),Y
B179   C8                       INY
B17A   91 5F                    STA ($5F),Y
B17C   C8                       INY
B17D   91 5F                    STA ($5F),Y
B17F   C8                       INY
B180   91 5F                    STA ($5F),Y
B182   C8                       INY
B183   91 5F                    STA ($5F),Y
B185   A5 5F      LB185         LDA $5F
B187   18                       CLC
B188   69 02                    ADC #$02
B18A   A4 60                    LDY $60
B18C   90 01                    BCC LB18F
B18E   C8                       INY
B18F   85 47      LB18F         STA $47
B191   84 48                    STY $48
B193   60                       RTS
B194   A5 0B      LB194         LDA $0B
B196   0A                       ASL A
B197   69 05                    ADC #$05
B199   65 5F                    ADC $5F
B19B   A4 60                    LDY $60
B19D   90 01                    BCC LB1A0
B19F   C8                       INY
B1A0   85 58      LB1A0         STA $58
B1A2   84 59                    STY $59
B1A4   60                       RTS
B1A5   90 80                    BCC LB127
B1A7   00                       BRK
B1A8   00                       BRK
B1A9   00                       BRK
B1AA   20 BF B1                 JSR LB1BF
B1AD   A5 64                    LDA $64
B1AF   A4 65                    LDY $65
B1B1   60                       RTS
B1B2   20 73 00   LB1B2         JSR $0073
B1B5   20 9E AD                 JSR LAD9E
B1B8   20 8D AD   LB1B8         JSR LAD8D
B1BB   A5 66                    LDA $66
B1BD   30 0D                    BMI LB1CC
B1BF   A5 61      LB1BF         LDA $61
B1C1   C9 90                    CMP #$90
B1C3   90 09                    BCC LB1CE
B1C5   A9 A5                    LDA #$A5
B1C7   A0 B1                    LDY #$B1
B1C9   20 5B BC                 JSR LBC5B
B1CC   D0 7A      LB1CC         BNE LB248
B1CE   4C 9B BC   LB1CE         JMP LBC9B
B1D1   A5 0C      LB1D1         LDA $0C
B1D3   05 0E                    ORA $0E
B1D5   48                       PHA
B1D6   A5 0D                    LDA $0D
B1D8   48                       PHA
B1D9   A0 00                    LDY #$00
B1DB   98         LB1DB         TYA
B1DC   48                       PHA
B1DD   A5 46                    LDA $46
B1DF   48                       PHA
B1E0   A5 45                    LDA $45
B1E2   48                       PHA
B1E3   20 B2 B1                 JSR LB1B2
B1E6   68                       PLA
B1E7   85 45                    STA $45
B1E9   68                       PLA
B1EA   85 46                    STA $46
B1EC   68                       PLA
B1ED   A8                       TAY
B1EE   BA                       TSX
B1EF   BD 02 01                 LDA $0102,X
B1F2   48                       PHA
B1F3   BD 01 01                 LDA $0101,X
B1F6   48                       PHA
B1F7   A5 64                    LDA $64
B1F9   9D 02 01                 STA $0102,X
B1FC   A5 65                    LDA $65
B1FE   9D 01 01                 STA $0101,X
B201   C8                       INY
B202   20 79 00                 JSR $0079
B205   C9 2C                    CMP #$2C
B207   F0 D2                    BEQ LB1DB
B209   84 0B                    STY $0B
B20B   20 F7 AE                 JSR LAEF7
B20E   68                       PLA
B20F   85 0D                    STA $0D
B211   68                       PLA
B212   85 0E                    STA $0E
B214   29 7F                    AND #$7F
B216   85 0C                    STA $0C
B218   A6 2F                    LDX $2F
B21A   A5 30                    LDA $30
B21C   86 5F      LB21C         STX $5F
B21E   85 60                    STA $60
B220   C5 32                    CMP $32
B222   D0 04                    BNE LB228
B224   E4 31                    CPX $31
B226   F0 39                    BEQ LB261
B228   A0 00      LB228         LDY #$00
B22A   B1 5F                    LDA ($5F),Y
B22C   C8                       INY
B22D   C5 45                    CMP $45
B22F   D0 06                    BNE LB237
B231   A5 46                    LDA $46
B233   D1 5F                    CMP ($5F),Y
B235   F0 16                    BEQ LB24D
B237   C8         LB237         INY
B238   B1 5F                    LDA ($5F),Y
B23A   18                       CLC
B23B   65 5F                    ADC $5F
B23D   AA                       TAX
B23E   C8                       INY
B23F   B1 5F                    LDA ($5F),Y
B241   65 60                    ADC $60
B243   90 D7                    BCC LB21C
B245   A2 12      LB245         LDX #$12
B247   2C A2 0E                 BIT $0EA2
B24A   4C 37 A4   LB24A         JMP LA437
B24D   A2 13      LB24D         LDX #$13
B24F   A5 0C                    LDA $0C
B251   D0 F7                    BNE LB24A
B253   20 94 B1                 JSR LB194
B256   A5 0B                    LDA $0B
B258   A0 04                    LDY #$04
B25A   D1 5F                    CMP ($5F),Y
B25C   D0 E7                    BNE LB245
B25E   4C EA B2                 JMP LB2EA
B261   20 94 B1   LB261         JSR LB194
B264   20 08 A4                 JSR LA408
B267   A0 00                    LDY #$00
B269   84 72                    STY $72
B26B   A2 05                    LDX #$05
B26D   A5 45                    LDA $45
B26F   91 5F                    STA ($5F),Y
B271   10 01                    BPL LB274
B273   CA                       DEX
B274   C8         LB274         INY
B275   A5 46                    LDA $46
B277   91 5F                    STA ($5F),Y
B279   10 02                    BPL LB27D
B27B   CA                       DEX
B27C   CA                       DEX
B27D   86 71      LB27D         STX $71
B27F   A5 0B                    LDA $0B
B281   C8                       INY
B282   C8                       INY
B283   C8                       INY
B284   91 5F                    STA ($5F),Y
B286   A2 0B      LB286         LDX #$0B
B288   A9 00                    LDA #$00
B28A   24 0C                    BIT $0C
B28C   50 08                    BVC LB296
B28E   68                       PLA
B28F   18                       CLC
B290   69 01                    ADC #$01
B292   AA                       TAX
B293   68                       PLA
B294   69 00                    ADC #$00
B296   C8         LB296         INY
B297   91 5F                    STA ($5F),Y
B299   C8                       INY
B29A   8A                       TXA
B29B   91 5F                    STA ($5F),Y
B29D   20 4C B3                 JSR LB34C
B2A0   86 71                    STX $71
B2A2   85 72                    STA $72
B2A4   A4 22                    LDY $22
B2A6   C6 0B                    DEC $0B
B2A8   D0 DC                    BNE LB286
B2AA   65 59                    ADC $59
B2AC   B0 5D                    BCS LB30B
B2AE   85 59                    STA $59
B2B0   A8                       TAY
B2B1   8A                       TXA
B2B2   65 58                    ADC $58
B2B4   90 03                    BCC LB2B9
B2B6   C8                       INY
B2B7   F0 52                    BEQ LB30B
B2B9   20 08 A4   LB2B9         JSR LA408
B2BC   85 31                    STA $31
B2BE   84 32                    STY $32
B2C0   A9 00                    LDA #$00
B2C2   E6 72                    INC $72
B2C4   A4 71                    LDY $71
B2C6   F0 05                    BEQ LB2CD
B2C8   88         LB2C8         DEY
B2C9   91 58                    STA ($58),Y
B2CB   D0 FB                    BNE LB2C8
B2CD   C6 59      LB2CD         DEC $59
B2CF   C6 72                    DEC $72
B2D1   D0 F5                    BNE LB2C8
B2D3   E6 59                    INC $59
B2D5   38                       SEC
B2D6   A5 31                    LDA $31
B2D8   E5 5F                    SBC $5F
B2DA   A0 02                    LDY #$02
B2DC   91 5F                    STA ($5F),Y
B2DE   A5 32                    LDA $32
B2E0   C8                       INY
B2E1   E5 60                    SBC $60
B2E3   91 5F                    STA ($5F),Y
B2E5   A5 0C                    LDA $0C
B2E7   D0 62                    BNE LB34B
B2E9   C8                       INY
B2EA   B1 5F      LB2EA         LDA ($5F),Y
B2EC   85 0B                    STA $0B
B2EE   A9 00                    LDA #$00
B2F0   85 71                    STA $71
B2F2   85 72      LB2F2         STA $72
B2F4   C8                       INY
B2F5   68                       PLA
B2F6   AA                       TAX
B2F7   85 64                    STA $64
B2F9   68                       PLA
B2FA   85 65                    STA $65
B2FC   D1 5F                    CMP ($5F),Y
B2FE   90 0E                    BCC LB30E
B300   D0 06                    BNE LB308
B302   C8                       INY
B303   8A                       TXA
B304   D1 5F                    CMP ($5F),Y
B306   90 07                    BCC LB30F
B308   4C 45 B2   LB308         JMP LB245
B30B   4C 35 A4   LB30B         JMP LA435
B30E   C8         LB30E         INY
B30F   A5 72      LB30F         LDA $72
B311   05 71                    ORA $71
B313   18                       CLC
B314   F0 0A                    BEQ LB320
B316   20 4C B3                 JSR LB34C
B319   8A                       TXA
B31A   65 64                    ADC $64
B31C   AA                       TAX
B31D   98                       TYA
B31E   A4 22                    LDY $22
B320   65 65      LB320         ADC $65
B322   86 71                    STX $71
B324   C6 0B                    DEC $0B
B326   D0 CA                    BNE LB2F2
B328   85 72                    STA $72
B32A   A2 05                    LDX #$05
B32C   A5 45                    LDA $45
B32E   10 01                    BPL LB331
B330   CA                       DEX
B331   A5 46      LB331         LDA $46
B333   10 02                    BPL LB337
B335   CA                       DEX
B336   CA                       DEX
B337   86 28      LB337         STX $28
B339   A9 00                    LDA #$00
B33B   20 55 B3                 JSR LB355
B33E   8A                       TXA
B33F   65 58                    ADC $58
B341   85 47                    STA $47
B343   98                       TYA
B344   65 59                    ADC $59
B346   85 48                    STA $48
B348   A8                       TAY
B349   A5 47                    LDA $47
B34B   60         LB34B         RTS
B34C   84 22      LB34C         STY $22
B34E   B1 5F                    LDA ($5F),Y
B350   85 28                    STA $28
B352   88                       DEY
B353   B1 5F                    LDA ($5F),Y
B355   85 29      LB355         STA $29
B357   A9 10                    LDA #$10
B359   85 5D                    STA $5D
B35B   A2 00                    LDX #$00
B35D   A0 00                    LDY #$00
B35F   8A         LB35F         TXA
B360   0A                       ASL A
B361   AA                       TAX
B362   98                       TYA
B363   2A                       ROL A
B364   A8                       TAY
B365   B0 A4                    BCS LB30B
B367   06 71                    ASL $71
B369   26 72                    ROL $72
B36B   90 0B                    BCC LB378
B36D   18                       CLC
B36E   8A                       TXA
B36F   65 28                    ADC $28
B371   AA                       TAX
B372   98                       TYA
B373   65 29                    ADC $29
B375   A8                       TAY
B376   B0 93                    BCS LB30B
B378   C6 5D      LB378         DEC $5D
B37A   D0 E3                    BNE LB35F
B37C   60                       RTS
B37D   A5 0D                    LDA $0D
B37F   F0 03                    BEQ LB384
B381   20 A6 B6                 JSR LB6A6
B384   20 26 B5   LB384         JSR LB526
B387   38                       SEC
B388   A5 33                    LDA $33
B38A   E5 31                    SBC $31
B38C   A8                       TAY
B38D   A5 34                    LDA $34
B38F   E5 32                    SBC $32
B391   A2 00      LB391         LDX #$00
B393   86 0D                    STX $0D
B395   85 62                    STA $62
B397   84 63                    STY $63
B399   A2 90                    LDX #$90
B39B   4C 44 BC                 JMP LBC44
B39E   38                       SEC
B39F   20 F0 FF                 JSR $FFF0
B3A2   A9 00      LB3A2         LDA #$00
B3A4   F0 EB                    BEQ LB391
B3A6   A6 3A      LB3A6         LDX $3A
B3A8   E8                       INX
B3A9   D0 A0                    BNE LB34B
B3AB   A2 15                    LDX #$15
B3AD   2C A2 1B                 BIT $1BA2
B3B0   4C 37 A4                 JMP LA437
B3B3   20 E1 B3                 JSR LB3E1
B3B6   20 A6 B3                 JSR LB3A6
B3B9   20 FA AE                 JSR LAEFA
B3BC   A9 80                    LDA #$80
B3BE   85 10                    STA $10
B3C0   20 8B B0                 JSR LB08B
B3C3   20 8D AD                 JSR LAD8D
B3C6   20 F7 AE                 JSR LAEF7
B3C9   A9 B2                    LDA #$B2
B3CB   20 FF AE                 JSR LAEFF
B3CE   48                       PHA
B3CF   A5 48                    LDA $48
B3D1   48                       PHA
B3D2   A5 47                    LDA $47
B3D4   48                       PHA
B3D5   A5 7B                    LDA $7B
B3D7   48                       PHA
B3D8   A5 7A                    LDA $7A
B3DA   48                       PHA
B3DB   20 F8 A8                 JSR LA8F8
B3DE   4C 4F B4                 JMP LB44F
B3E1   A9 A5      LB3E1         LDA #$A5
B3E3   20 FF AE                 JSR LAEFF
B3E6   09 80                    ORA #$80
B3E8   85 10                    STA $10
B3EA   20 92 B0                 JSR LB092
B3ED   85 4E                    STA $4E
B3EF   84 4F                    STY $4F
B3F1   4C 8D AD                 JMP LAD8D
B3F4   20 E1 B3   LB3F4         JSR LB3E1
B3F7   A5 4F                    LDA $4F
B3F9   48                       PHA
B3FA   A5 4E                    LDA $4E
B3FC   48                       PHA
B3FD   20 F1 AE                 JSR LAEF1
B400   20 8D AD                 JSR LAD8D
B403   68                       PLA
B404   85 4E                    STA $4E
B406   68                       PLA
B407   85 4F                    STA $4F
B409   A0 02                    LDY #$02
B40B   B1 4E                    LDA ($4E),Y
B40D   85 47                    STA $47
B40F   AA                       TAX
B410   C8                       INY
B411   B1 4E                    LDA ($4E),Y
B413   F0 99                    BEQ LB3AE
B415   85 48                    STA $48
B417   C8                       INY
B418   B1 47      LB418         LDA ($47),Y
B41A   48                       PHA
B41B   88                       DEY
B41C   10 FA                    BPL LB418
B41E   A4 48                    LDY $48
B420   20 D4 BB                 JSR LBBD4
B423   A5 7B                    LDA $7B
B425   48                       PHA
B426   A5 7A                    LDA $7A
B428   48                       PHA
B429   B1 4E                    LDA ($4E),Y
B42B   85 7A                    STA $7A
B42D   C8                       INY
B42E   B1 4E                    LDA ($4E),Y
B430   85 7B                    STA $7B
B432   A5 48                    LDA $48
B434   48                       PHA
B435   A5 47                    LDA $47
B437   48                       PHA
B438   20 8A AD                 JSR LAD8A
B43B   68                       PLA
B43C   85 4E                    STA $4E
B43E   68                       PLA
B43F   85 4F                    STA $4F
B441   20 79 00                 JSR $0079
B444   F0 03                    BEQ LB449
B446   4C 08 AF                 JMP LAF08
B449   68         LB449         PLA
B44A   85 7A                    STA $7A
B44C   68                       PLA
B44D   85 7B                    STA $7B
B44F   A0 00      LB44F         LDY #$00
B451   68                       PLA
B452   91 4E                    STA ($4E),Y
B454   68                       PLA
B455   C8                       INY
B456   91 4E                    STA ($4E),Y
B458   68                       PLA
B459   C8                       INY
B45A   91 4E                    STA ($4E),Y
B45C   68                       PLA
B45D   C8                       INY
B45E   91 4E                    STA ($4E),Y
B460   68                       PLA
B461   C8                       INY
B462   91 4E                    STA ($4E),Y
B464   60                       RTS
B465   20 8D AD                 JSR LAD8D
B468   A0 00                    LDY #$00
B46A   20 DF BD                 JSR LBDDF
B46D   68                       PLA
B46E   68                       PLA
B46F   A9 FF      LB46F         LDA #$FF
B471   A0 00                    LDY #$00
B473   F0 12                    BEQ LB487
B475   A6 64      LB475         LDX $64
B477   A4 65                    LDY $65
B479   86 50                    STX $50
B47B   84 51                    STY $51
B47D   20 F4 B4   LB47D         JSR LB4F4
B480   86 62                    STX $62
B482   84 63                    STY $63
B484   85 61                    STA $61
B486   60                       RTS
B487   A2 22      LB487         LDX #$22
B489   86 07                    STX $07
B48B   86 08                    STX $08
B48D   85 6F      LB48D         STA $6F
B48F   84 70                    STY $70
B491   85 62                    STA $62
B493   84 63                    STY $63
B495   A0 FF                    LDY #$FF
B497   C8         LB497         INY
B498   B1 6F                    LDA ($6F),Y
B49A   F0 0C                    BEQ LB4A8
B49C   C5 07                    CMP $07
B49E   F0 04                    BEQ LB4A4
B4A0   C5 08                    CMP $08
B4A2   D0 F3                    BNE LB497
B4A4   C9 22      LB4A4         CMP #$22
B4A6   F0 01                    BEQ LB4A9
B4A8   18         LB4A8         CLC
B4A9   84 61      LB4A9         STY $61
B4AB   98                       TYA
B4AC   65 6F                    ADC $6F
B4AE   85 71                    STA $71
B4B0   A6 70                    LDX $70
B4B2   90 01                    BCC LB4B5
B4B4   E8                       INX
B4B5   86 72      LB4B5         STX $72
B4B7   A5 70                    LDA $70
B4B9   F0 04                    BEQ LB4BF
B4BB   C9 02                    CMP #$02
B4BD   D0 0B                    BNE LB4CA
B4BF   98         LB4BF         TYA
B4C0   20 75 B4                 JSR LB475
B4C3   A6 6F                    LDX $6F
B4C5   A4 70                    LDY $70
B4C7   20 88 B6                 JSR LB688
B4CA   A6 16      LB4CA         LDX $16
B4CC   E0 22                    CPX #$22
B4CE   D0 05                    BNE LB4D5
B4D0   A2 19                    LDX #$19
B4D2   4C 37 A4   LB4D2         JMP LA437
B4D5   A5 61      LB4D5         LDA $61
B4D7   95 00                    STA $00,X
B4D9   A5 62                    LDA $62
B4DB   95 01                    STA $01,X
B4DD   A5 63                    LDA $63
B4DF   95 02                    STA $02,X
B4E1   A0 00                    LDY #$00
B4E3   86 64                    STX $64
B4E5   84 65                    STY $65
B4E7   84 70                    STY $70
B4E9   88                       DEY
B4EA   84 0D                    STY $0D
B4EC   86 17                    STX $17
B4EE   E8                       INX
B4EF   E8                       INX
B4F0   E8                       INX
B4F1   86 16                    STX $16
B4F3   60                       RTS
B4F4   46 0F      LB4F4         LSR $0F
B4F6   48         LB4F6         PHA
B4F7   49 FF                    EOR #$FF
B4F9   38                       SEC
B4FA   65 33                    ADC $33
B4FC   A4 34                    LDY $34
B4FE   B0 01                    BCS LB501
B500   88                       DEY
B501   C4 32      LB501         CPY $32
B503   90 11                    BCC LB516
B505   D0 04                    BNE LB50B
B507   C5 31                    CMP $31
B509   90 0B                    BCC LB516
B50B   85 33      LB50B         STA $33
B50D   84 34                    STY $34
B50F   85 35                    STA $35
B511   84 36                    STY $36
B513   AA                       TAX
B514   68                       PLA
B515   60                       RTS
B516   A2 10      LB516         LDX #$10
B518   A5 0F                    LDA $0F
B51A   30 B6                    BMI LB4D2
B51C   20 26 B5                 JSR LB526
B51F   A9 80                    LDA #$80
B521   85 0F                    STA $0F
B523   68                       PLA
B524   D0 D0                    BNE LB4F6
B526   A6 37      LB526         LDX $37
B528   A5 38                    LDA $38
B52A   86 33      LB52A         STX $33
B52C   85 34                    STA $34
B52E   A0 00                    LDY #$00
B530   84 4F                    STY $4F
B532   84 4E                    STY $4E
B534   A5 31                    LDA $31
B536   A6 32                    LDX $32
B538   85 5F                    STA $5F
B53A   86 60                    STX $60
B53C   A9 19                    LDA #$19
B53E   A2 00                    LDX #$00
B540   85 22                    STA $22
B542   86 23                    STX $23
B544   C5 16      LB544         CMP $16
B546   F0 05                    BEQ LB54D
B548   20 C7 B5                 JSR LB5C7
B54B   F0 F7                    BEQ LB544
B54D   A9 07      LB54D         LDA #$07
B54F   85 53                    STA $53
B551   A5 2D                    LDA $2D
B553   A6 2E                    LDX $2E
B555   85 22                    STA $22
B557   86 23                    STX $23
B559   E4 30      LB559         CPX $30
B55B   D0 04                    BNE LB561
B55D   C5 2F                    CMP $2F
B55F   F0 05                    BEQ LB566
B561   20 BD B5   LB561         JSR LB5BD
B564   F0 F3                    BEQ LB559
B566   85 58      LB566         STA $58
B568   86 59                    STX $59
B56A   A9 03                    LDA #$03
B56C   85 53                    STA $53
B56E   A5 58      LB56E         LDA $58
B570   A6 59                    LDX $59
B572   E4 32      LB572         CPX $32
B574   D0 07                    BNE LB57D
B576   C5 31                    CMP $31
B578   D0 03                    BNE LB57D
B57A   4C 06 B6                 JMP LB606
B57D   85 22      LB57D         STA $22
B57F   86 23                    STX $23
B581   A0 00                    LDY #$00
B583   B1 22                    LDA ($22),Y
B585   AA                       TAX
B586   C8                       INY
B587   B1 22                    LDA ($22),Y
B589   08                       PHP
B58A   C8                       INY
B58B   B1 22                    LDA ($22),Y
B58D   65 58                    ADC $58
B58F   85 58                    STA $58
B591   C8                       INY
B592   B1 22                    LDA ($22),Y
B594   65 59                    ADC $59
B596   85 59                    STA $59
B598   28                       PLP
B599   10 D3                    BPL LB56E
B59B   8A                       TXA
B59C   30 D0                    BMI LB56E
B59E   C8                       INY
B59F   B1 22                    LDA ($22),Y
B5A1   A0 00                    LDY #$00
B5A3   0A                       ASL A
B5A4   69 05                    ADC #$05
B5A6   65 22                    ADC $22
B5A8   85 22                    STA $22
B5AA   90 02                    BCC LB5AE
B5AC   E6 23                    INC $23
B5AE   A6 23      LB5AE         LDX $23
B5B0   E4 59      LB5B0         CPX $59
B5B2   D0 04                    BNE LB5B8
B5B4   C5 58                    CMP $58
B5B6   F0 BA                    BEQ LB572
B5B8   20 C7 B5   LB5B8         JSR LB5C7
B5BB   F0 F3                    BEQ LB5B0
B5BD   B1 22      LB5BD         LDA ($22),Y
B5BF   30 35                    BMI LB5F6
B5C1   C8                       INY
B5C2   B1 22                    LDA ($22),Y
B5C4   10 30                    BPL LB5F6
B5C6   C8                       INY
B5C7   B1 22      LB5C7         LDA ($22),Y
B5C9   F0 2B                    BEQ LB5F6
B5CB   C8                       INY
B5CC   B1 22                    LDA ($22),Y
B5CE   AA                       TAX
B5CF   C8                       INY
B5D0   B1 22                    LDA ($22),Y
B5D2   C5 34                    CMP $34
B5D4   90 06                    BCC LB5DC
B5D6   D0 1E                    BNE LB5F6
B5D8   E4 33                    CPX $33
B5DA   B0 1A                    BCS LB5F6
B5DC   C5 60      LB5DC         CMP $60
B5DE   90 16                    BCC LB5F6
B5E0   D0 04                    BNE LB5E6
B5E2   E4 5F                    CPX $5F
B5E4   90 10                    BCC LB5F6
B5E6   86 5F      LB5E6         STX $5F
B5E8   85 60                    STA $60
B5EA   A5 22                    LDA $22
B5EC   A6 23                    LDX $23
B5EE   85 4E                    STA $4E
B5F0   86 4F                    STX $4F
B5F2   A5 53                    LDA $53
B5F4   85 55                    STA $55
B5F6   A5 53      LB5F6         LDA $53
B5F8   18                       CLC
B5F9   65 22                    ADC $22
B5FB   85 22                    STA $22
B5FD   90 02                    BCC LB601
B5FF   E6 23                    INC $23
B601   A6 23      LB601         LDX $23
B603   A0 00                    LDY #$00
B605   60                       RTS
B606   A5 4F      LB606         LDA $4F
B608   05 4E                    ORA $4E
B60A   F0 F5                    BEQ LB601
B60C   A5 55                    LDA $55
B60E   29 04                    AND #$04
B610   4A                       LSR A
B611   A8                       TAY
B612   85 55                    STA $55
B614   B1 4E                    LDA ($4E),Y
B616   65 5F                    ADC $5F
B618   85 5A                    STA $5A
B61A   A5 60                    LDA $60
B61C   69 00                    ADC #$00
B61E   85 5B                    STA $5B
B620   A5 33                    LDA $33
B622   A6 34                    LDX $34
B624   85 58                    STA $58
B626   86 59                    STX $59
B628   20 BF A3                 JSR LA3BF
B62B   A4 55                    LDY $55
B62D   C8                       INY
B62E   A5 58                    LDA $58
B630   91 4E                    STA ($4E),Y
B632   AA                       TAX
B633   E6 59                    INC $59
B635   A5 59                    LDA $59
B637   C8                       INY
B638   91 4E                    STA ($4E),Y
B63A   4C 2A B5                 JMP LB52A
B63D   A5 65      LB63D         LDA $65
B63F   48                       PHA
B640   A5 64                    LDA $64
B642   48                       PHA
B643   20 83 AE                 JSR LAE83
B646   20 8F AD                 JSR LAD8F
B649   68                       PLA
B64A   85 6F                    STA $6F
B64C   68                       PLA
B64D   85 70                    STA $70
B64F   A0 00                    LDY #$00
B651   B1 6F                    LDA ($6F),Y
B653   18                       CLC
B654   71 64                    ADC ($64),Y
B656   90 05                    BCC LB65D
B658   A2 17                    LDX #$17
B65A   4C 37 A4                 JMP LA437
B65D   20 75 B4   LB65D         JSR LB475
B660   20 7A B6                 JSR LB67A
B663   A5 50                    LDA $50
B665   A4 51                    LDY $51
B667   20 AA B6                 JSR LB6AA
B66A   20 8C B6                 JSR LB68C
B66D   A5 6F                    LDA $6F
B66F   A4 70                    LDY $70
B671   20 AA B6                 JSR LB6AA
B674   20 CA B4                 JSR LB4CA
B677   4C B8 AD                 JMP LADB8
B67A   A0 00      LB67A         LDY #$00
B67C   B1 6F                    LDA ($6F),Y
B67E   48                       PHA
B67F   C8                       INY
B680   B1 6F                    LDA ($6F),Y
B682   AA                       TAX
B683   C8                       INY
B684   B1 6F                    LDA ($6F),Y
B686   A8                       TAY
B687   68                       PLA
B688   86 22      LB688         STX $22
B68A   84 23                    STY $23
B68C   A8         LB68C         TAY
B68D   F0 0A                    BEQ LB699
B68F   48                       PHA
B690   88         LB690         DEY
B691   B1 22                    LDA ($22),Y
B693   91 35                    STA ($35),Y
B695   98                       TYA
B696   D0 F8                    BNE LB690
B698   68                       PLA
B699   18         LB699         CLC
B69A   65 35                    ADC $35
B69C   85 35                    STA $35
B69E   90 02                    BCC LB6A2
B6A0   E6 36                    INC $36
B6A2   60         LB6A2         RTS
B6A3   20 8F AD   LB6A3         JSR LAD8F
B6A6   A5 64      LB6A6         LDA $64
B6A8   A4 65                    LDY $65
B6AA   85 22      LB6AA         STA $22
B6AC   84 23                    STY $23
B6AE   20 DB B6                 JSR LB6DB
B6B1   08                       PHP
B6B2   A0 00                    LDY #$00
B6B4   B1 22                    LDA ($22),Y
B6B6   48                       PHA
B6B7   C8                       INY
B6B8   B1 22                    LDA ($22),Y
B6BA   AA                       TAX
B6BB   C8                       INY
B6BC   B1 22                    LDA ($22),Y
B6BE   A8                       TAY
B6BF   68                       PLA
B6C0   28                       PLP
B6C1   D0 13                    BNE LB6D6
B6C3   C4 34                    CPY $34
B6C5   D0 0F                    BNE LB6D6
B6C7   E4 33                    CPX $33
B6C9   D0 0B                    BNE LB6D6
B6CB   48                       PHA
B6CC   18                       CLC
B6CD   65 33                    ADC $33
B6CF   85 33                    STA $33
B6D1   90 02                    BCC LB6D5
B6D3   E6 34                    INC $34
B6D5   68         LB6D5         PLA
B6D6   86 22      LB6D6         STX $22
B6D8   84 23                    STY $23
B6DA   60                       RTS
B6DB   C4 18      LB6DB         CPY $18
B6DD   D0 0C                    BNE LB6EB
B6DF   C5 17                    CMP $17
B6E1   D0 08                    BNE LB6EB
B6E3   85 16                    STA $16
B6E5   E9 03                    SBC #$03
B6E7   85 17                    STA $17
B6E9   A0 00                    LDY #$00
B6EB   60         LB6EB         RTS
B6EC   20 A1 B7                 JSR LB7A1
B6EF   8A                       TXA
B6F0   48                       PHA
B6F1   A9 01                    LDA #$01
B6F3   20 7D B4                 JSR LB47D
B6F6   68                       PLA
B6F7   A0 00                    LDY #$00
B6F9   91 62                    STA ($62),Y
B6FB   68                       PLA
B6FC   68                       PLA
B6FD   4C CA B4                 JMP LB4CA
B700   20 61 B7                 JSR LB761
B703   D1 50                    CMP ($50),Y
B705   98                       TYA
B706   90 04      LB706         BCC LB70C
B708   B1 50                    LDA ($50),Y
B70A   AA                       TAX
B70B   98                       TYA
B70C   48         LB70C         PHA
B70D   8A         LB70D         TXA
B70E   48         LB70E         PHA
B70F   20 7D B4                 JSR LB47D
B712   A5 50                    LDA $50
B714   A4 51                    LDY $51
B716   20 AA B6                 JSR LB6AA
B719   68                       PLA
B71A   A8                       TAY
B71B   68                       PLA
B71C   18                       CLC
B71D   65 22                    ADC $22
B71F   85 22                    STA $22
B721   90 02                    BCC LB725
B723   E6 23                    INC $23
B725   98         LB725         TYA
B726   20 8C B6                 JSR LB68C
B729   4C CA B4                 JMP LB4CA
B72C   20 61 B7                 JSR LB761
B72F   18                       CLC
B730   F1 50                    SBC ($50),Y
B732   49 FF                    EOR #$FF
B734   4C 06 B7                 JMP LB706
B737   A9 FF                    LDA #$FF
B739   85 65                    STA $65
B73B   20 79 00                 JSR $0079
B73E   C9 29                    CMP #$29
B740   F0 06                    BEQ LB748
B742   20 FD AE                 JSR LAEFD
B745   20 9E B7                 JSR LB79E
B748   20 61 B7   LB748         JSR LB761
B74B   F0 4B                    BEQ LB798
B74D   CA                       DEX
B74E   8A                       TXA
B74F   48                       PHA
B750   18                       CLC
B751   A2 00                    LDX #$00
B753   F1 50                    SBC ($50),Y
B755   B0 B6                    BCS LB70D
B757   49 FF                    EOR #$FF
B759   C5 65                    CMP $65
B75B   90 B1                    BCC LB70E
B75D   A5 65                    LDA $65
B75F   B0 AD                    BCS LB70E
B761   20 F7 AE   LB761         JSR LAEF7
B764   68                       PLA
B765   A8                       TAY
B766   68                       PLA
B767   85 55                    STA $55
B769   68                       PLA
B76A   68                       PLA
B76B   68                       PLA
B76C   AA                       TAX
B76D   68                       PLA
B76E   85 50                    STA $50
B770   68                       PLA
B771   85 51                    STA $51
B773   A5 55                    LDA $55
B775   48                       PHA
B776   98                       TYA
B777   48                       PHA
B778   A0 00                    LDY #$00
B77A   8A                       TXA
B77B   60                       RTS
B77C   20 82 B7                 JSR LB782
B77F   4C A2 B3                 JMP LB3A2
B782   20 A3 B6   LB782         JSR LB6A3
B785   A2 00                    LDX #$00
B787   86 0D                    STX $0D
B789   A8                       TAY
B78A   60                       RTS
B78B   20 82 B7                 JSR LB782
B78E   F0 08                    BEQ LB798
B790   A0 00                    LDY #$00
B792   B1 22                    LDA ($22),Y
B794   A8                       TAY
B795   4C A2 B3                 JMP LB3A2
B798   4C 48 B2   LB798         JMP LB248
B79B   20 73 00   LB79B         JSR $0073
B79E   20 8A AD   LB79E         JSR LAD8A
B7A1   20 B8 B1   LB7A1         JSR LB1B8
B7A4   A6 64                    LDX $64
B7A6   D0 F0                    BNE LB798
B7A8   A6 65                    LDX $65
B7AA   4C 79 00                 JMP $0079
B7AD   20 82 B7                 JSR LB782
B7B0   D0 03                    BNE LB7B5
B7B2   4C F7 B8                 JMP LB8F7
B7B5   A6 7A      LB7B5         LDX $7A
B7B7   A4 7B                    LDY $7B
B7B9   86 71                    STX $71
B7BB   84 72                    STY $72
B7BD   A6 22                    LDX $22
B7BF   86 7A                    STX $7A
B7C1   18                       CLC
B7C2   65 22                    ADC $22
B7C4   85 24                    STA $24
B7C6   A6 23                    LDX $23
B7C8   86 7B                    STX $7B
B7CA   90 01                    BCC LB7CD
B7CC   E8                       INX
B7CD   86 25      LB7CD         STX $25
B7CF   A0 00                    LDY #$00
B7D1   B1 24                    LDA ($24),Y
B7D3   48                       PHA
B7D4   98                       TYA
B7D5   91 24                    STA ($24),Y
B7D7   20 79 00                 JSR $0079
B7DA   20 F3 BC                 JSR LBCF3
B7DD   68                       PLA
B7DE   A0 00                    LDY #$00
B7E0   91 24                    STA ($24),Y
B7E2   A6 71      LB7E2         LDX $71
B7E4   A4 72                    LDY $72
B7E6   86 7A                    STX $7A
B7E8   84 7B                    STY $7B
B7EA   60                       RTS
B7EB   20 8A AD   LB7EB         JSR LAD8A
B7EE   20 F7 B7                 JSR LB7F7
B7F1   20 FD AE   LB7F1         JSR LAEFD
B7F4   4C 9E B7                 JMP LB79E
B7F7   A5 66      LB7F7         LDA $66
B7F9   30 9D                    BMI LB798
B7FB   A5 61                    LDA $61
B7FD   C9 91                    CMP #$91
B7FF   B0 97                    BCS LB798
B801   20 9B BC                 JSR LBC9B
B804   A5 64                    LDA $64
B806   A4 65                    LDY $65
B808   84 14                    STY $14
B80A   85 15                    STA $15
B80C   60                       RTS
B80D   A5 15                    LDA $15
B80F   48                       PHA
B810   A5 14                    LDA $14
B812   48                       PHA
B813   20 F7 B7                 JSR LB7F7
B816   A0 00                    LDY #$00
B818   B1 14                    LDA ($14),Y
B81A   A8                       TAY
B81B   68                       PLA
B81C   85 14                    STA $14
B81E   68                       PLA
B81F   85 15                    STA $15
B821   4C A2 B3                 JMP LB3A2
B824   20 EB B7                 JSR LB7EB
B827   8A                       TXA
B828   A0 00                    LDY #$00
B82A   91 14                    STA ($14),Y
B82C   60                       RTS
B82D   20 EB B7                 JSR LB7EB
B830   86 49                    STX $49
B832   A2 00                    LDX #$00
B834   20 79 00                 JSR $0079
B837   F0 03                    BEQ LB83C
B839   20 F1 B7                 JSR LB7F1
B83C   86 4A      LB83C         STX $4A
B83E   A0 00                    LDY #$00
B840   B1 14      LB840         LDA ($14),Y
B842   45 4A                    EOR $4A
B844   25 49                    AND $49
B846   F0 F8                    BEQ LB840
B848   60         LB848         RTS
B849   A9 11      LB849         LDA #$11
B84B   A0 BF                    LDY #$BF
B84D   4C 67 B8                 JMP LB867
B850   20 8C BA   LB850         JSR LBA8C
B853   A5 66                    LDA $66
B855   49 FF                    EOR #$FF
B857   85 66                    STA $66
B859   45 6E                    EOR $6E
B85B   85 6F                    STA $6F
B85D   A5 61                    LDA $61
B85F   4C 6A B8                 JMP LB86A
B862   20 99 B9   LB862         JSR LB999
B865   90 3C                    BCC LB8A3
B867   20 8C BA   LB867         JSR LBA8C
B86A   D0 03      LB86A         BNE LB86F
B86C   4C FC BB                 JMP LBBFC
B86F   A6 70      LB86F         LDX $70
B871   86 56                    STX $56
B873   A2 69                    LDX #$69
B875   A5 69                    LDA $69
B877   A8         LB877         TAY
B878   F0 CE                    BEQ LB848
B87A   38                       SEC
B87B   E5 61                    SBC $61
B87D   F0 24                    BEQ LB8A3
B87F   90 12                    BCC LB893
B881   84 61                    STY $61
B883   A4 6E                    LDY $6E
B885   84 66                    STY $66
B887   49 FF                    EOR #$FF
B889   69 00                    ADC #$00
B88B   A0 00                    LDY #$00
B88D   84 56                    STY $56
B88F   A2 61                    LDX #$61
B891   D0 04                    BNE LB897
B893   A0 00      LB893         LDY #$00
B895   84 70                    STY $70
B897   C9 F9      LB897         CMP #$F9
B899   30 C7                    BMI LB862
B89B   A8                       TAY
B89C   A5 70                    LDA $70
B89E   56 01                    LSR $01,X
B8A0   20 B0 B9                 JSR LB9B0
B8A3   24 6F      LB8A3         BIT $6F
B8A5   10 57                    BPL LB8FE
B8A7   A0 61                    LDY #$61
B8A9   E0 69                    CPX #$69
B8AB   F0 02                    BEQ LB8AF
B8AD   A0 69                    LDY #$69
B8AF   38         LB8AF         SEC
B8B0   49 FF                    EOR #$FF
B8B2   65 56                    ADC $56
B8B4   85 70                    STA $70
B8B6   B9 04 00                 LDA $0004,Y
B8B9   F5 04                    SBC $04,X
B8BB   85 65                    STA $65
B8BD   B9 03 00                 LDA $0003,Y
B8C0   F5 03                    SBC $03,X
B8C2   85 64                    STA $64
B8C4   B9 02 00                 LDA $0002,Y
B8C7   F5 02                    SBC $02,X
B8C9   85 63                    STA $63
B8CB   B9 01 00                 LDA $0001,Y
B8CE   F5 01                    SBC $01,X
B8D0   85 62                    STA $62
B8D2   B0 03      LB8D2         BCS LB8D7
B8D4   20 47 B9                 JSR LB947
B8D7   A0 00      LB8D7         LDY #$00
B8D9   98                       TYA
B8DA   18                       CLC
B8DB   A6 62      LB8DB         LDX $62
B8DD   D0 4A                    BNE LB929
B8DF   A6 63                    LDX $63
B8E1   86 62                    STX $62
B8E3   A6 64                    LDX $64
B8E5   86 63                    STX $63
B8E7   A6 65                    LDX $65
B8E9   86 64                    STX $64
B8EB   A6 70                    LDX $70
B8ED   86 65                    STX $65
B8EF   84 70                    STY $70
B8F1   69 08                    ADC #$08
B8F3   C9 20                    CMP #$20
B8F5   D0 E4                    BNE LB8DB
B8F7   A9 00      LB8F7         LDA #$00
B8F9   85 61      LB8F9         STA $61
B8FB   85 66      LB8FB         STA $66
B8FD   60                       RTS
B8FE   65 56      LB8FE         ADC $56
B900   85 70                    STA $70
B902   A5 65                    LDA $65
B904   65 6D                    ADC $6D
B906   85 65                    STA $65
B908   A5 64                    LDA $64
B90A   65 6C                    ADC $6C
B90C   85 64                    STA $64
B90E   A5 63                    LDA $63
B910   65 6B                    ADC $6B
B912   85 63                    STA $63
B914   A5 62                    LDA $62
B916   65 6A                    ADC $6A
B918   85 62                    STA $62
B91A   4C 36 B9                 JMP LB936
B91D   69 01      LB91D         ADC #$01
B91F   06 70                    ASL $70
B921   26 65                    ROL $65
B923   26 64                    ROL $64
B925   26 63                    ROL $63
B927   26 62                    ROL $62
B929   10 F2      LB929         BPL LB91D
B92B   38                       SEC
B92C   E5 61                    SBC $61
B92E   B0 C7                    BCS LB8F7
B930   49 FF                    EOR #$FF
B932   69 01                    ADC #$01
B934   85 61                    STA $61
B936   90 0E      LB936         BCC LB946
B938   E6 61      LB938         INC $61
B93A   F0 42                    BEQ LB97E
B93C   66 62                    ROR $62
B93E   66 63                    ROR $63
B940   66 64                    ROR $64
B942   66 65                    ROR $65
B944   66 70                    ROR $70
B946   60         LB946         RTS
B947   A5 66      LB947         LDA $66
B949   49 FF                    EOR #$FF
B94B   85 66                    STA $66
B94D   A5 62      LB94D         LDA $62
B94F   49 FF                    EOR #$FF
B951   85 62                    STA $62
B953   A5 63                    LDA $63
B955   49 FF                    EOR #$FF
B957   85 63                    STA $63
B959   A5 64                    LDA $64
B95B   49 FF                    EOR #$FF
B95D   85 64                    STA $64
B95F   A5 65                    LDA $65
B961   49 FF                    EOR #$FF
B963   85 65                    STA $65
B965   A5 70                    LDA $70
B967   49 FF                    EOR #$FF
B969   85 70                    STA $70
B96B   E6 70                    INC $70
B96D   D0 0E                    BNE LB97D
B96F   E6 65      LB96F         INC $65
B971   D0 0A                    BNE LB97D
B973   E6 64                    INC $64
B975   D0 06                    BNE LB97D
B977   E6 63                    INC $63
B979   D0 02                    BNE LB97D
B97B   E6 62                    INC $62
B97D   60         LB97D         RTS
B97E   A2 0F      LB97E         LDX #$0F
B980   4C 37 A4                 JMP LA437
B983   A2 25      LB983         LDX #$25
B985   B4 04      LB985         LDY $04,X
B987   84 70                    STY $70
B989   B4 03                    LDY $03,X
B98B   94 04                    STY $04,X
B98D   B4 02                    LDY $02,X
B98F   94 03                    STY $03,X
B991   B4 01                    LDY $01,X
B993   94 02                    STY $02,X
B995   A4 68                    LDY $68
B997   94 01                    STY $01,X
B999   69 08      LB999         ADC #$08
B99B   30 E8                    BMI LB985
B99D   F0 E6                    BEQ LB985
B99F   E9 08                    SBC #$08
B9A1   A8                       TAY
B9A2   A5 70                    LDA $70
B9A4   B0 14                    BCS LB9BA
B9A6   16 01      LB9A6         ASL $01,X
B9A8   90 02                    BCC LB9AC
B9AA   F6 01                    INC $01,X
B9AC   76 01      LB9AC         ROR $01,X
B9AE   76 01                    ROR $01,X
B9B0   76 02      LB9B0         ROR $02,X
B9B2   76 03                    ROR $03,X
B9B4   76 04                    ROR $04,X
B9B6   6A                       ROR A
B9B7   C8                       INY
B9B8   D0 EC                    BNE LB9A6
B9BA   18         LB9BA         CLC
B9BB   60                       RTS
B9BC   81 00                    STA ($00,X)
B9BE   00                       BRK
B9BF   00                       BRK
B9C0   00                       BRK
B9C1   03                       ???               ;%00000011
B9C2   7F                       ???               ;%01111111
B9C3   5E 56 CB                 LSR $CB56,X
B9C6   79 80 13                 ADC $1380,Y
B9C9   9B                       ???               ;%10011011
B9CA   0B                       ???               ;%00001011
B9CB   64                       ???               ;%01100100 'd'
B9CC   80                       ???               ;%10000000
B9CD   76 38                    ROR $38,X
B9CF   93                       ???               ;%10010011
B9D0   16 82                    ASL $82,X
B9D2   38                       SEC
B9D3   AA                       TAX
B9D4   3B                       ???               ;%00111011 ';'
B9D5   20 80 35                 JSR $3580
B9D8   04                       ???               ;%00000100
B9D9   F3                       ???               ;%11110011
B9DA   34                       ???               ;%00110100 '4'
B9DB   81 35                    STA ($35,X)
B9DD   04                       ???               ;%00000100
B9DE   F3                       ???               ;%11110011
B9DF   34                       ???               ;%00110100 '4'
B9E0   80                       ???               ;%10000000
B9E1   80                       ???               ;%10000000
B9E2   00                       BRK
B9E3   00                       BRK
B9E4   00                       BRK
B9E5   80                       ???               ;%10000000
B9E6   31 72                    AND ($72),Y
B9E8   17                       ???               ;%00010111
B9E9   F8                       SED
B9EA   20 2B BC   LB9EA         JSR LBC2B
B9ED   F0 02                    BEQ LB9F1
B9EF   10 03                    BPL LB9F4
B9F1   4C 48 B2   LB9F1         JMP LB248
B9F4   A5 61      LB9F4         LDA $61
B9F6   E9 7F                    SBC #$7F
B9F8   48                       PHA
B9F9   A9 80                    LDA #$80
B9FB   85 61                    STA $61
B9FD   A9 D6                    LDA #$D6
B9FF   A0 B9                    LDY #$B9
BA01   20 67 B8                 JSR LB867
BA04   A9 DB                    LDA #$DB
BA06   A0 B9                    LDY #$B9
BA08   20 0F BB                 JSR LBB0F
BA0B   A9 BC                    LDA #$BC
BA0D   A0 B9                    LDY #$B9
BA0F   20 50 B8                 JSR LB850
BA12   A9 C1                    LDA #$C1
BA14   A0 B9                    LDY #$B9
BA16   20 43 E0                 JSR $E043
BA19   A9 E0                    LDA #$E0
BA1B   A0 B9                    LDY #$B9
BA1D   20 67 B8                 JSR LB867
BA20   68                       PLA
BA21   20 7E BD                 JSR LBD7E
BA24   A9 E5                    LDA #$E5
BA26   A0 B9                    LDY #$B9
BA28   20 8C BA   LBA28         JSR LBA8C
BA2B   D0 03                    BNE LBA30
BA2D   4C 8B BA                 JMP LBA8B
BA30   20 B7 BA   LBA30         JSR LBAB7
BA33   A9 00                    LDA #$00
BA35   85 26                    STA $26
BA37   85 27                    STA $27
BA39   85 28                    STA $28
BA3B   85 29                    STA $29
BA3D   A5 70                    LDA $70
BA3F   20 59 BA                 JSR LBA59
BA42   A5 65                    LDA $65
BA44   20 59 BA                 JSR LBA59
BA47   A5 64                    LDA $64
BA49   20 59 BA                 JSR LBA59
BA4C   A5 63                    LDA $63
BA4E   20 59 BA                 JSR LBA59
BA51   A5 62                    LDA $62
BA53   20 5E BA                 JSR LBA5E
BA56   4C 8F BB                 JMP LBB8F
BA59   D0 03      LBA59         BNE LBA5E
BA5B   4C 83 B9                 JMP LB983
BA5E   4A         LBA5E         LSR A
BA5F   09 80                    ORA #$80
BA61   A8         LBA61         TAY
BA62   90 19                    BCC LBA7D
BA64   18                       CLC
BA65   A5 29                    LDA $29
BA67   65 6D                    ADC $6D
BA69   85 29                    STA $29
BA6B   A5 28                    LDA $28
BA6D   65 6C                    ADC $6C
BA6F   85 28                    STA $28
BA71   A5 27                    LDA $27
BA73   65 6B                    ADC $6B
BA75   85 27                    STA $27
BA77   A5 26                    LDA $26
BA79   65 6A                    ADC $6A
BA7B   85 26                    STA $26
BA7D   66 26      LBA7D         ROR $26
BA7F   66 27                    ROR $27
BA81   66 28                    ROR $28
BA83   66 29                    ROR $29
BA85   66 70                    ROR $70
BA87   98                       TYA
BA88   4A                       LSR A
BA89   D0 D6                    BNE LBA61
BA8B   60         LBA8B         RTS
BA8C   85 22      LBA8C         STA $22
BA8E   84 23                    STY $23
BA90   A0 04                    LDY #$04
BA92   B1 22                    LDA ($22),Y
BA94   85 6D                    STA $6D
BA96   88                       DEY
BA97   B1 22                    LDA ($22),Y
BA99   85 6C                    STA $6C
BA9B   88                       DEY
BA9C   B1 22                    LDA ($22),Y
BA9E   85 6B                    STA $6B
BAA0   88                       DEY
BAA1   B1 22                    LDA ($22),Y
BAA3   85 6E                    STA $6E
BAA5   45 66                    EOR $66
BAA7   85 6F                    STA $6F
BAA9   A5 6E                    LDA $6E
BAAB   09 80                    ORA #$80
BAAD   85 6A                    STA $6A
BAAF   88                       DEY
BAB0   B1 22                    LDA ($22),Y
BAB2   85 69                    STA $69
BAB4   A5 61                    LDA $61
BAB6   60                       RTS
BAB7   A5 69      LBAB7         LDA $69
BAB9   F0 1F                    BEQ LBADA
BABB   18                       CLC
BABC   65 61                    ADC $61
BABE   90 04                    BCC LBAC4
BAC0   30 1D                    BMI LBADF
BAC2   18                       CLC
BAC3   2C 10 14                 BIT $1410
BAC6   69 80                    ADC #$80
BAC8   85 61                    STA $61
BACA   D0 03                    BNE LBACF
BACC   4C FB B8                 JMP LB8FB
BACF   A5 6F      LBACF         LDA $6F
BAD1   85 66                    STA $66
BAD3   60                       RTS
BAD4   A5 66                    LDA $66
BAD6   49 FF                    EOR #$FF
BAD8   30 05                    BMI LBADF
BADA   68         LBADA         PLA
BADB   68                       PLA
BADC   4C F7 B8                 JMP LB8F7
BADF   4C 7E B9   LBADF         JMP LB97E
BAE2   20 0C BC   LBAE2         JSR LBC0C
BAE5   AA                       TAX
BAE6   F0 10                    BEQ LBAF8
BAE8   18                       CLC
BAE9   69 02                    ADC #$02
BAEB   B0 F2                    BCS LBADF
BAED   A2 00      LBAED         LDX #$00
BAEF   86 6F                    STX $6F
BAF1   20 77 B8                 JSR LB877
BAF4   E6 61                    INC $61
BAF6   F0 E7                    BEQ LBADF
BAF8   60         LBAF8         RTS
BAF9   84 20                    STY $20
BAFB   00                       BRK
BAFC   00                       BRK
BAFD   00                       BRK
BAFE   20 0C BC   LBAFE         JSR LBC0C
BB01   A9 F9                    LDA #$F9
BB03   A0 BA                    LDY #$BA
BB05   A2 00                    LDX #$00
BB07   86 6F                    STX $6F
BB09   20 A2 BB                 JSR LBBA2
BB0C   4C 12 BB                 JMP LBB12
BB0F   20 8C BA   LBB0F         JSR LBA8C
BB12   F0 76      LBB12         BEQ LBB8A
BB14   20 1B BC                 JSR LBC1B
BB17   A9 00                    LDA #$00
BB19   38                       SEC
BB1A   E5 61                    SBC $61
BB1C   85 61                    STA $61
BB1E   20 B7 BA                 JSR LBAB7
BB21   E6 61                    INC $61
BB23   F0 BA                    BEQ LBADF
BB25   A2 FC                    LDX #$FC
BB27   A9 01                    LDA #$01
BB29   A4 6A      LBB29         LDY $6A
BB2B   C4 62                    CPY $62
BB2D   D0 10                    BNE LBB3F
BB2F   A4 6B                    LDY $6B
BB31   C4 63                    CPY $63
BB33   D0 0A                    BNE LBB3F
BB35   A4 6C                    LDY $6C
BB37   C4 64                    CPY $64
BB39   D0 04                    BNE LBB3F
BB3B   A4 6D                    LDY $6D
BB3D   C4 65                    CPY $65
BB3F   08         LBB3F         PHP
BB40   2A                       ROL A
BB41   90 09                    BCC LBB4C
BB43   E8                       INX
BB44   95 29                    STA $29,X
BB46   F0 32                    BEQ LBB7A
BB48   10 34                    BPL LBB7E
BB4A   A9 01                    LDA #$01
BB4C   28         LBB4C         PLP
BB4D   B0 0E                    BCS LBB5D
BB4F   06 6D      LBB4F         ASL $6D
BB51   26 6C                    ROL $6C
BB53   26 6B                    ROL $6B
BB55   26 6A                    ROL $6A
BB57   B0 E6                    BCS LBB3F
BB59   30 CE                    BMI LBB29
BB5B   10 E2                    BPL LBB3F
BB5D   A8         LBB5D         TAY
BB5E   A5 6D                    LDA $6D
BB60   E5 65                    SBC $65
BB62   85 6D                    STA $6D
BB64   A5 6C                    LDA $6C
BB66   E5 64                    SBC $64
BB68   85 6C                    STA $6C
BB6A   A5 6B                    LDA $6B
BB6C   E5 63                    SBC $63
BB6E   85 6B                    STA $6B
BB70   A5 6A                    LDA $6A
BB72   E5 62                    SBC $62
BB74   85 6A                    STA $6A
BB76   98                       TYA
BB77   4C 4F BB                 JMP LBB4F
BB7A   A9 40      LBB7A         LDA #$40
BB7C   D0 CE                    BNE LBB4C
BB7E   0A         LBB7E         ASL A
BB7F   0A                       ASL A
BB80   0A                       ASL A
BB81   0A                       ASL A
BB82   0A                       ASL A
BB83   0A                       ASL A
BB84   85 70                    STA $70
BB86   28                       PLP
BB87   4C 8F BB                 JMP LBB8F
BB8A   A2 14      LBB8A         LDX #$14
BB8C   4C 37 A4                 JMP LA437
BB8F   A5 26      LBB8F         LDA $26
BB91   85 62                    STA $62
BB93   A5 27                    LDA $27
BB95   85 63                    STA $63
BB97   A5 28                    LDA $28
BB99   85 64                    STA $64
BB9B   A5 29                    LDA $29
BB9D   85 65                    STA $65
BB9F   4C D7 B8                 JMP LB8D7
BBA2   85 22      LBBA2         STA $22
BBA4   84 23                    STY $23
BBA6   A0 04                    LDY #$04
BBA8   B1 22                    LDA ($22),Y
BBAA   85 65                    STA $65
BBAC   88                       DEY
BBAD   B1 22                    LDA ($22),Y
BBAF   85 64                    STA $64
BBB1   88                       DEY
BBB2   B1 22                    LDA ($22),Y
BBB4   85 63                    STA $63
BBB6   88                       DEY
BBB7   B1 22                    LDA ($22),Y
BBB9   85 66                    STA $66
BBBB   09 80                    ORA #$80
BBBD   85 62                    STA $62
BBBF   88                       DEY
BBC0   B1 22                    LDA ($22),Y
BBC2   85 61                    STA $61
BBC4   84 70                    STY $70
BBC6   60                       RTS
BBC7   A2 5C                    LDX #$5C
BBC9   2C A2 57                 BIT $57A2
BBCC   A0 00                    LDY #$00
BBCE   F0 04                    BEQ LBBD4
BBD0   A6 49      LBBD0         LDX $49
BBD2   A4 4A                    LDY $4A
BBD4   20 1B BC   LBBD4         JSR LBC1B
BBD7   86 22                    STX $22
BBD9   84 23                    STY $23
BBDB   A0 04                    LDY #$04
BBDD   A5 65                    LDA $65
BBDF   91 22                    STA ($22),Y
BBE1   88                       DEY
BBE2   A5 64                    LDA $64
BBE4   91 22                    STA ($22),Y
BBE6   88                       DEY
BBE7   A5 63                    LDA $63
BBE9   91 22                    STA ($22),Y
BBEB   88                       DEY
BBEC   A5 66                    LDA $66
BBEE   09 7F                    ORA #$7F
BBF0   25 62                    AND $62
BBF2   91 22                    STA ($22),Y
BBF4   88                       DEY
BBF5   A5 61                    LDA $61
BBF7   91 22                    STA ($22),Y
BBF9   84 70                    STY $70
BBFB   60                       RTS
BBFC   A5 6E      LBBFC         LDA $6E
BBFE   85 66      LBBFE         STA $66
BC00   A2 05                    LDX #$05
BC02   B5 68      LBC02         LDA $68,X
BC04   95 60                    STA $60,X
BC06   CA                       DEX
BC07   D0 F9                    BNE LBC02
BC09   86 70                    STX $70
BC0B   60                       RTS
BC0C   20 1B BC   LBC0C         JSR LBC1B
BC0F   A2 06                    LDX #$06
BC11   B5 60      LBC11         LDA $60,X
BC13   95 68                    STA $68,X
BC15   CA                       DEX
BC16   D0 F9                    BNE LBC11
BC18   86 70                    STX $70
BC1A   60         LBC1A         RTS
BC1B   A5 61      LBC1B         LDA $61
BC1D   F0 FB                    BEQ LBC1A
BC1F   06 70                    ASL $70
BC21   90 F7                    BCC LBC1A
BC23   20 6F B9   LBC23         JSR LB96F
BC26   D0 F2                    BNE LBC1A
BC28   4C 38 B9                 JMP LB938
BC2B   A5 61      LBC2B         LDA $61
BC2D   F0 09                    BEQ LBC38
BC2F   A5 66      LBC2F         LDA $66
BC31   2A         LBC31         ROL A
BC32   A9 FF                    LDA #$FF
BC34   B0 02                    BCS LBC38
BC36   A9 01                    LDA #$01
BC38   60         LBC38         RTS
BC39   20 2B BC                 JSR LBC2B
BC3C   85 62      LBC3C         STA $62
BC3E   A9 00                    LDA #$00
BC40   85 63                    STA $63
BC42   A2 88                    LDX #$88
BC44   A5 62      LBC44         LDA $62
BC46   49 FF                    EOR #$FF
BC48   2A                       ROL A
BC49   A9 00      LBC49         LDA #$00
BC4B   85 65                    STA $65
BC4D   85 64                    STA $64
BC4F   86 61      LBC4F         STX $61
BC51   85 70                    STA $70
BC53   85 66                    STA $66
BC55   4C D2 B8                 JMP LB8D2
BC58   46 66                    LSR $66
BC5A   60                       RTS
BC5B   85 24      LBC5B         STA $24
BC5D   84 25      LBC5D         STY $25
BC5F   A0 00                    LDY #$00
BC61   B1 24                    LDA ($24),Y
BC63   C8                       INY
BC64   AA                       TAX
BC65   F0 C4                    BEQ LBC2B
BC67   B1 24                    LDA ($24),Y
BC69   45 66                    EOR $66
BC6B   30 C2                    BMI LBC2F
BC6D   E4 61                    CPX $61
BC6F   D0 21                    BNE LBC92
BC71   B1 24                    LDA ($24),Y
BC73   09 80                    ORA #$80
BC75   C5 62                    CMP $62
BC77   D0 19                    BNE LBC92
BC79   C8                       INY
BC7A   B1 24                    LDA ($24),Y
BC7C   C5 63                    CMP $63
BC7E   D0 12                    BNE LBC92
BC80   C8                       INY
BC81   B1 24                    LDA ($24),Y
BC83   C5 64                    CMP $64
BC85   D0 0B                    BNE LBC92
BC87   C8                       INY
BC88   A9 7F                    LDA #$7F
BC8A   C5 70                    CMP $70
BC8C   B1 24                    LDA ($24),Y
BC8E   E5 65                    SBC $65
BC90   F0 28                    BEQ LBCBA
BC92   A5 66      LBC92         LDA $66
BC94   90 02                    BCC LBC98
BC96   49 FF                    EOR #$FF
BC98   4C 31 BC   LBC98         JMP LBC31
BC9B   A5 61      LBC9B         LDA $61
BC9D   F0 4A                    BEQ LBCE9
BC9F   38                       SEC
BCA0   E9 A0                    SBC #$A0
BCA2   24 66                    BIT $66
BCA4   10 09                    BPL LBCAF
BCA6   AA                       TAX
BCA7   A9 FF                    LDA #$FF
BCA9   85 68                    STA $68
BCAB   20 4D B9                 JSR LB94D
BCAE   8A                       TXA
BCAF   A2 61      LBCAF         LDX #$61
BCB1   C9 F9                    CMP #$F9
BCB3   10 06                    BPL LBCBB
BCB5   20 99 B9                 JSR LB999
BCB8   84 68                    STY $68
BCBA   60         LBCBA         RTS
BCBB   A8         LBCBB         TAY
BCBC   A5 66                    LDA $66
BCBE   29 80                    AND #$80
BCC0   46 62                    LSR $62
BCC2   05 62                    ORA $62
BCC4   85 62                    STA $62
BCC6   20 B0 B9                 JSR LB9B0
BCC9   84 68                    STY $68
BCCB   60                       RTS
BCCC   A5 61      LBCCC         LDA $61
BCCE   C9 A0                    CMP #$A0
BCD0   B0 20                    BCS LBCF2
BCD2   20 9B BC                 JSR LBC9B
BCD5   84 70                    STY $70
BCD7   A5 66                    LDA $66
BCD9   84 66                    STY $66
BCDB   49 80                    EOR #$80
BCDD   2A                       ROL A
BCDE   A9 A0                    LDA #$A0
BCE0   85 61                    STA $61
BCE2   A5 65                    LDA $65
BCE4   85 07                    STA $07
BCE6   4C D2 B8                 JMP LB8D2
BCE9   85 62      LBCE9         STA $62
BCEB   85 63                    STA $63
BCED   85 64                    STA $64
BCEF   85 65                    STA $65
BCF1   A8                       TAY
BCF2   60         LBCF2         RTS
BCF3   A0 00      LBCF3         LDY #$00
BCF5   A2 0A                    LDX #$0A
BCF7   94 5D      LBCF7         STY $5D,X
BCF9   CA                       DEX
BCFA   10 FB                    BPL LBCF7
BCFC   90 0F                    BCC LBD0D
BCFE   C9 2D                    CMP #$2D
BD00   D0 04                    BNE LBD06
BD02   86 67                    STX $67
BD04   F0 04                    BEQ LBD0A
BD06   C9 2B      LBD06         CMP #$2B
BD08   D0 05                    BNE LBD0F
BD0A   20 73 00   LBD0A         JSR $0073
BD0D   90 5B      LBD0D         BCC LBD6A
BD0F   C9 2E      LBD0F         CMP #$2E
BD11   F0 2E                    BEQ LBD41
BD13   C9 45                    CMP #$45
BD15   D0 30                    BNE LBD47
BD17   20 73 00                 JSR $0073
BD1A   90 17                    BCC LBD33
BD1C   C9 AB                    CMP #$AB
BD1E   F0 0E                    BEQ LBD2E
BD20   C9 2D                    CMP #$2D
BD22   F0 0A                    BEQ LBD2E
BD24   C9 AA                    CMP #$AA
BD26   F0 08                    BEQ LBD30
BD28   C9 2B                    CMP #$2B
BD2A   F0 04                    BEQ LBD30
BD2C   D0 07                    BNE LBD35
BD2E   66 60      LBD2E         ROR $60
BD30   20 73 00   LBD30         JSR $0073
BD33   90 5C      LBD33         BCC LBD91
BD35   24 60      LBD35         BIT $60
BD37   10 0E                    BPL LBD47
BD39   A9 00                    LDA #$00
BD3B   38                       SEC
BD3C   E5 5E                    SBC $5E
BD3E   4C 49 BD                 JMP LBD49
BD41   66 5F      LBD41         ROR $5F
BD43   24 5F                    BIT $5F
BD45   50 C3                    BVC LBD0A
BD47   A5 5E      LBD47         LDA $5E
BD49   38         LBD49         SEC
BD4A   E5 5D                    SBC $5D
BD4C   85 5E                    STA $5E
BD4E   F0 12                    BEQ LBD62
BD50   10 09                    BPL LBD5B
BD52   20 FE BA   LBD52         JSR LBAFE
BD55   E6 5E                    INC $5E
BD57   D0 F9                    BNE LBD52
BD59   F0 07                    BEQ LBD62
BD5B   20 E2 BA   LBD5B         JSR LBAE2
BD5E   C6 5E                    DEC $5E
BD60   D0 F9                    BNE LBD5B
BD62   A5 67      LBD62         LDA $67
BD64   30 01                    BMI LBD67
BD66   60                       RTS
BD67   4C B4 BF   LBD67         JMP LBFB4
BD6A   48         LBD6A         PHA
BD6B   24 5F                    BIT $5F
BD6D   10 02                    BPL LBD71
BD6F   E6 5D                    INC $5D
BD71   20 E2 BA   LBD71         JSR LBAE2
BD74   68                       PLA
BD75   38                       SEC
BD76   E9 30                    SBC #$30
BD78   20 7E BD                 JSR LBD7E
BD7B   4C 0A BD                 JMP LBD0A
BD7E   48         LBD7E         PHA
BD7F   20 0C BC                 JSR LBC0C
BD82   68                       PLA
BD83   20 3C BC                 JSR LBC3C
BD86   A5 6E                    LDA $6E
BD88   45 66                    EOR $66
BD8A   85 6F                    STA $6F
BD8C   A6 61                    LDX $61
BD8E   4C 6A B8                 JMP LB86A
BD91   A5 5E      LBD91         LDA $5E
BD93   C9 0A                    CMP #$0A
BD95   90 09                    BCC LBDA0
BD97   A9 64                    LDA #$64
BD99   24 60                    BIT $60
BD9B   30 11                    BMI LBDAE
BD9D   4C 7E B9                 JMP LB97E
BDA0   0A         LBDA0         ASL A
BDA1   0A                       ASL A
BDA2   18                       CLC
BDA3   65 5E                    ADC $5E
BDA5   0A                       ASL A
BDA6   18                       CLC
BDA7   A0 00                    LDY #$00
BDA9   71 7A                    ADC ($7A),Y
BDAB   38                       SEC
BDAC   E9 30                    SBC #$30
BDAE   85 5E      LBDAE         STA $5E
BDB0   4C 30 BD                 JMP LBD30
BDB3   9B                       ???               ;%10011011
BDB4   3E BC 1F                 ROL $1FBC,X
BDB7   FD 9E 6E                 SBC $6E9E,X
BDBA   6B                       ???               ;%01101011 'k'
BDBB   27                       ???               ;%00100111 '''
BDBC   FD 9E 6E                 SBC $6E9E,X
BDBF   6B                       ???               ;%01101011 'k'
BDC0   28                       PLP
BDC1   00                       BRK
BDC2   A9 71      LBDC2         LDA #$71
BDC4   A0 A3                    LDY #$A3
BDC6   20 DA BD                 JSR LBDDA
BDC9   A5 3A                    LDA $3A
BDCB   A6 39                    LDX $39
BDCD   85 62      LBDCD         STA $62
BDCF   86 63                    STX $63
BDD1   A2 90                    LDX #$90
BDD3   38                       SEC
BDD4   20 49 BC                 JSR LBC49
BDD7   20 DF BD                 JSR LBDDF
BDDA   4C 1E AB   LBDDA         JMP LAB1E
BDDD   A0 01      LBDDD         LDY #$01
BDDF   A9 20      LBDDF         LDA #$20
BDE1   24 66                    BIT $66
BDE3   10 02                    BPL LBDE7
BDE5   A9 2D                    LDA #$2D
BDE7   99 FF 00   LBDE7         STA $00FF,Y
BDEA   85 66                    STA $66
BDEC   84 71                    STY $71
BDEE   C8                       INY
BDEF   A9 30                    LDA #$30
BDF1   A6 61                    LDX $61
BDF3   D0 03                    BNE LBDF8
BDF5   4C 04 BF                 JMP LBF04
BDF8   A9 00      LBDF8         LDA #$00
BDFA   E0 80                    CPX #$80
BDFC   F0 02                    BEQ LBE00
BDFE   B0 09                    BCS LBE09
BE00   A9 BD      LBE00         LDA #$BD
BE02   A0 BD                    LDY #$BD
BE04   20 28 BA                 JSR LBA28
BE07   A9 F7                    LDA #$F7
BE09   85 5D      LBE09         STA $5D
BE0B   A9 B8      LBE0B         LDA #$B8
BE0D   A0 BD                    LDY #$BD
BE0F   20 5B BC                 JSR LBC5B
BE12   F0 1E                    BEQ LBE32
BE14   10 12                    BPL LBE28
BE16   A9 B3      LBE16         LDA #$B3
BE18   A0 BD                    LDY #$BD
BE1A   20 5B BC                 JSR LBC5B
BE1D   F0 02                    BEQ LBE21
BE1F   10 0E                    BPL LBE2F
BE21   20 E2 BA   LBE21         JSR LBAE2
BE24   C6 5D                    DEC $5D
BE26   D0 EE                    BNE LBE16
BE28   20 FE BA   LBE28         JSR LBAFE
BE2B   E6 5D                    INC $5D
BE2D   D0 DC                    BNE LBE0B
BE2F   20 49 B8   LBE2F         JSR LB849
BE32   20 9B BC   LBE32         JSR LBC9B
BE35   A2 01                    LDX #$01
BE37   A5 5D                    LDA $5D
BE39   18                       CLC
BE3A   69 0A                    ADC #$0A
BE3C   30 09                    BMI LBE47
BE3E   C9 0B                    CMP #$0B
BE40   B0 06                    BCS LBE48
BE42   69 FF                    ADC #$FF
BE44   AA                       TAX
BE45   A9 02                    LDA #$02
BE47   38         LBE47         SEC
BE48   E9 02      LBE48         SBC #$02
BE4A   85 5E                    STA $5E
BE4C   86 5D                    STX $5D
BE4E   8A                       TXA
BE4F   F0 02                    BEQ LBE53
BE51   10 13                    BPL LBE66
BE53   A4 71      LBE53         LDY $71
BE55   A9 2E                    LDA #$2E
BE57   C8                       INY
BE58   99 FF 00                 STA $00FF,Y
BE5B   8A                       TXA
BE5C   F0 06                    BEQ LBE64
BE5E   A9 30                    LDA #$30
BE60   C8                       INY
BE61   99 FF 00                 STA $00FF,Y
BE64   84 71      LBE64         STY $71
BE66   A0 00      LBE66         LDY #$00
BE68   A2 80      LBE68         LDX #$80
BE6A   A5 65      LBE6A         LDA $65
BE6C   18                       CLC
BE6D   79 19 BF                 ADC $BF19,Y
BE70   85 65                    STA $65
BE72   A5 64                    LDA $64
BE74   79 18 BF                 ADC $BF18,Y
BE77   85 64                    STA $64
BE79   A5 63                    LDA $63
BE7B   79 17 BF                 ADC $BF17,Y
BE7E   85 63                    STA $63
BE80   A5 62                    LDA $62
BE82   79 16 BF                 ADC $BF16,Y
BE85   85 62                    STA $62
BE87   E8                       INX
BE88   B0 04                    BCS LBE8E
BE8A   10 DE                    BPL LBE6A
BE8C   30 02                    BMI LBE90
BE8E   30 DA      LBE8E         BMI LBE6A
BE90   8A         LBE90         TXA
BE91   90 04                    BCC LBE97
BE93   49 FF                    EOR #$FF
BE95   69 0A                    ADC #$0A
BE97   69 2F      LBE97         ADC #$2F
BE99   C8                       INY
BE9A   C8                       INY
BE9B   C8                       INY
BE9C   C8                       INY
BE9D   84 47                    STY $47
BE9F   A4 71                    LDY $71
BEA1   C8                       INY
BEA2   AA                       TAX
BEA3   29 7F                    AND #$7F
BEA5   99 FF 00                 STA $00FF,Y
BEA8   C6 5D                    DEC $5D
BEAA   D0 06                    BNE LBEB2
BEAC   A9 2E                    LDA #$2E
BEAE   C8                       INY
BEAF   99 FF 00                 STA $00FF,Y
BEB2   84 71      LBEB2         STY $71
BEB4   A4 47                    LDY $47
BEB6   8A                       TXA
BEB7   49 FF                    EOR #$FF
BEB9   29 80                    AND #$80
BEBB   AA                       TAX
BEBC   C0 24                    CPY #$24
BEBE   F0 04                    BEQ LBEC4
BEC0   C0 3C                    CPY #$3C
BEC2   D0 A6                    BNE LBE6A
BEC4   A4 71      LBEC4         LDY $71
BEC6   B9 FF 00   LBEC6         LDA $00FF,Y
BEC9   88                       DEY
BECA   C9 30                    CMP #$30
BECC   F0 F8                    BEQ LBEC6
BECE   C9 2E                    CMP #$2E
BED0   F0 01                    BEQ LBED3
BED2   C8                       INY
BED3   A9 2B      LBED3         LDA #$2B
BED5   A6 5E                    LDX $5E
BED7   F0 2E                    BEQ LBF07
BED9   10 08                    BPL LBEE3
BEDB   A9 00                    LDA #$00
BEDD   38                       SEC
BEDE   E5 5E      LBEDE         SBC $5E
BEE0   AA                       TAX
BEE1   A9 2D                    LDA #$2D
BEE3   99 01 01   LBEE3         STA $0101,Y
BEE6   A9 45                    LDA #$45
BEE8   99 00 01                 STA $0100,Y
BEEB   8A                       TXA
BEEC   A2 2F                    LDX #$2F
BEEE   38                       SEC
BEEF   E8         LBEEF         INX
BEF0   E9 0A                    SBC #$0A
BEF2   B0 FB                    BCS LBEEF
BEF4   69 3A                    ADC #$3A
BEF6   99 03 01                 STA $0103,Y
BEF9   8A                       TXA
BEFA   99 02 01                 STA $0102,Y
BEFD   A9 00                    LDA #$00
BEFF   99 04 01                 STA $0104,Y
BF02   F0 08                    BEQ LBF0C
BF04   99 FF 00   LBF04         STA $00FF,Y
BF07   A9 00      LBF07         LDA #$00
BF09   99 00 01                 STA $0100,Y
BF0C   A9 00      LBF0C         LDA #$00
BF0E   A0 01                    LDY #$01
BF10   60                       RTS
BF11   80                       ???               ;%10000000
BF12   00                       BRK
BF13   00                       BRK
BF14   00                       BRK
BF15   00                       BRK
BF16   FA                       ???               ;%11111010
BF17   0A                       ASL A
BF18   1F                       ???               ;%00011111
BF19   00                       BRK
BF1A   00                       BRK
BF1B   98                       TYA
BF1C   96 80                    STX $80,Y
BF1E   FF                       ???               ;%11111111
BF1F   F0 BD                    BEQ LBEDE
BF21   C0 00                    CPY #$00
BF23   01 86                    ORA ($86,X)
BF25   A0 FF                    LDY #$FF
BF27   FF                       ???               ;%11111111
BF28   D8                       CLD
BF29   F0 00                    BEQ LBF2B
BF2B   00         LBF2B         BRK
BF2C   03                       ???               ;%00000011
BF2D   E8                       INX
BF2E   FF                       ???               ;%11111111
BF2F   FF                       ???               ;%11111111
BF30   FF                       ???               ;%11111111
BF31   9C                       ???               ;%10011100
BF32   00                       BRK
BF33   00                       BRK
BF34   00                       BRK
BF35   0A                       ASL A
BF36   FF                       ???               ;%11111111
BF37   FF                       ???               ;%11111111
BF38   FF                       ???               ;%11111111
BF39   FF                       ???               ;%11111111
BF3A   FF                       ???               ;%11111111
BF3B   DF                       ???               ;%11011111
BF3C   0A                       ASL A
BF3D   80                       ???               ;%10000000
BF3E   00                       BRK
BF3F   03                       ???               ;%00000011
BF40   4B                       ???               ;%01001011 'K'
BF41   C0 FF                    CPY #$FF
BF43   FF                       ???               ;%11111111
BF44   73                       ???               ;%01110011 's'
BF45   60                       RTS
BF46   00                       BRK
BF47   00                       BRK
BF48   0E 10 FF                 ASL $FF10
BF4B   FF                       ???               ;%11111111
BF4C   FD A8 00                 SBC $00A8,X
BF4F   00                       BRK
BF50   00                       BRK
BF51   3C                       ???               ;%00111100 '<'
BF52   EC AA AA                 CPX $AAAA
BF55   AA                       TAX
BF56   AA                       TAX
BF57   AA                       TAX
BF58   AA                       TAX
BF59   AA                       TAX
BF5A   AA                       TAX
BF5B   AA                       TAX
BF5C   AA                       TAX
BF5D   AA                       TAX
BF5E   AA                       TAX
BF5F   AA                       TAX
BF60   AA                       TAX
BF61   AA                       TAX
BF62   AA                       TAX
BF63   AA                       TAX
BF64   AA                       TAX
BF65   AA                       TAX
BF66   AA                       TAX
BF67   AA                       TAX
BF68   AA                       TAX
BF69   AA                       TAX
BF6A   AA         LBF6A         TAX
BF6B   AA                       TAX
BF6C   AA                       TAX
BF6D   AA                       TAX
BF6E   AA                       TAX
BF6F   AA                       TAX
BF70   AA                       TAX
BF71   20 0C BC                 JSR LBC0C
BF74   A9 11                    LDA #$11
BF76   A0 BF                    LDY #$BF
BF78   20 A2 BB                 JSR LBBA2
BF7B   F0 70                    BEQ LBFED
BF7D   A5 69                    LDA $69
BF7F   D0 03                    BNE LBF84
BF81   4C F9 B8                 JMP LB8F9
BF84   A2 4E      LBF84         LDX #$4E
BF86   A0 00                    LDY #$00
BF88   20 D4 BB                 JSR LBBD4
BF8B   A5 6E                    LDA $6E
BF8D   10 0F                    BPL LBF9E
BF8F   20 CC BC                 JSR LBCCC
BF92   A9 4E                    LDA #$4E
BF94   A0 00                    LDY #$00
BF96   20 5B BC                 JSR LBC5B
BF99   D0 03                    BNE LBF9E
BF9B   98                       TYA
BF9C   A4 07                    LDY $07
BF9E   20 FE BB   LBF9E         JSR LBBFE
BFA1   98                       TYA
BFA2   48                       PHA
BFA3   20 EA B9                 JSR LB9EA
BFA6   A9 4E                    LDA #$4E
BFA8   A0 00                    LDY #$00
BFAA   20 28 BA                 JSR LBA28
BFAD   20 ED BF                 JSR LBFED
BFB0   68                       PLA
BFB1   4A                       LSR A
BFB2   90 0A                    BCC LBFBE
BFB4   A5 61      LBFB4         LDA $61
BFB6   F0 06                    BEQ LBFBE
BFB8   A5 66                    LDA $66
BFBA   49 FF                    EOR #$FF
BFBC   85 66                    STA $66
BFBE   60         LBFBE         RTS
BFBF   81 38                    STA ($38,X)
BFC1   AA                       TAX
BFC2   3B                       ???               ;%00111011 ';'
BFC3   29 07                    AND #$07
BFC5   71 34                    ADC ($34),Y
BFC7   58                       CLI
BFC8   3E 56 74                 ROL $7456,X
BFCB   16 7E                    ASL $7E,X
BFCD   B3                       ???               ;%10110011
BFCE   1B                       ???               ;%00011011
BFCF   77                       ???               ;%01110111 'w'
BFD0   2F                       ???               ;%00101111 '/'
BFD1   EE E3 85                 INC $85E3
BFD4   7A                       ???               ;%01111010 'z'
BFD5   1D 84 1C                 ORA $1C84,X
BFD8   2A                       ROL A
BFD9   7C                       ???               ;%01111100 '|'
BFDA   63                       ???               ;%01100011 'c'
BFDB   59 58 0A                 EOR $0A58,Y
BFDE   7E 75 FD                 ROR $FD75,X
BFE1   E7                       ???               ;%11100111
BFE2   C6 80                    DEC $80
BFE4   31 72                    AND ($72),Y
BFE6   18                       CLC
BFE7   10 81                    BPL LBF6A
BFE9   00                       BRK
BFEA   00                       BRK
BFEB   00                       BRK
BFEC   00                       BRK
BFED   A9 BF      LBFED         LDA #$BF
BFEF   A0 BF                    LDY #$BF
BFF1   20 28 BA                 JSR LBA28
BFF4   A5 70                    LDA $70
BFF6   69 50                    ADC #$50
BFF8   90 03                    BCC LBFFD
BFFA   20 23 BC                 JSR LBC23
BFFD   4C 00 E0   LBFFD         JMP $E000
                                .END

;auto-generated symbols and labels
 LA020        $A020
 LA05D        $A05D
 LA079        $A079
 LA0E4        $A0E4
 LA10B        $A10B
 LA133        $A133
 LA158        $A158
 LA162        $A162
 LA177        $A177
 LA1AF        $A1AF
 LA1F9        $A1F9
 LA23F        $A23F
 LA24E        $A24E
 LA3B7        $A3B7
 LA3A4        $A3A4
 LA3B0        $A3B0
 LA38F        $A38F
 LA408        $A408
 LA3F3        $A3F3
 LA3DC        $A3DC
 LA3EC        $A3EC
 LA3E8        $A3E8
 LA435        $A435
 LA434        $A434
 LA412        $A412
 LA416        $A416
 LB526        $B526
 LA421        $A421
 LAAD7        $AAD7
 LAB45        $AB45
 LAB47        $AB47
 LA456        $A456
 LA67A        $A67A
 LAB1E        $AB1E
 LA474        $A474
 LBDC2        $BDC2
 LA560        $A560
 LA480        $A480
 LA49C        $A49C
 LA579        $A579
 LA7E1        $A7E1
 LA96B        $A96B
 LA613        $A613
 LA4ED        $A4ED
 LA4D7        $A4D7
 LA4DF        $A4DF
 LA659        $A659
 LA533        $A533
 LA508        $A508
 LA3B8        $A3B8
 LA522        $A522
 LA55F        $A55F
 LA544        $A544
 LA53C        $A53C
 LA576        $A576
 LA562        $A562
 LA437        $A437
 LAACA        $AACA
 LA58E        $A58E
 LA5C9        $A5C9
 LA582        $A582
 LA5EE        $A5EE
 LA5A4        $A5A4
 LA5AC        $A5AC
 LA5B6        $A5B6
 LA5F5        $A5F5
 LA609        $A609
 LA5DC        $A5DC
 LA5DE        $A5DE
 LA5E5        $A5E5
 LA5F9        $A5F9
 LA5B8        $A5B8
 LA5C7        $A5C7
 LA640        $A640
 LA641        $A641
 LA62E        $A62E
 LA637        $A637
 LA617        $A617
 LA68E        $A68E
 LA68D        $A68D
 LA81D        $A81D
 LA6A4        $A6A4
 LA6BB        $A6BB
 LA6C9        $A6C9
 LA714        $A714
 LA82C        $A82C
 LA6E6        $A6E6
 LA6E8        $A6E8
 LBDCD        $BDCD
 LA700        $A700
 LA717        $A717
 LA6F3        $A6F3
 LA737        $A737
 LA72F        $A72F
 LA72C        $A72C
 LA6EF        $A6EF
 LA9A5        $A9A5
 LA38A        $A38A
 LA753        $A753
 LA3FB        $A3FB
 LA906        $A906
 LAEFF        $AEFF
 LAD8D        $AD8D
 LAD8A        $AD8A
 LAE43        $AE43
 LBBA2        $BBA2
 LA79F        $A79F
 LBC2B        $BC2B
 LAE38        $AE38
 LA7BE        $A7BE
 LA807        $A807
 LA7CE        $A7CE
 LA84B        $A84B
 LA7ED        $A7ED
 LA7AE        $A7AE
 LA82B        $A82B
 LA804        $A804
 LA80E        $A80E
 LAF08        $AF08
 LA80B        $A80B
 LA8A0        $A8A0
 LA827        $A827
 LA832        $A832
 LA870        $A870
 LA849        $A849
 LA854        $A854
 LA469        $A469
 LA862        $A862
 LA87D        $A87D
 LA660        $A660
 LA897        $A897
 LA909        $A909
 LA8BC        $A8BC
 LA8C0        $A8C0
 LA8E3        $A8E3
 LA8D1        $A8D1
 LA8EB        $A8EB
 LA905        $A905
 LA919        $A919
 LA911        $A911
 LAD9E        $AD9E
 LA937        $A937
 LA940        $A940
 LA8FB        $A8FB
 LA948        $A948
 LB79E        $B79E
 LA957        $A957
 LA8E8        $A8E8
 LA95F        $A95F
 LA7EF        $A7EF
 LA96A        $A96A
 LA953        $A953
 LA99F        $A99F
 LA971        $A971
 LB08B        $B08B
 LAD90        $AD90
 LA9D9        $A9D9
 LA9D6        $A9D6
 LBC1B        $BC1B
 LB1BF        $B1BF
 LBBD0        $BBD0
 LAA2C        $AA2C
 LB6A6        $B6A6
 LAA24        $AA24
 LAA1D        $AA1D
 LBAE2        $BAE2
 LBC0C        $BC0C
 LAA07        $AA07
 LBAED        $BAED
 LA9ED        $A9ED
 LBC9B        $BC9B
 LAA27        $AA27
 LB248        $B248
 LBD7E        $BD7E
 LAA4B        $AA4B
 LAA3D        $AA3D
 LAA52        $AA52
 LAA68        $AA68
 LB475        $B475
 LB67A        $B67A
 LB6DB        $B6DB
 LAA86        $AA86
 LABB5        $ABB5
 LAA90        $AA90
 LAAA0        $AAA0
 LAB21        $AB21
 LAAE7        $AAE7
 LAAF8        $AAF8
 LAAE8        $AAE8
 LAB13        $AB13
 LAA9A        $AA9A
 LBDDD        $BDDD
 LB487        $B487
 LAB3B        $AB3B
 LAA9D        $AA9D
 LAAE5        $AAE5
 LAAEE        $AAEE
 LAB0E        $AB0E
 LB79B        $B79B
 LAB5F        $AB5F
 LAB0F        $AB0F
 LAB19        $AB19
 LAAA2        $AAA2
 LAB10        $AB10
 LAB28        $AB28
 LAB42        $AB42
 LAB62        $AB62
 LAB57        $AB57
 LAB5B        $AB5B
 LAB6B        $AB6B
 LB3A6        $B3A6
 LAB92        $AB92
 LAC0F        $AC0F
 LABB7        $ABB7
 LABCE        $ABCE
 LAEBD        $AEBD
 LABF9        $ABF9
 LABEA        $ABEA
 LA8F8        $A8F8
 LAC0D        $AC0D
 LABD6        $ABD6
 LAC03        $AC03
 LAC51        $AC51
 LAC41        $AC41
 LAC4D        $AC4D
 LACB8        $ACB8
 LAC4A        $AC4A
 LAC89        $AC89
 LAC65        $AC65
 LAC71        $AC71
 LAC72        $AC72
 LAC7D        $AC7D
 LB48D        $B48D
 LB7E2        $B7E2
 LA9DA        $A9DA
 LAC91        $AC91
 LBCF3        $BCF3
 LA9C2        $A9C2
 LAC9D        $AC9D
 LAB4D        $AB4D
 LACDF        $ACDF
 LAEFD        $AEFD
 LAC15        $AC15
 LACD1        $ACD1
 LAD32        $AD32
 LACEA        $ACEA
 LACFB        $ACFB
 LAD27        $AD27
 LAD35        $AD35
 LB867        $B867
 LBC5D        $BC5D
 LAD78        $AD78
 LAD75        $AD75
 LAD24        $AD24
 LAD97        $AD97
 LAD99        $AD99
 LAD96        $AD96
 LADA4        $ADA4
 LAE83        $AE83
 LADD7        $ADD7
 LAE30        $AE30
 LADBB        $ADBB
 LAE07        $AE07
 LAE58        $AE58
 LADE8        $ADE8
 LB63D        $B63D
 LAE5D        $AE5D
 LAE20        $AE20
 LAE19        $AE19
 LAE5B        $AE5B
 LAE66        $AE66
 LAE11        $AE11
 LADF0        $ADF0
 LADF9        $ADF9
 LAE33        $AE33
 LADA9        $ADA9
 LAE80        $AE80
 LAE64        $AE64
 LAE92        $AE92
 LB113        $B113
 LAE9A        $AE9A
 LAF28        $AF28
 LAEAD        $AEAD
 LAF0D        $AF0D
 LAE8A        $AE8A
 LAECC        $AECC
 LAEC6        $AEC6
 LAEE3        $AEE3
 LAF0F        $AF0F
 LB391        $B391
 LAEEA        $AEEA
 LB3F4        $B3F4
 LAEF1        $AEF1
 LAFA7        $AFA7
 LAEFA        $AEFA
 LADFA        $ADFA
 LAF27        $AF27
 LAF5D        $AF5D
 LAF14        $AF14
 LAF5C        $AF5C
 LAF84        $AF84
 LBE68        $BE68
 LB46F        $B46F
 LAF6E        $AF6E
 LAFA0        $AFA0
 LAF92        $AF92
 LBC4F        $BC4F
 LBC3C        $BC3C
 LAFD1        $AFD1
 LAD8F        $AD8F
 LAFD6        $AFD6
 LBBFC        $BBFC
 LB02E        $B02E
 LBC5B        $BC5B
 LB061        $B061
 LB6AA        $B6AA
 LB056        $B056
 LB066        $B066
 LB072        $B072
 LB05B        $B05B
 LB07B        $B07B
 LB090        $B090
 LB07E        $B07E
 LB09F        $B09F
 LB0AF        $B0AF
 LB0BA        $B0BA
 LB0B0        $B0B0
 LB0C4        $B0C4
 LB0D4        $B0D4
 LB0DB        $B0DB
 LB09C        $B09C
 LB0E7        $B0E7
 LB1D1        $B1D1
 LB0FB        $B0FB
 LB11D        $B11D
 LB109        $B109
 LB185        $B185
 LB0F1        $B0F1
 LB0EF        $B0EF
 LB11C        $B11C
 LB128        $B128
 LB13B        $B13B
 LB123        $B123
 LB143        $B143
 LB138        $B138
 LB159        $B159
 LB18F        $B18F
 LB1A0        $B1A0
 LB127        $B127
 LB1CC        $B1CC
 LB1CE        $B1CE
 LB1B2        $B1B2
 LB1DB        $B1DB
 LAEF7        $AEF7
 LB228        $B228
 LB261        $B261
 LB237        $B237
 LB24D        $B24D
 LB21C        $B21C
 LB24A        $B24A
 LB194        $B194
 LB245        $B245
 LB2EA        $B2EA
 LB274        $B274
 LB27D        $B27D
 LB296        $B296
 LB34C        $B34C
 LB286        $B286
 LB30B        $B30B
 LB2B9        $B2B9
 LB2CD        $B2CD
 LB2C8        $B2C8
 LB34B        $B34B
 LB30E        $B30E
 LB308        $B308
 LB30F        $B30F
 LB320        $B320
 LB2F2        $B2F2
 LB331        $B331
 LB337        $B337
 LB355        $B355
 LB378        $B378
 LB35F        $B35F
 LB384        $B384
 LBC44        $BC44
 LB3E1        $B3E1
 LB44F        $B44F
 LB092        $B092
 LB3AE        $B3AE
 LB418        $B418
 LBBD4        $BBD4
 LB449        $B449
 LBDDF        $BDDF
 LB4F4        $B4F4
 LB4A8        $B4A8
 LB4A4        $B4A4
 LB497        $B497
 LB4A9        $B4A9
 LB4B5        $B4B5
 LB4BF        $B4BF
 LB4CA        $B4CA
 LB688        $B688
 LB4D5        $B4D5
 LB501        $B501
 LB516        $B516
 LB50B        $B50B
 LB4D2        $B4D2
 LB4F6        $B4F6
 LB54D        $B54D
 LB5C7        $B5C7
 LB544        $B544
 LB561        $B561
 LB566        $B566
 LB5BD        $B5BD
 LB559        $B559
 LB57D        $B57D
 LB606        $B606
 LB56E        $B56E
 LB5AE        $B5AE
 LB5B8        $B5B8
 LB572        $B572
 LB5B0        $B5B0
 LB5F6        $B5F6
 LB5DC        $B5DC
 LB5E6        $B5E6
 LB601        $B601
 LA3BF        $A3BF
 LB52A        $B52A
 LB65D        $B65D
 LB68C        $B68C
 LADB8        $ADB8
 LB699        $B699
 LB690        $B690
 LB6A2        $B6A2
 LB6D6        $B6D6
 LB6D5        $B6D5
 LB6EB        $B6EB
 LB7A1        $B7A1
 LB47D        $B47D
 LB761        $B761
 LB70C        $B70C
 LB725        $B725
 LB706        $B706
 LB748        $B748
 LB798        $B798
 LB70D        $B70D
 LB70E        $B70E
 LB782        $B782
 LB3A2        $B3A2
 LB6A3        $B6A3
 LB1B8        $B1B8
 LB7B5        $B7B5
 LB8F7        $B8F7
 LB7CD        $B7CD
 LB7F7        $B7F7
 LB7EB        $B7EB
 LB83C        $B83C
 LB7F1        $B7F1
 LB840        $B840
 LBA8C        $BA8C
 LB86A        $B86A
 LB999        $B999
 LB8A3        $B8A3
 LB86F        $B86F
 LB848        $B848
 LB893        $B893
 LB897        $B897
 LB862        $B862
 LB9B0        $B9B0
 LB8FE        $B8FE
 LB8AF        $B8AF
 LB8D7        $B8D7
 LB947        $B947
 LB929        $B929
 LB8DB        $B8DB
 LB936        $B936
 LB91D        $B91D
 LB946        $B946
 LB97E        $B97E
 LB97D        $B97D
 LB985        $B985
 LB9BA        $B9BA
 LB9AC        $B9AC
 LB9A6        $B9A6
 LB9F1        $B9F1
 LB9F4        $B9F4
 LBB0F        $BB0F
 LB850        $B850
 LBA30        $BA30
 LBA8B        $BA8B
 LBAB7        $BAB7
 LBA59        $BA59
 LBA5E        $BA5E
 LBB8F        $BB8F
 LB983        $B983
 LBA7D        $BA7D
 LBA61        $BA61
 LBADA        $BADA
 LBAC4        $BAC4
 LBADF        $BADF
 LBACF        $BACF
 LB8FB        $B8FB
 LBAF8        $BAF8
 LB877        $B877
 LBB12        $BB12
 LBB8A        $BB8A
 LBB3F        $BB3F
 LBB4C        $BB4C
 LBB7A        $BB7A
 LBB7E        $BB7E
 LBB5D        $BB5D
 LBB29        $BB29
 LBB4F        $BB4F
 LBC02        $BC02
 LBC11        $BC11
 LBC1A        $BC1A
 LB96F        $B96F
 LB938        $B938
 LBC38        $BC38
 LB8D2        $B8D2
 LBC2F        $BC2F
 LBC92        $BC92
 LBCBA        $BCBA
 LBC98        $BC98
 LBC31        $BC31
 LBCE9        $BCE9
 LBCAF        $BCAF
 LB94D        $B94D
 LBCBB        $BCBB
 LBCF2        $BCF2
 LBCF7        $BCF7
 LBD0D        $BD0D
 LBD06        $BD06
 LBD0A        $BD0A
 LBD0F        $BD0F
 LBD6A        $BD6A
 LBD41        $BD41
 LBD47        $BD47
 LBD33        $BD33
 LBD2E        $BD2E
 LBD30        $BD30
 LBD35        $BD35
 LBD91        $BD91
 LBD49        $BD49
 LBD62        $BD62
 LBD5B        $BD5B
 LBAFE        $BAFE
 LBD52        $BD52
 LBD67        $BD67
 LBFB4        $BFB4
 LBD71        $BD71
 LBDA0        $BDA0
 LBDAE        $BDAE
 LBDDA        $BDDA
 LBC49        $BC49
 LBDE7        $BDE7
 LBDF8        $BDF8
 LBF04        $BF04
 LBE00        $BE00
 LBE09        $BE09
 LBA28        $BA28
 LBE32        $BE32
 LBE28        $BE28
 LBE21        $BE21
 LBE2F        $BE2F
 LBE16        $BE16
 LBE0B        $BE0B
 LB849        $B849
 LBE47        $BE47
 LBE48        $BE48
 LBE53        $BE53
 LBE66        $BE66
 LBE64        $BE64
 LBE8E        $BE8E
 LBE6A        $BE6A
 LBE90        $BE90
 LBE97        $BE97
 LBEB2        $BEB2
 LBEC4        $BEC4
 LBEC6        $BEC6
 LBED3        $BED3
 LBF07        $BF07
 LBEE3        $BEE3
 LBEEF        $BEEF
 LBF0C        $BF0C
 LBEDE        $BEDE
 LBF2B        $BF2B
 LBFED        $BFED
 LBF84        $BF84
 LB8F9        $B8F9
 LBF9E        $BF9E
 LBCCC        $BCCC
 LBBFE        $BBFE
 LB9EA        $B9EA
 LBFBE        $BFBE
 LBF6A        $BF6A
 LBFFD        $BFFD
 LBC23        $BC23
