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

begin

end ALU_Multiplication_Arch;