----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         InstructionDecoder - InstructionDecoder_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.1
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
use TinyAVR.Constants.all;
use TinyAVR.Opcodes.all;

entity InstructionDecoder is
    Port (  Clock           : in STD_LOGIC;                                 -- Clock signal
            nReset          : in STD_LOGIC;                                 -- Reset (active low)
            SREG            : in STD_LOGIC_VECTOR(7 downto 0);              -- Status Register input
            IR              : in STD_LOGIC_VECTOR(15 downto 0);             -- Instruction Register

            ALU_Operation   : out ALU_Op_t;                                 -- ALU operation
            ALU_Sel         : out ALU_Src_t;                                -- Select the data source for the ALU
            
            T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);             -- Mask for T Flag (used by BST and BLD)

            Register_Sel    : out Sel_t;                                    -- Select the data source for the register file
            DstRegAddr      : out STD_LOGIC_VECTOR(6 downto 0);             -- Write destination register address
            RegDAddr        : out STD_LOGIC_VECTOR(6 downto 0);             -- Register D read register address
            RegRAddr        : out STD_LOGIC_VECTOR(6 downto 0);             -- Register R read register address
            Immediate       : out STD_LOGIC_VECTOR(7 downto 0);             -- Immediate value
            Register_WE     : out STD_LOGIC;                                -- Register file write enable signal
            Register_Pair   : out STD_LOGIC;                                -- Copy register pair (used by MOVW) 

            Memory_WE       : out STD_LOGIC;                                -- SRAM write enable signal
            Memory_Enable   : out STD_LOGIC;                                -- SRAM enable signal
            Memory_Stack    : out STD_LOGIC_VECTOR(7 downto 0);             -- Stack data for the SRAM
            Memory_Mask     : out STD_LOGIC_VECTOR(7 downto 0);             -- Bit mask for the SRAM (used by CBI and SBI)
            Memory_Address  : out STD_LOGIC_VECTOR(5 downto 0);             -- SRAM memory address
            Memory_Mode     : out Sram_Mode_t;                              -- SRAM operation mode
            Memory_Set      : out Set_Opt_t;                                -- Memory set / clear option (used by CBI and SBI)
            Memory_Write    : out Write_Opt_t;                              -- Enable write of individual bits in the memory (used by CBI and SBI)

            PC_Address      : in STD_LOGIC_VECTOR(15 downto 0);             -- Program address from programm counter
            PC_Mode         : out PC_Mode_t;                                -- Program counter mode
            PC_Offset       : out STD_LOGIC_VECTOR(11 downto 0);            -- Address offset for the Programm Counter

            SREG_Write      : out Write_Opt_t;                              -- Enable write of individual bits in the Status Register (used by BSET and BCLR)
            SREG_Set        : out Set_Opt_t;                                -- Status Register set / clear option (used by BSET and BCLR)
            SREG_Mask       : out Bit_Mask_t                                -- Status Register modification mask (used by BSET and BCLR)
            );
end InstructionDecoder;

architecture InstructionDecoder of InstructionDecoder is

    signal ClockCycle       : INTEGER                           := 0;

begin

    DecodeInstruction: process(IR, nReset, ClockCycle)
        variable Dst            : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable RegD           : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable RegR           : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable ImData         : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable ReturnAddress  : STD_LOGIC_VECTOR(15 downto 0)     := (others => '0');
    begin
        PC_Mode         <= PC_INC;                                          -- Default: Increment the Programm Counter
        PC_Offset       <= STD_LOGIC_VECTOR(TO_SIGNED(1, PC_Offset'length));-- Default: Step size is 1
        SREG_Mask       <= (others => '0');                                 -- Default: Don´t mask any status bits
        SREG_Set        <= OPT_SET;                                         -- Default: Set the bits in the SREG
        SREG_Write      <= OPT_LOCK;                                        -- Default: Don´t write individual bits in the SREG
        ALU_Operation   <= ALU_OP_NOP;                                      -- Default: No operation by the ALU
        ALU_Sel         <= ALU_SRC_REG;                                     -- Default: Set register R as input for the ALU
        Register_Sel    <= SRC_ALU;                                         -- Default: Set ALU output as input for the register file
        Register_WE     <= '1';                                             -- Default: Write to the register file
        Register_Pair   <= '0';                                             -- Default: Don´t copy register pairs
        Memory_WE       <= '0';                                             -- Default: Don´t write to the memory
        Memory_Enable   <= '0';                                             -- Default: Don´t use the memory
        Memory_Address  <= (others => '0');                                 -- Default: Set memory address to zero
        Memory_Mask     <= (others => '0');                                 -- Default: Don´t mask any memory bits
        Memory_Mode     <= MEM_UPDATE_SREG;                                 -- Default: Update the SREG
        Memory_Write    <= OPT_LOCK;                                        -- Default: Don´t write individual bits
        Memory_Set      <= OPT_SET;                                         -- Default: Set the bits in the memory

        Dst             := "00" & IR(8 downto 4);                           -- Default: Get the destination register address from the instruction
        RegD            := "00" & IR(8 downto 4);                           -- Default: Get the Register D address from the instruction
        RegR            := "00" & IR(9) & IR(3 downto 0);                   -- Default: Get the Register R address from the instruction
        ImData          := IR(11 downto 8) & IR(3 downto 0);                -- Default: Get the immediate value from the instruction

        -- ADC instruction
        --  - Set the ALU operation to "ADC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpADC)) then
            ALU_Operation   <= ALU_OP_ADC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- ADD instruction
        --  - Set the ALU operation to "ADD"
        --  - Flag the changeable status flags
        if(std_match(IR, OpADD)) then
            ALU_Operation   <= ALU_OP_ADD;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- ADIW instruction
        --  - Flag the changeable status flags
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Get the immediate value
        --  - Get the register addresses
        --  - 1. Clock: Stop the PC
        --              Set the ALU operation to "ADD"
        --  - 2. Clock: Clear the immediate value
        --              Set the ALU operation to "ADC"
        if(std_match(IR, OpADIW)) then
            SREG_Mask       <= STATUS_FLAG_SVNZC;
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ImData          := "00" & IR(7 downto 6) & IR(3 downto 0);

            -- Select the register pair
            case IR(5 downto 4) is
                when "00" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Dst'length));

                when "01" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Dst'length));

                when "10" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Dst'length));

                when "11" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Dst'length));

                when others =>

            end case;

            -- Add the data byte
            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_ADD;
            end if;

            -- Add the carry
            if(ClockCycle = 1) then
                ImData          := (others => '0');
                ALU_Operation   <= ALU_OP_ADC;
            end if;
        end if;

        -- AND instruction
        --  - Set the ALU operation to "AND"
        --  - Flag the changeable status flags
        if(std_match(IR, OpAND)) then
            ALU_Operation   <= ALU_OP_AND;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ANDI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "AND"
        --  - Flag the changeable status flags
        if(std_match(IR, OpANDI) or std_match(IR, OpCBR)) then
            RegD            := "001" & IR(7 downto 4);
            Dst             := "001" & IR(7 downto 4);
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_AND;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ASR instruction
        --  - Set the ALU operation to "ASR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpASR)) then
            ALU_Operation   <= ALU_OP_ASR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- BCLR instruction
        --  - Flag the changeable status flags
        --  - Set the write direction to 'CLEAR'
        --  - Enable write for individual bits in the status register
        --  - Disable write for the register file
        if(std_match(IR, OpBCLR)) then
            SREG_Mask(to_integer(UNSIGNED(IR(6 downto 4)))) <= '1';
            SREG_Set        <= OPT_CLEAR;
            SREG_Write      <= OPT_WRITE;
            Register_WE     <= '0';
        end if;

        -- BLD instruction
        if(std_match(IR, OpBLD)) then
            ALU_Sel         <= ALU_SRC_T_REG;
            ALU_Operation   <= ALU_OP_OR;
            T_Mask          <= "00000" & IR(2 downto 0);
        end if;

        -- BRBC instruction
        if(std_match(IR, OpBRBC)) then
        end if;

        -- BRBS instruction
        if(std_match(IR, OpBRBS)) then
        end if;

        -- BREAK instruction
        if(std_match(IR, OpBREAK)) then
        end if;

        -- BSET instruction
        --  - Flag the changeable status flags
        --  - Set the write direction to 'SET'
        --  - Enable write for individual bits in the status register
        --  - Disable write for the register file
        if(std_match(IR, OpBSET)) then
            SREG_Mask(to_integer(UNSIGNED(IR(6 downto 4)))) <= '1';
            SREG_Set        <= OPT_SET;
            SREG_Write      <= OPT_WRITE;
            Register_WE     <= '0';
        end if;

        -- BST instruction
        --  - Disable write for the register file
        --  - Set the destination register address 
        --  - Set the bit mask for the T Flag
        --  - Enable writing of the T Flag
        --  - Set the ALU operation to "SET T FLAG"
        if(std_match(IR, OpBST)) then
            Register_WE             <= '0';
            T_Mask                  <= "00000" & IR(2 downto 0);
            SREG_Mask(STATUS_BIT_T) <= '1';
            ALU_Operation           <= ALU_SET_T;
        end if;

        -- CALL instruction
        if(std_match(IR, OpCALL)) then
        end if;

        -- CBI instruction
        --  - Enable write for the SRAM
        --  - Enable the SRAM
        --  - Set the SRAM address
        --  - Set the bit mask for the bit manipulation
        --  - Configure the bit manipulation to "SET"
        --  - Enable bit manipulation
        --  - Save the data in the SRAM region
        if(std_match(IR, OpCBI)) then
            Memory_WE       <= '1';
            Memory_Enable   <= '1';
            Memory_Address  <= "0" & IR(7 downto 3);
            Memory_Mask(to_integer(UNSIGNED(IR(2 downto 0)))) <= '1';
            Memory_Set      <= OPT_CLEAR;
            Memory_Write    <= OPT_WRITE;
            Memory_Mode     <= MEM_MEMORY;
        end if;

        -- COM instruction
        --  - Set the ALU operation to "COM"
        --  - Flag the changeable status flags
        if(std_match(IR, OpCOM)) then
            ALU_Operation   <= ALU_OP_NOT;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- CP instruction
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        --  - Disable write for the register file
        if(std_match(IR, OpCP)) then
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
            Register_WE     <= '0';
        end if;

        -- CPC instruction
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        --  - Disable write for the register file
        if(std_match(IR, OpCPC)) then
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
            Register_WE     <= '0';
        end if;

        -- CPI instruction
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        --  - Disable write for the register file
        if(std_match(IR, OpCPI)) then
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
            Register_WE     <= '0';
        end if;

        -- DEC instruction
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the immediate value for the operation
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpDEC)) then
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ImData          := x"01";
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
        --  - Set the ALU operation to "XOR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpEOR)) then
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
        if(std_match(IR, OpICALL)) then
        end if;

        -- IJMP instruction
        --  - Disable write for the register file
        --  - 1. Clock: Set the Z register as address source for the PC
        --  - 2. Clock: Keep the address in the PC
        if(std_match(IR, OpIJMP)) then
            Register_WE     <= '0';

            if(ClockCycle = 0) then
                PC_Mode     <= PC_Z_REG;
            elsif(ClockCycle = 1) then
                PC_Mode     <= PC_INC;
            end if;
        end if;

        -- IN instruction
        --  - Set the memory as data source for the register file
        --  - Enable the SRAM
        --  - Set the SRAM address
        --  - Save the data in the SRAM region
        if(std_match(IR, OpIN)) then
            Register_Sel    <= SRC_MEMORY; 
            Memory_Enable   <= '1';
            Memory_Address  <= IR(10 downto 9) & IR(3 downto 0);
            Memory_Mode     <= MEM_MEMORY;
        end if;

        -- INC instruction
        --  - Set the immediate value for the operation
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "ADD"
        --  - Flag the changeable status flags
        if(std_match(IR, OpINC)) then
            ImData          := x"01";
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_ADD;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- JMP instruction
        if(std_match(IR, OpJMP)) then
        end if;

        -- LDI instruction
        --  - Set the destination register address (the address offset is 16)
        --  - Set the input source for the register file to "Immediate"
        --  - Set the immediate value
        if(std_match(IR, OpLDI)) then
            Dst             := "001" & IR(7 downto 4);
            Register_Sel    <= SRC_IMMEDIATE;
        end if;

        -- MOV instruction
        --  - Set the input source for the register file to "Register"
        if(std_match(IR, OpMOV)) then
            Register_Sel    <= SRC_REGISTER;
        end if;

        -- MOVW instruction
        --  - Set the input source for the register file to "Register"
        --  - Set the address of the source register (address has to be multiplied by 2)
        --  - Set the address of the destination register (address has to be multiplied by 2)
        if(std_match(IR, OpMOVW)) then
            Register_Sel    <= SRC_REGISTER;
            RegR            := "00" & IR(3 downto 0) & "0";
            Dst             := "00" & IR(7 downto 4) & "0";
            Register_Pair   <= '1';
        end if;

        -- MUL instruction
        if(std_match(IR, OpMUL)) then
        end if;

        -- MULS instruction
        if(std_match(IR, OpMULS)) then
        end if;

        -- MULSU instruction
        if(std_match(IR, OpMULSU)) then
        end if;

        -- NEG instruction
        if(std_match(IR, OpNEG)) then
            ALU_Operation   <= ALU_OP_NEG;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- NOP instruction
        if(std_match(IR, OpNOP)) then
        end if;

        -- OR instruction
        --  - Set the ALU operation to "OR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpOR)) then
            ALU_Operation   <= ALU_OP_OR;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- ORI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "OR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpORI)) then
            RegD            := "001" & IR(7 downto 4);
            Dst             := "001" & IR(7 downto 4);
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_OR;
            SREG_Mask       <= STATUS_FLAG_SVNZ;
        end if;

        -- OUT instruction
        --  - Disable write for the register file
        --  - Enable write for the SRAM
        --  - Enable the SRAM
        --  - Set the SRAM address
        --  - Save the data in the SRAM region
        if(std_match(IR, OpOUT)) then
            Register_WE     <= '0';
            Memory_WE       <= '1';
            Memory_Enable   <= '1';
            Memory_Address  <= IR(10 downto 9) & IR(3 downto 0);
            Memory_Mode     <= MEM_MEMORY;
        end if;

        -- POP instruction
        --  - Set the stack pointer to decrement
        --  - Enable the SRAM
        --  - Enable read from the SRAM
        --  - Set the input mode for the SRAM to STACK
        --  - Disable the program counter
        if(std_match(IR, OpPOP)) then
            if(ClockCycle = 0) then
                Memory_Enable   <= '1';
                Memory_WE       <= '0';
                Memory_Mode     <= MEM_STACK;
                PC_Mode         <= PC_KEEP;
            elsif(ClockCycle = 1) then
                Register_Sel    <= SRC_MEMORY;
                Register_WE     <= '1';
                RegD            := "00" & IR(8 downto 4);
            end if;
        end if;

        -- PUSH instruction
        --  - Disable write for the register file
        --  - Set the output register of the register file
        --  - Disable the program counter
        --  - Set the stack pointer to decrement
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the input mode for the SRAM to STACK
        if(std_match(IR, OpPUSH)) then
            Register_WE     <= '0';

            if(ClockCycle = 0) then
                RegD            := "00" & IR(8 downto 4);
                PC_Mode         <= PC_KEEP;
            elsif(ClockCycle = 1) then
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Mode     <= MEM_STACK;
            end if;
        end if;

        -- RCALL instruction
        if(std_match(IR, OpRCALL)) then
        end if;

        -- RJMP instruction
        --  - Disable write for the register file
        --  - 1. Clock: Disable the PC
        --              Load the address from the Instruction Register
        --  - 2. Clock: Resume
        if(std_match(IR, OpRJMP)) then
            Register_WE     <= '0';

            if(ClockCycle = 0) then
                PC_Offset <= IR(11 downto 0);
            elsif(ClockCycle = 1) then
            end if;
        end if;

        -- ROR instruction
        --  - Set the ALU operation to "ROR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpROR)) then
            ALU_Operation   <= ALU_OP_ROR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- SBC instruction
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSBC)) then
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SBCC instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Set the ALU operation to "SBC"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSBCI)) then
            RegD            := "001" & IR(7 downto 4);
            Dst             := "001" & IR(7 downto 4);
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ALU_Operation   <= ALU_OP_SBC;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SBI instruction
        --  - Enable write for the SRAM
        --  - Enable the SRAM
        --  - Set the SRAM address
        --  - Set the bit mask for the bit manipulation
        --  - Configure the bit manipulation to "SET"
        --  - Enable bit manipulation
        --  - Save the data in the SRAM region
        if(std_match(IR, OpSBI)) then
            Memory_WE       <= '1';
            Memory_Enable   <= '1';
            Memory_Address  <= "0" & IR(7 downto 3);
            Memory_Mask(to_integer(UNSIGNED(IR(2 downto 0)))) <= '1';
            Memory_Set      <= OPT_SET;
            Memory_Write    <= OPT_WRITE;
            Memory_Mode     <= MEM_MEMORY;
        end if;

        -- SBIW instruction
        --  - Flag the changeable status flags
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Get the immediate value
        --  - Get the register addresses
        --  - 1. Clock: Stop the PC
        --              Set the ALU operation to "SUB"
        --  - 2. Clock: Clear the immediate value
        --              Set the ALU operation to "SBC"
        if(std_match(IR, OpSBIW)) then
            SREG_Mask       <= STATUS_FLAG_SVNZC;
            ALU_Sel         <= ALU_SRC_IMMEDIATE;
            ImData          := "00" & IR(7 downto 6) & IR(3 downto 0);

            -- Select the register pair
            case IR(5 downto 4) is
                when "00" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Dst'length));

                when "01" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Dst'length));

                when "10" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Dst'length));

                when "11" =>
                    RegD := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, RegD'length));
                    Dst := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Dst'length));

                when others =>

            end case;

            -- Add the data byte
            if(ClockCycle = 0) then
                ALU_Operation   <= ALU_OP_SUB;
                PC_Mode         <= PC_KEEP;
                PC_Offset       <= STD_LOGIC_VECTOR(to_signed(0, 12));
            end if;

            -- Add the carry
            if(ClockCycle = 1) then 
                ALU_Operation   <= ALU_OP_SBC;
                ImData          := (others => '0');
            end if;
        end if;

        -- SLEEP instruction
        if(std_match(IR, OpSLEEP)) then
        end if;

        -- STS instruction
        if(std_match(IR, OpSTS)) then
        
--            if(ClockCycle = 0) then
--                LoadNewInst <= '0';
--                PCOffset <= std_logic_vector(to_signed(0, 12));
--                -- No action (waiting for m)
--            end if;
--            if CycleCount = "01" then
--                newIns   <= '0';
--                -- No action (m is output automatically, outside this process)
--            end if;
--            if CycleCount = "10" then
--                -- Keep everything the same (data comes in / goes out)
--                if ProgDBM = '1' then
--                    OutRd  <= IR(9);        -- Read
--                    OutWr  <= not IR(9);    -- Write
--                end if;
                
--                if (IR(9) = '0') or (ProgDBM = '0') then -- (LOAD or Register store)
--                    EnableIn  <= '1'; -- input into registers
--                end if;
--            end if;
        end if;

        -- SUB instruction
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSUB)) then
            ALU_Operation   <= ALU_OP_SUB;
            SREG_Mask       <= STATUS_FLAG_HSVNZC;
        end if;

        -- SUBI instruction
        --  - Set the input register address (the address offset is 16)
        --  - Set the destination register address (the address offset is 16)
        --  - Set the input for the ALU to "IMMEDIATE"
        --  - Set the ALU operation to "SUB"
        --  - Flag the changeable status flags
        if(std_match(IR, OpSUBI)) then
            RegD            := "001" & IR(7 downto 4);
            Dst             := "001" & IR(7 downto 4);
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

        DstRegAddr <= Dst;
        RegDAddr <= RegD;
        RegRAddr <= RegR;
        Immediate <= ImData;

    end process;

    -- Keep track of the cycles for each instruction
    UpdateClockCycle : process
    begin
        wait until rising_edge(Clock);

        ClockCycle <= 0;

        -- Increase the cycle counter according to the current instruction
        if((ClockCycle = 0) and (std_match(IR, OpMUL) or std_match(IR, OpADIW) or std_match(IR, OpSBIW) or std_match(IR, OpSTS) or 
                                 std_match(IR, OpJMP) or std_match(IR, OpRJMP) or std_match(IR, OpIJMP) or 
                                 std_match(IR, OpRCALL) or std_match(IR, OpPOP) or std_match(IR, OpPUSH)
                                 )) then
            ClockCycle <= 1;
        elsif((ClockCycle = 1) and (std_match(IR, OpRCALL))) then
            ClockCycle <= 2;
        elsif((ClockCycle = 2) and (std_match(IR, OpCALL))) then
            ClockCycle <= 23;
        end if;

        -- These instructions need two clock cycles
--        if((Cycles = "00") and (std_match(IR, OpMUL) or std_match(IR, OpADIW) or std_match(IR, OpSBIW) or std_match(IR, OpLDX)  or std_match(IR, OpLDXI) or std_match(IR, OpLDXD) or
--                                std_match(IR, OpLDYI) or std_match(IR, OpLDYD) or std_match(IR, OpLDDY) or std_match(IR, OpLDZI) or std_match(IR, OpLDZD) or std_match(IR, OpLDDZ) or
--                                       std_match(IR, OpSTX)  or std_match(IR, OpSTXI) or std_match(IR, OpSTXD) or
--                                       std_match(IR, OpSTYI) or std_match(IR, OpSTYD) or std_match(IR, OpSTDY) or
--                                       std_match(IR, OpSTZI) or std_match(IR, OpSTZD) or std_match(IR, OpSTDZ) or
--                                       std_match(IR, OpPOP)  or std_match(IR, OpPUSH) or
--                                       std_match(IR, OpLDS)  or std_match(IR, OpSTS)  or
--                                       std_match(IR, OpJMP)  or std_match(IR, OpRJMP) or std_match(IR, OpIJMP) or
--                                       std_match(IR, OpCALL) or std_match(IR, OpRCALL) or std_match(IR, OpICALL) or
--                                       std_match(IR, OpRET)  or std_match(IR, OpRETI)) then
--                -- update if in first clock of two clock instruction
--                CycleCount <= "01";
--            end if;
--            if CycleCount = "01" and ( std_match(IR, OpLDS) or std_match(IR, OpSTS)  or
--                                       std_match(IR, OpJMP) or std_match(IR, OpCALL) or
--                                       std_match(IR, OpRCALL) or std_match(IR, OpICALL) or
--                                       std_match(IR, OpRET) or std_match(IR, OpRETI) or
--                                       (SkipCondition = '1' and TwoWordInstr = '1') ) then
--                -- update if in second clock of three clock instruction
--                CycleCount <= "10";
--            end if;
--            if CycleCount = "10" and ( std_match(IR, OpCALL) or std_match(IR, OpRET) or std_match(IR, OpRETI) ) then
--                -- update if in third clock of four clock instruction
--                CycleCount <= "11";
--        end if;
    end process;
end InstructionDecoder;