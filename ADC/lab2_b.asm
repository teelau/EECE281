	$MODDE2
	org 0000H
	ljmp myprogram

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