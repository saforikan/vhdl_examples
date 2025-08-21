--
-- Testbench based on VUnit testing framework and GHDL simulator
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

library simlib;
use simlib.sim.all;
use simlib.axi_mm_csr_pkg.all;

entity timestamp_csr_tb is
	generic (
		runner_cfg : string
	);
end timestamp_csr_tb;

architecture testbench of timestamp_csr_tb is

	constant CSR_CLK_PERIOD : time := 5 ns; -- 200 MHz
	constant TS_CLK_PERIOD : time := 8 ns; -- 125 MHz
	signal clk  : std_logic := '0';
	signal ts_clk : std_logic := '0';
	signal rst : std_logic := '1';

	constant end_msg : msg_type_t := new_msg_type("test_end");
	constant cmp_recv : actor_t := new_actor("receiver");

	-- AXI-Lite mmap
	constant CSR_ADDR_WIDTH : integer := 3;
	constant CSR_DATA_WIDTH : integer := 32;

	signal mm_s2m : axi_mm_s2m_t := axi_mm_s2m_init;
	signal mm_m2s : axi_mm_m2s_t := axi_mm_m2s_init;

begin
	-- Clock generation
	clk <= not clk after CSR_CLK_PERIOD/2;
	ts_clk <= not ts_clk after TS_CLK_PERIOD/2;
	rst <= '0' after 15 ns;
	csr_clk <= clk;

	dut : entity work.timestamp_csr
		port map (
			clk => clk,
			tsclk => ts_clk,
			rst => rst,

			-- slave axi-lite write address channel signals
			s_axi_lite_awaddr => mm_m2s.awaddr(CSR_ADDR_WIDTH - 1 downto 0),
			s_axi_lite_awvalid => mm_m2s.awvalid,
			s_axi_lite_awready => mm_s2m.awready,
		
			-- slave axi-lite read address channel signals
			s_axi_lite_araddr => mm_m2s.araddr(CSR_ADDR_WIDTH - 1 downto 0),
			s_axi_lite_arvalid => mm_m2s.arvalid,
			s_axi_lite_arready => mm_s2m.arready,
		
			-- slave axi-lite write data channel signals
			s_axi_lite_wdata => mm_m2s.wdata,
			s_axi_lite_wvalid => mm_m2s.wvalid,
			s_axi_lite_wready => mm_s2m.wready,
			
			-- slave axi-lite read data channel signals
			s_axi_lite_rdata => mm_s2m.rdata,
			s_axi_lite_rvalid => mm_s2m.rvalid,
			s_axi_lite_rready => mm_m2s.rready,
		
			-- slave axi-lite write response channel signals
			s_axi_lite_bvalid => mm_s2m.bvalid,
			s_axi_lite_bready => mm_m2s.bready
		);

	test_runner_watchdog(runner, 1 ms);
	main : process
		procedure read_ts(
			hi_word : std_logic_vector(CSR_DATA_WIDTH - 1 downto 0);
			lo_word : std_logic_vector(CSR_DATA_WIDTH - 1 downto 0)
		) is
		begin
			read_csr(0, lo_word, mm_m2s, mm_s2m);
			read_csr(1, hi_word, mm_m2s, mm_s2m);
		end procedure;

		variable msg : msg_t;

	begin
		test_runner_setup(runner, runner_cfg);
		wait until rst = '0';

		if run("read_early") then
			read_ts(x"00000000", x"00000000");	-- expect x"00_00_00_00_00_00_00_00"
			wait_clk_cyc(clk, 5);
			read_ts(x"00000000", x"00000007");	-- expect x"00_00_00_00_00_00_00_07
			wait_clk_cyc(clk, 5);

		elsif run("read_later") then
			wait_clk_cyc(clk, 2000);
			read_ts(x"00000000", x"000004df");	-- expect x"00_00_00_00_00_00_04_DF"
			wait_clk_cyc(clk, 5000);
			read_ts(x"00000000", x"0000111a");	-- expect x"00_00_00_00_00_00_11_1A"
			wait_clk_cyc(clk, 10000);
			read_ts(x"00000000", x"0000298a");	-- expect x"00_00_00_00_00_00_29_8A"
			wait_clk_cyc(clk, 5);
		end if;

		wait for 1 us;
		msg := new_msg(end_msg);
		send(net, cmp_recv, msg);
		test_runner_cleanup(runner);
	end process main;

end architecture;
