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
    Generic (   SRAM_SIZE   : INTEGER                           := 12;          -- Address length of the SRAM in bit
                PM_SIZE     : INTEGER                           := 6            -- Address length of the Program Memory in bit
                );
    Port (  Clock           : in STD_LOGIC;                                     -- 
            nReset          : in STD_LOGIC;                                     -- Reset input (active low)

            PortA           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port A
            PortB           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port B
            PortC           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port C
            PortD           : inout STD_LOGIC_VECTOR(7 downto 0)                -- I/O Port D
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

    signal Reg_PortB        : STD_LOGIC_VECTOR(7 downto 0);
    signal Reg_PinB         : STD_LOGIC_VECTOR(7 downto 0);
    signal Reg_DDRB         : STD_LOGIC_VECTOR(7 downto 0);

    component ProgMem is
        Generic (   PM_SIZE     : INTEGER := 6 
                    );
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
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);
                SRAM_Source     : out Sram_Source_t;
                SRAM_WE         : out STD_LOGIC;
                SRAM_Enable     : out STD_LOGIC;
                SRAM_X          : out STD_LOGIC_VECTOR(15 downto 0);
                SRAM_Y          : out STD_LOGIC_VECTOR(15 downto 0);
                SRAM_Z          : out STD_LOGIC_VECTOR(15 downto 0);
                SRAM_Data       : inout STD_LOGIC_VECTOR(7 downto 0);
                SRAM_Address    : out STD_LOGIC_VECTOR((SRAM_SIZE - 1) downto 0);
                SRAM_RegD       : out STD_LOGIC_VECTOR(7 downto 0);
                SRAM_Status     : out STD_LOGIC_VECTOR(7 downto 0);
                SRAM_SREG       : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : out STD_LOGIC_VECTOR(15 downto 0);
                StackPointerOut : in STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component Memory is
        Generic (   SRAM_SIZE   : INTEGER := 12
                    );
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                WE              : in STD_LOGIC;
                Enable          : in STD_LOGIC;
                Address         : in STD_LOGIC_VECTOR((SRAM_SIZE - 1) downto 0);
                X               : in STD_LOGIC_VECTOR(15 downto 0);
                Y               : in STD_LOGIC_VECTOR(15 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                Source          : in Sram_Source_t;
                StatusRegIn     : in STD_LOGIC_VECTOR(7 downto 0); 
                RegisterIn      : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);
                StatusRegOut    : out STD_LOGIC_VECTOR(7 downto 0);
                StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);
                Data            : inout STD_LOGIC_VECTOR(7 downto 0);
                Reg_PortB       : out STD_LOGIC_VECTOR(7 downto 0);
                Reg_PinB        : in STD_LOGIC_VECTOR(7 downto 0);
                Reg_DDRB        : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component IO_Controller is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                PortA           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortB           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortC           : inout STD_LOGIC_VECTOR(7 downto 0);
                PortD           : inout STD_LOGIC_VECTOR(7 downto 0);
                Reg_PortB       : in STD_LOGIC_VECTOR(7 downto 0);
                Reg_PinB        : out STD_LOGIC_VECTOR(7 downto 0);
                Reg_DDRB        : in STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

begin

    PM_i        : component ProgMem generic map ( PM_SIZE => PM_SIZE
                                                  )
                                    port map (  ProgramAddress => ProgramAddress,
                                                ProgramData => ProgramData
                                                );

    Core_i      : component Core    generic map ( SRAM_SIZE => SRAM_SIZE
                                                  )
                                    port map (  Clock => Clock,
                                                nReset => nReset,
                                                Prog_Addr => ProgramAddress,
                                                Prog_Mem => ProgramData,
                                                SRAM_Source => SRAM_Source,
                                                SRAM_WE => SRAM_WE,
                                                SRAM_Enable => SRAM_Enable,
                                                SRAM_X => SRAM_X,
                                                SRAM_Y => SRAM_Y,
                                                SRAM_Z => SRAM_Z,
                                                SRAM_Data => SRAM_Data,
                                                SRAM_Address => SRAM_Address,
                                                SRAM_RegD => SRAM_RegD,
                                                SRAM_Status => SRAM_Status,
                                                SRAM_SREG => SRAM_SREG,
                                                StackPointerIn => StackPointerIn,
                                                StackPointerOut => StackPointerOut
                                                );

    SRAM_i      : component Memory  generic map ( SRAM_SIZE => SRAM_SIZE
                                                  )
                                    port map (  Clock => Clock,
                                                nReset => nReset,
                                                WE => SRAM_WE,
                                                Enable => SRAM_Enable,
                                                Source => SRAM_Source,
                                                Address => SRAM_Address,
                                                RegisterIn => SRAM_RegD,
                                                StatusRegOut => SRAM_SREG,
                                                StatusRegIn => SRAM_Status,
                                                X => SRAM_X,
                                                Y => SRAM_Y,
                                                Z => SRAM_Z,
                                                StackPointerIn => StackPointerIn,
                                                StackPointerOut => StackPointerOut,
                                                Data => SRAM_Data,
                                                Reg_PortB => Reg_PortB,
                                                Reg_PinB => Reg_PinB,
                                                Reg_DDRB => Reg_DDRB
                                                );

    IO_i        : component IO_Controller port map ( Clock => Clock,
                                                     nReset => nReset,
                                                     PortA => PortA,
                                                     PortB => PortB,
                                                     PortC => PortC,
                                                     PortD => PortD,
                                                     Reg_PortB => Reg_PortB,
                                                     Reg_PinB => Reg_PinB,
                                                     Reg_DDRB => Reg_DDRB
                                                     );

end Top_Arch;