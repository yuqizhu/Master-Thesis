Name Keypad

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Keypad                                  ;
;                               Keypad Functions                             ;
;                                   EEgCS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains functions for the keypad routine.
; The public functions included are:
; Initkey - Initialization of the key function
; Getkey  - Respond to the key press
; Isakey  - Set the zero flag if a key available and resets it otherwise 
; KeyScan - Scan the keypads and debounce the key press
; Revision History:
; 11/17/2012  Yuqi Zhu  
; 11/18/2012  Yuqi Zhu
; 11/19/2012  Yuqi Zhu
; 11/20/2012  Yuqi Zhu  




; local include file
$INCLUDE(Keypad.inc)





CGROUP GROUP CODE
DGROUP GROUP DATA


; the code segment

CODE   SEGMENT PUBLIC 'CODE'
   
       ASSUME CS:CGROUP, DS:DGROUP




; Initkey
; Description: Initialzation of the keypad functions, including the initialization of the shared variables.
;
; Operation: The scan starts from the first row and first column, and there's no key being pressed at the beginning
;            So Initkey sets all of the RowNumber, ColNumber and Keypad to 0. It also initializes the code buffer to 
;            0. Debounce counter, repeat counter and repeat rate are initialized to their default value.
;
; Arguments:    None
; Return Value: None
;
; Local Variables:  None
; Shared Variables: RowNumber     ; the index of row that's currently being scanned, 
;                   ColNumber     ; the index of column that's currently being scanned, 
;                   Keyflag       ; flag indicating whether a key is available
;                   keycode       ; the code of last pressed key. 
;                   debounce_cntr ; debounce counter
;                   repeat_rate   ; rate of auto repeat                 
;                   repeat_cntr   ; repeat Counter 
;  
; Global Variables: None
;
; Input:  None 
; Output: None
;
; Error Handling:  None
;
; Algorithms:      None
; Data Structures: None
;
; Registers Changed:  
;
; Author: Yuqi Zhu
; Last Modified: 11/20/2012

InitKey  PROC NEAR
      PUBLIC InitKey
     MOV keyflag,   0                   ; no key is pressed initially
     MOV rownumber, 0                   ; scanning starts from the first row
     MOV colnumber, 0                   ; initialize colnumber and keycode to 0
     MOV keycode,   0                   ; 
     MOV debounce_cntr,  Debounce_Time  ; debounce function will count Debounce_Time before sets the keyflag
     MOV repeat_rate, SLOW_RATE         ; the repeat_rate is set to the SLOW_RATE initially
     MOV repeat_cntr, FAST_REPEAT_TIME  ; after FAST_REPEAT_TIME, the repeat_cntr will be set to FAST_RATE 
     RET
InitKey ENDP





; GetKey 
;
; Description: This function returns the corresponding code when there is a key available.
; Operation: This function takes no argument and returns the keycode stored in the buffer, which stores the code of the last
;            pressed key.

; Arguments: None
; Return Value: KeyCode  ; The value of the shared variable that stores the code of last pressed key
;
; Local Variables:    None         
; Shared Variables:   keycode      ; The keycode corresponds to the key currently being pressd
; Global Variables:   None
;
; Input: None 
; Output: None
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;

; Registers Changed: Flags, AL
;
; Author: Yuqi Zhu
; Last Modified: 11/20/2012
GetKey PROC NEAR
   PUBLIC GetKey       
CheckKey:               ; check if there's a key available
   Call Isakey          ; Call isakey to reset the zero flag if there's a key available
   JNZ  GetKeyBody      ; going back to the top if no key is available
   JZ CheckKey          ; Otherwise, process the key press
GetKeyBody:             ; store the Keycode to AL
   MOV AL, keycode    
   JMP EndGetKey
EndGetKey:              ; resets the keyflag and we are done
   MOV keyflag, 0
   RET

GetKey ENDP


; Isakey
; Description: This function resets the zero flag if a key is available. 
; Operation: This function resets the zero flag if a key is available; it sets the zero flag otherwise.           
;
; Arguments: None
; Return Value: None
;
; Local Variables: None
; Shared Variables: keyflag ; Flag indicating whether a key is available
; Global Variables: None
;
; Input: None 
; Output: The zero flag will be set if there's a key being pressed. 
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: Flags
;
; Author: Yuqi Zhu
; Last Modified: 11/20/2012
Isakey PROC NEAR
   PUBLIC Isakey        
   CMP keyflag, 0    ; set the zero flag if there's a key available, reset it otherwise.
   RET
Isakey ENDP

; KeyScan
; Description: This function scannes through the rows of keys to check if there's a key being pressed within the row.
;              If there's a key being pressed, it will debounce it, update the repeat_rate, set the keyflag and store
;              its keycode into the buffer. If no key is pressed, the function will scan the next row.
;
; Operation: This function is called by the timer event handler regularly. If there's a key being pressed. A debounce
;            procedure will debounce the currently pressed key and decrement the repeat counter. After the key is fully 
;            debounced, the function sets the keyflag, set the debounce counter to repeat rate and stores the key code
;            into the buffer. If the repeat counter reaches zero, the repeat rate will be updated to fast rate. If no
;            key is being pressed, the function updates the rownumber and resets the debounce_cntr, repeat_rate and
;            repeat_cntr to default value.
;
; Arguments: None
; Return Value: None
;
; Local Variables:  None
; Shared Variables: keyflag              ; flag indicating whether a key is available
;                   rownumber            ; index of the current row being scanned
;                   colnumber            ; index of the column of the key being pressed
;                   keycode              ; key code of the last pressed key
;                   debouncecntr         ; debounce counter
;                   repeat_rate          ; repeat rate
;                   repeat_cntr          ; repeat counter
; Global Variables: None
;
; Input: None 
; Output: None
;
; Error Handling: None
;
; Algorithms: None
; Data Structures: None
;
; Registers Changed: Flags, AX, BX, DX
; Limitations : Can not process multiple key press.
;
; Author: Yuqi Zhu
; Last Modified: 11/20/2012
KeyScan PROC NEAR
        PUBLIC KeyScan 
ScanBody:                               ; scan the row to check if there's key being pressed
                                        ; if so, go ahead to debounce the key. If not, move
                                        ; to the next row and resets the debouncecntr, repeat_rate
                                        ; and repeat_cntr                                        
  MOV DX, keypad_address                ; setup for scanning the current row
  ADD DL, rownumber                     ; store the address of current keypad row to DL
  IN  AL, DX                            ; read the keypad data into AL
  AND AL, low_nibble_mask               ; mask the high_nibbles as we only need the low_nibble.
  CMP AL, non_pressed                   ; check if there's a key being pressed
  JNE  KeyDebounce                      ; if so, we go to the debounce function
  MOV debounce_cntr, Debounce_Time      ; otherwise, we reset the debounce_cntr, repeat_rate and repeat_cntr 
  MOV repeat_rate, SLOW_RATE            ; to default value
  MOV repeat_cntr, FAST_REPEAT_TIME   
  INC rownumber                         ; update the rownumber
  CMP rownumber, Row_Num                ; If reaches the last row, go back to the first row
  JNE EndKeyScan 
  MOV rownumber, 0                   
  JMP EndKeyScan                        ; done and return
KeyDebounce:                            ; decrement the debounce counter
   PUSH AX                              ; save the data read from the keypad
   DEC debounce_cntr                    ; decrement the debounce counter
   CMP debounce_cntr, 0                 ; if the debounce counter haven't reached zero
   JNE AutoRepeat                       ; skip setflag.
   ;JE  SetFlag                         ; otherwise, set the keyflag  

SetFlag:                                ; set the keyflag
   MOV keyflag, 1                       ; set the keyflag to 1
   MOV AX, repeat_rate                  ; update debounce counter to auto repeat rate
   MOV debounce_cntr, AX
   ;JMP AutoRepeat
   
AutoRepeat:                             ; decrement the repeat counter
   DEC repeat_cntr                      ; decrement the repeat counter
   CMP repeat_cntr, 0                   ; if the counter haven't reached 0,
   JNE EndDebounce                      ; we are done with debouncing
   ;JE  UpdateRepeat                    ; otherwise, update the auto repeat rate

UpdateRepeat:                           ; update the repeat rate to fast rate
   MOV repeat_rate, FAST_RATE           
   ;JMP EndDebounce
   
EndDebounce:                            ; if the keyflag is set after the debouncing, store its keycode into the buffer
                                        ; otherwise, we are done with keyscan
   POP AX                               ; restore the data of the keypad into AX
   CMP keyflag, 1                       ; if keyflag wasn't set to 1 after the debounce function         
   JNE EndKeyScan                       ; done with keyscan
   ;JE ColScan                          ; otherwise, store the key code into the buffer

ColScan:                                ; find out the column number of the key pressed
   MOV BX, OFFSET(KeyScanTable)         ; using the KeyScan table, find the column number corresponding to the data obtained from 
   XLAT CS:KeyScanTable                 ; the key address
   MOV colnumber, AL                    ; store the column number in AL
   
StoreKey:                               ; store the keycode of the current pressed key into the buffer
   CMP colnumber, Invalid_value         ; check if the colnumber if valid
   JE  StoreInvalidKey                  ; store the invalid key code if it's invalid, 
                                        ; otherwise, store the corresponding key code
   MOV AL, rownumber                    ; calculate the index of the key pressed
   MOV BL, Col_Num                      ; 
   MUL BL                               ; times the row index with the number of columns on the keypad 
   ADD AL, colnumber                    ; and add the current column index, we get the index of the current pressed key
   CMP currtable, 1
   JE  NumtableHandle
   MOV SI, OFFSET(MainTable)            ; find the keycode corresponding to the pressed key using MainTable
   ADD SI, BX
   MOV AL, [SI].keycode                 ; 
   MOV keycode, AL                      ; store the keycode into buffer
   MOV AL, [SI].nexttable
   MOV currtable, AL
   JMP EndkeyScan                       ; done and return
NumTableHandle:   
   MOV SI, OFFSET(NumTable)             ; find the keycode corresponding to the pressed key using NumTable
   ADD SI, BX
   MOV AL, [SI].keycode                 ; 
   MOV keycode, AL                      ; store the keycode into buffer
   MOV AL, [SI].nexttable
   MOV currtable, AL
   JMP EndkeyScan                       ; done and return

StoreInvalidKey:                        ; store the invalid keycode
   MOV keycode, Invalid_keycode         ; invalid keycode is 16
EndKeyScan:                             ; done and return
  RET 

KeyScan ENDP


; KeyScanTable
;
; Description:      This is the key scan table including the column index of the key being pressed corresponding to the 
;                   data read from the keypad. This table is only useful for single key press. An invalid_value of 16 indicates
;                   no key is being pressed or multiple keys are being pressed
;
; Author:           Yuqi Zhu
; Last Modified:    11/20/2012


KeyScanTable    LABEL   BYTE
         PUBLIC  KeyScanTable
;  DB    colnumber
   DB    Invalid_value    
   DB    Invalid_value
   DB    Invalid_value
   DB    Invalid_value
   DB    Invalid_value
   DB    Invalid_value
   DB    Invalid_value
   DB    0
   DB    Invalid_value
   DB    Invalid_value
   DB    Invalid_value
   DB    1
   DB    Invalid_value   
   DB    2
   DB    3
   DB    Invalid_value
   
; MainTable
; Description:      This table includes the key code corresponding to the key being pressed on the main menu
; Author:           Yuqi Zhu
; Last Modified:    3/31/2013
   
MainTable LABEL  KeyEntry
      PUBLIC  MainTable
;KeyEntry Code
    KeyEntry<'b','main'> 
    KeyEntry<'a','main'>
    KeyEntry<'s','num'>
    KeyEntry<'v','num'>
    KeyEntry<'d','num'>
    KeyEntry<'t','num'>
    KeyEntry<'e','num'>
    KeyEntry<'f','num'>
    KeyEntry<'o','num'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>
    KeyEntry<'*', 'main'>

; NumTable
; Description:      This table includes the key code corresponding to the key being pressed on the number menu
; Author:           Yuqi Zhu
; Last Modified:    3/31/2013

NumTable LABEL KeyEntry
     PUBLIC NumTable

    KeyEntry<'+','num'>
    KeyEntry<'-','num'>
    KeyEntry<'0','num'>
    KeyEntry<'1','num'>
    KeyEntry<'2','num'>
    KeyEntry<'3','num'>
    KeyEntry<'4','num'>
    KeyEntry<'6','num'>
    KeyEntry<'7','num'>
    KeyEntry<'8','num'>
    KeyEntry<'9','num'>
    KeyEntry<'*','num'>
    KeyEntry<'*','num'>
    KeyEntry<'*','num'>
    KeyEntry<13,'main'>

CODE ENDS      



; the data segment
DATA SEGMENT PUBLIC 'DATA'
     keyflag       DB ?                ; keyflag indicating if a key is being pressed
     rownumber     DB ?                ; index of the current row being scanned
     colnumber     DB ?                ; index of the column of the key being pressed
     keycode       DB ?                ; key code of the last pressed key
     debounce_cntr DW ?                ; counter of the debounce time
     repeat_rate   DW ?                ; repeat rate
     repeat_cntr   DW ?                ; repeat counter
     currtable     DW ?                ; current menu table
DATA ENDS
     END
