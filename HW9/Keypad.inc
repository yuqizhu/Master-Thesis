
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Keypad.INC                                ;
;                                Keypad Routine                              ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Keypad Routine
; program (keypad.ASM).
;
; Revision History:
;    11/19/2012 Yuqi Zhu 
;    11/20/2012 Yuqi Zhu Update comments
; General Definitions:
Keypad_Address    EQU    0080h          ; the I/O address of the first row of keypad
low_nibble_mask   EQU    0Fh            ; the mask for the data read from the keypad as only the low_nibbles are required
Non_Pressed       EQU    15             ; data corresponds to no key being pressed
Col_Num           EQU    4              ; number of columns on keypad
Row_Num           EQU    4              ; number of rows on keypad
Invalid_value     EQU    16             ; this value is used for colnumber if no key is being pressed or multiple keys are being pressed
Invalid_keycode   EQU    '*'            ; invalid keycode when multiple keys are being pressed
Debounce_Time     EQU    50             ; the debounce counter 
SLOW_RATE         EQU    1000           ; the slow repeat rate 
FAST_RATE         EQU    500            ; the fast repeat rate
FAST_REPEAT_TIME  EQU    2000           ; auto repeat counter

KeyEntry STRUC                          ; The data structure of each keyentry consists of three parts: keycode, the string to display
   Keycode   DW ?                       ; and the offset of the next key menu
   NextTable DW ?

KeyEntry ENDS

    
