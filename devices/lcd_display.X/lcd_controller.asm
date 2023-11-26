;**********************************************************************
; Description:
;   Main logic, this should be the router or switch that monitors and
;   controls the other parts and make them work with eachother.
;   Note. The A/D part should be moved to a separate unit.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\Common\src\mcu_defines.inc"
    #include    "defines.inc"
    #include    "..\..\Common\src\constants.inc"
    #include    "..\..\Common\src\input_output.inc"
    #include    "..\..\Common\src\isr_timer.inc"
    #include    "..\..\Common\src\i2c.inc"
    #include    "..\..\common\src\version_information.inc"

    errorlevel  -207            ; suppress message 207 from list file

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  Init_CLogic
    GLOBAL  Do_CLogic

;***** Extern declarations ********************************************

    ; From InputOutput.asm
    Extern Input
    Extern InputD
    Extern Output

    ; From I2C_*.asm
    Extern RxPtr
    Extern I2cRxBuf
    Extern I2C_State

    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
gprbank0    udata
LcdState    res 1       ; Lcd controller states
LcdBufCnt   res 1
LcdBufIdx   res 1
#ifndef HW_PWM
LcdDimCnt   res 1
LcdDimTm    res 1
LcdDimVal   res 1
#endif

LcdBuffer   udata
LcdBuf      res 80

; "Shared" temp variables..
Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** Constants ******************************************************
; BaxiController Logic State bits and other constants

; LCD State bits
S_Init      EQU 0x00        ; Initialization in progress..
S_Flip      EQU 0x01

;***** Code Section ***************************************************
PROG0   code

;**********************************************************************
; Init CLogic
;   Initializes variables and read default values from EEprom.
;**********************************************************************
Init_CLogic
    ; LCD Controller Init
    banksel LcdState
    clrf    LcdState
    clrf    LcdBufIdx

    bsf     LcdState, S_Init

    movlw   0x01
    movwf   LcdBufCnt

#ifndef HW_PWM
    movlw   0x7f
    movwf   LcdDimVal

    bsf     Output, outBL
#endif
#ifdef __DEBUG
    banksel RxPtr
    movlw   20
    movwf   RxPtr
#endif
#ifdef HW_PWM
    ; Unlock PPS
    banksel PPSLOCK
    movlw   0x55
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bcf     PPSLOCK, PPSLOCKED  ; Unlock periheral registers

    ; Configure RC2 to output PWM3OUT
    banksel RC2PPS
    movlw   B'00001110'         ; PWM3OUT
    movwf   RC2PPS

    ; Lock PPS
    banksel PPSLOCK
    movlw   0x55        ; Issue the Lock/Unlock sequence..
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bsf     PPSLOCK, PPSLOCKED  ; Lock periheral registers

    ; Configure PWM
    banksel PWM3CON
    movlw   B'10000000'         ; Enable PWM 3, output = active high
    movwf   PWM3CON
    clrf    PWM3DCL
    movlw   0x0f
    movwf   PWM3DCH

    ; Set PWM 3 clock source to Timer 2
    banksel CCPTMRS
    bcf     CCPTMRS, 4
    bcf     CCPTMRS, 5

    ; Configure Timer2
    banksel PIE1
    bcf     PIE1, TMR2IE
    banksel PIR1
    bcf     PIR1, TMR2IF
    clrf    TMR2
    movlw   0x7e                ; Make PR2 < PWM2DCH max (0x7f) to have a Alway's ON PWM state
    movwf   PR2
    movlw   B'00000100'         ; Timer 2 ON, Prescaler = 1, Postscaler 1:1
    movwf   T2CON
#endif

    ; Setup LCD contrast control using FVR, DAC and Op Amp

    ; Set FVR buffer gain to 2x
    banksel FVRCON
    movfw   FVRCON
    andlw   B'11110011'         ; Mask CDAFVR bits
    iorlw   B'10001000'         ; Enable FVR, Set CDAFVR bits to 2x gain
    movwf   FVRCON

    ; Configure DAC1
    banksel DAC1CON0
    movlw   0xa0                ; Set DAC output to ca 1280mV
    movwf   DAC1CON1
    movlw   B'10001000'         ; DAC enable, use FVR buffer2 output and Vss, don't connect DAC to pins
    movwf   DAC1CON0

    ; Configure RA1 pin before enabling Op Amp output
    banksel TRISA
    bsf     TRISA, 0x02         ; Make sure RA1 is configured as input
    banksel ANSELA
    bsf     ANSELA, 0x01        ; Set RA1/OpAmp1OUT pin as a analog pin

    ; Configure Op Amp
    banksel OPA1CON
    movlw   B'11010010'         ; Enable OpAmp, connect - to output and + to DAC1
    movwf   OPA1CON

;    movlw   High LcdBuf
;    movwf   FSR0H
;    movlw   LcdBuf
;    movwf   FSR0L
;
;    movlw   'H'
;    movwi   FSR0++
;    movlw   'e'
;    movwi   FSR0++
;    movlw   'l'
;    movwi   FSR0++
;    movlw   'l'
;    movwi   FSR0++
;    movlw   'o'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   'W'
;    movwi   FSR0++
;    movlw   'o'
;    movwi   FSR0++
;    movlw   'r'
;    movwi   FSR0++
;    movlw   'l'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   '!'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .64
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '2'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .20
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '3'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .84
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '4'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .20
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '3'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .84
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '4'
;    movwi   FSR0++
    return
;   4 x 20
;   Rad 1: 00 - 19
;   Rad 2: 64 - 83
;   Rad 3: 20 - 39
;   Rad 4: 84 - 103
;**********************************************************************
; Do Logic
;   React to input changes and set output states.
;**********************************************************************
Do_CLogic
    banksel LcdBufCnt

#ifndef HW_PWM
    ; Backlight control
    decfsz  LcdDimCnt, F
    goto    $ + 5
    movfw   LcdDimVal
    movwf   LcdDimTm
    movlw   0x7e
    movwf   LcdDimCnt

    movfw   LcdDimTm
    skpz
    decf    LcdDimTm, F

    bcf     Output, outBL
    movfw   LcdDimTm
    skpz
    bsf     Output, outBL
#endif
    ; Flip
    movlw   1 << S_Flip
    xorwf   LcdState, F
    btfss   LcdState, S_Flip
    return

    call    Do_ProcessRxBuffer

    ; Check if we have anything to send to LCD
    banksel LcdBufCnt
    movfw   LcdBufCnt
    skpnz
    return

    ; Set TRISB as inputs
    banksel TRISB
    movlw   0xff
    movwf   TRISB

    ; Check busy flag
    banksel PORTB
    bcf     LcdRsPin
    bsf     LcdRwPin
    bsf     LcdEPin
    nop     ; Insert NOP to meet the minimum data setup time of max 190ns.
    nop
    nop
    movfw   PORTB       ; Save LCD output
    bcf     LcdEPin
    btfsc   WREG, 0x07
    return          ; LCD still busy, bail...

    ; Write data to display..
    banksel LcdState
    btfsc   LcdState, S_Init
    goto    InitLcd

    ; Fetch next char from buffer...
    movlw   High LcdBuf
    movwf   FSR0H
    movlw   LcdBuf
    addwf   LcdBufIdx, w
    movwf   FSR0L
    skpnc
    incf    FSR0H, F
    incf    LcdBufIdx, F
    decfsz  LcdBufCnt, F
    goto    $ + 2
    clrf    LcdBufIdx

    movfw   INDF0
    xorlw   0x10
    skpnz
    goto    ClearDisp

    movfw   INDF0
    xorlw   0x11
    skpnz
    goto    CursorHome

    movfw   INDF0
    xorlw   0x12
    skpnz
    goto    CursorPos

    movfw   INDF0
    xorlw   0x13
    skpnz
    goto    CursorOff

    movfw   INDF0
    xorlw   0x14
    skpnz
    goto    CursorOn

    movfw   INDF0
    xorlw   0x15
    skpnz
    goto    SetBacklight

    movfw   INDF0
    xorlw   0x16
    skpnz
    goto    SetContrast

    ; ...and write to LCD
    banksel PORTB
    bsf     LcdRsPin
    bcf     LcdRwPin
    movfw   INDF0
    goto    LcdWrite

ClearDisp
    banksel PORTB
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00000001'     ; Clear Display
    goto    LcdWrite

CursorHome
    banksel PORTB
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00000010'     ; Cursor home
    goto    LcdWrite

CursorPos
    banksel LcdBufCnt
    incf    LcdBufIdx, F
    decf    LcdBufCnt, F
    banksel PORTB
    bcf     LcdRsPin
    bcf     LcdRwPin
    moviw   ++FSR0
    andlw   0x7f
    iorlw   0x80
    goto    LcdWrite

CursorOff
    banksel PORTB
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00001100'     ; Display On, Cursor Off, Blink Off
    goto    LcdWrite

CursorOn
    banksel PORTB
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00001110'     ; Display On, Cursor On, Blink Off
    goto    LcdWrite

SetBacklight
    banksel LcdBufCnt
    incf    LcdBufIdx, F
    decf    LcdBufCnt, F
    moviw   ++FSR0
    andlw   0x7f
#ifndef HW_PWM
    movwf   LcdDimVal
#endif
#ifdef HW_PWM
    banksel PWM3DCH
    movwf   PWM3DCH
#endif
    return

SetContrast
    banksel LcdBufCnt
    incf    LcdBufIdx, F
    decf    LcdBufCnt, F
    moviw   ++FSR0
    banksel DAC1CON1
    movwf   DAC1CON1
    return

;<editor-fold defaultstate="collapsed" desc="InitLcd">
;**********************************************************************
; InitLcd
;   Initialize LCD display controller
;**********************************************************************
InitLcd
    ; Initialize LCD display
    incf    LcdBufCnt, F
    movlp   High INIT_LCD_TABLE
    movfw   LcdBufCnt
    andlw   0x0f
    addlw   LOW INIT_LCD_TABLE
    skpnc
    incf    PCLATH, F
    movwf   PCL
INIT_LCD_TABLE
    nop             ; 0x00
    nop             ; 0x01
    goto    InitLCD01       ; 0x02
    goto    InitLCD02       ; 0x03
    goto    InitLCD03       ; 0x04
    goto    InitLCD04       ; 0x05
    goto    InitLCD05       ; 0x06
    goto    InitLCD06       ; 0x07
    goto    InitLCD07       ; 0x08
    goto    InitLCD08       ; 0x09
    goto    InitLCD09       ; 0x10
    goto    InitLCD0a       ; 0x11
    goto    InitLCD0b       ; 0x12
    goto    InitLCD0c       ; 0x13
    goto    InitLCD0d       ; 0x14
    goto    InitLCD0e       ; 0x15
    goto    InitLCD0f       ; 0x16

InitLCD01
    banksel PORTB           ; Function set
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   1   DL  N   F   -   -
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00111000'     ; DL = 1 (8-bit), N = 1 (2-lines), F = 0 (5x8 dot)
    goto    LcdWrite

InitLCD02
    banksel PORTB           ; Clear Display and set address to 0
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   0   0   0   0   0   1
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00000001'     ; Clear Display
    goto    LcdWrite

InitLCD03
    banksel PORTB           ; Return home 
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   0   0   0   0   1   0
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00000010'
    goto    LcdWrite

InitLCD04
    banksel PORTB           ; Entry mode set
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   0   0   0   1   I/D S
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00000110'     ; I/D = 1 (Increment), S = 0 (Don't shift display)
    goto    LcdWrite

InitLCD05
    banksel PORTB           ; Display on/off control
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   0   0   1   D   C   B
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00001100'     ; D = 1 (Display On), C = 0 (Cursor Off), B = 0 (Blink Off)
    goto    LcdWrite

InitLCD06
    banksel PORTB           ; Cursor/display shift
                            ; RS R/w DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
                            ; 0  0   0   0   0   1   S/C R/L -   -
    bcf     LcdRsPin
    bcf     LcdRwPin
    movlw   B'00010100'     ; S/C = 0 (Cursor Move), R/L = 1 (Shift to right)
    goto    LcdWrite

InitLCD07
    banksel LcdState
    bcf     LcdState, S_Init
    movlw   35
    movwf   LcdBufCnt

    movlw   High LcdBuf
    movwf   FSR0H
    movlw   LcdBuf
    movwf   FSR0L

    movlw   0x11
    movwi   FSR0++
    movlw   'L'
    movwi   FSR0++
    movlw   'C'
    movwi   FSR0++
    movlw   'D'
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   'P'
    movwi   FSR0++
    movlw   'l'
    movwi   FSR0++
    movlw   's'
    movwi   FSR0++
    movlw   'P'
    movwi   FSR0++
    movlw   'I'
    movwi   FSR0++
    movlw   'C'
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   'v'
    movwi   FSR0++
    movlw   '0'+VerMajor
    movwi   FSR0++
    movlw   '.'
    movwi   FSR0++
    movlw   '0'+VerMinor
    movwi   FSR0++
    movlw   0x12
    movwi   FSR0++
    movlw   .64
    movwi   FSR0++
    movlw   'A'
    movwi   FSR0++
    movlw   'd'
    movwi   FSR0++
    movlw   'd'
    movwi   FSR0++
    movlw   'r'
    movwi   FSR0++
    movlw   ':'
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   '0'+I2C_ADR/10
    movwi   FSR0++
    movlw   '0'+I2C_ADR%10
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   '0'+LCD_X/10
    movwi   FSR0++
    movlw   '0'+LCD_X%10
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   'x'
    movwi   FSR0++
    movlw   ' '
    movwi   FSR0++
    movlw   '0'+LCD_Y
    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .20
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '3'
;    movwi   FSR0++
;    movlw   0x12
;    movwi   FSR0++
;    movlw   .84
;    movwi   FSR0++
;    movlw   'R'
;    movwi   FSR0++
;    movlw   'a'
;    movwi   FSR0++
;    movlw   'd'
;    movwi   FSR0++
;    movlw   ' '
;    movwi   FSR0++
;    movlw   '4'
;    movwi   FSR0++
    return
;   4 x 20
;   Rad 1: 00 - 19
;   Rad 2: 64 - 83
;   Rad 3: 20 - 39
;   Rad 4: 84 - 103
;    banksel PORTB
;    bcf     LcdRsPin
;    bcf     LcdRwPin
;    movlw   B'00000010'     ; Cursor home
;    goto    LcdWrite

InitLCD08
InitLCD09
InitLCD0a
InitLCD0b
InitLCD0c
InitLCD0d
InitLCD0e
InitLCD0f
    return

LcdWrite
    banksel PORTB
    movwf   PORTB

    ; Set TRISB as outputs
    banksel TRISB
    movlw   0x00
    movwf   TRISB

    banksel PORTB
    bsf     LcdEPin
    nop
    nop
    bcf     LcdEPin

    ; Set TRISB as inputs
    banksel TRISB
    movlw   0xff
    movwf   TRISB
    return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_ProcessRxBuffer">
;**********************************************************************
; Do_ProcessRxBuffer
;   Check if there is anything in the Rx buffer and process that.
;**********************************************************************
Do_ProcessRxBuffer
    banksel I2C_State
    btfsc   I2C_State, i2cBusy
    return

    banksel RxPtr
    movfw   RxPtr
    skpnz
    return                      ; RxPrt = 0, nothing new to process

    bcf     INTCON, GIE
    ; For now, just copy RxBuffer to LcdBuf
    movfw   RxPtr
    movwf   LcdBufCnt
    movwf   Temp
    clrf    LcdBufIdx
    clrf    RxPtr
    ; Copy I2cRxBuf to LcdBuf
    movlw   High LcdBuf
    movwf   FSR0H
    movlw   LcdBuf
    movwf   FSR0L

    movlw   High I2cRxBuf
    movwf   FSR1H
    movlw   I2cRxBuf
    movwf   FSR1L

    moviw   FSR1++
    movwi   FSR0++
    decfsz  Temp, F
    goto    $ - 3
    bsf     INTCON, GIE
    return
;</editor-fold>

    END
