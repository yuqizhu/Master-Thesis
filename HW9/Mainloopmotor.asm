Name Mainloopmotor

; This is the mainloop of the parse routines

; Revision History
;   4/02/2013 Yuqi Zhu Initial Revision




; The locally included files
$INCLUDE(Keypad.inc)




CGROUP GROUP CODE
DGROUP GROUP DATA, STACK





; the code segment starts
CODE SEGMENT PUBLIC 'CODE'

     ASSUME CS:CGROUP, DS:DGROUP, SS:DGROUP

; external function declaration
     EXTRN InitParse:NEAR              ; Initialization of parser functions
     EXTRN InitSerial:NEAR             ; Initialization of the serial functions   
     EXTRN InitMotor:NEAR              ; Initialization of the motor functions
     EXTRN InitTimer0:NEAR             ; Initialization of Timer0 interrupt, which controls the motor
     EXTRN InstallTimer0Handler:NEAR   ; Install the handler for timer0
     EXTRN InitINT2:NEAR               ; Install the interrupt 2 interrupt, which controls the serial channel
     EXTRN InstallINT2Handler:NEAR     ; Install the handler for the interrupt 2

     EXTRN InitCS:NEAR                 ; Initialization of the chip select units
     EXTRN ClrIRQVectors:NEAR          ; Clear the unused slots in the interrupt vector table
     EXTRN SerialInRdy                 ; The function that judges whether the input queue is ready
     EXTRN GetMotorSpeed               ; Get the current speed of the motor 
     EXTRN GetMotorDirection           ; Get the current direction of the motor
     EXTRN SerialGetChar               ; The function that get the next character on the input queue
     EXTRN SerialOutRdy                ; Judge whether the output queue is ready
     EXTRN SerialPutchar               ; Put the next character onto the output queue 
START:  

MAIN:
        MOV     AX, DGROUP            ;initialize the stack segment
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack) ;Sets SP to be the start of the 
                                              ;stack
        
        MOV     AX, DGROUP            ;initialize the data segment
        MOV     DS, AX

        CALL    InitParse             ; Initialize the parser functions
        CALL    InitMotor             ; Initialize the motor functions
        CALL    InitSerial            ; Initialize the serial functions
        CALL    InitINT2              ; Initialize the interrupt 2
        CALL    InstallINT2Handler    ; Install the handler for the interrupt 2
        CALL    InitTimer0            ; Initialize the timer0
        CALL    InstallTimer0Handler  ; Install the handler for the timer0

        CALL    InitCS                ; Initialize the chip select units
        CALL    ClrIRQVectors         ; Clear the unused slots in the interrupt vector table
        STI
DataFunctions:
        CALL    SerialInRdy           ; Check if there's a data available 
        JZ      DataFunctions         ; If not, go back to the first step
        CALL    SerialGerChar         ; Get the character from the input queue 
        CMP     AL, 'b'               ; If the user requires the current speed
        JZ      Getspeedpart          ; Output the current speed to the serial
        CMP     AL, 'a'               ; If the user requires the current direction
        JZ      Getdirectionpart      ; Output the current direction to the serial channel
        JMP     MotorPart             ; Otherwise, parse the input using parser

GetSpeedPart:
        CALL    SerialOutRdy          ; Check if the input serial channel is ready to accept another character    
        JNZ     Getspeedpart
        CALL    GetMotorSpeed         ; If so, output the current speed to the serial
        MOV     BX, AX
        MOV     AL, BL
        CALL    SerialPutChar
        MOV     AL, BH
        CALL    SerialPutChar
        JMP     DataFunctions         ; Go back to the first step 

GetDirectionPart:
        CALL    SerialOutRdy          ; Check if the input serial channel is ready to accept another character 
        JNZ     GetDirectionpart
        CALL    GetMotorDirection     ; If so, output the current direction to the serial
        MOV     BX, AX
        MOV     AL, BL
        CALL    SerialPutChar
        MOV     AL, BH
        CALL    SerialPutChar
        JMP     DataFunctions         ; Go back to the first step
MotorPart:
        CALL    ParseSerialChar       ; Parse the input using parser
        JMP     DataFunctions         ; Go back to the first step after finishes
 
CODE    ENDS


; the data segment
DATA SEGMENT PUBLIC 'DATA'            ;setup DGROUP

DATA ENDS

; the stack segment
STACK  SEGMENT STACK 'STACK'
                DB 80 DUP ('Stack ')  ;240 words
                
TopOfStack LABEL  WORD                ; The label for the start of the stack

STACK  ENDS
  
  
  
       END START
