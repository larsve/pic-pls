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
    #include    "i2c_constants.inc"
    #include    "isr_timer.inc"
    #include    "macros.inc"
    #include    "version_information.inc"

;***** Local script configurations ********************************************

#ifndef ADC
    #ifdef I2C_SendAdc
        #undefine I2C_SendAdc
    #endif
#endif

;***** I2C transfer and payload sizes *****************************************
; I2C data payload size
I2C_DataSize = 0

#ifdef I2C_SendAdc
I2C_DataSize += I2C_AdcBlockSize
#endif

#ifdef I2C_SendBaxi
I2C_DataSize += I2C_BaxiBlockSize
#endif

#ifdef I2C_SendDht11
I2C_DataSize += I2C_DHT11BlockSize
#endif

#ifdef I2C_SendLcd
I2C_DataSize += I2C_LcdBlockSize
#endif

#ifdef I2C_SendSpd
I2C_DataSize += I2C_SpdBlockSize
#endif

#ifdef I2C_SendStatus
I2C_DataSize += I2C_StatusBlockSize
#endif

#ifdef I2C_SendUptime
I2C_DataSize += I2C_Counter4BlockSize
#endif

#ifdef I2C_SendPvPic
I2C_DataSize += I2C_PvPicBlockSize
#endif

#ifdef I2C_SendSolPic
I2C_DataSize += I2C_SolPicBlockSize
#endif

; I2C transmission block size (including header payload and trailing CRC)
I2C_TxSize      EQU I2C_HeaderSize + I2C_DataSize + 1

;***** Global declarations ****************************************************
    ; Methods
    GLOBAL  Init_I2C
    GLOBAL  Do_I2C
    GLOBAL  Do_I2C_Read
    GLOBAL  Do_I2C_Write

    ; Variables
    GLOBAL  I2C_State
    GLOBAL  I2Ccrc
    GLOBAL  I2CData
    GLOBAL  I2CTO
    GLOBAL  ReadCache
    GLOBAL  RxPtr
    GLOBAL  I2cRxBuf

;***** Extern declarations ****************************************************

#ifdef I2C_SendAdc
    ; From ADC.asm
    Extern  AdcFlags
    Extern  AdcResets
#ifdef __16F886
    Extern  AN0
    Extern  AN1
    Extern  AN2
    Extern  AN3
    Extern  AN4
    Extern  AN5
    Extern  AN6
    Extern  AN7
    Extern  AN8
    Extern  AN9
    Extern  AN10
    Extern  AN11
    Extern  ANchnREF1p
    Extern  ANchnREF2p
    Extern  ANchnREF1m
    Extern  ANchnREF2m
#endif
#ifdef __16F1713
    Extern  AN0
    Extern  AN1
    Extern  AN2
    Extern  AN3
    Extern  AN4
    Extern  AN8
    Extern  AN9
    Extern  AN10
    Extern  AN11
    Extern  AN12
    Extern  AN13
    Extern  AN14
    Extern  AN15
    Extern  AN16
    Extern  AN17
    Extern  AN18
    Extern  AN19
    Extern  ANDac2
    Extern  ANTemp
    Extern  ANDac1
    Extern  ANFvr1
    Extern  ANFvr2
    Extern  ANFvr4
    Extern  ANRef1
    Extern  ANRef2
    Extern  ANRef3
    Extern  ANRef4
    Extern  ANRef5
#endif
#endif

#ifdef I2C_SendBaxi
    ; From BaxiController.asm
    Extern  Alarms
    Extern  RState
    Extern  DState
    Extern  MaxChn
    Extern  Inmatningar
    Extern  Backningar
    Extern  InmatTmActive
    Extern  InmatTmIdle
    Extern  SkruvPulser
    Extern  LastInTime
    Extern  OCLimitL
    Extern  OCLimitH
    Extern  ExhaustTemp
    Extern  WaterTemp
    Extern  PiIdleTm
    Extern  PiActTm
    Extern  PiRevTm
#endif

#ifdef I2C_SendDht11
    Extern  DHT_RH              ; Relative humidity
    Extern  DHT_Temp            ; Temperature
    Extern  DHT_OK              ; Read OK
    Extern  DHT_CRC             ; Read error
#endif

    ; From I2C_xxx.asm
    Extern  Init_I2C_HW
    Extern  Reset_I2C_HW
    Extern  Do_I2C_HW

    ; From ISR_Timer.asm
    Extern  Timer_Tick

#ifdef I2C_SendUptime
    ; From Logic.asm
    Extern  Uptime
#endif

#ifdef I2C_SendSpd
    ; From SPD100GD.asm
    Extern  SPD_State           ; SPD status bits
    Extern  SPD_B1              ; SPD High 6 bits of the 14-bit value
    Extern  SPD_B2              ; SPD Low 8 bits of the 14-bit value
    Extern  SPD_ReadOk          ; No of OK decoded values
    Extern  SPD_PE1             ; Parity error (byte #1)
    Extern  SPD_PE2             ; Parity error (byte #2)
    Extern  SPD_Restart
    Extern  SPD_BufPtr
    Extern  SPD_Buf             ; Cycle time buffer (22 bytes)
    Extern  SPD_AvgLo
    Extern  SPD_AvgHi
#endif

;***** Script variables *******************************************************

;----- Bank 0 -----------------------------------------------------------------
gprbank0    udata
I2C_State   res 1       ; I2C status
I2CData     res 1       ; I2C data index (internal address to read/write)
I2Ccrc      res 1       ; I2C data CRC
I2CTO       res 1       ; I2C TimeOut
I2C_Resets  res 1       ; I2C reset counter
ReadCache   res 1       ; Readahead cache
BufferB1    res 1       ; Transmission buffer 1 - 4
BufferB2    res 1       ;
BufferB3    res 1       ;
BufferB4    res 1       ;
RxPtr       res 1       ; Rx buffer pointer (offset within I2cRxBuf)

;----- Dynamic ----------------------------------------------------------------
I2cRxData   udata
I2cRxBuf    res i2cRxSize

;----- Overloaded temp variables ----------------------------------------------
Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

;***** I2C Main program *******************************************************
PROG0       code

;******************************************************************************
; Init / Reset I2C
;   Initializes I2C interrupt registers.
;**********************************************************************
Init_I2C
    ; Initialize / Clear variables
    banksel I2C_Resets
    clrf    I2C_Resets
Reset_I2C
    banksel I2C_State
    clrf    I2C_State
    clrf    I2CData
    clrf    I2Ccrc
    clrf    I2CTO
    clrf    BufferB1
    clrf    BufferB2
    clrf    BufferB3
    clrf    BufferB4
    clrf    RxPtr

    goto    Init_I2C_HW

;**********************************************************************
; Do I2C
;   I2C maintenance.
;**********************************************************************
Do_I2C
    call    Do_I2C_HW
    banksel I2C_State
    btfss   I2C_State, i2cBusy      ; Check if I2C are busy
    return                          ; No it's idle, bail

    ; Time to decrease timeout timer?
    btfss   Timer_Tick, TimerTick_1ms
    return                          ; No

    decfsz  I2CTO, F
    return                          ; TimeoutTimer still > 0, bail

    ; Timeout occured!
    incf    I2C_Resets, F
    call    Reset_I2C_HW
    goto    Reset_I2C

;**********************************************************************
; Do I2C Write
;   I2C master is writing data to us. Read byte is in ISRTemp.
;**********************************************************************
#ifdef __16F886
Do_I2C_Write                        ; I2C (master) Write
    banksel I2CData

    ; TODO: Save byte in ISRTemp to buffer

    movlw   .10
    movwf   I2CTO
    return
#endif
#ifdef __16F1713
Do_I2C_Write                        ; I2C (master) Write
    ; Set INDF0 to point to correct place in buffer to write to.
    banksel RxPtr
    movlw   High I2cRxBuf
    movwf   FSR0H
    movlw   I2cRxBuf
    addwf   RxPtr, w
    movwf   FSR0L
    skpnc
    incf    FSR0H, f

    ; Write read byte to buffer
    banksel ISRTemp
    movfw   ISRTemp
    movwf   INDF0

    ; Increase RxPtr and check against i2cRxSize so we don't write outside the buffer
    banksel RxPtr
    incf    RxPtr, f
    movlw   i2cRxSize
    subwf   RxPtr, w
    skpnc
    clrf    RxPtr               ; C = 1, so RxPtr >= i2cRxSize = Reset RxPrt

    return
#endif

;**********************************************************************
; Do I2C Read
;   I2C master is reading data from us.
;**********************************************************************
Do_I2C_Read                     ; I2C (master) Read
    banksel I2CData
    ; Check I2CData for a value to send...
    movlw   HIGH I2C_READ_TABLE
    movwf   PCLATH

    ; Check that we don't read outside the "buffer"
    movfw   I2CData
    sublw   I2C_TxSize          ; C = 1 if I2CData <= I2C_TxSize
    btfss   STATUS, C           ; C = 0 (I2CData > I2C_TxSize),
    movlw   I2C_TxSize          ; Set pointer to end of "buffer" (CRC byte)
    btfsc   STATUS, C           ; C = 1 (I2CData <= I2C_TxSize)
    movfw   I2CData             ; Set byte address in "buffer"

    movwf   ISRTemp
    bcf     STATUS, C
    rlf     ISRTemp, W          ; I2CData * 2 (every byte in "buffer" uses 2 instructions)
    addlw   LOW I2C_READ_TABLE
    btfsc   STATUS, C
    incf    PCLATH,F
    movwf   PCL
I2C_READ_TABLE
    ;<editor-fold defaultstate="collapsed" desc="16 Byte --- Header ------------------------">
    ; I2C Header 0x00 - 0x0f
    movlw   'Y'                 ;  1 - Magic[0]
    goto    WRITE_SSBUF
    movlw   'o'                 ;  2 - Magic[1]
    goto    WRITE_SSBUF
    movlw   'l'                 ;  3 - Magic[2]
    goto    WRITE_SSBUF
    movlw   't'                 ;  4 - Magic[3]
    goto    WRITE_SSBUF
    movlw   'h'                 ;  5 - Magic[4]
    goto    WRITE_SSBUF
    movlw   I2C_DeviceType      ;  6 - Device type
    goto    WRITE_SSBUF
    movlw   I2C_DeviceFunc      ;  7 - Device function (PCB/hardware)
    goto    WRITE_SSBUF
    movlw   I2C_Version         ;  8 - Firmware version
    goto    WRITE_SSBUF
    movlw   I2C_ProtocolVer     ;  9 - Protocol version
    goto    WRITE_SSBUF
    movlw   I2C_DataSize        ; 10 - Data payload size, not including trailing CRC byte
    goto    WRITE_SSBUF
    movlw   VerMajor            ; 11 - Version information (Major)
    goto    WRITE_SSBUF
    movlw   VerMinor            ; 12 - Version information (Minor)
    goto    WRITE_SSBUF
    movlw   VerPatch            ; 13 - Version information (Patch)
    goto    WRITE_SSBUF
    movlw   VerBuild            ; 14 - Version information (Build)
    goto    WRITE_SSBUF
    movlw   0x00                ; 15 - Vref
    goto    WRITE_SSBUF
    goto    WRITE_CRC           ; 16 - CRC
    nop
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="--- ADC data block --------------">
#ifdef I2C_SendAdc
    movlw   I2C_AdcBlockSize    ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_AdcBlockID      ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_AdcBlockVer     ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .0                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF

    movfw   AdcFlags            ;  5 - ADC Flags
    goto    WRITE_SSBUF
    movfw   AdcResets           ;  6 - ADC Resets
    goto    WRITE_SSBUF
    movlw   I2C_AdcHwVer        ;  7 - ADC Hardware version
    goto    WRITE_SSBUF

    ;<editor-fold defaultstate="collapsed" desc="PIC16F886">
#ifdef  __16F886
    movfw   AN0                 ;  8 - AN0 MSB
    goto    WRITE_SSBUF
    movfw   AN0 + 1             ;  9 - AN0 LSB
    goto    WRITE_SSBUF
    movfw   AN1                 ; 10 - AN1 MSB
    goto    WRITE_SSBUF
    movfw   AN1 + 1             ; 11 - AN1 LSB
    goto    WRITE_SSBUF
    movfw   AN2                 ; 12 - AN2 MSB
    goto    WRITE_SSBUF
    movfw   AN2 + 1             ; 13 - AN2 MSB
    goto    WRITE_SSBUF
    movfw   AN3                 ; 14 - AN3 MSB
    goto    WRITE_SSBUF
    movfw   AN3 + 1             ; 15 - AN3 MSB
    goto    WRITE_SSBUF
    movfw   AN4                 ; 16 - AN4 MSB
    goto    WRITE_SSBUF
    movfw   AN4 + 1             ; 17 - AN4 MSB
    goto    WRITE_SSBUF
    movfw   AN5                 ; 18 - AN5 MSB
    goto    WRITE_SSBUF
    movfw   AN5 + 1             ; 19 - AN5 MSB
    goto    WRITE_SSBUF
    movfw   AN6                 ; 20 - AN6 MSB
    goto    WRITE_SSBUF
    movfw   AN6 + 1             ; 21 - AN6 MSB
    goto    WRITE_SSBUF
    movfw   AN7                 ; 22 - AN7 MSB
    goto    WRITE_SSBUF
    movfw   AN7 + 1             ; 23 - AN7 MSB
    goto    WRITE_SSBUF
    movfw   AN8                 ; 24 - AN8 MSB
    goto    WRITE_SSBUF
    movfw   AN8 + 1             ; 25 - AN8 MSB
    goto    WRITE_SSBUF
    movfw   AN9                 ; 26 - AN9 MSB
    goto    WRITE_SSBUF
    movfw   AN9 + 1             ; 27 - AN9 MSB
    goto    WRITE_SSBUF
    movfw   AN10                ; 28 - AN10 MSB
    goto    WRITE_SSBUF
    movfw   AN10 + 1            ; 29 - AN10 MSB
    goto    WRITE_SSBUF
    movfw   AN11                ; 30 - AN11 MSB
    goto    WRITE_SSBUF
    movfw   AN11 + 1            ; 31 - AN11 MSB
    goto    WRITE_SSBUF
    movfw   ANchnREF1p          ; 32 - AN0 to AN7 +Vref bits
    goto    WRITE_SSBUF
    movfw   ANchnREF2p          ; 33 - AN8 to AN11 +Vref bits
    goto    WRITE_SSBUF
    movfw   ANchnREF1m          ; 34 - AN0 to AN7 -Vref bits
    goto    WRITE_SSBUF
    movfw   ANchnREF2m          ; 35 - AN8 to AN11 -Vref bits
    goto    WRITE_SSBUF
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="PIC16F1713">
#ifdef __16F1713
    movfw   AN0                 ;  8 - AN0 MSB
    goto    WRITE_SSBUF
    movfw   AN0 + 1             ;  9 - AN0 LSB
    goto    WRITE_SSBUF
    movfw   AN1                 ; 10 - AN1 MSB
    goto    WRITE_SSBUF
    movfw   AN1 + 1             ; 11 - AN1 LSB
    goto    WRITE_SSBUF
    movfw   AN2                 ; 12 - AN2 MSB
    goto    WRITE_SSBUF
    movfw   AN2 + 1             ; 13 - AN2 LSB
    goto    WRITE_SSBUF
    movfw   AN3                 ; 14 - AN3 MSB
    goto    WRITE_SSBUF
    movfw   AN3 + 1             ; 15 - AN3 LSB
    goto    WRITE_SSBUF
    movfw   AN4                 ; 16 - AN4 MSB
    goto    WRITE_SSBUF
    movfw   AN4 + 1             ; 17 - AN4 LSB
    goto    WRITE_SSBUF
    movfw   AN8                 ; 18 - AN8 MSB
    goto    WRITE_SSBUF
    movfw   AN8 + 1             ; 19 - AN8 LSB
    goto    WRITE_SSBUF
    movfw   AN9                 ; 20 - AN9 MSB
    goto    WRITE_SSBUF
    movfw   AN9 + 1             ; 21 - AN9 LSB
    goto    WRITE_SSBUF
    movfw   AN10                ; 22 - AN10 MSB
    goto    WRITE_SSBUF
    movfw   AN10 + 1            ; 23 - AN10 LSB
    goto    WRITE_SSBUF
    movfw   AN11                ; 24 - AN11 MSB
    goto    WRITE_SSBUF
    movfw   AN11 + 1            ; 25 - AN11 LSB
    goto    WRITE_SSBUF
    movfw   AN12                ; 26 - AN12 MSB
    goto    WRITE_SSBUF
    movfw   AN12 + 1            ; 27 - AN12 LSB
    goto    WRITE_SSBUF
    movfw   AN13                ; 28 - AN13 MSB
    goto    WRITE_SSBUF
    movfw   AN13 + 1            ; 29 - AN13 LSB
    goto    WRITE_SSBUF
    movfw   AN14                ; 30 - AN14 MSB
    goto    WRITE_SSBUF
    movfw   AN14 + 1            ; 31 - AN14 LSB
    goto    WRITE_SSBUF
    movfw   AN15                ; 32 - AN15 MSB
    goto    WRITE_SSBUF
    movfw   AN15 + 1            ; 33 - AN15 LSB
    goto    WRITE_SSBUF
    movfw   AN16                ; 34 - AN16 MSB
    goto    WRITE_SSBUF
    movfw   AN16 + 1            ; 35 - AN16 LSB
    goto    WRITE_SSBUF
    movfw   AN17                ; 36 - AN17 MSB
    goto    WRITE_SSBUF
    movfw   AN17 + 1            ; 37 - AN17 LSB
    goto    WRITE_SSBUF
    movfw   AN18                ; 38 - AN18 MSB
    goto    WRITE_SSBUF
    movfw   AN18 + 1            ; 39 - AN18 LSB
    goto    WRITE_SSBUF
    movfw   AN19                ; 40 - AN19 MSB
    goto    WRITE_SSBUF
    movfw   AN19 + 1            ; 41 - AN19 LSB
    goto    WRITE_SSBUF
    movfw   ANDac2              ; 42 - AN DAC2 MSB
    goto    WRITE_SSBUF
    movfw   ANDac2 + 1          ; 43 - AN DAC2 LSB
    goto    WRITE_SSBUF
    movfw   ANTemp              ; 44 - AN Temperature MSB
    goto    WRITE_SSBUF
    movfw   ANTemp + 1          ; 45 - AN Temperature LSB
    goto    WRITE_SSBUF
    movfw   ANDac1              ; 46 - AN DAC1 MSB
    goto    WRITE_SSBUF
    movfw   ANDac1 + 1          ; 47 - AN DAC1 LSB
    goto    WRITE_SSBUF
    movfw   ANFvr1              ; 48 - AN Fixed Voltage Reference @ 1.024V MSB
    goto    WRITE_SSBUF
    movfw   ANFvr1 + 1          ; 49 - AN Fixed Voltage Reference @ 1.024V LSB
    goto    WRITE_SSBUF
    movfw   ANFvr2              ; 50 - AN Fixed Voltage Reference @ 2.048V MSB
    goto    WRITE_SSBUF
    movfw   ANFvr2 + 1          ; 51 - AN Fixed Voltage Reference @ 2.048V LSB
    goto    WRITE_SSBUF
    movfw   ANFvr4              ; 52 - AN Fixed Voltage Reference @ 4.096V MSB
    goto    WRITE_SSBUF
    movfw   ANFvr4 + 1          ; 53 - AN Fixed Voltage Reference @ 4.096V LSB
    goto    WRITE_SSBUF
    movfw   ANRef1              ; 54 - AN +Vref 1
    goto    WRITE_SSBUF
    movfw   ANRef2              ; 55 - AN +Vref 2
    goto    WRITE_SSBUF
    movfw   ANRef3              ; 56 - AN +Vref 3
    goto    WRITE_SSBUF
    movfw   ANRef4              ; 57 - AN +Vref 4
    goto    WRITE_SSBUF
    movfw   ANRef5              ; 58 - AN +Vref 5
    goto    WRITE_SSBUF
#endif
;</editor-fold>
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="--- Baxi data block -------------">
#ifdef I2C_SendBaxi
    ; Baxi Special data block...
    movlw   I2C_BaxiBlockSize   ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_BaxiBlockID     ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_BaxiBlockVer    ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .0                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF_AND_COPY_Inmtningr

    movfw   BufferB1            ;  5 - Inmatningar LSB
    goto    WRITE_SSBUF
    movfw   BufferB2            ;  6 - Inmatningar
    goto    WRITE_SSBUF
    movfw   BufferB3            ;  7 - Inmatningar
    goto    WRITE_SSBUF
    movfw   BufferB4            ;  8 - Inmatningar MSB
    goto    WRITE_SSBUF_AND_COPY_TmAct_Idl

    movfw   BufferB1            ;  9 - InmatTmActive LSB
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 10 - InmatTmActive MSB
    goto    WRITE_SSBUF

    movfw   BufferB3            ; 11 - InmatTmIdle LSB
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 12 - InmatTmIdle MSB
    goto    WRITE_SSBUF_AND_COPY_SkruvPlsr

    movfw   BufferB1            ; 13 - SkruvPulser LSB
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 14 - SkruvPulser
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 15 - SkruvPulser
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 16 - SkruvPulser MSB
    goto    WRITE_SSBUF_AND_COPY_Status1

    movfw   BufferB1            ; 17 - Alarms
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 18 - RState
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 19 - MaxChn
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 20 - OCLimitL (gräns för att backa)
    goto    WRITE_SSBUF_AND_COPY_Status2
    movfw   BufferB1            ; 21 - OCLimitH (gräns för att stoppa)
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 22 - Last Baxi Input Time (@192ms ticks)
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 23 - ExhaustTemp
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 24 - WaterTemp
    goto    WRITE_SSBUF_AND_COPY_Backningar
    movfw   BufferB1            ; 25 - Backningar LSB
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 26 - Backningar
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 27 - Backningar
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 28 - Backningar MSB
    goto    WRITE_SSBUF_AND_COPY_Status3
    movfw   BufferB1            ; 29 - PiIdleTm LSB
    goto    WRITE_SSBUF
    movfw   BufferB2            ; 30 - PiIdleTm MSB
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 31 - PiActTm
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 32 - PiRevTm
    goto    WRITE_SSBUF
    ; DState ?
#endif ;}
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="--- DHT11 data block ------------">
#ifdef I2C_SendDht11
    ; DHT11 special data block...
    movlw   I2C_DHT11BlockSize  ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_DHT11BlockID    ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_DHT11BlockVer   ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .0                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF_AND_COPY_DHT11

    movfw   BufferB1            ;  5 - Relative humidity
    goto    WRITE_SSBUF
    movfw   BufferB2            ;  6 - Temperature
    goto    WRITE_SSBUF
    movfw   BufferB3            ;  7 - Read OK
    goto    WRITE_SSBUF
    movfw   BufferB4            ;  8 - Read errors
    goto    WRITE_SSBUF
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="--- LCD data block --------------">
#ifdef I2C_SendLcd
    movlw   I2C_LcdBlockSize    ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_LcdBlockID      ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_LcdBlockVer     ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .0                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF
    movlw   LCD_X               ;  5 - LCD X
    goto    WRITE_SSBUF
    movlw   LCD_Y               ;  6 - LCD Y
    goto    WRITE_SSBUF
    movlw   0x00                ;  7 - LCD features #1
    goto    WRITE_SSBUF
    movlw   0x00                ;  8 - LCD features #1
    goto    WRITE_SSBUF
    movlw   0x00                ;  9 - LCD features #1
    goto    WRITE_SSBUF
    movlw   0x00                ; 10 - LCD features #1
    goto    WRITE_SSBUF
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="--- SPD data block --------------">
#ifdef I2C_SendSpd
    movlw   I2C_SpdBlockSize    ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_SpdBlockID      ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_SpdBlockVer     ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .3                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF
    movlw   'S'                 ;  5 - Block ID Name
    goto    WRITE_SSBUF
    movlw   'P'                 ;  6 - Block ID Name
    goto    WRITE_SSBUF
    movlw   'D'                 ;  7 - Block ID Name
    goto    WRITE_SSBUF

    movfw   SPD_AvgLo           ;  8 - SPD byte #2 (LSB)
    goto    WRITE_SSBUF
    movfw   SPD_AvgHi           ;  9 - SPD byte #1 (MSB)
    goto    WRITE_SSBUF


    movfw   SPD_B1              ; 10 - SPD byte #1 (MSB)
    goto    WRITE_SSBUF
    movfw   SPD_B2              ; 11 - SPD byte #2 (LSB)
    goto    WRITE_SSBUF
    movlw   0x00                ; 12 - SPD byte #3
    goto    WRITE_SSBUF

    movfw   SPD_PE1             ; 13 - SPD Parity Error byte #1
    goto    WRITE_SSBUF
    movfw   SPD_PE2             ; 14 - SPD Parity Error byte #2
    goto    WRITE_SSBUF
    movlw   0x00                ; 15 - SPD Parity Error byte #3
    goto    WRITE_SSBUF

    movfw   SPD_ReadOk          ; 16 - No or OK SPD reads (wrapps around after 255)
    goto    WRITE_SSBUF
    movlw   0x00                ; 17 - Seconds since start (wrapps around after 255)
    goto    WRITE_SSBUF
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="--- Uptime data block -----------">
#ifdef I2C_SendUptime
    movlw   I2C_Counter4BlockSize   ;  1 - Block size
    goto    WRITE_SSBUF
    movlw   I2C_Counter4BlockID     ;  2 - Block ID Type
    goto    WRITE_SSBUF
    movlw   I2C_Counter4BlockVer    ;  3 - Block ID Version
    goto    WRITE_SSBUF

    movlw   .3                  ;  4 - Block ID Name Length
    goto    WRITE_SSBUF
    movlw   'U'                 ;  5 - Block ID Name
    goto    WRITE_SSBUF
    movlw   'p'                 ;  6 - Block ID Name
    goto    WRITE_SSBUF
    movlw   't'                 ;  7 - Block ID Name
    goto    WRITE_SSBUF_AND_COPY_UPTIME

    movfw   BufferB1            ;  8 - CounterB1
    goto    WRITE_SSBUF
    movfw   BufferB2            ;  9 - CounterB2
    goto    WRITE_SSBUF
    movfw   BufferB3            ; 10 - CounterB3
    goto    WRITE_SSBUF
    movfw   BufferB4            ; 11 - CounterB4
    goto    WRITE_SSBUF
#endif
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="--- CRC -------------------------">
    clrf    I2CData             ; Reset Data index
    goto    WRITE_CRC           ; CRC
    ;nop
    ; Dummy fill, just in case we read out side of the "buffer"...
    movlw   0x0f                ; EOF, return 0x0f
    goto    WRITE_SSBUF
    movlw   0x0f                ; EOF, return 0x0f
    goto    WRITE_SSBUF
    movlw   0x0f                ; EOF, return 0x0f
    goto    WRITE_SSBUF
    movlw   0x0f                ; EOF, return 0x0f
    goto    WRITE_SSBUF
    movlw   0x0f                ; EOF, return 0x0f
    goto    WRITE_SSBUF
;</editor-fold>

WRITE_SSBUF
    movwf   ReadCache
    return

    ;<editor-fold defaultstate="collapsed" desc="WRITE_CRC">
WRITE_CRC                       ; Add a number (42) to CRC if it's = 0xff
    movfw   I2Ccrc
    xorlw   0xff
    movlw   0x00
    skpnz
    movlw   .42
    addwf   I2Ccrc, F
    movfw   I2Ccrc
    goto    WRITE_SSBUF
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="WRITE_SSBUF_AND_COPY_DHT11">
#ifdef I2C_SendDht11
#ifdef __16F1713
WRITE_SSBUF_AND_COPY_DHT11
    ; Start to write value in W to I2C register and start the sending..
    movwf   ReadCache
    ; Copy data to buffer
    movlw   High DHT_RH
    movwf   FSR0H
    movlw   DHT_RH
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4
#endif
    return
#endif
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="WRITE_SSBUF_AND_COPY_UPTIME">
WRITE_SSBUF_AND_COPY_UPTIME
    ; Start to write value in W to I2C register and start the sending..
    movwf   ReadCache

    ; Copy Uptime counter to Temp registers.
#ifdef __16F886
    SetFsr  Uptime
    movfw   INDF
    movwf   BufferB1
    incf    FSR, F
    movfw   INDF
    movwf   BufferB2
    incf    FSR, F
    movfw   INDF
    movwf   BufferB3
    incf    FSR, F
    movfw   INDF
    movwf   BufferB4
#endif
#ifdef __16F1713
    movlw   High Uptime
    movwf   FSR0H
    movlw   Uptime
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4
#endif
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="BaxiController WRITE_SSBUF_...">
#ifdef BaxiController           ; Baxi (ADC MAX data block and Baxi special data block) ;{
WRITE_SSBUF_AND_COPY_Inmtningr
    movwf   ReadCache

    ; Copy Inmatningar to temp buffer...
    movlw   High Inmatningar
    movwf   FSR0H
    movlw   Inmatningar
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4
    return

WRITE_SSBUF_AND_COPY_TmAct_Idl
    movwf   ReadCache

    ; Copy Inmatningar to temp buffer...
    movlw   High InmatTmActive
    movwf   FSR0H
    movlw   InmatTmActive
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2

    movlw   InmatTmIdle
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4
    return

WRITE_SSBUF_AND_COPY_SkruvPlsr
    movwf   ReadCache

    ; Copy Inmatningar to temp buffer...
    movlw   High SkruvPulser
    movwf   FSR0H
    movlw   SkruvPulser
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4
    return

WRITE_SSBUF_AND_COPY_Status1
    movwf   ReadCache

    movlw   High BufferB1
    movwf   FSR0H
    movlw   BufferB1
    movwf   FSR0L

    banksel Alarms
    movfw   Alarms
    movwi   FSR0++              ; Alarms -> BufferB1
    movfw   RState
    movwi   FSR0++              ; RState -> BufferB2
    movfw   MaxChn
    movwi   FSR0++              ; MaxChn -> BufferB3
    banksel OCLimitL
    movfw   OCLimitL
    movwi   FSR0++              ; OCLimitL -> BufferB4
    banksel BufferB1
    return

WRITE_SSBUF_AND_COPY_Status2
    movwf   ReadCache

    movlw   High BufferB1
    movwf   FSR0H
    movlw   BufferB1
    movwf   FSR0L

    banksel OCLimitH
    movfw   OCLimitH
    movwi   FSR0++              ; OCLimitH -> BufferB1

    banksel LastInTime
    movfw   LastInTime
    movwi   FSR0++              ; LastInTime -> BufferB2

    banksel ExhaustTemp
    movfw   ExhaustTemp
    movwi   FSR0++              ; ExhaustTemp -> BufferB3

    movfw   WaterTemp
    movwi   FSR0++              ; WaterTemp -> BufferB4

    banksel BufferB1
    return

WRITE_SSBUF_AND_COPY_Backningar
    movwf   ReadCache

    movlw   High Backningar
    movwf   FSR0H
    movlw   Backningar
    movwf   FSR0L
    moviw   FSR0++
    movwf   BufferB1
    moviw   FSR0++
    movwf   BufferB2
    moviw   FSR0++
    movwf   BufferB3
    moviw   FSR0++
    movwf   BufferB4

    banksel BufferB1
    return

WRITE_SSBUF_AND_COPY_Status3
    movwf   ReadCache

    movlw   High BufferB1
    movwf   FSR0H
    movlw   BufferB1
    movwf   FSR0L

    banksel PiIdleTm
    movfw   PiIdleTm
    movwi   FSR0++              ; PiIdleTm LSB -> BufferB1
    movfw   PiIdleTm + 1
    movwi   FSR0++              ; PiIdleTm MSB -> BufferB2
    movfw   PiActTm
    movwi   FSR0++              ; PiActTm -> BufferB3
    movfw   PiRevTm
    movwi   FSR0++              ; PiRevTm -> BufferB4

    banksel BufferB1
    return
#endif
;</editor-fold>



;**********************************************************************
; Do I2CBCL ISR
;   I2C Bus Collition Interrupt Service Routine (ISR) handler.
;**********************************************************************
;Do_I2CBCL_ISR
;   return

    END                         ; directive 'end of program'

