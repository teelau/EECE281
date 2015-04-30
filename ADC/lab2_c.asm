	$MODDE2
	
	CLK EQU 33333333
	FREQ_0 EQU 200
	FREQ_1 EQU 300
	FREQ_2 EQU 400
	FREQ_3 EQU 500
	FREQ_4 EQU 700
	FREQ_5 EQU 1200
	FREQ_6 EQU 1600
	FREQ_7 EQU 2000
	
	NOTE_0 EQU 65536-(CLK/(12*2*FREQ_0))
	NOTE_1 EQU 65536-(CLK/(12*2*FREQ_1))
	NOTE_2 EQU 65536-(CLK/(12*2*FREQ_2))
	NOTE_3 EQU 65536-(CLK/(12*2*FREQ_3))
	NOTE_4 EQU 65536-(CLK/(12*2*FREQ_4))
	NOTE_5 EQU 65536-(CLK/(12*2*FREQ_5))
	NOTE_6 EQU 65536-(CLK/(12*2*FREQ_6))
	NOTE_7 EQU 65536-(CLK/(12*2*FREQ_7))
	
	org 0000H
	ljmp myprogram

	org 000BH
	ljmp ISR_timer0
	
	DSEG at 30H
	sound1: ds 1
	CSEG
	
ISR_timer0:
	cpl P0.0
	mov a, sound1
	cjne a, #0, buzz2 
    mov TH0, #high(NOTE_0)
    mov TL0, #low(NOTE_0)
    reti
buzz2:
	cjne a, #1, buzz3
	mov TH0, #high(NOTE_1)
    mov TL0, #low(NOTE_1)
	reti
buzz3:
	cjne a, #2, buzz4
	mov TH0, #high(NOTE_2)
    mov TL0, #low(NOTE_2)
	reti
buzz4:
	cjne a, #3, buzz5
	mov TH0, #high(NOTE_3)
    mov TL0, #low(NOTE_3)
	reti
buzz5:
	cjne a, #4, buzz6
	mov TH0, #high(NOTE_4)
    mov TL0, #low(NOTE_4)
	reti
buzz6:
	cjne a, #5, buzz7
	mov TH0, #high(NOTE_5)
    mov TL0, #low(NOTE_5)
	reti
buzz7:
	cjne a, #6, buzz8
	mov TH0, #high(NOTE_6)
    mov TL0, #low(NOTE_6)
	reti
buzz8:
	mov TH0, #high(NOTE_7)
    mov TL0, #low(NOTE_7)
	reti
	
delay100us:
	mov R1, #10
L00: mov R0, #111
L01: djnz R0, L01 ; 111*30ns*3=10us
	djnz R1, L00 ; 10*10us=100us, approximately
	ret

myprogram: 
	mov SP, #7FH ; Set the stack pointer
 	mov LEDRA, #0 ; Turn off all LEDs
 	mov LEDRB, #0
 	mov LEDRC, #0
 	mov LEDG, #0
 	mov P3MOD, #11111111B ; Configure P3.0 to P3.7 as outputs
	mov P2MOD, #00000000B ; p2 is inputs
	mov P0MOD, #00000011B ; P0.0, P0.1 are outputs.  P0.1 is used for testing Timer 2!
	setb P0.0

    mov TMOD,  #00000001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    setb TR0 ; Enable timer 0

    mov sound1, #0
     
    setb EA  ; Enable all interrupts
	;clear port pins
	mov		p3, #0
	mov		p2, #0

loopy:
	;begin conversion
	mov     p3,#0
	setb	p3.7
	lcall delay100us
	jnb		p2.4,L1
	clr		p3.7
L1:	setb	p3.6
	lcall delay100us
	jnb		p2.4,L2
	clr		p3.6
L2:	setb	p3.5
	lcall delay100us
	jnb		p2.4,L3
	clr		p3.5
L3:	setb	p3.4
	lcall delay100us
	jnb		p2.4,L4
	clr		p3.4
L4:	setb	p3.3
	lcall delay100us
	jnb		p2.4,L5
	clr		p3.3
L5:	setb	p3.2
	lcall delay100us
	jnb		p2.4,L6
	clr		p3.2
L6:	setb	p3.1
	lcall delay100us
	jnb		p2.4,L7
	clr		p3.1
L7:	setb	p3.0
	lcall delay100us
	jnb		p2.4,L8
	clr		p3.0
L8:
	mov ledra, p3
	clr et0
	jnb ledra.7,K1
	;freq 7
	mov sound1, #7
	ljmp Kend
K1:
	jnb ledra.6,K2
	;freq 6
	mov sound1, #6
	ljmp Kend
K2:
	jnb ledra.5,K3
	;freq 5
	mov sound1, #5
	ljmp Kend
K3:
	jnb ledra.4,K4
	;freq 4
	mov sound1, #4
	ljmp Kend
K4:
	jnb ledra.3,K5
	;freq 3
	mov sound1, #3
	ljmp Kend
K5:
	jnb ledra.2,K6
	;freq 2
	mov sound1, #2
	ljmp Kend
K6:
	jnb ledra.1,K7
	;freq 1
	mov sound1, #1
	ljmp Kend
K7:
	;freq 0
	mov sound1, #0
Kend:
	setb et0
	;conversion#2
	mov     p3,#0
	setb	p3.7
	lcall delay100us
	jnb		p2.5,L12
	clr		p3.7
L12:setb	p3.6
	lcall delay100us
	jnb		p2.5,L22
	clr		p3.6
L22:setb	p3.5
	lcall delay100us
	jnb		p2.5,L32
	clr		p3.5
L32:setb	p3.4
	lcall delay100us
	jnb		p2.5,L42
	clr		p3.4
L42:setb	p3.3
	lcall delay100us
	jnb		p2.5,L52
	clr		p3.3
L52:setb	p3.2
	lcall delay100us
	jnb		p2.5,L62
	clr		p3.2
L62:setb	p3.1
	lcall delay100us
	jnb		p2.5,L72
	clr		p3.1
L72:setb	p3.0
	lcall delay100us
	jnb		p2.5,L82
	clr		p3.0
L82:
	mov ledg, p3
	
	ljmp loopy
END