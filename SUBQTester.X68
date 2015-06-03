*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

    SUBQ.B  #1,D0
    SUBQ.W  #2,D2
    SUBQ.L  #3,D3
    SUBQ.B  #4,D1
    SUBQ.B  #5,D2
    SUBQ.W  #6,D4
    SUBQ.L  #7,D5
    SUBQ.L  #8,D6

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
