;**********************************************************************
; Description:
;   Global defines that change some parts of the program to suite the
;   specific needs of the different types of hardware used.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\common\src\i2c_defines.inc"

#define LedDisplay


;*** Common configuration *********************************************

; I2C configuration
#define I2C
#define MSSP_ISR
#define I2C_DeviceType DT_PLS           ; Set device type
#define I2C_DeviceFunc DF_LED_DISPLAY   ; Set device function
#define I2C_ADR 16
#define I2C_SendUptime          ; Send Uptime counter

; Misc configuration
#define OSC 4                   ; 1, 2, 4, 8, 16, 32MHz
#define RunLed
#define I2cActLed

;*** Special configuration ********************************************
#define ControllerLogic
