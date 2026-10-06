START:
	MVI B,FEH	; B= 11111110
	LDA 2000H	; load input
	ORA A		; set flags from A
	JZ ALL_ZEROS	; if (input==0), all LEDs off
	
LOOP1:
	RRC		; CY= LSB
	JC FOUND	; if (LSB==1), found 1 
	MOV E,A		; save A
	MOV A,B	
	RLC		; rotate B
	MOV B,A
	MOV A,E 	; restore A
	JMP LOOP1	; loop

FOUND:
	MOV A,B	; A= B
	STA 3000H	; load output
	JMP START

ALL_ZEROS:
	CMA		; A= 11111111
	STA 3000H	; load output
	JMP START

END

