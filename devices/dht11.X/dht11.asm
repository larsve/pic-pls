;**********************************************************************
; Description:
;   Send periodic read request to DHT11 sensor and decode bit-stream.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\common\src\mcu_defines.inc"
    #include    "defines.inc"
    #include    "..\..\common\src\constants.inc"
    #include    "..\..\common\src\input_output.inc"
    #include    "..\..\common\src\isr_timer.inc"
    #include    "..\..\common\src\macros.inc"

;***** Script local defines *******************************************

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  Init_CLogic
    GLOBAL  Do_CLogic
    GLOBAL  Do_PORT_IOC

    ;Data
    GLOBAL  DHT_RH              ; Relative humidity
    GLOBAL  DHT_Temp            ; Temperature
    GLOBAL  DHT_OK              ; Read OK
    GLOBAL  DHT_CRC             ; Read error

;***** Extern declarations ********************************************
    ; From InputOutput.asm
    Extern Input
    Extern InputD
    Extern Output

    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
gprbank1    udata
LState      res 1           ; Logic status bits
DHT_BitCnt  res 1           ; DHT11 stream bit count, complete message is 40 bits inc CRC
DHT_Bits    res 5           ; DHT11 bitstream buffer
DHT_RH      res 1           ; Relative humidity
DHT_Temp    res 1           ; Temperature
DHT_OK      res 1           ; Read OK
DHT_CRC     res 1           ; Read error
Timer       res 1           ; Time counter

; "Shared" temp variables..
Temp_Data   udata_ovr 0x6e
Temp        res 1
ISRTemp     res 1

;***** Constants ******************************************************
; Logic State bits
LS_Start        EQU 0x00        ; Start a new read cycle
LS_NewValue     EQU 0x01        ; New data to be precessed in bitstream
;LS_             EQU 0x02        ;
;LS_             EQU 0x03        ;
;LS_             EQU 0x04        ;
;LS_             EQU 0x05        ;
;LS_             EQU 0x06        ;
;LS_             EQU 0x07        ;

;***** Code Section ***************************************************
PROG0   code

    ;<editor-fold defaultstate="collapsed" desc="*** Init Controller Logic ****************">
;**********************************************************************
; Init_CLogic
;   Initializes variables and buffers.
;**********************************************************************
Init_CLogic
    ; Clear/init variables
    banksel LState
    clrf    LState
    clrf    DHT_RH
    clrf    DHT_Temp
    clrf    DHT_CRC
    clrf    DHT_OK
    clrf    DHT_BitCnt
    clrf    Timer

    ; Setup RB0 interrupt
    banksel IOCBP
    bcf     INTCON, IOCIE       ; Make sure interrupts are disabled, will be enabled when we should start to read from DHT11
    bsf     IOCBP, IOCBP0       ; Enable interrupt on positive edge on RB0

    ; Init Timer0 for DHT11 timing..
    banksel OPTION_REG
    bcf     OPTION_REG, T0CS    ; Clock on internal clock (Fosc/4)
    bcf     OPTION_REG, PSA     ; Prescalar assigned to Timer and not to WDT
#if OSC == 8
    bcf     OPTION_REG, PS2     ; @8MHz = 1LSB = 1us
    bcf     OPTION_REG, PS1     ;
    bcf     OPTION_REG, PS0     ;
#else
    error "Must use 8MHz or faster..."
#endif

    banksel LState
    bsf     LState, LS_Start    ; Start a new read cycly immediately
    return
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="*** Do Controller Logic ******************">
;**********************************************************************
; Do_CLogic
;   React to input changes and set output states.
;**********************************************************************
Do_CLogic
    banksel LState
    call    StartCycle
    call    DelayCycle
    call    ProcessBitStream
    return
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="*** Do PORT Interrupt On Change **********">
;**********************************************************************
; Do_PORT_IOC
;   ISR for PORT B on Change interrupts.
;**********************************************************************
Do_PORT_IOC
    ; Read and clear timer 0
    banksel TMR0
    movfw   TMR0
    movwf   ISRTemp
    clrf    TMR0

    ; Clear PORTB IOC flags
    banksel IOCBF
    clrf    IOCBF

    ; Bail if Timer 0 have wrapped around
    btfss   INTCON, TMR0IF
    goto    $ + 3
    bcf     INTCON, TMR0IF      ; Clear Timer 0 flag before bailing
    return

    ; Check the length of the timer value to descide if it's a 1 or 0, about 120ms = 1 and around 77ms = 0
    banksel ISRTemp
    movlw   98                  ; 98 = middle between 77ms and 129ms
    subwf   ISRTemp, w          ; C = 1 if TMR0 > W = pulse width > 98ms
    banksel DHT_Bits
    rlf     DHT_Bits + 4, f
    rlf     DHT_Bits + 3, f
    rlf     DHT_Bits + 2, f
    rlf     DHT_Bits + 1, f
    rlf     DHT_Bits, f
    decfsz  DHT_BitCnt, f
    return                      ; More bits to read, bail...

    ; Disable PORTB IOC interrupts now that we have all bits
    bcf     INTCON, IOCIE

    ; Let the controller logic know that we have a new value ready to be processed
    banksel LState
    bsf     LState, LS_NewValue
    return
    return
;</editor-fold>


;**********************************************************************
; Local routines
;**********************************************************************

    ;<editor-fold defaultstate="collapsed" desc="DelayCycle">
;**********************************************************************
; DelayCycle
;   Handles the delay between each read cycle
;**********************************************************************
DelayCycle
    banksel LState
    btfsc   LState, LS_Start
    return                      ; Start in progress, bail

    movfw   Timer
    skpnz
    goto    BeginDelayCycle

    ; Dec Timer until zero
    btfss   Timer_Tick, TimerTick_1000ms
    return
    decfsz  Timer, f
    return                      ; Timer > 0, bail

    bsf     LState, LS_Start    ; Flip state to begin a new DHT11 start cycle
    return
BeginDelayCycle
    ; Begin delay between reads..
    movlw   15                  ; 15second delay = read 4 times per minute
    movwf   Timer
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="ProcessBitStream">
ProcessBitStream
    banksel LState
    btfss   LState, LS_NewValue
    return                      ; No new value to process, bail
    bcf     LState, LS_NewValue

    ; Calc bitstream CRC
    movfw   DHT_Bits            ; RH MSB
    addwf   DHT_Bits + 1, w     ; RH LSB
    addwf   DHT_Bits + 2, w     ; Temp MSB
    addwf   DHT_Bits + 3, w     ; Temp LSB
    xorwf   DHT_Bits + 4, w     ; CRC
    skpz
    goto    ReadError

    ; Received data is OK, copy data from bitstream to variables
    movfw   DHT_Bits
    movwf   DHT_RH
    movfw   DHT_Bits + 2
    movwf   DHT_Temp

    ; Inc no of good values
    incf    DHT_OK, f
    return
ReadError
    ; Inc no of read errors
    incf    DHT_CRC, f
    ; Reduse time before next read to 5 seconds
    movlw   5
    movwf   Timer
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="StartCycle">
;**********************************************************************
; StartCycle
;   Handles the DHT11 start cycle
;**********************************************************************
StartCycle
    banksel LState
    btfss   LState, LS_Start
    return                      ; Should not start now, bail..

    movfw   Timer
    skpnz
    goto    BeginStartCycle

    ; Dec Timer until zero
    btfss   Timer_Tick, TimerTick_1ms
    return
    decfsz  Timer, f
    return                      ; Timer > 0, bail

    ; Start cycle complete, set RB0 as input and enable interrupts
    bcf     LState, LS_Start

    banksel TRISB
    bsf     TRISB, 0x00         ; Set RB0 as input again
    banksel DHT_BitCnt
    movlw   41
    movwf   DHT_BitCnt          ; Read 41 bits for a compleate read cycle
    banksel IOCBF
    clrf    IOCBF               ; Clear PORTB IOC flags before enabling interrupt
    bsf     INTCON, IOCIE       ; Enable IOC interrupts

    return

BeginStartCycle
    ; Disable PORTB IOC interrupts before toggling the pin
    bcf     INTCON, IOCIE

    ; DHT11 start cycle should be a low pulse dor at least 18ms
    movlw   19                  ; To be on the safe side, make it somewhere between 18 and 19ms..
    movwf   Timer

    banksel PORTB
    bcf     PORTB, 0x00         ; Make sure RB0 latch is zero
    banksel TRISB
    bcf     TRISB, 0x00         ; Set RB0 pin as output
    return
;</editor-fold>

;**********************************************************************
; GetLedTime
;   Get LedTime from a lookuptable based on LedTimeIdx and returns
;   the new LedTime value in W.
;**********************************************************************
;GetLedTime
;   pageselw    LedTimeLookup
;   movlw   LedTimeLookup
;   addwf   LedTimeIdx, w
;   btfsc   STATUS, C
;   incf    PCLATH, f
;   movwf   PCL
;LedTimeLookup
;   dt   0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x10
;   dt   0x11, 0x12, 0x12, 0x13, 0x13, 0x14, 0x14, 0x14
;   dt   0x14, 0x14, 0x14, 0x14, 0x13, 0x13, 0x12, 0x12
;   dt   0x11, 0x10, 0x10, 0x0F, 0x0E, 0x0D, 0x0C, 0x0B
;   dt   0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x04
;   dt   0x03, 0x02, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00
;   dt   0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x02
;   dt   0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
;   return

    END
