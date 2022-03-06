;**********************************************************************
; Description:
;   Version information.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************


I2C_ProtocolVer         EQU 0x03
I2C_HeaderSize          EQU .16
I2C_Version             EQU 0x01


; *** I2C Data Block Constants ****************************************

I2C_AdcBlockID          EQU 0x01
I2C_AdcBlockVer         EQU 0x04
#ifdef __16F886
I2C_AdcBlockSize        EQU 35
I2C_AdcHwVer            EQU 0x01
#endif
#ifdef __16F1713
I2C_AdcBlockSize        EQU 58
I2C_AdcHwVer            EQU 0x02
#endif

I2C_SpdBlockID          EQU 0x02
I2C_SpdBlockVer         EQU 0x01
I2C_SpdBlockSize        EQU 17

I2C_StatusBlockID       EQU 0x03
I2C_StatusBlockVer      EQU 0x01
I2C_StatusBlockSize     EQU 6

I2C_Counter4BlockID     EQU 0x04
I2C_Counter4BlockVer    EQU 0x01
I2C_Counter4BlockSize   EQU 11

I2C_LcdBlockSize        EQU .10
I2C_LcdBlockID          EQU 0x05
I2C_LcdBlockVer         EQU 0x01

I2C_BaxiBlockID         EQU 0xfe
I2C_BaxiBlockVer        EQU 0x03
I2C_BaxiBlockSize       EQU 33

I2C_DHT11BlockID        EQU 0xfe
I2C_DHT11BlockVer       EQU 0x01
I2C_DHT11BlockSize      EQU 8

I2C_PvPicBlockID        EQU 0xfe
I2C_PvPicBlockVer       EQU 0x01
I2C_PvPicBlockSize      EQU 36

I2C_SolPicBlockID       EQU 0xfe
I2C_SolPicBlockVer      EQU 0x01
I2C_SolPicBlockSize     EQU 40
