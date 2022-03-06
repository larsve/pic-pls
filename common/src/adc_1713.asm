;**********************************************************************
; Description:
;   A/D Conversion routines.
;
;**********************************************************************
; Configuration points:
;   ADC_AVG     Enable ADC oversampling
;   ADC_AVG_CNT Set oversampling value (4, 8, 16, 32, 64, default 64)
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "adc.inc"
    #include    "isr_timer.inc"
    #include    "macros.inc"

;***** Global declarations ********************************************
    ; Methods
    Global Init_ADC
    Global Do_ADC

    ; Variables
    Global AdcState
    Global ANchn
#ifndef ADC_AVG
    Global AdcChn
#endif
    GLOBAL AdcFlags
    Global AdcResets
    Global AN0              ; RA0
    Global AN1              ; RA1
    Global AN2              ; RA2
    Global AN3              ; RA3
    Global AN4              ; RA5
    Global AN8              ; RB2
    Global AN9              ; RB3
    Global AN10             ; RB1
    Global AN11             ; RB4
    Global AN12             ; RB0
    Global AN13             ; RB5
    Global AN14             ; RC2
    Global AN15             ; RC3
    Global AN16             ; RC4
    Global AN17             ; RC5
    Global AN18             ; RC6
    Global AN19             ; RC7
    Global ANDac2           ; RA5/RB7
    Global ANTemp
    Global ANDac1           ; RA2/RB7
    Global ANFvr1
    Global ANFvr2
    Global ANFvr4
    Global ANRef1
    Global ANRef2
    Global ANRef3
    Global ANRef4
    Global ANRef5
#ifdef BaxiController
    ;Global RBxADC
    Global ExhaustTemp      ; AN18
    Global IrSignal         ; AN19
    Global OCLimitL         ; AN4
    Global OCLimitH         ; AN13
    Global OCSignal         ; AN10
    Global WaterTemp        ; AN12
#endif

;***** Extern declarations ********************************************
    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
;AdcData     udata
gprbank0    udata
AdcState    res 1           ; ADC status bits
AdcChn      res 1           ; Channel for ADC value
AdcHi       res 1           ; ADC value (high bits)
AdcLo       res 1           ; ADC value (low bits)
AdcFlags    res 1           ; ADC flags sent to I2C master to help parse ADC block
AdcResets   res 1           ; No of ADC reset / re-initializations
AdcTmp      res 1           ; Temporary value

ANchn       res 1           ; Analog Channel
AN0         res 2           ; AN0
AN1         res 2           ; AN1
AN2         res 2           ; AN2
AN3         res 2           ; AN3
AN4         res 2           ; AN4
AN8         res 2           ; AN8
AN9         res 2           ; AN9
AN10        res 2           ; AN10
AN11        res 2           ; AN11
AN12        res 2           ; AN12
AN13        res 2           ; AN13
AN14        res 2           ; AN14
AN15        res 2           ; AN15
AN16        res 2           ; AN16
AN17        res 2           ; AN17
AN18        res 2           ; AN18
AN19        res 2           ; AN19
ANDac2      res 2           ; AN DAC 2 output
ANTemp      res 2           ; AN Temperature
ANDac1      res 2           ; AN DAC 1 output
ANFvr1      res 2           ; AN Fvr 1.024V
ANFvr2      res 2           ; AN Fvr 2.048V
ANFvr4      res 2           ; AN Fvr 4.069V
ANRef1      res 1           ; VREF+ for AN0 to AN3
ANRef2      res 1           ; VREF+ for AN4, AN8 to AN10
ANRef3      res 1           ; VREF+ for AN11 to AN14
ANRef4      res 1           ; VREF+ for AN15 to AN18
ANRef5      res 1           ; VREF+ for AN19, ANTemp, ANFvr_1024, ANFvr_2048
#ifdef ADC_AVG
AvgCnt      res 1           ; Avg count
#endif
#ifdef BaxiController
BaxiData    udata
ExhaustTemp res 1           ; AN18
IrSignal    res 1           ; AN19
OCLimitL    res 1           ; AN4
OCLimitH    res 1           ; AN13
OCSignal    res 1           ; AN10
WaterTemp   res 1           ; AN12
#endif

gprbank1    udata
ChnRef      res 1           ; Copy of reference selection in bank 1 (where ADCON1 is)

gprbank2    udata
FvrRef      res 1           ; Copy of reference selection in bank 2 (where FVRCON is)

#ifdef ADC_AVG
AdcAvgData  udata
AN0avg      res 2           ; AN0 avg
AN1avg      res 2           ; AN1 avg
AN2avg      res 2           ; AN2 avg
AN3avg      res 2           ; AN3 avg
AN4avg      res 2           ; AN4 avg
AN8avg      res 2           ; AN8 avg
AN9avg      res 2           ; AN9 avg
AN10avg     res 2           ; AN10 avg
AN11avg     res 2           ; AN11 avg
AN12avg     res 2           ; AN12 avg
AN13avg     res 2           ; AN13 avg
AN14avg     res 2           ; AN14 avg
AN15avg     res 2           ; AN15 avg
AN16avg     res 2           ; AN16 avg
AN17avg     res 2           ; AN17 avg
AN18avg     res 2           ; AN18 avg
AN19avg     res 2           ; AN19 avg
ANDac2avg   res 2           ; AN DAC 2 output avg
ANTempavg   res 2           ; AN Temperature avg
ANDac1avg   res 2           ; AN DAC 2 output
ANFvr1avg   res 2           ; AN Fvr 1,024V avg
ANFvr2avg   res 2           ; AN Fvr 2,048V avg
ANFvr4avg   res 2           ; AN Fvr 4,096V avg
#endif

#ifdef ADC_AVG
#ifndef ADC_AVG_CNT
#define ADC_AVG_CNT .64     ; No of sampels to calc average values on (Valid values: 4, 8, 16, 32, 64)
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

    clrf    AdcState
    clrf    AdcHi
    clrf    AdcLo
    clrf    ANRef1
    clrf    ANRef2
    clrf    ANRef3
    clrf    ANRef4
    clrf    ANRef5

    movlw   High AN0
    movwf   FSR0H
    movlw   AN0
    movwf   FSR0L
    movlw   ANRef5 - AN0 + 1
    movwf   ANchn
    movlw   0x00
ClearAdcData
    movwi   FSR0++
    decfsz  ANchn, f
    goto    ClearAdcData

    clrf    ANchn

#ifdef ADC_AVG
    ; Clear AN0avg to AN11avg
    movlw   High AN0avg
    movwf   FSR0H
    movlw   AN0avg
    movwf   FSR0L
    movlw   ANFvr4avg - AN0avg + 2
    movwf   AvgCnt
    movlw   0x00
ClearAdcAvgData
    movwi   FSR0++
    decfsz  AvgCnt, f
    goto    ClearAdcAvgData

    movlw   ADC_AVG_CNT
    movwf   AvgCnt
#endif

    ; AdcRef bits:
    ;   00: Use Vdd as Vref+
    ;   01: Use FVR 1,024V as Vref+
    ;   10: Use FVR 2,048V as Vref+
    ;   11: Use FVR 4,096V as Vref+
    ;
    ; AdcRef1 bits:
    ;  0x07:0x06 - AN0/RA0 ref select
    ;  0x05:0x04 - AN1/RA1 ref select
    ;  0x03:0x02 - AN2/RA2 ref select
    ;  0x01:0x00 - AN3/RA3 ref select
    ;
    ; AdcRef2 bits:
    ;  0x07:0x06 - AN4/RA5 ref select
    ;  0x05:0x04 - AN8/RB2 ref select
    ;  0x03:0x02 - AN9/RB3 ref select
    ;  0x01:0x00 - AN10/RB1 ref select
    ;
    ; AdcRef3 bits:
    ;  0x07:0x06 - AN11/RB4 ref select
    ;  0x05:0x04 - AN12/RB0 ref select
    ;  0x03:0x02 - AN13/RB5 ref select
    ;  0x01:0x00 - AN14/RC2 ref select
    ;
    ; AdcRef4 bits:
    ;  0x07:0x06 - AN15/RC3 ref select
    ;  0x05:0x04 - AN16/RC4 ref select
    ;  0x03:0x02 - AN17/RC5 ref select
    ;  0x01:0x00 - AN18/RC6 ref select
    ;
    ; AdcRef5 bits:
    ;  0x07:0x06 - AN19/RC7 ref select
    ;  0x05:0x04 - AN DAC 2 ref select
    ;  0x03:0x02 - AN Temperature ref select
    ;  0x01:0x00 - AN DAC 1 ref select

#ifdef BaxiController
  #if BaxiNo == 2
    #define AdcRef1 B'00100000' ; Set AN0/RA0,  AN1/RA1,  AN2/RA2,  AN03/RA3
    #define AdcRef2 B'00000000' ; Set AN4/RA5,  AN8/RB2,  AN9/RB3,  AN10/RB1
    #define AdcRef3 B'00100000' ; Set AN11/RB4, AN12/RB0, AN13/RB5, AN14/RC2
    #define AdcRef4 B'00000000' ; Set AN15/RC3, AN16/RC4, AN17/RC5, AN18/RC6
    #define AdcRef5 B'00001100' ; Set AN19/RC7, DAC2,     Temp,     DAC1
  #else
    #define AdcRef1 B'00101010' ; Set AN0/RA0,  AN1/RA1,  AN2/RA2,  AN03/RA3
    #define AdcRef2 B'00101000' ; Set AN4/RA5,  AN8/RB2,  AN9/RB3,  AN10/RB1
    #define AdcRef3 B'00100010' ; Set AN11/RB4, AN12/RB0, AN13/RB5, AN14/RC2
    #define AdcRef4 B'00000000' ; Set AN15/RC3, AN16/RC4, AN17/RC5, AN18/RC6
    #define AdcRef5 B'00001100' ; Set AN19/RC7, DAC2,     Temp,     DAC1
  #endif
#endif

#ifdef DHT11
    #define AdcRef1 B'00000000' ; Set AN0/RA0,  AN1/RA1,  AN2/RA2,  AN03/RA3
    #define AdcRef2 B'00000000' ; Set AN4/RA5,  AN8/RB2,  AN9/RB3,  AN10/RB1
    #define AdcRef3 B'00000000' ; Set AN11/RB4, AN12/RB0, AN13/RB5, AN14/RC2
    #define AdcRef4 B'00000000' ; Set AN15/RC3, AN16/RC4, AN17/RC5, AN18/RC6
    #define AdcRef5 B'00001100' ; Set AN19/RC7, DAC2,     Temp,     DAC1
#endif

    movlw   AdcRef1
    movwf   ANRef1
    movlw   AdcRef2
    movwf   ANRef2
    movlw   AdcRef3
    movwf   ANRef3
    movlw   AdcRef4
    movwf   ANRef4
    movlw   AdcRef5
    movwf   ANRef5

    ; Initialize PIC ADC registers
    banksel ADCON0
    movlw   B'11000001'     ; Channel #0, AD ON
    movwf   ADCON0

    movlw   b'11110000' ; FRC, Right justified, Vref- to Vss, Vref+ to Vdd
#if OSC == 32
    movlw   b'10100000' ; Fosc/32, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
#if OSC == 16
    movlw   b'11010000' ; Fosc/16, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
#if OSC == 8
    movlw   b'10010000' ; Fosc/8, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
#if OSC == 4
    movlw   b'11000000' ; Fosc/4, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
#if OSC == 2
    movlw   b'10000000' ; Fosc/2, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
#if OSC == 1
    movlw   b'10000000' ; Fosc/2, Right justified, Vref- to Vss, Vref+ to Vdd
#endif
    movwf   ADCON1

#ifdef BaxiController
    banksel ExhaustTemp
    clrf    ExhaustTemp ; AN18
    clrf    IrSignal    ; AN19
    clrf    OCLimitL    ; AN4
    clrf    OCLimitH    ; AN13
    clrf    OCSignal    ; AN10
    clrf    WaterTemp   ; AN12
#endif
    return

;**********************************************************************
; Do ADC
;   Handles (starts) A/D conversion.
;**********************************************************************
Do_ADC
    banksel AdcState
    bcf     AdcState, adcDone
#ifdef BaxiController
    bcf     AdcState, adcOcSignalDone
#endif

    banksel PIR1
    btfsc   PIR1, ADIF      ; Check ADC done interrupt flag.
    call    ReadAdcValue

#ifdef ADC_AVG
    ; Check if we should calc average values now?
    banksel AvgCnt
    movfw   AvgCnt
    skpz
    goto    SkipAdcAvg

    ; Save ADC values
    movlw   High AN0avg         ; FSR0 = Source
    movwf   FSR0H
    movlw   AN0avg
    movwf   FSR0L
    movlw   High AN0            ; FSR1 = Destination
    movwf   FSR1H
    movlw   AN0
    movwf   FSR1L
    movlw   23 * 2              ; 23 channels * 2 bytes each
    movwf   AvgCnt
    ; Start inner loop
    moviw   FSR0++
    movwi   FSR1++
    decfsz  AvgCnt, F
    goto    $-3                 ; Inner loop

    ; Clear AN0avg to AN11avg
    movlw   23 * 2              ; 23 channels x 2 bytes each
    movwf   AvgCnt
    movlw   AN0avg

    movlw   High AN0avg
    movwf   FSR0H
    movlw   AN0avg
    movwf   FSR0L
    movlw   0x00
    movwi   FSR0++
    decfsz  AvgCnt, F
    goto    $-2

    movlw   ADC_AVG_CNT
    movwf   AvgCnt
    bsf     AdcState, adcDone
#ifdef BaxiController
    #if ADC_AVG_CNT != 32
    Fix 16-bit -> 8-bit conversion below!!
    #endif
    banksel ExhaustTemp
    ; Copy 10-bit AN18 to high 8-bit ExhaustTemp
    movlw   High AN18
    movwf   FSR0H
    movlw   AN18
    movwf   FSR0L
    moviw   FSR0++
    movwf   ExhaustTemp
    moviw   FSR0++
    lsrf    WREG, F
    rlf     ExhaustTemp, F

    ; Copy 10-bit AN19 to high 8-bit IrSignal
    movlw   High AN19
    movwf   FSR0H
    movlw   AN19
    movwf   FSR0L
    moviw   FSR0++
    movwf   IrSignal
    moviw   FSR0++
    lsrf    WREG, F
    rlf     IrSignal, F

    ; Copy 10-bit AN4 to high 8-bit OCLimitL
    movlw   High AN4
    movwf   FSR0H
    movlw   AN4
    movwf   FSR0L
    moviw   FSR0++
    movwf   OCLimitL
    moviw   FSR0++
    lsrf    WREG, F
    rlf     OCLimitL, F

    ; Copy 10-bit AN12 to high 8-bit WaterTemp
    movlw   High AN12
    movwf   FSR0H
    movlw   AN12
    movwf   FSR0L
    moviw   FSR0++
    movwf   WaterTemp
    moviw   FSR0++
    lsrf    WREG, F
    rlf     WaterTemp, F

    ; Copy 10-bit AN13 to high 8-bit OCLimitH
    movlw   High AN13
    movwf   FSR0H
    movlw   AN13
    movwf   FSR0L
    moviw   FSR0++
    movwf   OCLimitH
    moviw   FSR0++
    lsrf    WREG, F
    rlf     OCLimitH, F

#endif
SkipAdcAvg
#endif

    ; Start to check if the ADC result is ready
    btfss   Timer_Tick, TimerTick_1ms
    return

    ; Check the ADC reinit flag..
    banksel AdcState
    btfsc   AdcState, adcReInit
    goto    ReInitADC

    banksel ADCON0
    btfss   ADCON0, GO          ; Have we started ADC yet?
    goto    StartADC            ; No, Start ADC

    ; Assume that something is very wrong here, try to re initialize ADC
    bcf     ADCON0, ADON        ; Shutdown ADC
    banksel AdcState
    bsf     AdcState, adcReInit ; Set resetflag
    incf    AdcResets, F        ; Inc no of resets
    return

StartADC
    bsf     ADCON0, GO          ; Start ADC and return
    return

;**********************************************************************
; Read Adc Value
;   Read the newly converted value, and setup next channel to be
;   converted.
;**********************************************************************
ReadAdcValue
    banksel PIR1
    bcf     PIR1, ADIF      ; Clear ADC interrupt flag

    ; Save ADC result to AdcHi & AdcLo
    banksel ANchn
    movfw   ANchn
    movwf   AdcChn

    ; Save ADC values
#ifndef ADC_AVG
    movlw   High ADRESH     ; FSR0 = source
    movwf   FSR0H
    movlw   ADRESH
    movwf   FSR0L

    movlw   High AN0        ; FSR1 = destination
    movwf   FSR1H
    movfw   ANchn
    andlw   0x1f
    lslf    WREG, F         ; ANchn * 2
    addlw   AN0
    movwf   FSR1L
    moviw   FSR0--          ; Read AD result High (2-bits)
    movwi   FSR1++
    moviw   FSR0--          ; Read AD result Low (8-bits)
    movwi   FSR1++

    bsf     AdcState, adcDone
#ifdef BaxiController
    TODO: Kolla vilken kanal vi läst och uppdatera rätt värde
    ExhaustTemp - AN18
    IrSignal    - AN19
    OCLimitL    - AN4
    OCLimitH    - AN13
    WaterTemp   - AN12
#endif
#endif
#ifdef ADC_AVG
    movlw   High ADRESL         ; FSR0 = source
    movwf   FSR0H
    movlw   ADRESL
    movwf   FSR0L

    movlw   High AN0avg         ; FSR1 = destination
    movwf   FSR1H
    movfw   ANchn
    andlw   0x1f
    lslf    WREG, F             ; ANchn * 2
    addlw   AN0avg + 1
    movwf   FSR1L

    moviw   FSR0++              ; Read AD result Low (8-bits)
    addwf   INDF1, F
    decf    FSR1, F
    skpnc
    incf    INDF1, F            ; LSB carry
    moviw   FSR0++              ; Read AD result High (2-bits)
    addwf   INDF1, F
#endif

#ifdef BaxiController
    movfw   ANchn
    xorlw   0x07                ; ANchn #7 = AN10
    skpz
    goto    NotTheOCSignalYouAreLookingFor

    ; Copy 10-bit AN10 to high 8-bit OCSignal
    banksel OCSignal
    movlw   High ADRESL         ; FSR0 = source
    movwf   FSR0H
    movlw   ADRESL
    movwf   FSR0L
    moviw   FSR0++
    movwf   OCSignal
    moviw   FSR0++
    lsrf    WREG, F
    rrf     OCSignal, F
    lsrf    WREG, F
    rrf     OCSignal, F
    banksel ANchn
    bsf     AdcState, adcOcSignalDone
NotTheOCSignalYouAreLookingFor
#endif

    ; Get next channel number...
    incf    ANchn, F            ; Inc ANchn
    movfw   ANchn
    sublw   22
    btfss   STATUS, C           ; if ANchn > 22
    clrf    ANchn               ; Yes, set ANchn to 0
#ifdef  ADC_AVG
    btfss   STATUS, C           ; if ANchn > 22
    decf    AvgCnt, F
#endif
SETUP_NEXT_ADC_CHANNEL
    ; Setup AD for next channel
    movlp   High ADC_CHN_TABLE
    movfw   ANchn
    andlw   0x1f
    addlw   LOW ADC_CHN_TABLE
    skpnc
    incf    PCLATH,F
    movwf   PCL
ADC_CHN_TABLE
    goto    SetupAN0    ; 0x00
    goto    SetupAN1    ; 0x01
    goto    SetupAN2    ; 0x02
    goto    SetupAN3    ; 0x03
    goto    SetupAN4    ; 0x04
    goto    SetupAN8    ; 0x05
    goto    SetupAN9    ; 0x06
    goto    SetupAN10   ; 0x07
    goto    SetupAN11   ; 0x08
    goto    SetupAN12   ; 0x09
    goto    SetupAN13   ; 0x0a
    goto    SetupAN14   ; 0x0b
    goto    SetupAN15   ; 0x0c
    goto    SetupAN16   ; 0x0d
    goto    SetupAN17   ; 0x0e
    goto    SetupAN18   ; 0x0f
    goto    SetupAN19   ; 0x10
    goto    SetupANDac2 ; 0x11
    goto    SetupANTemp ; 0x12
    goto    SetupANDac1 ; 0x13
    goto    SetupANFvr1 ; 0x14
    goto    SetupANFvr2 ; 0x15
    goto    SetupANFvr4 ; 0x16
    goto    SetupOvf    ; 0x17
    goto    SetupOvf    ; 0x18
    goto    SetupOvf    ; 0x19
    goto    SetupOvf    ; 0x1a
    goto    SetupOvf    ; 0x1b
    goto    SetupOvf    ; 0x1c
    goto    SetupOvf    ; 0x1d
    goto    SetupOvf    ; 0x1e
    goto    SetupOvf    ; 0x1f
SetupAN0    ; ANchn = 0
    movfw   ANRef1
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00000000' << 2    ; AN0 / RA0
    goto    SET_ADC_CHN

SetupAN1    ; ANchn = 1
    movfw   ANRef1
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00000001' << 2    ; AN1 / RA1
    goto    SET_ADC_CHN

SetupAN2    ; ANchn = 2
    movfw   ANRef1
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00000010' << 2    ; AN2 / Vref- / RA2
    goto    SET_ADC_CHN

SetupAN3    ; ANchn = 3
    movfw   ANRef1
    andlw   0x03
    iorlw   B'00000011' << 2    ; AN3 / Vref+ / RA3
    goto    SET_ADC_CHN

SetupAN4    ; ANchn = 4
    movfw   ANRef2
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00000100' << 2    ; AN4 / RA5
    goto    SET_ADC_CHN

SetupAN8    ; ANchn = 5
    movfw   ANRef2
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001000' << 2    ; AN8 / RB2
    goto    SET_ADC_CHN

SetupAN9    ; ANchn = 6
    movfw   ANRef2
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001001' << 2    ; AN9 / RB3
    goto    SET_ADC_CHN

SetupAN10   ; ANchn = 7
    movfw   ANRef2
    andlw   0x03
    iorlw   B'00001010' << 2    ; AN10 / RB1
    goto    SET_ADC_CHN

SetupAN11   ; ANchn = 8
    movfw   ANRef3
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001011' << 2    ; AN11 / RB4
    goto    SET_ADC_CHN

SetupAN12   ; ANchn = 9
    movfw   ANRef3
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001100' << 2    ; AN12 / RB0
    goto    SET_ADC_CHN

SetupAN13   ; ANchn = 10
    movfw   ANRef3
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001101' << 2    ; AN13 / RB5
    goto    SET_ADC_CHN

SetupAN14   ; ANchn = 11
    movfw   ANRef3
    andlw   0x03
    iorlw   B'00001110' << 2    ; AN14 / RC2
    goto    SET_ADC_CHN

SetupAN15   ; ANchn = 12
    movfw   ANRef4
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00001111' << 2    ; AN15 / RC3
    goto    SET_ADC_CHN

SetupAN16   ; ANchn = 13
    movfw   ANRef4
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00010000' << 2    ; AN16 / RC4
    goto    SET_ADC_CHN

SetupAN17   ; ANchn = 14
    movfw   ANRef4
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00010001' << 2    ; AN17 / RC5
    goto    SET_ADC_CHN

SetupAN18   ; ANchn = 15
    movfw   ANRef4
    andlw   0x03
    iorlw   B'00010010' << 2    ; AN18 / RC6
    goto    SET_ADC_CHN

SetupAN19   ; ANchn = 16
    movfw   ANRef5
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00010011' << 2    ; AN19 / RC7
    goto    SET_ADC_CHN

SetupANDac2 ; ANchn = 17
    movfw   ANRef5
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00011100' << 2    ; AN DAC 2 output
    goto    SET_ADC_CHN

SetupANTemp ; ANchn = 18
    movfw   ANRef5
    lsrf    WREG, F
    lsrf    WREG, F
    andlw   0x03
    iorlw   B'00011101' << 2    ; AN Temperature
    goto    SET_ADC_CHN

SetupANDac1 ; ANchn = 19
    movfw   ANRef5
    andlw   0x03
    iorlw   B'00011110' << 2    ; AN DAC 1 output
    goto    SET_ADC_CHN

SetupANFvr1 ; ANchn = 20
    banksel FVRCON
    movfw   FVRCON
    andlw   0xfc
    iorlw   0x01
    movwf   FVRCON
    movlw   B'00011111' << 2    ; AN Fixed Voltage Reference (1.024V)
    goto    SET_ADC_CHN

SetupANFvr2 ; ANchn = 21
    banksel FVRCON
    movfw   FVRCON
    andlw   0xfc
    iorlw   0x02
    movwf   FVRCON
    movlw   B'00011111' << 2    ; AN Fixed Voltage Reference (2.048V)
    goto    SET_ADC_CHN

SetupANFvr4 ; ANchn = 22
    banksel FVRCON
    movfw   FVRCON
    andlw   0xfc
    iorlw   0x03
    movwf   FVRCON
    movlw   B'00011111' << 2    ; AN Fixed Voltage Reference (4.096V)
    goto    SET_ADC_CHN

SetupOvf    ; ANchn = Overflow
    clrf    ANchn               ; ANchn overflow, reset value any try again
    goto    SETUP_NEXT_ADC_CHANNEL

SET_ADC_CHN
    banksel ADCON1
    movwf   ChnRef
    andlw   0x03
    skpz
    goto    SetupFvr

    ; Clear ADPREF in ADCON1 to set Vdd as Vref+
    movfw   ADCON1
    andlw   B'11111100'
    movwf   ADCON1
    goto    SetupAdcChn

SetupFvr
    ; Set ADPREF in ADCON1 to 0x02 set Fvr as Vref+
    movfw   ADCON1
    iorlw   B'00000011'
    movwf   ADCON1

    ; Set FVRCON to desired FVR value
    movfw   ChnRef
    andlw   0x03
    banksel FVRCON
    movwf   FvrRef
    movfw   FVRCON
    andlw   B'11111100'
    iorwf   FvrRef, W
    movwf   FVRCON
    banksel ADCON1

SetupAdcChn
    movfw   ChnRef
    andlw   0x1f << 2
    iorlw   0x01                ; Set ADON bit
    banksel ADCON0
    movwf   ADCON0
    return

    END
