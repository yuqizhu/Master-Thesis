
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display.INC                               ;
;                               Display Routine                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Display Routine
; program (display.ASM).
;
; Revision History:
;    11/11/2012 Yuqi Zhu initial revision

; General Definitions:
NUM_Digit EQU 8      ; Number of LEDdigits on the board 
Buffer_size EQU 16   ; The size of the buffers
String_size EQU 16  