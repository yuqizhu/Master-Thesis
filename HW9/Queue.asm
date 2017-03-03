NAME    QueueRoutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;                                                                            ;    
;                                 QueueRoutines                              ;    
;                                Queue Functions                             ;    
;                                   EE/CS 51                                 ;    
;                                                                            ;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    



CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


$INCLUDE(queue.inc)

; QueueInit
;
; Description: Initialize the Queue of size s, whose head pointer and tail pointer are both 0.
;
; Operation: Construct a queue of size s and assign 0 to the head pointer and tail pointer.
;
; Arguments: AX --- Size of the queue
;            SI --- Address of the queue
;
; Return Value: A queue of size 0 whose head pointer and tail pointer are both 0.
;
; Local Variables: None
; Shared Variables: None
; Global Variables: None
;
; Input: None
; Output: None
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: BX
; Author: Yuqi Zhu
; Last Modified: 11/04/2012

QueueInit     PROC    NEAR           ; Initialize the queue
              PUBLIC  QueueInit


       MOV   BX, 0                   ; setup for the initialization
       MOV  [SI].head, BX            ; Set the head pointer to 0
       MOV  [SI].currsize, AX        ; Set the current size to AX
       MOV  [SI].tail, BX            ; Set the tail pointer to 0
       RET

QueueInit ENDP


; QueueEmpty
;
; Description: Test the queue is empty of not.
;
; Operation: Set the zero flag if the queue is empty and reset it otherwise.
;
; Arguments: SI --- The address of the queue
; Return Value: The zero flag is set to 1 if the queue is empty
;
; Local Variables: None
; Shared Variables: None
; Global Variables: None
;
; Input:None
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: BX
;
; Author: Yuqi Zhu
; Last Modified: 11/04/2012
QueueEmpty PROC NEAR                ; Set the zero flad if the queue is empty and reset it otherwise 
           PUBLIC QueueEmpty        
           MOV BX, [SI].tail        ; Store the value of tail pointer to BX
           CMP BX, [SI].head        ; Compare the tail pointer with the head pointer, if they're equal then the 
                                    ; queue is empty
           RET
QueueEmpty ENDP

; QueueFull
;
; Description: Tell if the given queue is full or not. 
;
; Operation: Set the zero flag if the queue is full and reset it otherwise.
;
; Arguments: SI --- The address of the queue.
; Return Value: Set the zero flag to 1 if the queue is full
;
; Local Variables: None
; Shared Variables: None
; Global Variables: None 
;
; Input:None
; Output: None
;
; Error Handling:None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: CX, BX
;
; Author: Yuqi Zhu
; Last Modified: 11/04/2012

QueueFull PROC NEAR                ; Test if the queue is full. Set the zero flag if the queue is full and reset it otherwise.
          PUBLIC QueueFull
     MOV CX, [SI].head             ; Move the value of the head pointer to CX 
     ADD CX, [SI].currsize         ; Get the sum of the current size and the value of head pointer
     MOV BX, [SI].tail             ; Move the value of the tail pointer to BX 
     CMP CL, BL                    ; Compare the sum with the value of the tail pointer, if they're equal then the queue is full
     RET
QueueFull ENDP

; Dequeue
;
; Description: Remove the last entry of the queue if the queue is not empty and increase the head pointer by 1.

; Operation: Removes the last entry of the queue. If the queue is empty, then the procedure will wait 
;            until there's a value added to it. The function will return after the value has 
;            been removed from the queue.
;
; Arguments: SI --- The address of the queue
; Return Value: The value at the head point is stored in AL.
;
; Local Variables: None
; Shared Variables: None
; Global Variables: None
;
; Input: None
; Output: None
;
; Error Handling:None
;
; Algorithms:None    
; Data Structures: None    
;    
; Registers Changed: BX, AL    
;    
; Author: Yuqi Zhu    
; Last Modified: 11/04/2012   
    
Dequeue PROC NEAR            ; Remove the entry at the head pointer of the queue and increase the head pointer by 1.
        PUBLIC Dequeue    
    
DequeueBody:                 ; Handle the case that the queue is empty
   CALL QueueEmpty           ; Test if the queue is empty
   JE   DequeueBody          ; If it's empty then jump back the start
   JMP  NonEmptyCase         ; Otherwise proceed

NonEmptyCase:    
   MOV BX, [SI].head         ; Move the value of the head pointer to BX
   MOV AL, [SI].array[BX]    ; Get the correponding entry from the array
   INC BX                    ; Increase the head pointer
   MOV [SI].head, BX         
   CMP [SI].head, MAX_SIZE   ; Test if the value of the head pointer exceeds the size of the array 
   JB EndDequeue             ; If not, we are done
   MOV [SI].head, 0          ; Otherwise, the head pointer must be just out of the allowed range and we change the value of 
                             ; the head pointer to 0.
   JMP EndDequeue   
      
   
EndDequeue:    
   RET  
   
Dequeue ENDP    
        
; Enqueue    
;    
; Description: Add a passed 8-bit value to the end of the queue if the queue if not full and increase the tail pointer by 1.  
; Operation: Add a passed 8-bit value to the end of the queue. If the queue is full it will wait until there's an open space.    
;            The function will not return until the value has been added.    
    
;    
; Arguments:  AL --- The value to be added    
;             SI --- The address of the queue    
; Return Value: None
;    
; Local Variables: None  
; Shared Variables: None    
; Global Variables: None   
;    
; Input: None    
; Output: None 
;    
; Error Handling:None    
;    
; Algorithms: None    
; Data Structures: None    
;    
; Registers Changed: BX, AL  
;    
; Author: Yuqi Zhu    
; Last Modified:11/04/2012  
     
Enqueue PROC NEAR                ; Add a passed entry at the tail pointer and increase the tail pointer by 1
        PUBLIC Enqueue    
    
EnqueueBody:                     ; Handle the case that the queue is full
    CALL QueueFULL               ; Test if the queue is full
    JE EnqueueBody               ; If the queue is full then go back to the beginnning
    JMP NotFullCase              ; Otherwise proceed
       
      
NotFullCase:                     
   MOV BX, [SI].tail             
   MOV [SI].array[BX], AL        ; Store AL at the corresponding entry of the queue
   INC BX                        
   MOV [SI].tail, BX             ; Increase the tail pointer by 1
   CMP [SI].tail, MAX_SIZE       ; Test if the tail pointer exceeds the maximum size
   JB  EndEnqueue                ; If not, we are done
   MOV [SI].tail, 0              ; Otherwise, we change the tail pointer value to 0 as the tail pointer
                                 ; must be just outside the range
EndEnqueue:    
   RET        
    
Enqueue ENDP    
    

CODE    ENDS
        END
