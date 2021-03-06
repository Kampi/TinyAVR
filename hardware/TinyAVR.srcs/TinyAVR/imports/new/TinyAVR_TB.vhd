----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         TinyAVR_TB - TinyAVR_TB_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Testbench for the AVR microprocessor.
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

entity TinyAVR_TB is
--  Port ( );
end TinyAVR_TB;

architecture TinyAVR_TB_Arch of TinyAVR_TB is

    constant SRAM_SIZE      : INTEGER                       := 12;
    constant PM_SIZE        : INTEGER                       := 6;
    constant ClockPeriod    : TIME                          := 8 ns;

    -- Simulation signals
    signal SimulationClock  : STD_LOGIC                     := '0';
    signal nSimulationReset : STD_LOGIC                     := '0';

    -- I/O ports
    signal PortA            : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal PortB            : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal PortC            : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal PortD            : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');

    component Top is
        Generic (   SRAM_SIZE   : INTEGER                   := 12;
                    PM_SIZE     : INTEGER                   := 6
                    );
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                PortA           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortB           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortC           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortD           : inout STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

begin

    UUT : Top generic map ( SRAM_SIZE => SRAM_SIZE,
                            PM_SIZE => PM_SIZE
                            )
              port map (  Clock => SimulationClock,
                          nReset => nSimulationReset,
                          PortA => PortA,
                          PortB => PortB,
                          PortC => PortC,
                          PortD => PortD
                          );

    -- Clock generation
    Clock_Proc : process
    begin
        wait for (ClockPeriod / 2);
        SimulationClock <= '1';
        wait for (ClockPeriod / 2);
        SimulationClock <= '0';
    end process;

    -- Stimulus
    Stim_Proc : process
    begin
        wait for 10 ns;
        nSimulationReset <= '1';
        wait for 100 ns;
        PortB <= "01010101";
        wait;
    end process;

end TinyAVR_TB_Arch;