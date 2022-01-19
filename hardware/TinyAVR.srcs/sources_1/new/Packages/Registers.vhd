----------------------------------------------------------------------------------
-- Company:             www.kampis-elektroecke.de
-- Engineer:            Daniel Kampert  
-- 
-- Create Date:         22.07.2020 19:04:49
-- Design Name:         
-- Package Name:        Registers
-- Project Name:        TinyAVR
-- Target Devices:      
-- Tool Versions:       Vivado 2020.2
-- Description:         Register addresses for the TinyAVR microprocessor.
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

package Registers is

    constant RegSREG    : INTEGER           := 16#3F#;
    constant RegSPH     : INTEGER           := 16#3E#;
    constant RegSPL     : INTEGER           := 16#3D#;

    constant RegXL      : INTEGER           := 16#1A#;
    constant RegXH      : INTEGER           := 16#1B#;
    constant RegYL      : INTEGER           := 16#1C#;
    constant RegYH      : INTEGER           := 16#1D#;
    constant RegZL      : INTEGER           := 16#1E#;
    constant RegZH      : INTEGER           := 16#1F#;

end package;