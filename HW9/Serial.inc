;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Serial.INC                               ;
;                                 Serial Routine                             ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Serial Routine
; (serial.ASM).
;
; Revision History:
;    12/03/2012 Yuqi Zhu Intial Revisions
;    12/05/2012 Yuqi Zhu Updated Comments
;    12/08/2012 Yuqi Zhu Updated Comments

; Addresses:
THRaddr         EQU   0100h           ; Address of Transmitter Holding Register
RBRaddr         EQU   0100h           ; Address of Receiver Buffer Register
LSBaddr         EQU   0100h           ; Address of Divisor Latch
IIRaddr         EQU   0102h           ; Address of interrupt identification register
                                      ; (IIR)
LCRaddr         EQU   0103h           ; Address of interrupt control register (LCR)
LSRaddr         EQU   0105h           ; Address of status register (LSR)
IERaddr         EQU   0101h           ; Address of interrupt enable register (IER)

; Values 
IERval          EQU   07h             ; Value to write to IER 
                                      ; 0000----  Those bits are always cleared
                                      ; ----0---  Disable the modem status interrupt
                                      ; -----1--  enables the receiver line status
                                      ;           interrupt
                                      ; ------1-  enables the THRE interrupt
                                      ; -------1  enables the received data available
                                      ;           interrupt
LCRval          EQU   07h             ; Value to write to LCR
                                      ; 0-------  clear the DLAB bit to read or
                                      ;           write
                                      ; -0------  Disable the break condition
                                      ; --000---  Disable the parity
                                      ; -----1--  Set 2 stop bits when bit length
                                      ;           is 8 bits
                                      ; ------11  set bit length to 8 bits
                                       

; Masks
IER_DISTHRE     EQU   05h             ; Disable the THRE interrupt
DLAB_MASK       EQU   80h             ; Enable the DLAB bit in LCR to access
                                      ; the divisor latch
INTERRUPT_MASK  EQU   06h             ; Mask for retrieving interrupt type from
                                      ; IIR
ERROR_MASK      EQU   0Eh             ; Mask for retrieving error type from LSR

; General Definitions:

QFULL_ERROR     EQU   128             ; User define error type for Rqueue Full 
                                      ; Error 
BAUD_RATE       EQU   60              ; BAUD_RATE divisor for a BAUD_RATE of 9600
QUEUE_SIZE      EQU   64              ; Size of TQueue and RQueue