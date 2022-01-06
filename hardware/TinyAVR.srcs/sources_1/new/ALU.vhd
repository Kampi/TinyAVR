----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU - ALU_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.1
-- Description:         Arithmetic-Logical Unit (ALU) for the TinyAVR microprocessor.
--                      This design perform different arithmetic and logical operations (add, sub, shift, etc.)
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

entity ALU is
    Port (  RegD        : in STD_LOGIC_VECTOR(7 downto 0);              -- Register D input
            RegR        : in STD_LOGIC_VECTOR(7 downto 0);              -- Register R input
            Immediate   : in STD_LOGIC_VECTOR(7 downto 0);              -- Immediate input

            Operation   : in ALU_Op_t;                                  -- ALU operation
            Sel         : in ALU_Src_t;                                 -- Input source for the ALU
            T_Mask      : in STD_LOGIC_VECTOR(7 downto 0);              -- Input mask for the T Flag (used by BST and BLD)
            Mask        : in Bit_Mask_t;                                --
            SREGIn      : in STD_LOGIC_VECTOR(7 downto 0);              -- Status register input

            SREGOut     : out STD_LOGIC_VECTOR(7 downto 0);             -- Modified Status register output
            Result      : out STD_LOGIC_VECTOR(7 downto 0)              -- Result output
            );
end ALU;

architecture ALU_Arch of ALU is

    signal OperandA             : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');
    signal OperandB             : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    -- The formula for these signals depends on the operation
    signal T                    : STD_LOGIC                                 := '0';
    signal H                    : STD_LOGIC                                 := '0';
    signal V                    : STD_LOGIC                                 := '0';
    signal C                    : STD_LOGIC                                 := '0';
    signal R                    : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    signal ArithmeticH          : STD_LOGIC                                 := '0';
    signal ArithmeticV          : STD_LOGIC                                 := '0';
    signal ArithmeticC          : STD_LOGIC                                 := '0';
    signal ArithmeticResult     : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    signal LogicResult          : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    signal ShiftV               : STD_LOGIC                                 := '0';
    signal ShiftC               : STD_LOGIC                                 := '0';
    signal ShiftResult          : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    signal MultiplicationC      : STD_LOGIC                                 := '0';
    signal MultiplicationResult : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    signal TResult              : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');
    
    signal SREGOut_Temp         : STD_LOGIC_VECTOR(7 downto 0)              := (others => '0');

    component ALU_Arithmetic is
        Port (  A           : in  STD_LOGIC_VECTOR(7 downto 0);
                B           : in  STD_LOGIC_VECTOR(7 downto 0);
                CarryIn     : in  STD_LOGIC;
                Operation   : in  ALU_Op_t;
                H           : out STD_LOGIC;
                V           : out STD_LOGIC;
                C           : out STD_LOGIC;
                R           : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component ALU_Logic is
        Port (  Operation   : in  ALU_Op_t;
                A           : in STD_LOGIC_VECTOR(7 downto 0);
                B           : in STD_LOGIC_VECTOR(7 downto 0);
                R           : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component ALU_Shift is
        Port (  A           : in STD_LOGIC_VECTOR(7 downto 0);
                CarryIn     : in STD_LOGIC;
                Operation   : in ALU_Op_t;
                V           : out STD_LOGIC;
                C           : out STD_LOGIC;
                R           : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component ALU_Multiplication is
        Port (  A           : in STD_LOGIC_VECTOR(7 downto 0);
                B           : in STD_LOGIC_VECTOR(7 downto 0);
                Operation   : in ALU_Op_t;
                C           : out STD_LOGIC;
                R           : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

    component ALU_Status is
        Port (  R           : in STD_LOGIC_VECTOR(7 downto 0);
                H           : in STD_LOGIC;
                V           : in STD_LOGIC;
                C           : in STD_LOGIC;
                T           : in STD_LOGIC;
                SREGIn      : in STD_LOGIC_VECTOR(7 downto 0);
                Mask        : in Bit_Mask_t;
                SREGOut     : out STD_LOGIC_VECTOR(7 downto 0)
                );
    end component;

begin

    TResult(to_integer(UNSIGNED(T_Mask))) <= SREGIn(STATUS_BIT_T);
    T <= OperandA(to_integer(UNSIGNED(T_Mask)))  when (Operation = ALU_SET_T);

    -- Select the input for operand B (Register or Immediate)
    OperandA <= RegD;
    OperandB <= Immediate       when (Sel = ALU_SRC_IMMEDIATE)  else
                TResult         when (Sel = ALU_SRC_T_REG)      else
                RegR;

    -- Select the result and the flags according to the operation
    R <= ArithmeticResult       when ((Operation = ALU_OP_ADC) or (Operation = ALU_OP_ADD) or (Operation = ALU_OP_SBC) or (Operation = ALU_OP_SUB) or (Operation = ALU_OP_NEG)) else
         LogicResult            when ((Operation = ALU_OP_AND) or (Operation = ALU_OP_OR) or (Operation = ALU_OP_NOT) or (Operation = ALU_OP_XOR))                              else
         ShiftResult            when ((Operation = ALU_OP_ASR) or (Operation = ALU_OP_ROR) or (Operation = ALU_OP_SWAP))                                                        else
         MultiplicationResult   when ((Operation = ALU_OP_MUL_HIGH_U) or (Operation = ALU_OP_MUL_LOW_U))                                                                        else
         (others => '0');

    H <= ArithmeticH            when ((Operation = ALU_OP_ADC) or (Operation = ALU_OP_ADD) or (Operation = ALU_OP_SBC) or (Operation = ALU_OP_SUB) or (Operation = ALU_OP_NEG)) else
         '0';

    V <= ArithmeticV            when ((Operation = ALU_OP_ADC) or (Operation = ALU_OP_ADD) or (Operation = ALU_OP_SBC) or (Operation = ALU_OP_SUB) or (Operation = ALU_OP_NEG)) else
         ShiftV                 when ((Operation = ALU_OP_ASR) or (Operation = ALU_OP_ROR)) else
         '0';

    C <= ArithmeticC            when ((Operation = ALU_OP_ADC) or (Operation = ALU_OP_ADD) or (Operation = ALU_OP_SBC) or (Operation = ALU_OP_SUB) or (Operation = ALU_OP_NEG)) else
         ShiftC                 when ((Operation = ALU_OP_ASR) or (Operation = ALU_OP_ROR))                                                                                     else
         MultiplicationC        when ((Operation = ALU_OP_MUL_HIGH_U) or (Operation = ALU_OP_MUL_LOW_U))                                                                        else
         '1'                    when ((Operation = ALU_OP_NOT))                                                                                                                 else
         '0';

    ArithmeticINst : ALU_Arithmetic port map (  Operation   => Operation,
                                                A           => OperandA,
                                                B           => OperandB,
                                                CarryIn     => SREGIn(STATUS_BIT_C),
                                                H           => ArithmeticH,
                                                V           => ArithmeticV,
                                                C           => ArithmeticC,
                                                R           => ArithmeticResult
                                                );

    LogicInst : ALU_Logic port map (    Operation   => Operation,
                                        A           => OperandA,
                                        B           => OperandB,
                                        R           => LogicResult
                                        );

    ShiftInst : ALU_Shift port map (    Operation   => Operation,
                                        A           => OperandA,
                                        CarryIn     => SREGIn(STATUS_BIT_C),
                                        V           => ShiftV,
                                        C           => ShiftC,
                                        R           => ShiftResult
                                        );

    MultInst : ALU_Multiplication port map (    Operation   => Operation,
                                                A           => OperandA,
                                                B           => OperandB,
                                                C           => MultiplicationC,
                                                R           => MultiplicationResult
                                                );

    StatusInst : ALU_Status port map (  R           => R,
                                        H           => H,
                                        V           => V,
                                        C           => C,
                                        T           => T,
                                        SREGIn      => SREGIn,
                                        Mask        => Mask,
                                        SREGOut     => SREGOut_Temp
                                        );

    Result <= R;
    SREGOut <= SREGOut_Temp;

end ALU_Arch;