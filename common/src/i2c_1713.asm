;******************************************************************************
; Description:
;   Methods to initialize and handle any I2C bus requests (we always
;   act as a I2C slave on the I2C bus. I2C adress is controled by
;   various defines, that is defined in Defines.inc.
;
;******************************************************************************
; Notes:
;
;
;******************************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "i2c.inc"

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
    Extern  RxPtr
    Extern  Do_I2C_Read
    Extern  Do_I2C_Write

;***** Script variables *******************************************************

;----- Bank 0 -----------------------------------------------------------------
;gprbank0   udata

;----- Overloaded temp variables ----------------------------------------------
Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** I2C Main program *******************************************************
PROG0       code

;******************************************************************************
; Init / Reset I2C
;   Initializes I2C interrupt registers.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Init_I2C_HW">
Init_I2C_HW
    ; Initialize / Clear variables
    banksel TRISC                   ; Make sure that I2C SCL/SDA is set as input..
    bsf     TRISC, TRISC3
    bsf     TRISC, TRISC4

    ; Setup I2C..
    banksel SSP1CON1
    bcf     SSP1CON1, SSPEN

    banksel SSP1ADD
#ifdef I2C_ADR
    movlw   I2C_ADR * 2
#else
    movlw   I2C_Address * 2         ; Set I2C slave address
#endif
    movwf   SSP1ADD

    bsf     SSP1STAT, SMP           ; Disable slew rate control (for standard speed mode)
    bcf     SSP1STAT, CKE           ; Disable SMBus specific inputs

    bcf     SSP1CON2, GCEN          ; Disable General Call ENable bit
    bsf     SSP1CON2, SEN           ; Enable Clock stretching (both receive and transmit)

    bsf     SSP1CON3, SDAHT         ; Enable SDA hold time (300ns)
    bcf     SSP1CON3, AHEN          ; Disable Address Hold ENanble bit
    bcf     SSP1CON3, DHEN          ; Disable Data Hold ENable bit

    movlw   B'00110110'             ; Enable SDA/SCL pins, Enable 7-bit address I2C slave mode (no Start/Stop interrupts)
    movwf   SSP1CON1

    banksel PIE1                    ; Enable SSP and BCL interrupts
    bsf     PIE1, SSP1IE
;   bsf     PIE2, BCL1IE

    return
;</editor-fold>

;******************************************************************************
; Reset I2C HW
;   Resest I2C registers.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Reset_I2C_HW">
Reset_I2C_HW
    ; Check if CKP cleared
    banksel SSP1CON1
    btfsc   SSP1CON1, CKP
    goto    $ + 4
    movlw   0xff                    ; Send 0xff so that we don't draw SDA low
    movwf   SSP1BUF                 ; Write to SSPBUF so that we can release SCL
    bsf     SSP1CON1, CKP           ; Set the CKP flag to release SCL

    bcf     SSP1CON1, SSPEN         ; Disable MSSP
    return
;</editor-fold>

;******************************************************************************
; Do I2C HW
;   I2C maintenance.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Do_I2C_HW">
Do_I2C_HW
    ; Check i2cBusy flag..
    banksel I2C_State
    btfss   I2C_State, i2cBusy
    return                          ; i2cBusy isn't set, bail..

    ; Check P-flag in SSP1STAT..
    banksel SSP1STAT
    btfss   SSP1STAT, P
    return                          ; P-flag isn't set, bail..

    ; Clear states and setup read cache...
    banksel I2C_State
    bcf     I2C_State, i2cBusy      ; Clear I2C bus busy flag
    clrf    I2CData                 ; Reset internal I2C address index
    clrf    I2Ccrc                  ; Clear I2C crc
    goto    Do_I2C_Read             ; Pre-load ReadCache to be ready for next read
    return
;</editor-fold>

;******************************************************************************
; Do MSSP ISR
;   I2C Interrupt Service Routine (ISR) handler.
;******************************************************************************
;<editor-fold defaultstate="collapsed" desc="Do_MSSP_ISR">
Do_MSSP_ISR
    banksel PIR1
    bcf     PIR1, SSP1IF            ; Clear SSP Interrupt Flag

    ; Check if master is reading or writing from/to us..
    banksel SSP1STAT
    btfss   SSP1STAT, R_NOT_W
    goto    I2C_Write

    ; I2C Master Read

    ; Check if this is the first byte the master is reading, then we can't check ACKSTAT..
    btfss   SSP1STAT, D_NOT_A
    goto    $ + 3
    btfsc   SSP1CON2, ACKSTAT
    return                          ; Last byte was data and master sent a NACK.

    banksel ReadCache
    movfw   ReadCache
    banksel SSP1BUF
    movwf   SSP1BUF                 ; write to SSBUF so it can be sent to the I2C master
    bsf     SSP1CON1, CKP           ; Set the CKP flag to release SCL
    banksel I2Ccrc
    xorwf   I2Ccrc, F               ; update crc value
    incf    I2CData, F

    ; Setup timeout if busy flag isn't yet set
    movlw   i2cTimeout
    btfss   I2C_State, i2cBusy
    movwf   I2CTO

    bsf     I2C_State, i2cBusy      ; Set I2C bus busy flag
    goto    Do_I2C_Read             ; Read next byte into pre-fetch buffer


I2C_Write                           ; I2C (master) Write
    banksel SSP1BUF
    movfw   SSP1BUF                 ; A read from SSP1BUF clears th BF flag in SSP1STAT
    bsf     SSP1CON1, CKP           ; Set the CKP flag to release SCL
    banksel ISRTemp
    movwf   ISRTemp                 ; Store read byte in ISRTemp

    ; Clear RxPtr if Busy flag isn't set..
    banksel I2C_State
    btfss   I2C_State, i2cBusy
    clrf    RxPtr

    ; Setup timeout if busy flag isn't yet set
    movlw   i2cTimeout
    btfss   I2C_State, i2cBusy
    movwf   I2CTO

    bsf     I2C_State, i2cBusy      ; Set I2C bus busy flag

    ; Check if read byte were address or data
    banksel SSP1STAT
    btfsc   SSP1STAT, D_NOT_A
    goto    Do_I2C_Write            ; It's data, write it to buffer
    return
;</editor-fold>

;**********************************************************************
; Do I2CBCL_ISR
;   I2C Bus Collition Interrupt Service Routine (ISR) handler.
;**********************************************************************
Do_I2CBCL_ISR
    return

    END                             ; directive 'end of program'