//  square.c: Uses timer 2 interrupt to generate a square wave in pin
//  P2.0 and a 75% duty cycle wave in pin P2.1
//  Copyright (c) 2010-2015 Jesus Calvino-Fraga
//  ~C51~
	
#include <C8051F38x.h>
#include <stdlib.h>
#include <stdio.h>
#define SYSCLK    48000000L // SYSCLK frequency in Hz
#define BAUDRATE  115200L   // Baud rate of UART in bps
#define iterations 40000
#define OUT0 P0_7
#define OUT1 P0_6
#define BUZZ P0_2

volatile int tx;
volatile unsigned char pwm_count=0;
void resetLED( void );
volatile int buzz;
	
char _c51_external_startup (void)
{
	
	PCA0MD&=(~0x40) ;    // DISABLE WDT: clear Watchdog Enable bit
	VDM0CN=0x80; // enable VDD monitor
	RSTSRC=0x02|0x04; // Enable reset on missing clock detector and VDD

	// CLKSEL&=0b_1111_1000; // Not needed because CLKSEL==0 after reset
	#if (SYSCLK == 12000000L)
		//CLKSEL|=0b_0000_0000;  // SYSCLK derived from the Internal High-Frequency Oscillator / 4 
	#elif (SYSCLK == 24000000L)
		CLKSEL|=0b_0000_0010; // SYSCLK derived from the Internal High-Frequency Oscillator / 2.
	#elif (SYSCLK == 48000000L)
		CLKSEL|=0b_0000_0011; // SYSCLK derived from the Internal High-Frequency Oscillator / 1.
	#else
		#error SYSCLK must be either 12000000L, 24000000L, or 48000000L
	#endif
	OSCICN |= 0x03; // Configure internal oscillator for its maximum frequency

	// Configure UART0
	SCON0 = 0x10; 
#if (SYSCLK/BAUDRATE/2L/256L < 1)
	TH1 = 0x10000-((SYSCLK/BAUDRATE)/2L);
	CKCON &= ~0x0B;                  // T1M = 1; SCA1:0 = xx
	CKCON |=  0x08;
#elif (SYSCLK/BAUDRATE/2L/256L < 4)
	TH1 = 0x10000-(SYSCLK/BAUDRATE/2L/4L);
	CKCON &= ~0x0B; // T1M = 0; SCA1:0 = 01                  
	CKCON |=  0x01;
#elif (SYSCLK/BAUDRATE/2L/256L < 12)
	TH1 = 0x10000-(SYSCLK/BAUDRATE/2L/12L);
	CKCON &= ~0x0B; // T1M = 0; SCA1:0 = 00
#else
	TH1 = 0x10000-(SYSCLK/BAUDRATE/2/48);
	CKCON &= ~0x0B; // T1M = 0; SCA1:0 = 10
	CKCON |=  0x02;
#endif
	TL1 = TH1;      // Init Timer1
	TMOD &= ~0xf0;  // TMOD: timer 1 in 8-bit autoreload
	TMOD |=  0x20;                       
	TR1 = 1; // START Timer1
	TI = 1;  // Indicate TX0 ready
	
	// Configure the pins used for square output
	P0MDOUT|=0b_1100_0000;
	P2MDOUT|=0b_1111_1111;
	P1MDIN|=0b_0111_1111;
	P1MDOUT|=0b_1000_0000;
	P0MDOUT |= 0b_0001_0100; // Enable UTX as push-pull output
	XBR0     = 0x01; // Enable UART on P0.4(TX) and P0.5(RX)                     
	XBR1     = 0x40; // Enable crossbar and weak pull-ups

	// Initialize timer 2 for periodic interrupts
	TMR2CN=0x00;   // Stop Timer2; Clear TF2;
	CKCON|=0b_0001_0000;
	TMR2RL=0x10000L-(SYSCLK/(2L*15200)); // Initialize reload value
	TMR2=0xffff;   // Set to reload immediately
	ET2=1;         // Enable Timer2 interrupts
	TR2=1;         // Start Timer2

	EA=1; // Enable interrupts
	
	return 0;
}
void Timer3us(unsigned char us)
{
	unsigned char i;               // usec counter
	
	// The input for Timer 3 is selected as SYSCLK by setting T3ML (bit 6) of CKCON:
	CKCON|=0b_0100_0000;
	
	TMR3RL = (-(SYSCLK)/1000000L); // Set Timer3 to overflow in 1us.
	TMR3 = TMR3RL;                 // Initialize Timer3 for first overflow
	
	TMR3CN = 0x04;                 // Sart Timer3 and clear overflow flag
	for (i = 0; i < us; i++)       // Count <us> overflows
	{
		while (!(TMR3CN & 0x80));  // Wait for overflow
		TMR3CN &= ~(0x80);         // Clear overflow indicator
	}
	TMR3CN = 0 ;                   // Stop Timer3 and clear overflow flag
}

void waitms (unsigned int ms)
{
	unsigned int j;
	unsigned char k;
	for(j=0; j<ms; j++)
		for (k=0; k<4; k++) Timer3us(250);
}

void Timer2_ISR (void) interrupt 5
{
	TF2H = 0; // Clear Timer2 interrupt flag
	if(tx == 1){
	OUT0=!OUT0;
	OUT1=!OUT0;
	}
	if(buzz == 1)
	BUZZ =! BUZZ;
}

void wait_bit_time(){
	float n=iterations;
	while (n>0){
	n--;
	}
	return;
} 

void tx_byte ( unsigned char val ){
	unsigned char j;
	//send the start bit
	tx=0;
	wait_bit_time();
	for (j=0; j<8; j++)
	{
	tx=val&(0x01<<j)?1:0;
	wait_bit_time();
	}
	tx = 1;
	//send the stop bits
	wait_bit_time();
	wait_bit_time();
}

void resetLED( void ){
		P2_2 = 1;	
		P2_3 = 1;
		P2_4 = 1;
		P2_5 = 1;
		P2_6 = 1;
		P2_7 = 1;
		P1_7 = 1;
}
void main (void)
{
	tx = 1;
	P2_0 = 1;
	P2_1 = 0;
	
	while(1){
	if (P1_0==0){
		resetLED ( );
		P1_7 = 0;
		P2_3 = 0;
		P2_4 = 0;
		P2_5 = 0;
		P2_6 = 0;
		P2_7 = 0;
		tx_byte(0);
		}
	if (P1_1 == 0){
		resetLED ( );
		P2_6 = 0;
		P2_7 = 0;
		tx_byte(255);
		}
	if (P1_2 == 0){
		resetLED ( );
		P2_5 = 0;
		P2_6 = 0;
		P2_2 = 0;
		P2_3 = 0;
		P2_4 = 0;
		tx_byte(6);
		}
	if (P1_3 == 0){
		resetLED ( );
		P2_5 = 0;
		P2_6 = 0;
		P2_2 = 0;
		P2_4 = 0;
		P2_7 = 0;
		tx_byte(102);
		}	
	if (P1_4 == 0){
		resetLED ( );
		P1_7 = 0;
		P2_7 = 0;
		P2_6 = 0;
		P2_2 = 0;
		tx_byte(24);	
		}
	if (P1_5 == 0){
		resetLED ( );
		P2_5 = 0;
		P2_2 = 0;
		P1_7 = 0;
		P2_4 = 0;
		P2_7 = 0;
		P2_2 = 0;
		buzz = 1;

_asm
	mov R2, #90
L3: mov R1, #250
L2: mov R0, #100
L1: djnz R0, L1
	djnz R1, L2
	djnz R2, L3
_endasm;

		buzz = 0;
		tx_byte(242);	
		}
	if (P1_6 == 0){
		resetLED ( );
		P2_5 = 0;
		P2_2 = 0;
		P1_7 = 0;
		P2_4 = 0;
		P2_7 = 0;
		P2_2 = 0;
		P2_3 = 0;	
		tx_byte(60);
		}
}
}
