;**********************************************************************
; Description:
;   Define global constants used with ADC.asm.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************


; ADC state constants
adcDone         EQU 0x07    ; New ADC value is complete
adcReInit       EQU 0x06    ; Reinitialize ADC
#ifdef BaxiController
adcOcSignalDone EQU 0x05    ; New Over-Current-Signal value is complete
#endif
