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
                PM_SIZE     : INTEGER                           := 7            -- Address length of the Program Memory in bit
                );
    Port (  Clock           : in STD_LOGIC;                                     -- Main clock input
            nReset          : in STD_LOGIC;                                     -- Reset input (active low)

            PortA           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port A
            PortB           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port B
            PortC           : inout STD_LOGIC_VECTOR(7 downto 0);               -- I/O Port C
            PortD           : inout STD_LOGIC_VECTOR(7 downto 0)                -- I/O Port D
            );
end Top;

architecture Top_Arch of Top is

    signal SRAM_Source      : Sram_Source_t;

    signal SRAM_WE          : STD_LOGIC;
    signal SRAM_Enable      : STD_LOGIC;
    signal Pair             : STD_LOGIC;
    signal UpdateX          : STD_LOGIC;
    signal UpdateY          : STD_LOGIC;
    signal UpdateZ          : STD_LOGIC;

    signal SRAM_Data        : STD_LOGIC_VECTOR(7 downto 0);
    signal SRAM_Address     : UNSIGNED((SRAM_SIZE - 1) downto 0);
    signal SRAM_Status      : STD_LOGIC_VECTOR(7 downto 0);
    signal SRAM_SREG        : STD_LOGIC_VECTOR(7 downto 0);
    signal StackPointer     : STD_LOGIC_VECTOR(15 downto 0);
    signal SP               : STD_LOGIC_VECTOR(15 downto 0);

    signal ProgramAddress   : UNSIGNED(15 downto 0);
    signal ProgramData      : STD_LOGIC_VECTOR(15 downto 0);

    signal ALU_Result       : STD_LOGIC_VECTOR(7 downto 0);
    signal Immediate        : STD_LOGIC_VECTOR(7 downto 0);
    signal RegD             : STD_LOGIC_VECTOR(7 downto 0);
    signal RegR             : STD_LOGIC_VECTOR(7 downto 0);

    signal Z                : UNSIGNED(15 downto 0);
    signal RegD_Addr        : UNSIGNED(6 downto 0);
    signal RegR_Addr        : UNSIGNED(6 downto 0);
    signal DstReg_Addr      : UNSIGNED(6 downto 0);
    signal Offset_Addr      : SIGNED(1 downto 0);

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
                IRQ             : in STD_LOGIC;
                Prog_Addr       : out UNSIGNED(15 downto 0);
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);
                Pair            : out STD_LOGIC;
                UpdateX         : out STD_LOGIC;
                UpdateY         : out STD_LOGIC;
                UpdateZ         : out STD_LOGIC;
                Enable          : out STD_LOGIC;
                WE              : out STD_LOGIC;
                DstReg_Addr     : out UNSIGNED(6 downto 0);
                RegD_Addr       : out UNSIGNED(6 downto 0);
                RegR_Addr       : out UNSIGNED(6 downto 0);
                Offset_Addr     : out SIGNED(1 downto 0);
                Z               : in UNSIGNED(15 downto 0);
                RegD            : in STD_LOGIC_VECTOR(7 downto 0);
                RegR            : in STD_LOGIC_VECTOR(7 downto 0);
                Immediate       : out STD_LOGIC_VECTOR(7 downto 0);
                ALU_Result      : out STD_LOGIC_VECTOR(7 downto 0);
                SRAM_Source     : out Sram_Source_t;
                SRAM_Data       : inout STD_LOGIC_VECTOR(7 downto 0);
                SRAM_Address    : out UNSIGNED((SRAM_SIZE - 1) downto 0);
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
                Pair            : in STD_LOGIC;
                UpdateX         : in STD_LOGIC;
                UpdateY         : in STD_LOGIC;
                UpdateZ         : in STD_LOGIC;
                Address         : in UNSIGNED((SRAM_SIZE - 1) downto 0);
                DstReg_Addr     : in UNSIGNED(6 downto 0);
                RegD_Addr       : in UNSIGNED(6 downto 0);
                RegR_Addr       : in UNSIGNED(6 downto 0);
                Offset_Addr     : in SIGNED(1 downto 0);
                Z               : out UNSIGNED(15 downto 0);
                Source          : in Sram_Source_t;
                Status          : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointer    : in STD_LOGIC_VECTOR(15 downto 0);
                Immediate       : in STD_LOGIC_VECTOR(7 downto 0);
                ALU             : in STD_LOGIC_VECTOR(7 downto 0);
                SREG            : out STD_LOGIC_VECTOR(7 downto 0);
                SP              : out STD_LOGIC_VECTOR(15 downto 0);
                Data            : inout STD_LOGIC_VECTOR(7 downto 0);
                RegD            : out STD_LOGIC_VECTOR(7 downto 0);
                RegR            : out STD_LOGIC_VECTOR(7 downto 0);
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
                                                IRQ => '0',
                                                Prog_Addr => ProgramAddress,
                                                Prog_Mem => ProgramData,
                                                RegD_Addr => RegD_Addr,
                                                RegR_Addr => RegR_Addr,
                                                DstReg_Addr => DstReg_Addr,
                                                Offset_Addr => Offset_Addr,
                                                Z => Z,
                                                RegD => RegD,
                                                RegR => RegR,
                                                Immediate => Immediate,
                                                ALU_Result => ALU_Result,
                                                Pair => Pair,
                                                UpdateX => UpdateX,
                                                UpdateY => UpdateY,
                                                UpdateZ => UpdateZ,
                                                SRAM_Source => SRAM_Source,
                                                WE => SRAM_WE,
                                                Enable => SRAM_Enable,
                                                SRAM_Data => SRAM_Data,
                                                SRAM_Address => SRAM_Address,
                                                SRAM_Status => SRAM_Status,
                                                SRAM_SREG => SRAM_SREG,
                                                StackPointerIn => StackPointer,
                                                StackPointerOut => SP
                                                );

    SRAM_i      : component Memory  generic map ( SRAM_SIZE => SRAM_SIZE
                                                  )
                                    port map (  Clock => Clock,
                                                nReset => nReset,
                                                WE => SRAM_WE,
                                                Enable => SRAM_Enable,
                                                Pair => Pair,
                                                UpdateX => UpdateX,
                                                UpdateY => UpdateY,
                                                UpdateZ => UpdateZ,
                                                Source => SRAM_Source,
                                                Address => SRAM_Address,
                                                SREG => SRAM_SREG,
                                                Status => SRAM_Status,
                                                Z => Z,
                                                StackPointer => StackPointer,
                                                Immediate => Immediate,
                                                ALU => ALU_Result,
                                                SP => SP,
                                                Data => SRAM_Data,
                                                Reg_PortB => Reg_PortB,
                                                Reg_PinB => Reg_PinB,
                                                Reg_DDRB => Reg_DDRB,
                                                RegD => RegD,
                                                RegR => RegR,
                                                RegD_Addr => RegD_Addr,
                                                RegR_Addr => RegR_Addr,
                                                DstReg_Addr => DstReg_Addr,
                                                Offset_Addr => Offset_Addr
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