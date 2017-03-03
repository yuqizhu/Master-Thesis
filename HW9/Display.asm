 NAME    DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Display                                  ;
;                              Display Functions                             ;
;                                   EEgCS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for displaying strings on 7-segment LED 
; displays. The public functions included are:
; InitDisplay   - Initialize the display and shared variables
; Display       - Display the string
; DisplayHex    - Display the Hexdecimal representation of the value
; DisplayNum    - Display the Decimal representation of the value
; DisplayMux    - The multiplex function that's called by the timer event handler
;                 to display strings on 7-segment LED display
;
; The local functions included are:
; Store:        - Store the pattern of the character 
;
; Revision History:
;     11/10/2012 Yuqi Zhu
;     11/11/2012 Yuqi Zhu
;     11/12/2012 Yuqi Zhu
;     11/13/2012 Yuqi Zhu
;     11/14/2012 Yuqi Zhu
;





; local include files
$INCLUDE (display.inc)
$INCLUDE (timer.inc)





CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


; the code segment

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP





; external function declarations

        EXTRN  Dec2String:NEAR          ; Conversion Routine, convert the 16-bit signed value into a string of 
                                        ; its decimal representation
        EXTRN  Hex2String:NEAR          ; Conversion Routine, convert the 16-bit unsigned value into a string of
                                        ; its hexadecimal representaion
        EXTRN  ASCIISegTable:BYTE       ; Table contains the patterns ASCII characters

    




        
; InitDisplay
;
; Description: This function initializes the display and its shared variables.
;
; Operation: This function sets counter to 0 so that the display function will start from the first LED digit and 
;            first pattern in the buffer. The buffer is then initialized so that all of its entries become 0.
;
; Arguments: None
; Return Value: None
;
; Local Variables:  CX - Buffer_Size Counter
;                   DI - string buffer pointer
;                   
; Shared Variables: Buffer  - buffer used to store patterns of characters
;                   Counter - The index of the current LED digit being activated and the current pattern in the buffer
;                             being handled
; Global Variables: None
;
; Input: None 
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: flags, DI, CX, AL
;
; Author: Yuqi Zhu
; Last Modified:
;    11/14/2012


Initdisplay PROC NEAR
            PUBLIC Initdisplay

InitdisplayBody:                   ; Initialize the registers and shared variables
    MOV Counter, 0                 ; Start from the first LED digit and first pattern in the buffer
    MOV DI, OFFSET(Buffer)         ; Store the buffer pointer into DI
    MOV CX, Buffer_Size            ; Setup the counter for the loop to clear the buffer
CLRBuffer:                         ; Clear the buffer
    XOR AL, AL                     ; Set AL to 0
    MOV [DI], AL                   ; Clear the current entry of the buffer
    INC DI                         ; Move the pointer to the next entry
    LOOP CLRBuffer                 ; Loop clearing the buffer
EndInit:                           ; Set DI back to the buffer pointer and return 
    MOV DI, OFFSET(Buffer)         
    RET
Initdisplay ENDP   





; Display 
;
; Description: This function is passed a <NULL> terminated string and stores its pattern into the buffer.
;              The string can not have more than 15 characters.
;
; Operation: Clear the buffer before store the patterns. Get each character of the string and retrieve its pattern from the 
;            ASCII segment table and store the pattern into the display buffer. The size of the string is limited to 15 
;            characters.
;           
; Arguments: ES:SI - The string passed by reference
; Return Value: None
;
; Local Variables:  DI - The buffer pointer
;                   CX - The size of the buffer
;                   SI - The string pointer                  
;
; Shared Variables: Buffer - Buffer used to store the pattern of characters
;                   
; Global Variables: None
;
; Input: None 
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Limitations: Can only handle strings with less than 16 characters.
;
; Registers Changed: flags, DI, CX, AL, SI
;
; Author: Yuqi Zhu
; Last Modified:
; 11/14/2012

Display PROC NEAR
        PUBLIC Display

InitBody:                  ; Initialize the registers
    MOV DI, OFFSET(Buffer)        ; Store the pointer of buffer into DI
    MOV CX, Buffer_size           ; Store the size of the buffer into CX, prepareing for the loop clearing
                                  ; of the buffer
       
CLRBody:                          ; Clear the entries of the buffer
    XOR AL, AL                    ; Set AL to 0
    MOV [DI], AL                  ; Use AL to clear the buffer
    INC DI                        ; Move the pointer
    LOOP CLRBody                  ; Loop clearing the buffer
    MOV DI, OFFSET(Buffer)        ; Move the pointer back to the beginning of the buffer

GettingPattern:                   ; Storing the pattern into the buffer
    MOV AL, ES:[SI]               ; Retrieve the character
    CMP AL, 0                     ; Check if it's the NULL terminator
    JE EndDisplay                 ; If so, we are done
    CALL Store                    ; Otherwise, we call the store function to store the corresponding 
                                  ; pattern into buffer
    INC SI                        ; Move to the next character
    JMP GettingPattern           
    
EndDisplay:                       ; Done with storing and return
    RET

Display    ENDP
        


; Store
;
; Description: This function is called by display and store the 7-segment pattern of passed character into buffer
;
; Operation: This functions retrieve the 7-segment pattern of the passed ASCII character from the ASCII segment table
;            and store it into the passed address in the buffer.
;             
; Arguments: AL - The ASCII character
;            DI - Place to store the pattern in the buffer
; Return Value: None
;
; Local Variables: AL  - The pattern of the passed ASCII character
;                  DI  - The pointer of the buffer
; Shared Variables: None
; Global Variables: None
;
; Input: None
; Output: None 
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: BX, AL, DI 
;
; Limitations : Not able to store the pattern when the buffer is full.
;
; Author: Yuqi Zhu
; Last Modified:
; 11/14/2012

Store PROC NEAR            ; This function retrieves the pattern of ASCII character and stores it into the buffer
  LEA BX, ASCIISegTable    ; Setup for retrieving the pattern
  XLAT ASCIISegTable       ; Put the pattern into AL
  MOV  [DI], AL            ; Store the pattern into the passed place in AL
  INC DI                   ; Move the buffer pointer to the next place
  RET                      ; Done and return
Store  ENDP



; DisplayNum
;
; Description: This function is passed a 16-bit signed value and stores the pattern of its decimal representation into
;              the buffer. 
;
; Operation:   Call the Dec2string to convert the 16-bit signed binary number to string of its decimal representation 
;              and store it into the string buffer. Copy the value of DS into ES as the string passed to display function
;              is in ES:SI. We then call the display function to store its pattern into the pattern buffer.
;
; Arguments: AX --- The 16-bit signed value
; Return Value: None
;
; Local Variables: SI - The pointer of the string buffer
; Shared Variables: String - The string buffer used to store the decimal representation of the binary number
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: SI, DS, ES
;
; Author: Yuqi Zhu
; Last Modified:
; 11/14/2012

DisplayNum PROC NEAR
        PUBLIC DisplayNum

DisplayNumBody:                      ; Call the dec2string function to store a string of decimal representation
                                     ; of the passed binary value into the string buffer and then call the display
                                     ; function to store its pattern into the pattern buffer.
    MOV SI, OFFSET(String)           ; Setup SI so that the string will be stored into the string buffer 
	CALL Dec2String              ; Call Dec2string to store the string of its decimal representation into DS:SI
	MOV SI, OFFSET(String)       ; Move the pointer to the start of the string buffer
	PUSH DS	                     ; Copy the value of DS into ES as display takes a string stored in ES:SI
	POP ES
    CALL Display                     ; Call the display function to store the pattern into buffer
    RET                              ; Done and return

DisplayNum    ENDP
        


; DisplayHex
;
; Description: This function is passed a 16-bit unsigned binary value and stores the pattern of its hexadecimal representation 
;              into the buffer.
;
; Operation:   Call the Hex2string to convert the 16-bit unsigned binary number to string of its hexadecimal representation 
;              and store it into the string buffer. Copy the value of DS into ES as the string passed to display function
;              is in ES:SI. We then call the display function to store its pattern into the pattern buffer.
;
; Arguments: AX --- The 16-bit unsigned value
; Return Value: None
;
; Local Variables: SI - The pointer of the string buffer
; Shared Variables: String - The string buffer used to store the hexadecimal representation of the binary number
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: SI, DS, ES
;
; Author: Yuqi Zhu
; Last Modified:
; 11/14/2012

DisplayHex PROC NEAR
        PUBLIC DisplayHex

DisplayHexBody:                        ; Call the Hex2string function to store a string of hexadecimal representation
                                       ; of the passed unsigned binary value into the string buffer and then call the
                                       ; display function to store its pattern into the pattern buffer.

    MOV SI, OFFSET(String)             ; Setup SI so that the string will be stored into the string buffer 
    CALL Hex2String                    ; Call Hex2string to store the string of its hexadecimal representation into DS:SI 
    MOV SI, OFFSET(String)             ; Move the pointer to the start of the string buffer
    PUSH DS                            ; Copy the value of DS into ES as display takes a string stored in ES:SI
    POP  ES
    CALL Display                       ; Call the display function to store the pattern into buffer

    RET                                ; Done and return

DisplayHex    ENDP



; DisplayMux
;
; Description: This function is the multiplex function that displays the pattern stored in the buffer on the LED
;              display one by one. This function is called by the timer event handler every 1 ms
;
; Operation:  This function displays the pattern to the corresponding LED digit one by one every 1 ms. So it looks
;             like all of the digits are lighting up at the same time. 
; Arguments:    None 
; Return Value: None
;
; Local Variables:  None
; Shared Variables: Counter - the index of the current LED digit and the current pattern in the buffer
;                   Buffer  - the buffer of the pattern
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Limitations: Only the first 8 characters in the string will be displayed.
;
;Registers Changed: DX, AL,  
;
; Author: Yuqi Zhu
; Last Modified:
; 11/14/2012



DisplayMux PROC NEAR
      PUBLIC DisplayMux
      
DisplayMuxBody:                     ; Display the current pattern in the buffer to the corresponding LED digit 
                                    ; If reaches the last digit, then reset the counter to go back to the first 
                                    ; digit; if not, we move to the next digit.
    PUSH BX                         ; Save the value in BX
    MOV DX, LEDDisplay              ; Set DX to the address of the LEDdisplay
    ADD DX, Counter                 ; Add counter to DX, so DX becomes the address of the current LED digit 
    MOV BX, Counter                 ; Setup BX to retrieve the current pattern to AL
    MOV AL, Buffer[BX] 
    OUT DX, AL
    INC Counter                     ; Increment the counter
    CMP Counter, NUM_Digit          ; If we goes beyond the last digit, then we move back the first digit
    JNE ENDMux                      ; Otherwise, we are done.
    MOV Counter, 0
    
ENDMux:                             ; Pop the value back to BX and return.          
   POP BX 
   RET
    
DisplayMux   ENDP



CODE ENDS
  
; the data segment
DATA SEGMENT PUBLIC 'DATA'                    
    String DB String_Size DUP (?)   ; String buffer used to store the converted decimal representation of hexadecimal representation
    Buffer DB Buffer_Size DUP (?)   ; Buffer used to store the pattern of the characters 
    Counter DW ?                    ; Counter of the current LED digit being activated
DATA ENDS
     END
