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

#define BaxiController
#ifndef BaxiNo
  #define BaxiNo 1
;  #define BaxiNo 2
#endif

#if BaxiNo == 1
    #define I2C_ADR 11
    #define INVERT_TX_LED
#else
  #if BaxiNo == 2
    #define I2C_ADR 12
    #define INVERT_TX_LED
  #else
    error "Invalid BaxiNo set, must be one of the following values: 1, 2."
  #endif
#endif

#define I2C_DeviceType DT_PLS   ; Set device type
#define I2C_DeviceFunc DF_BAXI  ; Set device function

;*** Common configuration *********************************************

; ADC configuration
#define ADC
#define ADC_AVG
#define ADC_AVG_CNT 32          ; No of sampels to calc average values on (Valid values: 4, 8, 16, 32, 64)

; I2C configuration
#define I2C                     ; Enable I2C
#define MSSP_ISR                ; Use interrupt to handle I2C
#define I2C_SendAdc             ; Send ADC values
#define I2C_SendBaxi            ; Send Baxi data
#define I2C_SendUptime          ; Send Uptime counter

; Misc configuration
#define OSC 16                  ; 1, 2, 4, 8, 16, 32MHz
#define RunLed
#define I2cActLed

;*** Special configuration ********************************************
#define ControllerLogic

#if BaxiNo == 1
;TrigLevel      EQU 20          ; Trigger ADC level. 20 x 19,5mV = 390mV for Baxi1
TrigLevel       EQU 51          ; Trigger ADC level. 51 x 19,5mV = 996mV for Baxi1
#else
  #if BaxiNo == 2
;TrigLevel      EQU 12          ; Trigger ADC level. 12 x 19.5mV = 234mv for Baxi2
TrigLevel       EQU 51          ; Trigger ADC level. 51 x 19,5mV = 996mv for Baxi2
  #else
    error "Invalid BaxiNo set, must be one of the following values: 1, 2."
  #endif
#endif


; *** EEPROM defines **************************************************
EE_UTV_ofs      EQU 0x00    ; Vatten temp offet
;EE_UTV_AlarmTemp   EQU 0x01    ; Inställt värde larm temperatur
;EE_SKRUV_run       EQU 0x02    ; Tid i tiondels sekund steg som skruvmotorn ska köras.
;EE_SKRUV_wait      EQU 0x03    ; Tid i tiondels sekund steg mellan inmatningarna.


;Alarm Temp:
;    (Temp: 100; kNom:   13.06 ),
;    (Temp: 110; kNom:    9.585),
;    (Temp: 120; kNom:    7.131),
;    (Temp: 130; kNom:    5.374),
;    (Temp: 140; kNom:    4.098),
;    (Temp: 150; kNom:    3.161),
;
;    RS:= 4700;
;    R1:= RS + (PT312[j].kNom * 1000);   = 14285 ohm
;    I1:= 5 / R1;           = 3,5001750087504375218760938046902e-4 A
;    U1:= I1 * RS;          = 1,6450822541127056352817640882044 V
;    ADC:= 1024 * (U1 / 5)      = 336,91284564228211410570528526426
;    HiADC:= ADC / 4            = 84,228211410570528526426321316066
;
;   100 grader
;   1,3231981981981981981981981981982 V
;   270,99099099099099099099099099099 ADC
;   67,747747747747747747747747747748 HiADC
