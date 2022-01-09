----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         RegisterFile - RegisterFile_Arch
-- Project Name:        TinyCore
-- Target Devices: 
-- Tool Versions:       Vivado 2020.1
-- Description:         Register file for the TinyAVR microprocessor.
--                      This design implements the general purpose register for the TinyAVR microprocessor.
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

entity RegisterFile is
    Port (  Clock       : in STD_LOGIC;                                     -- Clock signal
            nReset      : in STD_LOGIC;                                     -- Reset (active low)

            -- Control input
            WE          : in STD_LOGIC;                                     -- Write enable signal
            Pair        : in STD_LOGIC;                                     -- Copy register pair (used by MOVW)
            UpdateX     : in STD_LOGIC;                                     -- Update the X Register pair with the offset address
            UpdateY     : in STD_LOGIC;                                     -- Update the Y Register pair with the offset address
            UpdateZ     : in STD_LOGIC;                                     -- Update the Z Register pair with the offset address

            -- Address inputs
            DstRegAddr  : in STD_LOGIC_VECTOR(6 downto 0);                  -- Write destination register address
            RegDAddr    : in STD_LOGIC_VECTOR(6 downto 0);                  -- Register D read address
            RegRAddr    : in STD_LOGIC_VECTOR(6 downto 0);                  -- Register R read address
            OffsetAddr  : in SIGNED(1 downto 0);                            -- Address offset for indirect addressing mode

            -- Data inputs
            Source      : in Reg_Source_t;                                  -- Select the input data source for the register file
            ALU         : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from ALU
            Immediate   : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from immediate value
            Memory      : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from SRAM

            -- Data outputs
            X           : out STD_LOGIC_VECTOR(15 downto 0);                -- X register output
            Y           : out STD_LOGIC_VECTOR(15 downto 0);                -- Y register output
            Z           : out STD_LOGIC_VECTOR(15 downto 0);                -- Z register output
            RegD        : out STD_LOGIC_VECTOR(7 downto 0);                 -- Register D output
            RegR        : out STD_LOGIC_VECTOR(7 downto 0)                  -- Register R output
            );
end RegisterFile;

architecture RegisterFile_Arch of RegisterFile is

    constant REG_COUNT  : INTEGER                                       := 32;

    type Registers_t is array(0 to (REG_COUNT - 1)) of STD_LOGIC_VECTOR(7 downto 0);

    signal RegisterFile : Registers_t                                   := (others => (others => '0'));

    signal X_Temp       : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');
    signal Y_Temp       : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');
    signal Z_Temp       : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');

begin

    RegD    <= RegisterFile(to_integer(UNSIGNED(RegDAddr)));
    RegR    <= RegisterFile(to_integer(UNSIGNED(RegRAddr)));
    X_Temp  <= RegisterFile(REG_COUNT - 5) & RegisterFile(REG_COUNT - 6);
    Y_Temp  <= RegisterFile(REG_COUNT - 3) & RegisterFile(REG_COUNT - 4);
    Z_Temp  <= RegisterFile(REG_COUNT - 1) & RegisterFile(REG_COUNT - 2);

    WriteRegister: process
        variable RegisterInput  : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
        variable Address        : UNSIGNED(16 downto 0)         := (others => '0');
    begin
        wait until rising_edge(Clock);

        if(WE = '1') then
            case Source is
                when SRC_ALU =>
                    RegisterFile(to_integer(UNSIGNED(DstRegAddr))) <= ALU;

                when SRC_IMMEDIATE =>
                    RegisterFile(to_integer(UNSIGNED(DstRegAddr))) <= Immediate;

                when SRC_MEMORY =>
                    RegisterFile(to_integer(UNSIGNED(DstRegAddr))) <= Memory;

                when SRC_REGISTER =>
                    if(Pair = '1') then
                        RegisterFile(to_integer(UNSIGNED(DstRegAddr) + 1)) <= RegisterFile(to_integer(UNSIGNED(RegRAddr) + 1));
                    elsif(UpdateX = '1') then
                        Address := UNSIGNED(SIGNED('0' & X_Temp) + resize(OffsetAddr, X_Temp'length + 1));

                        RegisterFile(REG_COUNT - 6) <= STD_LOGIC_VECTOR(Address(7 downto 0));
                        RegisterFile(REG_COUNT - 5) <= STD_LOGIC_VECTOR(Address(15 downto 8));
                    elsif(UpdateY = '1') then
                        Address := UNSIGNED(SIGNED('0' & Y_Temp) + resize(OffsetAddr, Y_Temp'length + 1));

                        RegisterFile(REG_COUNT - 4) <= STD_LOGIC_VECTOR(Address(7 downto 0));
                        RegisterFile(REG_COUNT - 3) <= STD_LOGIC_VECTOR(Address(15 downto 8));
                    elsif(UpdateZ = '1') then
                        Address := UNSIGNED(SIGNED('0' & Z_Temp) + resize(OffsetAddr, Z_Temp'length + 1));

                        RegisterFile(REG_COUNT - 2) <= STD_LOGIC_VECTOR(Address(7 downto 0));
                        RegisterFile(REG_COUNT - 1) <= STD_LOGIC_VECTOR(Address(15 downto 8));
                    else
                        RegisterFile(to_integer(UNSIGNED(DstRegAddr))) <= RegisterFile(to_integer(UNSIGNED(RegRAddr)));
                    end if;

                when others =>
                    RegisterFile(to_integer(UNSIGNED(DstRegAddr))) <= (others => 'X');

            end case;
        end if;

        if(nReset = '0') then
            RegisterFile <= (others => (others => '0'));
        end if;
    end process;

    X <= X_Temp;
    Y <= Y_Temp;
    Z <= Z_Temp;

end RegisterFile_Arch;