;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Motor.INC                                ;
;                                 Motor Routine                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Motor Routine
; (motor.ASM).
;
; Revision History:
;    11/28/2012 Yuqi Zhu Initial Revision
;    12/02/2012 Yuqi Zhu Update comments

; General Definitions:
IGNORE_SPEED      EQU 65535           ; Setmotorspeed will ignore the passed
                                      ; speed if it's equal to IGNORE_SPEED 
IGNORE_ANGLE      EQU -32768          ; Setmotorspeed will ignore the passed
                                      ; angle if it's equal to IGNORE_ANGLE 
WHEEL_NUM         EQU 3               ; Number of wheels
CYCLE_LENGTH      EQU 128             ; Length of the cycle of parallel IO counter 

; Addresses:
portBaddr         EQU 0181h           ; Address of PortB
PIOctrladdr       EQU 0183h           ; Address of the control register of parallel
                                      ; IO control register
; Parallel IO control register value                                    
PIOctrlval        EQU 080h            ;value to write to Parallel IO control 
                                      ;register
                                      ;1-------  enable parallel IO
                                      ;-00000-0  unimportant bits, all set to 0
                                      ;------0-  set portB to output
                                 