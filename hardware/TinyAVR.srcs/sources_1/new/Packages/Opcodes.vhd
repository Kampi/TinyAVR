----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Package Name:        Opcodes
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.1
-- Description:         Opcodes for the TinyAVR microprocessor.
--                      Please check the AVR Instruction Set Manual at
--                          http://ww1.microchip.com/downloads/en/devicedoc/atmel-0856-avr-instruction-set-manual.pdf 
--                      for additional informations.
-- 
-- Dependencies:        
-- 
-- Revision:
--  Revision            0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package Opcodes is

    subtype Opcode_t is STD_LOGIC_VECTOR(15 downto 0);

    constant OpADC      : Opcode_t          := "000111----------";
    constant OpADD      : Opcode_t          := "000011----------";
    constant OpADIW     : Opcode_t          := "10010110--------";
    constant OpAND      : Opcode_t          := "001000----------";
    constant OpANDI     : Opcode_t          := "0111------------";
    constant OpASR      : Opcode_t          := "1001010-----0101";

    constant OpBCLR     : Opcode_t          := "100101001---1000";
    constant OpBLD      : Opcode_t          := "1111100-----0---";
    constant OpBRBC     : Opcode_t          := "111101----------";
    constant OpBRBS     : Opcode_t          := "111100----------";
    constant OpBRCC     : OpCode_t          := "111101-------000";          -- Implemented with BRBC
    constant OpBRCS     : OpCode_t          := "111100-------000";          -- Implemented with BRBS
    constant OpBREAK    : Opcode_t          := "1001010110011000";          -- Not implemented (Debug module)
    constant OpBREQ     : OpCode_t          := "111101-------001";          -- Implemented with BRBC
    constant OpBRGE     : OpCode_t          := "111101-------100";          -- Implemented with BRBC
    constant OpBRHC     : OpCode_t          := "111101-------101";          -- Implemented with BRBC
    constant OpBRHS     : OpCode_t          := "111100-------101";          -- Implemented with BRBS
    constant OpBRID     : OpCode_t          := "111101-------111";          -- Implemented with BRBC
    constant OpBRIE     : OpCode_t          := "111100-------111";          -- Implemented with BRBS
    constant OpBRLO     : OpCode_t          := "111100-------000";          -- Implemented with BRBS
    constant OpBRLT     : OpCode_t          := "111100-------100";          -- Implemented with BRBS
    constant OpBRMI     : OpCode_t          := "111100-------010";          -- Implemented with BRBS
    constant OpBRNE     : OpCode_t          := "111101-------001";          -- Implemented with BRBC
    constant OpBRPL     : OpCode_t          := "111101-------010";          -- Implemented with BRBC
    constant OpBRSH     : OpCode_t          := "111101-------000";          -- Implemented with BRBC
    constant OpBRTC     : OpCode_t          := "111101-------110";          -- Implemented with BRBC
    constant OpBRTS     : OpCode_t          := "111100-------110";          -- Implemented with BRBS
    constant OpBRVC     : OpCode_t          := "111101-------011";          -- Implemented with BRBC
    constant OpBRVS     : OpCode_t          := "111100-------011";          -- Implemented with BRBS
    constant OpBSET     : Opcode_t          := "100101000---1000";
    constant OpBST      : Opcode_t          := "1111101-----0---";

    constant OpCALL     : Opcode_t          := "1001010-----111-";          -- Not available in all devices
    constant OpCBI      : Opcode_t          := "10011000--------";
    constant OpCBR      : Opcode_t          := "0111------------";          -- Implemented with ANDI
    constant OpCLC      : Opcode_t          := "1001010010001000";          -- Implemented with BCLR
    constant OpCLH      : Opcode_t          := "1001010011011000";          -- Implemented with BCLR
    constant OpCLI      : Opcode_t          := "1001010011111000";          -- Implemented with BCLR
    constant OpCLN      : Opcode_t          := "1001010010101000";          -- Implemented with BCLR
    constant OpCLR      : Opcode_t          := "001001----------";          -- Implemented with EOR
    constant OpCLS      : Opcode_t          := "1001010011001000";          -- Implemented with BCLR
    constant OpCLT      : Opcode_t          := "1001010011101000";          -- Implemented with BCLR
    constant OpCLV      : Opcode_t          := "1001010010111000";          -- Implemented with BCLR
    constant OpCLZ      : Opcode_t          := "1001010010011000";          -- Implemented with BCLR
    constant OpCOM      : Opcode_t          := "1001010-----0000";
    constant OpCP       : Opcode_t          := "000101----------";
    constant OpCPC      : Opcode_t          := "000001----------";
    constant OpCPI      : Opcode_t          := "0011------------";
    constant OpCPSE     : Opcode_t          := "000100----------";          -- Not implemented (2 clock cycles)

    constant OpDEC      : Opcode_t          := "1001010-----1010";

    constant OpEICALL   : Opcode_t          := "1001010100011001";          -- Not available in all devices
    constant OpEIJMP    : Opcode_t          := "1001010000011001";          -- Not available in all devices
    constant OpELPM     : Opcode_t          := "----------------";          -- Not implemented
    constant OpEOR      : Opcode_t          := "001001----------";

    constant OpFMUL     : Opcode_t          := "000000110---1---";          -- Not available in all devices
    constant OpFMULS    : Opcode_t          := "000000111---0---";          -- Not available in all devices
    constant OpFMULSU   : Opcode_t          := "000000111---1---";          -- Not available in all devices

    constant OpICALL    : Opcode_t          := "1001010100001001";
    constant OpIJMP     : Opcode_t          := "1001010000001001";
    constant OpIN       : Opcode_t          := "10110-----------";
    constant OpINC      : Opcode_t          := "1001010-----0011";

    constant OpJMP      : Opcode_t          := "1001010-----110-";          -- Not available in all devices

    -- Rest is missing
    constant OpLAC      : Opcode_t          := "1001001-----0110";          -- Not implemented
    constant OpLAS      : Opcode_t          := "1001001-----0101";          -- Not implemented
    constant OpLAT      : Opcode_t          := "1001001-----0111";          -- Not implemented
    -- Rest is missing
    constant OpLDI      : Opcode_t          := "1110------------";

    constant OpMOV      : Opcode_t          := "001011----------";
    constant OpMOVW     : Opcode_t          := "00000001--------";
    constant OpMUL      : Opcode_t          := "100111----------";
    constant OpMULS     : Opcode_t          := "00000010--------";          -- Not implemented
    constant OpMULSU    : Opcode_t          := "000000110---0---";

    constant OpNEG      : Opcode_t          := "1001010-----0001";
    constant OpNOP      : Opcode_t          := "0000000000000000";

    constant OpOR       : Opcode_t          := "001010----------";
    constant OpORI      : Opcode_t          := "0110------------";
    constant OpOUT      : Opcode_t          := "10111-----------";

    constant OpPOP      : Opcode_t          := "1001000-----1111";
    constant OpPUSH     : Opcode_t          := "1001001-----1111";

    constant OpRCALL    : Opcode_t          := "1101------------";          -- Not implemented
    constant OpRET      : Opcode_t          := "1001010100001000";
    constant OpRETI     : Opcode_t          := "1001010100011000";          -- Not implemented
    constant OpRJMP     : Opcode_t          := "1100------------";
    constant OpROL      : Opcode_t          := "000111----------";          -- Implemented with ADC
    constant OpROR      : Opcode_t          := "1001010-----0111";

    constant OpSBC      : Opcode_t          := "000010----------";
    constant OpSBCI     : Opcode_t          := "0100------------";
    constant OpSBI      : Opcode_t          := "10011010--------";
    constant OpSBIC     : Opcode_t          := "10011001--------";          -- Not implemented
    constant OpSBIS     : Opcode_t          := "10011011--------";          -- Not implemented
    constant OpSBIW     : Opcode_t          := "10010111--------";
    constant OpSBR      : Opcode_t          := "0110------------";          -- Implemented with ORI
    constant OpSBRC     : Opcode_t          := "1111110-----0---";          -- Not implemented
    constant OpSBRS     : Opcode_t          := "1111111-----0---";          -- Not implemented
    constant OpSEC      : Opcode_t          := "1001010000001000";          -- Implemented with BSET
    constant OpSEH      : Opcode_t          := "1001010001011000";          -- Implemented with BSET
    constant OpSEI      : Opcode_t          := "1001010001111000";          -- Implemented with BSET
    constant OpSEN      : Opcode_t          := "1001010000101000";          -- Implemented with BSET
    constant OpSER      : Opcode_t          := "11101111----1111";          -- Implemented with LDI
    constant OpSES      : Opcode_t          := "1001010001001000";          -- Implemented with BSET
    constant OpSET      : Opcode_t          := "1001010001101000";          -- Implemented with BSET
    constant OpSEV      : Opcode_t          := "1001010000111000";          -- Implemented with BSET
    constant OpSEZ      : Opcode_t          := "1001010000011000";          -- Implemented with BSET
    constant OpSLEEP    : Opcode_t          := "1000010110001000";          -- Not implemented
    --constant OpSPM      : Opcode_t          := "";
    
    -- Rest is missing
    constant OpSTS      : Opcode_t          := "1001001-----0000";
    constant OpSUB      : Opcode_t          := "000110----------";
    constant OpSUBI     : Opcode_t          := "0101------------";
    constant OpSWAP     : Opcode_t          := "1001010-----0010";

    constant OpTST      : Opcode_t          := "001000----------";          -- Implemented with AND
 
    constant OpWDR      : Opcode_t          := "1001010110101000";          -- Not implemented (no watchdog)

    constant OpXCH      : Opcode_t          := "1001001-----0100";          -- Not implemented

end package;