;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Init.INC                                 ;
;                            Initialization function                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the initialization functions(init.ASM).
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
;     12/02/2012 Yuqi Zhu       Initialization functions are moved to this file
;                               







; Interrupt Controller Definitions

; Addresses

INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI 
                                        ;register

; Register Values
NonSpecEOI      EQU     08000H          ;Non-specific EOI command


; Chip Select Unit Definitions

; Addresses
PACSreg         EQU     0FFA4H          ;address of PACS register
MPCSreg         EQU     0FFA8H          ;address of MPCS register

; Control Register Values
PACSval         EQU     00003H          ;PCS base at 0, 3 wait states
                                        ;0000000000------  starts at address 0
                                        ;----------000---  reserved
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states
MPCSval         EQU     00183H          ;PCS in I/O space, use PCS5/6, 3 wait 
                                        ;states
                                        ;0---------000---  reserved
                                        ;-0000001--------  MCS is 8KB
                                        ;--------1-------  output PCS5/PCS6
                                        ;---------0------  PCS in I/O space
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states







; General Definitions

FIRST_RESERVED_VEC	EQU	1	;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3
NUM_IRQ_VECTORS         EQU     256     ;number of interrupt vectors
