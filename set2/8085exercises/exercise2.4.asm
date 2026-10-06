START:
	LDA 2000H	; load input

	MOV B,A		; save input
	ANI 01H 	; isolate B0
	MOV C,A		; C= 0000000(B0)
	MOV A,B		; restore input
	ANI 02H 	; isolate A0
	RRC		; A= 0000000(A0)
	ANA C		; A= 0000000(B0*A0)
	MOV C,A		; C= 0000000(B0*A0) 

	MOV A,B		; restore input
	ANI 04H		; isolate B1
	MOV D,A		; D= 00000(B1)00
	MOV A,B 	; restore input
	ANI 08H		; isolate A1
	RRC		; A= 00000(A1)00
	ANA D		; A= 00000(B1*A1)00
	RRC		; A= 000000(B1*A1)0
	MOV D,A		; D= 000000(X1)0

	RRC		; A= 0000000(B1*A1)
	ORA C		; A= 0000000(X0)
	ADD D		; A= 000000(X1)(X0)
	MOV C,A		; C= 000000(X1)(X0)

	MOV A,B		; restore input
	ANI 10H		; isolate B2
	MOV D,A		; D= 000(B2)0000
	MOV A,B		; restore input
	ANI 20H		; isolate A2
	RRC		; A= 000(A2)0000
	XRA D		; A= 000(B2 XOR A2)0000
	RRC		; A= 0000(B2 XOR A2)000
	RRC		; A= 00000(B2 XOR A2)00
	MOV D,A		; D= 00000(B2 XOR A2)00

	MOV A,B 	; restore input
	ANI 40H		; isolate B3
	MOV E,A		; E= 0(B3)000000
	MOV A,B 	; restore input
	ANI 80H		; isolate A3
	RRC 		; A= 0(A3)000000
	XRA E		; A= 0(B3 XOR A3)000000
	RRC
	RRC
	RRC		; A= 0000(B3 XOR A3)000
	MOV E,A		; E= 0000(X3)000
	
	RRC 		; A= 00000(B3 XOR A3)00
	ORA D		; A= 00000(X2)00
	ADD E		; A= 0000(X3)(X2)00

	ADD C		; A= 0000(X3)(X2)(X1)(X0)
	CMA
	STA 3000H	; load output
	JMP START

END


	


	
	
	




	
	
	
