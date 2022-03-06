;**********************************************************************
; Description:
;   Startup/initialization code for PIC16F1713 MCU.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"

;***** Global declarations ********************************************

    GLOBAL  Do_Startup

;***** Extern declarations ********************************************

    Extern  Main

;***** Variables ******************************************************

;***** Constants ******************************************************

;***** Code Section ***************************************************
PROG0       code

;**********************************************************************
; Do_Startup
;   Initializes oscillator and check brownout/wdt/etc flags.
;**********************************************************************
Do_Startup
    ; Enable FVR & Temperatues sensor
    banksel FVRCON
    bsf     FVRCON, FVREN
    bsf     FVRCON, TSEN
    bsf     FVRCON, TSRNG   ; Temperature range Vdd - 4V

    ; Configure Oscillator
    banksel OSCCON
    movlw   B'01110000' ; 8Mhz, No PLL, Clock source from FOSC in __CONFIG1
#if OSC == 32
    movlw   b'11110000' ; 32MHz, 4x PLL, internal oscillator
#endif
#if OSC == 16
    movlw   b'01111010' ; 16MHz, No PLL, internal oscillator
#endif
#if OSC == 8
    movlw   b'01110010' ; 8MHz, No PLL, internal oscillator
#endif
#if OSC == 4
    movlw   b'01101010' ; 4MHz, No PLL, internal oscillator
#endif
#if OSC == 2
    movlw   b'01100010' ; 2MHz, No PLL, internal oscillator
#endif
#if OSC == 1
    movlw   b'01011010' ; 1MHz, No PLL, internal oscillator
#endif
    movwf   OSCCON
    goto    Main

    END
