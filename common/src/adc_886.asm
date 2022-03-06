;**********************************************************************
; Description:
;   A/D Conversion routines.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "MCU_Defines.inc"
    #include    "..\src\Defines.inc"
    #include    "ADC.inc"
    #include    "ISR_Timer.inc"
    #include    "Macros.inc"

    errorlevel  -302            ; suppress message 302 from list file

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  Init_ADC
    GLOBAL  Do_ADC

    ; Variables
    GLOBAL  AdcState
    GLOBAL  ADC_chn
    GLOBAL  ADCcnt
    GLOBAL  AdcFlags
    GLOBAL  AdcResets
    GLOBAL  ANchn
    GLOBAL  AN0
    GLOBAL  AN1
    GLOBAL  AN2
    GLOBAL  AN3
    GLOBAL  AN4
    GLOBAL  AN5
    GLOBAL  AN6
    GLOBAL  AN7
    GLOBAL  AN8
    GLOBAL  AN9
    GLOBAL  AN10
    GLOBAL  AN11
    GLOBAL  ANchnREF1p
    GLOBAL  ANchnREF2p
    GLOBAL  ANchnREF1m
    GLOBAL  ANchnREF2m

;***** Extern declarations ********************************************
    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
gprbank0    udata
AdcState    res 1           ; ADC status bits
ADC_chn     res 1           ; Channel for ADC value
ADC_hi      res 1           ; ADC value (high bits)
ADC_lo      res 1           ; ADC value (low bits)
ADCcnt      res 1
AdcFlags    res 1           ; ADC flags sent to I2C master to help parse ADC block
AdcResets   res 1           ; No of ADC reset / re-initializations

ANchn       res 1           ; Analog Channel
AN0         res 2           ; AN0 MSB (BigEndian)
AN1         res 2           ; AN1 MSB
AN2         res 2           ; AN2 MSB
AN3         res 2           ; AN3 MSB
AN4         res 2           ; AN4 MSB
AN5         res 2           ; AN5 MSB
AN6         res 2           ; AN6 MSB
AN7         res 2           ; AN7 MSB
AN8         res 2           ; AN8 MSB
AN9         res 2           ; AN9 MSB
AN10        res 2           ; AN10 MSB
AN11        res 2           ; AN11 MSB
ANchnREF1p  res 1           ; VREF+ for AN0 to AN7
ANchnREF2p  res 1           ; VREF+ for AN8 to AN11
ANchnREF1m  res 1           ; VREF- for AN0 to AN7
ANchnREF2m  res 1           ; VREF- for AN8 to AN11
#ifdef ADC_AVG
AvgCnt      res 1           ; Avg count
#endif

Temp_Data   udata_ovr   0x6e
Temp        res 1
ISRTemp     res 1

gprbank1    udata
ChnRef      res 1           ; Copy of reference selection in bank 1 (where ADCON1 is)

#ifdef ADC_AVG
gprbank2    udata
AN0avg      res 2           ; AN0 avg
AN1avg      res 2           ; AN1 avg
AN2avg      res 2           ; AN2 avg
AN3avg      res 2           ; AN3 avg
AN4avg      res 2           ; AN4 avg
AN5avg      res 2           ; AN5 avg
AN6avg      res 2           ; AN6 avg
AN7avg      res 2           ; AN7 avg
AN8avg      res 2           ; AN8 avg
AN9avg      res 2           ; AN9 avg
AN10avg     res 2           ; AN10 avg
AN11avg     res 2           ; AN11 avg
#endif

#ifdef ADC_AVG
#ifndef ADC_AVG_CNT
#define ADC_AVG_CNT .64         ; No of sampels to calc average values on (Valid values: 4, 8, 16, 32, 64)
#endif
#endif

;***** Code Section ***************************************************
PROG0       code

;**********************************************************************
; Init ADC
;   Initialize A/D conversion parameters (Assumes that Init_IO already
;   has been executed).
;**********************************************************************
Init_ADC
    banksel AdcResets
    clrf    AdcResets

ReInitADC
    banksel AdcFlags
    clrf    AdcFlags

    ; Set ADC flag bits
    ; 7-6   Unused
    ; 5-3   ADC bits:
    ;   0 = 8bit ADC
    ;   1 = 10bit ADC
    ;   2 = 11bit ADC
    ;   3 = 12bit ADC
    ;   4 = 13bit ADC
    ;   5 = 14bit ADC
    ;   6 = 15bit ADC
    ;   7 = 16bit ADC
    ; 2-0   ADC oversampling:
    ;   0 = No oversampling (8 to 16bit ADC)
    ;   1 = 2x oversampling (8 to 15bit ADC)
    ;   2 = 4x oversampling (8 to 14bit ADC)
    ;   3 = 8x oversampling (8 to 13bit ADC)
    ;   4 = 16x oversampling (8 to 12bit ADC)
    ;   5 = 32x oversampling (8 to 11bit ADC)
    ;   6 = 64x oversampling (8 to 10bit ADC)
    ;   7 = 128x oversampling (only 8bit ADC)
    movlw   B'00001000'         ; Default to 10bit ADC values and no oversampling
#ifdef ADC_AVG
  if ADC_AVG_CNT == 64
    movlw   B'00001110'         ; 10bit ADC, 64x oversampling
  else
    if ADC_AVG_CNT == 32
    movlw   B'00001101'         ; 10bit ADC, 32x oversampling
    else
      if ADC_AVG_CNT == 16
    movlw   B'00001100'         ; 10bit ADC, 16x oversampling
      else
        if ADC_AVG_CNT == 8
    movlw   B'00001011'         ; 10bit ADC, 8x oversampling
        else
          if ADC_AVG_CNT == 4
    movlw   B'00001010'         ; 10bit ADC, 4x oversampling
          endif
        endif
      endif
    endif
  endif
#endif
    movwf   AdcFlags

    clrf    ADC_hi
    clrf    ADC_lo
    clrf    ADCcnt
    clrf    ANchnREF1p
    clrf    ANchnREF2p
    clrf    ANchnREF1m
    clrf    ANchnREF2m

    clrf    ANchn
    clrf    AN0
    clrf    AN0 + 1
    clrf    AN1
    clrf    AN1 + 1
    clrf    AN2
    clrf    AN2 + 1
    clrf    AN3
    clrf    AN3 + 1
    clrf    AN4
    clrf    AN4 + 1
    clrf    AN5
    clrf    AN5 + 1
    clrf    AN6
    clrf    AN6 + 1
    clrf    AN7
    clrf    AN7 + 1
    clrf    AN8
    clrf    AN8 + 1
    clrf    AN9
    clrf    AN9 + 1
    clrf    AN10
    clrf    AN10 + 1
    clrf    AN11
    clrf    AN11 + 1
    clrf    ANchnREF1p
    clrf    ANchnREF2p
    clrf    ANchnREF1m
    clrf    ANchnREF2m

#ifdef ADC_AVG
    ; Clear AN0avg to AN11avg
    movlw   .12 * .2
    movwf   AvgCnt
    ;movlw  AN0avg

    SetFsr  AN0avg
    clrf    INDF
    incf    FSR, F
    decfsz  AvgCnt, F
    goto    $-3

    movlw   ADC_AVG_CNT
    movwf   AvgCnt
#endif

    ; ANchnREFxp bits, 0 = use Vcc as ref, 1 = use RA3 as +ref
    ; ANchnREFxm bits, 0 = use GND as ref, 1 = use RA4 as -ref
    ;
    ; ANchnREF1y bits:
    ;  0x07 - AN0  / RA0 / ANchn00
    ;  0x06 - AN1  / RA1 / ANchn01
    ;  0x05 - AN2  / RA2 / ANchn02 / Vref-
    ;  0x04 - AN3  / RA3 / ANchn03 / Vref+
    ;  0x03 - AN4  / RA5 / ANchn04
    ;  0x02 - AN12 / RB0 / ANchn05
    ;  0x01 - AN10 / RB1 / ANchn06
    ;  0x00 - AN8  / RB2 / ANchn07

    ; ANchnREF2y bits:
    ;  0x07 - AN9  / RB3 / ANchn08
    ;  0x06 - AN11 / RB4 / ANchn09
    ;  0x05 - AN13 / RB5 / ANchn10
    ;  0x04 - Vref / --- / ANchn11
    ;  0x03 - Unsued
    ;  0x02 - Unsued
    ;  0x01 - Unsued
    ;  0x00 - Unsued

#ifdef LedDisplay
    #define AdcRef1p    B'00000000' ; Set ANchn00 - ANchn07 to use Vcc as ref
    #define AdcRef2p    B'00000000' ; Set ANchn08 - ANchn11 to use Vcc as ref
    #define AdcRef1m    B'00000000' ; Set ANchn00 - ANchn07 to use GND as ref
    #define AdcRef2m    B'00000000' ; Set ANchn08 - ANchn11 to use GND as ref
#endif

#ifdef PicIoController
    #define AdcRef1p    B'00000000' ; Set ANchn00 - ANchn07 to use Vcc as ref
    #define AdcRef2p    B'00000000' ; Set ANchn08 - ANchn11 to use Vcc as ref
    #define AdcRef1m    B'00000000' ; Set ANchn00 - ANchn07 to use GND as ref
    #define AdcRef2m    B'00000000' ; Set ANchn08 - ANchn11 to use GND as ref
#endif

#ifdef SpdController
    #define AdcRef1p    B'00000000' ; Set ANchn00 - ANchn07 to use Vcc as ref
    #define AdcRef2p    B'00000000' ; Set ANchn08 - ANchn11 to use Vcc as ref
    #define AdcRef1m    B'00000000' ; Set ANchn00 - ANchn07 to use GND as ref
    #define AdcRef2m    B'00000000' ; Set ANchn08 - ANchn11 to use GND as ref
#endif

    movlw   AdcRef1p            ; ANchn00 - ANchn07 positive reference selection
    movwf   ANchnREF1p
    movlw   AdcRef2p            ; ANchn08 - ANchn10 positive reference selection
    movwf   ANchnREF2p
    movlw   AdcRef1m            ; ANchn00 - ANchn07 negative reference selection
    movwf   ANchnREF1m
    movlw   AdcRef2m            ; ANchn08 - ANchn10 negative reference selection
    movwf   ANchnREF2m

    ; Make sure that neighter RA3/AN3 and 0.6vref uses +ref (RA3)
    bcf     ANchnREF1p, 4       ; RA3/AN3 ref = Vcc
    bcf     ANchnREF2p, 4       ; 0.6V ref = Vcc


    ; Initialize PIC ADC registers
    banksel ADCON0
    movlw   B'11000001'     ; Frc, Channel #0, AD ON (@4MHz)
#if OSC == 20
    movlw   B'10000001'     ; Fosc/32, Channel #0, AD ON (20MHz)
#endif
#if OSC == 8
    movlw   B'10000001'     ; Fosc/32, Channel #0, AD ON (20MHz)
#endif
#if OSC == 4
    movlw   B'01000001'     ; Fosc/8, Channel #0, AD ON (@4MHz)
#endif
    movwf   ADCON0

    bcf     PIR1, ADIF      ; Clear ADC done interrupt flag while we are here.

    banksel ADCON1
    movlw   B'00000000'     ; Left justify AD result, Vdd and Vss as Vref
    movwf   ADCON1          ;
#ifdef ADC_AVG
    bsf     ADCON1, ADFM    ; Right justify AD result
#endif

    banksel AdcState
    clrf    AdcState

    return

;**********************************************************************
; Do ADC
;   Handles (starts) A/D conversion.
;**********************************************************************
Do_ADC
    banksel AdcState
    bcf     AdcState, adcDone

    btfsc   PIR1, ADIF      ; Check ADC done interrupt flag.
    call    Read_ADC_Value

#ifdef ADC_AVG
    ; Check if the I2C master is reading from us, if it is, bail so that we don't update the values while it's reading..
;TODO

    banksel AdcState
    ; Check if we should calc average values now?
    movfw   AvgCnt
    skpz
    goto    SkipAdcAvg
    ;nop
    ; Save ADC averages...
;#if (.64 / AVG_CNT - 1) > 0
;  if AVG_CNT < .64
;   ; Start to roll every value so we get the 8 high bits in the same byte.
;    if AVG_CNT == .32
;   movlw   1
;    else
;    if AVG_CNT == .16
;   movlw   2
;      else
;        if AVG_CNT == .8
;   movlw   3
;        else
;          if AVG_CNT == .4
;   movlw   4
;          else
;   error "Invalid AVG_CNT set, must be one of the following values: 4, 8, 16, 32, 64."
;          endif
;        endif
;      endif
;    endif
;   movwf   Temp
;   bankisel    AN0avg
;   ; Start outer loop..
;   movlw   AN11avg + 1             ; Since it's stored in BigEndian, we start from the last LSB value and go up..
;   movwf   FSR
;   movlw   .12
;   movwf   AvgCnt
;   ; Start inner loop
;   bcf     STATUS, C
;   rlf     INDF, F                 ; Roll LSB
;   decf    FSR
;   rlf     INDF, F                 ; Roll MSB
;   decf    FSR
;   decfsz  AvgCnt, F
;   goto    $-6                     ; Inner loop (No of ADC channels)
;   decfsz  Temp, F
;   goto    $-0x0c                  ; Outer loop (No of bit shifts)
;  endif
    ; Move AN*avg values to AN* values
    SetFsr  AN0avg
    movfw   INDF                    ; AN0 MSB
    movwf   AN0
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN0 LSB
    movwf   AN0 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN1 MSB
    movwf   AN1
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN1 LSB
    movwf   AN1 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN2 MSB
    movwf   AN2
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN2 LSB
    movwf   AN2 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN3 MSB
    movwf   AN3
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN3 LSB
    movwf   AN3 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN4 MSB
    movwf   AN4
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN4 LSB
    movwf   AN4 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN5 MSB
    movwf   AN5
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN5 LSB
    movwf   AN5 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN6 MSB
    movwf   AN6
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN6 LSB
    movwf   AN6 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN7 MSB
    movwf   AN7
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN7 LSB
    movwf   AN7 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN8 MSB
    movwf   AN8
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN8 LSB
    movwf   AN8 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN9 MSB
    movwf   AN9
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN9 LSB
    movwf   AN9 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN10 MSB
    movwf   AN10
    clrf    INDF
    incf    FSR, F
    movfw   INDF                    ; AN10 LSB
    movwf   AN10 + 1
    clrf    INDF
    incf    FSR, F

    movfw   INDF                    ; AN11 MSB
    movwf   AN11
    clrf    INDF
    incf    FSR, F
    movfw   INDF                ; AN11 LSB
    movwf   AN11 + 1
    clrf    INDF
    incf    FSR, F

;   ; Clear AN0avg to AN11avg
;   movlw   .12 * .2                ; 12 channels x 2 bytes each
;   movwf   AvgCnt
;   movlw   AN0avg
;
;   SetFsr  AN0avg
;   clrf    INDF
;   incf    FSR, F
;   decfsz  AvgCnt, F
;   goto    $-3

    movlw   ADC_AVG_CNT
    movwf   AvgCnt
    bsf     AdcState, adcDone
SkipAdcAvg
#endif

    ; Time to start new ADC?
    btfss   Timer_Tick, TimerTick_1ms
    return

    ; Check the ADC reinit flag..
    btfsc   AdcState, adcReInit
    goto    ReInitADC

    btfss   ADCON0, GO          ; Have we started ADC yet?
    goto    StartADC            ; No, Start ADC

    ; Assume that something is very wrong here, try to re initialize ADC
    incf    AdcResets, F        ; Inc no of resets
    bsf     AdcState, adcReInit ; Set resetflag
    bcf     ADCON0, ADON        ; Shutdown ADC
    return

StartADC
    bsf     ADCON0, GO          ; No, start ADC and return
    return

;**********************************************************************
; Read ADC value
;   Handles A/D conversion interrupt.
;**********************************************************************
Read_ADC_Value
    banksel PIR1
    bcf     PIR1, ADIF      ; Clear ADC interrupt flag

    ; Save ADC result to ADC_hi & ADC_lo
    banksel ADRESL          ; Bank 1
    movfw   ADRESL
    banksel ADRESH          ; Bank 0
    movwf   ADC_lo
    movfw   ADRESH
    movwf   ADC_hi

    movfw   ANchn
    movwf   ADC_chn

    ; Save ADC values
    pageselw    ADC_SAVE_TABLE
    movfw   ANchn
    andlw   0x0f
    addlw   ADC_SAVE_TABLE
    skpnc
    incf    PCLATH,F
    movwf   PCL
ADC_SAVE_TABLE
    goto    SaveAdcChn0
    goto    SaveAdcChn1
    goto    SaveAdcChn2
    goto    SaveAdcChn3
    goto    SaveAdcChn4
    goto    SaveAdcChn5
    goto    SaveAdcChn6
    goto    SaveAdcChn7
    goto    SaveAdcChn8
    goto    SaveAdcChn9
    goto    SaveAdcChn10
    goto    SaveAdcChn11

#ifndef ADC_AVG
SaveAdcChn0                     ; ANchn = 0
    movfw   ADC_hi
    movwf   AN0
    movfw   ADC_lo
    movwf   AN0 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn1                     ; ANchn = 1
    movfw   ADC_hi
    movwf   AN1
    movfw   ADC_lo
    movwf   AN1 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn2                     ; ANchn = 2
    movfw   ADC_hi
    movwf   AN2
    movfw   ADC_lo
    movwf   AN2 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn3                     ; ANchn = 3
    movfw   ADC_hi
    movwf   AN3
    movfw   ADC_lo
    movwf   AN3 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn4                     ; ANchn = 4
    movfw   ADC_hi
    movwf   AN4
    movfw   ADC_lo
    movwf   AN4 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn5                     ; ANchn = 5
    movfw   ADC_hi
    movwf   AN5
    movfw   ADC_lo
    movwf   AN5 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn6                     ; ANchn = 6
    movfw   ADC_hi
    movwf   AN6
    movfw   ADC_lo
    movwf   AN6 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn7                     ; ANchn = 7
    movfw   ADC_hi
    movwf   AN7
    movfw   ADC_lo
    movwf   AN7 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn8                     ; ANchn = 8
    movfw   ADC_hi
    movwf   AN8
    movfw   ADC_lo
    movwf   AN8 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn9                     ; ANchn = 9
    movfw   ADC_hi
    movwf   AN9
    movfw   ADC_lo
    movwf   AN9 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn10                    ; ANchn = 10
    movfw   ADC_hi
    movwf   AN10
    movfw   ADC_lo
    movwf   AN10 + 1
    goto    ADC_SAVE_DONE

SaveAdcChn11                    ; ANchn = 11 / Vref
    movfw   ADC_hi
    movwf   AN11
    movfw   ADC_lo
    movwf   AN11 + 1
    goto    ADC_SAVE_DONE
#endif
#ifdef ADC_AVG
SaveAdcChn0
    SetFsr  AN0avg
    goto    UpdateAvg
SaveAdcChn1
    SetFsr  AN1avg
    goto    UpdateAvg
SaveAdcChn2
    SetFsr  AN2avg
    goto    UpdateAvg
SaveAdcChn3
    SetFsr  AN3avg
    goto    UpdateAvg
SaveAdcChn4
    SetFsr  AN4avg
    goto    UpdateAvg
SaveAdcChn5
    SetFsr  AN5avg
    goto    UpdateAvg
SaveAdcChn6
    SetFsr  AN6avg
    goto    UpdateAvg
SaveAdcChn7
    SetFsr  AN7avg
    goto    UpdateAvg
SaveAdcChn8
    SetFsr  AN8avg
    goto    UpdateAvg
SaveAdcChn9
    SetFsr  AN9avg
    goto    UpdateAvg
SaveAdcChn10
    SetFsr  AN10avg
    goto    UpdateAvg
SaveAdcChn11
    decf    AvgCnt, F
    SetFsr  AN11avg
;   goto    UpdateAvg
UpdateAvg
    incf    FSR, F                  ; Inc FSR to point to LSB and not MSB
    ; LSB
    movfw   ADC_lo
    addwf   INDF, F                 ; Add ADC LSB to avg
    decf    FSR, F                  ; Switch FSR to point to MSB
    skpnc
    incf    INDF, F                 ; LSB carry
    ; MSB
    movfw   ADC_hi                  ; Add ADC MSB to avg
    addwf   INDF, F
#endif

ADC_SAVE_DONE
#ifndef ADC_AVG
    bsf     AdcState, adcDone
#endif
    incf    ADCcnt, F

    ; Get next channel number...
    incf    ANchn, F            ; Inc ANchn
    movfw   ANchn
    sublw   .11
    btfss   STATUS, C           ; if ANchn > 11
    clrf    ANchn               ; Yes, set ANchn to 0

    ; Setup AD for next channel

    pageselw    ADC_CHN_TABLE
    movfw   ANchn               ; Calc ANchn * 4
    andlw   0x0f
    addlw   LOW ADC_CHN_TABLE
    skpnc
    incf    PCLATH,F
    movwf   PCL
ADC_CHN_TABLE
    goto    SetupChn0
    goto    SetupChn1
    goto    SetupChn2
    goto    SetupChn3
    goto    SetupChn4
    goto    SetupChn5
    goto    SetupChn6
    goto    SetupChn7
    goto    SetupChn8
    goto    SetupChn9
    goto    SetupChn10
    goto    SetupChn11

SetupChn0   ; ANchn = 0
    movlw   B'00000000'         ; AN0
    btfsc   ANchnREF1p, 0x07
    iorlw   0x80
    btfsc   ANchnREF1m, 0x07
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn1   ; ANchn = 1
    movlw   B'00000001'         ; AN1
    btfsc   ANchnREF1p, 0x06
    iorlw   0x80
    btfsc   ANchnREF1m, 0x06
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn2   ; ANchn = 2 / Vref-
    movlw   B'00000010'         ; AN2 / Vref-
;   btfsc   ANchnREF1p, 0x05
;   iorlw   0x80
    goto    SET_ADC_CHN

SetupChn3   ; ANchn = 3 / Vref+
    movlw   B'0000011'          ; AN3 / Vref+
    ; AN3 / Vref+ should never use any other ref then Vcc/ Gnd
;   btfsc   ANchnREF1m, 0x04
;   iorlw   0x40
    goto    SET_ADC_CHN

SetupChn4   ; ANchn = 4
    movlw   B'00000100'         ; AN4
    btfsc   ANchnREF1p, 0x03
    iorlw   0x80
    btfsc   ANchnREF1m, 0x03
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn5   ; ANchn = 5
    movlw   B'00001100'         ; AN12
    btfsc   ANchnREF1p, 0x02
    iorlw   0x80
    btfsc   ANchnREF1m, 0x02
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn6   ; ANchn = 6
    movlw   B'00001010'         ; AN10
    btfsc   ANchnREF1p, 0x01
    iorlw   0x80
    btfsc   ANchnREF1m, 0x01
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn7   ; ANchn = 7
    movlw   B'00001000'         ; AN8
    btfsc   ANchnREF1p, 0x00
    iorlw   0x80
    btfsc   ANchnREF1m, 0x00
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn8   ; ANchn = 8
    movlw   B'00001001'         ; AN9
    btfsc   ANchnREF2p, 0x07
    iorlw   0x80
    btfsc   ANchnREF2m, 0x07
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn9   ; ANchn = 9
    movlw   B'00001011'         ; AN11
    btfsc   ANchnREF2p, 0x06
    iorlw   0x80
    btfsc   ANchnREF2m, 0x06
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn10  ; ANchn = 10
    movlw   B'00001101'         ; AN13
    btfsc   ANchnREF2p, 0x05
    iorlw   0x80
    btfsc   ANchnREF2m, 0x05
    iorlw   0x40
    goto    SET_ADC_CHN

SetupChn11  ; ANchn = 11
    movlw   B'00001111'         ; Fixedref (0.6V)
    goto    SET_ADC_CHN


SET_ADC_CHN
    movwf   Temp
    banksel ADCON1
    movwf   ChnRef
    bcf     ADCON1, VCFG0       ; Set +ref to VCC
    bcf     ADCON1, VCFG1       ; Set -ref to GND
    btfsc   ChnRef, 7
    bsf     ADCON1, VCFG0       ; Change +ref to AN03
    btfsc   ChnRef, 6
    bsf     ADCON1, VCFG1       ; Change -ref to AN02

    banksel ADCON0
    movfw   Temp
    andlw   0x0f
    movwf   Temp
    bcf     STATUS, C
    rlf     Temp, F
    rlf     Temp, F
    movfw   ADCON0
    andlw   B'11000011'
    iorwf   Temp, w
    movwf   ADCON0
    return

    END
