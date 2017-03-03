Name Parse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Parser                                  ;
;                           Serial Parsing Functions                         ;
;                                   EEgCS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains functions for the Serial parsing functions. 
; The public functions included are:
;
; InitParser () --- Initialization of parser
; ParseSerialChar (c) --- This function parses the character received from the 
;                         serial.
; GetToken (C)        --- This function returns the token type and token value 
;                         of the passed character
; AddSign ()          --- Add sign
; AddDigit ()         --- Add digit and check if there's an overflow
; SignCheck ()        --- Check if the value in the accumulator is proper based 
;                         on the sign
; SignCheckEle ()     --- Check if the passed argument satisfies the requirement
;                         of SetElevation function
; SignHandle ()       --- Multiply the accumulator with the sign
; SetAbsSpeed ()      --- Set the absolute speed of motor
; SetRelSpeed ()      --- Set the relative speed of motor
; SetDirection ()     --- Set the direction of the robostrike
; RotateAngleAbs ()   --- Rotate the turrent, the passed argument is the absolute
;                         angle 
; RotateAngleRel ()   --- Rotate the turret, the passed argument is the relative
;                         angle with respect to the current position
; SetElevation()      --- Set the elevation of the turret
; FireLaser()         --- Fire the laser
; laseroff()          --- Turn off the laser
; seterror()          --- Setup AX to indicate an error happened
; Senderror()         --- Setup AX to RETURNERROR to indicate a non-parsing
;                         error happened 
; DONOP()             --- Do nothing but set AX to 0 to indicate that no error
;                         has happened
;
; Revision History:
; 12/08/2012  Yuqi Zhu Initial Revision 
; 12/14/2012  Yuqi Zhu Update Comments

; locally include file
$INCLUDE(Parse.inc)
$INCLUDE(Constants.inc)

CGROUP GROUP CODE
DGROUP GROUP DATA


; the code segment

CODE   SEGMENT PUBLIC 'CODE'
   
       ASSUME CS:CGROUP, DS:DGROUP


; External Function Declaration
EXTRN SetMotorSpeed     :NEAR     ; Setup the speed and direction of the robostrike
EXTRN GetMotorSpeed     :NEAR     ; Return the speed of motor 
EXTRN GetMotorDirection :NEAR     ; Return the current direction of robostrike's
                                  ; movement
EXTRN SetLaser          :NEAR     ; Turn on/off the laser
EXTRN GetLaser          :NEAR     ; Get the current status of the laser
EXTRN SetTurretAngle    :NEAR     ; Set the absolute angle of the turret
EXTRN GetTurretAngle    :NEAR     ; Get the angle of the turret
EXTRN SetRelTurretAngle :NEAR     ; Set the relative angle of the turret 
EXTRN SetTurretElevation:NEAR     ; Set the elevation angle of the turret
EXTRN GetTurretElevation:NEAR     ; Get the current elevation of the turret

; InitParser()
; Description: Initialization of the shared variable.
; Operation:   This function initializes all the shared vaiable to 0.
; Arguments:    None
; Return Value: None 
;
; Local Variables:  None
; Shared Variables: Accumulator   --- The accumulated value that received so far
;                                     (changed)
;                   SIGN          --- Buffer for the sign (changed) 
;                   current_state --- Current state in the state machine (changed)
;
; Global Variables: None
;
; Input:            None 
; Output:           None
;
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  None
;
; Registers Changed: None
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


 InitParse PROC NEAR
       PUBLIC InitParse
    MOV accumulator, 0                   ; Clear the accumulator
    MOV SIGN, 0                          ; Clear the sign buffer
    MOV current_state, INITIAL_STATE     ; Initialize to INITIAL_STATE 
    RET
InitParse ENDP


; ParseSerialChar(c)
; Description: This function is passed a single character and uses a state machine
;              to parse it. AX will be set to 0 if no error happened, a non-zero 
;              value in AX indicates an error. 
;
; Operation:   Firstly, this function calls GetToken to determine the token type
;              and token value of the passed character. Then, the function will 
;              use the transition table, along with the token type and token value
;              to obtain the action and next state. Action function will set AX
;              to a non-zero value if there's an error happened during the action
;              In case of an error happened, the state machine will go to either
;              ERROR_STATE or INITIAL_STATE based on the error type. If no error
;              is happened, the state machine will go to the next_state that's 
;              specified in the transition table. A return error is an error that's
;              happened after pressing return.
;
; Arguments:    AL  --- The passed character
; Return Value: None 
;
; Local Variables:  None
; Shared Variables: Accumulator   --- The accumulated value that received so far
;                                     (changed)
;                   SIGN          --- Buffer for the sign (changed) 
;                   current_state --- Current state in the state machine (changed)
; Global Variables: None
;
; Input:            None 
; Output:           None
;
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  None
;
; Registers Changed: AX, BX, CX, DX, Flags 
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


ParseSerialChar PROC NEAR                  
           PUBLIC ParseSerialChar
           
GetTokenBody:
    CALL GetToken                         ; Call gettoken to get the token_type
                                          ; and token_value 
    MOV CL, BL                            ; Store the token_type and token_value
    MOV CH, BH                            ; into BL, BH respectively
GetOffset:
    MOV BL, NUM_TYPES                     ; Setup for calculating the offset
    MOV AL, CURRENT_STATE                 ; The product of the number of types
    MUL BL                                ; and the index of the current state
                                          ; is the index of the first entry in the 
                                          ; current state
    ADD AL, CH                            ; Adding the index of the token type to
                                          ; the product yields the index of the
                                          ; current transition entry
    ADC AH, 0                             ; Add the overflow bit to AH, now AX
                                          ; is the index of the current entry
    IMUL BX, AX, SIZE TRANSITION_ENTRY    ; The product of the size of each entry
                                          ; and the index of current entry is the
                                          ; offset of the current entry
ActionAndUpate:                           ; Do the action and update the state 
    MOV AL, CL                            ; Store the token_value into AL
    CALL CS:statetable[BX].ACTION         ; Call the action function
    CMP AX, RETURNERROR                   ; Check if there's a return error
                                          ; happened during the action
    JE  SetReTurnError                    ; If so, jump to the step handling it
    CMP AX, 0                             ; Otherwise, check if there's other
                                          ; error
    JNE SetErrorState                     ; If so, jump to the step handling it
    MOV CL, CS:statetable[BX].NEXTSTATE   ; If no error happened, update current
                                          ; state to nextstate 
    MOV current_state, CL             
    JMP EndParse                          ; Done and return
SetReturnError:                           ; In case of a return error, go to
    CALL InitParse                        ; initial state and initialize the 
    JMP EndParse                          ; shared variable
SetErrorState:                            ; In case of a non return error
    CALL SetError                         ; Call SetError to initialize the
                                          ; shared variable and setup AX
    MOV CURRENT_STATE, ERROR_STATE        ; Move to the error state
EndParse:   
    RET                                   ; Done
ParseSerialChar ENDP
    

    
; GetToken()
; Description:  This function returns the Token_value and Token_type of the passed
;               ASCII character in AL
;
; Operation:    This function uses the TokenValueTable and TokenTypeTable to 
;               find out the Token value and Token type of the passed character
;               
;
; Arguments:          AL --- The passed ASCII character 
; Return Value:       BL --- Token value
;                     BH --- Token type 
;
; Local Variables:    None
; Shared Variables:   None
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AH, BX, SI
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


GetToken PROC NEAR
       PUBLIC GetToken
    MOV AH, 0                        ; Clear AH. As SI can only be written by
                                     ; a 16 bit register
    MOV SI, AX                       ; Setup SI to the offset on the table
    MOV BL, CS:TokenValueTable[SI]   ; Retrieve the token value and the token 
    MOV BH, CS:TokenTypeTable[SI]    ; type
    RET
GetToken ENDP



; AddSign()
; Description:  This function updates the SIGN.
;
; Operation:    Stores 1 into SIGN if a positive sign is passed or -1 into SIGN
;               if a negative sign is passed.
;
; Arguments:          AL --- Token_value of the sign, 1 for positive sign and -1
;                            for negative sign
; Return Value:       AX --- Error Indicator, cleared to show that no error is 
;                            happened
;
; Local Variables:    None
; Shared Variables:   SIGN  --- Sign buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012



AddSign PROC NEAR
       PUBLIC AddSign
    CMP AL, 1                ; If a positive sign is passed
    JE  SetPositive          ; Store POS_SIGN into SIGN buffer
    ;JNE SetNegative         ; Otherwise, store NEG_SIGN
SetNegative:                 ; Store NEG_SIGN into SIGN
    MOV SIGN, NEG_SIGN
    JMP EndAddSign
SetPositive:                 ; Store POS_SIGN into SIGN
    MOV SIGN, POS_SIGN
    JMP EndAddSign
EndAddSign:                  ; No error happened
    MOV AX, 0
    RET
AddSign ENDP



; AddDigit()
; Description:  This function updates the accumulator. If an overflow happensm 
;               the function will set AX to 1.
; Operation:    This function updates the accumulator by multiplying the previous
;               accumulator value by 10 and adding the passed digit. If an overflow
;               happened, the function will return 1 in AX.
;               
; Arguments:          AL --- Passed digit 
; Return Value:       AX --- Error indicator
;
; Local Variables:    None
; Shared Variables:   accumulator --- Accumulated value (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, CX, DX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

AddDigit PROC NEAR
       PUBLIC AddDigit
    PUSH BX               ; Save BX as BX is the address of the transtion entry
    MOV CL, AL            ; Save the digit into CX as AX is used for multiplication
    MOV CH, 0
    MOV AX, accumulator   ; Multiply the current accumulator by 10
    MOV BX, 10
    MUL BX
    ADD AX, CX            ; Add the passed digit
    ADC DX, 0             ; Check if there's an overflow bit
    CMP DX, 0             
    JNE AddDigitError     ; If so, set AX to 1 to indicate an overflow error
    MOV accumulator, AX   ; Otherwise, update accumulator
    MOV AX, 0             ; No error happened
    JMP Endadddigit
AddDigitError:            ; If there's an overflow, set AX to 1
    MOV AX, 1
EndAddDigit:              ; Retrieve value of BX
    POP BX
    RET
AddDigit ENDP    


; SignCheck()
; Description:  This function checks if the value in the accumulator violates the
;               SIGN. If so, a RETURNERROR will be stored in AX. A positive sign
;               must have value less or equal to 32767, a negative sign must have 
;               value less or equal to 32768. No sign doesn't have any restriction
;               for its value.
; Operation:    Checks if the value in the accumulator meets the requirement of 
;               the SIGN. If not, a RETURNERROR will be passed through AX.
;               
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN          --- Sign buffer  (read)
;                     accumulator   --- Accumulated value buffer (read)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SignCheck PROC NEAR
       PUBLIC SignCheck
SignCheckBody:               ; Check if there's a SIGN
    CMP SIGN, POS_SIGN       ; If so, jump to the appropriate handler
	JE PosCheck
	CMP SIGN, NEG_SIGN
	JE NegCheck            
	MOV AX, 0                ; Otherwise, clear AX to indicate no error happened
	JMP EndCheck             ; Done
PosCheck:                    ; Check if the signed-value is positive
    MOV AX, accumulator     
	CMP AX, 0
	JL SetCheckError         ; If not, jump to the error handler
	MOV AX, 0                ; Otherwise, clear AX to indicate no error's happened
    JMP EndCheck
NegCheck:                    ; Check if the unsigned-value is less than or equal
                             ; to 08000h 
    MOV AX, accumulator
	CMP AX, 08000h
	JA SetCheckError         ; If not, jump to error handler
	MOV AX, 0                ; Otherwise, no error happened and we are done
    JMP EndCheck
SetCheckError:               ; Send RETURNERROR to AX
    MOV AX, RETURNERROR
EndCheck:
    RET
SignCheck ENDP	


; SignCheckEle()
; Description:  This function checks if the combination of sign and accumulator
;               satisfies the requirement of the SetElevation function. If there's
;               a sign, then accumulator must be a non-negative value less or equal
;               to 60. If there's no sign, then the absolute value of the accumulator
;               must be less or equal to 60. If any of those requirements is 
;               violated, a RETURNERROR will be send to AX.
;
; Operation:    Check if the absolute value of the passed argument for set elevation 
;               command is larger than 60. If so, this function will return 
;               RETURNERROR in AX. 
;               
;
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (read)
;                     accumulator --- The accumulated value buffer (read)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SignCheckEle PROC NEAR
       PUBLIC SignCheckEle

    CMP SIGN, 0                     ; Check if there's a sign and jump to the
	JE  NoSignCheckEleBody          ; corresponding handler
	JMP SignCheckEleBody            
NoSignCheckEleBody:                 ; If there's no sign, check if the absolute
    MOV AX, accumulator             ; value of accumulator is larger than 60
	CMP AX, 60
	JG SetErrorEle                  ; If so, set AX
	CMP AX, -60
	JL SetErrorEle
	MOV AX, 0                       ; Otherwise, there's no error and we are done
    JMP EndCheckEle
SignCheckEleBody:                   ; If there's a sign, check if the accumulator
    MOV AX, accumulator             ; is a non-negative value that's less or equal
	CMP AX, 60                      ; to 60.
	JA SetErrorEle                  ; If it's violated, set AX
	MOV AX, 0                       ; Otherwise, there's no error and we are done
    JMP EndCheckEle
SetErrorEle:                        ; Set AX to RETURNERROR
    MOV AX, RETURNERROR
EndCheckEle:
    RET
SignCheckEle ENDP	


; SignHandle()
; Description:  This function integrates sign into accumulator.
; Operation:    If there's a sign, this function multiplies the sign with the
;               accumulator. If there's no sign, the function leaves the accumulator
;               unchanged.               
;
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (read)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, BX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SignHandle PROC NEAR
       PUBLIC SignHandle
    CMP SIGN, 0                   ; Check if there's a sign
    JE EndSignHandle              ; If so, we are done 
    MOV BX, SIGN                  ; Otherwise, multiply accumulator with SIGN
    MOV AX, accumulator
    IMUL BX	
	MOV accumulator, AX
EndSignHandle:                    ; Done
    RET
SignHandle ENDP


; SetAbsSpeed()
; Description:  This function sets the absolute speed of the motor based on the
;               SIGN and accumulator. If there's an RETURNERROR in the value of 
;               accumulator or SIGN, this function returns RETURNERROR in AX. 
;               Otherwise, AX is cleared to 0
; Operation:    Check if there's nagative SIGN. If so, generates a RETURNERROR. 
;               Otherwise, call SignCheck to check if the value of accumulator fits
;               in 15-bits. If not, return RETURNERROR in AX. Otherwise, call
;               SetMotorSpeed to update the speed of motor and clear AX to indicate
;               no error happened.
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SetAbsSpeed PROC NEAR
          PUBLIC SetAbsSpeed
    PUSH BX                       ; Save BX as BX stores the index of current
                                  ; transition entry
	CMP SIGN, -1                  ; Check if there's a negative SIGN
	JE SetAbsSpeedError           ; If so, generate an error
	MOV SIGN, 1                   ; Otherwise, assume there's a positive sign
                                  ; and call SignCheck to check if the value
                                  ; of accumulator fits in 15-bits
    CALL SignCheck
    CMP AX, RETURNERROR           ; If an error has been generated, return the
                                  ; error and done
    JE EndSetAbsSpeed
    MOV AX, accumulator           ; Otherwise, setup the speed and angle argument
                                  ; and call SetMotorSpeed. IGNORE_ANGLE will 
                                  ; leave the angle unchanged
    MOV BX, IGNORE_ANGLE
    CALL SetMotorSpeed            ; Call SetMotorSpeed
    MOV SIGN, 0                   ; Clear SIGN
    MOV accumulator, 0            ; Clear accumulator
    MOV AX, 0                     ; There's no error and we are done
    JMP EndSetAbsSpeed
SetAbsSpeedError:                 ; Return RETURNERROR in AX
    MOV AX, RETURNERROR
EndSetAbsSpeed:  
    POP BX                        ; Retrieve BX and return
    RET
SetAbsSpeed ENDP
    
 
    
; SetRelSpeed()
; Description:  This function sets the relative speed of the motor based on the
;               SIGN and accumulator. If there's an RETURNERROR in the value of 
;               accumulator or SIGN, this function returns RETURNERROR in AX. 
;               Otherwise, AX is cleared to 0. If after the change, the speed is
;               negative, the speed will be truncated to 0 and the motor will be
;               halted. If the speed exceeds MAXIMUM_SPEED after the change, the
;               speed will be truncated to MAXIMUM_SPEED.
; Operation:    Call SignCheck to check if the value in accumulator satisfies the
;               restriction of SIGN. Genreate an error if there's a violation.
;               If there's no error, call GetMotorSpeed to get the current speed.
;               If the relative speed argument is negative, check if the updated
;               speed is negative; truncated to 0 if so. If the speed argument is 
;               positive, check if the updated speed exceeds MAXIMUM_SPEED; if so,
;               truncated the speed to MAXIMUM_SPEED. Finally, set angle argument
;               to IGNORE_ANGLE and call SetMotorSpeed to update the speed and 
;               clear AX to indicate no error.
;               
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, DX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


SetRelSpeed PROC NEAR
           PUBLIC SetRelSpeed
    PUSH BX                   ; Store the value of BX
	CALL SignCheck            ; Check if there's an error in the value of
                              ; accumulator
    CMP AX, RETURNERROR       ; If so, return the error in AX and done
	JE EndSetRelSpeed
    CALL SignHandle           ; Otherwise, integrate SIGN into accumulator
    CMP accumulator, 0        ; Check if accumulator is negative
    JL HandleNegativeSpeed    ; If so, go the negative speed handler
                              ; Otherwise, use the positive speed handler
    CALL GetMotorSpeed        ; Call GetMotorSpeed to obtain the current speed
    ADD AX, accumulator       ; Update the speed and check if it exceeds 
    ADC DX, 0                 ; MAXIMUM_SPEED
    CMP DX, 0                 ; Check if there's an overflow
    JNE SetMaximum            ; If so, truncate speed to MAXIMUM_SPEED
    CMP AX, MAXIMUM_SPEED     ; Check if AX exceeds MAXIMUM_SPEED
    JA  SetMaximum            ; If so, truncate speed to MAXIMUM_SPEED
    JMP SetSpeed              ; If none of these special conditions happened,
                              ; call SetMotorSpeed to set the speed
HandleNegativeSpeed:          ; Handle the negative relative speed
	CALL GetMotorSpeed        ; Call GetMotorSpeed to obtain the current speed
    IMUL BX, accumulator, -1  ; Check if the absolute value of accumulator
    CMP AX, BX                ; exceeds the current speed
    JB SetZero                ; If so, the updated speed will be negative and thus
                              ; should be truncated to 0
    ADD AX, accumulator       ; Otherwise, update the speed and send the speed
                              ; to motor
    JMP SetSpeed
SetMaximum:
    MOV AX, MAXIMUM_SPEED     ; Truncate speed to MAXIMUM_SPEED
    JMP SetSpeed    
SetZero:                      ; Clear speed 
    MOV AX, 0    
SetSpeed:                     
    MOV BX, IGNORE_ANGLE      ; Set the angle argument to IGNORE_ANGLE to keep
                              ; the current angle
    CALL SetMotorSpeed        ; Update the direction and speed of Robostrike
    MOV SIGN, 0               ; Initialize the shared variables 
    MOV accumulator, 0 
    MOV AX, 0                 ; No error happened
EndSetRelSpeed:	
    POP BX                    ; Restore BX and done
    RET
SetRelSpeed    ENDP    
    

; SetDirection()
; Description:  This function updates the direction of the Robostrike. If there's
;               an error in the value of the accumulator, a RETURNERROR will be
;               returned in AX. Otherwise, the function calls SetMotorSpeed to
;               update the direction and clears AX to indicate no error.
; Operation:    Call SignCheck to check if there's a error in the value of 
;               accumulator and sets AX if so. Then the angle argument is truncated
;               to the remainder when divided by TWOPI and added with the current
;               angle. Finally, set speed argument to IGNORE_SPEED and call
;               SetMotorSpeed to update the direction and clear AX to indicate
;               no error.
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, CX, DX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SetDirection PROC NEAR
          PUBLIC SetDirection
    PUSH BX                     ; Store the value of BX
	CALL SignCheck              ; Check if there's an error in accumulator
    CMP AX, RETURNERROR         ; If so, return the error in AX
	JE EndSetDirection
	CALL SignHandle             ; Integrate SIGN into accumulator
    MOV AX, accumulator         ; Divide the angle argument by TWOPI
    CWD 
    MOV CX, TWOPI
    IDIV CX
    MOV BX, DX                  ; Store the remainder into BX
    CALL GetMotorDirection      ; Call GetMotorDirection to get the current
                                ; angle and add that to BX
    ADD BX, AX 
SendAngle:    
    MOV AX, IGNORE_SPEED        ; Set the speed argument to IGNORE_SPEED
    CALL SetMotorSpeed          ; Call SetMotorSpeed to update the direction
    MOV SIGN, 0                 ; Initialize the shared variables
    MOV accumulator, 0
    MOV AX, 0                   ; No error
EndSetDirection:	
    POP BX                      ; Restore the value of BX
    RET
SetDirection ENDP


; RotateTurretAbs()
; Description:  This function rotates the turret to an absolute angle and clears
;               AX to indicate no error.
; Operation:    If the passed angle is negative, truncates it to the remainder 
;               when divided by TWOPI as SetTurretAngle only accepts positive value.
;               Call SetTurretAngle to set the turret angle and clear AX to indicate 
;               no error.
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, DX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


RotateTurretAbs PROC NEAR
       PUBLIC RotateTurretAbs
    PUSH BX                       ; Store the value of BX
    MOV AX, accumulator           ; Check if the angle argument is negative
    CMP AX, 0
    JB SetNegativeAngle           ; If so, jump to negative angle handler
    JMP SetAngle                  ; Otherwise, update the turret angle
SetNegativeAngle:    
    MOV BX, TWOPI                 ; Setup for finding the remainder of the angle
    MOV DX, 0FFFFh                ; argument when divided by TWOPI
    IDIV BX
    ADD DX, TWOPI
    MOV AX, DX                    ; Store the remainder into AX
SetAngle:
    CALL SetTurretAngle           ; Call SetTurretAngle to update the turret angle
    MOV accumulator, 0            ; Initialize the shared variable
    MOV SIGN, 0
    MOV AX, 0                     ; No error
    POP BX                        ; Restore BX
    RET
RotateTurretAbs ENDP

; RotateTurretRel()
; Description:  This function returns RETURNERROR in AX if there's an error in
;               the value of accumulator. Otherwise, it calls SetRelTurretAngle
;               to rotate the turret and clear AX.
; Operation:    Call SignCheck first to check if there's an error in accumulator;
;               set AX if so. Otherwise, call SetRelTurretAngle to update the 
;               turret angle and clear AX.
;
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


RotateTurretRel PROC NEAR
       PUBLIC RotateTurretRel
    PUSH BX                         ; Store the value of BX
	CALL SignCheck                  ; Check if there's an error in accumulator
    CMP AX, RETURNERROR
	JE EndRotateTurretRel           ; Return the error if so
    CALL SignHandle	                ; Integrate the SIGN into accumulator
    MOV AX, accumulator        
    CALL SetRelTurretAngle          ; Call SetRelTurretAngle to update the turret
                                    ; angle  
    MOV accumulator, 0              ; Clear the shared variables
    MOV SIGN, 0
    MOV AX, 0                       ; No error
EndRotateTurretRel:                 
    POP BX                          ; Restore BX
    RET
RotateTurretRel ENDP


; SetElevation()
; Description:  This function checks if there's error in the value of accumulator
;               and generate an error if so. If there's no error, this function
;               calls SetTurretElevation to upate the Turret Elevation angle.
;               The angle argument has to be between -60 and 60.
; Operation:    Call SignCheckEle to check if there's a error in the value of 
;               accumulator and sets AX if so. Otherwise, it calls SetTurretElevation
;               and clears AX
; Arguments:          None
; Return Value:       AX --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN        --- The sign buffer (changed)
;                     accumulator --- The accumulated value buffer (changed)
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX, Flags
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


SetElevation PROC NEAR
     PUBLIC SetElevation
    PUSH BX                       ; Save BX
	CALL SignCheckEle             ; Check if the angle argument is between -60 and
                                  ; 60
    CMP AX, RETURNERROR           ; If not, return RETURNERROR in AX
	JE EndSetElevation
    CALL SignHandle	              ; Integrate SIGN with the accumulator
    MOV AX, accumulator           
    CALL SetTurretElevation       ; Update the turret elevation                 
	MOV SIGN, 0                   ; Initialize the shared variables
    MOV accumulator, 0 
    MOV AX, 0                     ; No error
    JMP EndSetElevation
EndSetElevation: 
    POP BX                        ; Restore BX
    RET
SetElevation ENDP

; FireLaser()
; Description:  This function turns on the laser.
; Operation:    This function calls SetLaser to turn on the laser.
;               
; Arguments:          None
; Return Value:       AX  --- Error Indicator 
;
; Local Variables:    None
; Shared Variables:   None
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012
FireLaser PROC NEAR
     PUBLIC FireLaser
    MOV AX, 1         ; Setlaser uses AX as a state indicator; 1 means on_state
    CALL SetLaser     ; Call setlaser to turn on the laser
    MOV AX, 0         ; No error happened
    RET
FireLaser ENDP



; laseroff()
; Description:  This function turns off the laser
;
; Operation:    This function calls SetLaser to turn off the laser
;               
; Arguments:          None
; Return Value:       AX--- Error indicator
;
; Local Variables:    None
; Shared Variables:   None
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012
LaserOff PROC NEAR
    PUBLIC LaserOff
    MOV AX, 0              ; SetLaser takes AX as state indicator ; a 0 value means
                           ; off_state
    CALL SetLaser          ; Call the SetLaser function
    MOV AX, 0              ; Clear AX to indicate no error has happened
    RET
LaserOff ENDP  

  
; SetError()
; Description:  This is the non return error handler. It clears the shared variable
;               and sets AX to indicate an error has happened  
; Operation:    This function sets AX to indicate a non return error has happened
;               and initializes the other shared variable.
;               
;
; Arguments:          None
; Return Value:       AX --- The error indicator 
;
; Local Variables:    None
; Shared Variables:   SIGN  --- The sign buffer (changed)
;                     accumulator --- The accumulated value (changed)
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012

SetError PROC NEAR
      PUBLIC SetError
    MOV SIGN, 0            ; Clear the SIGN buffer and accumulator
    MOV accumulator, 0
    MOV AX, 1              ; Set AX to indicate a non-return error happened 
    RET
SetError ENDP

; SendError()
; Description:  This function send a returnerror using AX
; Operation:    Setting AX to RETURNERROR to indicate a return error has happened
;               
;
; Arguments:          None
; Return Value:       AX --- The error indicator
;
; Local Variables:    None
; Shared Variables:   None
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX
;
; Author: Yuqi Zhu
; Last Modified: 12/14/2012


SendError PROC NEAR
       PUBLIC SendError
    MOV AX, RETURNERROR   ; Set AX to indicate a return error has happened
    RET
SendError ENDP


; DONOP()
; Description:  Do nothing.
;
; Operation:    This function does nothing but clear AX to indicate no error has
;               has happened.
;               
; Arguments:          None
; Return Value:       AX --- AX is cleared to indicate no error has happened 
;
; Local Variables:    None
; Shared Variables:   None
;
; Global Variables:   None
;
; Input:              None 
; Output:             None
;
; Error Handling:     None
;
; Algorithms:         None
; Data Structures:    None
;
; Registers Changed:  AX
;
; Author: Yuqi Zhu
; Last Modified: 12/07/2012


DONOP PROC NEAR
       PUBLIC DONOP
    MOV AX, 0    ; Clear AX as no error happened
    RET
DONOP ENDP


; Define a macro to make table a little more readable
; macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act) >
)

; StateTable
; 
; Description:      This table contains the transition entries for each state.
;                   Each entry consists a next state and an action.
;
; Author:           Yuqi Zhu
; Last Modified:    12/14/2012


StateTable	LABEL	TRANSITION_ENTRY
; CURRENT_STATE = INITIAL_STATE
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(SET_ABS_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(SET_REL_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(SET_DIRECTION, DONOP)              ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ROTATE_TURRET, DONOP)              ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(SET_ELEVATION, DONOP)              ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(FIRE_LASER, DONOP)                 ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(LASER_OFF, DONOP)                  ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, DONOP)              ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(INITIAL_STATE, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
 
; CURRENT_STATE = SET_ABS_SPEED
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(SET_ABS_SPEED_SIGN, AddSign)       ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ABS_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ABS_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = SET_ABS_SPEED_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ABS_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ABS_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE  
; CURRENT_STATE = SET_ABS_SPEED_VAL
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ABS_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SetAbsSpeed)        ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ABS_SPEED_VAL, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = SET_REL_SPEED
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(SET_REL_SPEED_SIGN, AddSign)       ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_REL_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_REL_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = SET_REL_SPEED_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_REL_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_REL_SPEED, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE   
; CURRENT_STATE = SET_REL_SPEED_VAL
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_REL_SPEED_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SetRelSpeed)        ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_REL_SPEED_VAL, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE 
; CURRENT_STATE = SET_DIRECTION
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(SET_DIRECTION_SIGN, AddSign)       ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_DIRECTION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_DIRECTION, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE  
; CURRENT_STATE = SET_DIRECTION_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_DIRECTION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_DIRECTION, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE 
; CURRENT_STATE = SET_DIRECTION_VAL
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_DIRECTION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SetDirection)       ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_DIRECTION_VAL, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE 
; CURRENT_STATE = ROTATE_TURRET
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ROTATE_TURRET_SIGN, AddSign)       ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ROTATE_TURRET_ABS, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(ROTATE_TURRET, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = ROTATE_TURRET_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ROTATE_TURRET_REL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(ROTATE_TURRET, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE   
; CURRENT_STATE = ROTATE_TURRET_REL
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ROTATE_TURRET_REL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, RotateTurretRel)    ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(ROTATE_TURRET_REL, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE   
; CURRENT_STATE = ROTATE_TURRET_ABS
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ROTATE_TURRET_ABS, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, RotateTurretAbs)    ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(ROTATE_TURRET_ABS, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE 
; CURRENT_STATE = SET_ELEVATION
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(SET_ELEVATION_SIGN, AddSign)       ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ELEVATION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ELEVATION, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = SET_ELEVATION_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ELEVATION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SendError)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ELEVATION, DONOP)              ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = SET_ELEVATION_VAL
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(SET_ELEVATION_VAL, AddDigit)       ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, SetElevation)       ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(SET_ELEVATION_VAL, DONOP)          ; TOKEN_TYPE = TOKEN_SPACE    
; CURRENT_STATE = FIRE_LASER
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, FireLaser)          ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(FIRE_LASER, DONOP)                 ; TOKEN_TYPE = TOKEN_SPACE
; CURRENT_STATE = LASER_OFF
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, LaserOff)           ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(LASER_OFF, DONOP)                  ; TOKEN_TYPE = TOKEN_SPACE 
; CURRENT_STATE = ERROR_STATE
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_OTHER 
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_S
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_V
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_D
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_T
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_E
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_F
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_O
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_SIGN
   %TRANSITION(ERROR_STATE, SetError)             ; TOKEN_TYPE = TOKEN_DIGIT
   %TRANSITION(INITIAL_STATE, DONOP)              ; TOKEN_TYPE = TOKEN_ETR
   %TRANSITION(ERROR_STATE, DONOP)                ; TOKEN_TYPE = TOKEN_SPACE 

   
; TOKEN Tables
;
; Description:      This creates the tables of TOKEN types and TOKEN values.
;                   Each entry corresponds to the TOKEN type and the TOKEN
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TOKENTypeTable for TOKEN types and
;                   TOKENValueTable for TOKEN values.
;
; Author:           Glen George, Yuqi Zhu
; Last Modified:    12/14/2012

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)		;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_SPACE, 9)		;TAB
        %TABENT(TOKEN_OTHER, 10)    ;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_ETR, 13)	    ;carriage return
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_SPACE, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_SIGN, +1)  ;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_SIGN, -1)  ;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_D, 'D')    	;D
        %TABENT(TOKEN_E, 'E') 		;E  
        %TABENT(TOKEN_F, 'F')	    ;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_O, 'O')    	;O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S, 'S')	    ;S
        %TABENT(TOKEN_T, 'T')	    ;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_V, 'V')    	;V
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_D, 'd')    	;d
        %TABENT(TOKEN_E, 'e')		;e  (exponent indicator)
        %TABENT(TOKEN_F, 'f')	    ;f
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_O, 'o')	;o
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_S, 's')    	;s
        %TABENT(TOKEN_T, 't')   	;t
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_V, 'v')   	;v
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)  

; TOKEN type table - uses first byte of macro table entry
%*DEFINE(TABENT(TOKENtype, TOKENvalue))  (
        DB      %TOKENtype
)

; TOKENTypeTable
;
; Description:      This table contains the TOKEN type for each character
;
; Author:           Glen George, Yuqi Zhu
; Last Modified:    12/14/2012

TOKENTypeTable	LABEL   BYTE
        %TABLE


; TOKEN value table - uses second byte of macro table entry
%*DEFINE(TABENT(TOKENtype, TOKENvalue))  (
        DB      %TOKENvalue
)

; TOKENValueTable
;
; Description:      This table contains the TOKEN value for each character
;
; Author:           Glen George, Yuqi Zhu
; Last Modified:    12/14/2012

TOKENValueTable	LABEL       BYTE
        %TABLE
        
CODE ENDS
    
     
;data segment     
DATA SEGMENT PUBLIC 'DATA'
    current_state DB ?        ; Index of current state
    accumulator   DW ?        ; buffer for accumulated value
    SIGN          DW ?        ; SIGN buffer
DATA ENDS
     END
