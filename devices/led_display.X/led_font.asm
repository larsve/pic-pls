;**********************************************************************
; Description:
;
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\common\src\mcu_defines.inc"

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  GetCharData

    ; Variables
    GLOBAL  CharData0
    GLOBAL  CharData1
    GLOBAL  CharData2
    GLOBAL  CharData3
    GLOBAL  CharData4

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
gprbank0    udata
CharData0   res 1           ; LSB character data
CharData1   res 1           ;
CharData2   res 1           ;
CharData3   res 1           ;
CharData4   res 1           ; MSB character data
ASCIIhi     res 1           ; LSB of program memory adress for current font-data stream
ASCIIlo     res 1           ; MSB of program memory adress for current font-data stream

Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** Code Section ***************************************************
PROG1       code

;**********************************************************************
; GetCharData
;   In parameter: w-register = ASCII value to fetch char data for.
;   Out parameters: CharData0..CharData4 = Bitstream for font data.
;       CharData0
;         Bit 0-4: Row0 D0 - D4
;         Bit 5-7: Row1 D0 - D2
;       CharData1
;         Bit 0-1: Row1 D3 - D4
;         Bit 2-6: Row2 D0 - D4
;         Bit 7:   Row3 D0
;       CharData2
;         Bit 0-3: Row3 D1 - D4
;         Bit 4-7: Row4 D0 - D3
;       CharData3
;         Bit 0:   Row4 D4
;         Bit 1-5: Row5 D0 - D4
;         Bit 6-7: Row6 D0 - D1
;       CharData4
;         Bit 0-2: Row6 D2 - D4
;         Bit 3-7: Unused
;**********************************************************************
GetCharData
    clrf    ASCIIhi
    movwf   ASCIIlo             ; Store ASCII value to get

    ; Calc ASCII * 4
    bcf     STATUS, C
    rlf     ASCIIlo, F          ; * 2
    rlf     ASCIIhi, F

    bcf     STATUS, C
    rlf     ASCIIlo, F          ; * 4
    rlf     ASCIIhi, F

    ; Calc ASCII * 1 and add to previous result to get ASCII * 5
    addwf   ASCIIlo, F
    btfsc   STATUS, C
    incf    ASCIIhi, F

    ; Disable interrupts because we need the stackspace...
    bcf     INTCON, GIE         ; Clear Global Interrupt Enable flag

    ; Get character font data (5 x 7 bit = 35 bits = 5 bytes)
    pagesel ReadFontByte
    call    ReadFontByte
    movwf   CharData0
    incf    ASCIIlo, F
    btfsc   STATUS, Z
    incf    ASCIIhi, F
    pagesel ReadFontByte
    call    ReadFontByte
    movwf   CharData1
    incf    ASCIIlo, F
    btfsc   STATUS, Z
    incf    ASCIIhi, F
    pagesel ReadFontByte
    call    ReadFontByte
    movwf   CharData2
    incf    ASCIIlo, F
    btfsc   STATUS, Z
    incf    ASCIIhi, F
    pagesel ReadFontByte
    call    ReadFontByte
    movwf   CharData3
    incf    ASCIIlo, F
    btfsc   STATUS, Z
    incf    ASCIIhi, F
    pagesel ReadFontByte
    call    ReadFontByte
    movwf   CharData4

    ; Re-enable interrupts
    pagesel ReEnableInterrupts
ReEnableInterrupts
    bsf     INTCON, GIE         ; Set Global Interrupt Enable flag
    btfss   INTCON, GIE
    goto    ReEnableInterrupts

    clrf    PCLATH
    return

ReadFontByte
    ; Check I2CData for a value to send...
;   movlw   HIGH FontDataTable
;   movwf   PCLATH
;   movfw   ASCIIhi
;   addwf   PCLATH, F
;
;   movfw   ASCIIlo
;   addlw   LOW FontDataTable
;   btfsc   STATUS, C
;   incf    PCLATH,F
;   movwf   PCL
;
    pageselw FontDataTable
    movfw   ASCIIhi
    addwf   PCLATH, F

    movlw   FontDataTable
    addwf   ASCIIlo, W
    btfsc   STATUS, C
    incf    PCLATH, F
    movwf   PCL

    return                      ; Useless since we'll never reach this, but feels god to have :-)


;***** Font Data Section **********************************************
FONTDATA    code                ; Font data is stored in a separate code block so it can be
FontDataTable                   ; reallocated by the compiler/linker when it no longer can
                                ; fit in the same program block as the main program.

    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # 0
    dt  0x10, 0x42, 0x08, 0x21, 0x04    ; ASCII # 1
    dt  0x18, 0x63, 0x8C, 0x31, 0x06    ; ASCII # 2
    dt  0x9C, 0x73, 0xCE, 0x39, 0x07    ; ASCII # 3
    dt  0xDE, 0x7B, 0xEF, 0xBD, 0x07    ; ASCII # 4
    dt  0xFF, 0xFF, 0xFF, 0xFF, 0x07    ; ASCII # 5
    dt  0x21, 0x84, 0x10, 0x42, 0x00    ; ASCII # 6
    dt  0x63, 0x8C, 0x31, 0xC6, 0x00    ; ASCII # 7
    dt  0xE7, 0x9C, 0x73, 0xCE, 0x01    ; ASCII # 8
    dt  0xEF, 0xBD, 0xF7, 0xDE, 0x03    ; ASCII # 9
    dt  0xFF, 0xFF, 0xFF, 0xFF, 0x07    ; ASCII # A
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # B
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # C
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # D
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # E
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII # F
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #10
    dt  0x00, 0x00, 0x00, 0xC0, 0x07    ; ASCII #11
    dt  0x00, 0x00, 0x00, 0xFE, 0x07    ; ASCII #12
    dt  0x00, 0x00, 0xF0, 0xFF, 0x07    ; ASCII #13
    dt  0x00, 0x80, 0xFF, 0xFF, 0x07    ; ASCII #14
    dt  0x00, 0xFC, 0xFF, 0xFF, 0x07    ; ASCII #15
    dt  0xE0, 0xFF, 0xFF, 0xFF, 0x07    ; ASCII #16
    dt  0xFF, 0xFF, 0xFF, 0xFF, 0x07    ; ASCII #17
    dt  0xFF, 0xFF, 0xFF, 0xFF, 0x07    ; ASCII #18
    dt  0xFF, 0xFF, 0xFF, 0x3F, 0x00    ; ASCII #19
    dt  0xFF, 0xFF, 0xFF, 0x01, 0x00    ; ASCII #1A
    dt  0xFF, 0xFF, 0x0F, 0x00, 0x00    ; ASCII #1B
    dt  0xFF, 0x7F, 0x00, 0x00, 0x00    ; ASCII #1C
    dt  0xFF, 0x03, 0x00, 0x00, 0x00    ; ASCII #1D
    dt  0x1F, 0x00, 0x00, 0x00, 0x00    ; ASCII #1E
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #1F
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #20
    dt  0x84, 0x10, 0x42, 0x00, 0x01    ; ASCII #21
    dt  0x4A, 0x01, 0x00, 0x00, 0x00    ; ASCII #22
    dt  0x4A, 0x7D, 0xF5, 0x95, 0x02    ; ASCII #23
    dt  0xE4, 0x51, 0x57, 0x3C, 0x01    ; ASCII #24
    dt  0x38, 0x0B, 0x82, 0xE6, 0x00    ; ASCII #25
    dt  0x88, 0x52, 0x54, 0x25, 0x03    ; ASCII #26
    dt  0x8C, 0x11, 0x04, 0x00, 0x00    ; ASCII #27
    dt  0x82, 0x10, 0x42, 0x88, 0x00    ; ASCII #28
    dt  0x88, 0x10, 0x42, 0x08, 0x02    ; ASCII #29
    dt  0x40, 0x91, 0x4F, 0x14, 0x00    ; ASCII #2A
    dt  0x80, 0x90, 0x4F, 0x08, 0x00    ; ASCII #2B
    dt  0x00, 0x00, 0x8C, 0x11, 0x04    ; ASCII #2C
    dt  0x00, 0x80, 0x0F, 0x00, 0x00    ; ASCII #2D
    dt  0x00, 0x00, 0x00, 0x18, 0x03    ; ASCII #2E
    dt  0x20, 0x08, 0x82, 0x20, 0x00    ; ASCII #2F
    dt  0x2E, 0xC6, 0x18, 0xA3, 0x03    ; ASCII #30
    dt  0x84, 0x11, 0x42, 0x88, 0x03    ; ASCII #31
    dt  0x2E, 0x06, 0x83, 0xE0, 0x07    ; ASCII #32
    dt  0x2E, 0x06, 0x17, 0xA2, 0x03    ; ASCII #33
    dt  0xC2, 0x28, 0xF9, 0x85, 0x00    ; ASCII #34
    dt  0x1F, 0xFA, 0x10, 0x82, 0x07    ; ASCII #35
    dt  0x06, 0x41, 0x1F, 0xA3, 0x03    ; ASCII #36
    dt  0x3F, 0x08, 0x82, 0x10, 0x02    ; ASCII #37
    dt  0x2E, 0x46, 0x17, 0xA3, 0x03    ; ASCII #38
    dt  0x2E, 0xC6, 0x17, 0x04, 0x03    ; ASCII #39
    dt  0x80, 0x31, 0xC0, 0x18, 0x00    ; ASCII #3A
    dt  0x8C, 0x01, 0xC6, 0x08, 0x02    ; ASCII #3B
    dt  0x41, 0x10, 0x44, 0x44, 0x00    ; ASCII #3C
    dt  0x00, 0x7C, 0xF0, 0x01, 0x00    ; ASCII #3D
    dt  0x10, 0x11, 0x41, 0x10, 0x04    ; ASCII #3E
    dt  0x2E, 0x06, 0x41, 0x00, 0x01    ; ASCII #3F
    dt  0x2E, 0xDE, 0x7A, 0xA1, 0x03    ; ASCII #40
    dt  0x2E, 0xC6, 0x1F, 0x63, 0x04    ; ASCII #41
    dt  0x3E, 0x46, 0x1F, 0xA3, 0x07    ; ASCII #42
    dt  0x2E, 0x42, 0x08, 0xA3, 0x03    ; ASCII #43
    dt  0x3E, 0xC6, 0x18, 0xA3, 0x07    ; ASCII #44
    dt  0x1F, 0x42, 0x0F, 0xE1, 0x07    ; ASCII #45
    dt  0x1F, 0x42, 0x0F, 0x21, 0x04    ; ASCII #46
    dt  0x2E, 0x42, 0x38, 0xA3, 0x03    ; ASCII #47
    dt  0x31, 0xC6, 0x1F, 0x63, 0x04    ; ASCII #48
    dt  0x8E, 0x10, 0x42, 0x88, 0x03    ; ASCII #49
    dt  0x21, 0x84, 0x10, 0xA2, 0x03    ; ASCII #4A
    dt  0x51, 0x52, 0x4C, 0x65, 0x04    ; ASCII #4B
    dt  0x10, 0x42, 0x08, 0xE1, 0x07    ; ASCII #4C
    dt  0x71, 0xD7, 0x1A, 0x63, 0x04    ; ASCII #4D
    dt  0x31, 0xE6, 0x3A, 0x63, 0x04    ; ASCII #4E
    dt  0x2E, 0xC6, 0x18, 0xA3, 0x03    ; ASCII #4F
    dt  0x3E, 0x46, 0x0F, 0x21, 0x04    ; ASCII #50
    dt  0x2E, 0xC6, 0x58, 0x65, 0x03    ; ASCII #51
    dt  0x3E, 0x46, 0x4F, 0x65, 0x04    ; ASCII #52
    dt  0x2E, 0x42, 0x17, 0xA2, 0x03    ; ASCII #53
    dt  0x9F, 0x10, 0x42, 0x08, 0x01    ; ASCII #54
    dt  0x31, 0xC6, 0x18, 0xA3, 0x03    ; ASCII #55
    dt  0x31, 0x46, 0xA5, 0x08, 0x01    ; ASCII #56
    dt  0x31, 0xC6, 0x5A, 0x77, 0x04    ; ASCII #57
    dt  0x31, 0x2A, 0xA2, 0x62, 0x04    ; ASCII #58
    dt  0x31, 0x2A, 0x42, 0x08, 0x01    ; ASCII #59
    dt  0x3F, 0x08, 0x82, 0xE0, 0x07    ; ASCII #5A
    dt  0x87, 0x10, 0x42, 0xC8, 0x01    ; ASCII #5B
    dt  0x00, 0x22, 0x22, 0x02, 0x00    ; ASCII #5C
    dt  0x9C, 0x10, 0x42, 0x08, 0x07    ; ASCII #5D
    dt  0xC4, 0x45, 0x00, 0x00, 0x00    ; ASCII #5E
    dt  0x00, 0x00, 0x00, 0xC0, 0x07    ; ASCII #5F
    dt  0x8C, 0x21, 0x02, 0x00, 0x00    ; ASCII #60
    dt  0x00, 0x38, 0x29, 0x65, 0x03    ; ASCII #61
    dt  0x10, 0x42, 0x9B, 0xA3, 0x07    ; ASCII #62
    dt  0x00, 0x38, 0x08, 0xA3, 0x03    ; ASCII #63
    dt  0x21, 0x84, 0x36, 0xE3, 0x03    ; ASCII #64
    dt  0x00, 0xB8, 0xE8, 0xA1, 0x03    ; ASCII #65
    dt  0x44, 0x21, 0x8E, 0x10, 0x02    ; ASCII #66
    dt  0x00, 0xBC, 0xF8, 0x82, 0x01    ; ASCII #67
    dt  0x10, 0xDA, 0x1C, 0x63, 0x04    ; ASCII #68
    dt  0x80, 0x00, 0x46, 0x88, 0x03    ; ASCII #69
    dt  0x02, 0x18, 0x21, 0x24, 0x03    ; ASCII #6A
    dt  0x10, 0x4A, 0x8A, 0xA9, 0x04    ; ASCII #6B
    dt  0x8C, 0x10, 0x42, 0x88, 0x03    ; ASCII #6C
    dt  0x00, 0xA8, 0x1A, 0x63, 0x04    ; ASCII #6D
    dt  0x00, 0xD8, 0x1C, 0x63, 0x04    ; ASCII #6E
    dt  0x00, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #6F
    dt  0x00, 0xF8, 0x98, 0x2D, 0x04    ; ASCII #70
    dt  0x00, 0xBC, 0x38, 0x5B, 0x00    ; ASCII #71
    dt  0x00, 0x2C, 0x86, 0x10, 0x02    ; ASCII #72
    dt  0x00, 0x38, 0xE8, 0x82, 0x07    ; ASCII #73
    dt  0x08, 0x71, 0x84, 0x14, 0x01    ; ASCII #74
    dt  0x00, 0xA4, 0x94, 0x56, 0x01    ; ASCII #75
    dt  0x00, 0xC4, 0x18, 0x15, 0x01    ; ASCII #76
    dt  0x00, 0xC4, 0x58, 0xAB, 0x02    ; ASCII #77
    dt  0x00, 0x44, 0x45, 0x54, 0x04    ; ASCII #78
    dt  0x00, 0x44, 0x45, 0x08, 0x02    ; ASCII #79
    dt  0x00, 0x7C, 0x41, 0xD0, 0x07    ; ASCII #7A
    dt  0x82, 0x10, 0x44, 0x88, 0x00    ; ASCII #7B
    dt  0x84, 0x10, 0x42, 0x08, 0x01    ; ASCII #7C
    dt  0x88, 0x10, 0x41, 0x08, 0x02    ; ASCII #7D
    dt  0x00, 0xA0, 0x2A, 0x00, 0x00    ; ASCII #7E
    dt  0xAA, 0xAA, 0xAA, 0xAA, 0x02    ; ASCII #7F
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #80
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #81
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #82
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #83
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #84
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #85
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #86
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #87
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #88
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #89
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8A
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8B
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8C
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8D
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8E
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #8F
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #90
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #91
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #92
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #93
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #94
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #95
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #96
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #97
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #98
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #99
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9A
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9B
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9C
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9D
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9E
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #9F
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #A0
    dt  0x80, 0x00, 0x42, 0x08, 0x01    ; ASCII #A1
    dt  0xC4, 0x55, 0x5A, 0x1D, 0x01    ; ASCII #A2
    dt  0x26, 0x21, 0x8E, 0xD0, 0x07    ; ASCII #A3
    dt  0x20, 0x3A, 0xE5, 0x22, 0x00    ; ASCII #A4
    dt  0x51, 0x11, 0xE2, 0x08, 0x01    ; ASCII #A5
    dt  0x84, 0x10, 0x40, 0x08, 0x01    ; ASCII #A6
    dt  0x0E, 0xFA, 0xF8, 0x82, 0x03    ; ASCII #A7
    dt  0x4A, 0x01, 0x00, 0x00, 0x00    ; ASCII #A8
    dt  0xAE, 0xEE, 0xBC, 0xAB, 0x03    ; ASCII #A9
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #AA
    dt  0xA0, 0x28, 0xAA, 0x0A, 0x00    ; ASCII #AB
    dt  0x3F, 0x00, 0x00, 0x00, 0x00    ; ASCII #AC
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #AD
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #AE
    dt  0x1F, 0x00, 0x00, 0x00, 0x00    ; ASCII #AF
    dt  0x44, 0x11, 0x00, 0x00, 0x00    ; ASCII #B0
    dt  0x84, 0x7C, 0x42, 0xC0, 0x07    ; ASCII #B1
    dt  0x26, 0x19, 0xF4, 0x00, 0x00    ; ASCII #B2
    dt  0x26, 0x89, 0x64, 0x00, 0x00    ; ASCII #B3
    dt  0x8C, 0x11, 0x04, 0x00, 0x00    ; ASCII #B4
    dt  0x00, 0x80, 0x94, 0x56, 0x05    ; ASCII #B5
    dt  0xAD, 0xF7, 0x56, 0x4A, 0x01    ; ASCII #B6
    dt  0x00, 0x30, 0x06, 0x00, 0x00    ; ASCII #B7
    dt  0x00, 0x00, 0xC6, 0x08, 0x02    ; ASCII #B8
    dt  0xC2, 0x08, 0x71, 0x00, 0x00    ; ASCII #B9
    dt  0xA2, 0x08, 0x70, 0x00, 0x00    ; ASCII #BA
    dt  0x80, 0xAA, 0xA2, 0x28, 0x00    ; ASCII #BB
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #BC
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #BD
    dt  0x00, 0x00, 0x00, 0x00, 0x00    ; ASCII #BE
    dt  0x04, 0x10, 0x14, 0xA3, 0x03    ; ASCII #BF
    dt  0x88, 0xB8, 0xF8, 0x63, 0x04    ; ASCII #C0
    dt  0x82, 0xB8, 0xF8, 0x63, 0x04    ; ASCII #C1
    dt  0x44, 0xB9, 0xF8, 0x63, 0x04    ; ASCII #C2
    dt  0x8A, 0xBA, 0xF8, 0x63, 0x04    ; ASCII #C3
    dt  0x0A, 0xB8, 0xF8, 0x63, 0x04    ; ASCII #C4
    dt  0x04, 0xB8, 0xF8, 0x63, 0x04    ; ASCII #C5
    dt  0x8F, 0xD2, 0x4F, 0xE9, 0x05    ; ASCII #C6
    dt  0x2E, 0x42, 0x18, 0x1D, 0x01    ; ASCII #C7
    dt  0x88, 0x7C, 0xE8, 0xE1, 0x07    ; ASCII #C8
    dt  0x82, 0x7C, 0xE8, 0xE1, 0x07    ; ASCII #C9
    dt  0x44, 0x7D, 0xE8, 0xE1, 0x07    ; ASCII #CA
    dt  0x0A, 0x7C, 0xE8, 0xE1, 0x07    ; ASCII #CB
    dt  0x88, 0x38, 0x42, 0x88, 0x03    ; ASCII #CC
    dt  0x82, 0x38, 0x42, 0x88, 0x03    ; ASCII #CD
    dt  0x44, 0x39, 0x42, 0x88, 0x03    ; ASCII #CE
    dt  0x0A, 0x38, 0x42, 0x88, 0x03    ; ASCII #CF
    dt  0xC9, 0xB8, 0x08, 0xA7, 0x03    ; ASCII #D0
    dt  0x8A, 0xC6, 0x5C, 0x67, 0x04    ; ASCII #D1
    dt  0x88, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #D2
    dt  0x82, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #D3
    dt  0x44, 0xB9, 0x18, 0xA3, 0x03    ; ASCII #D4
    dt  0x8A, 0xBA, 0x18, 0xA3, 0x03    ; ASCII #D5
    dt  0x0A, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #D6
    dt  0x60, 0x3B, 0xE2, 0x36, 0x00    ; ASCII #D7
    dt  0x2E, 0xCE, 0x9A, 0xA3, 0x03    ; ASCII #D8
    dt  0x88, 0x80, 0x18, 0xA3, 0x03    ; ASCII #D9
    dt  0x82, 0x80, 0x18, 0xA3, 0x03    ; ASCII #DA
    dt  0x44, 0x81, 0x18, 0xA3, 0x03    ; ASCII #DB
    dt  0x0A, 0x80, 0x18, 0xA3, 0x03    ; ASCII #DC
    dt  0x04, 0x38, 0x42, 0x88, 0x03    ; ASCII #DD
    dt  0x0E, 0xBA, 0x10, 0x1D, 0x01    ; ASCII #DE
    dt  0x4C, 0x4A, 0x1B, 0x2D, 0x04    ; ASCII #DF
    dt  0x88, 0x38, 0x29, 0x65, 0x03    ; ASCII #E0
    dt  0x82, 0x38, 0x29, 0x65, 0x03    ; ASCII #E1
    dt  0x44, 0x39, 0x29, 0x65, 0x03    ; ASCII #E2
    dt  0x8A, 0x3A, 0x29, 0x65, 0x03    ; ASCII #E3
    dt  0x0A, 0x38, 0x29, 0x65, 0x03    ; ASCII #E4
    dt  0x04, 0x38, 0x29, 0x65, 0x03    ; ASCII #E5
    dt  0x00, 0xA8, 0x6A, 0xA9, 0x02    ; ASCII #E6
    dt  0xC0, 0x41, 0x18, 0x1D, 0x01    ; ASCII #E7
    dt  0x88, 0xB8, 0xE8, 0xA1, 0x03    ; ASCII #E8
    dt  0x82, 0xB8, 0xE8, 0xA1, 0x03    ; ASCII #E9
    dt  0x44, 0xB9, 0xE8, 0xA1, 0x03    ; ASCII #EA
    dt  0x0A, 0xB8, 0xE8, 0xA1, 0x03    ; ASCII #EB
    dt  0x88, 0x00, 0x46, 0x88, 0x03    ; ASCII #EC
    dt  0x82, 0x00, 0x46, 0x88, 0x03    ; ASCII #ED
    dt  0x44, 0x01, 0x46, 0x88, 0x03    ; ASCII #EE
    dt  0x0A, 0x00, 0x46, 0x88, 0x03    ; ASCII #EF
    dt  0xD1, 0xBC, 0xF8, 0x82, 0x01    ; ASCII #F0
    dt  0x8A, 0xDA, 0x1C, 0x63, 0x04    ; ASCII #F1
    dt  0x88, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #F2
    dt  0x82, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #F3
    dt  0x44, 0xB9, 0x18, 0xA3, 0x03    ; ASCII #F4
    dt  0x8A, 0xBA, 0x18, 0xA3, 0x03    ; ASCII #F5
    dt  0x0A, 0xB8, 0x18, 0xA3, 0x03    ; ASCII #F6
    dt  0x80, 0x80, 0x0F, 0x08, 0x00    ; ASCII #F7
    dt  0x00, 0xB8, 0x59, 0xB3, 0x03    ; ASCII #F8
    dt  0x88, 0x80, 0x94, 0x56, 0x01    ; ASCII #F9
    dt  0x82, 0x80, 0x94, 0x56, 0x01    ; ASCII #FA
    dt  0x44, 0x81, 0x94, 0x56, 0x01    ; ASCII #FB
    dt  0x40, 0x81, 0x94, 0x56, 0x01    ; ASCII #FC
    dt  0x00, 0x00, 0x46, 0x08, 0x01    ; ASCII #FD
    dt  0xC0, 0x41, 0x17, 0x1C, 0x01    ; ASCII #FE
    dt  0x0A, 0x44, 0x45, 0x08, 0x02    ; ASCII #FF

    END