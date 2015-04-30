; Blinky_Int.asm: blinks LEDR0 of the DE2-8052 each second.
; Also generates a 2kHz signal at P0.0 using timer 0 interrupt.
; Also keeps a BCD counter using timer 2 interrupt.

$MODDE2

CLK EQU 33333333
FREQ_0 EQU 2000
FREQ_2 EQU 100
TIMER0_RELOAD EQU 65536-(CLK/(12*2*FREQ_0))
TIMER2_RELOAD EQU 65536-(CLK/(12*FREQ_2))

org 0000H
	ljmp myprogram
	
org 000BH
	ljmp ISR_timer0
	
org 002BH
	ljmp ISR_timer2

DSEG at 30H
snooze_flag: ds 1
snooze_count: ds 1

stopwatch_flag: ds 1
Cnt_10ms2: ds 1
swatch_hour: ds 1
swatch_minute: ds 1
swatch_count: ds 1
swatch_dec: ds 1

alarm_trigger_repeat: ds 1
alarm_flag: ds 1
alarm_xm: ds 1
alarm_hour: ds 1
alarm_minute: ds 1
alarm_count: ds 1
bcd_xm: ds 1
bcd_hour: ds 1
bcd_minute: ds 1
BCD_count: ds 1
Cnt_10ms:  ds 1

CSEG

; Look-up table for 7-segment displays
myXM:
	DB 088H, 08CH ; A and P
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
myBlank:
	DB 0FFH
ISR_timer2:
	push psw
	push acc
	push dpl
	push dph
	
	clr TF2
	cpl P0.1
	
		;activate stopwatch mode
		jnb swa.6, timer_set_proxy1
		
		lcall display_stopwatch
		
		;stopwatch reset
			jb key.3,do_nothing_proxy0S	;key pressed?
			mov stopwatch_flag, #0
			mov swatch_hour,#0
			mov swatch_minute, #0
			mov swatch_count, #0
			mov swatch_dec, #0
			do_nothing_proxy0S:	
			
		;stopwatch on/off
		jnb swa.5, swatch_onoff
		mov stopwatch_flag, #1
		sjmp swatch_onoff2
		swatch_onoff:
		mov stopwatch_flag, #0
		swatch_onoff2:
		
		mov a, stopwatch_flag
		cjne a, #1, skip_timer_trigger
			mov a, swatch_dec
			inc a
			mov swatch_dec, a
			
			mov a, Cnt_10ms2
			inc a
			mov Cnt_10ms2, a	
			cjne a, #100, do_nothing_proxy0A
			mov Cnt_10ms2, #0
			
			lcall increment_seconds_swatch
			lcall check_overflows_swatch
		skip_timer_trigger:
		
		ljmp do_nothing
		
	timer_set_proxy1:
		
	;display to 7 segments
	;lcall check_overflows
	lcall display_hex
	
	;display alarm status/snooze
	mov a, alarm_flag
	cjne a, #1, skip_status
	setb LEDG.5
	skip_status:
			
		;activate fast-time mode
		;jb swa.7, timer_fast
		
		;activate set-time mode, freeze clock
		jnb swa.0, timer_set
		
			;;;;;
			;activate set-alarm mode
			jnb swa.1, timer_alarm
					
				jb key.3,do_nothing_proxyB1 ;key press?
				lcall set_alarm_time		;save the current time to set alarm
				mov alarm_flag, #1
				;keyreleaseA1:
				;jnb key.3, keyreleaseA1
				do_nothing_proxyB1:
				
			ljmp do_nothing
			timer_alarm:
			;;;;;
			
			jb key.1,do_nothing_proxy01	;key pressed?
			lcall increment_seconds		;seconds++
							
			jnb key.1,$
			ljmp do_nothing_proxy0A
			do_nothing_proxy01:			;wait for key release
		
			jb key.2,do_nothing_proxy02	;key pressed?
			lcall increment_minutes		;minutes++
					
			jnb key.2,$ 
			ljmp do_nothing_proxy0A		;wait for key release
			do_nothing_proxy02:
			
			jb key.3,do_nothing_proxy0A	;key pressed?
			lcall increment_hours		;hours++
						
			jnb key.3,$		;wait for key release
				
			
		do_nothing_proxy0A:
		lcall check_overflows
		ljmp do_nothing
		timer_set:

	;check for snooze button
	mov a, alarm_trigger_repeat
	cjne a, #1, alarm_off_proxy3
	jb key.3, alarm_off_proxy3
	mov snooze_flag, #1
	setb LEDG.7
	lcall clear_red_led
	mov alarm_trigger_repeat, #0
	alarm_off_proxy3:

	;check for alarm-off button
	jb key.2, alarm_off_proxy
	mov alarm_flag, #0
	mov alarm_trigger_repeat, #0
	clr LEDG.5
	lcall clear_red_led
	alarm_off_proxy:
	
	;check for alarm-reset button
	jb key.1, alarm_off_proxy2
	mov alarm_trigger_repeat, #0
	lcall clear_red_led
	alarm_off_proxy2:
	
			;activate fast-time mode
			jb swa.7, timer_fast
			
	;wait 1 second
	mov a, Cnt_10ms
	inc a
	mov Cnt_10ms, a	
	cjne a, #100, do_nothing
	mov Cnt_10ms, #0
	

	timer_fast: ;fast mode skips the 1 second delay


	;idle mode, increment 1 second
    lcall increment_seconds
	lcall check_overflows
	
	;(after being set) check alarm here
	mov a, alarm_flag
	cjne a, #1, skip_alarm_trigger
	lcall trigger_the_alarm
	skip_alarm_trigger:
	
	;count snooze 1 minute after being pressed
	mov a, snooze_flag
	cjne a, #1, snooze_off_proxy
	mov a, snooze_count
	inc a
	da a
	mov snooze_count, a
	cjne a, #60H, snooze_off_proxy
	mov snooze_flag, #0
	mov snooze_count, #0
	mov alarm_trigger_repeat, #1
	clr LEDG.7
	snooze_off_proxy:
	
do_nothing:
	pop dph
	pop dpl
	pop acc
	pop psw
	
	reti

ISR_timer0:
	cpl P0.0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
	reti
	
;For a 33.33MHz clock, one cycle takes 30ns
WaitHalfSec:
	mov R2, #90
L3: mov R1, #250
L2: mov R0, #250
L1: djnz R0, L1
	djnz R1, L2
	djnz R2, L3
	ret
	
WaitBuffer:
	mov R2, #45
L03:mov R1, #250
L02:mov R0, #250
L01:djnz R0, L01
	djnz R1, L02
	djnz R2, L03
	ret
	
myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	mov P0MOD, #00000011B ; P0.0, P0.1 are outputs.  P0.1 is used for testing Timer 2!
	setb P0.0

    mov TMOD,  #00000001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    
        
    mov T2CON, #00H ; Autoreload is enabled, work as a timer
    clr TR2
    clr TF2
    ; Set up timer 2 to interrupt every 10ms
    mov RCAP2H,#high(TIMER2_RELOAD)
    mov RCAP2L,#low(TIMER2_RELOAD)
    setb TR2
    setb ET2
    
    mov snooze_flag, #0
    mov snooze_count, #0
    mov stopwatch_flag, #0
    mov Cnt_10ms2,#0
    mov swatch_hour,#0
	mov swatch_minute, #0
	mov swatch_count, #0
	mov swatch_dec, #0
    mov alarm_trigger_repeat, #0
    mov alarm_flag, #0
	mov alarm_xm, #0
	mov alarm_hour, #0
	mov alarm_minute, #0
	mov alarm_count, #61
    mov bcd_xm, #0
    mov bcd_hour, #12H
    mov bcd_minute, #0
    mov BCD_count, #0
    mov Cnt_10ms, #0
     
    setb EA  ; Enable all interrupts

M0:
	cpl LEDRA.0
	lcall WaitHalfSec
	lcall repeat_the_alarm
	sjmp M0
	
display_stopwatch:

	mov a, swatch_count
	mov dptr, #myLUT
; Display min 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX2, A
; Display min 2
    mov A, swatch_count
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX3, A	
    
	mov a, swatch_minute
; Display hr 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX4, A
; Display hr 2
    mov A, swatch_minute
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX5, A	
    
	mov a, swatch_hour
; Display hr 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX6, A
; Display hr 2
    mov A, swatch_hour
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX7, A	
    
    mov a, #0
	mov dptr, #myBlank
    anl A, #0FH
    movc A, @A+dptr
    mov HEX0, A
    ret
	
display_hex:
	
	mov a, bcd_count
	mov dptr, #myLUT
; Display sec 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX2, A
; Display sec 2
    mov A, BCD_count
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX3, A	

	mov a, bcd_minute
; Display min 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX4, A
; Display min 2
    mov A, BCD_minute
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX5, A	
    
	mov a, bcd_hour
; Display hr 0
    anl A, #0FH
    movc A, @A+dptr
    mov HEX6, A
; Display hr 2
    mov A, BCD_hour
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX7, A	
    
   	mov a, bcd_xm
	mov dptr, #myXM
;Display xm
    anl A, #0FH
    movc A, @A+dptr
    mov HEX0, A
    ret

increment_seconds_swatch:
    mov a, swatch_count	; seconds++
	add a, #1
	da a
	mov swatch_count, a
	ret

increment_minutes_swatch:
    mov a, swatch_minute	; seconds++
	add a, #1
	da a
	mov swatch_minute, a
	ret
	
increment_hours_swatch:
    mov a, swatch_hour	; seconds++
	add a, #1
	da a
	mov swatch_hour, a
	ret
	
increment_seconds:
    mov a, bcd_count	; seconds++
	add a, #1
	da a
	mov bcd_count, a
	ret
	
increment_minutes:
    mov a, bcd_minute	; seconds++
	add a, #1
	da a
	mov bcd_minute, a
	ret
	
increment_hours:
    mov a, bcd_hour	; seconds++
	add a, #1
	da a
	mov bcd_hour, a
	mov a, bcd_hour
	cjne a, #12H, reset_hour2
	mov a, bcd_xm
	add a, #1
	da a
	mov bcd_xm, a
	reset_hour2:
	ret

check_overflows_swatch:
	mov a, swatch_count
	cjne a, #60H, reset_secondsA	;if seconds = 60
	lcall increment_minutes_swatch
	mov swatch_count, #0					;seconds = 0
	reset_secondsA:
	
	mov a, swatch_minute
	cjne a, #60H, reset_minuteA	;if minute = 60
	lcall increment_hours_swatch
	mov swatch_minute, #0					;minute = 0
	reset_minuteA:
	
	mov a, swatch_hour						;if hour = 13
	cjne a, #13H, reset_hour1A			;xm++					
	mov swatch_hour, #1H					;hour = 1
	reset_hour1A:
	ret

check_overflows:
	mov a, BCD_count
	cjne a, #60H, reset_seconds	;if seconds = 60
	lcall increment_minutes
	mov bcd_count, #0					;seconds = 0
	reset_seconds:
	
	mov a, bcd_minute
	cjne a, #60H, reset_minute	;if minute = 60
	lcall increment_hours
	mov bcd_minute, #0					;minute = 0
	reset_minute:
	
	mov a, bcd_hour						;if hour = 13
	cjne a, #13H, reset_hour1			;xm++					
	mov bcd_hour, #1H					;hour = 1
	reset_hour1:
	
	mov a, bcd_xm
	cjne a, #2H, reset_xm			;if xm=2
	mov bcd_xm, #0						;xm = 0
	reset_xm:
	ret
	
set_alarm_time:
	mov alarm_count, bcd_count
	mov alarm_minute, bcd_minute
	mov alarm_hour, bcd_hour
	mov alarm_xm, bcd_xm
	ret

trigger_the_alarm:

	mov a, alarm_count
	cjne a, bcd_count, alarm_trigger_false						
	mov a, alarm_minute
	cjne a, bcd_minute, alarm_trigger_false					
	mov a, alarm_hour						
	cjne a, bcd_hour, alarm_trigger_false				
	mov a, bcd_xm
	cjne a, alarm_xm, alarm_trigger_false
	
	mov alarm_trigger_repeat, #1

	alarm_trigger_false:					
	ret
	
repeat_the_alarm:
	mov a, alarm_trigger_repeat
	cjne a, #1, alarm_trigger_repeat_false
	cpl LEDRA.1
	cpl LEDRA.2
	cpl LEDRA.3
	cpl LEDRA.4
	cpl LEDRA.5
	cpl LEDRA.6
	cpl LEDRA.7
	alarm_trigger_repeat_false:
	ret
	
clear_red_led:
	clr LEDRA.1
	clr LEDRA.2
	clr LEDRA.3
	clr LEDRA.4
	clr LEDRA.5
	clr LEDRA.6
	clr LEDRA.7
	ret
END
