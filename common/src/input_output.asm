;**********************************************************************
; Description:
;   Initialize I/O and handle any digital input/output.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "constants.inc"
    #include    "input_output.inc"
    #include    "isr_timer.inc"

;***** Global declarations ********************************************
    ; Methods
    GLOBAL Init_IO
    GLOBAL Do_Input
    GLOBAL Do_Output

    ; Variables
    GLOBAL Input
    GLOBAL InputD
    GLOBAL Output
    ;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    GLOBAL VFD_Char
#endif
;</editor-fold>


;***** Extern declarations ********************************************
    ; Variables
;    Extern Timer_Tick          ; From ISR_Timer.asm

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
Shared_Data udata_shr
Input       res 1
InputD      res 1
Output      res 1
;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
VFD_Char    res 1           ; Character code to write to VFD
#endif
;</editor-fold>

Temp_Data   udata_ovr   0x6e
Temp        res 1

;***** Code Section ***************************************************
PROG0   code

;**********************************************************************
; Init Input and Output
;   Initializes input.
;**********************************************************************
;<editor-fold defaultstate="collapsed" desc="PIC16F886">
#ifdef __16F886
Init_IO
    ; Select bank 0
    bcf     STATUS, RP0
    bcf     STATUS, RP1

    ; Clear variables
    clrf    Input
    clrf    InputD
    clrf    Output

    ; Setup I/O ports
    clrf    PORTA               ; Clear port A output latches
    clrf    PORTB               ; Clear port B output latches
    clrf    PORTC               ; Clear port C output latches
    clrf    PORTE               ; Clear port E output latches

    BANKSEL TRISA               ; Set bank for TRIS registers
    movlw   PortA_TRIS          ; Port A IO bits
    movwf   TRISA               ; Set Port A IO register

    movlw   PortB_TRIS          ; Port B IO bits
    movwf   TRISB               ; Set Port B IO register

    movlw   PortC_TRIS          ; Port C IO bits
    movwf   TRISC               ; Set Port C IO register

    ; Port B weak pullup
    movlw   PortB_WPU           ; Port B Weak Pullups
    movwf   WPUB
    bcf     OPTION_REG, NOT_RBPU; Enable weak pullup's

    ; Analog
    banksel ANSEL
    movlw   PortA_ADC           ; A/D / I/O select bits
    movwf   ANSEL

    movlw   PortB_ADC           ; A/D / I/O select bits
    movwf   ANSELH

#ifdef __DEBUG
    movlw   0xff
    movwf   Output
    call    Do_Output
    movlw   0x00
    movwf   Output
    call    Do_Output
#endif

    return
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PIC16F1713">
#ifdef __16F1713
Init_IO
    ; Clear variables
    clrf    Input
    clrf    InputD
    clrf    Output

    ; Setup I/O ports
    banksel PORTA
    clrf    PORTA               ; Clear port A output latches
    clrf    PORTB               ; Clear port B output latches
    clrf    PORTC               ; Clear port C output latches

    banksel ANSELA              ; Set Analog/digital select bits
    movlw   PortA_ADC
    movwf   ANSELA
    movlw   PortB_ADC
    movwf   ANSELB
    movlw   PortC_ADC
    movwf   ANSELC

    banksel WPUA                ; Configure weak pull-up
    movlw   PortA_WPU
    movwf   WPUA
    movlw   PortB_WPU
    movwf   WPUB
    movlw   PortC_WPU
    movwf   WPUC
    #if PortA_WPU || PortB_WPU || PortC_WPU != 0
    banksel OPTION_REG
    bcf     OPTION_REG, NOT_WPUEN; Enable weak pullup's
    #endif

    banksel ODCONA              ; Disable Open-drain output
    clrf    ODCONA
    clrf    ODCONB
    clrf    ODCONC

    banksel SLRCONA             ; Set slew rate to max
    clrf    SLRCONA
    clrf    SLRCONB
    clrf    SLRCONC

    banksel IOCAF               ; Disable Interrupt on change
    clrf    IOCAF
    clrf    IOCAN
    clrf    IOCAP
    clrf    IOCBF
    clrf    IOCBN
    clrf    IOCBP
    clrf    IOCCF
    clrf    IOCCN
    clrf    IOCCP

    banksel TRISA               ; Set Data Direction Registers
    movlw   PortA_TRIS
    movwf   TRISA
    movlw   PortB_TRIS
    movwf   TRISB
    movlw   PortC_TRIS
    movwf   TRISC

    ; Setup I2C peripheral..
    banksel PPSLOCK
    movlw   0x55                ; Issue the Lock/Unlock sequence..
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bcf     PPSLOCK, PPSLOCKED  ; Unlock periheral registers

    banksel RC3PPS
    movlw   B'00010000'         ; Set RC3 as SCL output pin
    movwf   RC3PPS
    movlw   B'00010001'         ; Set RC4 as SDA output pin
    movwf   RC4PPS

    banksel SSPCLKPPS
    movlw   B'00010011'         ; Set SSP CLK (I2C SCL) input to PORTC, Bit 3 (RC3)
    movwf   SSPCLKPPS
    movlw   B'00010100'         ; Set SSP DAT (I2C SDA) input to PORTC, Bit 4 (RC4)
    movwf   SSPDATPPS

    banksel PPSLOCK
    movlw   0x55                ; Issue the Lock/Unlock sequence..
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bsf     PPSLOCK, PPSLOCKED  ; Lock periheral registers

    return
#endif
;</editor-fold>

;**********************************************************************
; Do Input
;   Scan input I/O ports.
;**********************************************************************
Do_Input
    banksel PORTA
    clrf    Temp                ; Clear Temp Input

    ; Read input pins and set matching bits in the Temp variable
    ;<editor-fold defaultstate="collapsed" desc="BaxiController">
#ifdef BaxiController
    ; Styrsignal från Baxi (aktiv låg)
    btfss   BaxiFwdInPin
    bsf     Temp, inBaxiFwd     ; Forward
    btfss   BaxiRevInPin
    bsf     Temp, inBaxiRev     ; Reverse

    ; Pulsgivare på skruvaxeln
    btfsc   PgSkruvPin
    bsf     Temp, inPgSkruv
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    btfss   ButtonPin
    bsf     Temp, inButton

    btfsc   VFD_BusyPin
    bsf     Temp, inVFDBusy

    btfsc   VFD_WritePin
    bsf     Temp, inVFDWrite
#endif
;</editor-fold>

    ; Sätt InputD genom att köra en XOR på Temp och det gamla Input värdet
    movfw   Temp                ; Input Delta = Input xor Temp
    xorwf   Input, W
    movwf   InputD

    movfw   Temp                ; Input = Temp
    movwf   Input

    return

;**********************************************************************
; Do Output
;   Set output I/O ports.
;**********************************************************************
Do_Output
    banksel PORTA
#ifdef RunLed
    ; Run LED
    btfss   Output, outRunLed
    bcf     RunLedPin
    btfsc   Output, outRunLed
    bsf     RunLedPin
#endif

    ;<editor-fold defaultstate="collapsed" desc="BaxiController output">
#ifdef BaxiController
    ; Flismagasin Ir Diod
    #ifndef INVERT_TX_LED
    btfss   Output, outMagIrDiod
    bcf     MagIrDiodPin
    btfsc   Output, outMagIrDiod
    bsf     MagIrDiodPin
    #endif
    #ifdef INVERT_TX_LED
    ;btfss   Output, outMagIrDiod
    bsf     MagIrDiodPin
    ;btfsc   Output, outMagIrDiod
    ;bcf     MagIrDiodPin
    #endif

    ; Växlingsrelä (växlar mellan BAXI/PIC styrning av inmatningsmotorn)
    btfsc   Output, outSwRel
    bsf     SwRelPin
    btfss   Output, outSwRel
    bcf     SwRelPin

    ; Triac styrning (aktiv hög)
    btfss   Output, outTriac
    bcf     TriacUtPin
    btfsc   Output, outTriac
    bsf     TriacUtPin

    ; Back relä (aktiv hög)
    btfss   Output, outRevRel
    bcf     RevRelPin
    btfsc   Output, outRevRel
    bsf     RevRelPin

    ; Spänning till strömmätarna (aktiv hög)
    btfss   Output, outCurPwr
    bcf     CurPwrPin
    btfsc   Output, outCurPwr
    bsf     CurPwrPin
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="LcdDisplay output">
#ifdef LcdDisplay
#ifndef HW_PWM
    ; LCD Backlight
    btfss   Output, outBL
    bcf LcdBlPin
    btfsc   Output, outBL
    bsf LcdBlPin
#endif
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="LedDisplay output">
#ifdef LedDisplay
    btfss   Output, outLED0
    bcf     LED0Pin
    btfsc   Output, outLED0
    bsf     LED0Pin

    btfss   Output, outLED1
    bcf     LED1Pin
    btfsc   Output, outLED1
    bsf     LED1Pin

    btfss   Output, outLED2
    bcf     LED2Pin
    btfsc   Output, outLED2
    bsf     LED2Pin
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="RS232Interface output">
#ifdef RS232Interface
#ifdef __DEBUG
    btfss   Output, outLed1
    bsf     Led1Pin
    btfsc   Output, outLed1
    bcf     Led1Pin

    btfss   Output, outLed2
    bsf     Led2Pin
    btfsc   Output, outLed2
    bcf     Led2Pin
#endif

    btfss   Output, outACT
    bcf     ActLedPin
    btfsc   Output, outACT
    bsf     ActLedPin
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    bcf     VFD_SelectPin       ; VFD Select should always be low ( = Always selected)

    btfss   Output, outVFDResetWR
    goto    SkipVfdWrReset

    bcf     Output, outVFDResetWR
    bcf     VFD_WritePin
SkipVfdWrReset

    btfsc   VFD_BusyPin         ;Skip write if the Busy flag is set
    goto    Skip_VFD_Char_Output

    btfsc   Input, inVFDWrite   ; VFD write set?
    goto    Skip_VFD_Char_Output; Yes, skip data output

    ; Write char to VFD (D0 - D7).
    bcf     VFD_WritePin        ; Set VFD WR to low
    ; Because D0 isn't mapped to RA0 we have to set the bits separately.
    clrf    PORTA               ; All VDF_Dx is on PORTA
    btfsc   VFD_Char, 0x07
    bsf     VFD_D7Pin
    btfsc   VFD_Char, 0x06
    bsf     VFD_D6Pin
    btfsc   VFD_Char, 0x05
    bsf     VFD_D5Pin
    btfsc   VFD_Char, 0x04
    bsf     VFD_D4Pin
    btfsc   VFD_Char, 0x03
    bsf     VFD_D3Pin
    btfsc   VFD_Char, 0x02
    bsf     VFD_D2Pin
    btfsc   VFD_Char, 0x01
    bsf     VFD_D1Pin
    btfsc   VFD_Char, 0x00
    bsf     VFD_D0Pin
Skip_VFD_Char_Output

    ; Alarm
    btfss   Output, outAlarm
    bsf     AlarmPin
    btfsc   Output, outAlarm
    bcf     AlarmPin

    ; VFD Write
    btfss   Output, outVFDWrite ; VFD Write flag set?
    return                      ; No, return
    btfsc   VFD_BusyPin         ; Yes, check if the Busy flag is set
    return                      ; Yes, still busy, return
    bcf     Output, outVFDWrite ; Clear VFD write flag
    bsf     VFD_WritePin        ; Set VFD WR to high
#endif
;</editor-fold>

    return


    END
