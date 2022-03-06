;**********************************************************************
; Description:
;   Timer/timing module, used to keep (relative) track of time. Uses
;   the 16-bit Timer1 timer to generate 1ms, 10ms, 100ms, 1s and 10s
;   ticks.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "mcu_defines.inc"
    #include    "defines.inc"
    #include    "isr_timer.inc"

;***** Global declarations ********************************************
    ; Methods
    GLOBAL  ISR_Timer
    GLOBAL  Init_Timer
    GLOBAL  Do_Timer

    ; Variables
    GLOBAL  Timer_Tick

;***** Variables ******************************************************

; Allocate RAM addresses in unbanked memory
Shared_Data udata_shr
Timer_Tick  res 1

; Allocate RAM addresses in bank0
TimerData   udata
ISRTick     res 1
TT10        res 1
TT100       res 1
TT1000      res 1
TT10000     res 1

; Timer preload values (might need to be adjusted if code in ISR_Timer is updated)
;<editor-fold defaultstate="collapsed" desc="PIC16F886">
#ifdef __16F886
#if OSC == 20
TCntHi      EQU 0xec    ; ec80 = 1.000000ms @ 20MHz
TCntLo      EQU 0x80
#endif
#if OSC == 8
TCntHi      EQU 0xf8    ; f838 = 1.000000ms @ 8MHz
TCntLo      EQU 0x38
#endif
#if OSC == 4
TCntHi      EQU 0xfc    ; fc20 = 1.000000ms @ 4MHz
TCntLo      EQU 0x20
#endif
#endif
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PIC16F1713">
#ifdef __16F1713
#if OSC == 32
TCntHi      EQU 0xe0    ; 0xe0c8 ? 0.999999ms @ 32MHz (on average)
TCntLo      EQU 0xc8    ; jitter ? ±9µs on TimerTick_1ms (idle)
#endif
#if OSC == 16
TCntHi      EQU 0xf0    ; 0xf068 ? 1.000001ms @ 16MHz (on average)
TCntLo      EQU 0x68    ; jitter ? ±12µs on TimerTick_1ms (idle)
#endif
#if OSC == 8
TCntHi      EQU 0xf8    ; 0xf838 ? 1.000002ms @ 8MHz (on average)
TCntLo      EQU 0x38    ; jitter ? ±26µs on TimerTick_1ms (idle)
#endif
#if OSC == 4
TCntHi      EQU 0xfc    ; 0xfc20 ? 0.999999ms @ 4MHz (on average)
TCntLo      EQU 0x20    ; jitter ? ±60µs on TimerTick_1ms (idle)
#endif
#if OSC == 2
TCntHi      EQU 0xfe    ; 0xfe15 ? 0.999623ms @ 2MHz (on average)
TCntLo      EQU 0x15    ; jitter ? -126µs to +46µs on TimerTick_1ms (idle)
#endif
#if OSC == 1
TCntHi      EQU 0xff    ; 0xff0f ? 1.001320ms @ 1MHz (on average)
TCntLo      EQU 0x0f    ; jitter ? -372µs to +504µs on TimerTick_1ms (idle)
#endif
#endif
;</editor-fold>

;***** Code Section ***************************************************
PROG0       code

;**********************************************************************
; ISR Timer
;   Interrupt Service Routine for timer.
;**********************************************************************
ISR_Timer
    banksel PIR1
    btfss   PIR1, TMR1IF
    return  ; Not a timer interrupt

    bcf     T1CON, TMR1ON   ; Stop timer
    bcf     PIR1, TMR1IF    ; Clear Interrupt flag

    ; Reload Timer
    movlw   TCntHi
    movwf   TMR1H
    movlw   TCntLo
    addwf   TMR1L, F
    btfsc   STATUS, C
    incf    TMR1H, F

    bsf     T1CON, TMR1ON   ; Start timer

    banksel ISRTick
    bsf     ISRTick, 0x01
    return

;**********************************************************************
; Init Timer
;   Initializes Timer/Interrupt control
;**********************************************************************
Init_Timer

    banksel ISRTick
    clrf    Timer_Tick
    clrf    ISRTick

    ; Init 10ms, 100ms, 1s, 10s counters
    movlw   0x0a
    movwf   TT10
    movwf   TT100
    movwf   TT1000
    movwf   TT10000

    banksel INTCON
    bcf     INTCON, GIE     ; Disable interrupts
    bsf     INTCON, PEIE    ; Must be enabled to get a timer interrupt
    clrf    T1CON           ; Clear Timer 1 register
                            ; = No prescaler
                            ; = Osc input disabled
                            ; = Sync external clock (not in use when we use internal klock)
                            ; = Internal clock (Fosc/4)
                            ; = Timer stopped
    ; Set timer start value
    movlw   TCntHi
    movwf   TMR1H
    movlw   TCntLo
    movwf   TMR1L

    bcf     PIR1, TMR1IF    ; Clear timer 1 interupt occured flag

    banksel PIE1
    bsf     PIE1, TMR1IE    ; Enable timer 1 overflow interrupt enable flag

;   bsf     T1CON, TMR1ON   ; Start timer
;   bsf     INTCON, GIE     ; Enable interrupts
    return

;**********************************************************************
; Do Timer
;   Gets called once for each program loop
;**********************************************************************
Do_Timer
    banksel T1CON
    btfsc   T1CON, TMR1ON   ; Has timer been started yet?
    goto    Checkticks      ; Yes, check if it's wrapped

    bcf     PIR1, TMR1IF    ; Clear timer 1 interupt occured flag
    bsf     T1CON, TMR1ON   ; Start timer
    bsf     INTCON, PEIE    ; Must be enabled to get a timer interrupt
    bsf     INTCON, GIE     ; Enable interrupts

Checkticks
    banksel ISRTick

    clrf    Timer_Tick

    btfss   ISRTick, 0x01
    return
    bcf     ISRTick, 0x01

    bsf     Timer_Tick, TimerTick_1ms

    decfsz  TT10, F
    return

    movlw   0x0a
    movwf   TT10
    bsf     Timer_Tick, TimerTick_10ms

    decfsz  TT100, F
    return

    movlw   0x0a
    movwf   TT100
    bsf     Timer_Tick, TimerTick_100ms

    decfsz  TT1000, F
    return

    movlw   0x0a
    movwf   TT1000
    bsf     Timer_Tick, TimerTick_1000ms

    decfsz  TT10000, F
    return

    movlw   0x0a
    movwf   TT10000
    bsf     Timer_Tick, TimerTick_10000ms
    return

    END
