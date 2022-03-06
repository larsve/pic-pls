;**********************************************************************
; Description:
;   Version information.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************


; *** I2C defines *****************************************************

; Device Type
DT_PLS          EQU 0x01    ; 0x01 = PLS

; Device function (PCB/hardware) for Device Type = 0x01
DF_BAXI         EQU 0x01    ; 0x01 = Baxi Controller
DF_COMBIHEAT    EQU 0x02    ; 0x02 = CombiHeat Controller
DF_VFD          EQU 0x03    ; 0x03 = VFD Display
DF_PC           EQU 0x04    ; 0x04 = PC Controller
DF_SPD          EQU 0x05    ; 0x05 = SPD Controller
DF_LED_DISPLAY  EQU 0x06    ; 0x06 = LED Display
DF_BAXI_INMAT   EQU 0x07    ; 0x07 = Baxi Inmatning
DF_PRESSURE     EQU 0x08    ; 0x08 = Pressure Controller
DF_PIC_IO       EQU 0x09    ; 0x09 = Pic Io Controller
DF_LCD_DISPLAY  EQU 0x0a    ; 0x0a = LCD display
DF_SOL_PIC      EQU 0x0b    ; 0x0b = SolPic
DF_FREEZER      EQU 0x0c    ; 0x0c = Freeser monitor / controller
DF_DHT11        EQU 0x0d    ; 0x0d = DTH11 humidity / temperature sensor

DF_DEV_PCB      EQU 0xf0    ; 0xF0 = Utvecklingskort


