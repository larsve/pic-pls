;**********************************************************************
; Description:
;   Startup/initialization code for PIC16F886 MCU.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "MCU_Defines.inc"
    #include    "..\src\Defines.inc"

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
    banksel OSCCON
#if OSC == 20
    ; Select 8MHz operation..
    bsf     OSCCON, IRCF2
    bsf     OSCCON, IRCF1
    bsf     OSCCON, IRCF0
#endif
#if OSC == 8
    ; Select 8MHz operation..
    bsf     OSCCON, IRCF2
    bsf     OSCCON, IRCF1
    bsf     OSCCON, IRCF0
#endif
#if OSC == 4
    ; Select 4MHz operation.. (Default)
;   bsf     OSCCON, IRCF2
;   bsf     OSCCON, IRCF1
;   bcf     OSCCON, IRCF0
#endif
    ; Select 2MHz operation..
;   bsf     OSCCON, IRCF2
;   bcf     OSCCON, IRCF1
;   bsf     OSCCON, IRCF0

    ; Select 1MHz operation..
;   bsf     OSCCON, IRCF2
;   bcf     OSCCON, IRCF1
;   bcf     OSCCON, IRCF0

    ; Select 500kHz operation..
;   bcf     OSCCON, IRCF2
;   bsf     OSCCON, IRCF1
;   bsf     OSCCON, IRCF0

    ; Select 250kHz operation..
;   bcf     OSCCON, IRCF2
;   bsf     OSCCON, IRCF1
;   bcf     OSCCON, IRCF0

    ; Select 125kHz operation..
;   bcf     OSCCON, IRCF2
;   bcf     OSCCON, IRCF1
;   bsf     OSCCON, IRCF0

    ; Select 31kHz operation..
;   bcf     OSCCON, IRCF2
;   bcf     OSCCON, IRCF1
;   bcf     OSCCON, IRCF0
    goto    Main

    END
