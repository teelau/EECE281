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

ISR_timer2:
	push psw
	push acc
	push dpl
	push dph
	
	clr TF2
	cpl P0.1
	
	mov a, Cnt_10ms
	inc a
	mov Cnt_10ms, a
	
	cjne a, #100, do_nothing
	
	mov Cnt_10ms, #0
	
	mov a, BCD_count
	;add a, #1
	;da a
	
	cjne a, #60H, reset_seconds_return	;if seconds = 60
	mov a, bcd_minute					;minute++
	add a, #1
	da a
	mov bcd_minute, a
	mov bcd_count, #0					;seconds = 0
	
	mov a, bcd_minute
	cjne a, #60H, reset_minutes_return	;if minute = 60
	mov a, bcd_hour						;hour++
	add a, #1
	da a
	mov bcd_hour, a
	mov bcd_minute, #0					;minute = 0
	
	mov a, bcd_hour						;if hour = 13
	cjne a, #13H, reset_hours_return	;xm++
	mov a, bcd_xm
	add a, #1							
	da a
	mov bcd_xm, a					
	mov bcd_hour, #1H					;hour = 1
	
	mov a, bcd_xm
	cjne a, #2H, reset_xm_return		;if xm=2
	mov bcd_xm, #0						;xm = 0
	reset_xm_return:
	reset_hours_return:
	reset_minutes_return:
	reset_seconds_return:
	
	
	
	
	
	
	
	
	
	mov a, bcd_xm
	mov dptr, #myXM
;Display xm
    anl A, #0FH
    movc A, @A+dptr
    mov HEX0, A
	;cjne a, #0, reset_am_return ;if xm = 0, display am
;Display am
	;anl A, #0FH
    ;movc A, @A+dptr
    ;mov HEX0, A
	
	;reset_am_return:
;Display pm						;if xm = 1, display pm
	;anl A, #0FH
    ;movc A, @A+dptr
    ;mov HEX0, A

	
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
	mov dptr, #myLUT
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
	mov dptr, #myLUT
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
    
    mov a, bcd_count	; seconds++
	add a, #1
	da a
	mov bcd_count, a

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
    
    mov bcd_xm, #0
    mov bcd_hour, #12H
    mov bcd_minute, #0
    mov BCD_count, #0
    mov Cnt_10ms, #0
     
    setb EA  ; Enable all interrupts

M0:
	cpl LEDRA.0
	lcall WaitHalfSec
	sjmp M0
END
