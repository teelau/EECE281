//  square.c: Uses timer 2 interrupt to generate a square wave in pin
//  P2.0 and a 75% duty cycle wave in pin P2.1
//  Copyright (c) 2010-2015 Jesus Calvino-Fraga
//  ~C51~

#include <C8051F38x.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define SYSCLK    48000000L // SYSCLK frequency in Hz
#define BAUDRATE  115200L   // Baud rate of UART in bps

#define OUT0 P2_0
#define OUT1 P2_1

// ANSI colors
#define	COLOR_BLACK		0
#define	COLOR_RED		1
#define	COLOR_GREEN		2
#define	COLOR_YELLOW		3
#define	COLOR_BLUE		4
#define	COLOR_MAGENTA		5
#define	COLOR_CYAN		6
#define	COLOR_WHITE		7

// Some ANSI escape sequences
#define CURSOR_ON "\x1b[?25h"
#define CURSOR_OFF "\x1b[?25l"
#define CLEAR_SCREEN "\x1b[2J"
#define GOTO_YX "\x1B[%d;%dH"
#define CLR_TO_END_LINE "\x1B[K"

/* Black foreground, white background */
#define BKF_WTB "\x1B[0;30;47m"
#define FORE_BACK "\x1B[0;3%d;4%dm"
#define FONT_SELECT "\x1B[%dm"

volatile unsigned char pwm_count=0;
volatile unsigned int forward=0; // forward
volatile unsigned int reverse=0; // reverse

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
	SCON = 0x52; // this enables serial reception
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
	P2MDOUT|=0b_0000_0011;
	P0MDOUT |= 0x10; // Enable UTX as push-pull output
	XBR0     = 0x01; // Enable UART on P0.4(TX) and P0.5(RX)                     
	XBR1     = 0x40; // Enable crossbar and weak pull-ups

	// Initialize timer 2 for periodic interrupts
	TMR2CN=0x00;   // Stop Timer2; Clear TF2;
	CKCON|=0b_0001_0000;
	TMR2RL=(-(SYSCLK/(2*48))/(100L)); // Initialize reload value
	TMR2=0xffff;   // Set to reload immediately
	ET2=1;         // Enable Timer2 interrupts
	TR2=1;         // Start Timer2

	EA=1; // Enable interrupts
	
	return 0;
}


void Timer2_ISR (void) interrupt 5
{
	TF2H = 0; // Clear Timer2 interrupt flag
	
	pwm_count++;
	if(pwm_count>100) pwm_count=0;
	
	OUT0=pwm_count>forward?0:1; // forward
	OUT1=pwm_count>reverse?0:1; // reverse
}

void main (void)
{
	char direction[25]; // user choice
	int count_limit=0; // magnitude

	while(1)
	{   
    	printf("\x1b[2J"); // Clear screen using ANSI escape sequence.
		printf("\n\r");
		
		printf( " ษออออออออออออออออออหออออออออออออป\n" );
	    printf( " บ Speed:           บ            บ\n" );
	    printf( " ฬออออออออออออออออออฮออออออออออออน\n" );
	    printf( " บ Direction:       บ            บ\n" );
	    printf( " ศออออออออออออออออออสออออออออออออผ\n" );
	    
        printf( GOTO_YX , 3, 26);
	    printf( FORE_BACK , COLOR_GREEN, COLOR_WHITE );
	    printf("%d", count_limit);
		
		printf("\n\n\r How Fast?   ");
		scanf("%d", &count_limit); // speed
		printf("\n\r Which Direction?   ");
		scanf("%s", &direction); // direction - forward, reverse
		
		printf("\n\n\r");
		
		if( strcmp(direction, "reverse") == 0 ){
			reverse = count_limit; // yellow
			forward = 0;
		    printf( FORE_BACK , COLOR_CYAN, COLOR_WHITE );
		    printf( GOTO_YX , 5, 23);
		    printf("reverse");
		}
		else if( strcmp(direction, "gotta_go_fast") == 0){
			forward = 100;
			reverse = 0;
		    printf( FORE_BACK , COLOR_CYAN, COLOR_WHITE );
		    printf( GOTO_YX , 5, 23);
		    printf("FAST");
		}
		else if( strcmp(direction, "stop") == 0){
			forward = 0;
			reverse = 0;
		    printf( FORE_BACK , COLOR_CYAN, COLOR_WHITE );
		    printf( GOTO_YX , 5, 23);
		    printf("STOP");
		}
		else{
			forward = count_limit; // blue
			reverse = 0;
		    printf( FORE_BACK , COLOR_CYAN, COLOR_WHITE );
		    printf( GOTO_YX , 5, 23);
		    printf("forward");
		}
    	
	}
}
