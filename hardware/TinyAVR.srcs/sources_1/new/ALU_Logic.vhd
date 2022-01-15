----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Logic - ALU_Logic_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.2
-- Description:         Logic block for the TinyAVR ALU.
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library TinyAVR;
use TinyAVR.Constants.all;

entity ALU_Logic is
    Port (  Operation   : in  ALU_Op_t;                                 -- ALU operation
            A           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand A
            B           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand B
            R           : out STD_LOGIC_VECTOR(7 downto 0)              -- Operation result
            );
end ALU_Logic;

architecture ALU_Logic_Arch of ALU_Logic is

begin
    process(Operation, A, B)
    begin
        case Operation is
            when ALU_OP_AND =>
                R <= A and B;

            when ALU_OP_OR =>
                R <= A or B;

            when ALU_OP_NOT =>
                R <= not A;

            when ALU_OP_XOR =>
                R <= A xor B;

            when others =>
                R <= (others => 'X');

        end case;
    end process;
end ALU_Logic_Arch;