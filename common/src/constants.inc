;**********************************************************************
; Description:
;   Define global constants used in various places in many modules.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************


; *** Reset flags *****************************************************

rfPOR       EQU 0x07        ; Power On Reset
rfBOR       EQU 0x06        ; Brown-out Reset
rfWDT       EQU 0x05        ; Watchdog Timeout Rest
rfSTKOF     EQU 0x04        ; Stack overflow reset
rfSTKUF     EQU 0x03        ; Stack underflow reset
rfMCLR      EQU 0x02        ; MClear Reset
rfRI        EQU 0x01        ; Reset instruction


; *** Input/Output Constants ******************************************

;<editor-fold defaultstate="collapsed" desc="BaxiController">
#ifdef BaxiController
; Input constants
inBaxiFwd       EQU 0x07    ; Inmatningssignal ifrån Baxi styrningen
inBaxiRev       EQU 0x06    ; Inmatningssignal ifrån Baxi styrningen
inPgSkruv       EQU 0x05    ; Pulsvivare på skruv axeln
;inPgOmrMotor   EQU 0x04    ; Pulsgivare på omrörarmotor
;inSkruvMotor   EQU 0x03    ; Spänning skruvmotor

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
outTriac        EQU 0x06    ; Styrsignal för triac styrningen av skruv motorn
outRevRel       EQU 0x05    ; Reverseringsrelä för skruv motorn
outMagIrDiod    EQU 0x04    ; Flismagasin Ir diod (1 = Lysa)
outSwRel        EQU 0x03    ; Spänning till växlingsrelä (1 = PIC/Triac, 0 = Baxi/Kontaktor)
outCurPwr       EQU 0x02    ; Spänning till strömmätarna (Aktiv hög)
;out            EQU 0x01    ;
;out            EQU 0x00    ;

; Alarm constants
lrmTempAlarm    EQU 0x07    ; Alarm: Temperatur alarm (rökgastemp)
lrmMagAlarm     EQU 0x06    ; Alarm: Låg nivå flismagasin
lrmReversing    EQU 0x05    ; Alarm: Skruv reverserar
lrmStuck        EQU 0x04    ; Alarm: Skruv fastnat
lrmNoInput      EQU 0x03    ; Alarm: Ingen inmatnings signal

; Triac control constants
tcFwd           EQU 0x07    ; Run forward
tcRev           EQU 0x06    ; Run backward
tcTimeout       EQU 0x05    ; Use fwd/rev timeout
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="DHT11">
#ifdef DHT11
; Input constants
;in     EQU 0x07    ;
;in     EQU 0x06    ;
;in     EQU 0x05    ;
;in     EQU 0x04    ;
;in     EQU 0x03    ;
;in     EQU 0x02    ;
;in     EQU 0x01    ;
;in     EQU 0x00    ;

; Output constants
outRunLed   EQU 0x07    ; Program Running LED
;out         EQU 0x06    ;
;out         EQU 0x05    ;
;out         EQU 0x04    ;
;out         EQU 0x03    ;
;out         EQU 0x02    ;
;out         EQU 0x01    ;
;out         EQU 0x00    ;
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="CombiheatController (Obsolete)">
#ifdef CombiheatController
; Input constants
;in.....        EQU 0x07    ; ???

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="DevPcbController (Obsolete)">
#ifdef DevPcbController
; Input constants
;in.....        EQU 0x07    ; ???

; Output constants
outLED1         EQU 0x07    ; LED #1
outLED2         EQU 0x06    ; LED #2
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="LcdDisplay">
#ifdef LcdDisplay
; Input constants
;in         EQU 0x07    ;

; Output constants
outRunLed   EQU 0x07    ; Program Running LED
outE        EQU 0x06    ; LCD Enable
outRS       EQU 0x05    ; LCD Register Select
outRW       EQU 0x04    ; LCD Read/Write
#ifndef HW_PWM
outBL       EQU 0x03    ; LCD Backlight
#endif
;out        EQU 0x02    ;
;out        EQU 0x01    ;
;out        EQU 0x00    ;
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="LedDisplay">
#ifdef LedDisplay
; Input constants
;in...          EQU 0x07    ; ???

; Output constants
outLED0         EQU 0x07    ; LED #1
outLED1         EQU 0x06    ; LED #2
outLED2         EQU 0x05    ; LED #3
outRunLed       EQU 0x04    ; Run LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="PcIoController (Obsolete)">
#ifdef PcIoController
; Input constants
inLrmBtn        EQU 0x07    ; Larm knapp
inLrmLnfB1      EQU 0x06    ; Larm - Låg Nivå i Flismagasin
inLrmLnfB2      EQU 0x05    ; Larm - Låg Nivå i Flismagasin
inLrmPhsB1      EQU 0x04    ; Larm - Pannan Har Slocknat (Baxi 1)
inLrmPhsB2      EQU 0x03    ; Larm - Pannan Har Slocknat (Baxi 2)
inLrmStuckB1    EQU 0x02    ; Larm - Skruven har fastnat (Baxi 1)
inLrmStuckB2    EQU 0x01    ; Larm - Skruven har fastnat (Baxi 2)

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
outBirdAlarm    EQU 0x06    ; Enable/Disable Bird Alarm relay
outAlarm        EQU 0x05    ; Enable/Disable summer alarm
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="PicIoController">
#ifdef PicIoController
; Input constants
;in.....        EQU 0x07    ; ???

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="PressureController (Obsolete)">
#ifdef PressureController
; Input constants
;in...          EQU 0x07    ; ???

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="RS232Interface">
#ifdef RS232Interface
; Input constants
;in...          EQU 0x07    ; ???

; Output constants
outACT          EQU 0x07
#ifdef __DEBUG
outLed1         EQU 0x06
outLed2         EQU 0x05
outRunLed       EQU 0x04
#endif
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="SpdController">
#ifdef SpdController
; Input constants
;in.....        EQU 0x07    ; ???

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="SpdSim">
#ifdef SpdSim
; Input constants
;in.....        EQU 0x07    ; ???

; Output constants
outRunLed       EQU 0x07    ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="SolPic">
#ifdef SolPic
; Input constants
; Input 1
i1AlUEp     EQU 0x07        ; Upper Altitude Endpoint
i1AlLEp     EQU 0x06        ; Lower Altitude Endpoint
i1AzUEp     EQU 0x05        ; Upper Azimuth Endpoint
i1AzLEp     EQU 0x04        ; Lower Azimuth Endpoint
i1Wind      EQU 0x03        ; Wind speed
i1AlPg      EQU 0x02        ; Altitude position pulses
i1AzPg2     EQU 0x01        ; Azimuth position pulse counter
i1AzPg1     EQU 0x00        ; Azimuth position pulse counter
; Input 2
i2AlDec     EQU 0x05        ; Altitude -
i2AlInc     EQU 0x04        ; Altitude +
i2HmPwr     EQU 0x03        ; Hydraulic motor power
i2AzDec     EQU 0x02        ; Azimuth -
i2AzInc     EQU 0x01        ; Azimuth +

; Output constants
;outAcsEn   EQU 0x06        ; ACS712 enable
outAlDec    EQU 0x05        ; Altitude -
outAlInc    EQU 0x04        ; Altitude +
outHmPwr    EQU 0x03        ; Hydraulic motor power
outAzDec    EQU 0x02        ; Azimuth -
outAzInc    EQU 0x01        ; Azimuth +
outRunLed   EQU 0x00        ; Program Running LED
#endif
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="VfdDisplay">
#ifdef VfdDisplay
; Input constants
inButton        EQU 0x07    ; Button
inVFDBusy       EQU 0x06    ; VFD Busy pin
inVFDWrite      EQU 0x05    ; VFD Write pin

; Output constants
outAlarm        EQU 0x07    ; Temp alarm (vatten)
outVFDWrite     EQU 0x06    ; VFD Write pin
outVFDResetWR   EQU 0x05    ; VFD Reset WR pin
#endif
;</editor-fold>
