; dac.asm: uses a R-2R ladder DAC to generate a ramp
$MODDE2
org 0000H
 ljmp myprogram
; 100 micro-second delay subroutine
delay100us:
 mov R1, #10
 L0: mov R0, #111
L1: djnz R0, L1 ; 111*30ns*3=10us
 djnz R1, L0 ; 10*10us=100us, approximately
 ret
myprogram:
 mov SP, #7FH ; Set the stack pointer
 mov LEDRA, #0 ; Turn off all LEDs
 mov LEDRB, #0
 mov LEDRC, #0
 mov LEDG, #0
 mov P3MOD, #11111111B ; Configure P3.0 to P3.7 as outputs
 mov R3, #0 ; Initialize counter to zero
Loop:
 mov P3, R3
 inc R3
 lcall delay100us
 sjmp Loop
END 
