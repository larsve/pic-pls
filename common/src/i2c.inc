;**********************************************************************
; Description:
;   Status bits exposed in I2C_State byte.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************


; I2C_State flags
i2cBusy     EQU 0x07                ; Busy flag, set when reading or writing to the device, cleared when 'P' is detected.

; I2C Receive buffer size
i2cRxSize   EQU 0x50

; I2C timeout
i2cTimeout  EQU .100
