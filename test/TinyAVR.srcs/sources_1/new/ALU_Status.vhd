----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name: 
-- Module Name:         ALU_Status - ALU_Status_Arch
-- Project Name:        TinyAVR
-- Target Devices: 
-- Tool Versions:       Vivado 2020.2
-- Description:         Status block for the TinyAVR ALU.
-- 
-- Dependencies: 
-- 
-- Revision:
--  Revision            0.01 - File Created
-- Additional Comments: - T flag isn´t implemented yet
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

entity ALU_Status is
    Port (  R           : in STD_LOGIC_VECTOR(7 downto 0);              -- ALU result
            H           : in STD_LOGIC;                                 -- H flag from the ALU operation
            V           : in STD_LOGIC;                                 -- V flag from the ALU operation
            C           : in STD_LOGIC;                                 -- C flag from the ALU operation
            T           : in STD_LOGIC;                                 -- T flag from the ALU operation
            SREGIn      : in STD_LOGIC_VECTOR(7 downto 0);              -- SREG input
            Mask        : in Bit_Mask_t;                                -- Status register modification mask
            SREGOut     : out STD_LOGIC_VECTOR(7 downto 0)              -- Modified Status register output
            );
end ALU_Status;

architecture ALU_Status_Arch of ALU_Status is

begin

    process(R, H, V, C, T, SREGIn, Mask)
        variable NFlag  : STD_LOGIC                     := '0';
        variable VFlag  : STD_LOGIC                     := '0';
        variable Status : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    begin
        Status := SREGIn;

        -- Save the T Flag
        if(Mask(STATUS_BIT_T) = '1') then
            Status(STATUS_BIT_T) := T;
        end if;

        -- Save the C Flag from the ALU operation
        if(Mask(STATUS_BIT_C) = '1') then
            Status(STATUS_BIT_C) := C;
        end if;
                
        -- Modify the Z Flag
        if(Mask(STATUS_BIT_Z) = '1') then
            if(R = STD_LOGIC_VECTOR(to_unsigned(0, R'length))) then
                Status(STATUS_BIT_Z) := '1';
            else
                Status(STATUS_BIT_Z) := '0';
            end if;
        end if;
                
        -- Modify the N Flag
        if(Mask(STATUS_BIT_N) = '1') then
            NFlag := R(R'length - 1);
            Status(STATUS_BIT_N) := NFlag;
        else
            NFlag := '0';
        end if;
                
        -- Modify the V Flag
        if(Mask(STATUS_BIT_V) = '1') then
            VFlag := V;
            Status(STATUS_BIT_V) := VFlag;
        else 
            VFlag := '0';
         end if;
                
        -- Modify the S Flag
        if(Mask(STATUS_BIT_S) = '1') then
            Status(STATUS_BIT_S) := NFlag xor VFlag;
        end if;

        -- Modify the H Flag
        if(Mask(STATUS_BIT_H) = '1') then
            Status(STATUS_BIT_H) := H;
        end if;

        SREGOut <= Status;

    end process;
end ALU_Status_Arch;