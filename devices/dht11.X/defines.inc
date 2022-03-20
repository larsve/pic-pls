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

#define DHT11
#ifndef I2C_ADR
    #define I2C_ADR 10  ; Set default I2C address to 10
    ;#define I2C_ADR 15
    ;#define I2C_ADR 16
#endif
#define I2C_DeviceType DT_PLS   ; Set device type
#define I2C_DeviceFunc DF_DHT11 ; Set device function

;*** Common configuration *********************************************

; ADC configuration
#define ADC
#define ADC_AVG
#define ADC_AVG_CNT 64          ; No of sampels to calc average values on (Valid values: 4, 8, 16, 32, 64)

; I2C configuration
#define I2C                     ; Enable I2C
#define MSSP_ISR                ; Use interrupt to handle I2C
#define I2C_SendAdc             ; Send ADC values
#define I2C_SendDht11           ; Send DHT11 values
#define I2C_SendUptime          ; Send Uptime counter

; Misc configuration
#define OSC 8                   ; 1, 2, 4, 8, 16, 32MHz
#define RunLed
#define I2cActLed

;*** Special configuration ********************************************
#define ControllerLogic
#define PORT_IOC