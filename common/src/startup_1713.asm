;**********************************************************************
; Description:
;   Startup/initialization code for PIC16F1713 MCU.
;
;**********************************************************************
; Configuration points:
;   ResetCause    Enables ResetFlags, to be able to see cause of reset.
;   ResetCounters Enables reset counters.
;
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "constants.inc"

;***** Global declarations ********************************************

    GLOBAL  Do_Startup
#ifdef ResetCause
    GLOBAL  ResetFlags
#ifdef ResetCounters        ; Reset counters
    GLOBAL  WdtCnt          ; Watchdog reset counter
    GLOBAL  MClrCnt         ; MCLR reset counter
    GLOBAL  ResetCnt        ; Reset instruction counter
    GLOBAL  BorCnt          ; Brown-out reset counter
    GLOBAL  SorCnt          ; Stack Overflow Reset counter
    GLOBAL  SurCnt          ; Stack Underflow Reset counter
#endif
#endif

;***** Extern declarations ********************************************

    Extern  Main

;***** Variables ******************************************************
#ifdef ResetCause
; Allocate RAM addresses in bank 1 memory
gprbank1    udata
ResetFlags  res 1           ; Reset cause flags
#ifdef ResetCounters
WdtCnt      res 1           ; Watchdog reset counter
MClrCnt     res 1           ; MCLR reset counter
ResetCnt    res 1           ; Reset instruction counter
BorCnt      res 1           ; Brown-out reset counter
SorCnt      res 1           ; Stack Overflow Reset counter
SurCnt      res 1           ; Stack Underflow Reset counter
#endif

; "Shared" temp variables..
Temp_Data   udata_ovr   0x6e
Temp        res 1
#endif

;***** Constants ******************************************************

;***** Code Section ***************************************************
PROG0       code

;**********************************************************************
; Do_Startup
;   Initializes oscillator and check brownout/wdt/etc flags.
;**********************************************************************
Do_Startup
    ; Enable FVR & Temperature sensor
    banksel FVRCON
    bsf     FVRCON, FVREN
    bsf     FVRCON, TSEN
    bsf     FVRCON, TSRNG       ; Temperature range Vdd - 4V

    ; Configure Oscillator
    banksel OSCCON
    movlw   B'01110000'         ; 8Mhz, No PLL, Clock source from FOSC in __CONFIG1
#if OSC == 32
    movlw   b'11110000'         ; 32MHz, 4x PLL, internal oscillator
#endif
#if OSC == 16
    movlw   b'01111010'         ; 16MHz, No PLL, internal oscillator
#endif
#if OSC == 8
    movlw   b'01110010'         ; 8MHz, No PLL, internal oscillator
#endif
#if OSC == 4
    movlw   b'01101010'         ; 4MHz, No PLL, internal oscillator
#endif
#if OSC == 2
    movlw   b'01100010'         ; 2MHz, No PLL, internal oscillator
#endif
#if OSC == 1
    movlw   b'01011010'         ; 1MHz, No PLL, internal oscillator
#endif
    movwf   OSCCON

#ifdef ResetCause
    call    CheckResetCause
#endif

#ifdef WDT
    ; Enable watchdog timer
    clrwdt
    banksel WDTCON
    movlw B'00111' << 1 | 1     ; Enable WDT and set timeout to 128ms (00111)
    movwf   WDTCON
#endif

    goto    Main

    ;<editor-fold defaultstate="collapsed" desc="CheckResetCause">
#ifdef ResetCause
CheckResetCause
    ; Save copy of PCON before we re-initialize it..
    banksel PCON
    movfw   PCON
    banksel Temp
    movwf   Temp
    banksel PCON
    movlw   B'00011111'
    movwf   PCON

    clrf    ResetFlags

    ; Use FSR0/IND0 to access Temp
    banksel ResetFlags
    movlw   High Temp
    movwf   FSR0H
    movlw   Temp
    movwf   FSR0L

    ; The order of these checks is from chapter 5.12 (Determining the Cause of a Reset) in the datasheet

    ; Check if it's a POR
    btfsc   INDF0, NOT_POR
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfPOR
    goto    ResetCauseChecked

    ; Check if it's a BOR
    btfsc   INDF0, NOT_BOR
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfBOR
    goto    ResetCauseChecked

    ; Check if it's a WDT reset
    btfsc   STATUS, NOT_TO
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfWDT
    goto    ResetCauseChecked

    ; Check if it's a MCLR reset
    btfsc   INDF0, NOT_RMCLR
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfMCLR
    goto    ResetCauseChecked

    ; Check if it's a reset instruction that caused the reset
    btfsc   INDF0, NOT_RI
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfRI
    goto    ResetCauseChecked

    ; Check for stack overflow reset
    btfsc   INDF0, STKOVF
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfSTKOF
    goto    ResetCauseChecked

    ; Check for stack underflow reset
    btfsc   INDF0, STKUNF
    goto    $ + 3               ; No, check other reset causes..
    bsf     ResetFlags, rfSTKUF
ResetCauseChecked

#ifdef ResetCounters
    ; Brown-out Reset?
    btfsc   ResetFlags, rfBOR
    incf    BorCnt, f

    ; Watchdog Timeout Reset?
    btfsc   ResetFlags, rfWDT
    incf    WdtCnt, f

    ; Stack overflow Reset?
    btfsc   ResetFlags, rfSTKOF
    incf    SorCnt,f

    ; Stack underflow Reset?
    btfsc   ResetFlags, rfSTKUF
    incf    SurCnt,f

    ; MClear Reset?
    btfsc   ResetFlags, rfMCLR
    incf    MClrCnt, f

    ; Reset instruction?
    btfsc   ResetFlags, rfRI
    incf    ResetCnt, f

    ; Power On Reset?
    btfss   ResetFlags, rfPOR
    return
    clrf    WdtCnt              ; Yes it's a POR, clear/initialize alla memory locations
    clrf    MClrCnt
    clrf    ResetCnt
    clrf    BorCnt
    clrf    SorCnt              ; Stack Overflow Reset
    clrf    SurCnt              ; Stack Underflow Reset
#endif
    return
#endif
;</editor-fold>


    END
