----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Shift - ALU_Shift_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.1
-- Description:         Shift block for the TinyAVR ALU.
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

entity ALU_Shift is
    Port (  A           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU operand A
            CarryIn     : in STD_LOGIC;                                 -- Input carry flag
            Operation   : in ALU_Op_t;                                  -- ALU operation
            V           : out STD_LOGIC;                                -- V flag from the ALU operation
            C           : out STD_LOGIC;                                -- C flag from the ALU operation
            R           : out STD_LOGIC_VECTOR(7 downto 0)              -- Operation result
            );
end ALU_Shift;

architecture ALU_Shift_Arch of ALU_Shift is

    signal ShiftResult  : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    
    signal ShiftLeft    : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal ShiftRight   : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');

begin

    -- Shift the remaining 6 bits   
    process(Operation, A, CarryIn)
    begin  
        for i in 0 to 6 loop
            ShiftRight(i) <= A(i + 1);
            ShiftLeft(i + 1) <= A(i);
        end loop;
    end process;

    ShiftResult(6 downto 0) <=  ShiftRight(6 downto 0)              when ((Operation = ALU_OP_ASR) or (Operation = ALU_OP_ROR) or (Operation = ALU_OP_LSR)) else
                                A(2 downto 0) & A(7 downto 4)       when (Operation = ALU_OP_SWAP)                                                          else
                                (others => 'X');

    ShiftResult(7)          <=  A(7)                                when (Operation = ALU_OP_ASR)                                                           else
                                CarryIn                             when (Operation = ALU_OP_ROR)                                                           else
                                A(3)                                when (Operation = ALU_OP_SWAP)                                                          else
                                '0'                                 when (Operation = ALU_OP_LSR)                                                           else
                                'X';

    C                       <=  A(0);
    V                       <=  ShiftResult(7) xor A(0);
    R                       <=  ShiftResult;

end ALU_Shift_Arch;