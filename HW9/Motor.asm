Name Motor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Motor                                   ;
;                               Motor Functions                              ;
;                                   EEgCS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains functions for the motor. 
; The public functions included are:
; SetMotorSpeed(speed, angle)  --- set the speed and direction of the Robotrike
; GetMotorSpeed()              --- Get the current speed of Robotrike
; GetMotorDirection()          --- Get the current direction of Robotrike
; SetLaser(onoff)              --- switch the laser
; GetLaser()                   --- Get the laser status
; ParallelIO                   --- Send the control bits to PortB
;
; Revision History:
; 11/27/2012  Yuqi Zhu  Initial Revision 
; 11/28/2012  Yuqi Zhu  fixed bugs in ParallelIO
;                       fixed bugs in setlaser
; 11/29/2012  Yuqi Zhu  fixed bugs in setmotorspeed
; 11/30/2012  Yuqi Zhu  updated comments
; 12/2/2012   Yuqi Zhu  updated comments
; locally include file
$INCLUDE(Motor.inc)
$INCLUDE(Constants.inc)

CGROUP GROUP CODE
DGROUP GROUP DATA


; the code segment

CODE   SEGMENT PUBLIC 'CODE'
   
       ASSUME CS:CGROUP, DS:DGROUP


; External Function Declaration
    EXTRN Sin_Table:WORD   ; Table that includes the sin value for each degree
    EXTRN Cos_Table:WORD   ; Table that includes the cos value for each degree
;
; InitMotor
; Description:       This function initialized all the shared variables.
; Operation:         The speed of the three wheels and the robostrike are all 0
;                    initially, as well as the angle of the movement. The laser
;                    is off.
;
; Arguments:         None
; Return Value:      None 
;
; Local Variables:   None
; Shared Variables:  wspeed      --- The buffer stores the speed of three wheels 
;                                    (changed)                   
;                    currspeed   --- The total speed of robostrike (changed)
;                    currangle   --- The direction of the movement (changed)
;                    laserflag   --- The flag indicating the status of the laser
;                                    (changed)
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   None
;
; Registers Changed: AX, CX, DX, SI, flags 
;
; Author:            Yuqi Zhu
; Last Modified:     11/30/2012
InitMotor PROC NEAR              ; Initialize the shared variables
     PUBLIC InitMotor
InitBody:                        
    MOV DX, PIOctrladdr          ; Initialize the Parallel IO control register
    MOV AX, PIOctrlval           
    OUT DX, AL                   ; Send the value to the 
                                 ; Parallel IO control register
    MOV Vx, 0                    ; The x,y components of currspeed is 0 initially
    MOV Vy, 0                    ; 
    MOV currspeed, 0             ; The robostrike is not moving initially
    MOV currangle, 0             ; The direction of movement is orientation of 
                                 ; robostrike initially
    MOV laserflag, 0             ; The laser is off initially
    MOV SI, OFFSET(wspeed)       ; Setup for initializing the speed of three
                                 ; wheels
    MOV CX, WHEEL_NUM            ; setup for looping
InitSpeed:                       ; Initialize the speed of three wheels to 0
    XOR AL, AL                   ; Setup AL to initialize the wspeed buffer
    MOV DS:[SI], AL
    INC SI                       ; Move to the speed of next WHEEL_NUM
    LOOP InitSpeed               
EndLoop:                         ; Done and return
    RET
InitMotor ENDP    
    
    
    
; SetMotorSpeed(speed, angle)
; Description: The speed is passed in AX and is the absolute speed at which the
;              robostrike is run. A speed of 65535 indicates the current speed 
;              will not be changed. The angle is passed in BX and is the signed 
;              angle at which the robostrike moves, with 0 degree being the 
;              direction of robostrike orientation. An angle of -32768 indicates 
;              the current direction will not be changed. This function updates
;              the x,y components of the overall speed, the overall speed, angle 
;              of movement for robotrike. and the speed of three wheels.  
; Operation:   This function updates the overall speed if the passed speed is 
;              not 65535. It updates the angle of movement if the passed angle
;              is not -32768. Then the function uses fixed point arithmetics to
;              calculate the x,y component of overall speed and the speed of 
;              three wheels. The x,y component of overall speed is calculated by 
;              multiplying the overall speed with the cos and sin value of the 
;              angle and then truncating the upper 16-bit. The speed of three 
;              wheels is calculated by multiplying the x,y component of the 
;              speed with the position vector of each wheels, truncating the 
;              result to the upper 16-bits and finally multiplying by 4. The 
;              resulting speed for three wheels is a signed 8-bits value. A
;              negative value indicates the wheel moves reversely. 
;          
;
; Arguments:         AX(speed) --- The speed to update, a value of 65536 indicates
;                                  the current speed will not be changed
;                    BX(angle) --- The angle to update, a value of -32768 indicates
;                                  the current angle should not be changed
; Return Value:      None 
;
; Local Variables: 
; Shared Variables:  Vx        --- The x-component of the overall speed (changed)
;                    Vy        --- The y-component of the overall speed (changed)
;                    wspeed    --- The buffer stores the speed of 3 wheels (changed)
;                    currspeed --- The current overall speed of the robostrike 
;                                  (changed)
;                    currangle --- The current angle of the movement (changed)
;
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   Array
;
; Registers Changed: AX, BX, CX, DX, SI, flags
;
; Author:            Yuqi Zhu
; Last Modified:     11/30/2012

SetMotorSpeed PROC NEAR          ;  Update the speed and angle of the robostrike
         PUBLIC SetMotorSpeed    ;  as well as the speed of three wheels
UpdateSpeed:                     ;  Update the speed of robostrike if the passed 
                                 ;  speed is not IGNORE_SPEED
    MOV   CX, IGNORE_SPEED       ;  Check if the speed is IGNORE_SPEED
    CMP   AX, CX                 
    JE    UpdateAngle            ;  If so, don't change the speed 
    MOV   currspeed, AX          ;  Otherwise, update speed 

UpdateAngle:                     ;  Update the angle of robostrike if the passed
                                 ;  speed is not IGNORE_ANGLE 
    CMP   BX, IGNORE_ANGLE       ;  Check if the angle is IGNORE_ANGLE
    JE    XYSpeed                ;  If so, don't change the angle  
    CMP   BX, 0                  ;  Otherwise, update the angle
                                 ;  Check if the passed angle is positive or 
                                 ;  negative
    JGE   PosAngle               ;  Update positive angle
    JL    NegAngle               ;  Update negative angle
PosAngle:                        ;  Update the angle if the passed angle is 
                                 ;  positive
    MOV   AX, BX                 ;  Setup for division of the passed angle
    MOV   BX, TWOPI              ;  TWOPI is the divider      
    MOV   DX, 0                  ;  Clear DX for 16-bit division
    IDIV  BX                     
    MOV   currangle, DX          ;  Store the remainder into currangle. which 
                                 ;  is congruent to the passed angle modulo TWOPI
    JMP   XYSpeed                ;  Update the x,y component of the speed
NegAngle:                        ;  Update the angle if the passed angle is 
                                 ;  negative
    MOV   AX, BX                 ;  Setup for division of the passed angle
    MOV   BX, TWOPI              ;  TWOPI is the divider
    MOV   DX, 0FFFFh             ;  Setup DX for the signed division
    IDIV  BX                    
    ADD   DX, TWOPI              ;  Add TWOPI to the remainder to make it 
                                 ;  positive
    MOV   currangle, DX          ;  Store the result into currangle, which is 
                                 ;  congruent to the passed angle modulo TWOPI
XYSpeed:                         ;  Update the x,y component of the speed
    MOV   SI, OFFSET(Cos_Table)  ;  Find the cos_value of the angle of movement
    MOV   DX, currangle          ;  Setup DX for the index of the table, which
                                 ;  is the degree of angle
    SHL   DX, 1                  ;  Multiply the angle by 2 because the table is
                                 ;  using word
    ADD   SI, DX                 ;  SI points to the cos_value we looking for
    MOV   AX, CS:[SI]            ;  Store the cos_value into AX
    MOV   BX, currspeed          ;  Setup for the calculating the x-component 
    SHR   BX, 1                  ;  The maximum speed is 7FFF in our calculation,
                                 ;  so we divide the passed speed by 2
    IMUL  BX                     
    MOV   Vx, DX                 ;  Store the x-component
    MOV   SI, OFFSET(Sin_Table)  ;  Find the sin_value of the angle of movement
    MOV   DX, currangle          ;  Setup DX for the index of the table, which
                                 ;  is the degree of the angle
    SHL   DX, 1                  ;  Multiply the angle by 2 because the table is 
                                 ;  using word
    ADD   SI, DX                 ;  SI points to the sin_value we looking for 
    MOV   AX, CS:[SI]            ;  Store the sin_value into AX
    MOV   BX, currspeed          ;  Setup for calculating the y-component
    SHR   BX, 1                  ;  The maximum speed is 7FFF,in our calculation,
                                 ;  so we divide the passed speed by 2
    IMUL  BX                     
    MOV   Vy, DX                 ;  Store the y-component 
    MOV   SI, OFFSET(wspeed)     ;  Setup for updating the speed of three wheels
    MOV   BX, OFFSET(FTable)     ;  FTable contains the position vector of three
                                 ;  wheels
    MOV   CX, WHEEL_NUM          ;  Setup the looping number to 3
CalSpeed:                        ;  Update the speed of three wheels
    PUSH  CX                     ;  Save the looping index
                                 ;  Do the dot product of the position vector of
                                 ;  wheel and the speed 
    MOV   AX, CS:[BX]            ;  Move the x-component of the position vector
                                 ;  of the current wheel into AX    
    IMUL  Vx                     ;  Multiply the x-component of speed with the
                                 ;  x-component of the position vector
    MOV   CX, DX                 ;  Truncate the result to DX and store into AX
    ADD   BX, 2                  ;  Move to the y-component of the position 
                                 ;  vector
    MOV   AX, CS:[BX]            ;  Move the y-component of the position vector
                                 ;  of the current wheel into AX    
    IMUL  Vy                     ;  Multiply the y-component of speed with the
                                 ;  y-component of the position vector 
    ADD   BX, 2                   
    ADD   CX, DX                 ;  Truncate the result to DX and add it with
                                 ;  previous product to obtain the dot product
                                 ;  of the position vector and the speed
    SAL   CX, 2                  ;  Multiply the result by 2
    MOV   DS:[SI], CH            ;  Truncate the first 8 bits 
    INC   SI                     ;  Move to the next wheel
    POP   CX                     ;  Retrieve the looping number
    LOOP  CalSpeed               ;  Looping
EndSet:                          ;  Done and return
    RET
SetMotorSpeed ENDP   

  
; GetMotorSpeed 
;
; Description:      This function returns the current speed of the motorstrike.
; Operation:        Return currspeed.
; Arguments:        None
; Return Value:     currspeed --- The current speed of motorstrike, 65534 is the
;                                 full speed
;
; Local Variables:  None
; Shared Variables: currspeed --- The current speed of motorstrike (Read)
; Global Variables: None
;
; Input:            None 
; Output:           None
; Error Handling:   None
;
; Algorithms:       None
; Data Structures:  None
;
; Registers Changed: AX
;
; Author:           Yuqi Zhu
; Last Modified:    11/30/2012
GetMotorSpeed PROC NEAR
              PUBLIC GetMotorSpeed
    MOV AX, currspeed ; Return the current speed of motorstrike in AX
    RET              
GetMotorSpeed ENDP


; GetMotorDirection
; Description:      This function returns the angle of current movement
; Operation:        Return currangle        
;
; Arguments:        None
; Return Value:     The angle of current movement
;
; Local Variables:  None
; Shared Variables: currangle --- The direction of the current movement
;                                 (Read)
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
; Registers Changed: AX
;
; Author: Yuqi Zhu
; Last Modified: 11/30/2012


GetMotorDirection PROC NEAR
                  PUBLIC GetMotorDirection
    MOV AX, currangle                  ; Return the angle of current movement
    RET
GetMotorDirection ENDP



; SetLaser(onoff)
; Description: This function turns on/off the laser based on the passed value. 
;              Zero value will turn off the laser and any non-zero value will 
;              turn on the laser.
; Operation:   If zero is passed, this function is will reset the laserflag.
;              If a non-zero value is passed. The function will set the laserflag 
;           
; Arguments:   AX(onoff)  --- Indicate whether to turn on or turn off the laser
; Return Value:      None
;
; Local Variables:   None
; Shared Variables:  laserflag --- Flag indicating the current state of the laser
;                                  (changed)
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   None
;
; Registers Changed: AX
;
; Author:            Yuqi Zhu
; Last Modified:     11/30/2012
SetLaser PROC NEAR
         PUBLIC SetLaser
    CMP AX, 0           ; Check if the passed value is 0
    JE  Resetflag       ; If so, reset the laserflag
    JNE Setflag         ; Otherwise, set the laserflag
Resetflag:              ; Reset the laserflag
    MOV laserflag, 0
    JMP EndSetlaser     ; Done
Setflag:                ; Set the laserflag
    MOV laserflag, 1
EndSetlaser:            ; Done
    RET
SetLaser ENDP



; GetLaser()
; Description:  Return the current status of laser. A value of 0 indicates the 
;               laser is off and 1 indicates the laser is on.
;             
; Operation:    Return laserflag
;
; Arguments:    None
; Return Value: None 
;
; Local Variables:  None
; Shared Variables: LaserFlag --- Flag indicating the current state of the laser
;                                 (Read)
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
; Registers Changed: AX 
;
; Author:           Yuqi Zhu
; Last Modified:    11/30/2012


GetLaser PROC NEAR
         PUBLIC GetLaser
    MOV AX, laserflag         ; Return the current state of the laser
    RET
GetLaser ENDP


; ParallelIO 
; Description: This timer event handler sends the control bits to PortB to control
;              the status of three wheels and laser. Bits 0, 2, 4 control the 
;              direction of three wheels respectively and the bits 1, 3, 5 control
;              the on/off state of three wheels. Bits 7 controls the laser. We
;              adjust the speed of wheel by controlling the ratio between the 
;              number of on states and off states in a cycle. 
; Operation:   This function uses AL to store the control bits that's going to 
;              be sent to portB. A table that contains masks for each bit is 
;              used for setting the control bits. The function turns on the
;              motor if it's speed is larger than the current parallel IO counter
;              the function turns on the laser is the laserflag is set. Parallel
;              IO counter is cycle with length cycle_length. This function doesn't
;              change any registers or flags.
; Arguments:         None
; Return Value:      None 
;
; Local Variables:   AL        --- The control bits that's sent to portB
; Shared Variables:  wspeed    --- The buffer stores the speed of three wheels
;                                  (Read)                    
;                    LaserFlag --- Flag indicating the current state of the laser
;                                  (Read)
; Global Variables:  None
;
; Input:             None 
; Output:            None
;
; Error Handling:    None
;
; Algorithms:        None
; Data Structures:   Array
;
; Registers Changed: None
;
; Author: Yuqi Zhu
; Last Modified: 12/2/2012


ParallelIO PROC NEAR
           PUBLIC ParallelIO
    PUSH AX                     ; Save all the registers that will be used in the
                                ; time event handler, as well as all the flags
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSHF
    MOV SI, OFFSET(wspeed)      ; Setup for preparing the control bits
    MOV BX, OFFSET(BitsTable)   ; BitsTable contains the mask for each bit
                                ; (except bit 6), which is used for stepper
                                ;  motorstrike    
    MOV CX, WHEEL_NUM           ; setup the looping number as WHEEL_NUM
    MOV AL, 0                   ; Initialize the control bits to 0
Setpulse:                       ; Setup the control bits
    MOV DL, DS:[SI]             ; Retrieve the speed of the current wheel
    INC SI                      ; Move to the next wheel 
    CMP DL, 0                   ; Check if the speed is forward or backward
    JGE Setforward              ; Set the corresponding control bit to forward 
    JL  Setbackward             ; Set the corresponding control bit to backward
Setforward:                     ; If the speed is forward, which means the control 
    INC BX                      ; bit is 0. Ignore the current mask and move to 
                                ; the next mask
    CMP DL, pcntr               ; Check if the current speed is larger than the 
    JA  Turnon                  ; parallel IO counter; if so, turn on the motor
    JBE LoopBody                ; otherwise, turn off the motor
Setbackward:                    ; If the speed is backward, set the corresponding
    OR  AL, CS:[BX]             ; control bits
    INC BX                      ; move to the next bits
    NEG DL                      ; Compare the magnitude of speed with the parallel
    CMP DL, pcntr               ; IO counter
    JA  Turnon                  ; If the magnitude of speed is larger than the 
                                ; turn on the motor
    JBE LoopBody                ; Otherwise, turn if off
Turnon:                         ; Turn on the corresponding motor
    OR  AL, CS:[BX] 
LoopBody:                       ; Move to the next control bits and looping
    INC BX
    loop Setpulse
Setpulselaser:                  ; Setup the control bit for laser
    CMP laserflag, 0            ; If the laserflag is 0
    JE  Sendpulse               ; we are done with setting up the control bits
    OR  AL, 080h                ; otherwise, we set the control bits for laser
Sendpulse:                      ; Send the control bits to port B
    MOV DX, portBaddr            
    OUT DX, AL                  ; Output the control bits to portB
UpdateCntr:                     ; Update the parallel IO counter
    INC pcntr                   ; Increase the counter
    CMP pcntr, CYCLE_LENGTH     ; If the counter doesn't reach cycle_length
    JNE EndpIO                  ; Done and return
    MOV pcntr, 0                ; Otherwise, reset the counter
EndpIO:                         ; Retrieve all the flags and registers that has
    POPF                        ; been changed in the procdecure and return
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ParallelIO ENDP    

; FTable
; 
; Description:      This table contains the x,y components of position vectors
;                   of three wheels. 
;
; Author:           Yuqi Zhu
; Last Modified:    12/2/2012
        
FTable LABEL WORD
      PUBLIC FTable
DW 07FFFh
DW 0
DW 0C000h
DW 09127h
DW 0C000h
DW 06ED9h


; BitsTable
; 
; Description:      This table contains the masks for the control bits sending
;                   to portB
;
; Author:           Yuqi Zhu
; Last Modified:    12/2/2012
        
BitsTable LABEL BYTE
          PUBLIC BitsTable
DB 01h
DB 02h
DB 04h
DB 08h
DB 10h
DB 20h



CODE ENDS



; the data segment
DATA SEGMENT PUBLIC 'DATA'
    Vx            DW ?    ; The x-component of the current speed
    Vy            DW ?    ; The y-component of the current speed
    wspeed        DB  (WHEEL_NUM)  DUP (?)    ; The buffer storing the speed of 
                                              ; three wheels
    currspeed     DW ?    ; The overall speed of the robostrike
    currangle     DW ?    ; The angle of the movement
    laserflag     DW ?    ; The status of the laser
    pcntr         DB ?    ; The parallel IO counter
DATA ENDS
     END
