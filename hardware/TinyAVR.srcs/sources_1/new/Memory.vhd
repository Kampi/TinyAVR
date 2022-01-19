----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Module Name:         Memory - Memory_Arch
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Memory module for the TinyAVR microprocessor.
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

entity Memory is
    Generic (   SRAM_SIZE   : INTEGER := 12                                     -- Address length of the SRAM in bit
                );
    Port (  Clock           : in STD_LOGIC;                                     -- Clock signal
            nReset          : in STD_LOGIC;                                     -- Reset (active low)
            WE              : in STD_LOGIC;                                     -- Write enable signal
            Enable          : in STD_LOGIC;                                     -- Enable signal

            Pair            : in STD_LOGIC;                                     -- Use register pairs instead of a single register
            UpdateX         : in STD_LOGIC;                                     -- Update the X Register pair with the offset address
            UpdateY         : in STD_LOGIC;                                     -- Update the Y Register pair with the offset address
            UpdateZ         : in STD_LOGIC;                                     -- Update the Z Register pair with the offset address

            -- SRAM inputs
            Source          : in Sram_Source_t;                                 -- SRAM data source
            Status          : in STD_LOGIC_VECTOR(7 downto 0);                  -- Status input from ALU
            StackPointer    : in STD_LOGIC_VECTOR(15 downto 0);                 -- Stack pointer input
            Immediate       : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from immediate value
            ALU             : in STD_LOGIC_VECTOR(7 downto 0);                  -- Data input from ALU

            -- Address inputs
            Address         : in UNSIGNED((SRAM_SIZE - 1) downto 0);            -- SRAM memory address
            DstReg_Addr     : in UNSIGNED(6 downto 0);                          -- Write destination register address
            RegD_Addr       : in UNSIGNED(6 downto 0);                          -- Register D address
            RegR_Addr       : in UNSIGNED(6 downto 0);                          -- Register R address
            Offset_Addr     : in SIGNED(1 downto 0);                            -- Address offset for indirect addressing mode

            -- Address outputs
            Z               : out UNSIGNED(15 downto 0);                         -- Z address register

            -- SRAM outputs
            SREG            : out STD_LOGIC_VECTOR(7 downto 0);                 -- Status Register
            SP              : out STD_LOGIC_VECTOR(15 downto 0);                -- Stack Pointer

            -- Memory bus
            Data            : inout STD_LOGIC_VECTOR(7 downto 0);

            RegD            : out STD_LOGIC_VECTOR(7 downto 0);                 -- Register D output
            RegR            : out STD_LOGIC_VECTOR(7 downto 0);                 -- Register R output

            -- I/O controller register
            Reg_PortB       : out STD_LOGIC_VECTOR(7 downto 0);                 --
            Reg_PinB        : in STD_LOGIC_VECTOR(7 downto 0);                  --
            Reg_DDRB        : out STD_LOGIC_VECTOR(7 downto 0)                  --
            );
end Memory;

architecture Memory_Arch of Memory is

    type RAM_t is array(0 to ((2 ** SRAM_SIZE) - 1)) of STD_LOGIC_VECTOR(7 downto 0);

    signal RAM              : RAM_t                                         := (others => (others => '0'));

    signal X_Temp           : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');
    signal Y_Temp           : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');
    signal Z_Temp           : STD_LOGIC_VECTOR(15 downto 0)                 := (others => '0');

begin

    X_Temp          <= RAM(RegXH) & RAM(RegXL);
    Y_Temp          <= RAM(RegYH) & RAM(RegYL);
    Z_Temp          <= RAM(RegZH) & RAM(RegZL);

    Data            <=  RAM(to_integer(Address)) when ((Enable = '1') and (WE = '0'))   else
                        (others => 'Z');

    SREG            <= RAM(RegSREG);
    SP              <= RAM(RegSPH) & RAM(RegSPL);

    RegD            <= RAM(to_integer(UNSIGNED(RegD_Addr)));
    RegR            <= RAM(to_integer(UNSIGNED(RegR_Addr)));

    Z               <= UNSIGNED(Z_Temp);

    WriteMemory_Proc : process
        variable Var_Address    : UNSIGNED(16 downto 0)         := (others => '0');
    begin
        wait until rising_edge(Clock);

        -- Update the indirect addressing registers
        if(UpdateX = '1') then
            Var_Address := UNSIGNED(SIGNED('0' & X_Temp) + resize(Offset_Addr, X_Temp'length + 1));

            RAM(RegXL)  <= STD_LOGIC_VECTOR(Var_Address(7 downto 0));
            RAM(RegXH)  <= STD_LOGIC_VECTOR(Var_Address(15 downto 8));
        elsif(UpdateY = '1') then
            Var_Address := UNSIGNED(SIGNED('0' & Y_Temp) + resize(Offset_Addr, Y_Temp'length + 1));

            RAM(RegYL)  <= STD_LOGIC_VECTOR(Var_Address(7 downto 0));
            RAM(RegYH)  <= STD_LOGIC_VECTOR(Var_Address(15 downto 8));
        elsif(UpdateZ = '1') then
            Var_Address := UNSIGNED(SIGNED('0' & Z_Temp) + resize(Offset_Addr, Z_Temp'length + 1));

            RAM(RegZL)  <= STD_LOGIC_VECTOR(Var_Address(7 downto 0));
            RAM(RegZH)  <= STD_LOGIC_VECTOR(Var_Address(15 downto 8));
        end if;

        if((WE = '1') and (Enable = '1')) then
            case Source is
                -- Load an immediate value from the Program Memory
                when MEM_IMMEDIATE =>
                    RAM(to_integer(DstReg_Addr))    <= Immediate;

                -- An arithmetic or logical operation was processed
                -- Store the result in the destination register and the status in the SREG
                when MEM_ALU =>
                    RAM(to_integer(DstReg_Addr))    <= ALU;
                    RAM(RegSREG)                    <= Status;

                -- Data from one register should be copied into another register
                when MEM_REG =>
                    if(Pair = '1') then
                        RAM(to_integer(UNSIGNED(RegD_Addr) + 1))    <= RAM(to_integer(UNSIGNED(RegR_Addr) + 1));
                        RAM(to_integer(UNSIGNED(RegD_Addr)))        <= RAM(to_integer(UNSIGNED(RegR_Addr)));
                    else
                        RAM(to_integer(UNSIGNED(RegD_Addr)))        <= RAM(to_integer(UNSIGNED(RegR_Addr)));
                    end if;

                -- Load data from the register into the memory
                when MEM_OUT =>
                    RAM(to_integer(Address)) <= RAM(to_integer(RegD_Addr));

                when MEM_SP =>
                    RAM(RegSPH) <= StackPointer(15 downto 8);
                    RAM(RegSPL) <= StackPointer(7 downto 0);

                when MEM_X =>
                    RAM(to_integer(UNSIGNED(X_Temp))) <= RAM(to_integer(RegD_Addr));

                when MEM_Y =>
                    RAM(to_integer(UNSIGNED(Y_Temp))) <= RAM(to_integer(RegD_Addr));

                when MEM_Z =>
                    RAM(to_integer(UNSIGNED(Z_Temp))) <= RAM(to_integer(RegD_Addr));
                --
                when others =>
                    case Address is
                        when others =>
                            RAM(to_integer(Address)) <= Data;
                    end case;
            end case;
        elsif(Enable = '1') then
            -- Load data from the memory into a register
            if(Source = MEM_IN) then
                RAM(to_integer(RegD_Addr)) <= RAM(to_integer(Address));
            -- Load data indirect to a register by using the X register
            elsif(Source = MEM_X) then
                RAM(to_integer(RegD_Addr)) <= RAM(to_integer(UNSIGNED(X_Temp)));
            -- Load data indirect to a register by using the Y register
            elsif(Source = MEM_Y) then
                RAM(to_integer(RegD_Addr)) <= RAM(to_integer(UNSIGNED(Y_Temp)));
            -- Load data indirect to a register by using the Z register
            elsif(Source = MEM_Z) then
                RAM(to_integer(RegD_Addr)) <= RAM(to_integer(UNSIGNED(Z_Temp)));
            end if;
        end if;

        if(nReset = '0') then
            RAM <= (others => (others => '0'));
        end if;
    end process;
end Memory_Arch;