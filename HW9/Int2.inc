;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  int2.INC                                  ;
;                              int2 Event Handler                            ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for int2 functions (int2.ASM).
;
; Revision History:
;    11/11/92  Glen George      initial revision (originally part of
;                                  ISRDEMO.ASM)
;    10/27/93  Glen George      split definitions into own file (EHDEMO.INC)
;                               updated/corrected comments
;    10/24/94  Glen George      added Revision History section
;                               updated comments
;    10/25/95  Glen George      updated comments
;    10/28/96  Glen George      added COUNTS_PER_MS and MS_PER_SEG constants
;                               updated comments
;    10/28/97  Glen George      added RESERVED_VECS constant
;                               changed PACSVal and MPCSVal to not set
;                                  reserved bits and set 3 wait states
;                               updated comments
;    12/26/99  Glen George      updated comments
;     2/13/01  Glen George      changed MPCSVAL to a legal value
;     2/03/03  Glen George      changed NO_DIGITS to NUM_DIGITS
;                               changed Timer0EOI to TimerEOI
;                               added NUM_IRQ_VECTORS
;                               updated comments
;     1/28/04  Glen George      updated comments
;     2/05/05  Glen George      added FIRST_RESERVED_VEC and LAST_RESERVED_VEC
;                                  and removed RESERVED_VECS for new version
;                                  of ClrIRQVectors
;                               updated comments
;     12/02/2012 Yuqi Zhu       Move definitions that's unrelated to timer out
;                               of the file  
;
;     12/08/2012 Yuqi ZHu       Updated Comments



; Interrupt Controller Definitions

; Addresses
INT2CtrlrCtrl    EQU     0FF3CH         ;address of interrupt controller for INT2
INTCtrlrEOI      EQU     0FF22H         ;address of interrupt controller EOI 
                                        ;register

; Register Values
INT2CtrlrCVal    EQU     00011H         ;set priority for INT2 to 1 and enable
                                        ;00000000000-----  reserved
                                        ;-----------1----  Level triggering
                                        ;------------0---  enable int2 interrupt
                                        ;-------------001  int2 priority
                                        
INT2EOI          EQU    14              ;INT2 EOI command 





;Interrupt Vector
INT2VEC         EQU     14              ;interrupt vector for INT 0






