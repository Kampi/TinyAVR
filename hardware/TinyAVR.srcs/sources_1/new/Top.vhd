----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert          
-- 
-- Create Date:         14.01.2022 12:30:00
-- Design Name:         
-- Module Name:         Top - Top_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Top level design for the AVR microprocessor.
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

entity Top is
    Generic (   SRAM_SIZE   : INTEGER := 12                                     -- Address length of the SRAM in bit
            );
    Port (  Clock           : in STD_LOGIC;
            nReset          : in STD_LOGIC
            );
end Top;

architecture Top_Arch of Top is

    signal SRAM_Source     : Sram_Source_t;

    signal SRAM_WE         : STD_LOGIC;
    signal SRAM_Enable     : STD_LOGIC;
    signal SRAM_X          : STD_LOGIC_VECTOR(15 downto 0);
    signal SRAM_Y          : STD_LOGIC_VECTOR(15 downto 0);
    signal SRAM_Z          : STD_LOGIC_VECTOR(15 downto 0);
    signal SRAM_Data       : STD_LOGIC_VECTOR(7 downto 0);
    signal SRAM_Address    : STD_LOGIC_VECTOR((SRAM_SIZE - 1) downto 0);
    signal SRAM_RegD       : STD_LOGIC_VECTOR(7 downto 0);
    signal SRAM_Status     : STD_LOGIC_VECTOR(7 downto 0);
    signal SRAM_SREG       : STD_LOGIC_VECTOR(7 downto 0);
    signal StackPointerIn  : STD_LOGIC_VECTOR(15 downto 0);
    signal StackPointerOut : STD_LOGIC_VECTOR(15 downto 0);

    signal ProgramAddress  : UNSIGNED(15 downto 0);
    signal ProgramData     : STD_LOGIC_VECTOR(15 downto 0);

    component PM is
        Port (  ProgramAddress  : in UNSIGNED(15 downto 0);
                ProgramData     : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component Core is
        Generic (   SRAM_SIZE   : INTEGER := 12
                     );
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                Prog_Addr       : out UNSIGNED(15 downto 0);
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

begin

    PM_i        : component PM      port map (  ProgramAddress => ProgramAddress,
                                                ProgramData => ProgramData
                                                );

    Core_i      : component Core    generic map ( SRAM_SIZE => SRAM_SIZE
                                                  )
                                    port map (  Clock => Clock,
                                                nReset => nReset,
                                                Prog_Addr => ProgramAddress,
                                                Prog_Mem => ProgramData
                                                );

end Top_Arch;