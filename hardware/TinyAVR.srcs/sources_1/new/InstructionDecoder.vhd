----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         InstructionDecoder - InstructionDecoder_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Instruction decoder for the TinyAVR microprocessor.
--                      This design is responisble for decoding the current instruction from the
--                      Instruction Register (IR).
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
use TinyAVR.Opcodes.all;
use TinyAVR.Constants.all;
use TinyAVR.Registers.all;

entity InstructionDecoder is
    Generic (   SRAM_SIZE   : INTEGER := 12                                     -- Address length of the SRAM in bit
                );
    Port (  Clock           : in STD_LOGIC;                                     -- Clock signal
            nReset          : in STD_LOGIC;                                     -- Reset (active low)

            IRQ             : in STD_LOGIC;                                     -- Interrupt request

            IR              : in STD_LOGIC_VECTOR(15 downto 0);                 -- Instruction Register

            Pair            : out STD_LOGIC;                                    -- Copy register pair (used by MOVW)

            ALU_Operation   : out ALU_Op_t;                                     -- ALU operation
            ALU_Sel         : out ALU_Src_t;                                    -- Select the data source for the ALU

            T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);                 -- Mask for T Flag (used by BST and BLD)

            Immediate       : out STD_LOGIC_VECTOR(7 downto 0);                 -- Immediate value

            Register_Source : out Reg_Source_t;                                 -- Select the data source for the register file
            DstReg_Addr     : out UNSIGNED(6 downto 0);                         -- Write destination register address
            RegD_Addr       : out UNSIGNED(6 downto 0);                         -- Register D read register address
            RegR_Addr       : out UNSIGNED(6 downto 0);                         -- Register R read register address
            Offset_Addr     : out SIGNED(1 downto 0);                           -- Address offset for indirect addressing mode
            UpdateX         : out STD_LOGIC;                                    -- Update the X Register pair with the offset address
            UpdateY         : out STD_LOGIC;                                    -- Update the Y Register pair with the offset address
            UpdateZ         : out STD_LOGIC;                                    -- Update the Z Register pair with the offset address

            Memory_Data     : inout STD_LOGIC_VECTOR(7 downto 0);               -- SRAM data bus
            Memory_WE       : out STD_LOGIC;                                    -- SRAM write enable signal
            Memory_Enable   : out STD_LOGIC;                                    -- SRAM enable signal
            Memory_Address  : out UNSIGNED((SRAM_SIZE - 1) downto 0);           -- SRAM memory address
            Memory_Source   : out Sram_Source_t;                                -- SRAM data source

            PC              : in UNSIGNED(15 downto 0);                         -- Program address from Programm Counter
            PC_Addr         : out UNSIGNED(15 downto 0);                        -- Program address for Programm Counter
            PC_Mode         : out PC_Mode_t;                                    -- Program Counter mode

            StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);                 -- Stack pointer input
            StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);                -- Stack pointer output

            SREG_Mask       : out Bit_Mask_t;                                   -- Status Register modification mask
            SREG            : in STD_LOGIC_VECTOR(7 downto 0)                   -- Status Register input
            );
end InstructionDecoder;

architecture InstructionDecoder_Arch of InstructionDecoder is

    signal ClockCycle           : INTEGER                       := 0;

    signal SecondCycle          : STD_LOGIC                     := '0';
    signal TwoWordInstruction   : STD_LOGIC                     := '0';

begin

    Decode_Proc : process(IR, nReset, ClockCycle, SREG, StackPointerIn, Memory_Data, PC)
        variable Var_DstAddr    : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable Var_RegDAddr   : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable Var_RegRAddr   : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable Var_ImData     : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable Var_SREG_Temp  : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable Var_SRAM_Temp  : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable Var_SP_Temp    : STD_LOGIC_VECTOR(15 downto 0)     := (others => '0');
        variable Var_PC_Temp    : SIGNED(15 downto 0)               := (others => '0');
    begin
        PC_Mode         <= PC_INC;                                          -- Default: Increment the Programm Counter
        SREG_Mask       <= (others => '0');                                 -- Default: Don?t mask any status bits
        ALU_Operation   <= ALU_OP_NOP;                                      -- Default: No operation by the ALU
        ALU_Sel         <= ALU_SRC_REG;                                     -- Default: Set register R as input for the ALU
        Register_Source <= "00";                                            -- Default: Set ALU output as input for the register
        Pair            <= '0';                                             -- Default: Don?t copy register pairs
        Memory_WE       <= '0';                                             -- Default: Don?t write to the memory
        Memory_Enable   <= '0';                                             -- Default: Don?t use the memory
        Memory_Address  <= (others => '0');                                 -- Default: Set memory address to SREG
        Memory_Source   <= MEM_ALU;                                         -- Default: Update the memory from the ALU
        Memory_Data     <= (others => 'Z');                                 -- Default: Don?t use the memory bus
        SecondCycle     <= '0';                                             -- Default: No second clock cycle
        Offset_Addr     <= (others => '0');                                 -- Default: No address offset
        UpdateX         <= '0';                                             -- Default: Don?t update the X Register
        UpdateY         <= '0';                                             -- Default: Don?t update the Y Register
        UpdateZ         <= '0';                                             -- Default: Don?t update the Z Register

        Var_DstAddr     := "00" & IR(8 downto 4);                           -- Default: Get the destination register address from the instruction
        Var_RegDAddr    := "00" & IR(8 downto 4);                           -- Default: Get the Register D address from the instruction
        Var_RegRAddr    := "00" & IR(9) & IR(3 downto 0);                   -- Default: Get the Register R address from the instruction
        Var_ImData      := IR(11 downto 8) & IR(3 downto 0);                -- Default: Get the immediate value from the instruction
        Var_SREG_Temp   := SREG;

        -- Take care of 4 byte instructions
        if(std_match(IR, OpCALL) or std_match(IR, OpJMP) or std_match(IR, OpLDS_Long) or std_match(IR, OpSTS_Long)) then
            TwoWordInstruction <= '1';
        else
            TwoWordInstruction <= '0';
        end if;

        -- ADC instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "ADC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpADC)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_ADC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- ADD instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "ADD"
        --  - Flag the changeable status flags
        if(std_match(IR, OpADD)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_ADD;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- ADIW instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Flag the changeable status flags
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Get the immediate value
        --  - Get the register addresses
        --  - 1. Clock: Stop the PC
        --              Set the ALU operation to "ADD"
        --  - 2. Clock: Clear the immediate value
        --              Set the ALU operation to "ADC"
        if(std_match(IR, OpADIW)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            SREG_Mask       <= STATUS_FLAG_SVNZC;
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            Var_ImData      := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(7 downto 6) & IR(3 downto 0)), Var_ImData'length));

            case IR(5 downto 4) is
                when "00" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Var_DstAddr'length));
                when "01" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Var_DstAddr'length));
                when "10" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Var_DstAddr'length));
                when "11" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Var_DstAddr'length));
                when others =>
            end case;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_ADD;
            elsif(ClockCycle = 1) then
                Var_ImData      := (others => '0');
                ALU_Operation   <= ALU_OP_ADC;
            end if;
        end if;

        -- AND instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "AND"
        --  - Flag the changeable status flags
        if(std_match(IR, OpAND)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_AND;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ANDI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "AND"
        --  - Flag the changeable status flags
        if(std_match(IR, OpANDI) or std_match(IR, OpCBR)) then
            Var_RegDAddr    := "001" & IR(7 downto 4);
            Var_DstAddr     := "001" & IR(7 downto 4);
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_AND;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ASR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "ASR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpASR)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_ASR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- BCLR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Clear the target bit in the SREG
        --  - Select the memory bus as data source for the SRAM
        --  - Set the modified SRAM as data for the SRAM
        --  - Set the memory address for the SRAM
        if(std_match(IR, OpBCLR)) then
            Memory_Enable                                           <= '1';
            Memory_WE                                               <= '1';
            Var_SREG_Temp(to_integer(UNSIGNED(IR(6 downto 4))))     := '0';
            Memory_Source                                           <= MEM_MEMORY;
            Memory_Data                                             <= Var_SREG_Temp;
            Memory_Address                                          <= to_unsigned(RegSREG, Memory_Address'length);
        end if;

        -- BLD instruction
        --  - Enable write to the SRAM
        --  - Enable the SRAM
        --  - Select the T-Flag as source
        --  - Set the ALU operation to "OR"
        --  - Set the mask for the operation
        if(std_match(IR, OpBLD)) then
            Memory_WE       <= '1';
            Memory_Enable   <= '1';
            ALU_Sel         <= ALU_SRC_T_REG;
            ALU_Operation   <= ALU_OP_OR;
            T_Mask          <= STD_LOGIC_VECTOR(resize(UNSIGNED(IR(2 downto 0)), T_Mask'length));
        end if;

        -- BRBC instruction
        --      - 1. Clock: If masked bit is cleared:
        --                  Set the PC to the current address plus the offset
        --      - 2. Clock: Run the PC
        if(std_match(IR, OpBRBC)) then
            if(ClockCycle = 0) then
                if(SREG(to_integer(UNSIGNED(IR(2 downto 0)))) = '0') then
                    PC_Mode     <= PC_SET;
                    PC_Addr     <= to_unsigned(to_integer(PC) + to_integer(SIGNED(IR(9 downto 3))), PC_Addr'length);
                    SecondCycle <= '1';
                end if;
            elsif(ClockCycle = 1) then
            end if;
        end if;

        -- BRBS instruction
        --      - 1. Clock: If masked bit is set:
        --                  Set the PC to the current address plus the offset
        --      - 2. Clock: Run the PC
        if(std_match(IR, OpBRBS)) then
            if(ClockCycle = 0) then
                if(SREG(to_integer(UNSIGNED(IR(2 downto 0)))) = '0') then
                    PC_Mode     <= PC_SET;
                    PC_Addr     <= to_unsigned(to_integer(PC) + to_integer(SIGNED(IR(9 downto 3))), PC_Addr'length);
                    SecondCycle <= '1';
                end if;
            elsif(ClockCycle = 1) then
            end if;
        end if;

        -- BREAK instruction
        if(std_match(IR, OpBREAK)) then
        end if;

        -- BSET instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the target bit in the SREG
        --  - Select the memory bus as data source for the SRAM
        --  - Set the modified SRAM as data for the SRAM
        --  - Set the memory address for the SRAM
        if(std_match(IR, OpBSET)) then
            Memory_Enable                                           <= '1';
            Memory_WE                                               <= '1';
            Var_SREG_Temp(to_integer(UNSIGNED(IR(6 downto 4))))     := '1';
            Memory_Source                                           <= MEM_MEMORY;
            Memory_Data                                             <= Var_SREG_Temp;
            Memory_Address                                          <= to_unsigned(RegSREG, Memory_Address'length);
        end if;

        -- BST instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the bit mask for the T Flag
        --  - Enable writing of the T Flag
        --  - Set the ALU operation to "SET T FLAG"
        if(std_match(IR, OpBST)) then
            Memory_Enable           <= '1';
            Memory_WE               <= '1';
            SREG_Mask(STATUS_BIT_T) <= '1';
            ALU_Operation           <= ALU_SET_T;
            T_Mask                  <= STD_LOGIC_VECTOR(resize(UNSIGNED(IR(2 downto 0)), T_Mask'length));
        end if;

        -- CALL instruction
        if(std_match(IR, OpCALL)) then
        end if;

        -- CBI instruction
        --  - Enable the SRAM
        --  - Set the memory address (the address offset is 32)
        --  - Set the source for memory reading to the SRAM
        --  - 1. Clock: Disable the PC
        --              Disable memory write
        --              Get the data from memory
        --  - 2. Clock: Enable memory write
        --              Set the bit
        --              Copy the data into the memory
        if(std_match(IR, OpCBI)) then
            Memory_Enable       <= '1';
            Memory_Address      <= UNSIGNED("0000001" & IR(7 downto 3));
            Memory_Source       <= MEM_MEMORY;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '0';
                Var_SRAM_Temp   := Memory_Data;
            elsif(ClockCycle = 1) then
                Memory_WE       <= '1';
                Var_SRAM_Temp(to_integer(UNSIGNED(IR(2 downto 0)))) := '0';
                Memory_Data     <= Var_SRAM_Temp;
            end if;
        end if;

        -- COM instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "COM"
        --  - Flag the changeable status flags
        if(std_match(IR, OpCOM)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_NOT;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- CP instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpCP)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- CPC instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpCPC)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- CPI instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpCPI)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- DEC instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the immediate value for the operation
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpDEC)) then
            Var_ImData      := x"01";
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- EICALL instruction
        if(std_match(IR, OpEICALL)) then
        end if;

        -- EIJMP instruction
        if(std_match(IR, OpEIJMP)) then
        end if;

        -- ELPM instruction
        if(std_match(IR, OpELPM)) then
        end if;

        -- EOR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "XOR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpEOR)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_XOR;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- FMUL instruction
        if(std_match(IR, OpFMUL)) then
        end if;

        -- FMULS instruction
        if(std_match(IR, OpFMULS)) then
        end if;

        -- FMULSU instruction
        if(std_match(IR, OpFMULSU)) then
        end if;

        -- ICALL instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - 1. Clock: Hold the PC
        --              Set the destination to memory
        --              Set the memory address to the current stack pointer value
        --              Store the lower half of the program counter
        --  - 2. Clock: Set the address mode for the PC to Z-Register
        --              Set the memory address to the stack pointer value reduced by one
        --              Store the upper half of the program counter
        --  - 3. Clock: Set the destination for the SRAM to stack pointer
        --              Set the stack pointer to the stack pointer reduced by two
        if(std_match(IR, OpICALL)) then
            Memory_Enable       <= '1';
            Memory_WE           <= '1';

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_Source   <= MEM_MEMORY;
                Memory_Address  <= resize(UNSIGNED(StackPointerIn) - 0, Memory_Address'length);
                Memory_Data     <= STD_LOGIC_VECTOR(PC(7 downto 0));
            elsif(ClockCycle = 1) then
                PC_Mode         <= PC_Z_REG;
                Memory_Source   <= MEM_MEMORY;
                Memory_Address  <= resize(UNSIGNED(StackPointerIn) - 1, Memory_Address'length);
                Memory_Data     <= STD_LOGIC_VECTOR(PC(15 downto 8));
            elsif(ClockCycle = 2) then
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(UNSIGNED(StackPointerIn) - 2);
            end if;
        end if;

        -- IJMP instruction
        --      - 1. Clock: Set the Z register as address source for the PC
        --      - 2. Clock: Keep the address in the PC
        if(std_match(IR, OpIJMP)) then
            if(ClockCycle = 0) then
                PC_Mode     <= PC_Z_REG;
            elsif(ClockCycle = 1) then
            end if;
        end if;

        -- IN instruction
        --  - Enable the SRAM
        --  - Disable write to the SRAM
        --  - Set the SRAM address
        --  - Save the data in the SRAM
        if(std_match(IR, OpIN)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '0';
            Memory_Address  <= resize(UNSIGNED(IR(10 downto 9) & IR(3 downto 0)), Memory_Address'length);
            Memory_Source   <= MEM_IN;
        end if;

        -- INC instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "ADD"
        --  - Flag the changeable status flags
        if(std_match(IR, OpINC)) then
            Var_ImData      := x"01";
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_ADD;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- JMP instruction
        if(std_match(IR, OpJMP)) then
        end if;

        -- LD (X) instruction
        --  - Post increment:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable update of the X Register
        --                  Set the offset for the address register pair to 1
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the X Register as address source for the SRAM
        --  - Pre decrement:
        --      - 1. Clock: Disable write to the Register file
        --                  Enable update of the X Register
        --                  Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the X Register as address source for the SRAM
        --  - No address modification:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the X Register as address source for the SRAM
        if(std_match(IR, OpLD_X_1) or std_match(IR, OpLD_X_2) or std_match(IR, OpLD_X_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpLD_X_2)) then
                    Register_Source <= SRC_MEMORY;
                    UpdateX         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_X;
                elsif(std_match(IR, OpLD_X_3)) then
                    UpdateX         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                else
                    Register_Source <= SRC_MEMORY;
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_X;
                end if;
            elsif(ClockCycle = 1) then
                Register_Source <= SRC_MEMORY;
                Memory_Enable   <= '1';
                Memory_WE       <= '0';
                Memory_Source   <= MEM_X;
            end if;
        end if;

        -- LD (Y) instruction
        --  - Post increment:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable update of the Y Register
        --                  Set the offset for the address register pair to 1
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Y Register as address source for the SRAM
        --  - Pre decrement:
        --      - 1. Clock: Disable write to the Register file
        --                  Enable update of the Y Register
        --                  Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Y Register as address source for the SRAM
        --  - No address modification:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Y Register as address source for the SRAM
        if(std_match(IR, OpLD_Y_1) or std_match(IR, OpLD_Y_2) or std_match(IR, OpLD_Y_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpLD_X_2)) then
                    Register_Source <= SRC_MEMORY;
                    UpdateY         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_Y;
                elsif(std_match(IR, OpLD_Y_3)) then
                    UpdateY         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                else
                    Register_Source <= SRC_MEMORY;
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_Y;
                end if;
            elsif(ClockCycle = 1) then
                Register_Source <= SRC_MEMORY;
                Memory_Enable   <= '1';
                Memory_WE       <= '0';
                Memory_Source   <= MEM_Y;
            end if;
        end if;

        -- LD (Z) instruction
        --  - Post increment:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable update of the Z Register
        --                  Set the offset for the address register pair to 1
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Z Register as address source for the SRAM
        --  - Pre decrement:
        --      - 1. Clock: Disable write to the Register file
        --                  Enable update of the Z Register
        --                  Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Z Register as address source for the SRAM
        --  - No address modification:
        --      - 1. Clock: Enable write to the Register file
        --                  Set the SRAM as source for the Register file
        --                  Enable the SRAM
        --                  Enable write to the SRAM
        --                  Set the Z Register as address source for the SRAM
        if(std_match(IR, OpLD_Z_1) or std_match(IR, OpLD_Z_2) or std_match(IR, OpLD_Z_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpLD_Z_2)) then
                    Register_Source <= SRC_MEMORY;
                    UpdateZ         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_Z;
                elsif(std_match(IR, OpLD_Z_3)) then
                    UpdateZ         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                else
                    Register_Source <= SRC_MEMORY;
                    Memory_Enable   <= '1';
                    Memory_WE       <= '0';
                    Memory_Source   <= MEM_Z;
                end if;
            elsif(ClockCycle = 1) then
                Register_Source <= SRC_MEMORY;
                Memory_Enable   <= '1';
                Memory_WE       <= '0';
                Memory_Source   <= MEM_Z;
            end if;
        end if;

        -- LDI instruction
        --  - Set the destination register address (the address offset is 16)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input source for the memory to "Immediate"
        if(std_match(IR, OpLDI)) then
            Var_DstAddr     := "001" & IR(7 downto 4);
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            Memory_Source   <= MEM_IMMEDIATE;
        end if;

        -- LSR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "LSR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpLSR)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_LSR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- MOV instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Use the general purpose registers as input
        if(std_match(IR, OpMOV)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            Memory_Source   <= MEM_REG;
        end if;

        -- MOVW instruction
        --  - Set the address of the source register (address has to be multiplied by 2)
        --  - Set the address of the destination register (address has to be multiplied by 2)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Use the general purpose registers as input
        --  - Enable register pair copy
        if(std_match(IR, OpMOVW)) then
            Var_RegDAddr    := "00" & IR(7 downto 4) & "0";
            Var_RegRAddr    := "00" & IR(3 downto 0) & "0";
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            Memory_Source   <= MEM_REG;
            Pair            <= '1';
        end if;

        -- MUL instruction
        --  - 1. Clock: Set the destination register to R0
        --              Hold the PC
        --              Set the ALU operation to "MUL_LOW_U"
        --  - 2. Clock: Set the destination register to R1
        --              Enable the SRAM
        --              Enable write to the SRAM
        --              Set the ALU operation to "MUL_HIGH_U"
        --              Enable the Zero-Flag and Carry-Flag to update
        if(std_match(IR, OpMUL)) then
            if(ClockCycle = 0) then
                Var_DstAddr     := (others => '0');
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_MUL_LOW_U;
            elsif(ClockCycle = 1) then
               Var_DstAddr      := ((0) => '1', others => '0');
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                ALU_Operation   <= ALU_OP_MUL_HIGH_U;
                SREG_Mask       <= STATUS_FLAG_ZC;
            end if;
        end if;

        -- MULS instruction
        --  - 1. Clock: Set the destination register to R0
        --              Hold the PC
        --              Set the ALU operation to "MUL_LOW_S"
        --              Enable the Carry-Flag to update
        --  - 2. Clock: Set the destination register to R1
        --              Enable the SRAM
        --              Enable write to the SRAM
        --              Set the ALU operation to "MUL_HIGH_S"
        --              Enable the Zero-Flag to update
        if(std_match(IR, OpMULS)) then
            Var_RegDAddr        := "001" & IR(7 downto 4);
            Var_RegRAddr        := "001" & IR(3 downto 0);
            if(ClockCycle = 0) then
                Var_DstAddr     := (others => '0');
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_MUL_LOW_S;
            elsif(ClockCycle = 1) then
                Var_DstAddr     := ((0) => '1', others => '0');
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                ALU_Operation   <= ALU_OP_MUL_HIGH_S;
                SREG_Mask       <= STATUS_FLAG_ZC;
            end if;
        end if;

        -- MULSU instruction
        if(std_match(IR, OpMULSU)) then
            Var_RegDAddr        := "001" & IR(7 downto 4);
            Var_RegRAddr        := "001" & IR(3 downto 0);
            if(ClockCycle = 0) then
                Var_DstAddr     := (others => '0');
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_MUL_LOW_SU;
            elsif(ClockCycle = 1) then
                Var_DstAddr     := ((0) => '1', others => '0');
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                ALU_Operation   <= ALU_OP_MUL_HIGH_SU;
                SREG_Mask       <= STATUS_FLAG_ZC;
            end if;
        end if;

        -- NEG instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "NEG"
        --  - Flag the changeable status flags
        if(std_match(IR, OpNEG)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_NEG;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- NOP instruction
        if(std_match(IR, OpNOP)) then
        end if;

        -- OR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "OR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpOR)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_OR;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ORI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "OR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpORI)) then
            Var_RegDAddr    := "001" & IR(7 downto 4);
            Var_DstAddr     := "001" & IR(7 downto 4);
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_OR;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- OUT instruction
        --  - Enable the SRAM
        --  - Enable write for the SRAM
        --  - Set the SRAM address
        --  - Set the register as SRAM source
        if(std_match(IR, OpOUT)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            Memory_Address  <= resize(UNSIGNED(IR(10 downto 9) & IR(3 downto 0)), Memory_Address'length);
            Memory_Source   <= MEM_OUT;
        end if;

        -- POP instruction
        --  - Enable the SRAM
        --  - 1. Clock: Hold the PC
        --              Enable write to the SRAM
        --              Set the stack pointer as input source for the SRAM
        --              Write the new stack pointer into the SRAM
        --  - 2. Clock: Set the destination register address
        --              Disable write to the SRAM
        --              Set the SRAM as data source for the register file
        --              Disable memory write
        --              Set the memory address to the current stack pointer
        if(std_match(IR, OpPOP)) then
            Memory_Enable       <= '1';

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '1';
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(UNSIGNED(StackPointerIn) + 1);
            elsif(ClockCycle = 1) then
                Var_RegDAddr    := "00" & IR(8 downto 4);
                Memory_WE       <= '0';
                Memory_Source   <= MEM_IN;
                Memory_Address  <= resize(UNSIGNED(StackPointerIn), Memory_Address'length);
            end if;
        end if;

        -- PUSH instruction
        --  - Enable the SRAM
        --  - Enable write for the SRAM
        --  - 1. Clock: Hold the PC
        --              Set the register as input source for the SRAM
        --              Set the memory address to the stack pointer
        --  - 2. Clock: Set the stack pointer as input source for the SRAM
        --              Write the new stack pointer into the SRAM
        if(std_match(IR, OpPUSH)) then
            Memory_Enable       <= '1';
            Memory_WE           <= '1';

            if(ClockCycle = 0) then
                Var_RegDAddr    := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(8 downto 4)), Var_RegDAddr'length));
                PC_Mode         <= PC_KEEP;
                Memory_Source   <= MEM_OUT;
                Memory_Address  <= resize(UNSIGNED(StackPointerIn), Memory_Address'length);
            elsif(ClockCycle = 1) then
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(UNSIGNED(StackPointerIn) - 1);
            end if;
        end if;

        -- RCALL instruction
        if(std_match(IR, OpRCALL)) then
        end if;

        -- RET instruction
        --  - Enable the SRAM
        --  - 1. Clock: Hold the PC
        --              Disable memory write
        --              Set the memory as target
        --              Set the stack pointer as destination
        --              Read the upper byte of the current stack pointer (increased by one) from the memory
        --  - 2. Clock: Hold the PC
        --              Disable memory write
        --              Set the memory as target
        --              Set the stack pointer as destination
        --              Read the lower byte of the current stack pointer (increased by two) from the memory
        --  - 3. Clock: Set the PC
        --              Set the stack pointer as destination
        --              Write the current stack pointer into the memory
        --  - 4. Clock  Return program execution
        if(std_match(IR, OpRET)) then
            Memory_Enable       <= '1';

            if(ClockCycle = 0) then
                PC_Mode                     <= PC_KEEP;
                Memory_WE                   <= '0';
                Memory_Source               <= MEM_MEMORY;
                Memory_Address              <= resize(UNSIGNED(StackPointerIn) + 1, Memory_Address'length);
                Var_SP_Temp(15 downto 8)    := Memory_Data;
            elsif(ClockCycle = 1) then
                PC_Mode                     <= PC_KEEP;
                Memory_WE                   <= '0';
                Memory_Source               <= MEM_MEMORY;
                Memory_Address              <= resize(UNSIGNED(StackPointerIn) + 2, Memory_Address'length);
                Var_SP_Temp(7 downto 0)     := Memory_Data;
            elsif(ClockCycle = 2) then
                PC_Mode                     <= PC_SET;
                PC_Addr                     <= UNSIGNED(Var_SP_Temp);
                Memory_WE                   <= '1';
                Memory_Source               <= MEM_SP;
                StackPointerOut             <= STD_LOGIC_VECTOR(UNSIGNED(StackPointerIn) + 2);
            elsif(ClockCycle = 3) then
            end if;
        end if;

        -- RJMP instruction
        --  - 1. Clock: Disable the PC
        --              Load the address from the Instruction Register
        --  - 2. Clock: Resume
        if(std_match(IR, OpRJMP)) then
            if(ClockCycle = 0) then
                Var_PC_Temp := SIGNED(PC) + SIGNED(IR(11 downto 0));
                PC_Mode     <= PC_SET;
                PC_Addr     <= UNSIGNED(Var_PC_Temp);
            elsif(ClockCycle = 1) then
            end if;
        end if;

        -- ROR instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "ROR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpROR)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_ROR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- SBC instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSBC)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SBCI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSBCI)) then
            Var_RegDAddr    := "001" & IR(7 downto 4);
            Var_DstAddr     := "001" & IR(7 downto 4);
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SBI instruction
        --  - Enable the SRAM
        --  - Set the memory address (the address offset is 32)
        --  - Set the source for memory reading to the SRAM
        --  - 1. Clock: Disable the PC
        --              Disable memory write
        --              Get the data from memory
        --  - 2. Clock: Enable memory write
        --              Set the bit
        --              Copy the data into the memory
        if(std_match(IR, OpSBI)) then
            Memory_Enable       <= '1';
            Memory_Address      <= UNSIGNED("0000001" & IR(7 downto 3));
            Memory_Source       <= MEM_MEMORY;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '0';
                Var_SRAM_Temp   := Memory_Data;
            elsif(ClockCycle = 1) then
                Memory_WE       <= '1';
                Var_SRAM_Temp(to_integer(UNSIGNED(IR(2 downto 0)))) := '1';
                Memory_Data     <= Var_SRAM_Temp;
            end if;
        end if;

        -- SBIW instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Flag the changeable status flags
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Get the register addresses
        --  - 1. Clock: Stop the PC
        --              Set the ALU operation to "SUB"
        --  - 2. Clock: Clear the immediate value
        --              Set the ALU operation to "SBC"
        if(std_match(IR, OpSBIW)) then
            Var_ImData          := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(7 downto 6) & IR(3 downto 0)), Var_ImData'length));
            Memory_Enable       <= '1';
            Memory_WE           <= '1';
            SREG_Mask           <= STATUS_FLAG_SVNZC;
            ALU_Sel             <= ALU_SRC_IMMEDIATE;

            case IR(5 downto 4) is
                when "00" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Var_DstAddr'length));
                when "01" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Var_DstAddr'length));
                when "10" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Var_DstAddr'length));
                when "11" =>
                    Var_RegDAddr    := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Var_RegDAddr'length));
                    Var_DstAddr     := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Var_DstAddr'length));
                when others =>
            end case;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_SUB;
            elsif(ClockCycle = 1) then
                ALU_Operation   <= ALU_OP_SBC;
                Var_ImData      := (others => '0');
            end if;
        end if;

        -- SLEEP instruction
        if(std_match(IR, OpSLEEP)) then
        end if;

        -- ST (X) instruction
        --  - Post increment:
        --      - Enable update of the X Register
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the X Register
        --  - Pre decrement:
        --      - Enable update of the X Register
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the X Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the X Register
        if(std_match(IR, OpST_X_1) or std_match(IR, OpST_X_2) or std_match(IR, OpST_X_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpST_X_2)) then
                    UpdateX         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_X;
                elsif(std_match(IR, OpST_X_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateX         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_X;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable       <= '1';
                Memory_WE           <= '1';
                Memory_Source       <= MEM_X;
            end if;
        end if;

        -- ST (Y) instruction
        --  - Post increment:
        --      - Enable update of the Y Register
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Y Register
        --  - Pre decrement:
        --      - Enable update of the Y Register
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the Y Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Y Register
        if(std_match(IR, OpST_Y_1) or std_match(IR, OpST_Y_2) or std_match(IR, OpST_Y_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpST_Y_2)) then
                    UpdateY         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Y;
                elsif(std_match(IR, OpST_Y_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateY         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Y;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable       <= '1';
                Memory_WE           <= '1';
                Memory_Source       <= MEM_Y;
            end if;
        end if;

        -- ST (Z) instruction
        --  - Post increment:
        --      - Enable update of the Z Register
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Z Register
        --  - Pre decrement:
        --      - Enable update of the Z Register
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the Z Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Z Register
        if(std_match(IR, OpST_Z_1) or std_match(IR, OpST_Z_2) or std_match(IR, OpST_Z_3)) then
            if(ClockCycle = 0) then
                if(std_match(IR, OpST_Z_2)) then
                    UpdateZ         <= '1';
                    Offset_Addr     <= to_signed(1, Offset_Addr'length);
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Z;
                elsif(std_match(IR, OpST_Z_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateZ         <= '1';
                    Offset_Addr     <= to_signed(-1, Offset_Addr'length);
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Z;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable       <= '1';
                Memory_WE           <= '1';
                Memory_Source       <= MEM_Z;
            end if;
        end if;

        -- STS instruction
        if(std_match(IR, OpSTS)) then
        end if;

        -- SUB instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSUB)) then
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SUBI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSUBI)) then
            Var_RegDAddr    := "001" & IR(7 downto 4);
            Var_DstAddr     := "001" & IR(7 downto 4);
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SWAP instruction
        if(std_match(IR, OpSWAP)) then
            ALU_Operation   <= ALU_OP_SWAP;
        end if;

        -- WDR instruction
        if(std_match(IR, OpWDR)) then
        end if;

        -- XCH instruction
        if(std_match(IR, OpXCH)) then
        end if;

        DstReg_Addr <= UNSIGNED(Var_DstAddr);
        RegD_Addr   <= UNSIGNED(Var_RegDAddr);
        RegR_Addr   <= UNSIGNED(Var_RegRAddr);
        Immediate   <= Var_ImData;
    end process;

    UpdateClockCycle : process
    begin
        wait until rising_edge(Clock);

        ClockCycle <= 0;

        if((ClockCycle = 0) and (std_match(IR, OpMUL) or std_match(IR, OpMULS) or std_match(IR, OpMULSU) or std_match(IR, OpADIW) or
                                 std_match(IR, OpSBIW) or std_match(IR, OpSTS) or std_match(IR, OpJMP) or std_match(IR, OpRJMP) or
                                 std_match(IR, OpIJMP) or std_match(IR, OpRCALL) or std_match(IR, OpICALL) or std_match(IR, OpPOP) or
                                 std_match(IR, OpPUSH) or std_match(IR, OpRET) or std_match(IR, OpSBI) or std_match(IR, OpCBI) or
                                 (SecondCycle = '1')
                                 )) then
            ClockCycle <= 1;
        elsif((ClockCycle = 1) and (std_match(IR, OpRCALL) or std_match(IR, OpICALL) or std_match(IR, OpRET) or
                                    (TwoWordInstruction = '1')
                                    )) then
            ClockCycle <= 2;
        elsif((ClockCycle = 2) and (std_match(IR, OpRET))) then
            ClockCycle <= 3;
        end if;

        if(nReset = '0') then
            ClockCycle <= 0;
        end if;
    end process;
end InstructionDecoder_Arch;