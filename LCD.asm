
SYSCTL_RCGCGPIO_R       EQU  0x400FE608 
SYSCTL_RCC_R            EQU  0x400FE060 
GPIO_PORTA_DIR_R       	EQU  0x40004400 
GPIO_PORTA_DATA_R       EQU  0x400043FC 
GPIO_PORTA_DEN_R       	EQU  0x4000451C 
GPIO_PORTC_DIR_R       	EQU  0x40006400 
GPIO_PORTC_DATA_R       EQU  0x400063FC 
GPIO_PORTC_DEN_R       	EQU  0x4000651C 
GPIO_PORTE_DIR_R       	EQU  0x40024400 
GPIO_PORTE_DATA_R       EQU  0x400243FC 
GPIO_PORTE_DEN_R       	EQU  0x4002451C 

	AREA MyData, DATA, READWRITE, ALIGN = 2 
	THUMB
	AREA MyCode, CODE, READONLY, ALIGN=2 
	EXPORT Init_Ports_LCD
	EXPORT Display_Msg
	EXPORT Display_Char
	EXPORT Set_Position
	EXPORT WriteData
	EXPORT WriteCMD
	EXPORT SplitNum
	EXPORT Init_LCD
	EXPORT Init_Clock
	EXPORT Delay1ms

; Init_Ports - initializes ports A, C, and E for LCD display
Init_Ports_LCD
	LDR	R1, =SYSCTL_RCGCGPIO_R	;
	LDR	R0, [R1]
	ORR	R0, #0x17
	STR	R0, [R1]
	NOP
	NOP

	LDR	R1, =GPIO_PORTA_DIR_R
	MOV	R0, #0x3C
	STR	R0, [R1]

	LDR	R1, =GPIO_PORTA_DEN_R
	MOV	R0, #0x3C
	STR	R0, [R1]
	
	LDR	R1, =GPIO_PORTC_DIR_R
	MOV	R0, #0x40
	STR	R0, [R1]

	LDR	R1, =GPIO_PORTC_DEN_R
	MOV	R0, #0x40
	STR	R0, [R1]

	LDR	R1, =GPIO_PORTE_DIR_R
	MOV	R0, #0x01
	STR	R0, [R1]

	LDR	R1, =GPIO_PORTE_DEN_R
	MOV	R0, #0x01
	STR	R0, [R1]
	
	BX	LR

; Display_Msg - displays the message
Display_Msg
	PUSH	{LR, R0, R2}
	MOV		R2, #0x00
again 
	LDRB	R1, [R0,R2]
	
	CMP		R1, #0
	BEQ		done
	BL		Display_Char
	ADD		R2, #1
	B		again
done	
	POP		{LR, R0, R2}
	BX 		LR
	


Display_Char
	PUSH	{LR, R0, R1}
	BL		SplitNum	;
	BL		WriteData	; write upper 4 bits of ASCII byte
	MOV		R1, R0
	BL		WriteData	; write lower 4 bits of ASCII byte
	MOV		R0, #0x01	
	BL		Delay1ms	; wait for 1ms
	POP		{LR, R0, R1}
	BX		LR

; Set_Position - sets the position in R1 for displaying data in LCD

Set_Position
	PUSH	{LR, R1, R0}
	ORR		R1,	#0x80	; set b7 of R1
	BL		SplitNum	
	BL		WriteCMD	; write upper 4 bits of the command
	MOV		R1,	R0
	BL		WriteCMD	; write lower 4 bits of the command
	MOV		R0, #0x01		
	BL		Delay1ms	; wait for 1ms
	POP		{LR, R1, R0}
	BX		LR

; WriteData - sends a data (lower 4 bits) in R1 to LCD

WriteData
	PUSH	{LR, R1, R0}
	LSL		R1, R1, #2		; data from bits 2 - 5
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	LDR		R0, =GPIO_PORTE_DATA_R
	MOV		R1, #0x01	; Sending data
	STRB	R1, [R0]
	MOV		R1, #0x00	; Enabling the LCD (falling edge)
	LDR		R0,	=GPIO_PORTC_DATA_R
	STRB	R1, [R0]
	NOP
	NOP
	MOV		R1, #0x40	; Raising the edge in preparation for the next write 
	STRB	R1, [R0]
	POP		{LR, R1, R0}
	BX		LR			

; WriteCMD - sends a command (lower 4 bits) in R1 to LCD

WriteCMD 
	PUSH	{LR, R1, R0}
	LSL		R1, R1, #2		; data from bits 2 - 5
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	MOV		R1, #0x00;		; RS=0 for sending a command
	LDR		R0, =GPIO_PORTE_DATA_R
	STRB	R1, [R0]
	MOV		R1, #0x00	; Enabling the LCD
	LDR		R0, =GPIO_PORTC_DATA_R
	STRB	R1, [R0]
	NOP
	NOP
	MOV		R1, #0x40	; Raising PC6
	STRB	R1, [R0]
	POP		{LR, R1, R0}
	BX		LR

; SlipNum - separates hex numbers in R1
;	  R1 <- MS digit
;	  R0 <- LS digit

SplitNum
	PUSH	{LR}
	MOV		R0, R1
	AND		R0, #0x0F		; mask the upper 4 bits
	LSR		R1,	R1, #4 
	POP		{LR}
	BX		LR

; Init_LCD - initializes LCD according to the initializing sequence indicated
;	  by the manufacturer

Init_LCD
	PUSH	{LR}
	; wait 30ms for LCD to power up
	
	; send byte 1 of code to LCD
	MOV		R1,	#0x30	; R1 <- byte #1 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #1
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 5 ms
	
	; send byte 2 of code to LCD
	MOV		R1,	#0x30	; R1 <- byte #2 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #2
	MOV		R0,	#100		;
	BL		Delay1ms	; wait for 100 ms
	
	; send byte 3 of code to LCD
	MOV		R1,	#0x30	; R1 <- byte #3 of code: $30
	BL		SplitNum	;
	BL		WriteCMD	; write byte #3
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 1 ms
	
	
	; send byte 4 of code to LCD
	MOV		R1,	#0x20	; R1 <- byte #4 of code: $20
	BL		SplitNum	;
	BL		WriteCMD	; write byte #4
	MOV		R0,	#5		;
	BL		Delay1ms	; wait for 1 ms
	
	; send byte 5 of code to LCD
	MOV		R1,	#0x28		; R1 <- byte #5 of code: $28
				;  db5 = 1, db4 = 0 (DL = 0 - 4 bits), 
				;  db3 = 1 (N = 1 - 2 lines),
				;  db2 = 0 (F = 0 - 5x7 dots).
	BL			SplitNum	;
	BL			WriteCMD	; write upper 4 bits of byte #5
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #5
	MOV		R0,	#50	;
	BL		Delay1ms	; wait for 50ms
	
	; send byte 6 of code to LCD
	MOV		R1,	#0x0C		; R1 <- byte #6 of code: $0C
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #6
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #6
	MOV		R0,	#50		;
	BL		Delay1ms	; wait for 50ms
	
	; send byte 7 of code to LCD
	MOV		R1,	#0x01		; R1 <- byte #7 of code: $01
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #7
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #7
	MOV		R0,	#50		;
	BL		Delay1ms	; wait for 50ms
	
	; send byte 8 of code to LCD
	MOV		R1,	#0x06		; R1 <- byte #6 of code: $06
	BL		SplitNum	;
	BL		WriteCMD	; write upper 4 bits of byte #7
	MOV		R1,R0
	BL		WriteCMD	; write lower 4 bits of byte #7
	MOV		R0,	#50		;
	BL		Delay1ms	; wait for 50ms
	
	POP		{LR}
	BX		LR



Init_Clock
	; Bypass the PLL to operate at main 16MHz Osc.
	PUSH	{LR}
	LDR		R0, =SYSCTL_RCC_R
	LDR		R1, [R0]
	BIC		R1, #0x00400000 ; Clearing bit 22 (USESYSDIV)
	BIC		R1, #0x00000030	; Clearing bits 4 and 5 (OSCSRC) use main OSC
	ORR		R1, #0x00000800 ; Bypassing PLL
	
	STR		R1, [R0]
	POP		{LR}
	BX		LR

;Delay milliseconds
Delay1ms
	PUSH	{LR, R0, R3}
	MOVS	R3, R0
	BNE		L1; if n=0, return
	BX		LR; return

L1	LDR		R4, =5336
			; do inner loop 5336 times (16 MHz CPU clock)
L2	SUBS	R4, R4,#1
	BNE		L2
	SUBS		R3, R3, #1
	BNE		L1
	POP		{LR, R0, R3}
	BX			LR
	
	END
		
