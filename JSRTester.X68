*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $400
START:                  ; first instruction of program

      JSR   sub
      BRA   done
      
sub  
    MOVE.B  #14,D0
    RTS
      
    

* Put program code here
done
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
