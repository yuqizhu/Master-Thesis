NAME CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; file description including table of contents
;
; Revision History:
;     1/26/06  Glen George      initial revision


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

$INCLUDE(converts.inc)
$INCLUDE(constant.inc)

; Dec2String
;
; Description:      This function converts a 16-bit value to a decimal value and stores it as a string at the 
;                   specified address. The string is terminated by a <null> terminated decimal representation
;                   of the value in ASCII.
;
; Operation:        The function starts with the largest power of 10 possible and uses that to divide the given 
;                   value. We converted the quotient to character using ASCII and stored it at the specified 
;                   location. The remainder of the division will be used for the next iteration. Each time, we 
;                   will decrease our power by 10 and use the updated power to divide the remainder until the 
;                   remainder is 0. 
;
; Arguments:        AX --- Binary value to convert to decimal
;                   SI --- The address to store the string.
; Return Value:     None
;
; Local Variables: 
;                   arg (DI) --- Copy of the signed Binary value to compute
;                   digit (AX) --- The current computed digit   
;                   pwr10 (CX) --- Power of 10
;                   memorylocation (SI) --- The current location to store the character
; Shared Variables: None
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling:   None
;
; Algorithms:       Store the sign into the memory. Repeatedly divide by power of 10 and store the digit at 
;                   the corresponding place. The remainder is used for the next iteration.
; Data Structures:  None
;
; Registers Changed: None
; Stack Depth:      None
;
; Author: Yuqi Zhu
; Last Modified:    Oct 31st, 2012




Dec2String      PROC    NEAR
                PUBLIC  Dec2String

Dec2StringInit:                         ; initialization
        MOV     DI, AX                  ; DI = arg
        MOV     CX, 10000               ; start with 10^4 (10000's digit)

Dec2StringSign:
        CMP     DI, 0                   ; Compare the two digits
        JL      WriteNSign              ; Write the Negative Sign if the number is negative
        JGE     WritePSign              ; Write the Positive Sign if the number is positive
 
WriteNSign:
        MOV     Byte PTR [SI], NSignASCII   ; Write the negative sign 
        INC     SI                      ; Add 1 to the MemoryLocation 
		JMP     UnsignedConvert         ; Convert the argument to its absolute value.

WritePSign:
        MOV     Byte PTR [SI], PSignASCII   ; Write the positive sign
        INC     SI                      ; Add 1 to the MemoryLocation
        JMP     Dec2StringLoop          ; Start process the digit
		
UnsignedConvert:
        NOT     DI
		INC     DI
		JMP     Dec2StringLoop

Dec2StringLoop:                         ; loop getting the digits in arg

        CMP     CX, 0                   ; check if pwr10 > 0
        JBE      EndDec2StringLoop      ; if not, have done all digits, done
        ;JA    Dec2StringLoopBody       ; else get the next digit

Dec2StringLoopBody:                     ; get a digit
        MOV     DX, 0                   ; setup for arg/pwr10
        MOV     AX, DI
        DIV     CX                      ; digit (AX) = arg/pwr10
        ;JB     DecWriteDigit           ; process the digit

DecWriteDigit:                          ; write the digit as a string
        ADD     AX, ASCIIDigitConvert   ; Convert to String using ASCII
        MOV     BYTE PTR [SI],  AL      ; Write the String
        INC     SI                      ; Increment the memory location
        MOV     DI, DX                  ; now work with arg = arg MODULO pwr10
        MOV     DX, 0                   ; setup to update pwr10
		MOV     AX, CX                  
        MOV     CX, 10                  
        DIV     CX                      
        MOV     CX, AX                  ; pwr10 = pwr10/10 
        JMP     EndDec2StringLoopBody   ; done getting this digit


EndDec2StringLoopBody:
        JMP     Dec2StringLoop          ; keep looping (end check is at top)


EndDec2StringLoop:                      ; done converting
        MOV     BYTE PTR [SI], 0        ; add NULL character at the end
        RET                             ; and return



Dec2String         ENDP


; Hex2String
;
; Description:      This function converts a 16-bit value to a hexadecimal value and stores it as a string at
;                   the specified address. The string is terminated by a <null> terminated decimal representation 
;                   of the value in ASCII
;
; Operation:        The function starts with the largest power of 16 possible and uses that to divide the given value. 
;                   We converted the quotient to character using ASCII and stored it at the specified location. The 
;                   remainder of the division will be used for the next iteration. Each time, we will decrease our power 
;                   by 16 and use the updated power to divide the remainder until the remainder is 0.
;
; Arguments:        AX --- Binary value to convert to hexadecimal
;                   SI --- The address to store the string.
; Return Value:     None
;
; Local Variables: 
;                   arg   (DI) --- Copy of the Binary value to compute
;                   digit (AX) --- The current computed digit   
;                   pwr16 (CX) --- Power of 16
;                   memorylocation(SI) --- The current memory location to store the character.
; Shared Variables: None
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling:   None
;
; Algorithms:       Repeatedly divide by power of 16 and use the quotient as the next digit of the result. Store the 
;                   result at the corresponding memory location.
; Data Structures:  None
;
; Registers Changed: None
; Stack Depth:      None
;
; Author:           Yuqi Zhu
; Last Modified:    Oct 31st, 2012

Hex2String      PROC        NEAR
                PUBLIC      Hex2String


Hex2StringInit:                         ; initialization
        MOV     DI, AX                  ; DI = arg
        MOV     CX, 01000h              ; start with 16^3 

Hex2StringLoop:                         ; loop getting the digits in arg

        CMP     CX, 0                   ; check if pwr16 > 0
        JBE     EndHex2StringLoop       ; if not, have done all digits, done
        ;JA     Hex2StringLoopBody      ; else get the next digit

Hex2StringLoopBody:                     ; get a digit
        MOV     DX, 0                   ; setup for arg/pwr16
        MOV     AX, DI
        DIV     CX                      ; digit (AX) = arg/pwr16
        CMP     AX, 10
        JAE     HexWriteCharacter       ; Write the character
        ;JB     HexWriteDigit           ; Write the digit 

HexWriteDigit:                          ; Write the digit
        ADD     AX, ASCIIDigitConvert   ; Transfer to String using ASCII
        MOV     Byte PTR [SI], AL       ; Store the digit
        INC     SI                      ; Increment the memory location
        JMP     SetupBody               ; Setup for the next iteration

HexWriteCharacter:                      ; Write the character
        ADD     AX, ASCIICharacterConvert ; Transfer to String using ASCII
        MOV     Byte PTR [SI], AL       ; Store the character
        INC     SI                      ; Increment the memory location
        JMP     SetupBody               ; Setup for the next iteration

SetupBody:        
        MOV     DI, DX                  ; now work with arg = arg MODULO pwr16
        MOV     DX,  0                  ; setup to update pwr16
		SHR     CX,  4                  ; pwr16 = pwr16/16
        JMP     EndHex2StringLoopBody   ; done writting this digit


EndHex2StringLoopBody:
        JMP     Hex2StringLoop          ; keep looping (end check is at top)


EndHex2StringLoop:                      ; done converting
        MOV     Byte PTR [SI], 0        ; Add Null character at the end
        RET                             ; and return

Hex2String   ENDP

CODE ENDS

     END