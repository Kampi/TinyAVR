----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         ProgMem - ProgMem_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Program memory for the TinyAVR microprocessor.
--                      This design contains the compiled code for the TinyAVR microprocessor.
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
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library TinyAVR;
use TinyAVR.Constants.all;

entity ProgMem is
    Generic (   PM_SIZE         : INTEGER := 6                                  -- Program memory size in bits
                );
    Port (  ProgramAddress      : in UNSIGNED(15 downto 0);                     -- Program memory address bus
            ProgramData         : out STD_LOGIC_VECTOR(15 downto 0)             -- Program memory data bus
            );
end ProgMem;

architecture ProgMem_Arch of ProgMem is

    type ROM_t is array(0 to ((2 ** (PM_SIZE - 1)) - 1)) of STD_LOGIC_VECTOR(15 downto 0);

    impure function InitROMFromFile(RomFileName : in string) return ROM_t is
        FILE FileObj            : text is in RomFileName;
        variable RomFileLine    : line;
        variable ROM            : ROM_t                     := (others => (others => '0'));
    begin
        for i in ROM_t'range loop
            readline(FileObj, RomFileLine);
            hread(RomFileLine, ROM(i));
        end loop;

        return ROM;
    end function;

    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/ALU/Arith-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/ALU/Logic-Test.hex");
    signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/ALU/Mul-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/ALU/Rol-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/Subroutines/Call-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/Bitmanipulation/Bitmanipulation.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/Bitmanipulation/CBI_SBI.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/Branch/Branch-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/SRAM/ST_LD_X-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/SRAM/ST_LD_Y-Test.hex");
    --signal Memory : ROM_t := InitROMFromFile("../../../../software/AVRASM/SRAM/ST_LD_Z-Test.hex");

begin

    ProgramData <= Memory(to_integer(ProgramAddress));

end ProgMem_Arch;