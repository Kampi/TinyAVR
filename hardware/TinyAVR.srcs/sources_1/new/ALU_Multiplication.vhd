----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Multiplication - ALU_Multiplication_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.2
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

    signal Overflow     : STD_LOGIC                             := '0';
    signal Result_UU    : STD_LOGIC_VECTOR(15 downto 0)         := (others => '0');
    signal Result_SS    : STD_LOGIC_VECTOR(15 downto 0)         := (others => '0');
    signal Result_SU    : STD_LOGIC_VECTOR(15 downto 0)         := (others => '0');

begin

    Overflow    <= A(7) and B(7);

    Result_UU   <= STD_LOGIC_VECTOR(UNSIGNED(A) * UNSIGNED(B));
    Result_SS   <= STD_LOGIC_VECTOR(SIGNED(A) * SIGNED(B));
    Result_SU   <= STD_LOGIC_VECTOR(UNSIGNED(SIGNED(A)) * UNSIGNED(B));

    process(A, B, Operation, Overflow, Result_UU, Result_SS, Result_SU)
    begin
        if(Operation = ALU_OP_MUL_LOW_U) then
            R <= Result_UU(7 downto 0);
        elsif(Operation = ALU_OP_MUL_HIGH_U) then
            R <= Result_UU(15 downto 8);
        elsif(Operation = ALU_OP_MUL_LOW_S) then
            R <= Result_SS(7 downto 0);
        elsif(Operation = ALU_OP_MUL_HIGH_S) then
            R <= Result_SS(15 downto 8);
        elsif(Operation = ALU_OP_MUL_LOW_SU) then
            R <= Result_SU(7 downto 0);
        elsif(Operation = ALU_OP_MUL_HIGH_SU) then
            R <= Result_SU(15 downto 8);
            R(0) <= Result_SU(8) or Overflow;
        end if;
    end process;

    C <= Result_UU(15) when (Operation = ALU_OP_MUL_HIGH_U) else
         Result_SS(15) when (Operation = ALU_OP_MUL_HIGH_S) else
         Result_SU(15) when (Operation = ALU_OP_MUL_HIGH_SU);

end ALU_Multiplication_Arch;