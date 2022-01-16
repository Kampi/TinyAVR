----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert          
-- 
-- Create Date:         15.01.2022 22:08:40
-- Design Name: 
-- Module Name:         IO_Controller - IO_Controller_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         IO controller for the AVR microprocessor.
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

entity IO_Controller is
    Port (  Clock           : in STD_LOGIC;                                     -- 
            nReset          : in STD_LOGIC;                                     -- Reset input (active low)

            -- I/O ports
            PortA           : inout STD_LOGIC_VECTOR(7 downto 0);               -- Port A output
            PortB           : inout STD_LOGIC_VECTOR(7 downto 0);               -- Port B output
            PortC           : inout STD_LOGIC_VECTOR(7 downto 0);               -- Port C output
            PortD           : inout STD_LOGIC_VECTOR(7 downto 0);               -- Port D output

            -- Registers
            Reg_PortB       : in STD_LOGIC_VECTOR(7 downto 0);                  -- 
            Reg_PinB        : out STD_LOGIC_VECTOR(7 downto 0);                 -- 
            Reg_DDRB        : in STD_LOGIC_VECTOR(7 downto 0)                   -- 
            );
end IO_Controller;

architecture IO_Controller_Arch of IO_Controller is

    signal Test : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

    PortB <= (others => '1') when (Test = (Test'range => '1')) else (others => 'Z');

    process(PortB)
    begin
        if(Test = (Test'range => '0')) then
            Reg_PinB <= PortB;
        end if;
    end process;

end IO_Controller_Arch;