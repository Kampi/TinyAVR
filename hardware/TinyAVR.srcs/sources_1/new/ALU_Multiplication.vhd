----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Multiplication - ALU_Multiplication_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.1
-- Description:         Multiplication block for the TinyAVR ALU.
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

entity ALU_Multiplication is
    Port (  A           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand A
            B           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand B
            Operation   : in ALU_Op_t;                                  -- ALU operation
            C           : out STD_LOGIC;                                -- C flag from the ALU operation
            R           : out STD_LOGIC_VECTOR(7 downto 0)              -- Operation result
            );
end ALU_Multiplication;

architecture ALU_Multiplication_Arch of ALU_Multiplication is

    signal Partial              : STD_LOGIC_VECTOR(13 downto 0)             := (others => '0');
    signal Transfer             : STD_LOGIC_VECTOR(5 downto 0)              := (others => '0');

begin

    process(A, B, Operation, Transfer)
    begin
        if(Operation = ALU_OP_MUL_LOW_U) then
            Partial <= STD_LOGIC_VECTOR(("00" & UNSIGNED(A(3 downto 0)) * UNSIGNED(B(7 downto 4)) & "0000") +
                                         ("00" & UNSIGNED(A(7 downto 4)) * UNSIGNED(B(3 downto 0)) & "0000") +
                                         ("000000" & UNSIGNED(A(3 downto 0)) * UNSIGNED(B(3 downto 0))));
        elsif(Operation = ALU_OP_MUL_HIGH_U) then
            Partial <= STD_LOGIC_VECTOR(("000000" & UNSIGNED(A(7 downto 4)) * UNSIGNED(B(7 downto 4))) + UNSIGNED("00000000" & Transfer));
        end if;
    end process;

    process(Partial)
    begin
        Transfer <= STD_LOGIC_VECTOR(Partial(13 downto 8));
        C <= Partial(8);
    end process;

    R <= Partial(7 downto 0);

end ALU_Multiplication_Arch;