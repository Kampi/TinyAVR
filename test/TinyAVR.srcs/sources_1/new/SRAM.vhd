----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         SRAM - SRAM_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         SRAM module for the TinyAVR microprocessor.
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
use TinyAVR.Opcodes.all;

entity SRAM is
    Generic (   SRAM_SIZE   : INTEGER := 12                                     -- Address length of the SRAM in bit
            );
    Port (  Clock           : in STD_LOGIC;                                     -- Clock signal
            nReset          : in STD_LOGIC;                                     -- Reset (active low)
            WE              : in STD_LOGIC;                                     -- Write enable signal
            Enable          : in STD_LOGIC;                                     -- Enable signal

            -- SRAM inputs
            Source          : in Sram_Source_t;                                 -- SRAM data source
            StatusRegIn     : in STD_LOGIC_VECTOR(7 downto 0);                  -- Status input from ALU
            RegisterIn      : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from register file
            StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);                 -- Stack pointer input

            -- Address inputs
            Address         : in STD_LOGIC_VECTOR((SRAM_SIZE - 1) downto 0);    -- SRAM memory address
            X               : in STD_LOGIC_VECTOR(15 downto 0);                 -- X register input
            Y               : in STD_LOGIC_VECTOR(15 downto 0);                 -- Y register input
            Z               : in STD_LOGIC_VECTOR(15 downto 0);                 -- Z register input

            -- SRAM outputs
            StatusRegOut    : out STD_LOGIC_VECTOR(7 downto 0);                 -- Status register output
            StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);                -- Stack pointer output

            -- Memory bus
            Data            : inout STD_LOGIC_VECTOR(7 downto 0)
            );
end SRAM;

architecture SRAM_Arch of SRAM is

    type RAM_t is array(0 to ((2 ** SRAM_SIZE) - 1)) of STD_LOGIC_VECTOR(7 downto 0);

    signal RAM              : RAM_t                                         := (others => (others => '0'));

begin

    Data            <=  RAM(to_integer(UNSIGNED(X))) when ((Source = MEM_X) and (Enable = '1') and (WE = '0'))  else
                        RAM(to_integer(UNSIGNED(Y))) when ((Source = MEM_Y) and (Enable = '1') and (WE = '0'))  else
                        RAM(to_integer(UNSIGNED(Z))) when ((Source = MEM_Z) and (Enable = '1') and (WE = '0'))  else
                        RAM(to_integer(UNSIGNED(Address))) when ((Enable = '1') and (WE = '0'))                 else
                        (others => 'Z');

    StatusRegOut    <= RAM(16#3F#);

    StackPointerOut <= RAM(16#3E#) & RAM(16#3D#);

    UpdateSRAM : process
    begin
        wait until rising_edge(Clock);

        if(Source = MEM_SREG) then
            RAM(16#3F#) <= StatusRegIn;
        elsif((Source = MEM_REG) and (WE = '1') and (Enable = '1')) then
            RAM(to_integer(UNSIGNED(Address))) <= RegisterIn;
        elsif((Source = MEM_SP) and (WE = '1') and (Enable = '1')) then
            RAM(16#3E#) <= StackPointerIn(15 downto 8);
            RAM(16#3D#) <= StackPointerIn(7 downto 0);
        elsif((Source = MEM_MEMORY) and (WE = '1') and (Enable = '1')) then
            RAM(to_integer(UNSIGNED(Address))) <= Data;
        elsif((Source = MEM_X) and (WE = '1') and (Enable = '1')) then
            RAM(to_integer(UNSIGNED(X))) <= RegisterIn;
        elsif((Source = MEM_Y) and (WE = '1') and (Enable = '1')) then
            RAM(to_integer(UNSIGNED(Y))) <= RegisterIn;
        elsif((Source = MEM_Z) and (WE = '1') and (Enable = '1')) then
            RAM(to_integer(UNSIGNED(Z))) <= RegisterIn;
        end if;

        if(nReset = '0') then
            RAM <= (others => (others => '0'));
        end if;
    end process;
end SRAM_Arch;