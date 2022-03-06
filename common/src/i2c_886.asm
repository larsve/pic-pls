;******************************************************************************
; Description:
;   Methods to initialize and handle any I2C bus requests (we always
;   act as a I2C slave on the I2C bus. I2C adress is controlled by
;   various defines, that is defined in Defines.inc.
;
;******************************************************************************
; Notes:
;
;
;******************************************************************************

    #include    "MCU_Defines.inc"
    #include    "..\src\Defines.inc"
    #include    "I2C.inc"
    #include    "ISR_Timer.inc"

;***** Global declarations ****************************************************

    ; Methods
    GLOBAL  Init_I2C_HW
    GLOBAL  Reset_I2C_HW
    GLOBAL  Do_I2C_HW
    GLOBAL  Do_MSSP_ISR
    GLOBAL  Do_I2CBCL_ISR

;***** Extern declarations ****************************************************

    ; From I2C.asm
    Extern  I2C_State
    Extern  I2Ccrc
    Extern  I2CData
    Extern  I2CTO
    Extern  ReadCache
    Extern  Do_I2C_Read
    Extern  Do_I2C_Write

    ; From ISR_Timer.asm
    Extern  Timer_Tick

;***** Script variables *******************************************************

;----- Bank 0 -----------------------------------------------------------------
gprbank0    udata
cnt         res 1

;----- Overloaded temp variables ----------------------------------------------
Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** I2C Main program *******************************************************
PROG0       code

;******************************************************************************
; Init I2C_HW
;   Initializes I2C interrupt registers.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Init_I2C_HW">
Init_I2C_HW
    ; Initialize / Clear variables
    banksel TRISC                   ; Make sure that I2C SCL/SDA is set as input..
    bsf     TRISC, TRISC3
    bsf     TRISC, TRISC4

    ; Init I2C 7-bit slave mode...
    banksel SSPSTAT
    bsf     SSPSTAT, SMP

    ; Set slave address
    ; Reserved address space (7-bit):
    ; 0x00 - 0x07 and 0x78 - 7F (00 - 0F and F0 - FF)
#ifdef I2C_ADR
    movlw   I2C_ADR * 2
#else
    movlw   I2C_Address * 2
#endif
    movwf   SSPADD

    banksel SSPCON
    movlw   B'00111110'             ; SSPCON bits
                                    ;   WCOL  =    0 : Clear Collition Detected flag
                                    ;   SSPOV =    0 : Clear Receive Overflow flag
                                    ;   SSPEN =    1 : Enable I2C and configure SDA and SCL
                                    ;   CKP   =    1 : Enable clock on SCL (used for clock stretching by slaves)
                                    ;   SSPM  = 1110 : I2C 7-bit slave mode with Start/Stop interrupt
    movwf   SSPCON                  ; Set SSPCON register

    banksel PIE1                    ; Enable SSP and BCL interrupts
    bsf     PIE1, SSPIE
    ;bsf        PIE2, BCLIE
#ifdef I2Cdebug
    banksel TRISA
    bcf     TRISA, TRISA7
    bcf     TRISA, TRISA6
    bcf     TRISA, TRISA4
#endif
    return
;</editor-fold>

;******************************************************************************
; Reset I2C_HW
;   Resest I2C registers.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Reset_I2C_HW">
Reset_I2C_HW
    ; Check if CKP cleared
    banksel SSPCON
    btfsc   SSPCON, CKP
    goto    $ + 4
    movlw   0xff                    ; Send 0xff so that we don't draw SDA low
    movwf   SSPBUF                  ; Write to SSPBUF so that we can release SCL
    bsf     SSPCON, CKP             ; Set the CKP flag to release SCL

    bcf     SSPCON, SSPEN           ; Disable MSSP
    return
;</editor-fold>

;******************************************************************************
; Do I2C_HW
;   I2C maintenance.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Do_I2C_HW">
Do_I2C_HW
    ; Check i2cBusy flag..
    banksel I2C_State
    btfss   I2C_State, i2cBusy
#ifndef I2Cdebug
    return                          ; i2cBusy isn't set, bail..
#else
    goto    Do_I2C_HW_debug
#endif

    ; Check P-flag in SSP1STAT..
    banksel SSPSTAT
    btfss   SSPSTAT, P
#ifndef I2Cdebug
    return                          ; P-flag isn't set, bail..
#else
    goto    Do_I2C_HW_debug
#endif

    ; Clear states and setup read cache...
    banksel I2C_State
    bcf     I2C_State, i2cBusy      ; Clear I2C bus busy flag
    clrf    I2CData                 ; Reset internal I2C address index
    clrf    I2Ccrc                  ; Clear I2C crc
#ifndef I2Cdebug
    goto    Do_I2C_Read             ; Pre-load ReadCache to be ready for next read
#else
    call    Do_I2C_Read             ; Pre-load ReadCache to be ready for next read
#endif


#ifdef I2Cdebug
Do_I2C_HW_debug

    banksel I2C_State
    btfss   I2C_State, i2cBusy
    bcf     PORTA, RA7
    btfss   I2C_State, i2cBusy
    bcf     PORTA, RA6

    ; Check CKP, to see if we are clock stretching
    movlw   0x02
    btfsc   SSPCON, CKP
    movwf   cnt

    btfsc   SSPCON, CKP
    return

    movfw   cnt
    skpnz
    return

    btfss   Timer_Tick, TimerTick_1ms
    return                          ; No

    decfsz  cnt, f
    return

    movlw   0x80
    xorwf   PORTA, f

    banksel ReadCache
    goto    I2C_Read

    return
#endif
;</editor-fold>

;******************************************************************************
; Do MSSP ISR
;   I2C Interrupt Service Routine (ISR) handler.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Do_MSSP_ISR">
Do_MSSP_ISR
    banksel PIR1
    bcf     PIR1, SSPIF             ; Clear SSP Interrupt Flag
#ifdef I2Cdebug
    banksel PORTA
    movlw   0x40
    xorwf   PORTA, f
#endif

    ; If CKP is cleared then we are holding SCL low, ie the master want's to read data from us..
    banksel SSPCON
    btfss   SSPCON, CKP
    goto    I2C_Read

    ; If BF is set then we should read the data in SSPBUF
    banksel SSPSTAT
    btfsc   SSPSTAT, BF
    goto    I2C_Write

    return

I2C_Write                           ; I2C (master) Write
    banksel I2C_State
    bsf     I2C_State, i2cBusy      ; Set I2C bus busy flag
    movfw   SSPBUF                  ; A read from SSPBUF (Bank0) clears th BF flag in SSPSTAT
    movwf   ISRTemp                 ; Temporarily store in ISRTemp
    movlw   .10
    movwf   I2CTO
    bsf     I2C_State, i2cBusy      ; Set I2C bus busy flag
    movfw   ISRTemp                 ; Re-load written byte from ISRTemp
    goto    Do_I2C_Write            ; and call Do_I2C_Write

I2C_Read                            ; I2C (master) Read
    banksel ReadCache
    movfw   ReadCache
    movwf   SSPBUF                  ; write to SSBUF (Bank0) so it can be sent to the I2C master
    bsf     SSPCON, CKP             ; Set the CKP flag to release SCL
    xorwf   I2Ccrc, F               ; update crc value
#ifdef I2Cdebug
    movlw   0x10
    xorwf   PORTA, f
#endif
    incf    I2CData, F

    bsf     I2C_State, i2cBusy      ; Set I2C bus busy flag

    movlw   .10
    movwf   I2CTO

    goto    Do_I2C_Read
;</editor-fold>

;******************************************************************************
; Do I2CBCL ISR
;   I2C Bus Collition Interrupt Service Routine (ISR) handler.
;******************************************************************************
Do_I2CBCL_ISR
    return

    END                             ; directive 'end of program'

