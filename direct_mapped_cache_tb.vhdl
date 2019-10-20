LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE std.textio.ALL;
USE work.cache_pkg.ALL;
USE work.utils_pkg.ALL;
USE work.cache_test_pkg.ALL;
ENTITY direct_mapped_cache_tb IS
	GENERIC (
		TAG_FILENAME : STRING := "./imem/tag";
		DATA_FILENAME : STRING := "./imem/data";
		FILE_EXTENSION : STRING := ".txt"
	);
END;
ARCHITECTURE testbench OF direct_mapped_cache_tb IS
	CONSTANT clock_period : TIME := 10 ns;
	CONSTANT C_FILE_NAME : STRING := "test_results/direct_mapped_cache.txt";
	CONSTANT TEST_TIME : TIME := 10000 ns;
	CONSTANT NUMBER_OF_STATES : INTEGER := 4;

	SIGNAL reset : STD_LOGIC := '0';
	SIGNAL clk : STD_LOGIC := '0';
	SIGNAL add_cpu : STD_LOGIC_VECTOR(DEFAULT_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_cpu : STD_LOGIC_VECTOR(DEFAULT_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => 'Z');
	SIGNAL valid : STD_LOGIC := '0';
	SIGNAL dirty : STD_LOGIC := '0';
	SIGNAL hit : STD_LOGIC := '0';
	SIGNAL wr_rd : STD_LOGIC := '0';
	SIGNAL cache_memory_data_bus : STD_LOGIC_VECTOR(CACHE_BLOCK_LINE_RANGE) := (OTHERS => '0');
	SIGNAL new_cache_block_line : STD_LOGIC_VECTOR(CACHE_BLOCK_LINE_RANGE);
	SIGNAL rd_word : STD_LOGIC := '0';
	SIGNAL wr_word : STD_LOGIC := '0';
	SIGNAL rd_cache_block_line : STD_LOGIC := '0';
	SIGNAL wr_cache_block_Line : STD_LOGIC := '0';
	SIGNAL set_valid : STD_LOGIC := '0';
	SIGNAL set_dirty : STD_LOGIC := '0';
	SIGNAL my_data_word : STD_LOGIC_VECTOR(DEFAULT_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL eof : std_logic := '0';
	FILE fptr : text;

	-- clock gen component
	COMPONENT clock_gen
		GENERIC (clock_period : TIME);
		PORT (
			clk : OUT std_logic
		);
	END COMPONENT;
	COMPONENT direct_mapped_cache
		GENERIC (
			TAG_FILENAME : STRING;
			DATA_FILENAME : STRING;
			FILE_EXTENSION : STRING
		);
		PORT (
			clk : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			add_cpu : IN STD_LOGIC_VECTOR(DEFAULT_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0);
			data_cpu : INOUT STD_LOGIC_VECTOR(DEFAULT_DATA_WIDTH - 1 DOWNTO 0);
			new_cache_block_line : IN STD_LOGIC_VECTOR(DEFAULT_DATA_WIDTH * DEFAULT_BLOCK_SIZE - 1 DOWNTO 0);
			cache_memory_data_bus : OUT STD_LOGIC_VECTOR(DEFAULT_DATA_WIDTH * DEFAULT_BLOCK_SIZE - 1 DOWNTO 0);
			wr_cache_block_Line : IN STD_LOGIC;
			rd_cache_block_line : IN STD_LOGIC;
			rd_word : IN STD_LOGIC;
			wr_word : IN STD_LOGIC;
			wr_rd : IN STD_LOGIC;
			valid : INOUT STD_LOGIC;
			dirty : INOUT STD_LOGIC;
			set_valid : IN STD_LOGIC;
			set_dirty : IN STD_LOGIC;
			hit : OUT STD_LOGIC
		);
	END COMPONENT;

BEGIN
	-- Clock generator instl
	clock_gen_instl : clock_gen
	GENERIC MAP(clock_period => clock_period)
	PORT MAP(
		clk => clk
	);
	
	-- unit under test
	uut : direct_mapped_cache
	GENERIC MAP(
		TAG_FILENAME => TAG_FILENAME,
		DATA_FILENAME => DATA_FILENAME,
		FILE_EXTENSION => FILE_EXTENSION
	)
	PORT MAP(
		clk => clk,
		reset => reset,
		data_cpu => data_cpu,
		add_cpu => add_cpu,
		cache_memory_data_bus => cache_memory_data_bus,
		rd_word => rd_word,
		wr_word => wr_word,
		wr_cache_block_Line => wr_cache_block_Line,
		rd_cache_block_line => rd_cache_block_line,
		wr_rd => wr_rd,
		valid => valid,
		dirty => dirty,
		set_valid => set_valid,
		set_dirty => set_dirty,
		hit => hit,
		new_cache_block_line => new_cache_block_line
	);
	-- 

	stim_proc : PROCESS
		VARIABLE counter : INTEGER;
		VARIABLE old_addr : STD_LOGIC_VECTOR (15 DOWNTO 0);

		VARIABLE L : line;
		VARIABLE temp : STD_LOGIC_VECTOR (1 TO 1);
		VARIABLE tag1, tag2 : STD_LOGIC_VECTOR(CALCULATE_TAG_VECTOR_SIZE - 1 DOWNTO 0);
		VARIABLE index : STD_LOGIC_VECTOR(CALCULATE_INDEX_VECTOR_SIZE - 1 DOWNTO 0);
		VARIABLE offset : STD_LOGIC_VECTOR(CALCULATE_OFFSET_VECTOR_SIZE - 1 DOWNTO 0);
		VARIABLE irand : INTEGER;
		VARIABLE seed1, seed2 : POSITIVE;
		VARIABLE blockLine : BLOCK_LINE := INIT_BLOCK_LINE(0, 0, 0, 0);

	BEGIN
		WAIT FOR 1 ns;
		write(L, STRING'("cache controller tests "));
		writeline(output, L);
		data_cpu <= (others => 'Z');
		-- ---------------------------------------------------------------------------------------------------
		-- Reset the Direct Mapped Cache.
		-- ---------------------------------------------------------------------------------------------------
		reset   <= '0';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		reset <= '1';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		wait for 5 ns;
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		wait until falling_edge(clk);

	--	FOR I IN 0 to NUMBER_OF_STATES-1 LOOP
	--		add_cpu<=GENERATE_CPU_ADDRESS(I);
	--		data_cpu<=GET_DATA_DEFAULTS(I);
	--		tag1 := GET_TAG(add_cpu);
	--		index := GET_INDEX(add_cpu);
	--		offset := GET_OFFSET(add_cpu);
	--		WAIT UNTIL rising_edge(clk);
	--		WAIT UNTIL falling_edge(clk);
	--		-- IF (data_cpu = blockLine(I)) THEN
	--			-- REPORT "[SUCCESS] cpu instruction [0x" & TO_HEX_STRING(blockLine(I)) & "] cpu address [0x" & TO_HEX_STRING(add_cpu) & "] offset [" & INTEGER'IMAGE(J) & "] index [" & INTEGER'IMAGE(I) & "]" SEVERITY NOTE;
	--			-- REPORT "[SUCCESS]Iteration [ "&INTEGER'IMAGE(I) & " ]"&"cpu address [" & TO_STRING(add_cpu) & "]" & "cpu data [" & TO_STRING(blockLine(I)) & "]" SEVERITY NOTE;
	--			IF NOT is_X(add_cpu) and NOT is_X(blockLine(I)) THEN
	--			REPORT "Iteration [ "&INTEGER'IMAGE(I) & " ]"&"cpu address [" & TO_STRING(add_cpu) & "]" & "cpu data [" & TO_STRING(blockLine(I)) & "]" SEVERITY NOTE;
	--			END IF;
	--			-- ELSE
	--		-- 	-- TODO FIX THIS
	--		-- 	-- report "[FAILURE] cpu address [0x" & TO_HEX_STRING(add_cpu)  & "] offset [" & INTEGER'IMAGE(J) & "] index [" & INTEGER'IMAGE(I) & "] Actual Value [0x" & TO_HEX_STRING(data_cpu) & "] != Expected Value [0x" & TO_HEX_STRING(blockLine(I)) & "]." severity FAILURE;
	--		-- 	report "[FAILURE] cpu address [" &  TO_HEX_STRING(add_cpu)  & "] Actual Data Value [0x" & TO_STRING(data_cpu) & "] != Expected Data Value [" & TO_STRING(blockLine(I)) & "]." severity FAILURE;
	--		-- END IF;
	--		WAIT UNTIL rising_edge(clk);
	--		WAIT UNTIL falling_edge(clk);
--
	--	END LOOP;
		WAIT;
		-- end if;

	END PROCESS;

END;