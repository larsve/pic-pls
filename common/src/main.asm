;**********************************************************************
; Description:
;   Program main. Define what parts should be used and in what order
;   they are initialized and called.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    ;<editor-fold defaultstate="collapsed" desc="PIC 16F886 CONFIG">
#ifdef __16F886
#if OSC == 20
    __CONFIG    _CONFIG1, _LVP_OFF & _PWRTE_ON & _WDT_OFF & _FOSC_HS
#else
    __CONFIG    _CONFIG1, _LVP_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO
#endif
    __CONFIG    _CONFIG2, _WRT_OFF & _BOR40V
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="PIC 16F1713 CONFIG">
#ifdef __16F1713
    __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_SWDTEN & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
    __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_OFF & _ZCDDIS_ON & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOR_ON & _LVP_OFF
#endif
;</editor-fold>
    #include    "constants.inc"
    #include    "input_output.inc"
    #include    "isr_timer.inc"

;***** Global declarations ********************************************

    Global  Main

;***** Extern declarations ********************************************

    ; From Startup_*.asm
    Extern  Do_Startup

    ; From ISR_Main.asm
    Extern  Init_MainISR
    Extern  Do_MainISR

    ; From ISR_Timer.asm
    Extern  Init_Timer
    Extern  Do_Timer
    Extern  Timer_Tick

#ifdef I2C
    ; From I2C_Main.asm
    Extern  Init_I2C
    Extern  Do_I2C
#endif

    ; From InputOutput.asm
    Extern  Init_IO
    Extern  Do_Input
    Extern  Do_Output
    Extern  Output

    ; From Logic.asm
    Extern  Init_Logic
    Extern  Do_Logic

#ifdef ADC
    ; From ADC.asm
    Extern  Init_ADC
    Extern  Do_ADC
#endif

#ifdef RS232
    Extern  Init_RS232
    Extern  Do_RS232
#endif

#ifdef ControllerLogic
    Extern  Init_CLogic
    Extern  Do_CLogic
#endif

;***** Startup ********************************************************
RES_VECT  CODE    0x0000        ; processor reset vector
    pagesel Do_Startup          ; ensure page bits are cleared
    goto Do_Startup             ; go to beginning of program

;***** Main program ***************************************************
PROG0 CODE

;**********************************************************************
; Main program loop
;**********************************************************************
Main
    pagesel Init_IO
    call    Init_IO
    call    Init_Timer
#ifdef ADC
    call    Init_ADC
#endif
#ifdef I2C
    call    Init_I2C
#endif
#ifdef RS232
    call    Init_RS232
#endif
    call    Init_Logic
#ifdef ControllerLogic
    pagesel Init_CLogic
    call    Init_CLogic
    pagesel Init_MainISR
#endif
    call    Init_MainISR        ; Enable interrupts

Main_Loop
    call    Do_Timer
    call    Do_Input
#ifdef ADC
    call    Do_ADC
#endif
#ifdef I2C
    call    Do_I2C
#endif
#ifdef RS232
    call    Do_RS232
#endif
    call    Do_Logic
#ifdef ControllerLogic
    pagesel Init_CLogic
    call    Do_CLogic
    pagesel Do_Output
#endif
    call    Do_Output
#ifdef WDT
    clrwdt
#endif
    goto    Main_Loop

    END                         ; directive 'end of program'

