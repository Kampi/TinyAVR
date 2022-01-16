----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         Memory - Memory_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Memory module for the TinyAVR microprocessor.
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

entity Memory is
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
            Data            : inout STD_LOGIC_VECTOR(7 downto 0);

            -- I/O controller register
            Reg_PortB       : out STD_LOGIC_VECTOR(7 downto 0);                 --
            Reg_PinB        : in STD_LOGIC_VECTOR(7 downto 0);                  --
            Reg_DDRB        : out STD_LOGIC_VECTOR(7 downto 0)                  --
            );
end Memory;

architecture Memory_Arch of Memory is

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

    WriteMemory_Proc : process
    begin
        wait until rising_edge(Clock);

        if((WE = '1') and (Enable = '1')) then
            case Source is
                when MEM_SREG =>
                    RAM(16#3F#) <= StatusRegIn;
                when MEM_REG =>
                    RAM(to_integer(UNSIGNED(Address))) <= RegisterIn;
                when MEM_SP =>
                    RAM(16#3E#) <= StackPointerIn(15 downto 8);
                    RAM(16#3D#) <= StackPointerIn(7 downto 0);
                when MEM_X =>
                    RAM(to_integer(UNSIGNED(X))) <= RegisterIn;
                when MEM_Y =>
                    RAM(to_integer(UNSIGNED(Y))) <= RegisterIn;
                when MEM_Z =>
                    RAM(to_integer(UNSIGNED(Z))) <= RegisterIn;
                when others =>
                    case Address is
                        when others =>
                            RAM(to_integer(UNSIGNED(Address))) <= Data;
                    end case;
            end case;
        end if;

        if(nReset = '0') then
            RAM <= (others => (others => '0'));
        end if;
    end process;
end Memory_Arch;