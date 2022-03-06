;******************************************************************************
; Description:
;   Initialize and enable global ISR flag. Also contains dummy ISR's
;   that disable that ISR that caused it to be triggerd, also clears
;   the interrupt flag in some cases. If you don't want the interrupt
;   but you want to be able to check the interrupt flag, a change of
;   the dummy ISR might be nesecarry.
;
;******************************************************************************
; Configuration points:
;   MSSP_ISR        Enable MSSP ISR
;
;******************************************************************************
; Notes:
;
;
;******************************************************************************

;***** Includes ***************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"

;***** Global declarations ****************************************************

    Global  Init_MainISR
    Global  Do_MainISR
#ifdef  __16F886
    Global  PCLATH_save
#endif

;***** Extern declarations ****************************************************

    ; From I2C_Main.asm
#ifdef MSSP_ISR
    Extern  Do_MSSP_ISR
    Extern  Do_I2CBCL_ISR
#endif

    ; From ISR_Timer.asm
    Extern  ISR_Timer

#ifdef PORTB_ISR
    Extern  Do_PORTB_ISR
#endif
#ifdef PORT_IOC
    Extern  Do_PORT_IOC
#endif

;***** Script variables *******************************************************

; RAM addresses in shared memory
Shared_Data udata_shr
IRF_temp    res 1   ; Temp Interrupt Request Flags
#ifdef __16F886
W_save      res 1   ; Save/Restore original W during ISR call
STATUS_save res 1   ; Save/Restore original STATUS during ISR call
PCLATH_save res 1   ; Save/Restore original PCLATH during ISR call

; RAM addresses in banked memory
gprbank0    udata
FSR_save    res 1   ; Save/Restore original FSR during ISR call
#endif

;***** ISR vector *************************************************************
ISR_VECT  CODE    0x0004        ; interrupt vector location
#ifdef  __16F886
    movwf   W_save              ; save off current W register contents
    swapf   STATUS, w           ; move status register into W register
    movwf   STATUS_save         ; save off contents of STATUS register
    movfw   PCLATH
    movwf   PCLATH_save
#endif
    pagesel Do_MainISR
    goto Do_MainISR             ; Goto MainISR routine declared in ISR_Main.asm


;***** ISR Main program *******************************************************
PROG0       code

;******************************************************************************
; Init MainISR
;   Pre-Initializes interrupt registers.
;******************************************************************************
Init_MainISR
    banksel PIR1
    clrf    PIR1                ; Clear Peripheral Interrupr Request Register 1
    clrf    PIR2                ; Clear Peripheral Interrupr Request Register 2
#ifdef  __16F1713
    clrf    PIR3
#endif
    ; Additional clearing of Interrupt Request flags might be nessecerry before enabling GIE

    bsf     INTCON, GIE         ; Set Global Interrupt Enable flag

    return

;******************************************************************************
; Do MainISR
;   Main Interrupt Service Routine (ISR) handler.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="PIC16F886 Main ISR">
#ifdef  __16F886
Do_MainISR
    ; Save FSR pointer
    banksel FSR_save
    movfw   FSR
    movwf   FSR_save

    ; Call Interrupt handlers here. Handler must clear interrupt flag
    ;<editor-fold defaultstate="collapsed" desc="Check the RBIF flag..">
    ; Check the RBIF flag (Both RBIE and RBIF is located in the INTCON register)
    movfw   INTCON              ; Don't need to check/set bank here coz INTCON is
    movwf   IRF_temp            ; available in all banks
    btfss   INTCON, RBIE
    bcf     IRF_temp, RBIF

    btfsc   IRF_temp, RBIF      ; PortB change interrupt?
#ifdef PORTB_ISR
    call    Do_PORTB_ISR
#else
    call    ClearINTCON_RBIE    ; Dummy call to clear PortB interrupt enable flag
#endif
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="Check PIR1 flags..">
    banksel PIR1
    movfw   PIR1
    movwf   IRF_temp
    banksel PIE1
    movfw   PIE1
    andwf   IRF_temp, F
    skpnz
    goto    NoPir1Int

    btfsc   IRF_temp, SSPIF     ; MSSP interrupt?
#ifdef MSSP_ISR
    call    Do_MSSP_ISR         ; Yes, handle I2C/MSSP interrupt
#else
    call    ClearPIR1_SSPIE     ; Dummy call to clear MSSP interrupt enable flag
#endif

    btfsc   IRF_temp, TMR1IF    ; Timer1 interrupt?
    call    ISR_Timer           ; Yes, call Timer ISR

    btfsc   IRF_temp, ADIF      ; AD conversion ready?
    call    ClearPIR1_ADIE      ; Dummy call to clear ADC interrupt enable flag

    btfsc   IRF_temp, RCIF      ; Receive char interrupt?
    call    ClearPIR1_RCIE      ; Dummy call to clear RX interrupt enable flag

    btfsc   IRF_temp, TXIF      ; Transmit char interrupt?
    call    ClearPIR1_TXIE      ; Dummy call to clear TX interrupt enable flag

    btfsc   IRF_temp, CCP1IF    ; CCP1 interrupt?
    call    ClearPIR1_CCP1IE    ; Dummy call to clear CCP1 interrupt enable flag

    btfsc   IRF_temp, TMR2IF    ; Timer2 interrupt?
    call    ClearPIR1_TMR2IE    ; Dummy call to clear Timer2 interrupt enable flag
NoPir1Int
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="Check PIR2 flags..">
    banksel PIR2                ; Make sure that we are in bank 0..
    movfw   PIR2
    movwf   IRF_temp
    bsf     STATUS, RP0
    movfw   PIE2
    andwf   IRF_temp, F
    skpnz
    goto    NoPir2Int

    btfsc   IRF_temp, BCLIF     ; Bus Collision interrupt?
#ifdef MSSP_ISR
    call    Do_I2CBCL_ISR       ; Yes, handle I2C/MSSP Bus Collition interrupt
#else
    call    ClearPIR2_BCLIE     ; Dummy call to clear MSSP interrupt enable flag
#endif

    btfsc   IRF_temp, OSFIF     ; Oscillator Failed interrupt?
    call    ClearPIR2_OSFIE     ; Dummy call to clear Oscillator Fail enable flag

    btfsc   IRF_temp, C2IF      ; Comparator2 interrupt?
    call    ClearPIR2_C2IE      ; Dummy call to clear Comparator2 interrupt enable flag

    btfsc   IRF_temp, C1IF      ; Comparator1 interrupt?
    call    ClearPIR2_C1IE      ; Dummy call to clear Comparator1 interrupt enable flag

    btfsc   IRF_temp, EEIF      ; EEprom write complete interrupt?
    call    ClearPIR2_EEIE      ; Dummy call to clear EEprom write complete interrupt enable flag

    btfsc   IRF_temp, ULPWUIF   ; Ultra Low-Power Wake-up interrupt?
    call    ClearPIR2_ULPWUIE   ; Dummy call to clear ULPWU interrupt flag

    btfsc   IRF_temp, CCP2IF    ; CCP2 interrupt?
    call    ClearPIR2_CCP2IE    ; Dummy call to clear CCP2 interrupt enable flag
NoPir2Int
    ;</editor-fold>

    ; Cleanup and restore pre-isr status
    ; after all ISR handlers are called

    ; Restore FSR pointer
    banksel FSR_save
    movfw   FSR_save
    movwf   FSR

    movfw   PCLATH_save
    movwf   PCLATH
    swapf   STATUS_save, w      ; retrieve copy of STATUS register
    movwf   STATUS              ; restore pre-isr STATUS register contents
    swapf   W_save,f
    swapf   W_save,w            ; restore pre-isr W register contents
    retfie
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PIC16F1713 Main ISR">
#ifdef  __16F1713
Do_MainISR
    ; Call Interrupt handlers here. Handler must clear interrupt flag

    ;<editor-fold defaultstate="collapsed" desc="Check PIR1 flags..">
    banksel PIR1
    movfw   PIR1
    movwf   IRF_temp
    banksel PIE1
    movfw   PIE1
    andwf   IRF_temp, F
    skpnz
    goto    NoPir1Int

    btfsc   IRF_temp, TMR1GIF   ; Timer1 Gate interrupt?
    call    ClearPIR1_TMR1GIE   ; Dummy call to clear Timer1 Gate interrupt enable flag

    btfsc   IRF_temp, ADIF      ; AD conversion ready?
    call    ClearPIR1_ADIE      ; Dummy call to clear ADC interrupt enable flag

    btfsc   IRF_temp, RCIF      ; Receive char interrupt?
    call    ClearPIR1_RCIE      ; Dummy call to clear RX interrupt enable flag

    btfsc   IRF_temp, TXIF      ; Transmit char interrupt?
    call    ClearPIR1_TXIE      ; Dummy call to clear TX interrupt enable flag

    btfsc   IRF_temp, SSP1IF    ; MSSP interrupt?
#ifdef MSSP_ISR
    call    Do_MSSP_ISR         ; Yes, handle I2C/MSSP interrupt
#else
    call    ClearPIR1_SSP1IE    ; Dummy call to clear SSP1 interrupt enable flag
#endif

    btfsc   IRF_temp, CCP1IF    ; CCP1 interrupt?
    call    ClearPIR1_CCP1IE    ; Dummy call to clear CCP1 interrupt enable flag

    btfsc   IRF_temp, TMR2IF    ; Timer2 interrupt?
    call    ClearPIR1_TMR2IE    ; Dummy call to clear Timer2 interrupt enable flag

    btfsc   IRF_temp, TMR1IF    ; Timer1 interrupt?
    call    ISR_Timer           ; Yes, call Timer ISR
NoPir1Int
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="Check PIR2 flags..">
    banksel PIR2                ; Make sure that we are in bank 0..
    movfw   PIR2
    movwf   IRF_temp
    banksel PIE2
    movfw   PIE2
    andwf   IRF_temp, F
    skpnz
    goto    NoPir2Int

    btfsc   IRF_temp, OSFIF     ; Oscillator Failed interrupt?
    call    ClearPIR2_OSFIE     ; Dummy call to clear Oscillator Fail enable flag

    btfsc   IRF_temp, C2IF      ; Comparator2 interrupt?
    call    ClearPIR2_C2IE      ; Dummy call to clear Comparator2 interrupt enable flag

    btfsc   IRF_temp, C1IF      ; Comparator1 interrupt?
    call    ClearPIR2_C1IE      ; Dummy call to clear Comparator1 interrupt enable flag

    btfsc   IRF_temp, BCL1IF    ; Bus Collision interrupt?
#ifdef MSSP_ISR
    call    Do_I2CBCL_ISR       ; Yes, handle I2C/MSSP Bus Collition interrupt
#else
    call    ClearPIR2_BCL1IE    ; Dummy call to clear Bus Collision interrupt enable flag
#endif

    btfsc   IRF_temp, TMR6IF    ; Timer6 to PR6 interrupt?
    call    ClearPIR2_TMR6IE    ; Dummy call to clear Timer6 to PR6 interrupt enable flag

    btfsc   IRF_temp, TMR4IF    ; Timer4 to PR4 interrupt?
    call    ClearPIR2_TMR4IE    ; Dummy call to clear Timer4 to PR4 interrupt enable flag

    btfsc   IRF_temp, CCP2IF    ; CCP2 interrupt?
    call    ClearPIR2_CCP2IE    ; Dummy call to clear CCP2 interrupt enable flag
NoPir2Int
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="Check PIR3 flags..">
    banksel PIR3                ; Make sure that we are in bank 0..
    movfw   PIR3
    movwf   IRF_temp
    banksel PIE3
    movfw   PIE3
    andwf   IRF_temp, F
    skpnz
    goto    NoPir3Int

    btfsc   IRF_temp, NCOIF     ; NCO interrupt?
    call    ClearPIR3_NCOIE     ; Dummy call to clear NCO enable flag

    btfsc   IRF_temp, COGIF     ; COG Auto-Shutdown interrupt?
    call    ClearPIR3_COGIE     ; Dummy call to clear COG Auto-Shutdown interrupt enable flag

    btfsc   IRF_temp, ZCDIF     ; Zero-Cross Detection interrupt?
    call    ClearPIR3_ZCDIE     ; Dummy call to clear Zero-Cross Detection interrupt enable flag

    btfsc   IRF_temp, CLC4IF    ; CLC4 interrupt?
    call    ClearPIR3_CLC4IE    ; Dummy call to clear CLC4 interrupt enable flag

    btfsc   IRF_temp, CLC3IF    ; CLC3 interrupt?
    call    ClearPIR3_CLC3IE    ; Dummy call to clear CLC3 interrupt enable flag

    btfsc   IRF_temp, CLC2IF    ; CLC2 interrupt?
    call    ClearPIR3_CLC2IE    ; Dummy call to clear CLC2 interrupt enable flag

    btfsc   IRF_temp, CLC1IF    ; CLC1 interrupt?
    call    ClearPIR3_CLC1IE    ; Dummy call to clear CLC1 interrupt enable flag
NoPir3Int
    ;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="Check the IOCIF flag..">
    ; Check the IOCIF flag (Both IOCIE and IOCIF is located in the INTCON register)
    banksel INTCON
    movfw   INTCON
    movwf   IRF_temp
    btfss   INTCON, IOCIE
    bcf     IRF_temp, IOCIF

    btfsc   IRF_temp, IOCIF     ; Interrupt On Change interrupt?
#ifdef PORT_IOC
    call    Do_PORT_IOC
#else
    call    ClearINTCON_IOCIE   ; Dummy call to clear PortB interrupt enable flag
#endif
    ;</editor-fold>

    retfie
#endif
;</editor-fold>




;******************************************************************************
; Dummy interrupt clearing routines
;   Routines that is overrided/unused in the MainISR routine can be
;   commented out to save program space if neccesarry.
;******************************************************************************

; PIR1 interrupt flags...
#ifdef __16F1713
ClearPIR1_TMR1GIE
    banksel PIE1                ; Bank 1
    bcf     PIE1, TMR1GIE       ; Clear Timer1 Gate enable bit, since it isn't used..
    return
#endif

ClearPIR1_ADIE
    banksel PIE1                ; Bank 1
    bcf     PIE1, ADIE          ; Clear A/D interrupt enable bit, since it isn't used..
    return

ClearPIR1_RCIE
    banksel PIE1
    bcf     PIE1, RCIE          ; Clear Receive interrupt enable bit, since it isn't used..
    return

ClearPIR1_TXIE
    banksel PIE1
    bcf     PIE1, TXIE          ; Clear Transmit interrupt enable bit, since it isn't used..
    return

#ifdef __16F886
ClearPIR1_SSPIE
    banksel PIE1
    bcf     PIE1, SSPIE         ; Clear MSSP interrupt enable bit, since it isn't used..
    return
#endif
#ifdef __16F1713
ClearPIR1_SSP1IE
    banksel PIE1
    bcf     PIE1, SSP1IE        ; Clear MSSP interrupt enable bit, since it isn't used..
    return
#endif

ClearPIR1_CCP1IE
    banksel PIE1
    bcf     PIE1, CCP1IE        ; Clear CCP1 interrupt enable bit, since it isn't used..
    return

ClearPIR1_TMR2IE
    banksel PIE1
    bcf     PIE1, TMR2IE        ; Clear Timer2 interrupt enable bit, since it isn't used..
    return

ClearPIR1_TMR1IE
    banksel PIE1
    bcf     PIE1, TMR1IE        ; Clear Timer1 interrupt enable bit, since it isn't used..
    return

; PIR2 interrupt flags...
ClearPIR2_OSFIE
    banksel PIE2
    bcf     PIE2, OSFIF         ; Clear Oscillator Fail interrupt enable bit, since it isn't used..
    return

ClearPIR2_C2IE
    banksel PIE2
    bcf     PIE2, C2IF          ; Clear Comparator C2 interrupt enable bit, since it isn't used..
    return

ClearPIR2_C1IE
    banksel PIE2
    bcf     PIE2, C1IF          ; Clear Comparator C2 interrupt enable bit, since it isn't used..
    return
#ifdef __16F886
ClearPIR2_EEIE
    banksel PIE2
    bcf     PIE2, EEIF          ; Clear EEprom write operation complete interrupt enable bit, since it isn't used..
    return

ClearPIR2_BCLIE
    banksel PIE2
    bcf     PIE2, BCLIF         ; Clear Bus Collision interrupt enable bit, since it isn't used..
    return

ClearPIR2_ULPWUIE
    banksel PIE2
    bcf     PIE2, ULPWUIF       ; Clear Ultra Low-Power Wake-up interrupt enable bit, since it isn't used..
    return
#endif
#ifdef __16F1713
ClearPIR2_BCL1IE
    banksel PIE2
    bcf     PIE2, BCL1IF            ; Clear Bus Collision interrupt enable bit, since it isn't used..
    return
#endif
ClearPIR2_CCP2IE
    banksel PIE2
    bcf     PIE2, CCP2IF        ; Clear CCP2 interrupt enable bit, since it isn't used..
    return

#ifdef __16F1713
ClearPIR2_TMR4IE
    banksel PIE2
    bcf     PIE2, TMR4IE
    return
#endif

#ifdef __16F1713
ClearPIR2_TMR6IE
    banksel PIE2
    bcf     PIE2, TMR6IE
    return
#endif

#ifdef __16F1713
ClearPIR3_NCOIE     ; Dummy call to clear NCO enable flag
    banksel PIE3
    bcf     PIE3, NCOIE
    return

ClearPIR3_COGIE     ; Dummy call to clear COG Auto-Shutdown interrupt enable flag
    banksel PIE3
    bcf     PIE3, COGIE
    return

ClearPIR3_ZCDIE     ; Dummy call to clear Zero-Cross Detection interrupt enable flag
    banksel PIE3
    bcf     PIE3, ZCDIE
    return

ClearPIR3_CLC4IE    ; Dummy call to clear CLC4 interrupt enable flag
    banksel PIE3
    bcf     PIE3, CLC4IE
    return

ClearPIR3_CLC3IE    ; Dummy call to clear CLC3 interrupt enable flag
    banksel PIE3
    bcf     PIE3, CLC3IE
    return

ClearPIR3_CLC2IE    ; Dummy call to clear CLC2 interrupt enable flag
    banksel PIE3
    bcf     PIE3, CLC2IE
    return

ClearPIR3_CLC1IE    ; Dummy call to clear CLC1 interrupt enable flag
    banksel PIE3
    bcf     PIE3, CLC1IE
    return

ClearINTCON_IOCIE
    banksel INTCON
    bcf     INTCON, IOCIE       ; Clear Interrupt On Change interrupt enable flag
#endif

#ifdef  __16F886
ClearINTCON_RBIE
    banksel INTCON
    bcf     INTCON, RBIE        ; Clear PortB change interrupt enable flag
    return
#endif
    END                         ; directive 'end of program'

