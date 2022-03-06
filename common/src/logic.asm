;**********************************************************************
; Description:
;   Main logic, this should be the router or switch that monitors and
;   controls the other parts and make them work with each other.
;   Note. The A/D part should be moved to a separate unit.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "adc.inc"
    #include    "constants.inc"
    #include    "i2c.inc"
    #include    "input_output.inc"
    #include    "isr_timer.inc"
    #include    "macros.inc"

    errorlevel  -207            ; suppress message 207 from list file

;***** Script local defines *******************************************


;***** Global declarations ********************************************

    ; Methods
    GLOBAL  Init_Logic
    GLOBAL  Do_Logic

    ; Variables
    GLOBAL  Uptime

;***** Extern declarations ********************************************

    ; From InputOutput.asm
    Extern Input
    Extern InputD
    Extern Output

    ; From ISR_Timer.asm
    Extern Timer_Tick

#ifdef I2cActLed
    ; From I2C_*.asm
    Extern I2C_State
#endif


;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
Shared_Data udata_shr
LState      res 1           ; Logic & ADC status bits

; Allocate RAM addresses in bank 0 memory
gprbank0    udata
Uptime      res 4           ; Uptime counter
#ifdef I2cActLed
I2cActCnt   res 1           ; I2C activity timeout counter (used for switching running led between I2C activity or running LED)
#endif

; "Shared" temp variables..
Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** Constants ******************************************************
; Logic State bits
LS_Flash        EQU 0x00        ;
;LS_            EQU 0x01        ;
;LS_            EQU 0x02        ;
;LS_            EQU 0x03        ;
;LS_            EQU 0x04        ;
;LS_            EQU 0x05        ;
;LS_            EQU 0x06        ;
;LS_            EQU 0x07        ;

;***** Code Section ***************************************************
PROG0       code

;**********************************************************************
; Init Logic
;   Initializes variables and set default values.
;**********************************************************************
    ;<editor-fold defaultstate="collapsed" desc="Init_Logic">
Init_Logic
    ; Clear/init variables
    banksel LState
    clrf    LState
    ClearCounter    Uptime, 4

#ifdef I2cActLed
    clrf    I2cActCnt
#endif

    return
;</editor-fold>

;**********************************************************************
; Do Logic
;   React to input changes and set output states.
;**********************************************************************
Do_Logic
    banksel LState

    ; Flip Flash bit in LState
    movlw   1 << LS_Flash
    btfsc   Timer_Tick, TimerTick_1000ms
    xorwf   LState, F

#ifdef I2cActLed
    banksel I2C_State
    btfss   I2C_State, i2cBusy
    goto    SkipI2cActCntReset
    banksel I2cActCnt
    movlw   .50
    movwf   I2cActCnt
SkipI2cActCntReset
    banksel I2cActCnt
    movfw   I2cActCnt
    skpnz
    goto    $ + 4
    btfss   Timer_Tick, TimerTick_100ms
    goto    $ + 2
    decf    I2cActCnt, F
#endif
    call    Do_Uptime

    ; Set Output states
    banksel LState

    ; TODO: Kolla vilka program som vi ska ränsa Output för.
#ifdef PicIoController
    clrf    Output
#endif

#ifdef RunLed
    bcf     Output, outRunLed
    btfsc   LState, LS_Flash
    bsf     Output, outRunLed
#endif
#ifdef I2cActLed
    movfw   I2cActCnt
    skpnz
    goto    SkipI2cActLed
    bcf     Output, outRunLed
    banksel I2C_State
    btfss   I2C_State, i2cBusy
    goto    SkipI2cActLed
    banksel LState
    bsf     Output, outRunLed
SkipI2cActLed
    banksel LState
#endif

    return

;**********************************************************************
; Local routines
;**********************************************************************

    ;<editor-fold defaultstate="collapsed" desc="Do_Uptime">
;**********************************************************************
; Do_Uptime
;   Handle Uptime counter
;**********************************************************************
Do_Uptime
    ; Update uptime counter
    btfss   Timer_Tick, TimerTick_100ms
    return
    IncCounterNoIntr    Uptime, 4
    return
;</editor-fold>

    END
