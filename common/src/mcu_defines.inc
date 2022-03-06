;**********************************************************************
; Description:
;   This defines the common MCU defines that is included in all source
;   files.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    ;<editor-fold defaultstate="collapsed" desc="PIC 16F886 Initialization">
#ifdef __16F886
    list    p=16f886        ; list directive to define processor
    #include    <p16f886.inc>       ; processor specific variable definitions
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="PIC 16F1713 Initialization">
#ifdef __16F1713
    list    p=16f1713       ; list directive to define processor
    #include    <p16F1713.inc>
#endif
;</editor-fold>

    errorlevel  -302            ; suppress message 302 from list file

    radix dec