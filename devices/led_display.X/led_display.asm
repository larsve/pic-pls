;**********************************************************************
; Description:
;   Interface a 8-charatcer 5x7 dot matrix LED display, similar to the
;   SCF5744, 4-charater display.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\common\src\mcu_defines.inc"
    #include    "defines.inc"
    #include    "..\..\common\src\input_output.inc"
    #include    "..\..\common\src\isr_timer.inc"
    #include    "..\..\common\src\macros.inc"

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  Init_CLogic
    GLOBAL  Do_CLogic

    ; Variables
;   GLOBAL  DisplayData
;   GLOBAL  State
;   GLOBAL  DisplayData
;***** Extern declarations ********************************************

    ; From LedFont.asm
    Extern  GetCharData
    Extern  CharData0
    Extern  CharData1
    Extern  CharData2
    Extern  CharData3
    Extern  CharData4

    ; From ISR_Timer.asm
    Extern  Timer_Tick

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
gprbank0    udata
DisplayData res 8           ; Display buffer
CharNo      res 1           ; Current character number
RowNo       res 1           ; Current row number
State       res 1           ; Status bits
idx         res 1

Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

; State bits
sWrite      EQU 0x00        ; Write data to display

;***** Code Section ***************************************************
PROG1       code

;**********************************************************************
; Init CLogic
;   Initializes variables and read default values from EEprom.
;**********************************************************************
Init_CLogic

    ; Clear/init variables
    banksel State
    clrf    State
    clrf    CharNo
    clrf    RowNo
    clrf    idx

    bcf     LedReset
    bsf     LedLoad
    bcf     LedData
    bcf     LedClk
    bsf     LedReset

    bsf     State, sWrite

    ; Init Display
    movlw   B'11101000'         ; Set LED brightness
    call    WriteLedByte

    SetFsr  DisplayData         ; Fill display buffer with dummy data..
    movlw   'Y'
    movwf   INDF
    incf    FSR, F
    movlw   'o'
    movwf   INDF
    incf    FSR, F
    movlw   ' '
    movwf   INDF
    incf    FSR, F
    movlw   'B'
    movwf   INDF
    incf    FSR, F
    movlw   'r'
    movwf   INDF
    incf    FSR, F
    movlw   'u'
    movwf   INDF
    incf    FSR, F
    movlw   'c'
    movwf   INDF
    incf    FSR, F
    movlw   'e'
    movwf   INDF

    return

;**********************************************************************
; Do CLogic
;   React to input changes and set output states.
;**********************************************************************
Do_CLogic
    banksel State
    btfsc   State, sWrite
    call    DoWrite

    ; TODO: Implement I2C comminication, similar to LCD display so that we can
    ; write to the display over the I2C bus

    btfss   Timer_Tick, TimerTick_1000ms
    return

    incf    idx, F

    movlw   HIGH BANNER_TABLE
    movwf   PCLATH

    movfw   idx
    andlw   0x03
    addlw   LOW BANNER_TABLE
    btfsc   STATUS, C
    incf    PCLATH,F
    movwf   PCL
BANNER_TABLE
    goto    Banner3
    goto    Banner1
    goto    Banner2
    goto    Banner3

Banner1
    bsf     State, sWrite

    SetFsr  DisplayData         ; Fill display buffer with dummy data..
    movlw   'E'
    movwf   INDF
    incf    FSR, F
    movlw   'x'
    movwf   INDF
    incf    FSR, F
    movlw   't'
    movwf   INDF
    incf    FSR, F
    movlw   'e'
    movwf   INDF
    incf    FSR, F
    movlw   'n'
    movwf   INDF
    incf    FSR, F
    movlw   'd'
    movwf   INDF
    incf    FSR, F
    movlw   'a'
    movwf   INDF
    incf    FSR, F
    movlw   ' '
    movwf   INDF
    return
Banner2
    bsf     State, sWrite

    SetFsr  DisplayData         ; Fill display buffer with dummy data..
    movlw   'B'
    movwf   INDF
    incf    FSR, F
    movlw   'o'
    movwf   INDF
    incf    FSR, F
    movlw   'o'
    movwf   INDF
    incf    FSR, F
    movlw   't'
    movwf   INDF
    incf    FSR, F
    movlw   'c'
    movwf   INDF
    incf    FSR, F
    movlw   'a'
    movwf   INDF
    incf    FSR, F
    movlw   'm'
    movwf   INDF
    incf    FSR, F
    movlw   'p'
    movwf   INDF
    return
Banner3
    clrf    idx

    bsf     State, sWrite

    SetFsr  DisplayData         ; Fill display buffer with dummy data..
    movlw   ' '
    movwf   INDF
    incf    FSR, F
    movlw   ' '
    movwf   INDF
    incf    FSR, F
    movlw   '2'
    movwf   INDF
    incf    FSR, F
    movlw   '0'
    movwf   INDF
    incf    FSR, F
    movlw   '1'
    movwf   INDF
    incf    FSR, F
    movlw   '2'
    movwf   INDF
    incf    FSR, F
    movlw   ' '
    movwf   INDF
    incf    FSR, F
    movlw   ' '
    movwf   INDF
    return


DoWrite
    movfw   CharNo              ; Select display character to update (0-7)
    andlw   B'00000111'
    iorlw   B'10100000'
    call    WriteLedByte

    SetFsrOfsF  DisplayData, CharNo
    movfw   INDF
    call    GetCharData         ; Char data in CharData0..CharData4

    movlw   0x07                ; Seven rows to write
    movwf   RowNo
WriteRowData
    movfw   CharData0
    andlw   0x1f                ; Mask 3 high bits
    call    WriteLedByte

    ; Shift CharData 5 bits
    rrf     CharData4, F
    rrf     CharData3, F
    rrf     CharData2, F
    rrf     CharData1, F
    rrf     CharData0, F

    rrf     CharData4, F
    rrf     CharData3, F
    rrf     CharData2, F
    rrf     CharData1, F
    rrf     CharData0, F

    rrf     CharData4, F
    rrf     CharData3, F
    rrf     CharData2, F
    rrf     CharData1, F
    rrf     CharData0, F

    rrf     CharData4, F
    rrf     CharData3, F
    rrf     CharData2, F
    rrf     CharData1, F
    rrf     CharData0, F

    rrf     CharData4, F
    rrf     CharData3, F
    rrf     CharData2, F
    rrf     CharData1, F
    rrf     CharData0, F

    decfsz  RowNo, F
    goto    WriteRowData

    incf    CharNo, f

    btfss   CharNo, 3
    return
    bcf     State, sWrite
    clrf    CharNo
    return


WriteLedByte
    ; No need to take special care of timing here, the display is faster, so
    ; even with a faster clock, we are not near violating the minimum timings of
    ; the display.
    movwf   Temp
    bcf     LedClk
    bcf     LedLoad

    btfss   Temp, 0
    bcf     LedData
    btfsc   Temp, 0
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 1
    bcf     LedData
    btfsc   Temp, 1
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 2
    bcf     LedData
    btfsc   Temp, 2
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 3
    bcf     LedData
    btfsc   Temp, 3
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 4
    bcf     LedData
    btfsc   Temp, 4
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 5
    bcf     LedData
    btfsc   Temp, 5
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 6
    bcf     LedData
    btfsc   Temp, 6
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    btfss   Temp, 7
    bcf     LedData
    btfsc   Temp, 7
    bsf     LedData
    bsf     LedClk
    bcf     LedClk

    bsf     LedLoad
    return
    END