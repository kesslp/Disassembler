*-----------------------------------------------------------
* Title      :  Disassembler
* Written by :  Paul Kessler and Joscelyn Kim
* Date       :  199X
* Description:  This program takes assembled code and disassembles it into 
*               assembly language readable by humans.  The program will be 
*               disassembed in a user defined address range
*-----------------------------------------------------------
CR          EQU $0D
LF          EQU $0A

mask        EQU $0000000F
ascii_mask  EQU $00FF
counter     EQU 0
stack       EQU $B000
line_count  EQU 30

*---- User input address range -----

                ORG         $1000                       * start of the program
                LEA         stack,SP                    * initialize the stack
                CLR.B       D0                          * clear D0
                LEA         start_addr_msg, A1          * ask for starting address
                MOVE.B      #14, D0
                TRAP        #15                         
                MOVE.B      #2, D0                      * take in user input as string
                TRAP        #15
                MOVEM.W     A0-A6/D0-D7,-(SP)           * push registers on the stack
                JSR         get_addr                    * strip ascii characters to hex
                MOVEM.W     (SP)+, A0-A6/D0-D7          * restore registers
                MOVE.L      addr_val_temp,st_val
                
                LEA         end_addr_msg, A1            * ask for ending address
                MOVE.B      #14, D0
                TRAP        #15
                MOVEA.L     A4,A1                       * reset address at A1 to get user input
                MOVE.B      #2, D0                      * take address as a string
                TRAP        #15
                MOVEM.W     A0-A6/D0-D7,-(SP)           * push registers on the stack
                JSR         get_addr                    * strip ascii address into hex
                MOVEM.W     (SP)+, A0-A6/D0-D7          * restore the registers
                MOVE.L      addr_val_temp, end_val      * store address in end_val
                MOVEA.L     st_val,A5                   * store start val in A5
                MOVEA.L     end_val,A6                  * store end val in A6
                
                LEA         outputStart,A1              *ouput starting messaage
                MOVE.B      #14,D0          
                TRAP        #15
                
                LEA         outputNextLine,A1           *output nextline
                MOVE.B      #14,D0
                TRAP        #15
                
                MOVE.B      #line_count,(A3)
                SUBQ.B      #2,(A3)
                BRA         getOpCode                   * Jump to getOpCode sub routine

                

get_addr 
                SUBQ.B      #1,D1
                CLR.L       D7                          * we need D7 to be 0
                MOVE.B      (A1)+,D0                    * store first byte in D0
                ANDI.L      #ascii_mask,D0              * mask the first byte
                JSR         strip_ascii                 * strip ascii char into hex
                MULS.W      #4,D1
                ASL.L       D1,D0                       * shift left 8
                OR.L        D0,D7
                MOVE.B      (A1)+,D0                    * move next byte into D0
loop            SUBQ.B      #4,D1
                ANDI.L      #ascii_mask,D0              * mask the second byte
                JSR         strip_ascii                 * strip ascii to hex
                ASL.L       D1,D0                       * shift left 8
                OR.L        D0,D7
                CMP.B       #0,D1
                BEQ         rts_strtAddr
                MOVE.B      (A1)+,D0
                BRA         loop
                
rts_strtAddr
                MOVE.L      D7,addr_val_temp
                RTS     
                
strip_ascii     CMP.B       #$39,D0                     *Is it in range of 0-9?
                BLE         sub30                       *It's a number
                CMP.B       #$46,D0                     *Is it A...F?
                BLE         sub37                       *It's A...F
                SUB.B       #$57,D0                     *It's a...f
                BRA         ret_sa                      *Go back
sub37           SUB.B       #$37,D0                     *Strip 37
                BRA         ret_sa                      *Go back
sub30           SUB.B       #$30,D0                     *Strip 30
ret_sa          RTS                                     *Go back

                
*---- Data ----

start_addr_msg  DC.B    'Enter a starting address to disassemble: $', 0
end_addr_msg    DC.B    'Enter a ending address to stop disassembling: $', 0
addr_val_temp   DC.L    $00000000
st_val          DC.L    $00000000
end_val         DC.L    $00000000

*--- Data end ----


* Disassembler Start
getOpCode                        *Gets opcode
    *LEA     code,A0             *Loads "code" which is the op code
    
    CLR.L   D7
    CLR.L   D6
    CLR.L   D3
    CLR.L   D1
    CLR.L   D0
    CLR.L   D5
    CLR.L   D4
    
    SUBQ.B  #1,(A3)
    CMP.B   #0,(A3)
    BEQ     pageContinue
    
    MOVE.W  A5,D1               *move starting addr into D1
    MOVE.B  #15,D0              *convert number into hex and output to console
    MOVE.B  #16,D2
    TRAP    #15    
    MOVE.W  (A5)+,D4            *move data at starting addr to D4
    
    CLR.L   D1
    
    LEA     outputColon,A1      *output the colon and a space to the console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVEA.L A0,A1               *used to clear A0
    MOVE.W  D4,D2               *gets put into D4 and D2
    
    ROL.W   #4,D2               *rotate the first 4 significant bits to lower 4 bits
    
    AND.L   #mask,D2            *mask it to get only the first byte
    
    MOVE.B  D2,D5               *put that value into D5

nopOpCode
    CMP.W   #$4E71,D4
    BNE     rtsOpCode
    
    LEA     outputNOP,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     DONE
    
rtsOpCode
    CMP.W   #$4E75,D4
    BNE     jsrOpCode
    
    LEA     outputRTS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     DONE
    
jsrOpCode
    MOVE.W  D4,D3
    ROL.W   #8,D3
    AND.W   #$00FF,D3
    CMP.B   #$4E,D3
    BNE     movemOpCode
    
jsrMethod
    MOVE.W  D4,D3
    ROL.W   #3,D3
    AND.B   #7,D3
    CMP.B   #2,D3
    BEQ     jsrOutputDeref
    
    CMP.B   #7,D3
    BEQ     jsrOutputLabel

    
    BRA     outputData
        
jsrOutputDeref

    LEA     outputJSR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
jsrOutputLabel

    CMP.B   #1,D3
    BGT     dataOpCode
    JSR     sourceEA
    
    BRA     DONE
	
movemOpCode		
    MOVE.W  D4,D3		
    ASR.W   #6,D3		
    CMP.W   #$0122,D3		
    BEQ     movemMethodRegToMem		
    CMP.W   #$0132,D3		
    BEQ     movemMethodMemToReg		
    CMP.W   #$0123,D3		
    BEQ     movemLongRegToMem		
    CMP.W   #$0133,D3		
    BEQ     movemLongMemToReg		
    BRA     leaOpCode

movemLongRegToMem
    MOVE.B  #1,D6
    BRA     movemMethodRegToMem 

movemLongMemToReg
    MOVE.B  #1,D6
    BRA     movemMethodMemToReg		
    		
movemMethodRegToMem		
    MOVE.B  #0,D5                       *Register to memory baby!		
    MOVE.W  D4,D3		
    ROR.B   #3,D3		
    AND.W   #$0007,D3		
    CMP.B   #2,D3		
    BEQ     movemOutput		
    CMP.B   #4,D3		
    BEQ     movemOutput		
    CMP.B   #7,D3		
    BEQ     movemOutput		
    BRA     dataOpCode		
        		
movemMethodMemToReg		
    MOVE.B  #1,D5                       *Memory to Register baby!		
    MOVE.W  D4,D3		
    ROR.B   #3,D3		
    AND.W   #$0007,D3		
    CMP.B   #2,D3		
    BEQ     movemOutput		
    CMP.B   #3,D3		
    BEQ     movemOutput		
    CMP.B   #7,D3		
    BEQ     movemOutput		
    BRA     dataOpCode		
    		
movemOutput		
    MOVE.W  D4,D3		
    CMP.B   #1,D5		
    BEQ     movemOutputMemToReg		
    		
    ASR.W   #3,D3		
    AND.W   #$0007,D3		
    CMP.B   #2,D3		
    BEQ     getAnMode		
    CMP.B   #4,D3		
    BEQ     getAnMode		
    CMP.B   #7,D3		
    BNE     dataOpCode		
    MOVE.B  D4,D3		
    AND.B   #$07,D3		
    CMP.B   #1,D3		
    BGT     dataOpCode		
    BRA     getAnMode		
    		
movemOutputMemToReg
    ASR.W   #3,D3
    AND.W   #$0007,D3
    CMP.B   #2,D3
    BEQ     getAnMode
    CMP.B   #3,D3
    BEQ     getAnMode
    CMP.B   #7,D3
    BNE     dataOpCode
    MOVE.B  D4,D3
    AND.B   #$07,D3
    CMP.B   #1,D3
    BGT     dataOpCode
    BRA     getAnMode
    		
getAnMode		
    MOVE.B  D3,D2		
    		
movemWEA		
*    MOVE.W  (A5)+,D3
    CMP.B   #1,D6
    BEQ     displayMovemLong

displayMovemWord		
    LEA     outputMOVEMW,A1		
    MOVE.B  #14,D0		
    TRAP    #15
    BRA     regToMem

displayMovemLong
    LEA     outputMOVEML,A1		
    MOVE.B  #14,D0		
    TRAP    #15		
    
    
regToMem
    CLR.L   D3
    CLR.L   D2
    CLR.L   D1
    CLR.L   D6
    CLR.L   D7

    CMP.B   #0,D5
    BNE     memToReg
    
    CLR.L   D5
    
    MOVE.W  (A5)+,D5
    MOVE.W  #16,D6
    MOVE.B  #1,D2
    
    MOVE.W D4,-(A7)
    
    CLR.L   D4
    
    JSR     registerCheckerDn
    
    MOVE.W  (A7)+,D4
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
  
registerCheckerDn
    CMP.B   #9,D2
    BEQ     meepmeep

    MOVE.W  D5,D3
    
    ROL.W   D2,D5
    AND.L   #$FFFFFFFE,D5
    ROR.W   D2,D5
    
    ROL.W   D2,D3
    AND.L   #$00000001,D3
    ADD.B  #1,D2
    
meowmeow
    CMP.B   #1,D3
    BEQ     regBitSet           *Do shit

    CMP.B   #0,D4
    BEQ     registerCheckerDn   *the one before was a zero

    BRA     registerOutput    *output stuff because there is a range
    
regBitSet
    CMP.B   #1,D4
    BNE   hamsters

checkSeven                      *There is a range
    MOVE.B  D2,D7
    
    BRA     registerCheckerDn
    
hamsters
    MOVE.B  D2,D1       *sets the "start" of range
    
    MOVE.B  #1,D4       *there was a one
    
    BRA     registerCheckerDn
    
registerOutput
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    CMP.B   #1,D7
    BGE     outputpart2
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15

    CLR.L   D4

    BRA     registerCheckerDn  
    
outputpart2
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D7
    MOVE.L  D7,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D4
    CLR.L   D7
    
    BRA     registerCheckerDn
    
meepmeep
    CLR.L   D3
    CLR.L   D4
    CLR.L   D6
    CLR.L   D7
    CLR.L   D1
    
    
registerCheckAn
    CMP.B   #17,D2
    BEQ     registerDone
    
    MOVE.W  D5,D3
    
    ROL.W   D2,D5
    AND.L   #$FFFFFFFE,D5
    ROR.W   D2,D5
    
    ROL.W   D2,D3
    AND.L   #$00000001,D3
    ADD.B   #1,D2
    
registerRangeAn
    CMP.B   #1,D3
    BEQ     regBitSetAn           *Do shit

    CMP.B   #0,D4
    BEQ     registerCheckAn   *the one before was a zero

    BRA     registerOutputAn    *output stuff because there is a range
    
regBitSetAn
    CMP.B   #1,D4
    BNE   hamstersAn

checkSevenAn                      *There is a range
    SUBQ.B  #8,D2
    MOVE.B  D2,D7
    ADD.B   #8,D2
    
    BRA     registerCheckAn
    
hamstersAn
    SUBQ.B  #8,D2
    MOVE.B  D2,D1       *sets the "start" of range
    ADD.B   #8,D2
    
    MOVE.B  #1,D4       *there was a one
    
    BRA     registerCheckAn
    
registerOutputAn
    LEA     outputAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    CMP.B   #1,D7
    BGE     outputpart2An
        
    
displaySlash
    CMP.W   #1,D5
    BLT     ignoreSlash
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15

ignoreSlash
    CLR.L   D4

    BRA     registerCheckAn  
    
outputpart2An
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D7
    MOVE.L  D7,D1
    MOVE.B  #3,D0
    TRAP    #15
    
*displaySlash
    CMP.W   #1,D5
    BLT     ignoreSlashAn

    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15
    
ignoreSlashAn    
    CLR.L   D4
    CLR.L   D7
    
    BRA     registerCheckAn
    
registerDone
    CMP.B   #1,D7
    BGE     registerOutputAn

    RTS
    
memToReg

    JSR     sourceEA
    
    CLR.L   D3
    CLR.L   D1
    CLR.L   D6
    CLR.L   D5
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  (A5)+,D5
    MOVE.W  #16,D6
    MOVE.B  #1,D2
    
    MOVE.W  D5,D6
    
    
mirrorShift
    CMP.B   #15,D1
    BEQ     moveMContinue
    
    ADD.B   #1,D1
    
    ASR.W   #1,D6
    BCS     addBit
    
    BRA     zeroBit
    
addBit
    ADD.B   #1,D3
    ASL.W   #1,D3
    BRA     mirrorShift
    
zeroBit
    ASL.W   #1,D3
    BRA     mirrorShift 
    

moveMContinue

    MOVE.W  D3,D5
    CLR.L   D6
    CLR.L   D3
    CLR.L   D1
    
    MOVE.W  D4,-(A7)
    
    CLR.L   D4
    
    JSR     registerCheckerDn
    
    MOVE.W  (A7)+,D4   
     
    BRA DONE    		
    		    
leaOpCode
    CMP.B   #4,D5
    BNE     oriOpCode
    MOVE.W  D4,D3
    ROL.W   #8,D3
    CMP.B   #$44,D3
    BEQ     negMethod
    ROR.W   #8,D3
    ROR.W   #7,D3
    AND.B   #7,D3
    CMP.B   #7,D3
    BNE     dataOpCode
    
    MOVE.W  D4,D3
    ROR.W   #3,D3
    AND.B   #7,D3
    CMP.B   #2,D3
    BEQ     leaOutput
    
    CMP.B   #7,D3
    BEQ     leaOutput
    
    BRA     dataOpCode
    
leaOutput    
    LEA     outputLEA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addaDestEA
    
    BRA     DONE
    
oriOpCode                       *OR opcode
    CMP.B   #0,D5               
    BNE     moveByteOpCode      *if not, go to next opcode

*-------------------------------------------------Change this when merging         
    MOVE.W  D4,D2
    ROL.W   #8,D2
    AND.L   #$0000000F,D2
    
    MOVE.L  D2,D5
    
oriMethod
    CMP.B   #0,D5
    BNE     cmpiOpCode
    
    LEA     outputORI,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
        
    MOVE.L  #7,D2
    MOVE.L  #4,D3
    JSR     immediateData
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    BRA     DONE

cmpiOpCode
    CMP.B   #12,D5
    BNE     bclrOpCode
    
cmpiMethod
    LEA     outputCMPI,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    MOVE.L  #7,D2
    MOVE.L  #4,D3
    JSR     immediateData
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    BRA     DONE
    
bclrOpCode
    LEA     outputBCLR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  #10,D1
    MOVE.L  D4,D5
    ROL.W   D1,D5
    AND.L   #$00000007,D5
    
    CMP.B   #2,D5
    BEQ     bclrImmediate
    
    MOVE.L  #0,D2
    MOVE.L  D4,D3
    ROL.W   #7,D3
    AND.L   #$00000007,D3
    
    JSR     DnMode
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
        
bclrImmediate
    
    MOVE.L  #7,D2
    MOVE.L  #4,D3
    
    JSR     immediateData
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE    
    
moveByteOpCode                  *MOVE.B opcode
    CMP.B   #1,D5
    BNE     moveWordOpCode 

moveByteMethod                  *MOVE.B output
    LEA     outputMOVE,A1       *Outputs "MOVE" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputByte,A1       *Outputs ".B" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *Jump to subroutine sourceEA
    
    LEA     outputComma,A1      *Outputs a comma onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA   *Jump to subroutine moveDestinationEA
    
    BRA     DONE                *Yay done
    

moveWordOpCode                  *MOVE.W opcode
    CMP.B   #3,D5
    BNE     moveLongOpCode
   
moveWordMethod                  *MOVE.W output
    MOVE.W  D4,D2               *D4 has the original word
    MOVE.W  #10,D1              *Move the value 10 into D1 since ROL has issues with
    ROL.W   D1,D2               *   immediate values > 8
    
    CMP.W   #1,D2               *If the rotated value is a 1, it's a MOVEA.W
    BEQ     moveAWordMethod    
    
    LEA     outputMOVE,A1       *Outputs "MOVE." onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveWordMethodpt2   *Go to the rest of the method~
    
moveAWordMethod                 *MOVEA.W opcode
    LEA     outputMOVEA,A1      *Outputs "MOVEA" onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveWordMethodpt2   *Go to the rest of the method~
    
moveWordMethodpt2               *Part 2 of the MOVE/MOVEA.W series
    LEA     outputWord,A1       *Outputs ".W" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *Yay subroutines
    
    LEA     outputComma,A1      *outputs a comma onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA   *Gotta check the destination~

    BRA     DONE                *I'm done, bra

moveLongOpCode                  *MOVE.L opcode
    CMP.B   #2,D5
    BNE     addOpCode
    
moveLongOpCodeMethod            *MOVE.L output
    MOVE.W  A2,D2               *Gotta check if it's actually a MOVEA
    MOVE.W  #10,D1
    ROL.W   D1,D2
    
    CMP.W   #1,D2
    BEQ     moveALongMethod   

    LEA     outputMOVE,A1       *outputs "MOVE" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     moveLongMethodpt2   *Go to Part 2 of the MOVE series~
    
moveALongMethod                 *MOVEA.L output
    LEA     outputMOVEA,A1      *Outputs "MOVEA" onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveLongMethodpt2   *Go to part 2~
    
moveLongMethodpt2               *Part 2, the sequel(SQL?)
    
    LEA     outputLong,A1       *Outputs ".L" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    ADD.B   #1,D7
    
    JSR     sourceEA            *Go output source
    
    LEA     outputComma,A1      *Yay commas
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA    *Output destination
    BRA     DONE

addOpCode                        *ADD opcode
    CMP.B   #13,D5
    BNE     subOpCode    
    
addMethod                        *ADD output
    LEA     outputADD,A1         *Outputs "ADD" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode           *Checks if it's a byte,word, or long
    
    CMP.B   #1,D6               *If D6 == 1, the data register is the source
    BEQ     altOrder            *   D6 was decided in dotOpMode(?)
    
    CMP.B   #2,D6
    BEQ     addaOrder           *go do ADDA stuff
    
    JSR     sourceEA            *outputs what the source is
    
    LEA     outputComma,A1      *Commas~~~
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA       *outputs what the destination is
    
    BRA     DONE
    
subOpCode
    CMP.B   #9,D5               *is it SUB?
    BNE     subQOpCode          *not SUB, check if SUBQ

subMethod
    LEA     outputSUB,A1        *output SUB to the console
    MOVE.B  #14,D0  
    TRAP    #15

    JSR     dotOpMode           *check if its a B,W, or L

    CMP.B   #1,D6               *if D6 == 1, the data register is the source
    BEQ     altOrder

    JSR     sourceEA            *outputs what the source is

    LEA     outputComma,A1      *commas
    MOVE.B  #14,D0
    TRAP    #15

    JSR     addDestinationEA    *outputs what ths destination is

    BRA     DONE                

subQOpCode
    CMP.B   #5,D5               *is it SUBQ?
    BNE     orOpCode            *check if its DIVS.W
    
subQMethod
    LEA     outputSUBQ,A1       *output SUBQ
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  D4,D3               *move original word from D4
    MOVE.B  #10,D1              *hacks
    ROL.W   D1,D3               *ROL by 10
    AND.L   #00000003,D3        *Mask 
    JSR     byteOpMode          *check if B,W,L
    
    JSR     subQData            *outputs #1-#8
    
    LEA     outputComma,A1      *commas
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *get the source
    
    BRA     DONE
    
    
subQData
    MOVE.W  D4,D3               *move original word from D4
    ROL.W   #7,D3               *ROL 7
    AND.L   #$00000007,D3       *mask the bits
    
    CMP.B   #0,D3               *if its 0 display 8
    BEQ     display8ForSubQ
    
    CMP.B   #8,D3
    BGE     dataOpCode
    
    LEA     outputPound,A1      *output #
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D1
    MOVE.B  D3,D1               *output 1-7
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *return to subQmethod
    
display8ForSubQ

    LEA     outputPound,A1      *output #
    MOVE.B  #14,D0
    TRAP    #15
    CLR.L   D1
    MOVE.B  #8,D1               *output 8
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *return to subQMethod

orOpCode
    CMP.B   #8,D5   
    BNE     eorOpCode
    
    MOVE.L  D4,D5
    MOVE.L  #10,D1
    ROL.W   D1,D5
    
    AND.L   #$00000007,D5
    
    CMP.B   #7,D5
    BEQ     divsWOpCode
    
orMethod
    LEA     outputOR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    CMP.B   #1,D6
    BEQ     altOrder
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
    
divsWOpCode
*    CMP.B   #8,D5
*    BEQ     divsWCheck          *bits 8,7,6 need to make 7 to be DIVSW
*    BRA     eorOpCode
*    
divsWCheck
    MOVE.W  D4,D3
    MOVE.B  #10,D2
    ROL.W   D2,D3
    AND.L   #$00000007,D3
    CMP.B   #7,D3
    BNE     DONE
    
    LEA     outputDIVSW,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA 
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
    
eorOpCode
    CMP.B   #11,D5
    BNE     shiftsOpCode
    
    MOVE.L  D4,D5
    ROL.W   #8,D5
    AND.L   #$00000001,D5
    
    
eorMethod
    CMP.B   #1,D5
    BNE     cmpOpCode
    
    LEA     outputEOR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    JSR     addDestinationEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE    

cmpOpCode
    CMP.B   #0,D5
    BNE     DONE
    
    LEA     outputCMP,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
   
shiftsOpCode
    CMP.B   #14,D5
    BNE     mulsWOpCode
    
shiftMemoryShift
    MOVE.L  D4,D5
    ROR.W   #6,D5
    AND.L   #$00000003,D5
    
    CMP.B   #3,D5
    BNE     shiftRegisterShift
    
    MOVE.L  D4,D5
    ROL.W   #7,D5
    AND.L   #$00000003,D5
    
memoryLSD
    CMP.B   #1,D5
    BNE     memoryASD
    
    LEA     outputLS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
memoryASD
    CMP.B   #0,D5
    BNE     memoryROD
    
    LEA     outputAS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
memoryROD
    CMP.B   #3,D5
    BNE     dataOpCode
    
    LEA     outputRO,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
    
    
shiftRegisterShift
    MOVE.L  D4,D5
    ROR.W   #3,D5
    AND.L   #$00000003,D5
    
lsdOpCode
    CMP.B   #1,D5
    BNE     asdOpCode
    
lsdMethod
    LEA     outputLS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA
    
    BRA     DONE
 
asdOpCode
    CMP.B   #0,D5
    BNE     rodOpCode
    
    LEA     outputAS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA    
    
    BRA     DONE
    
rodOpCode
    CMP.B   #3,D5
    BNE     DONE
    
    LEA     outputRO,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA
    
    BRA     DONE
    
leftRight
    MOVE.L  D4,D3
    ROL.W   #8,D3
    AND.L   #$00000001,D3

    CMP.B   #0,D3
    BEQ     rightRight
    
    LEA     outputLeft,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
rightRight
    LEA     outputRight,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
shiftSourceEA
    MOVE.L  D4,D2
    ROR.W   #5,D2
    AND.L   #$00000001,D2

    MOVE.L  D4,D3
    ROL.W   #7,D3
    AND.L   #$00000007,D3
    
    CMP.B   #0,D2
    BEQ     shiftImmediateEA
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftImmediateEA
    LEA     outputPound,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CMP.B   #0,D3
    BEQ     shiftImmediateEight
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftImmediateEight
    MOVE.L  #8,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftDestEA
    MOVE.L  D4,D3
    AND.L   #$00000007,D3
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
mulsWOpCode
    CMP.B   #12,D5
    BNE     negOpCode
    MOVE.W  D4,D3
    ROR.W   #6,D3
    AND.B   #7,D3
    CMP.B   #7,D3
    BNE     dataOpCode   

mulsWMethod
    MOVE.W  D4,D3
    ROR.B   #3,D3
    AND.B   #7,D3
    CMP.B   #1,D3
    BEQ     dataOpCode
    
mulsOutput    
    LEA     outputMULS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
    
*mulsLOpCode
*    MOVE.W  D4,D3
*    MOVE.B  #10,D2
*    ROL.W   D2,D3
*    AND.W   #$01FF,D3
*    CMP.W   #304,D3
*    BNE     negOpCode
    
mulsLMethod
        
    
negOpCode
    MOVE.W  D4,D3
    ROL.W   #8,D3
    CMP.B   #$44,D3
    BNE     braOpCode
    
negMethod
    LEA     outputNEG,A1        *output NEG to the console
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D3
    MOVE.W  D4,D3               *move original word from D4
    MOVE.B  #10,D1              *hacks
    ROL.W   D1,D3               *ROL by 10
    AND.L   #00000003,D3        *Mask 
    JSR     byteOpMode          *check if B,W,L
        
    JSR     sourceEA
    
    BRA     DONE

braOpCode
    MOVE.W  D4,D3               *move the opcode word into D3
    ROL.W   #8,D3               *isolate the last byte
    CMP.B   #$60,D3             *is it a BRA?
    BNE     bccOpCode           *its data then
    
braMethod
    LEA     outputBRA,A1        
    MOVE.B  #14,D0
    TRAP    #15


bccDisplacement    
    MOVE.B  D4,D3
    AND.W   #$00FF,D3
    CMP.B   #$00,D3
    BEQ     bitDisplacement16
    CMP.B   #$FF,D3
    BEQ     bitDisplacement32
    ROL.B   #8,D3
    EOR.W   #$FF,D3
    ADD.W   #1,D3
    
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSpace,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  A5,A0
    SUBA.W  D3,A0
    MOVE.W  A0,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0
    
    
    BRA     DONE
   
bitDisplacement16
    
    MOVE.W  A5,A0
    MOVE.W  (A5)+,D4
    MOVE.W  D4,D3
    ROL.W   #4,D3
    AND.W   #$000F,D3
    CMP.W   #8,D3
    BGE     negBit16
    
    MOVE.W  D4,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSpace,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    ADDA.W  D4,A0
    MOVE.W  A0,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0
    
    BRA DONE
    
negBit16

    EOR.W   #$FFFF,D4
    ADD.W   #1,D4
    
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  D4,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSpace,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBA.W  D4,A0
    MOVE.W  A0,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0
    
    BRA     DONE
    
bitDisplacement32

    MOVE.L  A5,A0
    MOVE.L  (A5)+,D4
    MOVE.L  D4,D3
    ROL.W   #4,D3
    AND.L   #$0000000F,D3
    CMP.L   #8,D3
    BGE     negBit32
    
    MOVE.L  D4,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSpace,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    ADDA.L  D4,A0
    MOVE.L  A0,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.L  A4,A0
    
    BRA DONE

negBit32

    EOR.L   #$FFFFFFFF,D4
    ADD.L   #1,D4
    
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D4,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSpace,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    *MOVE.L  A5,A0
    SUBA.L  D4,A0
    MOVE.L  A0,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.L  A4,A0
    
    BRA     DONE
    
bccOpCode
    CMP.B   #6,D5               *is it Bcc?
    BNE     dataOpCode          *its data then
    
bccMethod
    MOVE.W  D4,D3
    ROL.W   #8,D3
    AND.W   #$000F,D3
    CMP.B   #5,D3
    BEQ     bcs
    CMP.B   #$C,D3
    BEQ     bge
    CMP.B   #$D,D3
    BEQ     bct
    BRA     bvc
    
bcs
    LEA     outputBCS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement
    
bge
    LEA     outputBGE,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement

bct
    LEA     outputBCT,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement
    
bvc
    LEA     outputBVC,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement
    

           
dataOpCode
    CLR.L   D3
    LEA     outputData,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  (A5),D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    BRA     DONE


altOrder                            *outputs the Dn as the source for ADD
    JSR     addDestinationEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    BRA     DONE
    
addaOrder                           *ADDA method
    JSR     sourceEA                *output source first
    
    LEA     outputComma,A1          *Comma
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addaDestEA              *Have to set destination mode in addaDestEA
    BRA     DONE


dotOpMode                           *Checks if it's a Byte,Word, or Long for ADD and SUB
    MOVE.W  D4,D3                   *Gets the original code from D4                 
    MOVE.B  #10,D2                  *yay hacks
    
    ROL.W   D2,D3                   *Rotates the original left by 10 bits
    AND.L   #$00000007,D3           *mask it up
    
    CMP.B   #3,D3                   
    BGE     altOpMode               *if value is > 3, Dn is the source
    
    BRA     byteOpMode    

altOpMode                           *But wait, there's more!
    CMP.B   #3,D3                   *If it's 3, it's an ADDA.W
    BEQ     addaWOpMode
    
    CMP.B   #7,D3                   *If it's a 7, it's an ADDA.L
    BEQ     addaLOpMode             *Otherwise, it's just ADD with Dn in source
    
    MOVE.B  #1,D6                   *D6 is 1 if Dn is the source
    AND.B   #$3,D3                  *Mask it so it can continue with the output
    BRA     byteOpMode              *without the meddling 2^2 bit

addaWOpMode                         *It's an ADDA.W
    MOVE.W  #2,D6
    
    LEA     outputADDA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
addaLOpMode                         *It's an ADDA.L
    MOVE.W  #2,D6
    
    ADD.B   #1,D7
    
    LEA     outputADDA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputLong,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
    
byteOpMode                          *It's a byte?
    CMP.B   #0,D3
    BNE     wordOpMode
    
    LEA     outputByte,A1           *Output ".B" !
    MOVE.B  #14,D0
    TRAP    #15
    RTS                             *Time to return back in time
    
wordOpMode                          *It's a word?
    CMP.B   #1,D3
    BNE     longOpMode
    
    LEA     outputWord,A1           *Output ".W" onto console
    MOVE.B  #14,D0
    TRAP    #15
    RTS                             *Time warp~
    
longOpMode                          *It better be a long then
    LEA     outputLong,A1           *outputs ".L" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    ADD.B   #1,D7
   
    RTS                             *whoosh~
 
    
sourceEA                            *output the Source EA
    MOVE.W  D4,D3                   *Put the original opcode into D3
    MOVE.W  D3,D2                   *Copy that into D2
    
    ROR.W   #3,D2                   *Whoo~ Rotating~
    AND.L   #$00000007,D2           *D2 has Mode
    

    AND.L   #$00000007,D3           *D3 has Register

 
DnMode                          *Is the Mode a Data Register?
    CLR.L   D1
    
    CMP.B   #0,D2
    BNE     AnMode
    
    LEA     outputDn,A1         *outputs "D" onto console
    MOVE.B  #14,D0
    TRAP    #15

    MOVE.B  D3,D1               *outputs the register, whatever the numeric value is
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *wooo~
  
AnMode                          *Mode is an Address Register?
    CMP.B   #1,D2
    BNE     deRefAnMode
    
    LEA     outputAn,A1         *Outputs "A" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *Outputs the register value
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *psssh
    
deRefAnMode                     *Mode is a (A0)?
    CMP.B   #2,D2               
    BNE     postIncrementAnMode
    
    LEA     outputdeRefAn1,A1   *Outputs "(A" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *outputs register value
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputdeRefAn2,A1   *makes it pretty by outputting ")"
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS                         *=-=
    
postIncrementAnMode
    CMP.B   #3,D2
    BNE     preDecrementAnMode
    
    LEA     outputdeRefAn1,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputPostIncrementAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
preDecrementAnMode
    CMP.B   #4,D2
    BNE     immediateData
    
    LEA     outputPreDecrementAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputdeRefAn1,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputdeRefAn2,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
immediateData                   *Mode is an #<data>
    CMP.B   #7,D2               *Mode for #<data> is 111
    BNE     xxxWord
    
    CMP.B   #4,D3               *Register for #<data> is 100
    BNE     xxxWord
                               
    LEA     outputPound,A1      *Outputs "#"
    MOVE.B  #14,D0
    TRAP    #15   
    
    CMP.B   #1,D7
    BEQ     immeDataLong
    
    MOVE.W  (A5)+,D3
    
    BRA     immediateDatapt2

immeDataLong
    MOVE.L  (A5)+,D3    
        
immediateDatapt2               *Outputs register value
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15

    RTS                         *~owo~
    
xxxWord
    CMP.B   #7,D2
    BNE     xxxLong
    
    CMP.B   #0,D3
    BNE     xxxLong
    
    LEA     outputAddr,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  (A5)+,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    RTS
    
xxxLong
    CMP.B   #7,D2
    BNE     DONE
    
    CMP.B   #1,D3
    BNE     DONE
    
    LEA     outputAddr,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  (A5)+,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    RTS
    

addDestinationEA                *Since ADD only has data register in dest area
    MOVE.W  D4,D3
    
    MOVE.W  D3,D2
    
    MOVE.L  #10,D1
    ROL.W   D1,D2
    AND.L   #$00000007,D2       *D2 has mode
    
    
    ROL.W   #7,D3
    AND.L   #$00000007,D3       *D3 has register
    
DnRegister                      *For ADD only, since it only has Dn 
    LEA     outputDn,A1         *outputs "D"
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *Outputs register value
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS

moveDestinationEA               *Destination output for MOVE
    MOVE.W  D4,D3
    MOVE.W  D3,D2
    
    ROL.W   #7,D3
    AND.L   #$00000007,D3       *D3 has Register
    
    MOVE.W  #10,D1      
    ROL.W   D1,D2               *D2 has Mode
    AND.L   #$00000007,D2
    
    BRA     DnMode              *output what it is, bra
    
addaDestEA                      *Sets up the dest mode to be proper
    MOVE.W  D4,D3               *Get the original code again
    MOVE.W  D3,D2
    
    ROL.W   #7,D3               
    AND.L   #$00000007,D3       *D3 has register
    
    MOVE.W  #10,D1
    ROL.W   D1,D2               *Have to AND it by 1, since the mode for ADDA
    AND.L   #$00000001,D2       *is always an Address
    
    BRA     DnMode
    
pageContinue
    LEA     outputContinue,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #5,D0
    TRAP    #15
    MOVE.B  #line_count,(A3)
    JMP     getOpCode
    
DONE
    CMP.W   A5,A6
    BLT     END   
    LEA     outputNextLine,A1
    MOVE.B  #14,D0
    TRAP    #15 
    JMP     getOpCode
    
END
    LEA     outputNextLine,A1
    MOVE.B  #14,D0
    TRAP    #15

    LEA     outputEnd,A1
    MOVE.B  #14,D0
    TRAP    #15
    SIMHALT             ; halt simulator

* Put variables and constants here

code        DC.W    $43D2


addCode     DC.W    $D640

moveCode1   DC.W    $303C
moveCode2   DC.W    $0011

outputADD   DC.B    'ADD',0
outputADDA  DC.B    'A',0
outputSUB   DC.B    'SUB',0
outputSUBQ  DC.B    'SUBQ',0
outputMOVE  DC.B    'MOVE',0
outputMOVEA DC.B    'MOVEA',0
outputMOVEMW DC.B   'MOVEM.W ',0
outputMOVEML DC.B   'MOVEM.L ',0
outputMULS  DC.B    'MULS ',0
outputDIVSW DC.B    'DIVS.W ',0
outputNOP   DC.B    'NOP ',0
outputJSR   DC.B    'JSR ',0
outputRTS   DC.B    'RTS ',0
outputLEA   DC.B    'LEA ',0
outputData  DC.B    'DATA ',0
outputNEG   DC.B    'NEG',0
outputBRA   DC.B    'BRA ',0
outputORI   DC.B    'ORI',0
outputOR    DC.B    'OR',0
outputEOR   DC.B    'EOR',0
outputCMPI  DC.B    'CMPI',0
outputCMP   DC.B    'CMP',0
outputBCLR  DC.B    'BCLR ',0
outputLS    DC.B    'LS',0
outputAS    DC.B    'AS',0
outputRO    DC.B    'RO',0
outputLeft  DC.B    'L',0
outputRight DC.B    'R',0
*outputRegList DC.B  'A0-A7/D0-D7',0


outputBCS   DC.B    'BCS ',0
outputBGE   DC.B    'BGE ',0
outputBCT   DC.B    'BCT ',0
outputBVC   DC.B    'BVC ',0

outputByte  DC.B    '.B ',0
outputWord  DC.B    '.W ',0
outputLong  DC.B    '.L ',0

outputdeRefAn1   DC.B    '(A',0
outputdeRefAn2   DC.B    ')',0
outputPostIncrementAn   DC.B    ')+',0
outputPreDecrementAn    DC.B    '-',0

outputAn    DC.B    'A',0
outputDn    DC.B    'D',0
outputPound DC.B    '#',0
outputAddr  DC.B    '   $',0
outputCurrentAddr   DC.W    $0000
outputSlash DC.B    '/',0

outputComma     DC.B    ',',0
outputDot       DC.B    '.',0
outputNextLine  DC.B    ' ',CR,LF,0
outputSpace     DC.B    ' ',0
outputColon     DC.B    ': ',0
outputNegSign   DC.B    '-',0
outputStart     DC.B    'Disassembling Initiated',0
outputEnd       DC.B    'Program Disassembled',0
outputContinue  DC.B    'Press ENTER key to continue disassembling',CR,LF,0
    END    $1000        ; last line of source















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
