;**********************************************************************
; Description:
;   Global defines that change some parts of the program so suite the
;   specific needs of the different types of hardware used.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

#include    "..\..\common\src\i2c_defines.inc"

#define LcdDisplay
#define ControllerLogic
;#define LCD_X 20
;#define LCD_Y 4
#define LCD_X 16
#define LCD_Y 2
#define HW_PWM

#ifndef I2C_ADR
;    #define I2C_ADR 16
    #define I2C_ADR 17
#endif
#define I2C_DeviceType DT_PLS           ; Set device type
#define I2C_DeviceFunc DF_LCD_DISPLAY   ; Set device function

;*** Common configuration *********************************************

; I2C configuration
#define I2C                     ; Enable I2C
#define MSSP_ISR                ; Use interrupt to handle I2C
#define I2C_SendLcd             ; Send LCD data
#define I2C_SendUptime          ; Send Uptime counter

; Misc configuration
#define OSC 8                   ; 1, 2, 4, 8, 16, 32MHz
#define RunLed
#define I2cActLed
