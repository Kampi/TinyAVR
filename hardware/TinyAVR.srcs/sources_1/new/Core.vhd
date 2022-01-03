----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert          
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         Core - Core_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.1
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library TinyAVR;
use TinyAVR.Constants.all;

entity Core is
    Port (  Clock       : in STD_LOGIC;
            nReset      : in STD_LOGIC;
            Output      : out STD_LOGIC_VECTOR(7 downto 0)
            );
end Core;

architecture Core_Arch of Core is

    signal RegisterWE           : STD_LOGIC;
    signal MemoryWE             : STD_LOGIC;
    signal MemoryEnable         : STD_LOGIC;
    signal Pair                 : STD_LOGIC;

    signal MemoryAddress        : STD_LOGIC_VECTOR(7 downto 0);
    signal X                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Y                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Z                    : STD_LOGIC_VECTOR(15 downto 0);
    signal IR                   : STD_LOGIC_VECTOR(15 downto 0);
    signal ProgData             : STD_LOGIC_VECTOR(15 downto 0);
    signal ProgAddr             : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_Offset            : STD_LOGIC_VECTOR(11 downto 0);
    signal PC_Addr              : STD_LOGIC_VECTOR(15 downto 0);
    signal T_Mask               : STD_LOGIC_VECTOR(7 downto 0);
    signal Stack                : STD_LOGIC_VECTOR(7 downto 0);
    signal Memory               : STD_LOGIC_VECTOR(7 downto 0);
    signal Immediate            : STD_LOGIC_VECTOR(7 downto 0);
    signal RegD                 : STD_LOGIC_VECTOR(7 downto 0);
    signal RegR                 : STD_LOGIC_VECTOR(7 downto 0);
    signal ALUStatus            : STD_LOGIC_VECTOR(7 downto 0);
    signal ALUOut               : STD_LOGIC_VECTOR(7 downto 0);
    signal SREG                 : STD_LOGIC_VECTOR(7 downto 0);
    signal DstRegAddr           : STD_LOGIC_VECTOR(6 downto 0);
    signal RegDAddr             : STD_LOGIC_VECTOR(6 downto 0);
    signal RegRAddr             : STD_LOGIC_VECTOR(6 downto 0);
    signal StackPointerIn       : STD_LOGIC_VECTOR(15 downto 0);
    signal StackPointerOut      : STD_LOGIC_VECTOR(15 downto 0);

    signal PC_Mode              : PC_Mode_t;
    signal Register_Sel         : Sel_t;
    signal ALU_Sel              : ALU_Src_t;
    signal ALU_Operation        : ALU_Op_t;
    signal SREG_Mask            : Bit_Mask_t;
    signal MemorySource         : Sram_Source_t;

    component PC is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                Mode            : in PC_Mode_t;
                Addr_Offset     : in STD_LOGIC_VECTOR(11 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                Addr            : in STD_LOGIC_VECTOR(15 downto 0); 
                Prog_Addr       : out STD_LOGIC_VECTOR(15 downto 0);
                Prog_Mem        : in STD_LOGIC_VECTOR(15 downto 0);
                IR              : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component PM is
        Port (  ProgramAddress  : in STD_LOGIC_VECTOR(15 downto 0);
                ProgramData     : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;
    
    component RegisterFile is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                WE              : in STD_LOGIC;
                Pair            : in STD_LOGIC;  
                DstRegAddr      : in STD_LOGIC_VECTOR(6 downto 0);
                RegDAddr        : in STD_LOGIC_VECTOR(6 downto 0);
                RegRAddr        : in STD_LOGIC_VECTOR(6 downto 0);
                Sel             : in Sel_t;
                ALUIn           : in STD_LOGIC_VECTOR(7 downto 0);
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
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                IR              : in STD_LOGIC_VECTOR(15 downto 0);
                ALU_Operation   : out ALU_Op_t;
                ALU_Sel         : out ALU_Src_t;
                T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);
                Register_Sel    : out Sel_t;
                DstRegAddr      : out STD_LOGIC_VECTOR(6 downto 0);
                RegDAddr        : out STD_LOGIC_VECTOR(6 downto 0);
                RegRAddr        : out STD_LOGIC_VECTOR(6 downto 0);
                Immediate       : out STD_LOGIC_VECTOR(7 downto 0);
                Register_WE     : out STD_LOGIC;
                Register_Pair   : out STD_LOGIC;
                Memory_Data     : inout STD_LOGIC_VECTOR(7 downto 0);
                Memory_WE       : out STD_LOGIC;
                Memory_Enable   : out STD_LOGIC;
                Memory_Address  : out STD_LOGIC_VECTOR(7 downto 0);
                Memory_Source   : out Sram_Source_t;
                SREG_Mask       : out Bit_Mask_t;
                SREG            : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);
                StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);
                PC              : in STD_LOGIC_VECTOR(15 downto 0);
                PC_Addr         : out STD_LOGIC_VECTOR(15 downto 0);
                PC_Mode         : out PC_Mode_t;
                PC_Offset       : out STD_LOGIC_VECTOR(11 downto 0)
                );
    end component;

    component SRAM is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                WE              : in STD_LOGIC;
                Enable          : in STD_LOGIC;
                Address         : in STD_LOGIC_VECTOR(7 downto 0);
                X               : in STD_LOGIC_VECTOR(15 downto 0);
                Y               : in STD_LOGIC_VECTOR(15 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                Source          : in Sram_Source_t;
                StatusRegIn     : in STD_LOGIC_VECTOR(7 downto 0); 
                RegisterIn      : in STD_LOGIC_VECTOR(7 downto 0);
                StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);
                StatusRegOut    : out STD_LOGIC_VECTOR(7 downto 0);
                StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);
                Data            : inout STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

begin

    PC_i        : component PC port map (   Clock => Clock,
                                            nReset => nReset,
                                            Prog_Mem => ProgData,
                                            IR => IR,
                                            Mode => PC_Mode,
                                            Addr_Offset => PC_Offset,
                                            Addr => PC_Addr,
                                            Z => Z,
                                            Prog_Addr => ProgAddr
                                            );

    PM_i        : component PM port map (   ProgramAddress => ProgAddr,
                                            ProgramData => ProgData
                                            );

    Register_i  : component RegisterFile port map ( Clock => Clock,
                                                    nReset => nReset,
                                                    WE => RegisterWE,
                                                    Pair => Pair,
                                                    DstRegAddr => DstRegAddr,
                                                    RegDAddr => RegDAddr,
                                                    RegRAddr => RegRAddr,
                                                    Sel => Register_Sel,
                                                    ALUIn => ALUOut,
                                                    Immediate => Immediate,
                                                    Memory => Memory,
                                                    RegD => RegD,
                                                    RegR => RegR,
                                                    X => X,
                                                    Y => Y,
                                                    Z => Z
                                                    );

    ALU_i       : component ALU port map (  Operation => ALU_Operation,
                                            SREGIn => SREG,
                                            Sel => ALU_Sel,
                                            T_Mask => T_Mask,
                                            Mask => SREG_Mask,
                                            RegD => RegD,
                                            RegR => RegR,
                                            Immediate => Immediate,
                                            Result => ALUOut,
                                            SREGOut => ALUStatus
                                            );

    Ctrl_i      : component InstructionDecoder port map (   Clock => Clock,
                                                            nReset => nReset,
                                                            IR => IR,
                                                            Register_WE => RegisterWE, 
                                                            Register_Pair => Pair,
                                                            DstRegAddr => DstRegAddr,
                                                            RegDAddr => RegDAddr,
                                                            RegRAddr => RegRAddr,
                                                            Immediate => Immediate,
                                                            Register_Sel => Register_Sel,
                                                            T_Mask => T_Mask,
                                                            ALU_Sel => ALU_Sel,
                                                            ALU_Operation => ALU_Operation,
                                                            PC => ProgAddr,
                                                            PC_Addr => PC_Addr,
                                                            PC_Mode => PC_Mode,
                                                            PC_Offset => PC_Offset,
                                                            SREG_Mask => SREG_Mask,
                                                            SREG => SREG,
                                                            Memory_Data => Memory,
                                                            Memory_WE => MemoryWE,
                                                            Memory_Enable => MemoryEnable,
                                                            Memory_Address => MemoryAddress,
                                                            Memory_Source => MemorySource,
                                                            StackPointerIn => StackPointerOut,
                                                            StackPointerOut => StackPointerIn
                                                            );

    SRAM_i      : component SRAM port map ( Clock => Clock,
                                            nReset => nReset,
                                            WE => MemoryWE,
                                            Source => MemorySource,
                                            Enable => MemoryEnable,
                                            Address => MemoryAddress,
                                            RegisterIn => RegD,
                                            StatusRegOut => SREG,
                                            StatusRegIn => ALUStatus,
                                            X => X,
                                            Y => Y,
                                            Z => Z,
                                            StackPointerIn => StackPointerIn,
                                            StackPointerOut => StackPointerOut,
                                            Data => Memory
                                            );

end Core_Arch;