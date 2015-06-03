*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $400
START:                  ; first instruction of program

* Put program code here

    LSL.B   #3,D0
    LSR.B   #4,D1
    ASL.B   #3,D0
    ASR.B   #6,D2
    ROL.B   #2,D3
    ROR.B   #7,D6

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    $400        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
