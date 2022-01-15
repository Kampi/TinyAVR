----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Package Name:        Constants
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.1
-- Description:         Constants for the TinyAVR microprocessor.
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

package Constants is

    subtype Reg_Source_t    is STD_LOGIC_VECTOR(1 downto 0);                        -- Data input source selection
    subtype PC_Mode_t       is STD_LOGIC_VECTOR(1 downto 0);                        -- Program Counter modes
    subtype ALU_Src_t       is STD_LOGIC_VECTOR(1 downto 0);                        -- Input sources for the ALU
    subtype ALU_Op_t        is STD_LOGIC_VECTOR(4 downto 0);                        -- ALU operation code
    subtype Sram_Source_t   is STD_LOGIC_VECTOR(2 downto 0);                        -- SRAM data sources
    subtype Bit_Mask_t      is STD_LOGIC_VECTOR(7 downto 0);                        -- Bit level mask for the bit operations
    subtype Set_Opt_t       is STD_LOGIC;                                           -- Clear / Set flag for bit mask operations
    subtype Write_Opt_t     is STD_LOGIC;                                           -- Write / Lock options for individual status bits
    subtype Stack_Mode_t    is STD_LOGIC;                                           -- Stack pointer counting modes

    -- Program Counter address modes
    constant PC_INC                 :   PC_Mode_t       := "00";                    -- Increment the address of the Program Counter by the given offset
    constant PC_Z_REG               :   PC_Mode_t       := "01";                    -- Use the address from the Z register
    constant PC_KEEP                :   PC_Mode_t       := "10";                    -- Don´t increment the Program Counter
    constant PC_SET                 :   PC_Mode_t       := "11";                    -- Set the Program Counter to a given address

    -- SRAM address sources
    constant MEM_MEMORY             :   Sram_Source_t   := "000";                   -- Update from SRAM
    constant MEM_SREG               :   Sram_Source_t   := "001";                   -- Update from SREG
    constant MEM_REG                :   Sram_Source_t   := "010";                   -- Update from Register
    constant MEM_SP                 :   Sram_Source_t   := "011";                   -- Update from Stack Pointer
    constant MEM_X                  :   Sram_Source_t   := "100";                   -- Update from Register with X Register as address
    constant MEM_Y                  :   Sram_Source_t   := "101";                   -- Update from Register with Y Register as address
    constant MEM_Z                  :   Sram_Source_t   := "110";                   -- Update from Register with Z Register as address

    -- Input data sources
    constant SRC_ALU                :   Reg_Source_t    := "00";                    -- Use the ALU output as data source
    constant SRC_MEMORY             :   Reg_Source_t    := "01";                    -- Use the SRAM output as data source
    constant SRC_IMMEDIATE          :   Reg_Source_t    := "10";                    -- Use a immediate value as data source
    constant SRC_REGISTER           :   Reg_Source_t    := "11";                    -- Use the register file as data source

    -- Second data source for ALU
    constant ALU_SRC_REG            :   ALU_Src_t       := "00";                    -- Register R as data source
    constant ALU_SRC_IMMEDIATE      :   ALU_Src_t       := "01";                    -- Immediate as data source
    constant ALU_SRC_T_REG          :   ALU_Src_t       := "10";                    -- Use the T Flag mask as data source

    -- ALU operations
    constant ALU_OP_NOP             :   ALU_Op_t        := "00000";                 -- No ALU operation

    -- Arithmetic operations
    constant ALU_OP_ADC             :   ALU_Op_t        := "00001";                 -- Addition with carry
    constant ALU_OP_ADD             :   ALU_Op_t        := "00010";                 -- Addition operation
    constant ALU_OP_SBC             :   ALU_Op_t        := "00011";                 -- Subtraction with carry
    constant ALU_OP_SUB             :   ALU_Op_t        := "00100";                 -- Subtraction
    constant ALU_OP_NEG             :   ALU_Op_t        := "00101";                 -- Two´s complement

    -- Logic operations
    constant ALU_OP_AND             :   ALU_Op_t        := "01000";                 -- Logical AND
    constant ALU_OP_OR              :   ALU_Op_t        := "01001";                 -- Logical OR
    constant ALU_OP_NOT             :   ALU_Op_t        := "01010";                 -- Logical NOT
    constant ALU_OP_XOR             :   ALU_Op_t        := "01011";                 -- Logical XOR

    -- Shift operations
    constant ALU_OP_ASR             :   ALU_Op_t        := "10000";                 -- Arithmetic shift right
    constant ALU_OP_LSL             :   ALU_Op_t        := "10001";                 -- Logical Shift Left
    constant ALU_OP_LSR             :   ALU_Op_t        := "10010";                 -- Logical Shift Right
    constant ALU_OP_ROR             :   ALU_Op_t        := "10100";                 -- Rotate Right Through Carry
    constant ALU_OP_SWAP            :   ALU_Op_t        := "10101";                 -- Swap the high and the low nibble

    constant ALU_SET_T              :   ALU_Op_t        := "10110";                 -- Set the T Flag

    -- Multiplication operations
    constant ALU_OP_MUL_HIGH_U      :   ALU_Op_t        := "10111";                 -- Unsigned x Unsigned high byte multiplication
    constant ALU_OP_MUL_LOW_U       :   ALU_Op_t        := "11000";                 -- Unsigned x Unsigned low byte multiplication
    constant ALU_OP_MUL_HIGH_S      :   ALU_Op_t        := "11001";                 -- Signed x Signed high byte multiplication
    constant ALU_OP_MUL_LOW_S       :   ALU_Op_t        := "11010";                 -- Signed x Signedlow byte multiplication
    constant ALU_OP_MUL_HIGH_SU     :   ALU_Op_t        := "11011";                 -- Signed x Unsigned high byte multiplication
    constant ALU_OP_MUL_LOW_SU      :   ALU_Op_t        := "11100";                 -- Signed x Unsigned low byte multiplication

    -- Status bit positions
    constant STATUS_BIT_C           :   INTEGER         := 0;                       -- Bit position of the C (Carry) flag
    constant STATUS_BIT_Z           :   INTEGER         := 1;                       -- Bit position of the Z (Zero) flag
    constant STATUS_BIT_N           :   INTEGER         := 2;                       -- Bit position of the N (Negatice) flag
    constant STATUS_BIT_V           :   INTEGER         := 3;                       -- Bit position of the V (Two´s Complement Overflow) flag
    constant STATUS_BIT_S           :   INTEGER         := 4;                       -- Bit position of the S (Sign) flag
    constant STATUS_BIT_H           :   INTEGER         := 5;                       -- Bit position of the H (Half Carry) flag
    constant STATUS_BIT_T           :   INTEGER         := 6;                       -- Bit position of the T (Copy Storage) flag
    constant STATUS_BIT_I           :   INTEGER         := 7;                       -- Bit position of the I (Interrupt) flag

    -- Status register modification masks
    -- The mask is only needed when the SREG should be written
    constant STATUS_FLAG_HSVNZC     :   Bit_Mask_t      := "00111111";              -- Change the status flags H, S, V, N, Z, C
    constant STATUS_FLAG_SVNZC      :   Bit_Mask_t      := "00011111";              -- Change the status flags S, V, N, Z, C
    constant STATUS_FLAG_SVNZ       :   Bit_Mask_t      := "00011110";              -- Change the status flags S, V, N, Z
    constant STATUS_FLAG_ZC         :   Bit_Mask_t      := "00000011";              -- Change the status flags Z, C
    constant STATUS_FLAG_Z          :   Bit_Mask_t      := "00000010";              -- Change the status flag Z
    constant STATUS_FLAG_C          :   Bit_Mask_t      := "00000001";              -- Change the status flag C

end package;