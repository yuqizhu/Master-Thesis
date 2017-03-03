NAME  timer2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    timer2                                  ;
;                         Timer2 and its event handler                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initialization of timer and its event handler.
; The included public functions are:
;                 
;      KeyAndDisplayhandler             -  This procedure calls displayMux to display the string stored in the buffer
;      InitTimer2                       -  Initialization of the timer 
;      InstallTimer2Handler             -  Install the timer event handler


; Revision History:
;   11/10/2012 Yuqi Zhu
;   11/11/2012 Yuqi Zhu
;   11/12/2012 Yuqi Zhu
;   11/13/2012 Yuqi Zhu
;   11/14/2012 Yuqi Zhu





; local include files
$INCLUDE(timer.INC)






CGROUP GROUP CODE





; the code segment

CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP





; external function declarations

       EXTRN DisplayMux:NEAR ; The multiplex function that displays the string pattern in the buffer to 
                             ; the correct LED digit





; KeyAndDisplayHandler 
;
; Description:       The timer event handler calls displaymux to display the pattern stored in the buffer. 
;
; Operation:         This function calls Displaymux to output the pattern stored in the buffer to the LED
;                    display.
;
; Arguments:         None
; Return Value:      None.
;
; Local Variables:   None
; Shared Variables:  None.
; Global Variables: 
; Input:             None.
; Output:            A character to the display.
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
; 11/14/2012

KeyAndDisplayHandler      PROC    NEAR
              PUBLIC KeyAndDisplayHandler 
        PUSH    AX                      ; save the registers
        PUSH    BX                      ; Event Handlers should NEVER change
        PUSH    DX                      ; any register values


DisplayUpdate:                          ; Call keyscan to scan the keypad
                                        ; Call displaymux to update the display
        
        CALL    KeyScan                 ; keyscan scans the keypad and stores the corresponding code
        CALL    DisplayMux              ; Displaymux displays the pattern stored in the buffer onto the LED digits
                         

EndTimerEventHandler:                   ; done taking care of the timer

        MOV     DX, INTCtrlrEOI         ; send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POP     DX                      ; restore the registers
        POP     BX
        POP     AX


        IRET                            ; and return (Event Handlers end with IRET not RET)


KeyAndDisplayHandler       ENDP







; InitTimer2
;
; Description:       Initialize the 80188 Timers.  The timers are initialized
;                    to generate interrupts every 1 ms. The timer2 is used to 
;                    generate interrupts and its maxcount has been set to 1ms 
;                    counts.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
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
InitTimer2       PROC    NEAR
      PUBLIC InitTimer2
                                ;initialize Timer #2 to generate interrupt
        MOV     DX, Tmr2Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt  ;setup max count for 1ms counts
        MOV     AX, COUNTS_PER_MS
        OUT     DX, AL

        MOV     DX, Tmr2Ctrl    ;setup the control register, interrupts enabled
        MOV     AX, Tmr2CtrlVal
        OUT     DX, AL


                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer2      ENDP




; InstallTimer2Handler
;
; Description:       Install the event handler for the timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
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

InstallTimer2Handler  PROC    NEAR
           PUBLIC InstallTimer2Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr2Vec), OFFSET(KeyAndDisplayHandler)
        MOV     ES: WORD PTR (4 * Tmr2Vec + 2), SEG(KeyAndDisplayHandler)


        RET                     ;all done, return


InstallTimer2Handler  ENDP




CODE ENDS



END
