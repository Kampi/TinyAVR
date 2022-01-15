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
    Port (  Clock           : in STD_LOGIC;
            nReset          : in STD_LOGIC;

            -- Program memory interface
            Prog_Addr       : out UNSIGNED(15 downto 0);
            Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);

            -- SRAM interface
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
end Core;

architecture Core_Arch of Core is

    signal RegisterWE           : STD_LOGIC;
    signal Pair                 : STD_LOGIC;
    signal UpdateX              : STD_LOGIC;
    signal UpdateY              : STD_LOGIC;
    signal UpdateZ              : STD_LOGIC;

    signal X                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Y                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Z                    : STD_LOGIC_VECTOR(15 downto 0);
    signal IR                   : STD_LOGIC_VECTOR(15 downto 0);
    signal T_Mask               : STD_LOGIC_VECTOR(7 downto 0);
    signal Immediate            : STD_LOGIC_VECTOR(7 downto 0);
    signal RegD                 : STD_LOGIC_VECTOR(7 downto 0);
    signal RegR                 : STD_LOGIC_VECTOR(7 downto 0);
    signal ALU_Status           : STD_LOGIC_VECTOR(7 downto 0);
    signal ALU_Out              : STD_LOGIC_VECTOR(7 downto 0);
    signal DstReg_Addr          : STD_LOGIC_VECTOR(6 downto 0);
    signal RegD_Addr            : STD_LOGIC_VECTOR(6 downto 0);
    signal RegR_Addr            : STD_LOGIC_VECTOR(6 downto 0);

    signal Offset_Addr          : SIGNED(1 downto 0);
    signal PC_Offset            : SIGNED(11 downto 0);
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
                Addr_Offset     : in SIGNED(11 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                Addr            : in UNSIGNED(15 downto 0);
                Prog_Addr       : out UNSIGNED(15 downto 0);
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);
                IR              : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component RegisterFile is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                WE              : in STD_LOGIC;
                Pair            : in STD_LOGIC;
                UpdateX         : in STD_LOGIC;
                UpdateY         : in STD_LOGIC;
                UpdateZ         : in STD_LOGIC;
                DstReg_Addr     : in STD_LOGIC_VECTOR(6 downto 0);
                RegD_Addr       : in STD_LOGIC_VECTOR(6 downto 0);
                RegR_Addr       : in STD_LOGIC_VECTOR(6 downto 0);
                Offset_Addr     : in SIGNED(1 downto 0);
                Source          : in Reg_Source_t;
                ALU             : in STD_LOGIC_VECTOR(7 downto 0);
                Immediate       : in STD_LOGIC_VECTOR(7 downto 0);
                Memory          : in STD_LOGIC_VECTOR(7 downto 0);
                X               : out STD_LOGIC_VECTOR(15 downto 0);
                Y               : out STD_LOGIC_VECTOR(15 downto 0);
                Z               : out STD_LOGIC_VECTOR(15 downto 0);
                RegD            : out STD_LOGIC_VECTOR(7 downto 0);
                RegR            : out STD_LOGIC_VECTOR(7 downto 0)
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
                IR              : in STD_LOGIC_VECTOR(15 downto 0);
                ALU_Operation   : out ALU_Op_t;
                ALU_Sel         : out ALU_Src_t;
                T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);
                Register_Source : out Reg_Source_t;
                DstReg_Addr     : out STD_LOGIC_VECTOR(6 downto 0);
                RegD_Addr       : out STD_LOGIC_VECTOR(6 downto 0);
                RegR_Addr       : out STD_LOGIC_VECTOR(6 downto 0);
                Immediate       : out STD_LOGIC_VECTOR(7 downto 0);
                Register_WE     : out STD_LOGIC;
                Register_Pair   : out STD_LOGIC;
                Offset_Addr     : out SIGNED(1 downto 0);
                UpdateX         : out STD_LOGIC;
                UpdateY         : out STD_LOGIC;
                UpdateZ         : out STD_LOGIC;
                Memory_Data     : inout STD_LOGIC_VECTOR(7 downto 0);
                Memory_WE       : out STD_LOGIC;
                Memory_Enable   : out STD_LOGIC;
                Memory_Address  : out STD_LOGIC_VECTOR((SRAM_SIZE - 1) downto 0);
                Memory_Source   : out Sram_Source_t;
                SREG_Mask       : out Bit_Mask_t;
                SREG            : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);
                StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);
                PC              : in UNSIGNED(15 downto 0);
                PC_Addr         : out UNSIGNED(15 downto 0);
                PC_Mode         : out PC_Mode_t;
                PC_Offset       : out SIGNED(11 downto 0)
                );
    end component;

begin

    PC_i        : component ProgCounter port map (  Clock => Clock,
                                                    nReset => nReset,
                                                    Prog_Mem => Prog_Mem,
                                                    IR => IR,
                                                    Mode => PC_Mode,
                                                    Addr_Offset => PC_Offset,
                                                    Addr => PC_Addr,
                                                    Z => Z,
                                                    Prog_Addr => PC
                                                    );

    Register_i  : component RegisterFile port map ( Clock => Clock,
                                                    nReset => nReset,
                                                    WE => RegisterWE,
                                                    Pair => Pair,
                                                    UpdateX => UpdateX,
                                                    UpdateY => UpdateY,
                                                    UpdateZ => UpdateZ,
                                                    DstReg_Addr => DstReg_Addr,
                                                    RegD_Addr => RegD_Addr,
                                                    RegR_Addr => RegR_Addr,
                                                    Offset_Addr => Offset_Addr,
                                                    Source => Register_Source,
                                                    ALU => ALU_Out,
                                                    Immediate => Immediate,
                                                    Memory => SRAM_Data,
                                                    RegD => RegD,
                                                    RegR => RegR,
                                                    X => X,
                                                    Y => Y,
                                                    Z => Z
                                                    );

    ALU_i       : component ALU port map (  Operation => ALU_Operation,
                                            SREGIn => SRAM_SREG,
                                            Sel => ALU_Sel,
                                            T_Mask => T_Mask,
                                            Mask => SREG_Mask,
                                            RegD => RegD,
                                            RegR => RegR,
                                            Immediate => Immediate,
                                            Result => ALU_Out,
                                            SREGOut => ALU_Status
                                            );

    Ctrl_i      : component InstructionDecoder generic map ( SRAM_SIZE => SRAM_SIZE
                                                             )
                                               port map (   Clock => Clock,
                                                            nReset => nReset,
                                                            IR => IR,
                                                            Register_WE => RegisterWE, 
                                                            Register_Pair => Pair,
                                                            Offset_Addr => Offset_Addr,
                                                            UpdateX => UpdateX,
                                                            UpdateY => UpdateY,
                                                            UpdateZ => UpdateZ,
                                                            DstReg_Addr => DstReg_Addr,
                                                            RegD_Addr => RegD_Addr,
                                                            RegR_Addr => RegR_Addr,
                                                            Immediate => Immediate,
                                                            Register_Source => Register_Source,
                                                            T_Mask => T_Mask,
                                                            ALU_Sel => ALU_Sel,
                                                            ALU_Operation => ALU_Operation,
                                                            PC => PC,
                                                            PC_Addr => PC_Addr,
                                                            PC_Mode => PC_Mode,
                                                            PC_Offset => PC_Offset,
                                                            SREG_Mask => SREG_Mask,
                                                            SREG => SRAM_SREG,
                                                            Memory_Data => SRAM_Data,
                                                            Memory_WE => SRAM_WE,
                                                            Memory_Enable => SRAM_Enable,
                                                            Memory_Address => SRAM_Address,
                                                            Memory_Source => SRAM_Source,
                                                            StackPointerIn => StackPointerOut,
                                                            StackPointerOut => StackPointerIn
                                                            );

    SRAM_Status <= ALU_Status;
    SRAM_RegD <= RegD;
    SRAM_X <= X;
    SRAM_Y <= Y;
    SRAM_Z <= Z;
    Prog_Addr <= PC;

end Core_Arch;