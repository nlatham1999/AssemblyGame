;game written in assembly

SYSCTL_RCGCGPIO_R       EQU  0x400FE608 
SYSCTL_RCC_R            EQU  0x400FE060 
GPIO_PORTA_DIR_R       	EQU  0x40004400 
GPIO_PORTA_DATA_R       EQU  0x400043FC 
GPIO_PORTA_DEN_R       	EQU  0x4000451C 
GPIO_PORTC_DIR_R       	EQU  0x40006400 
GPIO_PORTC_DATA_R       EQU  0x400063FC 
GPIO_PORTC_DEN_R       	EQU  0x4000651C 
GPIO_PORTD_DATA_R       EQU  0x400073FC 
GPIO_PORTD_DIR_R       	EQU  0x40007400 
GPIO_PORTD_DEN_R       	EQU  0x4000751C 
GPIO_PORTE_DIR_R       	EQU  0x40024400 
GPIO_PORTE_DATA_R       EQU  0x400243FC 
GPIO_PORTE_DEN_R       	EQU  0x4002451C 
Size_Cal				        EQU	 5
	AREA	 MyData, DATA, READWRITE, ALIGN = 2 
player1_position		    DCB		1
bullet_position			    DCB		1
	AREA	 MyCode, CODE, READONLY, ALIGN=2
	EXPORT	__main
player1_character       DCB "*", 0
bullets			            DCB "-", 0
reset_screen	          DCB "                ", 0

	
	IMPORT Init_Ports_LCD
	IMPORT Display_Msg
	IMPORT Set_Position
	IMPORT SplitNum
	IMPORT Init_LCD
	IMPORT Init_Clock
	IMPORT Delay1ms
	IMPORT Init_Keypad
	IMPORT Scan_Keypad
	IMPORT Key_ASCII
	IMPORT Scan_Keypad_no_loop
Msg_hd1 DCB    "Key Enter :", 0

__main
	BL 		Init_Ports_LCD  	;initialize the ports for lcd
	BL 		Init_Clock       	; intitialize the clock
	BL 		Init_LCD	     	;initialize  the lcd
	BL 		Init_Keypad			;initialize the keypad
	BL		Init_Characters 	;initilize the the characters
Forever	
	BL		Move_Character
	BL		Display_Character
	B		Forever
	
Init_Characters
	PUSH	{LR, R0-R5}
	
	LDR		R0, =player1_position
	MOV		R1, #0x03
	STRB	R1, [R0]
	
	POP		{LR, R0-R5}
	BX		LR
	
;see if a command was pressed and if so then move position
Move_Character
	PUSH	{LR, R0-R5}
	
	BL		Scan_Keypad_no_loop
	LDR		R0, =Key_ASCII
	LDR		R1, [R0]
	
	LDR		R2, =player1_position
	LDR		R3, [R2]
	MOV		R4, R3
	
	CMP		R1, #0
	BEQ		Move_Character_Done
	CMP		R1, #0x34
	BEQ		Move_Character_Left	
	CMP		R1, #0x32
	BEQ		Move_Character_Up	
	CMP		R1, #0x38
	BEQ		Move_Character_Down	
	CMP		R1, #0x36
	BEQ		Move_Character_Right
	B		  Move_Character_Done
	
Move_Character_Left
	AND		R4, #0x0000000F     
	CMP		R4, #0              ;check to see that it wont go out of bounds
	BEQ		Move_Character_Done
	SUB		R3, R3, #1
	B		  Move_Character_Done
Move_Character_Up   
	CMP		R3, #0x30              ;check to see that it wont go out of bounds
	BLO		Move_Character_Done
	SUB		R3, R3, #0x40
	B		  Move_Character_Done
Move_Character_Down
	CMP		R3, #0x30              ;check to see that it wont go out of bounds
	BHI		Move_Character_Done
	ADD		R3, R3, #0x40
	B		  Move_Character_Done
Move_Character_Right
	AND		R4, #0x0000000F     
	CMP		R4, #0x0F              ;check to see that it wont go out of bounds
	BEQ		Move_Character_Done
	ADD		R3, R3, #1
	B		  Move_Character_Done
Move_Character_Done
	STR		R3, [R2]
	POP		{LR, R0-R5}
	BX		LR
	
;displays the character
Display_Character
	PUSH	{LR, R0-R5}
	
	MOV		R1, #0x00
	BL		Set_Position
	LDR		R0, =reset_screen
	BL		Display_Msg
	MOV		R1, #0x40
	BL		Set_Position
	LDR		R0, =reset_screen
	BL		Display_Msg
	
	LDR		R0, =player1_position
	LDR		R1, [R0]
	BL		Set_Position
	
	LDR		R0, =player1_character
	BL		Display_Msg
	
	POP	  {LR, R0-R5}
	BX		LR
	
END
