
SYSCTL_RCGCGPIO_R       EQU  0x400FE608 
SYSCTL_RCC_R            EQU  0x400FE060 
GPIO_PORTA_DIR_R       	EQU  0x40004400 
GPIO_PORTA_DATA_R       EQU  0x400043FC 
GPIO_PORTA_DEN_R       	EQU  0x4000451C 	
GPIO_PORTD_DATA_R       EQU  0x400073FC 
GPIO_PORTD_DIR_R       	EQU  0x40007400 
GPIO_PORTD_DEN_R       	EQU  0x4000751C 	
	AREA MyData, DATA, READWRITE, ALIGN = 2 
RFlag	  		DCB	1
Key		  		DCB 1
Key_ASCII 		DCB 1
Num				DCB 1
	THUMB
	AREA MyCode, CODE, READONLY, ALIGN=2 
	EXPORT Init_Keypad
	EXPORT Read_Key
	EXPORT Scan_Keypad
	EXPORT Display_Digit
	EXPORT Scan_Col_0
	EXPORT Scan_Col_1
	EXPORT Scan_Col_2
	EXPORT Scan_Col_3
	EXPORT Read_PortD
	EXPORT Key_ASCII
	EXPORT Scan_Keypad_no_loop
		
	IMPORT Init_Ports_LCD
	IMPORT Display_Msg
	IMPORT Display_Char
	IMPORT Set_Position
	IMPORT WriteData
	IMPORT WriteCMD
	IMPORT SplitNum
	IMPORT Init_LCD
	IMPORT Init_Clock
	IMPORT Delay1ms
Msg_hd1 DCB    "Key Enter :", 0

Init_Keypad
	PUSH {R1, R0}
	LDR R0, =SYSCTL_RCGCGPIO_R ; Activating Port D’s clock
	LDR R1, [R0]
	ORR R1, #0x08
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTD_DIR_R ; Low nibble is input
	LDR R1, [R0]
	BIC R1, #0x0F
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTD_DEN_R ; Low nibble is digital
	LDR R1, [R0]
	ORR R1, #0x0F
	STR R1, [R0]
	POP {R1, R0}
	BX 	LR
	LTORG
	
;Reads the key
Read_Key
	PUSH		{LR, R1, R2}
	BL			Scan_Keypad   ;scans the keypad for the first digit
	MOV			R1, #0x0D	  ;set the position of the first digit
	BL			Display_Digit ;display the digit
	LDR			R1, =Key_ASCII
	LDRB		R2, [R1]
	LSL			R2, #8
	BL			Scan_Keypad	  ;scan the keypad for the second digit
	MOV			R1, #0x0E     ;set the position of the first digit
	BL			Display_Digit ;display the second digit
	LDR			R1, =Key_ASCII
	LDRB		R0, [R1]
	ADD			R0, R0, R2
	POP			{LR, R1, R2}
	BX			LR
	
Scan_Keypad
	PUSH	{LR, R0, R1, R2}
Scan_Keypad_loop
	BL 		Scan_Col_0			;scans the first collumn
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F		;take off the first half byte
	CMP		R1, #0x00			;compares the flag to 0
	BNE		Scan_Keypad_done    ;if the flag is not equeal then end the subroutine
	BL 		Scan_Col_1			;else continue to scannig of the second collumn
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_done
	BL 		Scan_Col_2
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_done
	BL 		Scan_Col_3
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_done
	B		Scan_Keypad_loop
Scan_Keypad_done	
	POP		{LR, R0, R1, R2}
	BX		LR	
	
;subroutine that only scans the keypad once
Scan_Keypad_no_loop
	PUSH	{LR, R0, R1, R2}
	
	LDR		R0, =Key_ASCII   	;set Key_ASCII to 0
	MOV		R1, #0x00
	STR		R1, [R0]
	
	BL 		Scan_Col_0			;scans the first collumn
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F		;take off the first half byte
	CMP		R1, #0x00			;compares the flag to 0
	BNE		Scan_Keypad_no_loop_done    ;if the flag is not equeal then end the subroutine
	BL 		Scan_Col_1			;else continue to scannig of the second collumn
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_no_loop_done
	BL 		Scan_Col_2
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_no_loop_done
	BL 		Scan_Col_3
	LDR		R0, =RFlag
	LDR		R1, [R0]
	AND		R1, R1, #0x0F
	CMP		R1, #0x00
	BNE		Scan_Keypad_no_loop_done
Scan_Keypad_no_loop_done	
	POP		{LR, R0, R1, R2}
	BX		LR	


Display_Digit
	PUSH 	{LR, R0, R1}
	BL		Set_Position	   ;set position of pacific time
	LDR		R0, =Key_ASCII
	BL		Display_Msg	       ;display pacific time
	POP		{LR, R0, R1}
	BX		LR
	

; Subroutine Scan_Col_0 - scans column 0
;******************************************************************************************
Scan_Col_0
	PUSH	{LR, R1, R0}
	MOV		R1, #0x04	; PA2 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_0_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_1
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_4
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_7
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_star
	B		Scan_Col_0_done	;
Found_key_1
	LDR		R0, =Key_ASCII
	MOV		R1, #0x31
	STR		R1, [R0]
	B			Scan_Col_0_done	; 
Found_key_4
	LDR		R0, =Key_ASCII
	MOV		R1, #0x34
	STR		R1, [R0]
	B			Scan_Col_0_done	;
Found_key_7
	LDR		R0, =Key_ASCII
	MOV		R1, #0x37
	STR		R1, [R0]
	B		Scan_Col_0_done	;
Found_key_star
	LDR		R0, =Key_ASCII
	MOV		R1, #0x2A
	STR		R1, [R0]
Scan_Col_0_done
	POP		{LR, R1, R0}
	BX		LR
	

; Subroutine Scan_Col_1 - scans column 1
;******************************************************************************************
Scan_Col_1
	PUSH	{LR, R1, R0}
	MOV		R1, #0x08	; PA3 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_1_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_2
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_5
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_8
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_0
	B		Scan_Col_1_done	;
Found_key_2
	LDR		R0, =Key_ASCII
	MOV		R1, #0x32
	STR		R1, [R0]
	B		Scan_Col_1_done	; 
Found_key_5
	LDR		R0, =Key_ASCII
	MOV		R1, #0x35
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_8
	LDR		R0, =Key_ASCII
	MOV		R1, #0x38
	STR		R1, [R0]
	B		Scan_Col_1_done	;
Found_key_0
	LDR		R0, =Key_ASCII
	MOV		R1, #0x30
	STR		R1, [R0]
Scan_Col_1_done
	POP		{LR, R1, R0}
	BX		LR


	
; Subroutine Scan_Col_2 - scans column 2
;******************************************************************************************
Scan_Col_2
	PUSH	{LR, R1, R0}
	MOV		R1, #0x10	; PA4 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_2_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_3
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_6
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_9
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_HashTag
	B		Scan_Col_2_done	;
Found_key_3
	LDR		R0, =Key_ASCII
	MOV		R1, #0x33
	STR		R1, [R0]
	B		Scan_Col_2_done	; 
Found_key_6
	LDR		R0, =Key_ASCII
	MOV		R1, #0x36
	STR		R1, [R0]
	B		Scan_Col_2_done	;
Found_key_9
	LDR		R0, =Key_ASCII
	MOV		R1, #0x39
	STR		R1, [R0]
	B		Scan_Col_2_done	;
Found_key_HashTag
	LDR		R0, =Key_ASCII
	MOV		R1, #0x23
	STR		R1, [R0]
Scan_Col_2_done
	POP		{LR, R1, R0}
	BX		LR
	
	
; Subroutine Scan_Col_3 - scans column 3
;******************************************************************************************
Scan_Col_3
	PUSH	{LR, R1, R0}
	MOV		R1, #0x20	; PA4 = 1
	LDR		R0, =GPIO_PORTA_DATA_R
	STRB	R1, [R0]
	
	BL		Read_PortD	;
	LDR		R0, =RFlag		; check the flag
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Scan_Col_3_done	;
	
	LDR		R0, =Key
	LDR		R1, [R0]
	AND		R1, #0x0F	; we care only about the low nibble of port 
	CMP		R1, #0x01	; check for Row 0
	BEQ		Found_key_A
	CMP		R1, #0x02	; check for Row 1
	BEQ		Found_key_B
	CMP		R1, #0x04	; check for Row	2
	BEQ		Found_key_C
	CMP		R1, #0x08	; check for Row 3
	BEQ		Found_key_D
	B		Scan_Col_2_done	;
Found_key_A
	LDR		R0, =Key_ASCII
	MOV		R1, #0x41
	STR		R1, [R0]
	B		Scan_Col_2_done	; 
Found_key_B
	LDR		R0, =Key_ASCII
	MOV		R1, #0x42
	STR		R1, [R0]
	B		Scan_Col_2_done	;
Found_key_C
	LDR		R0, =Key_ASCII
	MOV		R1, #0x43
	STR		R1, [R0]
	B		Scan_Col_2_done	;
Found_key_D
	LDR		R0, =Key_ASCII
	MOV		R1, #0x44
	STR		R1, [R0]
Scan_Col_3_done
	POP		{LR, R1, R0}
	BX		LR
	
	
Read_PortD
	PUSH	{LR, R0, R1, R2}
	LDR		R0, =RFlag
	MOV		R1, #0x00
	STRB	R1, [R0]
Read_PortD_loop	
	LDR		R0, =GPIO_PORTD_DATA_R
	LDR		R1, [R0]
	CMP		R1, #0x00
	BEQ		Read_PortD_done
	MOV		R0,	#90		;
	BL		Delay1ms	; wait for 90 ms
	LDR 	R0, =GPIO_PORTD_DATA_R
	LDR		R2, [R0]
	CMP		R1, R2
	BNE		Read_PortD_loop
	LDR		R0, =RFlag
	MOV		R1, #0x01
	STRB	R1, [R0]
	LDR		R0, =Key
	STRB	R2, [R0]
Read_PortD_done	
	POP		{LR, R0, R1, R2}
	BX		LR 
	
