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

            IR              : in STD_LOGIC_VECTOR(15 downto 0);             -- Instruction Register

            ALU_Operation   : out ALU_Op_t;                                 -- ALU operation
            ALU_Sel         : out ALU_Src_t;                                -- Select the data source for the ALU

            T_Mask          : out STD_LOGIC_VECTOR(7 downto 0);             -- Mask for T Flag (used by BST and BLD)

            Register_Source : out Reg_Source_t;                             -- Select the data source for the register file
            DstRegAddr      : out STD_LOGIC_VECTOR(6 downto 0);             -- Write destination register address
            RegDAddr        : out STD_LOGIC_VECTOR(6 downto 0);             -- Register D read register address
            RegRAddr        : out STD_LOGIC_VECTOR(6 downto 0);             -- Register R read register address
            Immediate       : out STD_LOGIC_VECTOR(7 downto 0);             -- Immediate value
            Register_WE     : out STD_LOGIC;                                -- Register file write enable signal
            Register_Pair   : out STD_LOGIC;                                -- Copy register pair (used by MOVW)
            Offset_Addr     : out SIGNED(1 downto 0);                       -- Address offset for indirect addressing mode
            UpdateX         : out STD_LOGIC;                                -- Update the X Register pair with the offset address
            UpdateY         : out STD_LOGIC;                                -- Update the Y Register pair with the offset address
            UpdateZ         : out STD_LOGIC;                                -- Update the Z Register pair with the offset address

            Memory_Data     : inout STD_LOGIC_VECTOR(7 downto 0);           -- SRAM data bus
            Memory_WE       : out STD_LOGIC;                                -- SRAM write enable signal
            Memory_Enable   : out STD_LOGIC;                                -- SRAM enable signal
            Memory_Address  : out STD_LOGIC_VECTOR(7 downto 0);             -- SRAM memory address
            Memory_Source   : out Sram_Source_t;                            -- SRAM data source

            PC              : in UNSIGNED(15 downto 0);                     -- Program address from Programm Counter
            PC_Addr         : out UNSIGNED(15 downto 0);                    -- Program address for Programm Counter
            PC_Mode         : out PC_Mode_t;                                -- Program Counter mode
            PC_Offset       : out SIGNED(11 downto 0);                      -- Address offset for the Programm Counter

            StackPointerIn  : in STD_LOGIC_VECTOR(15 downto 0);             -- Stack pointer input
            StackPointerOut : out STD_LOGIC_VECTOR(15 downto 0);            -- Stack pointer output

            SREG_Mask       : out Bit_Mask_t;                               -- Status Register modification mask
            SREG            : in STD_LOGIC_VECTOR(7 downto 0)               -- Status Register input
            );
end InstructionDecoder;

architecture InstructionDecoder_Arch of InstructionDecoder is

    signal ClockCycle           : INTEGER                       := 0;

    signal SecondCycle          : STD_LOGIC                     := '0';
    signal TwoWordInstruction   : STD_LOGIC                     := '0';

begin

    DecodeInstruction: process(IR, nReset, ClockCycle, SREG, StackPointerIn, Memory_Data, PC)
        variable Dst            : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable RegD           : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable RegR           : STD_LOGIC_VECTOR(6 downto 0)      := (others => '0');
        variable ImData         : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable SREG_Temp      : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable SRAM_Temp      : STD_LOGIC_VECTOR(7 downto 0)      := (others => '0');
        variable SP_Temp        : STD_LOGIC_VECTOR(15 downto 0)     := (others => '0');
    begin
        PC_Mode         <= PC_INC;                                          -- Default: Increment the Programm Counter
        PC_Offset       <= to_signed(1, PC_Offset'length);                  -- Default: Step size is 1
        SREG_Mask       <= (others => '0');                                 -- Default: Don´t mask any status bits
        ALU_Operation   <= ALU_OP_NOP;                                      -- Default: No operation by the ALU
        ALU_Sel         <= ALU_SRC_REG;                                     -- Default: Set register R as input for the ALU
        Register_Source <= SRC_ALU;                                         -- Default: Set ALU output as input for the register file
        Register_WE     <= '1';                                             -- Default: Write to the register file
        Register_Pair   <= '0';                                             -- Default: Don´t copy register pairs
        Memory_WE       <= '0';                                             -- Default: Don´t write to the memory
        Memory_Enable   <= '0';                                             -- Default: Don´t use the memory
        Memory_Address  <= (others => '0');                                 -- Default: Set memory address to SREG
        Memory_Source   <= MEM_SREG;                                        -- Default: Update the SREG
        Memory_Data     <= (others => 'Z');                                 -- Default: Don´t use the memory bus
        SecondCycle     <= '0';                                             -- Default: No second clock cycle
        Offset_Addr     <= (others => '0');                                 -- Default: No address offset
        UpdateX         <= '0';                                             -- Default: Don´t update the X Register
        UpdateY         <= '0';                                             -- Default: Don´t update the Y Register
        UpdateZ         <= '0';                                             -- Default: Don´t update the Z Register

        Dst             := "00" & IR(8 downto 4);                           -- Default: Get the destination register address from the instruction
        RegD            := "00" & IR(8 downto 4);                           -- Default: Get the Register D address from the instruction
        RegR            := "00" & IR(9) & IR(3 downto 0);                   -- Default: Get the Register R address from the instruction
        ImData          := IR(11 downto 8) & IR(3 downto 0);                -- Default: Get the immediate value from the instruction
        SREG_Temp       := SREG;

        -- Take care of 4 byte instructions
        if(std_match(IR, OpCALL) or std_match(IR, OpJMP) or std_match(IR, OpLDS_Long) or std_match(IR, OpSTS_Long)) then
            TwoWordInstruction <= '1';
        else
            TwoWordInstruction <= '0';
        end if;

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
            ImData          := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(7 downto 6) & IR(3 downto 0)), ImData'length));

            case IR(5 downto 4) is
                when "00" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Dst'length));
                when "01" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Dst'length));
                when "10" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Dst'length));
                when "11" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Dst'length));
                when others =>
            end case;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_ADD;
            end if;

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
        --  - Disable write for the register file
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Clear the target bit in the SREG
        --  - Select the memory bus as data source for the SRAM
        --  - Set the modified SRAM as data for the SRAM
        --  - Set the memory address to the SRAM
        if(std_match(IR, OpBCLR)) then
            Register_WE     <= '0';
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            SREG_Temp(to_integer(UNSIGNED(IR(6 downto 4)))) := '0';
            Memory_Source   <= MEM_MEMORY;
            Memory_Data     <= SREG_Temp;
            Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(16#3F#, Memory_Address'length));
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
        --  - Disable write to the register file
        --  - 1. Clock: 
        --      If masked bit is cleared:
        --          Set the PC to the current address plus the offset
        --      - 2. Clock: Run the PC
        if(std_match(IR, OpBRBC)) then
            Register_WE         <= '0';

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
        --  - Disable write to the register file
        --  - 1. Clock: 
        --      If masked bit is set:
        --          Set the PC to the current address plus the offset
        --      - 2. Clock: Run the PC
        if(std_match(IR, OpBRBS)) then
            Register_WE         <= '0';

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
        --  - Disable write for the register file
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Set the target bit in the SREG
        --  - Select the memory bus as data source for the SRAM
        --  - Set the modified SRAM as data for the SRAM
        --  - Set the memory address to the SRAM
        if(std_match(IR, OpBSET)) then
            Register_WE     <= '0';
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            SREG_Temp(to_integer(UNSIGNED(IR(6 downto 4)))) := '1';
            Memory_Source   <= MEM_MEMORY;
            Memory_Data     <= SREG_Temp;
            Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(16#3F#, Memory_Address'length));
        end if;

        -- BST instruction
        --  - Enable the SRAM
        --  - Enable write to the SRAM
        --  - Disable write for the register file
        --  - Set the bit mask for the T Flag
        --  - Enable writing of the T Flag
        --  - Set the ALU operation to "SET T FLAG"
        if(std_match(IR, OpBST)) then
            Memory_Enable           <= '1';
            Memory_WE               <= '1';
            Register_WE             <= '0';
            T_Mask                  <= STD_LOGIC_VECTOR(resize(UNSIGNED(IR(2 downto 0)), T_Mask'length));
            SREG_Mask(STATUS_BIT_T) <= '1';
            ALU_Operation           <= ALU_SET_T;
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
            Memory_Enable   <= '1';
            Memory_Address  <= "001" & IR(7 downto 3);
            Memory_Source   <= MEM_MEMORY;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '0';
                SRAM_Temp       := Memory_Data;
            elsif(ClockCycle = 1) then
                Memory_WE       <= '1';
                SRAM_Temp(to_integer(UNSIGNED(IR(2 downto 0)))) := '0';
                Memory_Data     <= SRAM_Temp;
            end if;
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
        --  - Disable write for the register file
        --  - 1. Clock: Hold the PC
        --              Enable the SRAM
        --              Enable write to the SRAM
        --              Set the destination for the SRAM to Memory
        --              Set the memory address to the current stack pointer value
        --              Set the memory data to the address of the next instruction after the instruction
        --  - 2. Clock: Set the address mode for the PC to Z-Register
        --  - 3. Clock: Enable the SRAM
        --              Enable write to the SRAM
        --              Set the destination for the SRAM to stack pointer
        --              Set the stack pointer to the current stack pointer minus 2 
        if(std_match(IR, OpICALL)) then
            Register_WE         <= '0';

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Source   <= MEM_MEMORY;
                Memory_Address  <= StackPointerIn((Memory_Address'length - 1) downto 0);
                Memory_Data     <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(PC)), Memory_Data'length));
            elsif(ClockCycle = 1) then
                PC_Mode         <= PC_Z_REG;
            elsif(ClockCycle = 2) then
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) - 2, StackPointerOut'length));
            end if;
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
            end if;
        end if;

        -- IN instruction
        --  - Set the memory as data source for the register file
        --  - Enable the SRAM
        --  - Set the SRAM address
        --  - Save the data in the SRAM
        if(std_match(IR, OpIN)) then
            Register_Source <= SRC_MEMORY;
            Memory_Enable   <= '1';
            Memory_Address  <= STD_LOGIC_VECTOR(resize(UNSIGNED(IR(10 downto 9) & IR(3 downto 0)), Memory_Address'length));
            Memory_Source   <= MEM_MEMORY;
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

        -- LD instruction
        if(std_match(IR, OpLD_X_1) or std_match(IR, OpLD_X_2) or std_match(IR, OpLD_X_3)) then
        end if;

        -- LDI instruction
        --  - Set the destination register address (the address offset is 16)
        --  - Set the input source for the register file to "Immediate"
        --  - Set the immediate value
        if(std_match(IR, OpLDI)) then
            Dst             := "001" & IR(7 downto 4);
            Register_Source <= SRC_IMMEDIATE;
        end if;

        -- LSR instruction
        --  - Set the ALU operation to "LSR"
        --  - Flag the changeable status flags
        if(std_match(IR, OpLSR)) then
            ALU_Operation   <= ALU_OP_LSR;
            SREG_Mask       <= STATUS_FLAG_SVNZC;
        end if;

        -- MOV instruction
        --  - Set the input source for the register file to "Register"
        if(std_match(IR, OpMOV)) then
            Register_Source <= SRC_REGISTER;
        end if;

        -- MOVW instruction
        --  - Set the input source for the register file to "Register"
        --  - Set the address of the source register (address has to be multiplied by 2)
        --  - Set the address of the destination register (address has to be multiplied by 2)
        if(std_match(IR, OpMOVW)) then
            Register_Source <= SRC_REGISTER;
            RegR            := "00" & IR(3 downto 0) & "0";
            Dst             := "00" & IR(7 downto 4) & "0";
            Register_Pair   <= '1';
        end if;

        -- MUL instruction
        --  - Flag the changeable status flags
        --  - 1. Clock: Hold the PC
        --              Set the ALU operation to "MUL_LOW"
        --              Set the destination register to R0
        --              Enable the Carry-Flag to update
        --  - 2. Clock: Set the ALU operation to "MUL_HIGH"
        --              Set the destination register to R1
        --              Enable the Zero-Flag to update
        if(std_match(IR, OpMUL)) then
            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_MUL_LOW_U;
                Dst             := (others => '0');
                SREG_Mask       <= STATUS_FLAG_C;
            elsif(ClockCycle = 1) then
                ALU_Operation   <= ALU_OP_MUL_HIGH_U;
                Dst             := ((0) => '1', others => '0');
                SREG_Mask       <= STATUS_FLAG_Z;
            end if;
        end if;

        -- MULS instruction
        --  - Flag the changeable status flags
        --  - 1. Clock: Hold the PC
        --              Set the ALU operation to low byte multiplication
        --              Set the destination register to R0
        --              Enable the Carry-Flag to update
        --  - 2. Clock: Set the ALU operation to high byte multiplication
        --              Set the destination register to R1
        --              Enable the Zero-Flag to update
        if(std_match(IR, OpMULS)) then
            RegD                := "001" & IR(7 downto 4);
            RegR                := "001" & IR(3 downto 0);
            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_MUL_LOW_S;
                Dst             := (others => '0');
                SREG_Mask       <= STATUS_FLAG_C;
            elsif(ClockCycle = 1) then
                ALU_Operation   <= ALU_OP_MUL_HIGH_S;
                Dst             := ((0) => '1', others => '0');
                SREG_Mask       <= STATUS_FLAG_Z;
            end if;
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
        --  - Disable write to the register file
        if(std_match(IR, OpNOP)) then
            Register_WE <= '0';
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
        --  - Enable the SRAM
        --  - Enable write for the SRAM
        --  - Set the SRAM address
        --  - Set the register file as SRAM source
        if(std_match(IR, OpOUT)) then
            Register_WE     <= '0';
            Memory_Enable   <= '1';
            Memory_WE       <= '1';
            Memory_Address  <= STD_LOGIC_VECTOR(resize(UNSIGNED(IR(10 downto 9) & IR(3 downto 0)), Memory_Address'length));
            Memory_Source   <= MEM_REG;
        end if;

        -- POP instruction
        --  - Enable the SRAM
        --  - 1. Clock: Disable write for the register file
        --              Hold the PC
        --              Enable write for the SRAM
        --              Set the stack pointer as input source for the SRAM
        --              Write the new stack pointer into the SRAM
        --  - 2. Clock: Set the destination register address
        --              Set the SRAM as data source for the register file
        --              Disable memory write
        --              Set the memory address to the current stack pointer
        if(std_match(IR, OpPOP)) then
            Memory_Enable       <= '1';

            if(ClockCycle = 0) then
                Register_WE     <= '0';
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '1';
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) + 1, StackPointerOut'length));
            elsif(ClockCycle = 1) then
                RegD            := "00" & IR(8 downto 4);
                Register_Source <= SRC_MEMORY;
                Memory_WE       <= '0';
                Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)), Memory_Address'length));
            end if;
        end if;

        -- PUSH instruction
        --  - Disable write for the register file
        --  - Enable the SRAM
        --  - Enable write for the SRAM
        --  - 1. Clock: Hold the PC
        --              Set the register as input source for the SRAM
        --              Set the memory address to the stack pointer
        --  - 2. Clock: Set the stack pointer as input source for the SRAM
        --              Write the new stack pointer into the SRAM
        if(std_match(IR, OpPUSH)) then
            Register_WE         <= '0';
            Memory_Enable       <= '1';
            Memory_WE           <= '1';

            if(ClockCycle = 0) then
                RegD            := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(8 downto 4)), RegD'length));
                PC_Mode         <= PC_KEEP;
                Memory_Source   <= MEM_REG;
                Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)), Memory_Address'length));
            elsif(ClockCycle = 1) then
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) - 1, StackPointerOut'length));
            end if;
        end if;

        -- RCALL instruction
        if(std_match(IR, OpRCALL)) then
        end if;

        -- RET instruction
        --  - Enable the SRAM
        --  - 1. Clock: Hold the PC
        --              Enable write to the SRAM
        --              Set the stack pointer as destination
        --              Write the new stack pointer (increased by two) into the SRAM
        --  - 2. Clock: Hold the PC
        --              Disable memory write
        --              Set the memory as destination
        --              Get the first byte of the memory address from stack
        --              Get the first byte of the return address
        --  - 3. Clock: Set the PC
        --              Disable memory write
        --              Set the memory as destination
        --              Get the second byte of the memory address from stack
        --              Get the second byte of the return address
        --  - 4. Clock  Return program execution
        if(std_match(IR, OpRET)) then
            Memory_Enable       <= '1';

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '1';
                Memory_Source   <= MEM_SP;
                StackPointerOut <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) + 2, StackPointerOut'length));
            elsif(ClockCycle = 1) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '0';
                Memory_Source   <= MEM_MEMORY;
                Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) - 0, Memory_Address'length));
                SP_Temp         := Memory_Data & "00000000";
            elsif(ClockCycle = 2) then
                PC_Mode         <= PC_SET;
                Memory_WE       <= '0';
                Memory_Source   <= MEM_MEMORY;
                Memory_Address  <= STD_LOGIC_VECTOR(to_unsigned(to_integer(UNSIGNED(StackPointerIn)) - 1, Memory_Address'length));
                SP_Temp         := Memory_Data & SP_Temp(15 downto 8);
                PC_Addr         <= UNSIGNED(SP_Temp);
            elsif(ClockCycle = 3) then
            end if;
        end if;

        -- RJMP instruction
        --  - Disable write for the register file
        --  - 1. Clock: Disable the PC
        --              Load the address from the Instruction Register
        --  - 2. Clock: Resume
        if(std_match(IR, OpRJMP)) then
            Register_WE     <= '0';

            if(ClockCycle = 0) then
                PC_Offset <= SIGNED(IR(11 downto 0));
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

        -- SBCI instruction
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
            Memory_Address      <= "001" & IR(7 downto 3);
            Memory_Source       <= MEM_MEMORY;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                Memory_WE       <= '0';
                SRAM_Temp       := Memory_Data;
            elsif(ClockCycle = 1) then
                Memory_WE       <= '1';
                SRAM_Temp(to_integer(UNSIGNED(IR(2 downto 0)))) := '1';
                Memory_Data     <= SRAM_Temp;
            end if;
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
            ImData          := STD_LOGIC_VECTOR(resize(UNSIGNED(IR(7 downto 6) & IR(3 downto 0)), ImData'length));

            case IR(5 downto 4) is
                when "00" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(24 + ClockCycle, Dst'length));
                when "01" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(26 + ClockCycle, Dst'length));
                when "10" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(28 + ClockCycle, Dst'length));
                when "11" =>
                    RegD    := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, RegD'length));
                    Dst     := STD_LOGIC_VECTOR(to_unsigned(30 + ClockCycle, Dst'length));
                when others =>
            end case;

            if(ClockCycle = 0) then
                PC_Mode         <= PC_KEEP;
                ALU_Operation   <= ALU_OP_SUB;
            elsif(ClockCycle = 1) then
                ALU_Operation   <= ALU_OP_SBC;
                ImData          := (others => '0');
            end if;
        end if;

        -- SLEEP instruction
        if(std_match(IR, OpSLEEP)) then
        end if;

        -- ST (X) instruction
        --  - Post increment:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the X Register
        --      - Enable update of the X Register
        --  - Pre decrement:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --                  Enable update of the X Register
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the X Register
        --                  Enable update of the X Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the X Register
        if(std_match(IR, OpST_X_1) or std_match(IR, OpST_X_2) or std_match(IR, OpST_X_3)) then
            -- Post incremented
            if(std_match(IR, OpST_X_2)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(1, Offset_Addr'length);
            -- Pre decremented
            elsif(std_match(IR, OpST_X_3)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(-1, Offset_Addr'length);
            -- Leave X unchanged
            else
            end if;

            if(ClockCycle = 0) then
                if(std_match(IR, OpST_X_2)) then
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_X;
                    UpdateX         <= '1';
                elsif(std_match(IR, OpST_X_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateX         <= '1';
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_X;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Source   <= MEM_X;
            end if;
        end if;

        -- ST (Y) instruction
        --  - Post increment:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Y Register
        --      - Enable update of the Y Register
        --  - Pre decrement:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --                  Enable update of the Y Register
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the Y Register
        --                  Enable update of the Y Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Y Register
        if(std_match(IR, OpST_Y_1) or std_match(IR, OpST_Y_2) or std_match(IR, OpST_Y_3)) then
            -- Post incremented
            if(std_match(IR, OpST_Y_2)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(1, Offset_Addr'length);
            -- Pre decremented
            elsif(std_match(IR, OpST_Y_3)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(-1, Offset_Addr'length);
            -- Leave Y unchanged
            else
            end if;

            if(ClockCycle = 0) then
                if(std_match(IR, OpST_Y_2)) then
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Y;
                    UpdateY         <= '1';
                elsif(std_match(IR, OpST_Y_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateY         <= '1';
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Y;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Source   <= MEM_Y;
            end if;
        end if;

        -- ST (Z) instruction
        --  - Post increment:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to 1
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Z Register
        --      - Enable update of the Z Register
        --  - Pre decrement:
        --      - Set the register file as source
        --      - Set the offset for the address register pair to -1
        --      - 1. Clock: Disable the PC
        --                  Enable a second clock cycle
        --                  Enable update of the Z Register
        --      - 2. Clock: Enable write to the SRAM
        --                  Set the address source for the SRAM to the Z Register
        --                  Enable update of the Z Register
        --  - No address modification:
        --      - Enable the SRAM
        --      - Enable write to the SRAM
        --      - Set the address source for the SRAM to the Z Register
        if(std_match(IR, OpST_Z_1) or std_match(IR, OpST_Z_2) or std_match(IR, OpST_Z_3)) then
            -- Post incremented
            if(std_match(IR, OpST_Z_2)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(1, Offset_Addr'length);
            -- Pre decremented
            elsif(std_match(IR, OpST_Z_3)) then
                Register_Source <= SRC_REGISTER;
                Offset_Addr     <= to_signed(-1, Offset_Addr'length);
            -- Leave Z unchanged
            else
            end if;

            if(ClockCycle = 0) then
                if(std_match(IR, OpST_Z_2)) then
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Z;
                    UpdateY         <= '1';
                elsif(std_match(IR, OpST_Z_3)) then
                    PC_Mode         <= PC_KEEP;
                    SecondCycle     <= '1';
                    UpdateY         <= '1';
                else
                    Memory_Enable   <= '1';
                    Memory_WE       <= '1';
                    Memory_Source   <= MEM_Z;
                end if;
            elsif(ClockCycle = 1) then
                Memory_Enable   <= '1';
                Memory_WE       <= '1';
                Memory_Source   <= MEM_Z;
            end if;
        end if;

        -- STS instruction
        if(std_match(IR, OpSTS)) then
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