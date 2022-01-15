----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ProgCounter - ProgCounter_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.2
-- Description:         Program counter for the TinyAVR microprocessor.
--                      This logic block updates the Program Counter (PC) and is responsible for
--                      loading new instructions into the Instruction Register (IR).
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

entity ProgCounter is
    Port (  Clock           : in STD_LOGIC;                                 -- Clock signal
            nReset          : in STD_LOGIC;                                 -- Reset (active low)
            Mode            : in PC_Mode_t;                                 -- Update source for the Programm Counter

            Addr_Offset     : in SIGNED(11 downto 0);                       -- Address offset for the Programm Counter
            Z               : in STD_LOGIC_VECTOR(15 downto 0);             -- Address input from Z register
            Addr            : in UNSIGNED(15 downto 0);                     -- Address input for the Program Counter

            Prog_Addr       : out UNSIGNED(15 downto 0);                    -- Programm address output
            Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);             -- Programm memory

            IR              : out STD_LOGIC_VECTOR(15 downto 0)             -- Instruction register
            );
end ProgCounter;

architecture ProgCounter_Arch of ProgCounter is

    signal PC               : UNSIGNED(15 downto 0)                 := (others => '0');

begin

    process
    begin
        wait until rising_edge(Clock);

        if(Mode = PC_INC) then
            IR <= Prog_Mem;
        end if;

        case Mode is
            when PC_INC =>
                PC <= UNSIGNED(to_unsigned(to_integer(SIGNED(PC)) + to_integer(Addr_Offset), PC'length));

            when PC_Z_REG =>
                PC <= UNSIGNED(Z);

            when PC_KEEP =>
                PC <= PC;

            when PC_SET =>
                PC <= Addr;

            when others =>
                PC <= (others => 'X');
        end case;
 
        if(nReset = '0') then
            PC <= (others => '0');
            IR <= (others => '0');
        end if;
    end process;

    Prog_Addr <= PC;
end ProgCounter_Arch;