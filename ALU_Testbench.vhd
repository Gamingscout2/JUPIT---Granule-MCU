library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_Testbench is
--  Port ( ); -- testbench has no I/O
end ALU_Testbench;

architecture TEST of ALU_Testbench is

    COMPONENT ALU
       PORT (
            OP : IN STD_LOGIC_VECTOR(2 downto 0);
            in_A, in_B : IN STD_LOGIC_VECTOR(7 downto 0);
            C_IN : IN STD_LOGIC;
            RESULT, RESULT_H : OUT STD_LOGIC_VECTOR(7 downto 0);
            C_OUT, V_OUT : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL A_TB, B_TB : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL OP_TB : STD_LOGIC_VECTOR(2 downto 0);
    SIGNAL C_IN_TB : STD_LOGIC;
    SIGNAL RESULT_TB, RESULT_H_TB : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL C_OUT_TB, V_OUT_TB : STD_LOGIC;

BEGIN
    UUT : ALU PORT MAP (  
        in_A => A_tb,
        in_B => B_tb,
        OP   => OP_TB,
        C_IN => C_IN_TB,
        RESULT => RESULT_TB,
        RESULT_H => RESULT_H_TB,
        C_OUT => C_OUT_TB,
        V_OUT => V_OUT_TB         
        );

    ---------------------------------------------------------------------------
    -- NAME: Stimulus
    ---------------------------------------------------------------------------
    stimulus : PROCESS
    
        -- Complete check procedure with high-byte tracking for multiplication
        PROCEDURE check(expected_low : IN STD_LOGIC_VECTOR(7 downto 0);
                        expected_high : IN STD_LOGIC_VECTOR(7 downto 0) := (others => '0')) IS
        BEGIN
            -- Assert check for low byte
            assert (RESULT_TB = expected_low)
                report "Mismatch on RESULT! OP=" & integer'image(to_integer(unsigned(OP_TB))) &
                       " A=" & integer'image(to_integer(signed(A_TB))) &
                       " B=" & integer'image(to_integer(signed(B_TB))) &
                       " Expected: " & integer'image(to_integer(signed(expected_low))) &
                       " Got: " & integer'image(to_integer(signed(RESULT_TB)))
                severity error;
                
            -- Assert check for high byte (used during multiplication)
            if OP_TB = "011" then
                assert (RESULT_H_TB = expected_high)
                    report "Mismatch on RESULT_H! Multiplication failed."
                    severity error;
            end if;
        END PROCEDURE;
    
        VARIABLE temp_s_8b : STD_LOGIC_VECTOR(7 downto 0);
        VARIABLE temp_s_16b : STD_LOGIC_VECTOR(15 downto 0); -- For multiplying
        VARIABLE cin_int : integer;
        
    BEGIN
        for k in 0 to 7 loop
            OP_TB <= STD_LOGIC_VECTOR(to_unsigned(k, 3));
            for i in 0 to 1 loop
                CASE i IS
                    WHEN 0 => C_IN_TB <= '0'; cin_int := 0;
                    WHEN 1 => C_IN_TB <= '1'; cin_int := 1;
                END CASE;
                
                -- CRITICAL FIX: Loop from -128 to 127 for valid 8-bit 2's complement values
                for j in -128 to 127 loop
                    A_TB <= STD_LOGIC_VECTOR(to_signed(j, 8));
                    for h in -128 to 127 loop
                        B_TB <= STD_LOGIC_VECTOR(to_signed(h, 8));
                        wait for 2 ns;
                             
                        CASE k is
                            WHEN 0 => -- ADD with Carry In
                                temp_s_8b := STD_LOGIC_VECTOR(SIGNED(A_TB) + SIGNED(B_TB) + to_signed(cin_int, 8));
                                check(temp_s_8b);
                            WHEN 1 => -- SUB with Carry In (Borrow)
                                temp_s_8b := STD_LOGIC_VECTOR(SIGNED(A_TB) - SIGNED(B_TB) - to_signed(cin_int, 8));
                                check(temp_s_8b);
                            WHEN 2 => -- DIV
                                if h /= 0 then -- Prevent division by zero crash in simulation
                                    temp_s_8b := STD_LOGIC_VECTOR(SIGNED(A_TB) / SIGNED(B_TB));
                                    check(temp_s_8b);
                                end if;
                            WHEN 3 => -- MUL (Produces 16-bit split across RESULT_H and RESULT)
                                temp_s_16b := STD_LOGIC_VECTOR(SIGNED(A_TB) * SIGNED(B_TB));
                                check(temp_s_16b(7 downto 0), temp_s_16b(15 downto 8));
                            WHEN 4 => -- AND
                                temp_s_8b := A_TB AND B_TB;
                                check(temp_s_8b);
                            WHEN 5 => -- OR
                                temp_s_8b := A_TB OR B_TB;
                                check(temp_s_8b);
                            WHEN 6 => -- XOR
                                temp_s_8b := A_TB XOR B_TB;
                                check(temp_s_8b);
                            WHEN 7 => -- XNOR
                                temp_s_8b := A_TB XNOR B_TB;
                                check(temp_s_8b);
                            WHEN OTHERS =>
                                null;
                        END CASE;
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;

        WAIT FOR 10 ns;
        Report LF& "**************************" &LF&
                   "Simulation Complete" &LF&
                   "**************************" SEVERITY NOTE;
        std.env.finish; -- VHDL-2008 clean finish rule
    END PROCESS stimulus;

end TEST;
