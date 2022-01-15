----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Arithmetic - ALU_Arithmetic_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.2
-- Description:         Arithmetic block for the TinyAVR ALU.
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library TinyAVR;
use TinyAVR.Constants.all;

entity ALU_Arithmetic is
    Port (  A           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand A
            B           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand B
            CarryIn     : in STD_LOGIC;                                 -- Input carry flag
            Operation   : in ALU_Op_t;                                  -- ALU operation
            H           : out STD_LOGIC;                                -- H flag from the ALU operation
            V           : out STD_LOGIC;                                -- V flag from the ALU operation
            C           : out STD_LOGIC;                                -- C flag from the ALU operation
            R           : out STD_LOGIC_VECTOR(7 downto 0)              -- Operation result
            );
end ALU_Arithmetic;

architecture ALU_Arithmetic_Arch of ALU_Arithmetic is

    signal Lower        : STD_LOGIC_VECTOR(4 downto 0)  := (others => '0');     -- Lower part for the H (Half Carry) flag calculation
    signal Middle       : STD_LOGIC_VECTOR(3 downto 0)  := (others => '0');     -- Middle part for the V (Two´s Complement Overflow) flag calculation
    signal Upper        : STD_LOGIC_VECTOR(1 downto 0)  := (others => '0');     -- Upper part for the C (Carry) flag calculation

begin

    -- Get the Half Carry flag
    process(Operation, A, B, CarryIn)
    begin
        case Operation is
            when ALU_OP_ADC | ALU_OP_ADD =>
                Lower <= STD_LOGIC_VECTOR(SIGNED('0' & A(3 downto 0)) + SIGNED('0' & B(3 downto 0)) + SIGNED(STD_LOGIC_VECTOR(to_signed(0, 4)) & (Operation(0) and CarryIn)));

            when ALU_OP_SBC | ALU_OP_SUB =>
                Lower <= STD_LOGIC_VECTOR(SIGNED('0' & A(3 downto 0)) - SIGNED('0' & B(3 downto 0)) - SIGNED(STD_LOGIC_VECTOR(to_signed(0, 4)) & (Operation(0) and CarryIn)));

            when ALU_OP_NEG =>
                Lower <= STD_LOGIC_VECTOR(SIGNED('1' & (not A(3 downto 0))) + to_signed(1, 5));

            when others =>
                Lower <= (others => 'X');

        end case;
    end process;
    
    --  Get the middle part for the Two´s Complement Overflow flag
    process(Operation, A, B, Lower)
    begin
        case Operation is
            when ALU_OP_ADC | ALU_OP_ADD =>
                Middle  <= STD_LOGIC_VECTOR(SIGNED('0' & A(6 downto 4)) + SIGNED('0' & B(6 downto 4)) + SIGNED(STD_LOGIC_VECTOR(to_signed(0, 3)) & Lower(4)));

            when ALU_OP_SBC | ALU_OP_SUB =>
                Middle  <= STD_LOGIC_VECTOR(SIGNED('0' & A(6 downto 4)) - SIGNED('0' & B(6 downto 4)) - SIGNED(STD_LOGIC_VECTOR(to_signed(0, 3)) & Lower(4)));

            when ALU_OP_NEG =>
                Middle  <= STD_LOGIC_VECTOR(SIGNED('1' & (not A(6 downto 4))) + SIGNED(STD_LOGIC_VECTOR(to_signed(0, 3)) & (not Lower(4))));

            when others =>
                Middle  <= (others => 'X');

        end case;
    end process;
    
    -- Get the upper part for the Carry flag
    process(Operation, A, B, Middle)
    begin
        case Operation is
            when ALU_OP_ADC | ALU_OP_ADD =>
                Upper   <= STD_LOGIC_VECTOR(SIGNED('0' & A(7 downto 7)) + SIGNED('0' & B(7 downto 7)) + SIGNED(STD_LOGIC_VECTOR(to_signed(0, 1)) & Middle(3)));

            when ALU_OP_SBC | ALU_OP_SUB =>
                Upper   <= STD_LOGIC_VECTOR(SIGNED('0' & A(7 downto 7)) - SIGNED('0' & B(7 downto 7)) - SIGNED(STD_LOGIC_VECTOR(to_signed(0, 1)) & Middle(3)));

            when ALU_OP_NEG =>
                Upper   <= STD_LOGIC_VECTOR(SIGNED('1' & (not A(7 downto 7))) + SIGNED(STD_LOGIC_VECTOR(to_signed(0, 1)) & (not Middle(3))));

            when others =>
                Upper   <= (others => 'X');

        end case;
    end process;

    H <= Lower(4);
    V <= Middle(3) xor Upper(1);
    C <= Upper(1);
    R <= Upper(0) & Middle(2 downto 0) & Lower(3 downto 0);

end ALU_Arithmetic_Arch;