----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert          
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         Core - Core_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         CPU core module for the TinyAVR microprocessor.
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

entity Core is
    Generic (   SRAM_SIZE   : INTEGER := 12
                );
    Port (  Clock           : in STD_LOGIC;                                     --
            nReset          : in STD_LOGIC;                                     --
            IRQ             : in STD_LOGIC;                                     -- Interrupt request

            -- Control signals
            Pair            : out STD_LOGIC;                                    -- Use a register pair instead of a single register
            UpdateX         : out STD_LOGIC;                                    -- Update the X Register pair with the offset address
            UpdateY         : out STD_LOGIC;                                    -- Update the Y Register pair with the offset address
            UpdateZ         : out STD_LOGIC;                                    -- Update the Z Register pair with the offset address

            -- Program memory interface
            Prog_Addr       : out UNSIGNED(15 downto 0);                        --
            Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);                 --

            DstReg_Addr     : out UNSIGNED(6 downto 0);                         -- Destination register address
            RegD_Addr       : out UNSIGNED(6 downto 0);                         -- Register D address
            RegR_Addr       : out UNSIGNED(6 downto 0);                         -- Register R address
            Offset_Addr     : out SIGNED(1 downto 0);                           -- Offset address for the indirect address mode
            Z               : in UNSIGNED(15 downto 0);                         -- Z Register address

            RegD            : in STD_LOGIC_VECTOR(7 downto 0);                  -- Register D input
            RegR            : in STD_LOGIC_VECTOR(7 downto 0);                  -- Register R input
            Immediate       : out STD_LOGIC_VECTOR(7 downto 0);                 -- Immediate value from Program memory
            ALU_Result      : out STD_LOGIC_VECTOR(7 downto 0);                 -- Result from ALU

            -- SRAM interface
            Enable          : out STD_LOGIC;                                    -- Enable the SRAM
            WE              : out STD_LOGIC;                                    -- Enable write to the SRAM
            SRAM_Source     : out Sram_Source_t;
            SRAM_Data       : inout STD_LOGIC_VECTOR(7 downto 0);
            SRAM_Address    : out UNSIGNED((SRAM_SIZE - 1) downto 0);
            SRAM_Status     : out STD_LOGIC_VECTOR(7 downto 0);
            SRAM_SREG       : in STD_LOGIC_VECTOR(7 downto 0);
            StackPointerIn  : out STD_LOGIC_VECTOR(15 downto 0);
            StackPointerOut : in STD_LOGIC_VECTOR(15 downto 0)
            );
end Core;

architecture Core_Arch of Core is

    signal Immediate_Temp       : STD_LOGIC_VECTOR(7 downto 0)          := (others => '0');

    signal IR                   : STD_LOGIC_VECTOR(15 downto 0);
    signal T_Mask               : STD_LOGIC_VECTOR(7 downto 0);
    signal ALU_Status           : STD_LOGIC_VECTOR(7 downto 0);

    signal PC                   : UNSIGNED(15 downto 0);
    signal PC_Addr              : UNSIGNED(15 downto 0);

    signal PC_Mode              : PC_Mode_t;
    signal Register_Source      : Reg_Source_t;
    signal ALU_Sel              : ALU_Src_t;
    signal ALU_Operation        : ALU_Op_t;
    signal SREG_Mask            : Bit_Mask_t;

    component ProgCounter is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                Mode            : in PC_Mode_t;
                Z               : in UNSIGNED(15 downto 0);
                Addr            : in UNSIGNED(15 downto 0);
                Prog_Addr       : out UNSIGNED(15 downto 0);
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);
                IR              : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component ALU is
        Port (  RegD            : in STD_LOGIC_VECTOR(7 downto 0);
                RegR            : in STD_LOGIC_VECTOR(7 downto 0);
                Immediate       : in STD_LOGIC_VECTOR(7 downto 0);
                Operation       : in ALU_Op_t;
                Sel             : in ALU_Src_t;
                T_Mask          : in STD_LOGIC_VECTOR(7 downto 0);
                Mask            : in Bit_Mask_t; 
                SREGIn          : in STD_LOGIC_VECTOR(7 downto 0); 
                SREGOut         : out STD_LOGIC_VECTOR(7 downto 0);
                Result          : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component InstructionDecoder is
        Generic (   SRAM_SIZE   : INTEGER := 12
                    );
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                IRQ             : in STD_LOGIC;
                IR              : in STD_LOGIC_VECTOR(15 downto 0);
                Pair            : out STD_LOGIC;
                ALU_Operation   : out ALU_Op_t;
                ALU_Sel         : out ALU_Src_t;
                T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);
                Immediate       : out STD_LOGIC_VECTOR(7 downto 0);
                Register_Source : out Reg_Source_t;
                DstReg_Addr     : out UNSIGNED(6 downto 0);
                RegD_Addr       : out UNSIGNED(6 downto 0);
                RegR_Addr       : out UNSIGNED(6 downto 0);
                Offset_Addr     : out SIGNED(1 downto 0);
                UpdateX         : out STD_LOGIC;
                UpdateY         : out STD_LOGIC;
                UpdateZ         : out STD_LOGIC;
                Memory_Data     : inout STD_LOGIC_VECTOR(7 downto 0);
                Memory_WE       : out STD_LOGIC;
                Memory_Enable   : out STD_LOGIC;
                Memory_Address  : out UNSIGNED((SRAM_SIZE - 1) downto 0);
                Memory_Source   : out Sram_Source_t;
                SREG_Mask       : out Bit_Mask_t;
                SREG            : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);
                StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);
                PC              : in UNSIGNED(15 downto 0);
                PC_Addr         : out UNSIGNED(15 downto 0);
                PC_Mode         : out PC_Mode_t
                );
    end component;

begin

    PC_i        : component ProgCounter port map (  Clock => Clock,
                                                    nReset => nReset,
                                                    Prog_Mem => Prog_Mem,
                                                    IR => IR,
                                                    Mode => PC_Mode,
                                                    Addr => PC_Addr,
                                                    Z => Z,
                                                    Prog_Addr => PC
                                                    );

    ALU_i       : component ALU port map (  Operation => ALU_Operation,
                                            SREGIn => SRAM_SREG,
                                            Sel => ALU_Sel,
                                            T_Mask => T_Mask,
                                            Mask => SREG_Mask,
                                            RegD => RegD,
                                            RegR => RegR,
                                            Immediate => Immediate_Temp,
                                            Result => ALU_Result,
                                            SREGOut => ALU_Status
                                            );

    Ctrl_i      : component InstructionDecoder generic map ( SRAM_SIZE => SRAM_SIZE
                                                             )
                                               port map (   Clock => Clock,
                                                            nReset => nReset,
                                                            IRQ => IRQ,
                                                            IR => IR,
                                                            Pair => Pair,
                                                            Offset_Addr => Offset_Addr,
                                                            UpdateX => UpdateX,
                                                            UpdateY => UpdateY,
                                                            UpdateZ => UpdateZ,
                                                            DstReg_Addr => DstReg_Addr,
                                                            RegD_Addr => RegD_Addr,
                                                            RegR_Addr => RegR_Addr,
                                                            Immediate => Immediate_Temp,
                                                            Register_Source => Register_Source, -- <- Kann weg
                                                            T_Mask => T_Mask,
                                                            ALU_Sel => ALU_Sel,
                                                            ALU_Operation => ALU_Operation,
                                                            PC => PC,
                                                            PC_Addr => PC_Addr,
                                                            PC_Mode => PC_Mode,
                                                            SREG_Mask => SREG_Mask,
                                                            SREG => SRAM_SREG,
                                                            Memory_Data => SRAM_Data,
                                                            Memory_WE => WE,
                                                            Memory_Enable => Enable,
                                                            Memory_Address => SRAM_Address,
                                                            Memory_Source => SRAM_Source,
                                                            StackPointerIn => StackPointerOut,
                                                            StackPointerOut => StackPointerIn
                                                            );

    SRAM_Status <= ALU_Status;
    Prog_Addr <= PC;
    Immediate <= Immediate_Temp;

end Core_Arch;