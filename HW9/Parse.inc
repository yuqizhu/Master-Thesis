;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Parse.INC                                ;
;                            Parsing Serial Functions                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the parsing serial functions(parse.ASM).
;
; Revision History:
; 12/08/2012 Yuqi Zhu  Initial Revision
; 12/12/2012 Yuqi Zhu  Updated Comments

; Transition Entry Definitions
TRANSITION_ENTRY  STRUC    ; Transtion entry specifies the next state to go to
                           ; and the action to take
   NEXTSTATE   DB  ?       ; State to update
   ACTION      DW  ?       ; Action to take
TRANSITION_ENTRY   ENDS


; State definitions

INITIAL_STATE	     EQU	0		;initial state
SET_ABS_SPEED        EQU    1       ;set absolute speed state
SET_ABS_SPEED_SIGN   EQU    2       ;set absolute speed state with SIGN
SET_ABS_SPEED_VAL    EQU    3       ;set absolute speed adding digits state
                                    ;(positive value only)                                   
SET_REL_SPEED        EQU    4       ;set relative speed state
SET_REL_SPEED_SIGN   EQU    5       ;set relative speed state with SIGN
SET_REL_SPEED_VAL    EQU    6       ;set relative speed adding digits state
SET_DIRECTION        EQU    7       ;set direction state
SET_DIRECTION_SIGN   EQU    8       ;set direction state with SIGN
SET_DIRECTION_VAL    EQU    9       ;set direction adding digits state
ROTATE_TURRET        EQU    10      ;rotate turret state
ROTATE_TURRET_SIGN   EQU    11      ;rotate turret state with SIGN
ROTATE_TURRET_REL    EQU    12      ;relatively rotate turret state
ROTATE_TURRET_ABS    EQU    13      ;absolutely rotate turret state
SET_ELEVATION        EQU    14      ;set elevation state
SET_ELEVATION_SIGN   EQU    15      ;set elevation state with SIGN
SET_ELEVATION_VAL    EQU    16      ;set elevation adding digits state
FIRE_LASER           EQU    17      ;fire laser state
LASER_OFF            EQU    18      ;laser off state
ERROR_STATE          EQU    19      ;error state

NUM_STATES	         EQU	20		;number of states



; Token Type Definitions

TOKEN_OTHER	  EQU	 0		;anything else
TOKEN_S	      EQU	 1		;token is character S
TOKEN_V	      EQU    2		;token is character V
TOKEN_D	      EQU    3		;token is character D
TOKEN_T	      EQU    4		;token is character T
TOKEN_E	      EQU    5		;token is character E
TOKEN_F	      EQU	 6		;token is character F
TOKEN_O	      EQU	 7		;token is character O
TOKEN_SIGN    EQU	 8		;token is a sign
TOKEN_DIGIT   EQU	 9		;token is a digit
TOKEN_ETR     EQU    10     ;token is enter
TOKEN_SPACE	  EQU	 11  	;token is a space or tab

NUM_TYPES	  EQU	 12		;number of token types



; Other Constants


IGNORE_SPEED       EQU  65535       ;SetMotorSpeed will ignore the speed argument
                                    ;if IGNORE_SPEED is passed 
IGNORE_ANGLE       EQU  -32768      ;SetMotorSpeed will ignore the angle argument
                                    ;if IGNORE_ANGLE is passed
ANGLE_BOUND        EQU  60          ;The absolute value of the angle for 
                                    ;SetElvation must below 60 

RETURNERROR        EQU  2           ;Error happened when return is pressed 
MAXIMUM_SPEED      EQU  65534       ;MAXIMUM_SPEED for robostrike 

