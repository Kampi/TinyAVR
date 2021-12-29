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

    signal Register_WE          : STD_LOGIC;
    signal Memory_WE            : STD_LOGIC;
    signal Memory_Enable        : STD_LOGIC;
    signal Pair                 : STD_LOGIC;

    signal ImmediateAddr        : STD_LOGIC_VECTOR(5 downto 0);
    signal X                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Y                    : STD_LOGIC_VECTOR(15 downto 0);
    signal Z                    : STD_LOGIC_VECTOR(15 downto 0);
    signal IR                   : STD_LOGIC_VECTOR(15 downto 0);
    signal ProgData             : STD_LOGIC_VECTOR(15 downto 0);
    signal ProgAddr             : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_Offset            : STD_LOGIC_VECTOR(11 downto 0);
    signal T_Mask               : STD_LOGIC_VECTOR(7 downto 0);
    signal Stack                : STD_LOGIC_VECTOR(7 downto 0);
    signal Memory_Data          : STD_LOGIC_VECTOR(7 downto 0);
    signal Immediate            : STD_LOGIC_VECTOR(7 downto 0);
    signal RegD                 : STD_LOGIC_VECTOR(7 downto 0);
    signal RegR                 : STD_LOGIC_VECTOR(7 downto 0);
    signal ALUResult            : STD_LOGIC_VECTOR(7 downto 0);
    signal ALUStatus            : STD_LOGIC_VECTOR(7 downto 0);
    signal SREG                 : STD_LOGIC_VECTOR(7 downto 0);
    signal DstRegAddr           : STD_LOGIC_VECTOR(6 downto 0);
    signal RegDAddr             : STD_LOGIC_VECTOR(6 downto 0);
    signal RegRAddr             : STD_LOGIC_VECTOR(6 downto 0);

    signal PC_Mode              : PC_Mode_t;
    signal Register_Sel         : Sel_t;
    signal ALU_Sel              : ALU_Src_t;
    signal ALU_Operation        : ALU_Op_t;
    signal SREG_Mask            : Bit_Mask_t;
    signal SREG_Set             : Set_Opt_t;
    signal SREG_Write           : Write_Opt_t;
    signal Memory_Mode          : Sram_Mode_t;
    signal Memory_Set           : Set_Opt_t;
    signal Memory_Write         : Write_Opt_t;
    signal Memory_Mask          : Bit_Mask_t;

    component PC is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                Mode            : in PC_Mode_t;
                Offset          : in STD_LOGIC_VECTOR(11 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                AddressIn       : in STD_LOGIC_VECTOR(15 downto 0); 
                Data            : in STD_LOGIC_VECTOR(15 downto 0);
                AddressOut      : out STD_LOGIC_VECTOR(15 downto 0);
                IR              : out STD_LOGIC_VECTOR(15 downto 0)
                );
    end component;

    component PM is
        Port (  Address         : in STD_LOGIC_VECTOR(15 downto 0);
                Data            : out STD_LOGIC_VECTOR(15 downto 0)
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
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                RegD            : in STD_LOGIC_VECTOR(7 downto 0);
                RegR            : in STD_LOGIC_VECTOR(7 downto 0);
                Immediate       : in STD_LOGIC_VECTOR(7 downto 0);
                Operation       : in ALU_Op_t;
                Sel             : in ALU_Src_t;
                T_Mask          : in STD_LOGIC_VECTOR(7 downto 0);
                Set_Mask        : in Bit_Mask_t;
                Set             : in Set_Opt_t;
                Set_E           : in Write_Opt_t;
                SREGIn          : in STD_LOGIC_VECTOR(7 downto 0); 
                SREGOut         : out STD_LOGIC_VECTOR(7 downto 0);
                Result          : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component InstructionDecoder is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                SREG            : in STD_LOGIC_VECTOR(7 downto 0);
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
                Memory_WE       : out STD_LOGIC;
                Memory_Enable   : out STD_LOGIC;
                Memory_Stack    : out STD_LOGIC_VECTOR(7 downto 0);
                Memory_Mask     : out STD_LOGIC_VECTOR(7 downto 0);
                Memory_Address  : out STD_LOGIC_VECTOR(5 downto 0);
                Memory_Mode     : out Sram_Mode_t;
                Memory_Set      : out Set_Opt_t;
                Memory_Write    : out Write_Opt_t;
                SREG_Set        : out Set_Opt_t;
                SREG_Write      : out Write_Opt_t;
                SREG_Mask       : out Bit_Mask_t;
                PC_Address      : in STD_LOGIC_VECTOR(15 downto 0); 
                PC_Mode         : out PC_Mode_t;
                PC_Offset       : out STD_LOGIC_VECTOR(11 downto 0)
                );
    end component;

    component SRAM is
        Port (  Clock           : in STD_LOGIC;
                nReset          : in STD_LOGIC;
                Mode            : in Sram_Mode_t;
                WE              : in STD_LOGIC;
                Mask            : in Bit_Mask_t;
                Set             : in Set_Opt_t;
                Write           : in Write_Opt_t;
                Enable          : in STD_LOGIC;
                ImmediateAddr   : in STD_LOGIC_VECTOR(5 downto 0);
                X               : in STD_LOGIC_VECTOR(15 downto 0);
                Y               : in STD_LOGIC_VECTOR(15 downto 0);
                Z               : in STD_LOGIC_VECTOR(15 downto 0);
                MemoryIn        : in STD_LOGIC_VECTOR(7 downto 0);
                SREGIn          : in STD_LOGIC_VECTOR(7 downto 0);
                MemoryOut       : out STD_LOGIC_VECTOR(7 downto 0);
                SREGOut         : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

begin

    PC_i        : component PC port map (   Clock => Clock,
                                            nReset => nReset,
                                            Data => ProgData,
                                            AddressOut => ProgAddr,
                                            IR => IR,
                                            Mode => PC_Mode,
                                            Offset => PC_Offset,
                                            Z => Z,
                                            AddressIn => (others => '0')
                                            );

    PM_i        : component PM port map (   Address => ProgAddr,
                                            Data => ProgData
                                            );

    Register_i  : component RegisterFile port map ( Clock => Clock,
                                                    nReset => nReset,
                                                    WE => Register_WE,
                                                    Pair => Pair,
                                                    DstRegAddr => DstRegAddr,
                                                    RegDAddr => RegDAddr,
                                                    RegRAddr => RegRAddr,
                                                    Sel => Register_Sel,
                                                    ALU => ALUResult,
                                                    Immediate => Immediate,
                                                    Memory => Memory_Data,
                                                    RegD => RegD,
                                                    RegR => RegR,
                                                    X => X,
                                                    Y => Y,
                                                    Z => Z
                                                    );

    ALU_i       : component ALU port map (  Clock => Clock,
                                            nReset => nReset,
                                            Operation => ALU_Operation,
                                            SREGIn => SREG,
                                            Sel => ALU_Sel,
                                            T_Mask => T_Mask,
                                            Set_Mask => SREG_Mask,
                                            Set => SREG_Set,
                                            Set_E => SREG_Write,
                                            RegD => RegD,
                                            RegR => RegR,
                                            Immediate => Immediate,
                                            Result => ALUResult,
                                            SREGOut => ALUStatus
                                            );

    Ctrl_i      : component InstructionDecoder port map (   Clock => Clock,
                                                            nReset => nReset,
                                                            IR => IR,
                                                            Register_WE => Register_WE,
                                                            Register_Pair => Pair,
                                                            DstRegAddr => DstRegAddr,
                                                            RegDAddr => RegDAddr,
                                                            RegRAddr => RegRAddr,
                                                            SREG => SREG,
                                                            Immediate => Immediate,
                                                            Register_Sel => Register_Sel,
                                                            T_Mask => T_Mask,
                                                            ALU_Sel => ALU_Sel,
                                                            ALU_Operation => ALU_Operation,
                                                            PC_Mode => PC_Mode,
                                                            PC_Address => ProgAddr,
                                                            PC_Offset => PC_Offset,
                                                            SREG_Mask => SREG_Mask,
                                                            SREG_Set => SREG_Set,
                                                            SREG_Write => SREG_Write,
                                                            Memory_WE => Memory_WE,
                                                            Memory_Enable => Memory_Enable,
                                                            Memory_Mask => Memory_Mask,
                                                            Memory_Address => ImmediateAddr,
                                                            Memory_Mode => Memory_Mode,
                                                            Memory_Set => Memory_Set,
                                                            Memory_Write => Memory_Write,
                                                            Memory_Stack => Stack--
                                                            );

    SRAM_i      : component SRAM port map ( Clock => Clock,
                                            nReset => nReset,
                                            WE => Memory_WE,
                                            Mask => Memory_Mask,
                                            Mode => Memory_Mode,
                                            Enable => Memory_Enable,
                                            Set => Memory_Set,
                                            Write => Memory_Write,
                                            ImmediateAddr => ImmediateAddr,
                                            MemoryIn => RegD,
                                            SREGIn => ALUStatus,
                                            MemoryOut => Memory_Data,
                                            SREGOut => SREG,
                                            X => X,
                                            Y => Y,
                                            Z => Z
                                            );

end Core_Arch;