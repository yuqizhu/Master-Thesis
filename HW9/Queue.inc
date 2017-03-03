
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Queue.INC                                ;
;                                 Queue Routine                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Display Routine
; program (queue.ASM).
;
; Revision History:
;    12/15/2012 Yuqi Zhu updated comments
 

MAX_SIZE EQU 256                     ; The maximum size of the queue

Queue STRUC                          ; Queue 
     head   DW ?                     ; Head pointer
     tail   DW ?                     ; Tail pointer
     currsize   DW ?                 ; Current size of queue
     array  DB MAX_SIZE DUP (?)      ; Array containing the queue
         
         
Queue  ENDS

