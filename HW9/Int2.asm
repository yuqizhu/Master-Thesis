NAME  int2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Int2                                    ;
;                           Int2 and its event handler                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initialization of interrupt 2 and its event 
; handler.
; The included public functions are:
;                 
;      SerialIOEventHandler          -  This procedure calls SerialIO to read or
;                                       write to the serial IO chips
;      InitINT2                      -  Initialization of the interrupt 2
;      InstallINT2Handler            -  Install the interrupt 2 event handler
;
; Revision History:
;   11/20/2012 Yuqi Zhu   Initial Revision
;   12/02/2012 Yuqi Zhu   Update Comments
;   12/08/2012 Yuqi Zhu   Update Comments



; local include files
$INCLUDE(int2.INC)





CGROUP GROUP CODE





; the code segment

CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP





; external function declarations

       EXTRN SerialIO:NEAR ; The serial IO functions that reads or writes data from
                           ; serial chips


; SerialIOEventHandler
;
; Description:       This function is the interrupt 2 event handler. This function
;                    calls SerialIO to read data from Serial chips or transmit 
;                    data to the serial chips. If an error happened, serialIO will
;                    store the error in a shared variable 
;
; Operation:         This function calls serialIO to handle the int2 interrupt.
;                    This function doesn't change any registers or flags
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
; 12/08/2012

SerialIOEventHandler       PROC    NEAR
               PUBLIC SerialIOEventHandler
        PUSH    AX                      ; save the registers
        PUSH    BX                      ; Event Handlers should NEVER change
        PUSH    DX                      ; any register values


SerialHandler:                          ; Call the SerialIO to transmit data or 
                                        ; read data from serial chip and store
                                        ; the error                                        

        CALL    SerialIO                
                         

EndTimerEventHandler:                   ; done taking care of the int2

        MOV     DX, INTCtrlrEOI         ; send the EOI to the interrupt controller
        MOV     AX, INT2EOI
        OUT     DX, AL

        POP     DX                      ; restore the registers
        POP     BX
        POP     AX


        IRET                            ; and return (Event Handlers end with 
                                        ; IRET not RET)


SerialIOEventHandler       ENDP









; InitINT2
;
; Description:       INT2 is intialized to level triggering and have priority 1
;
; Operation:         The interrupt controller is setup to be level triggered and
;                    have priority 1. Pending interrupts are cleared by sending 
;                    a Int2EOI to the  interrupt controller.
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
InitINT2       PROC    NEAR
      PUBLIC InitInt2

                                 ;initialize interrupt controller for int2
        MOV     DX, INT2CtrlrCtrl;setup the interrupt control register
        MOV     AX, INT2CtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a int2 EOI (to clear out controller)
        MOV     AX, Int2EOI
        OUT     DX, AL


        RET                     ;done so return


InitINT2      ENDP




; InstallINT2Handler
;
; Description:       Install the event handler for the int2 interrupt.
;
; Operation:         Writes the address of the int2 event handler to the
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

InstallINT2Handler  PROC    NEAR
           PUBLIC InstallINT2Handler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Int2Vec), OFFSET(SerialIOEventHandler) ; Move the
                                ; address of int2 event handler into the int2
                                ; interrupt vector
        
        MOV     ES: WORD PTR (4 * Int2Vec + 2), SEG(SerialIOEventHandler)


        RET                     ;all done, return


InstallINT2Handler  ENDP









CODE ENDS



END
