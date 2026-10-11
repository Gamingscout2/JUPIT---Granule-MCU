----------------------------------------------------------------------------------
-- Company: Novae Notiones Digital Design
-- Engineer: Phaedra Parsons
-- 
-- Create Date: 10/09/2026 06:44:25 PM
-- Design Name: ALU for Jupit Experimental 8-Bit Microcontroller
-- Module Name: ALU - Behavioral
-- Project Name: Jupit Rev 0.01
-- Target Devices: AMD/Xilinx Artix 7 FPGA / Digilent Basys 3 Dev Board
-- Tool Versions: AMD Vivado 2026.1
-- Description: Experiment to learn about CPU architecture and design, eventaully to expand to a full
--  experimental microcontroller design
--  Basic 8-Bit arithmetic logic unit
-- Dependencies: N/A
-- 
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

--****************************************
--+-------+--------------+
--| OP    | Operation    |
--+-------+--------------+
--| 000   | A + B        |
--+-------+--------------+
--| 001   | A - B        |
--+-------+--------------+
--| 010   | A / B        |
--+-------+--------------+
--| 011   | A * B        |
--+-------+--------------+
--| 100   | A & B        |
--+-------+--------------+
--| 101   | A || B       |
--+-------+--------------+
--| 110   | A XOR B      |
--+-------+--------------+
--| 111   | A XNOR B     |
--+-------+--------------+
--*****************************************

ENTITY ALU IS
  PORT (
        OP : IN STD_LOGIC_VECTOR(2 downto 0);
        in_A, in_B : IN STD_LOGIC_VECTOR(7 downto 0);
        C_IN : IN STD_LOGIC;
        RESULT, RESULT_H : OUT STD_LOGIC_VECTOR(7 downto 0);
        C_OUT, V_OUT : OUT STD_LOGIC
   );
end ALU;

ARCHITECTURE BEHAVIORAL OF ALU IS
    SIGNAL RES_TEMP : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL A_SIGNED, B_SIGNED : SIGNED(7 downto 0);
BEGIN
    A_SIGNED <= SIGNED(in_A);
    B_SIGNED <= SIGNED(in_B);
    PROCESS(A_SIGNED, B_SIGNED, C_IN, OP)
        VARIABLE temp_add_sub : SIGNED(8 downto 0); -- Extra bit to capture Carry Out
        VARIABLE temp_mul     : SIGNED(15 downto 0); -- 8-bit * 8-bit requires 16 bits
    BEGIN
        -- Default flag assignments to prevent latches
        C_OUT <= '0';
        V_OUT <= '0';
        
        CASE OP IS
            -- A + B
            WHEN "000" => 
                temp_add_sub := resize(a_signed, 9) + resize(b_signed, 9) + ("00000000" & C_IN);
                RESULT   <= STD_LOGIC_VECTOR(temp_add_sub(7 downto 0));
                C_OUT        <= temp_add_sub(8);
                IF (a_signed(7) = b_signed(7)) AND (temp_add_sub(7) /= a_signed(7)) THEN
                    V_OUT <= '1';
                ELSE
                    V_OUT <= '0';
                END IF;
                

            -- A - B
            WHEN "001" => 
                temp_add_sub := resize(a_signed, 9) - resize(b_signed, 9) - ("00000000" & C_IN);
                RESULT   <= STD_LOGIC_VECTOR(temp_add_sub(7 downto 0));
                C_OUT        <= temp_add_sub(8);
                IF (a_signed(7) /= b_signed(7)) AND (temp_add_sub(7) /= a_signed(7)) THEN
                    V_OUT <= '1';
                ELSE
                    V_OUT <= '0';
                END IF;

            -- A / B
            WHEN "010" => 
                IF (b_signed = 0) THEN
                    RESULT <= (OTHERS => '0'); -- Divide by zero safeguard
                    V_OUT <= '1';
                ELSE
                    RESULT <= STD_LOGIC_VECTOR(a_signed / b_signed);
                END IF;
                IF  (a_signed = "10000000" AND b_signed = "11111111") THEN
                    V_OUT <= '1';
                ELSE
                    V_OUT <= '0';
                END IF;

            -- A * B
            WHEN "011" => 
                temp_mul   := a_signed * b_signed;
                RESULT <= STD_LOGIC_VECTOR(temp_mul(7 downto 0)); -- Lower 8 bits of the product (goes into special result low register)
                RESULT_H <= STD_LOGIC_VECTOR(temp_mul(15 downto 8)); -- Upper 8 btis of product (goes into a special result high nibble register )
                -- Set overflow if product exceeds 8-bit signed range
                IF (temp_mul(15 downto 7) /= "000000000" AND temp_mul(15 downto 7) /= "111111111") THEN
                    V_OUT <= '1';
                END IF;

            -- Bitwise AND
            WHEN "100" => 
                RESULT <= STD_LOGIC_VECTOR(in_A AND in_B);

            -- Bitwise OR
            WHEN "101" => 
                RESULT <= STD_LOGIC_VECTOR(in_A OR in_B);

            -- Bitwise XOR
            WHEN "110" => 
                RESULT <= STD_LOGIC_VECTOR(in_A XOR in_B);

            -- Bitwise XNOR
            WHEN "111" => 
                RESULT<= STD_LOGIC_VECTOR(in_A XNOR in_B);

            WHEN OTHERS => 
                RESULT <= (OTHERS => '0');
        END CASE;
        
        
    END PROCESS;


END BEHAVIORAL;
