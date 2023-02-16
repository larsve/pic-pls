;**********************************************************************
; Description:
;   Triac forward/reverse control.
;
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "..\..\common\src\mcu_defines.inc"
    #include    "defines.inc"
    #include    "..\..\common\src\constants.inc"
    #include    "..\..\common\src\isr_timer.inc"

    errorlevel  -207            ; suppress message 207 from list file

;***** Global declarations ********************************************
   ; Methods
    GLOBAL  Init_TriacControl
    GLOBAL  Do_TriacControl

    ; Variables
    GLOBAL  TState


;***** Extern declarations ********************************************

    ; From InputOutput.asm
    Extern Output

    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
BaxiData    udata
TState      res 1       ; Triac control states
TStateD     res 1       ; Triac control states D
TriacState  res 1       ; Triac main state (idle, fwd, rev)
TriacSubState   res 1   ; Triac sub state
TriacCounter    res 1   ; Triac delay counter
FwdCnt      res 1       ; Triac Forward counter (in 10ms ticks)
RevCnt      res 1       ; Triac Reverse counter (in 10ms ticks)
TCTemp      res 1       ; Triac Control Temp

;***** Constants ******************************************************

; TriacStates
TS_IDLE     EQU 0x00
TS_REV      EQU 0x01
TS_FWD      EQU 0x02
;TS_STUCK   EQU 0x03

;***** Code Section ***************************************************
PROG1       code

;**********************************************************************
; Init Triac contol
;   Initialize variables.
;**********************************************************************
Init_TriacControl
    banksel TState
    clrf    TState
    clrf    TStateD
    clrf    TriacState
    clrf    TriacSubState
    clrf    TriacCounter
    clrf    FwdCnt
    clrf    RevCnt

    bsf     TState, tcTimeout   ; Use Fwd/Back timeout as default..
    return

;**********************************************************************
; Do triac control
;   React to input changes and set output states.
;**********************************************************************
Do_TriacControl
    ; Start to disable all Triac related output.
    bcf     Output, outTriac
    bcf     Output, outRevRel

    ; Check if input has changed since last time and reset counters if applicable.
    banksel TState
    movfw   TState
    xorwf   TStateD, w
    skpnz
    goto    NoTStateInputChange

    ; "And" the xor result with input to see what changed and is currently set..
    andwf   TState, w
    movwf   TCTemp

    ; Check the bits and reset the counters for the enabled bits..
    movlw   0xff
    btfsc   TCTemp, tcFwd
    movwf   FwdCnt
    btfsc   TCTemp, tcRev
    movwf   RevCnt

    ; Save input
    movfw   TState
    movwf   TStateD
NoTStateInputChange

    ; Check if we should use the timeout counters.
    btfss   TState, tcTimeout
    goto    SkipTcCounters

    ; Check timer if it's time to decrease counters..
    btfss   Timer_Tick, TimerTick_10ms
    goto    SkipTcCounters

    ; Decrease Fwd counter if > 0
    movfw   FwdCnt
    skpz
    decf    FwdCnt, F

    ; Decrease Rev counter if > 0
    movfw   RevCnt
    skpz
    decf    RevCnt, F
SkipTcCounters

    btfsc   Output, outSwRel
    goto    $ + 4
    clrf    TriacState
    clrf    TriacSubState
    return

    ;**********************************************************************
    ; Triac control main states:
    ; 0. Idle
    ; 1. Reverse
    ; 2. Forward
    ;**********************************************************************
    ; Check main state = 0 (idle)
    movfw   TriacState
    skpnz
    goto    TriacIdleMainState

    ; Check main state = 1 (Reverse)
    movfw   TriacState
    xorlw   TS_REV
    skpnz
    goto    TriacReverseMainState

    ; Check main state = 2 (forward)
    movfw   TriacState
    xorlw   TS_FWD
    skpnz
    goto    TriacForwardMainState

    ; Check main state = 3 (stuck)
;   movfw   TriacState
;   xorlw   TS_STUCK
;   skpnz
;   goto    TriacStuckMainState

    ; We should never get here, something is wrong, clear state and return
    clrf    TriacState
    return


;**********************************************************************
; TriacIdleMainState - TriacState 0 = Idle
;   Check if we should switch to Rev or Fwd states. Rev should have
;   priority over Fwd but only as long as RevCnt > 0.
;**********************************************************************
TriacIdleMainState
    ; Clear substate
    clrf    TriacSubState

    ; Check if we should reverse..
    movlw   TS_REV
    btfsc   TState, tcRev       ; We got signal?
    movwf   TriacState
    movfw   RevCnt              ; And have count > 0
    skpnz
    clrf    TriacState          ; Nope, no count, reset value.

    movfw   TriacState          ; Bail if we have set TriacState at this moment..
    skpz
    return

    ; Check if we should run forward..
    movlw   TS_FWD
    btfsc   TState, tcFwd       ; We got signal?
    movwf   TriacState
    movfw   FwdCnt              ; And have count > 0
    skpnz
    clrf    TriacState          ; Nope, no count, reset value.

    return

;**********************************************************************
; TriacReverseMainState - TriacState 1 = Reverse
;   Substates:
;   0. Enable Reverse relay and setup the delay.
;   1. Wait.
;   2. Enable Triac output and wait for tcRev to fall.
;   3. Disable Triacstyrningen and setup the delay.
;   4. Wait.
;   5. Disable the reverse relay, setup the delay.
;   6. Wait.
;   7. Done.
;**********************************************************************
TriacReverseMainState
    ; Check TriacSubState
    movlp   TRIAC_REV_JUMP_TABLE
    movfw   TriacSubState
    andlw   0x07
    addlw   TRIAC_REV_JUMP_TABLE
    btfsc   STATUS, C
    incf    PCLATH, F
    movwf   PCL
TRIAC_REV_JUMP_TABLE
    goto    TriacRevSubstate00  ; TriacSubstate = 0x00
    goto    TriacRevSubstate01  ; TriacSubstate = 0x01
    goto    TriacRevSubstate02  ; TriacSubstate = 0x02
    goto    TriacRevSubstate03  ; TriacSubstate = 0x03
    goto    TriacRevSubstate04  ; TriacSubstate = 0x04
    goto    TriacRevSubstate05  ; TriacSubstate = 0x05
    goto    TriacRevSubstate06  ; TriacSubstate = 0x06
    goto    TriacRevSubstate07  ; TriacSubstate = 0x07

    ; We should never get here, but in case we do...
    clrf    TriacState
    clrf    TriacSubState
    return

TriacRevSubstate00              ; Substate 0 = Enable Reverse relay and setup the delay.
    bsf     Output, outRevRel   ; Enable Reverse relay
    movlw   .10                 ; wait 100ms
    movwf   TriacCounter
    incf    TriacSubState, F
    return

TriacRevSubstate01              ; Substate 1 = Wait.
    bsf     Output, outRevRel   ; Enable Reverse relay
    btfsc   TState, tcRev
    goto    TriacDelay          ; and wait as long as we still have tcRev
    movlw   .5                  ; Move to substate 5 if tcRev falls before timeout expires..
    movwf   TriacSubState
    return

TriacRevSubstate02              ; Substate 2 = Enable Triac output and wait for tcRev to fall.
    bsf     Output, outRevRel   ; Enable Reverse relay
    bsf     Output, outTriac    ; Enable Triac output
    movfw   RevCnt              ; Check that RevCnt hasn't reached zero..
    skpnz
    goto    $ + 3
    btfsc   TState, tcRev       ; Check tcRev, and inc substate if it's false
    return
    incf    TriacSubState, F
    return

TriacRevSubstate03              ; Substate 3 = Disable Triac output and setup the delay.
    bsf     Output, outRevRel   ; Enable Reverse relay only
    movlw   .10                 ; wait 100ms
    movwf   TriacCounter
    incf    TriacSubState, F
    return

TriacRevSubstate04              ; Substate 4 = Wait.
    bsf     Output, outRevRel   ; Enable Reverse relay only
    movfw   RevCnt              ; and wait, but move to substate 1 if tcRev is
    skpnz                       ; set and RevCnt > 0
    goto    TriacDelay
    btfss   TState, tcRev
    goto    TriacDelay
    movlw   .1
    movwf   TriacSubState
    return

TriacRevSubstate05              ; Substate 5 = Disable the reverse relay, setup the delay.
    movlw   .10                 ; wait 100ms
    movwf   TriacCounter
    incf    TriacSubState, F
    return

TriacRevSubstate06              ; Substate 6 = Wait.
    goto    TriacDelay

TriacRevSubstate07              ; Substate 7 = Done.
    clrf    TriacState          ; Clear TriacState to revert back to the idle main state
    clrf    TriacSubState
    return

;**********************************************************************
; TriacForwardMainState - TriacState 2 = Forward
;   Substates:
;   0. Enable Triac output and wait for tcFwd to fall.
;   1. Setup delay.
;   2. Wait.
;   3. Done.
;**********************************************************************
TriacForwardMainState
    ; Check TriacSubState
    movlp   TRIAC_FWD_JUMP_TABLE
    movfw   TriacSubState
    andlw   0x03
    addlw   TRIAC_FWD_JUMP_TABLE
    btfsc   STATUS, C
    incf    PCLATH, F
    movwf   PCL
TRIAC_FWD_JUMP_TABLE
    goto    TriacFwdSubstate00  ; TriacSubstate = 0x00
    goto    TriacFwdSubstate01  ; TriacSubstate = 0x01
    goto    TriacFwdSubstate02  ; TriacSubstate = 0x02
    goto    TriacFwdSubstate03  ; TriacSubstate = 0x03

    ; We should never get here, but in case we do...
    clrf    TriacState
    clrf    TriacSubState
    return

TriacFwdSubstate00              ; Substate 0 = Enable Triac output and wait for tcFwd to fall.
    bsf     Output, outTriac    ; Enable Triac output
    movfw   FwdCnt              ; Check FwdCnt counter, and inc substate if zero
    skpnz
    goto    $ + 3
    btfsc   TState, tcFwd       ; Check tcFwd, and inc substate if it's false
    return
    bcf     Output, outTriac    ; Clear Triac output
    incf    TriacSubState, F    ; Inc substate
    return

TriacFwdSubstate01              ; Substate 1 = Setup delay.
    movlw   .10                 ; wait 100ms
    movwf   TriacCounter
    incf    TriacSubState, F
    return

TriacFwdSubstate02              ; Substate 2 = Wait.
    goto    TriacDelay

TriacFwdSubstate03              ; Substate 3 = Done.
    clrf    TriacState          ; Clear TriacState to revert back to the idle main state
    clrf    TriacSubState
    return

;**********************************************************************
; TriacDelay
;   Decrease TriacDely each 10ms and inc substate when it reaches zero.
;**********************************************************************
TriacDelay
    btfss   Timer_Tick, TimerTick_10ms
    return
    decfsz  TriacCounter, F
    return
    incf    TriacSubState, F    ; Delay has reached zero, inc substate..
    return

;**********************************************************************
; TriacStuckMainState - TriacState 3 = Stuck
;   Substates:
;**********************************************************************
;TriacStuckMainState
;    return

    END
