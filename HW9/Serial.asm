Name Serial

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Serial                                  ;
;                               Serial Functions                             ;
;                                   EEgCS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains functions for the Serial. 
; The public functions included are:
; InitSerial()      --- initialization of serial
; SerialInRdy()     --- check if there's a serial channel character available
; SerialGetChar()   --- get the next character for the serial channel 
; SerialOutRdy()    --- check if the serial channel is ready to transmit
; SerialPutChar(c)  --- output the character c to the serial channel
; SerialStatus()    --- return the serial channel error status
; SetSerial()       --- Initialize the serialIO registers
; SetBaudRate()     --- Sets up the Baud Rate

; Revision History:
; 11/30/2012  Yuqi Zhu Initial Revision 
; 12/05/2012  Yuqi Zhu Updated Comments
; 12/07/2012  Yuqi Zhu Updated Comments
; locally include file
$INCLUDE(Serial.inc)
$INCLUDE(queue.inc)

CGROUP GROUP CODE
DGROUP GROUP DATA


; the code segment

CODE   SEGMENT PUBLIC 'CODE'
   
       ASSUME CS:CGROUP, DS:DGROUP


; External Function Declaration
EXTRN QueueEmpty:NEAR    ; Check if queue is empty 
EXTRN QueueFull:NEAR     ; Check if queue is full
EXTRN QueueInit:NEAR     ; Initialize the queue
EXTRN Dequeue:NEAR       ; Remove the entry pointed by the head pointer in queue
EXTRN Enqueue:NEAR       ; Add the entry to where tail pointer points in queue


; InitSerial()
; Description: Initialization for the shared variables, the Serial IO
;              registers and the Baud Rate.
; Operation:   This function calls QueueInit twice to initialize the Rqueue and
;              Tqueue. This function also clears the kickstart flag and errorstatus
;              and calls setserial to setup the serial IO registers
;
; Arguments:    None
; Return Value: None 
;
; Local Variables:  None
; Shared Variables: Rqueue      --- The receive queue  (changed)
;                   Tqueue      --- The transmit queue (changed)
;                   errorstatus --- Specifies the errors that have happened 
;                                   (changed)
;                   kickstart   --- Kickstart flag (changed)
;
; Global Variables: None
;
; Input:            None 
; Output:           None
;
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  Array
;
; Registers Changed: SI, AX, BX, DX, 
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


InitSerial PROC NEAR                  ; Initialization for the SerialIO registers
           PUBLIC InitSerial
    MOV SI, OFFSET(RQueue)            ; Setup for initialization of RQueue 
    MOV AX, QUEUE_SIZE                ; QueueInit assumes queue size in AX and 
    CALL QueueInit                    ; address in SI
    MOV SI, OFFSET(TQueue)            ; Setup for initialization of TQueue
    MOV AX, QUEUE_SIZE       
    CALL QueueInit
    MOV errorstatus, 0                ; No error initially
    MOV kickstart, 0                  ; Clear the kickstart flag
    CALL SetSerial
    CALL SetBaudRate
    RET                               ; Done
InitSerial ENDP
    
    
; SerialInRdy
; Description: This function resets the zero flag if there's a character available
;              in receive queue; otherwise, it sets the zero flag.  
;
; Operation:   This function calls the QueueEmpty to check if RQueue is empty. 
;              The address of RQueue is moved to SI and QueueEmpty will set the 
;              zero flag if RQueue is empty.
;               
;
; Arguments:          None
; Return Value:       None 
;
; Local Variables:    None
; Shared Variables:   RQueue --- The receive queue (Read)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    Array
;
; Registers Changed:  SI, BX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012



SerialInRdy PROC NEAR          ; This function calls QueueEmpty to set the zero
          PUBLIC SerialInRdy   ; flag if the RQueue is empty
    MOV SI, OFFSET(RQueue)     ; QueueEmpty assumes the address of Queue is in SI
    CALL QueueEmpty
    RET                        ; Done
SerialInRdy ENDP



; SerialGetChar() 
;
; Description: This function returns with the next character in receiver queue in
;              AL. It also sets the carry flag if an error has happened. The 
;              function won't return until a charcter has been received.
;
; Operation:   This functions calls Dequeue to move the next character in receiver
;              to AL. It also sets the carry flag if the errorstatus is not
;              zero, which means an error has happened.
; Arguments:   None
; Return Value: The current speed of motorstrike
;
; Local Variables:   None
; Shared Variables:  RQueue      --- The receive queue (changed)
;                    errorstatus --- Indicates the errors that have happened (read)
; Global Variables:  None
;
; Input:             None 
; Output:            None
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   Array
;
; Registers Changed: SI, BX, AL, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012
SerialGetChar PROC NEAR             ; This function returns with the next character
              PUBLIC SerialGetChar  ; in receive queue

GetCharBody:                        ; Call Dequeue and set the carry flag
    MOV SI, OFFSET(RQueue)          ; Dequeue assumes address in SI
    CALL Dequeue
    CMP errorstatus, 0              ; Check if there's error happened
    JE  ResetCarry                  ; If not, resets the carry flag
    JNE SetCarry                    ; If there're errors, set the carry flag
ResetCarry:                         ; Reset the carry flag
    CLC
    JMP EndGetChar
SetCarry:                           ; Set the carry flag
    STC
EndGetChar:                         ; Done
    RET
SerialGetChar ENDP

; SerialOutRdy()
; Description: This function calls QueueFull to check if the transmit queue is
;              full; it sets the zero flag if the transmit queue is full and resets
;              it otherwise.
; Operation:   The address of TQueue is passed to SI and QueueFull is called to
;              check if the transmit queue is full        
;
; Arguments:    None
; Return Value: None
;
; Local Variables:  None
; Shared Variables: TQueue  --- The transmit queue
; 
; Global Variables: None
;
; Input:            None 
; Output:           None 
;
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  Array
;
; Registers Changed: SI, CX, BX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


SerialOutRdy PROC NEAR                      ; Call to QueueFull to check if the 
               PUBLIC SerialOutRdy          ; transmit queue is full
    MOV SI, OFFSET(TQueue)                  ; QueueFull assumes the address in 
    CALL QueueFull                          ; SI
    RET                                     ; Done
SerialOutRdy ENDP



; SerialPutChar(c)
; Description: This function outputs the passed character to the transmit queue.
;              This function won't return until a character has been transmitted.
;              If the kickflag is on, then this function will do the kickstart, 
;              i.e. turn off the THRE interrupt and turn it back again. The 
;              character is passed in AL.
; Operation:   If the kickstart flag is on, this function will turn off the THRE
;              interrupt and turn it back on again. Then the function will call
;              the Enqueue to transmit the passed character to TQueue. 
; Arguments:       AL        --- the value that needs to be passed to Tqueue
; Return Value:    None
;
; Local Variables: None
; Shared Variables:kickstart --- Kickstart flag (read)
;                  TQueue    --- The transmit queue (changed)
; Global Variables:None
;
; Input:           None 
; Output:          None
;
; Error Handling:  None
;
; Algorithms:      None
; Data Structures: Array
;
; Registers Changed: AL, BX, DX, SI, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


SerialPutChar PROC NEAR            ; Do the kickstart if the kickstart flag is on
          PUBLIC SerialPutChar     ; and transmit the character to transmit queue
    MOV BL, 0                      ; This is a critical code, we use XCHG here 
    XCHG kickstart, BL             ; to make sure we don't miss a kickstart if 
    CMP BL, 0                      ; an interrupt sets the flag between the 
    JE  PutCharBody                ; comparison and clear of the kickflag.
    ;JNE Kickstartbody
Kickstartbody:                     ; Do the kickstart
    PUSH AX                        ; Save the value in AL as it's the argument
    MOV AL, IER_DISTHRE            ; Setup to disable the THRE interrupt
    MOV DX, IERaddr
    OUT DX, AL                     ; Send the bits to disable the THRE interrupt
    MOV AL, IERval                 ; Setup to enable the THRE interrupt
    OUT DX, AL                     ; Send the bits to enable the THRE interrupt    
    POP AX                         ; Retrieve the argument
PutCharBody:                       ; Call Enqueue to put the character to the
                                   ; transmit queue
    MOV SI, OFFSET(TQueue)         ; Enqueue assumes address in SI
    CALL Enqueue
    RET                            ; Done
SerialPutChar ENDP

; SerialStatus()
; Description: This function returns the error status for serial channel in AL.
; Operation:   Return the errorstatus with AL.
;
; Arguments:        None
; Return Value:     None 
;
; Local Variables:  None
; Shared Variables: errorstatus --- Indicates the errors that have happened (read)
; Global Variables: None
;
; Input:            None 
; Output:           None
;
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  None
;
; Registers Changed: AL
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


SerialStatus PROC NEAR           ; Return the error in AL
          PUBLIC SerialStatus 
    MOV AL, 0                    ; This is a critical code to prevent errors from
                                 ; missing if it happens between moving the 
                                 ; errorstatus to AL and clearing the errorstatus 
    XCHG AL, errorstatus
    RET                          ; Done
SerialStatus ENDP


; SerialIO
; 
; Description:   This event handler picks the steps based on the interrupt
;                type that's determined by IIR. When an recevier line status
;                interrupt happened, the error will be retrieved from LSR and
;                stored in the errorstatus shared variable. When a received data
;                available interrupt happens, the event handler will move the value
;                from RBR into RQueue; if RQueue is empty, an error will be
;                generated and stored in errorstatus. When a transmitter holding
;                register empty interrupt happened, the event handler will move 
;                the next available entry from TQueue and transmit it into THR;
;                if TQueue is empty, the kickstart flag will be set. 
;
; Operation:     This function uses an interruptcalltable to choose the proper
;                steps for handling the interrupts. The RLSHandler uses the
;                ERROR_MASK to get the error type from LSR and store the into
;                errorstatus. The received data available interrupt handler move
;                the value from Receiver Buffer Register(RBR) into RQueue; an error
;                will be generated if RQueue is full. The transmitter holding 
;                register interrupt handler will transmit the next available data
;                from TQueue into Transmitter Holding Register (THR) or set the
;                kickstart flag if TQueue is empty. This function doesn't change
;                any registers or flags.
;
; Arguments:        None
; Return Value:     None 
;
; Local Variables:  None
; Shared Variables: RQueue      --- The receive queue (changed)
;                   TQueue      --- The transmit queue (changed)
;                   kickstart   --- Kickstart flag (changed)
;                   errorstatus --- Indicates the errors that have happened 
;                                   (changed)
; Global Variables: None
;
; Input:            None 
; Output:           None
;
; Error Handling:   If an RLS interrupt happens, the function will store the 
;                   error into errorstatus. If RQueue is full when a Received
;                   Data Available interrupt happens, a Queue Full error will
;                   be stored into errorstatus
;
; Algorithms:       None
; Data Structures:  Array
;
; Registers Changed:None
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


SerialIO PROC NEAR                    ; This function is the interrupt 2 event                                 
           PUBLIC SerialIO            ; handler
    PUSH AX                           ; The event handler doesn't change any 
    PUSH BX                           ; registers or flags
    PUSH CX
    PUSH DX
    PUSH SI
    PUSHF
Gettype:                                ; Determine the interrrupt type
    MOV DX, IIRaddr                     ; Retrieve the IIR value, bits 1, 2 indicate
    IN AL, DX                           ; the interrupt type
    AND AL, INTERRUPT_MASK              ; Use INTERRUPT_MASK to get the interrupt
                                        ; type  
    MOV AH, 0                           ; Setup AX to get the OFFSET on the table
                                        ; as SI has to be added with a 16-bit
                                        ; register  
    MOV SI, OFFSET(InterruptCallTable)  
    SAL AX, 1                           ; Each entry is a word, so we double the
                                        ; OFFSET
    ADD SI, AX                          
    MOV AX, CS:[SI]                     ; Get the address of the next step
    JMP AX                              ; Jump to the next step
RLSHandler:                             ; Handler for the receive line status
    MOV DX, LSRaddr                     ; Get the LSR value, whose bits 1, 2, 3
                                        ; indicate the error types
    IN  AL, DX                          ; Store the error type into AL
    AND AL, ERROR_MASK                  ; Only bits 1, 2, 3 matter
    OR  errorstatus, AL                 ; Store the error into the errorstatus
    JMP EndSerialIO                     
Receivedata:                            ; Handler for receiving the data
    MOV DX, RBRaddr                     ; Move the value from Receiver
    IN  AL, DX                          ; Buffer Register(RBR) into RQueue
    MOV SI, OFFSET(RQueue)              ; Call QueueFull to check if RQueue is 
    CALL QueueFull                      ; full; QueueFull doesn't change AL
    JE  RqueueFullError                 ; If Rqueue is full, generates a 
                                        ; RqueueFullError and stores it into error 
                                        ; status

    CALL Enqueue                        ; Otherwise, call Enqueue to move the value
                                        ; into RQueue
    JMP EndSerialIO
RqueueFullError:                        ; Store the QFULL_ERROR into error_status 
    OR errorstatus, QFULL_ERROR
    JMP EndSerialIO
Transmitdata:                           ; Handler for transmitting the data
    MOV SI, OFFSET(TQueue)              ; Call QueueEmpty to check if TQueue is
    CALL QueueEmpty                     ; empty
    JE Setkickstart                     ; If so, set the kickstart flag
    JNE Transmitbody                    ; Otherwise, transmit the data
Setkickstart:                           ; Set the kickstart flag
    MOV kickstart, 1                    
    JMP EndSerialIO
Transmitbody:                           ; Transmit the data
    CALL Dequeue                        ; Call Dequeue to move the next available
    MOV DX, THRaddr                     ; data into Transmitter Holding Register
    OUT DX, AL                          ; (THR)
    JMP EndSerialIO      
EndSerialIO:                            ; Restore the values into registers and
    POPF                                ; flags and return
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SerialIO ENDP        


; SetSerial
; 
; Description: This function initializes the registers for serial IO 
; Operation:  This function initializes the IER and LCR for serial IO
;
; Arguments:         None
; Return Value:      None 
;
; Local Variables:   None
; Shared Variables:  None
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   None
;
; Registers Changed: AL, DX
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012

SetSerial PROC NEAR          ; This function sets up the IER and LCR for serial
      PUBLIC SetSerial       ; IO
SetIER:                      ; Set up the IER 
    MOV DX, IERaddr          
    MOV AL, IERval
    OUT DX, AL               ; Send the value to IER
SetLCR:                      ; Set up the LCR
    MOV DX, LCRaddr
    MOV AL, LCRval
    OUT DX, AL               ; Send the value to LCR
EndSetSerial:                ; Done
    RET                     
SetSerial ENDP


; SetBaudRate
; 
; Description: This function sets up the baud rate. 
; Operation:   This function turn on the DLAB bit of LCR and write Baud_rate
;              into the Divisor_latch(LSB). After finish setting up the Baud rate,
;              the function turns off the DLAB bit of LCR.
;
; Arguments:         None
; Return Value:      None 
;
; Local Variables:   None
; Shared Variables:  None
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   None
;
; Registers Changed: AL, BL, DX
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012 

  
SetBaudRate PROC NEAR      ; This function sets up the baud rate
       PUBLIC SetBaudRate   
    MOV DX, LCRaddr        ; Retrieve the LCR value
    IN AL, DX              ; Input the value 
    MOV BL, AL             ; Save the value into BL as we will use AL later
    OR AL, DLAB_MASK       ; Turn on the DLAB bit
    OUT DX, AL             ; Write the new value to LCR
    MOV DX, LSBaddr        ; Set up the Baud_rate
    MOV AX, Baud_Rate    
    OUT DX, AX             ; Write the Baud_rate into LCR
    MOV DX, LCRaddr        ; Setup to write the original LCR value 
    MOV AL, BL
    OUT DX, AL             ; Write the original LCR value into LCR
    RET                    ; Done
SetBaudRate ENDP    

; InterruptCallTable
; 
; Description:      This table contains different steps for different interrupt 
;                   types received from IIR. Any interrupts other than three
;                   we need are omitted.
;
; Author:           Yuqi Zhu
; Last Modified:    12/07/2012

InterruptCallTable LABEL WORD
    PUBLIC InterruptCallTable
;DW    Step
 DW    EndSerialIO        
 DW    EndSerialIO
 DW    Transmitdata
 DW    EndSerialIO
 DW    Receivedata
 DW    EndSerialIO
 DW    RLSHandler
 DW    EndSerialIO

CODE ENDS






; the data segment

DATA SEGMENT PUBLIC 'DATA'
    TQueue Queue <>           ; The transmit queue
    RQueue Queue <>           ; The receive queue
    kickstart   DB ?          ; Kickstart flags
    errorstatus DB ?          ; Indicates the errors that have happened
     
DATA ENDS
     END
