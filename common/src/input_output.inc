;**********************************************************************
; Description:
;   Define all physical input/output. No manipulation should be done
;   directly, all manipulation of pin input/output shold be done in the
;   Do_Input/Do_Output methods.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

; PORT A
;<editor-fold defaultstate="collapsed" desc="BaxiController">
#ifdef BaxiController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 0 = Triacstyrnig (aktiv hög)
    ; RA6 : 0 = Reverserings relä (aktiv hög)
    ; RA5 : A = AN4, Tröskelvärde för strömmätning, för att börja backa
    ; RA4 : 0 = Växlings relä Baxi / PIC (PC) (aktiv hög) 1 = PC, 0 = Baxi
    ; RA3 : A = AN3
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : 0 = Signal för att tända IR-dioden i flismagasinet (aktiv hög)
    #define PortA_TRIS      B'00101110'     ; PORTA Data Direction Register
    #define PortA_ADC       B'00101110'     ; Bara RA2-3/AN2-3 som analoga ingångar
    #define PortA_WPU       B'00000000'     ; Disabled Pullup on PORT A
    #define TriacUtPin      PORTA, 0x07     ; Triacstyrnig (aktiv hög)
    #define RevRelPin       PORTA, 0x06     ; Reverserings relä (aktiv hög)
    #define SwRelPin        PORTA, 0x04     ; Växlings relä Baxi/PIC (aktiv hög)
    #define MagIrDiodPin    PORTA, 0x00     ; Signal för att tända IR-dioden i flismagasinet (aktiv hög)
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DHT11">
#ifdef DHT11
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Unused
    ; RA6 : 1 = Unused
    ; RA5 : A = AN4
    ; RA4 : 1 = Unused
    ; RA3 : A = AN3
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : 1 = AN0
    #define PortA_TRIS      B'11111111'     ; PORTA Data Direction Register
    #define PortA_ADC       B'00111111'     ; Bara RA2-3/AN2-3 som analoga ingångar
    #define PortA_WPU       B'00000000'     ; Disabled Pullup on PORT A
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="CombiheatController (Obsolete)">
#ifdef CombiheatController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : A = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortAIO         B'11111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00011111'         ; All possible as analog inputs
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DevPcbController (Obsolete)">
#ifdef DevPcbController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 0 = LED #1
    ; RA6 : 0 = LED #2
    ; RA5 : 1 = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortAIO         B'00111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00011111'         ; All possible as analog inputs
    #define LED1Pin         PORTA, 0x07         ; LED #1
    #define LED2Pin         PORTA, 0x06         ; LED #2
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LcdDisplay">
#ifdef LcdDisplay
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : 1 = Oanvänd
    ; RA4 : 1 = Oanvänd
    ; RA3 : 1 = Oanvänd
    ; RA2 : 1 = Oanvänd
    ; RA1 : 1 = Oanvänd
    ; RA0 : 0 = Running LED pin
    #define PortA_TRIS      B'11111110'     ; PORTA Data Direction Register
    #define PortA_ADC       B'00000000'     ; Bara RA2-3/AN2-3 som analoga ingångar
    #define PortA_WPU       B'00000000'     ; Disabled Pullup on PORT A
    #define RunLedPin       PORTA, 0x00     ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LedDisplay">
#ifdef LedDisplay
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : 1 = Oanvänd
    ; RA4 : 1 = Oanvänd
    ; RA3 : 1 = Oanvänd
    ; RA2 : 1 = Oanvänd
    ; RA1 : 1 = Oanvänd
    ; RA0 : 1 = Oanvänd
    #define PortA_TRIS      B'11111000'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00000000'         ; No Analog Input
    ;#define RA7Pin         PORTA, 0x07         ; RA7
    ;#define RA6Pin         PORTA, 0x06         ; RA6
    ;#define RA5Pin         PORTA, 0x05         ; RA5
    ;#define RA4Pin         PORTA, 0x04         ; RA4
    ;#define RA3Pin         PORTA, 0x03         ; RA3
    #define LED2Pin         PORTA, 0x02         ; RA2
    #define LED1Pin         PORTA, 0x01         ; RA1
    #define LED0Pin         PORTA, 0x00         ; RA0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PcIoController (Obsolete)">
#ifdef PcIoController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : 1 = Baxi #1 - Alarm: Skruven har fastnat
    ; RA4 : 1 = Oanvänd
    ; RA3 : 1 = Baxi #1 - Alarm: Pannan har slocknat
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortAIO         B'11111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00000111'         ; All possible as analog inputs
    #define LrmB1StuckPin   PORTA, 0x05         ; Larm skruven har fastnat
    #define LrmB1PhsPin     PORTA, 0x03         ; Larm Pannan Har Slocknat
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PicIoController">
#ifdef PicIoController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : A = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortA_TRIS      B'11111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00011111'         ; All possible as analog inputs
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PressureController (Obsolete)">
#ifdef PressureController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : A = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref+
    ; RA2 : A = AN2/Ref-
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortAIO         B'11111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'11111111'         ; All possible as analog inputs
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="RS232Interface">
#ifdef RS232Interface
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : 1 = Oanvänd
    ; RA4 : 1 = Oanvänd
    ; RA3 : 1 = Oanvänd
    ; RA2 : 1 = Oanvänd
    ; RA1 : 0 = Oanvänd
    ; RA0 : 0 = Oanvänd
#ifdef __DEBUG
    #define PortA_TRIS      B'11100000'     ; PORTA Data Direction Register
#else
    #define PortA_TRIS      B'11111111'     ; PORTA Data Direction Register
#endif
    #define PortA_ADC       B'00000000'     ; All as digital inputs
    #define PortA_WPU       B'00000000'     ; Disabled Pullup on PORT A
#ifdef __DEBUG
    #define Led1Pin         PORTA, 0x00
    #define Led2Pin         PORTA, 0x01
    #define StartCheckPin   PORTA, 0x02
    #define StartTrigPin    PORTA, 0x03
    #define IsrPin          PORTA, 0x04
#endif
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdController">
#ifdef SpdController
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : A = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortA_TRIS      B'11111111'         ; PORTA Data Direction Register
    ;#define PortA_TRIS     B'00111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00011111'         ; ANS4-ANS0 as analog inputs
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdSim">
#ifdef SpdSim
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Oanvänd
    ; RA6 : 1 = Oanvänd
    ; RA5 : A = AN4
    ; RA4 : 1 = Oanvänd
    ; RA3 : A = AN3/Ref
    ; RA2 : A = AN2
    ; RA1 : A = AN1
    ; RA0 : A = AN0
    #define PortA_TRIS      B'11111111'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00011111'         ; ANS4-ANS0 as analog inputs
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 0 = VFD_D1
    ; RA6 : 0 = VFD_D0
    ; RA5 : 0 = VFD_D2
    ; RA4 : 0 = VFD_D3
    ; RA3 : 0 = VFD_D4
    ; RA2 : 0 = VFD_D5
    ; RA1 : 0 = VFD_D6
    ; RA0 : 0 = VFD_D7
    #define PortA_TRIS      B'00000000'         ; PORTA Data Direction Register
    #define PortA_ADC       B'00000000'         ; No Analog Input
    #define VFD_D1Pin       PORTA, 0x07         ; VFD D1
    #define VFD_D0Pin       PORTA, 0x06         ; VFD D0
    #define VFD_D2Pin       PORTA, 0x05         ; VFD D2
    #define VFD_D3Pin       PORTA, 0x04         ; VFD D3
    #define VFD_D4Pin       PORTA, 0x03         ; VFD D4
    #define VFD_D5Pin       PORTA, 0x02         ; VFD D5
    #define VFD_D6Pin       PORTA, 0x01         ; VFD D6
    #define VFD_D7Pin       PORTA, 0x00         ; VFD D7
#endif
;</editor-fold>


; PORT B
;<editor-fold defaultstate="collapsed" desc="BaxiController">
#ifdef BaxiController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 0 = Running LED
    ; RB6 : 0 = Power to Current sensors (active high)
    ; RB5 : A = AN13, Tröskelvärde för strömmätning, för att stoppa inmatning
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10, Strömmätning
    ; RB0 : A = AN12, Vatten ut
    #define PortB_TRIS      B'00111111'     ; PORTB Data Direction Register
    #define PortB_ADC       B'00111111'     ; All possible as analog inputs
    #define PortB_WPU       B'00000000'     ; Disabled Pullup on PORT B
    #define RunLedPin       PORTB, 0x07     ; Running LED pin
    #define CurPwrPin       PORTB, 0x06     ; Power to Current sensors (active high)
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DTH11">
#ifdef DHT11
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 0 = Running LED
    ; RB6 : 1 = Unused
    ; RB5 : A = AN13
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : 1 = DHT11 sensor
    #define PortB_TRIS      B'01111111'     ; PORTB Data Direction Register
    #define PortB_ADC       B'00111110'     ; All possible as analog inputs
    #define PortB_WPU       B'00000000'     ; Disabled Pullup on PORT B
    #define RunLedPin       PORTB, 0x07     ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="CombiheatController (Obsolete)">
#ifdef CombiheatController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : A = AN13
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortBIO         B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00111111'         ; Alla som analoga ingångar
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DevPcbController (Obsolete)">
#ifdef DevPcbController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : A = AN13
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortBIO         B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00111111'         ; Alla som analoga ingångar
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LcdDisplay">
#ifdef LcdDisplay
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 0 = Data 7
    ; RB6 : 0 = Data 6
    ; RB5 : 0 = Data 5
    ; RB4 : 0 = Data 4
    ; RB3 : 0 = Data 3
    ; RB2 : 0 = Data 2
    ; RB1 : 0 = Data 1
    ; RB0 : 0 = Data 0
    #define PortB_TRIS      B'00000000'     ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'     ; All possible as analog inputs
    #define PortB_WPU       B'00000000'     ; Disabled Pullup on PORT B
    ; LCD Data
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LedDisplay">
#ifdef LedDisplay
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : 1 = Oanvänd
    ; RB4 : 1 = Oanvänd
    ; RB3 : 0 = !Reset
    ; RB2 : 0 = !Load
    ; RB1 : 0 = Data
    ; RB0 : 0 = SDCLK
    #define PortB_TRIS      B'11110000'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; Alla som digitala in/ut-gångar
    #define PortB_WPU       B'00000000'         ; Enabled Pullup on PORT B
    ;#define RB7Pin         PORTB, 0x07         ; RB7
    ;#define RB6Pin         PORTB, 0x06         ; RB6
    ;#define RB5Pin         PORTB, 0x05         ; RB5
    ;#define RB4Pin         PORTB, 0x04         ; RB4
    #define LedReset        PORTB, 0x03         ; Vit   !Reset
    #define LedLoad         PORTB, 0x02         ; Lila  !Load
    #define LedData         PORTB, 0x01         ; Blå   Data
    #define LedClk          PORTB, 0x00         ; Grön  SDCLK

    ; LED display
    ; 1 - Svart GND
    ; 2 - Vit   !Reset (Vit)
    ; 3 - Svart SDCLK  (Grön)
    ; 4 - Vit   Data   (Blå)
    ; 5 - Svart !Load  (Lila)
    ; 6 - Vit   Vcc
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PcIoController (Obsolete)">
#ifdef PcIoController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Knapp - Tysta larm (intern pullup, aktiv låg)
    ; RB5 : 1 = Baxi #2: Larm skruv reversering (aktiv låg)
    ; RB4 : 1 = Baxi #2: Larm Låg Nivå i Flismagasin (aktiv låg)
    ; RB3 : 1 = Baxi #2: Larm skruven har fastnat (aktiv låg)
    ; RB2 : 1 = Baxi #2: Larm Pannan Har Slocknat (aktiv låg)
    ; RB1 : 1 = Baxi #1: Larm skruv reversering (aktiv låg)
    ; RB0 : 1 = Baxi #1: Larm Låg Nivå i Flismagasin (aktiv låg)
    #define PortBIO         B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; Alla som digitala ingångar
    #define PortB_WPU       B'01000000'         ; Pullups on PORT B
    #define LrmBtnPin       PORTB, 0x06         ; Larm knapp
;   #define LrmB2RevPin     PORTB, 0x05         ; Baxi #2: Larm skruv reversering
    #define LrmB2LnfPin     PORTB, 0x04         ; Baxi #2: Larm Låg Nivå i Flismagasin
    #define LrmB2StuckPin   PORTB, 0x03         ; Baxi #2: Larm skruven har fastnat
    #define LrmB2PhsPin     PORTB, 0x02         ; Baxi #2: Larm Pannan Har Slocknat
;   #define LrmB1RevPin     PORTB, 0x01         ; Baxi #1: Larm skruv reversering
    #define LrmB1LnfPin     PORTB, 0x00         ; Baxi #1: Larm Låg Nivå i Flismagasin

#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PicIoController">
#ifdef PicIoController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : A = AN13
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortB_TRIS      B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00111111'         ; Alla som analoga ingångar
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PressureController (Obsolete)">
#ifdef PressureController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : A = AN13
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortBIO         B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00111111'         ; Alla som analoga ingångar
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="RS232Interface">
#ifdef RS232Interface
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : 1 = Oanvänd
    ; RB4 : 1 = Oanvänd
    ; RB3 : 1 = Oanvänd
    ; RB2 : 1 = Oanvänd
    ; RB1 : 1 = Oanvänd
    ; RB0 : 1 = Oanvänd
#ifdef __DEBUG
    #define PortB_TRIS      B'11110000'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; All as digital inputs
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#else
    #define PortB_TRIS      B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; All as digital inputs
    #define PortB_WPU       B'00000000'         ; Disabled Pullup on PORT B
#endif
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdController">
#ifdef SpdController
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : 1 = Serial data input from SPD100GD pressure gauge
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortB_TRIS      B'11111111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00011111'         ; ANS12-ANS8 as analog input, ANS13 as digital I/O
    #define PortB_WPU       B'00100000'         ; No enabled pullup on PORT B
    ;#define RB7Pin         PORTB, 0x07         ; RB7
    ;#define RB6Pin         PORTB, 0x06         ; RB6
    #define SPDPin          PORTB, 0x05         ; Serial data input from SPD100GD pressure gauge
    ;#define RB4Pin         PORTB, 0x04         ; RB4
    ;#define RB3Pin         PORTB, 0x03         ; RB3
    ;#define RB2Pin         PORTB, 0x02         ; RB2
    ;#define RB1Pin         PORTB, 0x01         ; RB1
    ;#define RB0Pin         PORTB, 0x00         ; RB0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdSim">
#ifdef SpdSim
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : 0 = Serial data output
    ; RB4 : A = AN11
    ; RB3 : A = AN9
    ; RB2 : A = AN8
    ; RB1 : A = AN10
    ; RB0 : A = AN12
    #define PortB_TRIS      B'11011111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00011111'         ; ANS12-ANS8 as analog input, ANS13 as digital I/O
    #define PortB_WPU       B'00100000'         ; No enabled pullup on PORT B
    ;#define RB7Pin         PORTB, 0x07         ; RB7
    ;#define RB6Pin         PORTB, 0x06         ; RB6
    #define SPDPin          PORTB, 0x05         ; SPD100GD serial data output
    ;#define RB4Pin         PORTB, 0x04         ; RB4
    ;#define RB3Pin         PORTB, 0x03         ; RB3
    ;#define RB2Pin         PORTB, 0x02         ; RB2
    ;#define RB1Pin         PORTB, 0x01         ; RB1
    ;#define RB0Pin         PORTB, 0x00         ; RB0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Oanvänd
    ; RB6 : 1 = Oanvänd
    ; RB5 : 0 = Summer
    ; RB4 : 1 = Knapp
    ; RB3 : 1 = Oanvänd
    ; RB2 : 1 = Oanvänd
    ; RB1 : 1 = Oanvänd
    ; RB0 : 1 = Oanvänd
#ifdef __DEBUG
    #define PortB_TRIS      B'11110111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; Alla som digitala in/ut-gångar
    #define PortB_WPU       B'00000000'         ; Enabled Pullup on PORT B
    #define AlarmPin        PORTB, 0x03         ; Alarm summer
    #define ButtonPin       PORTB, 0x04         ; Select / Snooze Button
#else
    #define PortB_TRIS      B'11011111'         ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'         ; Alla som digitala in/ut-gångar
    #define PortB_WPU       B'00000000'         ; Enabled Pullup on PORT B
    ;#define RB7Pin         PORTB, 0x07         ; RB7
    ;#define RB6Pin         PORTB, 0x06         ; RB6
    #define AlarmPin        PORTB, 0x05         ; Alarm summer
    #define ButtonPin       PORTB, 0x04         ; Select / Snooze Button
    ;#define RB3Pin         PORTB, 0x03         ; RB3
    ;#define RB2Pin         PORTB, 0x02         ; RB2
    ;#define RB1Pin         PORTB, 0x01         ; RB1
    ;#define RB0Pin         PORTB, 0x00         ; RB0
#endif
#endif
;</editor-fold>


; PORT C
;<editor-fold defaultstate="collapsed" desc="BaxiController">
#ifdef BaxiController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : A = AN19, Signal från IR-diod (<3V = tomt)
    ; RC6 : A = AN18, Rökgastemp
    ; RC5 : 1 = Signal från pulsgivare på skruvmotoraxeln
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : A = AN14, Oanvänd
    ; RC1 : 1 = Signal från Baxi för att köra skruven bakåt (aktiv låg)
    ; RC0 : 1 = Signal från Baxi för att starta inmatning (aktiv låg)
    #define PortC_TRIS      B'11111111'     ; PORTC Data Direction Register
    #define PortC_ADC       B'11000100'     ; Alla som analoga ingångar
    #define PortC_WPU       B'00100011'     ; Disabled Pullup on PORT C
    #define PgSkruvPin      PORTC, 0x05     ; Signal från pulsgivare på skruvmotoraxeln
    #define BaxiRevInPin    PORTC, 0x01     ; Signal från Baxi för att köra skruven bakåt (aktiv låg)
    #define BaxiFwdInPin    PORTC, 0x00     ; Signal från Baxi för att köra skruven frammåt (aktiv låg)
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DHT11">
#ifdef DHT11
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : A = AN19, Unused
    ; RC6 : A = AN18, Unused
    ; RC5 : A = AN, Unused
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : A = AN14, Unused
    ; RC1 : 1 = Unused
    ; RC0 : 1 = Unused
    #define PortC_TRIS      B'11111111'     ; PORTC Data Direction Register
    #define PortC_ADC       B'11000100'     ; Alla som analoga ingångar
    #define PortC_WPU       B'00100011'     ; Disabled Pullup on PORT C
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="CombiheatController (Obsolete)">
#ifdef CombiheatController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 0 = Running LED
    ; RC0 : 1 = Oanvänd
    #define PortCIO         B'11111101'         ; PORTC Data Direction Register
    #define RunLedPin       PORTC, 0x01         ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="DevPcbController (Obsolete)">
#ifdef DevPcbController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 1 = Oanvänd
    ; RC0 : 1 = Oanvänd
    #define PortCIO         B'11111111'         ; PORTC Data Direction Register
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LcdDisplay">
#ifdef LcdDisplay
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 0 = LCD Enable
    ; RC6 : 0 = LCD R/W
    ; RC5 : 0 = LCD RS
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 0 = Backlight PWM output
    ; RC1 : 1 = Oanvänd
    ; RC0 : 1 = Oanvänd
    #define PortC_TRIS      B'00011011'     ; PORTC Data Direction Register
    #define PortC_ADC       B'00000000'     ; Alla som analoga ingångar
    #define PortC_WPU       B'00000000'     ; Disabled Pullup on PORT C
    #define LcdEPin         PORTC, 0x07     ; LCD Enable pin
    #define LcdRwPin        PORTC, 0x06     ; LCD R/W pin
    #define LcdRsPin        PORTC, 0x05     ; LCD RS pin
#ifndef HW_PWM
    #define LcdBlPin        PORTC, 0x02     ; LCD Backlight pin
#endif
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="LedDisplay">
#ifdef LedDisplay
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 1 = Oanvänd
    ; RC0 : 1 = Oanvänd
    #define PortC_TRIS      B'11111101'         ; PORTC Data Direction Register
    ;#define RC7Pin         PORTC, 0x07         ; RC7
    ;#define RC6Pin         PORTC, 0x06         ; RC6
    ;#define RC5Pin         PORTC, 0x05         ; RC5
    ;#define SDAPin         PORTC, 0x04         ; I2C SDA - Must be set as input in TRIS
    ;#define SCLPin         PORTC, 0x03         ; I2C SCL - Must be set as input in TRIS
    ;#define RC2Pin         PORTC, 0x02         ; RC2
    #define RunLedPin       PORTC, 0x01         ; RC1
    ;#define RC0Pin         PORTC, 0x00         ; RC0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PcIoController (Obsolete)">
#ifdef PcIoController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 0 = Relä, siren till fågelskrämma
    ; RC5 : 0 = Alarm summer
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 0 = Running LED
    ; RC0 : 1 = Oanvänd
    #define PortCIO         B'10011101'         ; PORTC Data Direction Register
    #define BAPin           PORTC, 0x06         ; Fågelskrämma (Bird Alarm)
    #define LrmOutPin       PORTC, 0x05         ; Summer Alarm
    #define RunLedPin       PORTC, 0x01         ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PicIoController">
#ifdef PicIoController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 0 = Running LED
    ; RC0 : 1 = Oanvänd
    #define PortC_TRIS      B'11111101'         ; PORTC Data Direction Register
    #define RunLedPin       PORTC, 0x01         ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PressureController (Obsolete)">
#ifdef PressureController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 0 = Running LED
    ; RC0 : 1 = Oanvänd
    #define PortCIO         B'11111101'         ; PORTC Data Direction Register
    #define RunLedPin       PORTC, 0x01         ; Running LED pin
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="RS232Interface">
#ifdef RS232Interface
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = RS232 Rx
    ; RC6 : 0 = RS232 Tx
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 0 = I2C bus activity LED
    ; RC1 : 1 = Oanvänd
    ; RC0 : 1 = Oanvänd
#ifdef __DEBUG
    #define PortC_TRIS      B'10111001'         ; PORTC Data Direction Register
#else
    #define PortC_TRIS      B'10111011'         ; PORTC Data Direction Register
#endif
    #define ActLedPin       PORTC, 0x02         ; I2C bus activity LED
#ifdef __DEBUG
    #define RunLedPin       PORTC, 0x01         ; Running LED
#endif
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdController">
#ifdef SpdController
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 1 = Oanvänd
    ; RC1 : 0 = Running LED
    ; RC0 : 1 = Oanvänd
    #define PortC_TRIS      B'11111101'         ; PORTC Data Direction Register
    ;#define RC7Pin         PORTC, 0x07         ; RC7
    ;#define RC6Pin         PORTC, 0x06         ; RC6
    ;#define RC5Pin         PORTC, 0x05         ; RC5
    ;#define SDAPin         PORTC, 0x04         ; I2C SDA - Must be set as input in TRIS
    ;#define SCLPin         PORTC, 0x03         ; I2C SCL - Must be set as input in TRIS
    ;#define RC2Pin         PORTC, 0x02         ; RC2
    #define RunLedPin       PORTC, 0x01         ; Running LED pin
    ;#define RC0Pin         PORTC, 0x00         ; RC0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="SpdSim">
#ifdef SpdSim
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA (Oanvänd
    ; RC3 : 1 = I2C SCL (Oanvänd)
    ; RC2 : 1 = Oanvänd
    ; RC1 : 1 = Oanvänd
    ; RC0 : 0 = Running LED
    #define PortC_TRIS      B'11111110'         ; PORTC Data Direction Register
    ;#define RC7Pin         PORTC, 0x07         ; RC7
    ;#define RC6Pin         PORTC, 0x06         ; RC6
    ;#define RC5Pin         PORTC, 0x05         ; RC5
    ;#define SDAPin         PORTC, 0x04         ; I2C SDA - Must be set as input in TRIS
    ;#define SCLPin         PORTC, 0x03         ; I2C SCL - Must be set as input in TRIS
    ;#define RC2Pin         PORTC, 0x02         ; RC2
    #define RunLedPin       PORTC, 0x00         ; Running LED pin
    ;#define RC0Pin         PORTC, 0x00         ; RC0
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 1 = Oanvänd
    ; RC6 : 1 = Oanvänd
    ; RC5 : 1 = Oanvänd
    ; RC4 : 1 = I2C SDA
    ; RC3 : 1 = I2C SCL
    ; RC2 : 0 = VFD_Select
    ; RC1 : 1 = VFD_Busy
    ; RC0 : 0 = VFD_WR
    #define PortC_TRIS      B'11111010'         ; PORTC Data Direction Register
    ;#define RC7Pin         PORTC, 0x07         ; RC7
    ;#define RC6Pin         PORTC, 0x06         ; RC6
    ;#define RC5Pin         PORTC, 0x05         ; RC5
    ;#define SDAPin         PORTC, 0x04         ; I2C SDA - Must be set as input in TRIS
    ;#define SCLPin         PORTC, 0x03         ; I2C SCL - Must be set as input in TRIS
    #define VFD_SelectPin   PORTC, 0x02         ; RC2
    #define VFD_BusyPin     PORTC, 0x01         ; RC1
    #define VFD_WritePin    PORTC, 0x00         ; RC0
#endif
;</editor-fold>

