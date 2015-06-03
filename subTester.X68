*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $400
START:                  ; first instruction of program

* Put program code here
      
begin   SUB.B   D0,D1          *works
this    SUB.W   D3,D4
        BVC     begin           *works
here    SUB.L   D5,D6          *works
        SUB.B   (A0),D0        *works
        SUB.B    D0,(A5)       *works
        SUB.W   (A6),D3        *works
        SUB.L    D5,(A4)       *works
        SUBQ.B    #7,D2        *does not work
        BLT      adds
        
adds    ADD.B   D0,D1
        ADD.W   D2,D3
        ADD.L   D4,D5
        ADD.B   (A1),D3
        
        ADDA.W  A1,A2
        ADDA.L  A3,A5
        
        NEG.B   D0
        NEG.W   D1
        NEG.L   D2
        
        
        DIVS.W    D1,D0        *works
        DIVS.W    (A0),D4      *works
        *DIVS.W    #10,D4       *does not work
        ADD.B     #10,D0       *does not work
        *DIVS.L      $00000000,D1:D2 *dont know the syntax
        LEA     (A2),A1
        BRA     begin


DONE
    SIMHALT             ; halt simulator

* Put variables and constants here


    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
