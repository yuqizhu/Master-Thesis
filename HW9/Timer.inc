;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  TIMER.INC                                 ;
;                              Timer Event Handler                           ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timer Event Handler 
; program (timer2.ASM, timer.ASM).
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
;     11/11/2012 Yuqi Zhu       removed everything related to TIMER0
;                               update the address for LEDdigit
;                               changed the value of Timer 2 Control Register 
;                               changed the maxcount value of Timer 2
;                               change the filename to Timer.inc
;     12/15/2012 Yuqi Zhu       Integrate Timer0.inc and Timer2.inc together into
;                               Timer.inc 
; Timer Definitions

; Addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register

Tmr2Ctrl        EQU     0FF66H          ;address of Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ;address of Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ;address of Timer 2 Count Register

; Control Register Values
Tmr0CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  increment timer0 at
                                        ;                  1/4 CLKOUT
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode
                                      
Tmr2CtrlVal     EQU     0E001H          ;value to write to Timer 2 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  interrupts enabled
                                        ;----000000-0000-  reserved
                                        ;---0------0-----  read only
                                        ;---------------1  continuous mode


; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
INTCtrlrCVal    EQU     00001H        ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)



;Interrupt Vector
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0
Tmr2Vec         EQU     19              ; Address of Timer 2 interrupt vector

; Timing Definitions

COUNTS_PER_CYCLE   EQU     540          ;128 counts per 30 ms (assumes 18.432 
                                        ;MHz clock)
COUNTS_PER_MS   EQU     2304            ;number of timer counts per 1 ms (assumes 18.432 MHz clock)




; General Definitions

FIRST_RESERVED_VEC	EQU	1	;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3
NUM_IRQ_VECTORS         EQU     256     ;number of interrupt vectors
