*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

begin 
            BRA     done

            NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
                  NEG.B   D0
            NEG.W   D1
            NEG.L   D2
            NEG.B   D4
            NEG.W   D5
            NEG.B   D2
            NEG.B   D1
            BRA     begin
            
done            

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
