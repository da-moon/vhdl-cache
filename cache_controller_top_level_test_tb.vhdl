LIBRARY ieee;
USE std.textio.ALL;

ENTITY cache_controller_top_level_test_tb IS
END cache_controller_top_level_test_tb;
ARCHITECTURE testbench OF cache_controller_top_level_test_tb IS
BEGIN
    PROCESS
        VARIABLE L : line;
    BEGIN
        WAIT FOR 1 ns;
        write(L, STRING'("there is no need to test cache controller top level test ... moving on !"));
        writeline(output, L);
        WAIT;
    END PROCESS;
END testbench;