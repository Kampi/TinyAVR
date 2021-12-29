----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         SRAM - SRAM_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.1
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
    Port (  Clock           : in STD_LOGIC;                                     -- Clock signal
            nReset          : in STD_LOGIC;                                     -- Reset (active low)
            Mode            : in Sram_Mode_t;                                   -- SRAM operation mode
            WE              : in STD_LOGIC;                                     -- Write enable signal
            Mask            : in Bit_Mask_t;                                    -- Bit modification mask (used by CBI and SBI)
            Set             : in Set_Opt_t;                                     -- Set options for the masked bits (used by CBI and SBI)
            Write           : in Write_Opt_t;                                   -- Enable write of individual bits in the memory (used by CBI and SBI)
            Enable          : in STD_LOGIC;                                     -- Enable signal

            -- Data inputs
            MemoryIn        : in STD_LOGIC_VECTOR(7 downto 0);                  -- Memory data input
            SREGIn          : in STD_LOGIC_VECTOR(7 downto 0);                  -- Status input from ALU

            -- Address inputs
            ImmediateAddr   : in STD_LOGIC_VECTOR(5 downto 0);                  -- Immediate address from program code
            X               : in STD_LOGIC_VECTOR(15 downto 0);                 -- X register input
            Y               : in STD_LOGIC_VECTOR(15 downto 0);                 -- Y register input
            Z               : in STD_LOGIC_VECTOR(15 downto 0);                 -- Z register input

            -- Data outputs
            MemoryOut       : out STD_LOGIC_VECTOR(7 downto 0);                 -- Data out bus
            SREGOut         : out STD_LOGIC_VECTOR(7 downto 0)                  -- Status register
            );
end SRAM;

architecture SRAM_Arch of SRAM is

    type RAM_t is array(0 to ((2 ** SRAM_SIZE) - 1)) of STD_LOGIC_VECTOR(7 downto 0);

    signal RAM              : RAM_t                                         := (others => (others => '0'));

begin

    MemoryOut       <=  RAM(to_integer(UNSIGNED(ImmediateAddr))) when ((Enable = '1') and (Mode = MEM_MEMORY)) else
                        (others => 'Z');

    SREGOut         <= RAM(16#3F#);

    UpdateSRAM : process
        variable RAMEND         : UNSIGNED(15 downto 0) := (others => '0');
        variable StackPointer   : UNSIGNED(15 downto 0) := (others => '0');
    begin
        wait until rising_edge(Clock);

        -- Update the SREG
        if(Mode = MEM_UPDATE_SREG) then
            RAM(16#3F#) <= SREGIn;
        -- Update the SRAM from a immediate address
        elsif(Mode = MEM_MEMORY) then
            if((WE = '1') and (Enable = '1')) then
                -- Write a complete byte
                if(Write = OPT_LOCK) then
                    RAM(to_integer(UNSIGNED(ImmediateAddr))) <= MemoryIn;
                else
                    -- Set / Clear single bits
                    if(Set = OPT_SET) then
                        RAM(to_integer(UNSIGNED(ImmediateAddr))) <= RAM(to_integer(UNSIGNED(ImmediateAddr))) or Mask;
                    else
                        RAM(to_integer(UNSIGNED(ImmediateAddr))) <= RAM(to_integer(UNSIGNED(ImmediateAddr))) and (not Mask);
                    end if;
                end if;
            end if;
        -- Save the data on the stack
        elsif(Mode = MEM_STACK) then
            if(Enable = '1') then
                -- Get the current address from the stack pointer register
                StackPointer := UNSIGNED(RAM(16#3E#)) & UNSIGNED(RAM(16#3D#));

                -- Save the data and decrement the counter when the stack should be written
                if(WE = '1') then
                    RAM(to_integer(UNSIGNED(StackPointer))) <= MemoryIn;
                    StackPointer := StackPointer - 1;
                -- Increment the counter and get the data when the stack should be read
                else
                    StackPointer := StackPointer + 1;
                    MemoryOut <= RAM(to_integer(UNSIGNED(StackPointer)));
                end if;

                -- Save the new stack pointer
                RAM(16#3D#) <= STD_LOGIC_VECTOR(StackPointer(7 downto 0));
                RAM(16#3E#) <= STD_LOGIC_VECTOR(StackPointer(15 downto 8));
            end if;
        end if;

        if(nReset = '0') then
            RAM <= (others => (others => '0'));

            -- Initialize the stack pointer
            RAMEND := to_unsigned(((2 ** SRAM_SIZE) - 1), RAMEND'length);
            --RAM(61) <= STD_LOGIC_VECTOR(RAMEND(7 downto 0));
            --RAM(62) <= STD_LOGIC_VECTOR(RAMEND(15 downto 8));
            RAM(61) <= x"10";
            RAM(62) <= x"00";
        end if;
    end process;
end SRAM_Arch;