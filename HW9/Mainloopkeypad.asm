Name Mainloopkeypad

; This is the mainloop of the parse routines
;
; The public function included are:
; Handlekey --- Functions that output the keycode to the serial channel and display the keycodes
; Revision History
;   12/15/2012 Yuqi Zhu Initial Revision





; The locally included files
$INCLUDE(mainloopkeypad.inc)

CGROUP GROUP CODE
DGROUP GROUP DATA, STACK





; the code segment starts
CODE SEGMENT PUBLIC 'CODE'

     ASSUME CS:CGROUP, DS:DGROUP, SS:DGROUP

; external function declaration
     EXTRN InitParse:NEAR            ; Initialization of parser functions
     EXTRN InitDisplay:NEAR          ; Initialization of the Display functions
     EXTRN InitKey:NEAR              ; Initialization of the Key Functions
     EXTRN InitSerial:NEAR           ; Initialization of the Serial Functions

     EXTRN InitTimer2:NEAR           ; Initializatoin of the timer2 
     EXTRN InstallTimer2Handler:NEAR ; Functions for installing the timer2 handler
     EXTRN InitINT2:NEAR             ; Initialization of the Interrupt 2
     EXTRN InstallINT2Handler:NEAR   ; Functions for installing the interrupt 2 handler
 
     EXTRN InitCS:NEAR               ; Initialization of the chips select
     EXTRN ClrIRQVectors:NEAR        ; Clear the unused slots in the interrupt vector table

     EXTRN SerialInRdy               ; The function that judges whether the input queue is ready
     EXTRN IsaKey                    ; The function that judges whether a key has been pressed
     EXTRN SerialGetChar             ; The function that get the next character on the input queue
     EXTRN Display                   ; The function that displays the data stored in the buffer
     EXTRN GetKey                    ; Get the key being pressed
     EXTRN SerialOutRdy              ; Judge whether the output queue is ready
     EXTRN SerialPutchar             ; Put the next character onto the output queue 

START:  

MAIN:
        MOV     AX, DGROUP            ;initialize the stack segment
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack) ;Sets SP to be the start of the 
                                              ;stack
        
        MOV     AX, DGROUP            ;initialize the data segment
        MOV     DS, AX
        
        CALL    InitDisplay           ;initialize Display, serial and key functions
        CALL    InitSerial        
        CALL    InitKey
 
        CALL    InitINT2              ; Initialize interrupt 2 and timer2 interrupt and install their handlers
        CALL    InstallINT2Handler
        CALL    InitTimer2
        CALL    InstallTimer2Handler  

        CALL    InitCS                ; Initialize the chip select 
        CALL    ClrIRQVectors         ; Clear the interrupt vector table
        
InitMain:
        MOV     Bufferend, OFFSET(DisplayBuffer) ;Initialize the buffer of display
        MOV     SI, OFFSET(DisplayBuffer)
        MOV     ES:[SI], 0            ; Clear the buffer
        STI
KeyFunctions:
        CALL    IsaKey                ; Check if there's a key being pressed
        JZ      DisplayFunctions      ; If not, skip the key handling process and jump to the display functions
Keypressed:
        
        CALL    HandleKey             ; Handle the key pressed

DisplayFunctions:
        CALL    SerialInRdy           ; Check if there's a data being transmitted
        MOV     DI, OFFSET(DisplayBuffer) ;Set DI to the address of buffer 
        JZ      KeyFunctions          ; If no data is transmitted, go back to the keyfunctions
DisplayCur:
        CALL   SerialGetChar          ; Store all the data into the buffer
        MOV    [DI], AL                
        INC    DI 
        INC    BufferEnd              ; Increment the end pointer of the buffer
        CALL   SerialInRdy             
        JNZ    DisplayCur             
        CALL   Display                ; Display the data 
        MOV    SI, OFFSET(DisplayBuffer)  ; Prepare for clear the buffer
ClearBuffer:
        MOV     ES:[SI], 0            ; Clear the buffer
        INC     SI                     
        CMP     SI, BufferEnd
        JE      EndClear              ; Reach the end of the buffer and done with clearing
        JMP     ClearBuffer     
EndClear:
        MOV    BufferEnd, OFFSET(DisplayBuffer) ; Move the end pointer to the start of the buffer
        JMP    KeyFunctions                     ; Go back to the key functions
    
; HandleKey
;
; Description: This function handle the key being processed;
; Operation: This function transmits the keycode and stores the data into the buffer and display it.
;            If the length of data exceeds the maximum length, nothing will be stored into the buffer
;            After the enter key has been pressed, the buffer will be cleared.
;
; Arguments: None
; Return Value: None
;
; Local Variables:  None
;                   
; Shared Variables: DisplayBuffer  - buffer used to store the data to display
;                   Bufferend      - the end pointer of the buffer
;                  
; Global Variables: None
;
; Input: None 
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: Array
;
; Registers Changed: flags, SI, AL
;
; Author: Yuqi Zhu
; Last Modified:
;    3/31/2013

HandleKey PROC NEAR
          PUBLIC HandleKey

        CALL    GetKey                          ; Get the key being pressed 
SerialTransmit:
        CALL    SerialOutRdy                    ; If the Tqueue is ready to transmit the data
        JNZ     SerialTransmit                  ; put the character onto the queue
        CALL    SerialPutChar 
DisplayKey:                                     ; Store the keycode into the buffer
        CALL    GetKey
        MOV     SI, OFFSET(DisplayBuffer)       
        CMP     AL, 13                          ; If it's an enter key, clear the buffer
        JE      ClearBuffer                     
        CMP     AL, '*'                         ; If it's an invalid key, do nothing
        JE      EndHandleKey
        MOV     SI, OFFSET(DisplayBuffer)       ; Check if the length of keycode exceeds the 
                                                ; maximum length. 
        MOV     BX, OFFSET(DisplayBuffer)
        ADD     BX, MAX_LENGTH     
        CMP     Bufferend, BX
        JA      EndHandleKey                    ; If so, do nothing
        MOV     SI, Bufferend                   ; Otherwise, store the data into the buffer and display the data
        INC     Bufferend
        MOV     ES:[SI], AL
        CALL    Display
        JMP     EndHandleKey
ClearBuffer:                   
        MOV     ES:[SI], 0                      ; Clear each slot of the buffer until reaches end
        INC     SI
        CMP     SI, BufferEnd
        JE      EndHandlekKey
        JMP     ClearBUffer

        

EndHandleKey:
        RET
HandleKey ENDP        


CODE    ENDS

; the data segment
DATA SEGMENT PUBLIC 'DATA'            ;setup DGROUP
    DisplayBuffer   DB  (Buffer_size) DUP (?)   ; Buffer for storing the data to display
    BufferEnd       DW  ?                       ; The end pointer of the buffer
DATA ENDS

; the stack segment
STACK  SEGMENT STACK 'STACK'
                DB 80 DUP ('Stack ')  ;240 words
                
TopOfStack LABEL  WORD                ; The label for the start of the stack

STACK  ENDS
  
  
  
       END START
