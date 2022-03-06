;**********************************************************************
; Description:
;   Misc macros.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

; Clear multi byte counter
ClearCounter macro CounterLSB, NoOfBytes
    local i = NoOfBytes - 1
#ifdef __16F886
    SetFsr CounterLSB
    clrf    INDF
    while i > 0
    incf    FSR, F
    clrf    INDF
    i -= 1
    endw
#endif
#ifdef __16F1713
    movlw   High CounterLSB
    movwf   FSR0H
    movlw   CounterLSB
    movwf   FSR0L
    clrf    INDF0
    while i > 0
    incf    FSR0, F
    clrf    INDF0
    i -= 1
    endw
#endif
    endm

IncCounter macro CounterLSB, NoOfBytes
    local i = NoOfBytes
    local j = 0
#ifdef __16F886
    SetFsr CounterLSB
    while i > 0
    i -= 1
    j = i * 4 - 1
    incf    INDF, F
    if i == 0
        exitm
    endif
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR, F
    endw
#endif
#ifdef __16F1713
    movlw   High CounterLSB
    movwf   FSR0H
    movlw   CounterLSB
    movwf   FSR0L
    while i > 0
    i -= 1
    j = i * 4 - 1
    incf    INDF0, F
    if i == 0
        exitm
    endif
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR0, F
    endw
#endif
    endm

IncCounterNoIntr macro CounterLSB, NoOfBytes
    local i = NoOfBytes
    local j = 0
#ifdef __16F886
    SetFsr CounterLSB
    bcf     INTCON, GIE
    while i > 0
    i -= 1
    j = i * 4 - 1
    incf    INDF, F
    if i == 0
        bsf     INTCON, GIE
        exitm
    endif
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR, F
    endw
#endif
#ifdef __16F1713
    movlw   High CounterLSB
    movwf   FSR0H
    movlw   CounterLSB
    movwf   FSR0L
    bcf     INTCON, GIE
    while i > 0
    i -= 1
    j = i * 4 - 1
    incf    INDF0, F
    if i == 0
        bsf     INTCON, GIE
        exitm
    endif
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR0, F
    endw
#endif
    bsf     INTCON, GIE
    endm

DecCounter macro CounterLSB, NoOfBytes
    local i = NoOfBytes
    local j = 0
#ifdef __16F886
    SetFsr CounterLSB
    while i > 0
    i -= 1
    j = i * 6 - 3
    decf    INDF, F
    if i == 0
        exitm
    endif
    movfw   INDF
    xorlw   0xff
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR, F
    endw
#endif
#ifdef __16F1713
    movlw   High CounterLSB
    movwf   FSR0H
    movlw   CounterLSB
    movwf   FSR0L
    while i > 0
    i -= 1
    j = i * 6 - 3
    decf    INDF0, F
    if i == 0
        exitm
    endif
    movfw   INDF0
    xorlw   0xff
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR0, F
    endw
#endif
    endm

DecCounterNoIntr macro CounterLSB, NoOfBytes
    local i = NoOfBytes
    local j = 0
#ifdef __16F886
    SetFsr CounterLSB
    bcf     INTCON, GIE
    while i > 0
    i -= 1
    j = i * 6 - 3
    decf    INDF, F
    if i == 0
        bsf     INTCON, GIE
        exitm
    endif
    movfw   INDF
    xorlw   0xff
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR, F
    endw
#endif
#ifdef __16F1713
    movlw   High CounterLSB
    movwf   FSR0H
    movlw   CounterLSB
    movwf   FSR0L
    bcf     INTCON, GIE
    while i > 0
    i -= 1
    j = i * 6 - 3
    decf    INDF0, F
    if i == 0
        bsf     INTCON, GIE
        exitm
    endif
    movfw   INDF0
    xorlw   0xff
    btfss   STATUS, Z
    goto    $ + j
    incf    FSR0, F
    endw
#endif
    bsf     INTCON, GIE
    endm

#ifdef __16F886
; FSR helper macros
SetFsr macro FsrBuffer
;   movlw   HIGH FsrBuffer
;   andlw   0x01
;   btfss   STATUS, Z
;   bsf     STATUS, IRP
;   btfsc   STATUS, Z
;   bcf     STATUS, IRP
    movlw   FsrBuffer
    movwf   FSR                 ; FSR = pointer to buffer
    bankisel    FsrBuffer
    endm

; Set FSR with a litteral offset
SetFsrOfsL macro FsrBuffer, Offset
;   movlw   HIGH FsrBuffer
;   andlw   0x01
;   btfss   STATUS, Z
;   bsf     STATUS, IRP
;   btfsc   STATUS, Z
;   bcf     STATUS, IRP
;   movlw   FsrBuffer
;   movwf   FSR                 ; FSR = pointer to buffer
;   movlw   Offset
;   addwf   FSR, F
;   bankisel    FsrBuffer
    SetFsr  FsrBuffer
    movlw   Offset
    addwf   FSR, F
    endm

; Set FSR with a fileregister offset
SetFsrOfsF macro FsrBuffer, Offset
;   movlw   HIGH FsrBuffer
;   andlw   0x01
;   btfss   STATUS, Z
;   bsf     STATUS, IRP
;   btfsc   STATUS, Z
;   bcf     STATUS, IRP
;   movlw   FsrBuffer
;   addwf   Offset, w
;   movwf   FSR                 ; FSR = pointer to buffer
;   bankisel    FsrBuffer
    SetFsr  FsrBuffer
    movfw   Offset
    addwf   FSR, F
    endm
#endif

