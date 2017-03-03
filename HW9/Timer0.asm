NAME  timer0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    timer0                                  ;
;                         Timer0 and its event handler                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initialization of timer and its event 
; handler.
; The included public functions are:
;                 
;      MotorControl                  -  This procedure calls parallelIO to send  
;                                       the control bits to the portB
;      InitTimer0                    -  Initialization of the timer 
;      InstallTimer0Handler                -  Install the timer event handler
;
; Revision History:
;   11/20/2012 Yuqi Zhu   Initial Revision
;   12/02/2012 Yuqi Zhu   Update Comments




; local include files
$INCLUDE(timer.INC)





CGROUP GROUP CODE





; the code segment

CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP





; external function declarations

       EXTRN ParallelIO:NEAR ; The parallel IO functions that turns on/off three
                             ; motors and the laser




; MotorControl
;
; Description:       This function is the timer0 event handler. It calls 
;                    parallelIO to update the control bits in portB and thus 
;                    control the status of three motors and the laser.
;
; Operation:         This function calls parallelIO regularly to control the motors
;
; Arguments:         None
; Return Value:      None.
;
; Local Variables:   None
; Shared Variables:  None.
; Global Variables: 
; Input:             None.
; Output:            None
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       3 words
;
; Author:            Glen George, Yuqi Zhu
; Last Modified:     
; 12/02/2012

MotorControl       PROC    NEAR
               PUBLIC MotorControl
        PUSH    AX                      ; save the registers
        PUSH    BX                      ; Event Handlers should NEVER change
        PUSH    DX                      ; any register values


DisplayUpdate:                          ; Call the keyscan to scan the keypad

        CALL    ParallelIO              ; ParallelIO functions that send control
                                        ; bits to port B
                         

EndTimerEventHandler:                   ; done taking care of the timer

        MOV     DX, INTCtrlrEOI         ; send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POP     DX                      ; restore the registers
        POP     BX
        POP     AX


        IRET                            ; and return (Event Handlers end with 
                                        ; IRET not RET)


MotorControl       ENDP









; InitTimer0
;
; Description:       Timer0 is initialized to generate interrupts when maxcount
;                    reaches COUNTS_PER_CYCLE. 
;
; Operation:         The appropriate values are written to the timer0 control
;                    registers in the PCB.  Also, the timer0 count registers
;                    are reset to zero.  Finally, the interrupt controller is
;                    setup to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Glen George, Yuqi Zhu
; Last Modified:   
; 11/14/2012
InitTimer0       PROC    NEAR
      PUBLIC InitTimer0
                                ;initialize Timer #2 to generate interrupt
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCntA  ;setup max count for 1ms counts
        MOV     AX, COUNTS_PER_CYCLE
        OUT     DX, AL

        MOV     DX, Tmr0Ctrl    ;setup the control register, interrupts enabled
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL


                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer0      ENDP




; InstallTimer0Handler
;
; Description:       Install the event handler for the timer0 interrupt.
;
; Operation:         Writes the address of the timer0 event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, ES
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Jan. 28, 2002

InstallTimer0Handler  PROC    NEAR
           PUBLIC InstallTimer0Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(MotorControl) ; Move the
                                ; address of Timer0 event handler into the Timer0
                                ; interrupt vector
        
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(MotorControl)


        RET                     ;all done, return


InstallTimer0Handler  ENDP









CODE ENDS



END
