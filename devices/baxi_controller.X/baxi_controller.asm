;**********************************************************************
; Description:
;	Main logic, this should be the router or switch that monitors and
;	controls the other parts and make them work with each other.
;	Note. The A/D part should be moved to a separate unit.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include	"..\..\common\src\mcu_defines.inc"
    #include	"defines.inc"
    #include	"..\..\common\src\adc.inc"
    #include	"..\..\common\src\constants.inc"
    #include	"..\..\common\src\i2c.inc"
    #include	"..\..\common\src\input_output.inc"
    #include	"..\..\common\src\isr_timer.inc"
    #include	"..\..\common\src\macros.inc"

    errorlevel  -207			; suppress message 207 from list file

;***** Global declarations ********************************************

	; Methods
	GLOBAL	Init_CLogic
	GLOBAL  Do_CLogic
	
	; Variables
	GLOBAL	Alarms
	GLOBAL	RState
	GLOBAL	Inmatningar
    GLOBAL  Backningar
	GLOBAL	InmatTmActive
	GLOBAL	InmatTmIdle
	GLOBAL	SkruvPulser
	GLOBAL	MaxChn
	GLOBAL	LastInTime
	GLOBAL	PiIdleTm
	GLOBAL	PiActTm
	GLOBAL	PiRevTm
	GLOBAL	BDTemp


;***** Extern declarations ********************************************

	; From ADC.asm
	Extern AdcState
	Extern ANchn
	Extern ExhaustTemp      ; AN18
	Extern IrSignal         ; AN19
	Extern OCLimitL         ; AN4
	Extern OCLimitH         ; AN13
	Extern OCSignal         ; AN10
	Extern WaterTemp        ; AN12

	; From InputOutput.asm
	Extern Input
	Extern InputD
	Extern Output

	; From ISR_Timer.asm
	Extern Timer_Tick

    ; From I2C_*.asm
	Extern RxPtr
	Extern I2cRxBuf
    Extern I2C_State

	; From TriacControl.asm
	Extern Init_TriacControl
	Extern Do_TriacControl
	Extern TState               ; TriacStates = tcFwd, tcRev, tcTimeout

;***** Variables ******************************************************
BaxiData		udata
BState			res 1		; Baxi controller states
RState			res 1		; Baxi Run States
DState			res 1		; Desired Run State
AState			res 1		; Alarm states
Alarms          res 1       ; Active alarms
AlarmTemp		res 1		; ADC alarm temperature
MagAlarmCnt		res 1		; Flismagasin alarm fördröjnings räknare
BaxiRunTmr      res 1       ; Baxi input signal timer
SwRelCount		res 1		; Baxi/PIC pre-switch relay counter
SwRelPostCount	res 1		; Baxi/PIC post-switch relay counter
BDTemp          res 1       ; Temp variable in 'BaxiData' block
		
; Ström övervakning
MaxChn			res 1		; Max value of AN10 / RB1 / ANchn #7
OvrCurrTO		res 1		; Overcurrent protection timeout
SampleDelayTO	res 1		; Sample delay timeout

; Triac AutoRev styrning
RetryDelay		res 1		; Triac delay counter
RetryState		res 1		; Huvud state för triac AutoRev styrningen
RetryCount		res 1		; No of times to retry reversing
MaxCurrCount	res 1		; No of timea to retry with max current

; Alarms
MuteAlarmCnt	res 1		; Counter to mute alarms
;RevAlarmCnt	res 1		; Counter to hold alarm active after each reversering.
NoInpCnt		res 1		; No input alarm delay counter

Inmatningar		res 4		; Antal inmatningar
Backningar      res 4       ; Antal automatiska backningar
SkruvPulser		res 4		; Antal skruvpulser
InmatTmr		res 2		; Inmatningstids timer (100ms ticks)
InmatTmActive	res 2		; Inmatningstid 1 (inmatning)
InmatTmIdle		res 2		; Inmatningstid 2 (uppehåll)
CurPwrTmr		res 1		; Timer för styrning av spänning till strömmätarna.

; Baxi inmatning
InTimeCnt		res 1		; Input time counter
CurInTime		res 1		; Current input time (measured in "pulses" @ 192ms)
LastInTime		res 1		; Last input time (measured in "pulses" @ 192ms)
		
; RPi inmatning
PiState			res 1		; Pi timing state
PiCnt			res	2		; Pi sub-state counter
LastRPiTm		res 1		; Counter is reset to 255 when RPi updates timings, switch to Baxi signals when counter reaches zero
PiIdleTm		res 2		; Idle time in 100ms ticks, must be > PiActTm. 0-6553.5s
PiActTm			res 1		; Active time in 100ms ticks (0.1-25.5s). 0 = disable
PiRevTm			res 1		; Reverse time in 100ms ticks (0.1-25.5s). 0 = disable
PiRevInterleave	res	1		; Reverse interleave, 1 = reverse after every input.

; "Shared" temp variables..
Temp_Data	udata_ovr	0x6e
Temp		res 1
;ISRTemp		res 1

;***** Constants ******************************************************
; BaxiController Logic State bits and other constants 

; Baxi State bits
;BS_Running		EQU 0x00		; If we have signal from Baxi
BS_OvrCurr		EQU	0x01		; Over Current protection tripped
BS_SwitchRel	EQU 0x02		; Baxi/Triac switch relay (0 = Baxi, 1 = Triac)
BS_MagIrDiod	EQU 0x03		; Flismagasin IR diod (1 = lys)
;BS_RevRelay	EQU 0x04		; Enable reverse relay?
BS_OCH       	EQU 0x05		; OCSignal > OCLimitH
BS_OCL       	EQU 0x06		; OCSignal > OCLimitL
BS_Trig    		EQU 0x07		; OCSignal > TrigLevel

; Baxi Run State bits
RS_Running		EQU 0x00		; Baxi is running (we get a run forward signal from baxi)
RS_BaxiK		EQU 0x01		; Baxi (native)
RS_BaxiT		EQU 0x02		; Baxi source with PIC/Triac control
RS_PIC			EQU 0x03		; PIC/Triac control with timings from master (PC/raspberry PI)
RS_Stuck		EQU 0x04		; Stuck (baxi can only reverse)
RS_AutoRev		EQU 0x05		; Auto reverse active
RS_Rev			EQU 0x06		; Reverse
RS_Fwd			EQU 0x07		; Forward

; Alarm states
AS_MagAlarm		EQU 0x00		; Flismagasin låg nivå alarm
AS_TempAlarm	EQU 0x01		; Temp alarm (rökgas + vatten ut)
AS_NoInpAlarm	EQU 0x02		; Baxi alarm (Ingen inmatning)
;AS_StuckAlarm	EQU 0x03		; Baxi alarm (Fastnat)
;AS_RevAlarm	EQU 0x04		; Baxi alarm (Reverserar)

; Constants
MagAlarmDef		EQU 0xff		; Default timeout for Mag Alarm in seconds
NoInpCntDef		EQU 255         ; Number of seconds after last signal, before the alarm is triggerd.
SkruvMotorBrDef	EQU 50			; Time in 10ms ticks before we break power if we havent got any pulse
DefRetryCount	EQU .3			; Number of times to retry if we get stuck
DefMaxCurrCount	EQU .3			; Number of times to retry with max current before disable triac
	
OvrCurrTm1		EQU 60			; Overcurrent time in 10ms ticks (Normal)
OvrCurrTm2		EQU 80          ; Overcurrent time in 10ms ticks (Reverse retry)
SampleDelayTm	EQU 50			; Sample delay in 10ms ticks

;***** Code Section ***************************************************
PROG1		code

;**********************************************************************
; Init CLogic
;   Initializes variables and read default values from EEprom.
;**********************************************************************
Init_CLogic
	; BaxiController Init 
    banksel BState
    clrf    BState
	clrf	RState
	clrf	DState
	clrf	AState
    clrf	Alarms
    clrf	AlarmTemp
	clrf	MagAlarmCnt
    clrf    BaxiRunTmr
	clrf	CurPwrTmr
	clrf	InTimeCnt
	clrf	CurInTime
	clrf	LastInTime
	clrf	SwRelPostCount
	clrf	PiState
	clrf	LastRPiTm
	clrf	PiActTm
	clrf	PiRevTm
	clrf	PiRevInterleave
	
	movlw	0xff
	movwf	SwRelCount
	
    ; Ström övervakning
	clrf	MaxChn
	clrf	OvrCurrTO		; Overcurrent protection timeout
	clrf	SampleDelayTO	; Sample delay timeout

    ; Triac styrning
	clrf	RetryDelay
	clrf	RetryState		; Huvud state för triac styrningen
	clrf	RetryCount
	clrf	MaxCurrCount
	
    ; Alarms
	clrf	MuteAlarmCnt
	clrf	NoInpCnt
    
    ; Misc counters
	ClearCounter	Inmatningar, 4	; Antal inmatningar
    ClearCounter    Backningar, 4   ; Antal automatiska backningar
	ClearCounter	SkruvPulser, 4	; Antal skruvpulser
	ClearCounter	InmatTmr, 2		; Inmatningstids timer (100ms ticks)
	ClearCounter	InmatTmActive, 2; Inmatningstid 1 (inmatning)
	ClearCounter	InmatTmIdle, 2	; Inmatningstid 2 (uppehåll)
	ClearCounter	PiIdleTm,2		; Idle time in 100ms ticks, must be > PiActTm. 0-6553.5s

	; Setup default Baxi Run state
	clrf	RState
	bsf		RState, RS_BaxiT	; Use signal from Baxi, but we control the triac Fwd/Rev
	bsf		DState, RS_BaxiT
	
	#if BaxiNo == .1
    movlw   .204					; Baxi1 Alarm temp, dec 204 = approx 4V = approx 100 degrees Celcius 
	#else
    movlw   .212					; Baxi2 Alarm temp, dec 212 = approx 4V = approx 100 degrees Celcius 
	#endif
    movwf   AlarmTemp
    
	; Defaultvärde för flismagasin alrams räknare
	movlw	MagAlarmDef
	movwf	MagAlarmCnt

    call    Init_TriacControl   ; Init TriacControl logic

#ifdef __DEBUG
	banksel RxPtr
    movlw   High I2cRxBuf
    movwf   FSR0H
    movlw   I2cRxBuf
    movwf   FSR0L

    ; 1x - Set status
    movlw   0x01
    movwi   FSR0++
    movlw   0x08
    movwi   FSR0++

    ; 2xxxxx - Set timings
    movlw   0x02
    movwi   FSR0++
    movlw	0x01
    movwi   FSR0++
    movlw	0x00
    movwi   FSR0++
    movlw	0x01
    movwi   FSR0++
    movlw	0x01
    movwi   FSR0++
    movlw	0x01
    movwi   FSR0++

    ; Set size of the buffer...
    movlw   .8                 ; 2, 8
    movwf   RxPtr

#endif
	return

;**********************************************************************
; Do Logic
;   React to input changes and set output states.
;**********************************************************************
Do_CLogic
	call	Do_ProcessRxBuffer			; Process commands
	call	Do_DecreaseLastRPiTm		; Decrese LastRPiTm if > 0
	call	Do_UpdateBaxiRunStates		; Update RState:RS_* flags..
	call	Do_BaxiInTime				; Update CurInTime/LastInTime
	call	Do_CheckBaxiInput
    call    Do_FlisMagasinAlarm
	call	Do_TempAlarm
	call	Do_CheckNoInpAlarm
	call	Do_CountSkruvPulser
	call	Do_MaxCurrentDetection
	call	Do_TriacLogic				; Handle fwd/rev and auto rev high level triac control
	call	Do_TriacControl				; Handle triac low level control
	call	Do_SwitchRelay
    call	Do_CurPwr					; Handle current sensor power control (uses TState/Do_TriacLogic)

	; Set Output states
    banksel AState
    clrf    BDTemp
	btfsc	AState, AS_TempAlarm
	bsf		BDTemp, lrmTempAlarm
	
	movfw	MagAlarmCnt				; Check if MagAlarm counter > 0
	skpnz
	bsf		BDTemp, lrmMagAlarm		; Yes, set external alarm bit
	
	btfsc	RState, RS_AutoRev
	bsf		BDTemp, lrmReversing
	
	btfsc	RState, RS_Stuck
	bsf		BDTemp, lrmStuck

	; Check if we should mute alarms..
	movfw	MuteAlarmCnt
	skpz
	goto $ + 5
	bcf		BDTemp, lrmTempAlarm
	bcf		BDTemp, lrmMagAlarm
	bcf		BDTemp, lrmReversing
	bcf		BDTemp, lrmStuck

	; Check the NoInpAlarm
	btfsc	AState, AS_NoInpAlarm
	bsf		BDTemp, lrmNoInput
    
    movfw   BDTemp
    movwf   Alarms

	bcf		Output, outMagIrDiod
	btfsc	BState, BS_MagIrDiod
	bsf		Output, outMagIrDiod
	
	; Current sensor power.
	bcf		Output, outCurPwr
	movfw	CurPwrTmr
	skpz
	bsf		Output, outCurPwr
	return

;<editor-fold defaultstate="collapsed" desc="Do_BaxiInTime (CurInTime/LastInTime)">
;**********************************************************************
; Do_BaxiInTime
;	Handle control of Baxi/PIC switch relay. Check that we haven't had
;	any input for a period (2550ms) before we change the status of the
;	relay. 
;**********************************************************************
Do_BaxiInTime
	; Set LastInTime if we just lost signal
	btfss	InputD, inBaxiFwd
	goto	$ + 5
	btfsc	Input, inBaxiFwd
	goto	$ + 3
	movfw	CurInTime
	movwf	LastInTime

	; Handle CurInTime/LastInTime values..
	btfss	Input, inBaxiFwd	; Check if we have signal from Baxi
	return						; No, bail
	
	; Reset counter if we just got signal..
	movlw	.192
	btfss	InputD, inBaxiFwd
	movwf	InTimeCnt
	
	; Also reset CurInTime if we just got signal..
	btfss	InputD, inBaxiFwd
	clrf	CurInTime

	; Check if it's time to decrease counter yet..
	btfss	Timer_Tick, TimerTick_1ms
	return
	
	decfsz	InTimeCnt, f
	return

	; Timer reached zero, inc CurInTime and reset timer...
	incf	CurInTime, f
	movlw	.192
	movwf	InTimeCnt
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_CheckBaxiInput">
;**********************************************************************
; Do_CheckBaxiInput
;   Check/handle "Inmatnigar" counter, and also keep track of 
;	active/idle time for each state, also measure how long input we
;	have from Baxi and update CurInTime/LastInTime.
;**********************************************************************
Do_CheckBaxiInput
    banksel BState
    ; Decrease MuteAlarmCnt if RS_Running flag is cleared...
	movlw	0xff
	btfsc	RState, RS_Running  ; Reset MuteAlarmCnt as long 
	movwf	MuteAlarmCnt        ; as RS_Running is set.
	btfss	Timer_Tick, TimerTick_1000ms
	goto    $ + 4
	movfw	MuteAlarmCnt        ; Decrease counter as long 
	skpz                        ; as it's > 0
	decf	MuteAlarmCnt, F
    
    ; Increase "Inmatningar" counter for each new pulse on inBaxi...
	banksel	Inmatningar
	btfss	InputD, inBaxiFwd
	goto	SkipIncOfInmatningar
	btfss	Input, inBaxiFwd
	goto	SkipIncOfInmatningar
	IncCounterNoIntr	Inmatningar, 4
SkipIncOfInmatningar

	; Check if inBaxi have changed and set the switch
	btfss	InputD, inBaxiFwd
	goto	SkipInmatTmrReset
	btfsc	Input, inBaxiFwd
	goto	SetInmatTmIdle

	; Set InmatTmActive = InmatTmr, and clear InmatTmr = 0
    bcf     INTCON, GIE
	movfw	InmatTmr
	movwf	InmatTmActive
	movfw	InmatTmr + 1
	movwf	InmatTmActive + 1
    bsf     INTCON, GIE
	goto	ResetInmatTmr
SetInmatTmIdle
	; Set InmatTmIdle = InmatTmr, and clear InmatTmr = 0
    bcf     INTCON, GIE
	movfw	InmatTmr
	movwf	InmatTmIdle
	movfw	InmatTmr + 1
	movwf	InmatTmIdle + 1
    bsf     INTCON, GIE
ResetInmatTmr
	ClearCounter	InmatTmr, 2
SkipInmatTmrReset

	; Check if it's time to update InmatTmr
	btfss	Timer_Tick, TimerTick_100ms
	return

	; Check if the counter would overflow
	movlw   High InmatTmr
    movwf   FSR0H
    movlw   InmatTmr
    movwf   FSR0L
    moviw   FSR0++
    andwf   INDF0, w
	xorlw	0xff
	skpnz
	return
	IncCounter	InmatTmr, 2

	btfsc	Input, inBaxiFwd	; If the idle timer is counting, update the old value if InmatTmr > InmatTmIdle
	return
	
	movfw	InmatTmr + 1		; Check MSB
	subwf	InmatTmIdle + 1, w
	skpc
	goto	$ + 9				; High InmatTmr > High InmatTmIdle, update counter...
	movfw	InmatTmIdle + 1
	subwf	InmatTmr + 1, w
	skpc
	return
	movfw	InmatTmIdle
	subwf	InmatTmr, w
	skpc
	return
	movfw	InmatTmr			; InmatTmr > InmatTmIdle, update InmatTmIdle value.
	movwf	InmatTmIdle
	movfw	InmatTmr + 1
	movwf	InmatTmIdle + 1
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_CheckNoInpAlarm">
;**********************************************************************
; Do_CheckNoInpAlarm
;   Check/handle No Input alarm status
;**********************************************************************
Do_CheckNoInpAlarm
    banksel AState
	; Clear alarm
	bcf		AState, AS_NoInpAlarm

	; Check if we should reset alarm counter
	movlw	NoInpCntDef
	btfsc	InputD, inPgSkruv	; Have inPgSkruv changed?
	movwf	NoInpCnt			; Yes, reset counter

	; Check if counter > 0 and if it's time to decrease counter
	movfw	NoInpCnt
	skpnz
	goto	$ + 4				; NoInpCnt = 0, skip counter decrease
	btfsc	Timer_Tick, TimerTick_1000ms
	decfsz	NoInpCnt, f
	return

	; NoInpCnt = 0, check temperature before we set the alarm bit..
	movfw	AlarmTemp			; ExhaustTemp ADC decreased by increasing temperature
	subwf	ExhaustTemp, w		; C = 0 if W > f  (AlarmTemp (100 grader) > ExhaustTemp)
	skpc						; C = 1 if W <= f (AlarmTemp (100 grader) <= ExhaustTemp)
	return

	bsf		AState, AS_NoInpAlarm
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_CountSkruvPulser">
;**********************************************************************
; Do_CountSkruvPulser
;	Check inPgSkruv, and increase counter for each change (if not 
;	reversing, then we'll decrease the counter).
;**********************************************************************
Do_CountSkruvPulser
	; Check inPgSkruv..
	banksel	SkruvPulser
	btfss	InputD, inPgSkruv
	return
	btfsc	Output, outRevRel
	goto	DecSkruvPulserCounter
	IncCounterNoIntr	SkruvPulser, 4
	return
DecSkruvPulserCounter
	DecCounterNoIntr	SkruvPulser, 4
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_CurPwr">
;**********************************************************************
; Do_CurPwr
;	Check inPgSkruv, and increase counter for each change (if not 
;	reversing, then we'll decrease the counter).
;**********************************************************************
Do_CurPwr
	banksel	TState

	; Check if we should reset timer
	movlw	.50					; 5 seconds
	btfsc	TState, tcFwd
	movwf	CurPwrTmr
	btfsc	TState, tcRev
	movwf	CurPwrTmr
	
	; Check if timer > 0
	movfw	CurPwrTmr
	skpnz
	return
	
	; Check if it's time to decrease timer
	btfsc	Timer_Tick, TimerTick_100ms
	decf	CurPwrTmr, f
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_FlisMagasinAlarm">
;**********************************************************************
; Do_DecreaseLastRPiTm
;	Check if LastRPiTm > 0 and it's time to decrese it. LastRPiTm is 
;	set when new timings is received.
;**********************************************************************
Do_DecreaseLastRPiTm
	banksel LastRPiTm
	movfw	LastRPiTm
	skpnz
	return
	
	btfss	Timer_Tick, TimerTick_1000ms
	return
	
	decf	LastRPiTm, f
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_FlisMagasinAlarm">
;**********************************************************************
; Do_FlisMagasinAlarm
;	Check IR-input and set/reset alarm, also control when we should
;	enable IR-output.
;**********************************************************************
Do_FlisMagasinAlarm
	; Check if AN19 is next
    banksel BState
	bcf		BState, BS_MagIrDiod
    banksel ANchn
	movfw	ANchn				; Check if next channel to be converted
	xorlw	0x10				; is channel 0x10 (flismagasin ir receiver)
    banksel BState
	skpnz
	bsf		BState, BS_MagIrDiod
	
    ; Check if there is a new ADC value available
    banksel AdcState
	btfss	AdcState, adcDone
	goto	NoNewFmaAdc

	; Check level and set alarm on/off accordingly
    banksel AState
    bcf		AState, AS_MagAlarm
	movlw	154                 ; 154 dec is just above 3V (VCC = 5.0V)
	subwf	IrSignal, w         ; C = 0 if W > f (154 > ADC)
	skpc
	bsf		AState, AS_MagAlarm	; ADC < 3V, set alarm bit

    ; Reset MagAlarm counter to default timeout value?
	movlw	MagAlarmDef
    btfss   AState, AS_MagAlarm
	movwf	MagAlarmCnt
    
NoNewFmaAdc
    ; Decrease Alarm delay counter if alarm is active..
    btfss	Timer_Tick, TimerTick_1000ms
	return

	banksel AState
	btfss	AState, AS_MagAlarm	; Is MagAlarm triggerd?
	return						; No
	movfw	MagAlarmCnt			; Yes
	btfsc	STATUS, Z			; Check if counter > 0
	return						; No, counter = 0, return
	decf	MagAlarmCnt, F		; Dec alarm counter
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_ProcessRxBuffer">
;**********************************************************************
; Do_ProcessRxBuffer
;   Check if there is anything in the Rx buffer and process that.
;**********************************************************************
Do_ProcessRxBuffer
    banksel I2C_State
    btfsc   I2C_State, i2cBusy
    return
    
    banksel RxPtr
    movfw   RxPtr
    skpnz
    return						; RxPrt = 0, nothing new to process

    ; Use Temp as pointer to the buffer and compare that to RxPtr so we know how long the buffer is
    clrf    Temp
    movlw   High I2cRxBuf
    movwf   FSR0H
    movlw   I2cRxBuf
    movwf   FSR0L
ProcessLoop
    ; Read command byte...
    ; 1X						; Set drive mode
    movfw   INDF0
    xorlw   0x01
    skpnz
    goto    SetDriveMode
    
    ; 2XXXXX					; Set timings
    movfw   INDF0
    xorlw   0x02
    skpnz
    goto    SetTimings
    
    ; ? - Unknown command
    clrf    RxPtr
    return
    
    ;<editor-fold defaultstate="collapsed" desc="1X - SetDriveMode">
SetDriveMode
    ; 1X						; Set drive mode
    ; Check that we have at least 2 bytes in buffer..
    movfw   Temp
    addlw   0x02
    subwf   RxPtr, w
    skpc
    return

    ; Set DState/Drive Mode register.
    incf    FSR0L, f
    moviw   FSR0++
	banksel DState
	movwf	DState
	
    ; Inc Temp pointer and check if we should loop or exit
    banksel	RxPtr
    movfw   Temp
    addlw   0x02                ; Command + status bytes
    movwf   Temp
    movfw   RxPtr
    subwf   Temp, w
    skpc
    goto    ProcessLoop
    clrf    RxPtr
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="2XXXXX - SetTimings">
SetTimings
    ; 2XXXXX					; Set status (inc/dec altitude/azimuth)
    ; Check that we have at least 6 bytes in buffer..
    movfw   Temp
    addlw   0x06
    subwf   RxPtr, w
    skpc
    return
    
    ; Move buffer bytes to flags.
	banksel	PiIdleTm
    incf    FSR0L, f
    moviw   FSR0++
    movwf   PiIdleTm
    moviw   FSR0++
    movwf   PiIdleTm + 1
    moviw   FSR0++
    movwf   PiActTm
    moviw   FSR0++
    movwf   PiRevTm
    moviw   FSR0++
    movwf   PiRevInterleave
    
    ; Reset LastRPiTm
    movlw   0xff
    movwf   LastRPiTm

    ; Inc Temp pointer and check if we should loop or exit
	banksel	RxPtr
    movfw   Temp
    addlw   0x06                ; Command + status bytes
    movwf   Temp
    movfw   RxPtr
    subwf   Temp, w
    skpc
    goto    ProcessLoop
    clrf    RxPtr
    return
;</editor-fold>
    
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_SwitchRelay (switch between BAXI and PIC)">
;**********************************************************************
; Do_SwitchRelay
;	Handle control of Baxi/PIC switch relay. Check that we haven't had
;	any input for a period (2550ms) before we change the status of the
;	relay. 
;**********************************************************************
Do_SwitchRelay
	banksel	RState
	; Dec SwRelPostCount?
	movfw	SwRelPostCount
	skpnz
	goto	$ + 4
	btfss	Timer_Tick, TimerTick_10ms
	goto	$ + 2
	decf	SwRelPostCount, f
	
	; Reset counter if we have any signal from Baxi or if we control the triac
	movlw	0xff
	btfsc	Input, inBaxiFwd	; Baxi Fwd
	movwf	SwRelCount
	btfsc	Input, inBaxiRev	; Baxi Rev
	movwf	SwRelCount
	btfsc	TState, tcFwd		; Triac Fwd
	movwf	SwRelCount
	btfsc	TState, tcRev		; Triac Rev
	movwf	SwRelCount
	
	; Dec counter?
	movfw	SwRelCount
	skpnz
	goto	$ + 5				; No, it's already zero..
	btfss	Timer_Tick, TimerTick_10ms
	return						; It's > 0 but not yet time to dec counter..
	decfsz	SwRelCount, F
	return
	
	; Check RState: RS_* flags to see if we sholud change outSwRel state or not..
;	btfss	RState, RS_Running
;	return						; Not running, bail..
	
	; RS_BaxiK, RS_BaxiT and RS_PIC can all be enabled at the same time, so we
	; need to check them in reversed prio order (BaxiK has the highest prio and
	; RS_PIC has the lowest prio).
	movfw	Output
	movwf	BDTemp
	
	btfsc	RState, RS_BaxiT
	bsf		Output, outSwRel
	
	btfsc	RState, RS_PIC
	bsf		Output, outSwRel
	
	btfsc	RState, RS_BaxiK
	bcf		Output, outSwRel
	
	; Check if we have switched status of relay
	movfw	BDTemp
	xorwf	Output, w
	andlw	1<<outSwRel
	skpnz
	return
	
	; Set SwRelPostCount when we have changed status of switch relay
	movlw	.50
	movwf	SwRelPostCount
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_TempAlarm">
;**********************************************************************
; Do_TempAlarm
;	Check temp and set/reset temperature alarm. Alarm vill be set if 
;	ExhaustTemp (AN10) > AlarmTemp and WaterTemp (AN8) < 81 degrees celcius.
;**********************************************************************
Do_TempAlarm
    banksel AdcState
	btfss	AdcState, adcDone
	return
    
    banksel AState
	bcf		AState, AS_TempAlarm
	movfw	AlarmTemp				; ExhaustTemp ADC decreased by increasing temperature
	subwf	ExhaustTemp, w			; C = 1 if W <= f (ExhaustTemp >= AlarmTemp)
	skpc
	return
	bsf		AState, AS_TempAlarm

	; Check if water temperature below 81 degrees..
	; MCP9700 datasheet:
	;	  0 grader = 0,50V
	;	 81 grader = 1,31V
	;	100 grader = 1,50V
	;
	; 2015-03-08
	;								I2CTEST
	; PIC   Vcc   Givare  Temp      Volt    Vcorr
	; ----  ----  ------  ------    ------  ------
	; 1:12  4,92   1,281  82,010     1,300   0,020
	; 1:14  5,02   1,274  82,088     1,266   0,055
	;
	; ADC = Givare / (Vcc / 256)
	; 1:12	= 66,65365853658537 @ 82,01 grader
	; 1:14	= 64,968924302788844621513944223108 @ 82,09 grader
	;
	; V = ADC * (Vcc / 256)
	; 1:12	= 1,2684375V @ ADC 66
	; 1:14	= 1,255V @ ADC 64
	;
	; Diff
	; 1:12	= 1,281 - 1,2684375 = 0,0125625 = 1,25625 grader
	; 1:14	= 1,274 - 1,255     = 0,019     = 1,9 grader
	;
	; 2017-01-22
	;
	; AN12 (water) uses a 2,048V ref, so we have to re-calculate ADC
	; values according to that..
	;
	; 2017-09-26
	;					I2CTEST       Fvr2   ADC    ADC
	; PIC   Vcc	  Temp	Volt   Vcorr  Volt   Volt   Value
	; ----  ----  ----  -----  -----  -----  -----  -----
	; 1:12  5,00  81,8	1,269  0,049  2,048  1,220  151,9
	;
	; Ref.är 2,048 v
	; Offset är 0,049 
	; 81,8	(programmet)1,269V@5V	MCP9700
	#if BaxiNo == .1
	movlw	.150				; Baxi1 .150 = 80,3 grader @ 2,048 vREF
	#else
	movlw	.159				; Baxi2 .159 = 80,19 grader @ 2,048 vREF
	#endif

	subwf	WaterTemp, w		; C = 0 if W > f (.66/.64 > ADC)
	skpnc
	bcf		AState, AS_TempAlarm
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_TriacLogic">
;**********************************************************************
; Do_TriacLogic
;	Handle triac control logic states and automatic reverse and stuck
;	states.
;**********************************************************************
Do_TriacLogic
	banksel	RState
	
	; Disable Triac Output
	bcf		TState, tcFwd
	bcf		TState, tcRev
	
	; Bail if Baxi is running the show..
	btfsc	RState, RS_BaxiK
	return
	
	; OK, now we are in control, check if the RS_AutoRev is active..
	btfsc	RState, RS_AutoRev
	goto	AutoReverse
	
	; Check if we should run fwd/rev, and keep an eye on BS_OvrCurr and BS_OCH 
	; to see if we should start the RS_AutoRev logic or stop all input...
	
	; Start to check rev, because then we don't check BS_OverCurr..
	btfss	RState, RS_Rev
	goto	$ + 3
	bsf		TState, tcRev
	return
	
	; Check stuck state before we go any further..
	btfsc	RState, RS_Stuck
	return
	
	; Check fwd, and if enabled also check BS_OverCurr..
	btfss	RState, RS_Fwd
	return
	bsf		TState, tcFwd
	
	; Check BS_OvrCuff flag to see if we should change to the RS_AutoRev mode..
	btfss	BState, BS_OvrCurr
	return
	
	; Check BS_OCH, to see if we should stop input, before we start to reverse..
;	btfss	BState, BS_OCH
;	goto	$ + 7
;	bsf		RState, RS_Stuck
;	bcf		RState, RS_AutoRev
;	clrf	RetryState
	
	; Setup RetryCount to wait for a number of pulses to clear the RS_Stuck state..
;	movlw	0x0a				; Wait for 10 pulses
;	movwf	RetryCount
;	return
	
	; Enable AutoRev and setup parameters..
	bsf		RState, RS_AutoRev
	clrf	RetryDelay
	clrf	RetryState		; Huvud state för triac styrningen
	movlw	DefRetryCount
	movwf	RetryCount
	movlw	DefMaxCurrCount
	movwf	MaxCurrCount
	return
	
AutoReverse
	;******************************************************************
	; AutoReverse (Retry) substates:
	; 0. Disable Triac output and setup a default wait time.
	; 1. Wait.
	; 2. Enable reverse and setup the reverse time.
	; 3. Wait while reversing.
	; 4. Setup a wait time between rev and fwd
	; 5. Wait a while between rev and fwd
	; 6. Enable forward and setup forward time.
	; 7. Check BS_OvrCurr and BS_OCH while waiting. If BS_OvrCurr is set,
	;	 decrease the retry counter. If retry counter > 0 go to substate 0 and
	;	 try again else if retry counter = 0:
	;		disable triac output
	;		set the RS_Stuck flag
	;		clear the RS_AutoRev flag
	;		change to TriacStare 2  (stuck)
	;    If BS_OCH is set stop all input (set RS_Stuck)
	; 8. Disable Triac output and clear RS_AutoRev flag.
	;******************************************************************
	movlp	AUTOREV_JUMP_TABLE
	movfw   RetryState
	andlw	0x0f
	addlw	AUTOREV_JUMP_TABLE
	btfsc	STATUS, C
	incf	PCLATH,F
	movwf	PCL
AUTOREV_JUMP_TABLE
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x00
	goto	AutoRevDelay		; AutoRev retry Substate = 0x01
	goto	AutoRevSubstate02	; AutoRev retry Substate = 0x02
	goto	AutoRevSubstate03	; AutoRev retry Substate = 0x03
	goto	AutoRevSubstate04	; AutoRev retry Substate = 0x04
	goto	AutoRevSubstate05	; AutoRev retry Substate = 0x05
	goto	AutoRevSubstate06	; AutoRev retry Substate = 0x06
	goto	AutoRevSubstate07	; AutoRev retry Substate = 0x07
	goto	AutoRevSubstate08	; AutoRev retry Substate = 0x08
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x09
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0a
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0b
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0c
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0d
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0e
	goto	AutoRevSubstate00	; AutoRev retry Substate = 0x0f

AutoRevSubstate00
	; Retry state 0 - Disable Triac output and setup a default wait time.
	clrf	RetryState
	bcf		TState, tcRev
	bcf		TState, tcFwd
	movlw	.25					; Wait 250ms..
	movwf	RetryDelay
	incf	RetryState, F		; Move on to next state next time..
	IncCounterNoIntr	Backningar, 4
	return
	
AutoRevSubstate02
	; Retry state 2 - Enable reverse and setup the reverse time.
	bsf		TState, tcRev
	movlw	.100				; Reverse for 1000ms
	movwf	RetryDelay
	incf	RetryState, F
	return
	
AutoRevSubstate03
	; Retry state 3 - Wait while reversing.
	bsf		TState, tcRev
	goto	AutoRevDelay
	
AutoRevSubstate04
	; Retry state 4 - Setup a wait time between rev and fwd
	movlw	.25					; Wait for 250ms
	movwf	RetryDelay
	incf	RetryState, F
	return
	
AutoRevSubstate05
	; Retry state 5 - Wait a while between rev and fwd
	goto	AutoRevDelay
	
AutoRevSubstate06
	; Retry state 6 - Enable forward and setup forward time.
	movlw	.200				; Run forward for 2000ms
	incf	RetryState, F
	return
	
AutoRevSubstate07
	; Retry state 7 - Check BS_OvrCurr and BS_OCH while waiting.
	; If BS_OCH (and BS_OvrCurr) is set:
	;	disable triac output
	;	set the RS_Stuck flag
	;	clear the RS_AutoRev flag
	;	change to TriacStare 2  (stuck)
	; If BS_OvrCurr is set, decrease the retry counter. If retry counter > 0
	;	 go to substate 0 and try again else if retry counter = 0:
	bsf		TState, tcFwd
	btfss	BState, BS_OvrCurr
	goto	AutoRevDelay
	
	; Check if BS_OCH is set..
	btfss	BState, BS_OCH
	goto	DecRetryCounter		; Not set, dec RetryCount..
	
	decfsz	MaxCurrCount, F		; Dec max current counter..
	goto	DecRetryCounter
	
	; Skip RetryCount and go direct to the stuck state.
	bsf		RState, RS_Stuck
	bcf		RState, RS_AutoRev
	clrf	RetryState
	
	; Setup RetryCount to wait for a number of pulses to clear the RS_Stuck state..
	movlw	0x0a				; Wait for 10 pulses
	movwf	RetryCount
	return

DecRetryCounter
	movfw	RetryCount
	skpnz
	goto	AutoRevDelay		; This is the last try, ignore BS_OvrCurr as long as BS_OCH isn't set...
	
	decfsz	RetryCount, F
	goto	RetryAutoRev
	
	
RetryAutoRev
	clrf	RetryState			; Lets try again...
	return
	
AutoRevSubstate08
	; Retry state 8 - Disable Triac output and clear RS_AutoRev flag.
	bcf		RState, RS_AutoRev
	clrf	RetryState
	return
	
AutoRevDelay
	btfss	Timer_Tick, TimerTick_10ms
	return
	decfsz	RetryDelay, F
	return
	incf	RetryState, F
	return
;</editor-fold>
	
;<editor-fold defaultstate="collapsed" desc="Do_UpdateBaxiRunStates">
;**********************************************************************
; Do_UpdateBaxiRunStates
;	Update RState:RS_* flags
;**********************************************************************
Do_UpdateBaxiRunStates
    banksel RState
;RS_Running		EQU 0x00		; Baxi is running (we get a run forward signal from baxi)
;RS_BaxiK		EQU 0x01		; Baxi (native)
;RS_BaxiT		EQU 0x02		; Baxi source with PIC/Triac control
;RS_PIC			EQU 0x03		; PIC/Triac control with timings from master (PC/raspberry PI)
;RS_Stuck		EQU 0x04		; Stuck (can only reverse)
;RS_AutoRev		EQU 0x05		; Auto reverse active
;RS_Rev			EQU 0x06		; Reverse
;RS_Fwd			EQU 0x07		; Forward
	
	; Check if we should switch drive mode..
	movfw	DState
	movwf	BDTemp
	xorwf	RState, w
	andlw	1<<RS_BaxiK|1<<RS_BaxiT|1<<RS_PIC	; Mask everthing but RS_BaxiK, RS_BaxiT and RS_PIC
	movwf	BDTemp
	skpnz
	goto	SameDriveMode
	
	; Make sure SwRelCount and SwRelPostCount is both zero before switching drive mode
	movfw	SwRelCount
	skpz
	goto	SameDriveMode
	movfw	SwRelPostCount
	skpz
	goto	SameDriveMode
	
	; Update Drive mode flags
	bcf		RState, RS_BaxiK
	btfsc	DState, RS_BaxiK
	bsf		RState, RS_BaxiK
	bcf		RState, RS_BaxiT
	btfsc	DState, RS_BaxiT
	bsf		RState, RS_BaxiT
	bcf		RState, RS_PIC
	btfsc	DState, RS_PIC
	bsf		RState, RS_PIC
	
	; If RS_PIC is active, check that LastPiTm > 0 before we switch, use RS_BaxiT as fallback when LastPiTm = 0
	btfss	RState, RS_PIC
	goto	SameDriveMode
	movfw	LastRPiTm
	skpz
	goto	SameDriveMode
	bcf		RState, RS_PIC
	bsf		RState, RS_BaxiT
	clrf	PiState
	
SameDriveMode
	; Start to check if the RS_Stuck state is set
	btfss	RState, RS_Stuck
	goto	SkipStuckState
	
	; Check for pulses...
	btfss	InputD, inPgSkruv
	goto	SkipStuckState
	
	; Dec retry counter for each pulse we get until it's zero.
	decfsz	RetryCount, F
	goto	SkipStuckState
	
	; Resume normal operation..
	bcf		RState, RS_Stuck
SkipStuckState
	
	; Check the inBaxi signal, to see if Baxi appears to be running or not..
	; If we haven't got a signal for 30 seconds, we consider it stopped.
    movlw   30                  ; Reset BaxiRunTmr if
    btfsc	InputD, inBaxiFwd   ; there is a change on
    movwf   BaxiRunTmr          ; the inBaxi signal.
    
    bcf     RState, RS_Running  ; Clear RS_Running flag.
    movfw   BaxiRunTmr          ; Set RS_Running flag if
    skpz                        ; BaxiRunTmr > 0.
    bsf     RState, RS_Running
    
    ; Decrease BaxiRunTmr if RS_Running flag is set...
    btfss   RState, RS_Running
    goto    $ + 3
    btfsc   Timer_Tick, TimerTick_1000ms
    decf    BaxiRunTmr, F
	
	; Check input source..
	btfsc	RState, RS_BaxiK
	goto	BaxiKRunState
	btfsc	RState, RS_BaxiT
	goto	BaxiTRunState
	btfsc	RState, RS_PIC
	goto	PicRunState
	
	; Invalid Run State, set RS_BaxiK as fallback..
	bsf		RState, RS_BaxiK
	return
	
BaxiKRunState
	; Baxi controls everything, we only monitor.
	bcf		RState, RS_BaxiT
	bcf		RState, RS_PIC
	bcf		RState, RS_Stuck
	bcf		RState, RS_AutoRev
	bcf		RState, RS_Rev
	bcf		RState, RS_Fwd
	return
	
BaxiTRunState
	; Baxi is the source of the signal, but we control the motor.

	; Check relay position and postcounter before we do anything
	btfss	Output, outSwRel
	return	; Wrong position, bail
	movfw	SwRelPostCount
	skpz
	return	; Just switched, bail

	; Check that switch relay is in correct possition before we try to do anything
	; Check inBaxiRev to se if we should enable any output..
	btfsc	Input, inBaxiRev
	bsf		RState, RS_Rev
	btfss	Input, inBaxiRev
	bcf		RState, RS_Rev
	
	; Check Stuck state before we check inBaxiFwd
	btfsc	RState, RS_Stuck
	return
	
	; Check inBaxiFwd to se if we should enable any output..
	btfsc	Input, inBaxiFwd
	bsf		RState, RS_Fwd
	btfss	Input, inBaxiFwd
	bcf		RState, RS_Fwd
	return
	
PicRunState
	; Raspberry is the source of the timing to run the motor.

	; Check relay position and postcounter before we do anything
	btfss	Output, outSwRel
	return	; Wrong position, bail
	movfw	SwRelPostCount
	skpz
	return	; Just switched, bail
	
	movlp	PicRunStateSubstate
	movfw   PiState
	andlw	0x0f
	addlw	PicRunStateSubstate
	btfsc	STATUS, C
	incf	PCLATH,F
	movwf	PCL
PicRunStateSubstate
	goto	PicRunStateSubstate00	; Idle init
	goto	PicRunStateSubstate01	; Idle/Wait between inputs
	goto	PicRunStateSubstate02	; Input (normal)
	goto	PicRunStateSubstate03	; Input (reverse extra input)
	goto	PicRunStateSubstate04	; Reverse
	; TODO
	; We control the timing as long as we get regular updates of the time.
	; if we don't get updates for a while (time?), we revert back to the 
	; RS_BaxiT state. If we once have been in RS_PIC, but reverted to RS_BaxiT
	; we should go back to RS_PIC when we get updates again.
	return
	
PicRunStateSubstate00				; Idle init
	bcf		RState, RS_Rev
	bcf		RState, RS_Fwd
	ClearCounter	PiCnt, 2
	incf	PiState, f
	return
	
PicRunStateSubstate01				; Idle/Wait between inputs
    btfss   Timer_Tick, TimerTick_100ms
	return
	IncCounter PiCnt, 2
	
	; TODO: Check that LastRPiTm > 0

	; if PiCnt < PiIdleTm then return
	movfw	PiIdleTm
	subwf	PiCnt, w
	skpc
	return
	movfw	PiIdleTm + 1
	subwf	PiCnt + 1, w
	skpc
	return

	; Prepare next step
	incf	PiState, f
	ClearCounter	PiCnt, 2
	
	; Enable TriacFwd if PiActTm > 0
	movfw	PiActTm
	skpz
	bsf		RState, RS_Fwd
	return

PicRunStateSubstate02				; Input (normal)
    btfss   Timer_Tick, TimerTick_100ms
	return
	incf	PiCnt, f
	
	; if PiCnt < PiActTm then return
	movfw	PiActTm
	subwf	PiCnt, w
	skpc
	return
	
	; Prepare next step
	incf	PiState, f
	clrf	PiCnt
	
	; Disable input if we shouldn't reverse
	movfw	PiRevTm
	skpnz
	bcf		RState, RS_Fwd
	return
	
PicRunStateSubstate03				; Input (reverse extra input)
    btfss   Timer_Tick, TimerTick_100ms
	return
	incf	PiCnt, f
	
	; if PiCnt < PiRevTm then return
	movfw	PiRevTm
	subwf	PiCnt, w
	skpc
	return
	
	; Prepare next step
	incf	PiState, f
	clrf	PiCnt
	bcf		RState, RS_Fwd
	return
	
PicRunStateSubstate04				; Reverse
	bsf		RState, RS_Rev
	btfss   Timer_Tick, TimerTick_100ms
	return
	incf	PiCnt, f
	
	; if PiCnt < PiRevTm then return
	movfw	PiRevTm
	subwf	PiCnt, w
	skpc
	return
	
	; Restart on first step
	clrf	PiState
	bcf		RState, RS_Rev
	return
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="Do_MaxCurrentDetection">
;**********************************************************************
; Do_MaxCurrentDetection
;	Check current sensing inputs and set detected max values.
;**********************************************************************
Do_MaxCurrentDetection
    banksel BState
	; Check if we should reset the OvrCurrTO timeout to OvrCurrTm1 or OvrCurrTm2
	movlw	OvrCurrTm1
	btfsc	RState, RS_AutoRev
	movlw	OvrCurrTm2
    btfss   BState, BS_OCL
    movwf	OvrCurrTO			; BS_OCL-bit is cleared, reset counter
	
	; Check if counter > 0
	bsf		BState, BS_OvrCurr	; Set over curreent flag..
	movfw	OvrCurrTO
	skpnz
	goto	SkipOvrCurrCheck	; Counter = 0, skip the rest of the over current check
	bcf		BState, BS_OvrCurr	; Counter > 0, clear over current flag again..

	; Check if it's time to decrease the counter
	btfsc	Timer_Tick, TimerTick_10ms
	decfsz	OvrCurrTO, F
	goto	SkipOvrCurrCheck	; Still not = 0, skip the rest of the over current check
	bsf		BState, BS_OvrCurr	; Counter = 0 now, set over current flag again..
SkipOvrCurrCheck


	; Check if we should reset the SampleDelayTO timeout
	movlw	SampleDelayTm
    btfss   BState, BS_Trig
	movwf	SampleDelayTO		; All is cleared, reset counter
	
	; Check if Sample Delay counter > 0
	movfw	SampleDelayTO
	skpnz
	goto	SkipSampleDelayCheck
	
	; Check if it's time to decrease counter
	btfsc	Timer_Tick, TimerTick_10ms
	decfsz	SampleDelayTO, F
	goto	SkipSampleDelayCheck
	btfsc	RState, RS_AutoRev	; Don't clear max values if we are reversing.
	goto	SkipSampleDelayCheck
	btfss	RState, RS_Rev		; Don't clear max value if someone else is reversing
	clrf	MaxChn
SkipSampleDelayCheck

	; Check if we have a new ADC value to check yet..
	banksel AdcState
	btfss	AdcState, adcOcSignalDone
	return

	banksel BState
	; Check if above threshold value
	movlw	TrigLevel
	subwf	OCSignal, W			; C = 0 if W > f (Threshold > ADC)
	skpnc   ; What happen? Somebody set us up the bomb.
	goto	WeGotSignal

	bcf		BState, BS_Trig
	bcf		BState, BS_OCL
	bcf		BState, BS_OCH
	return
WeGotSignal   ; What! Main screen turn on. It's you! How are you gentlemen!! All you bits are belong to us!
	bsf		BState, BS_Trig   ; Move ZIG!
	
	; Check overcurrent detection
	bcf		BState, BS_OCL
	movfw	OCSignal
	subwf	OCLimitL, W			; C = 0 if w > f (OCSignal > OCLimitL)
	skpc
	bsf		BState, BS_OCL
	
	bcf		BState, BS_OCH
	movfw	OCSignal
	subwf	OCLimitH, W			; C = 0 if w > f (OCSignal > OCLimitH)
	skpc
	bsf		BState, BS_OCH
	
	; Check if SampleData timeout = 0
	movfw	SampleDelayTO
	skpz
	return
	
	; Only update the max value for "forward"
	btfsc	RState, RS_AutoRev
	return
	btfsc	RState, RS_Rev
	return
	
	; Check if OCSignal > Current Max value?
	movfw	OCSignal
	subwf	MaxChn, W			; C = 0 if W > f (OCSignal > MaxChn)
	skpnc
	return

	; Save the new maximum value
	movfw	OCSignal
	movwf	MaxChn
	return
;</editor-fold>

	END
