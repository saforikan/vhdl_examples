-- Basic code for read/write of memory mapped registers
-- To use, instantiate the package in the architecture as follows:
		-- MMAP AXI CONTROL
		-- signal mm_s2m : axi_mm_s2m_t := axi_mm_s2m_init;
		-- signal mm_m2s : axi_mm_m2s_t := axi_mm_m2s_init;

-- Tie the csr clock to the appropriate clock source, eg:
		-- csr_clk <= clk;

-- Adjust for the width of the address bus when instantiating the DUT, eg:
		-- ...
		-- s_axi_lite_awaddr => mm_m2s.awaddr(4 downto 0),
		-- s_axi_lite_awvalid => mm_m2s.awvalid,
		-- s_axi_lite_awready => mm_s2m.awready,
		-- s_axi_lite_araddr => mm_m2s.araddr(4 downto 0),
		-- ...

-- Then call read and writes as follows:
		-- read_csr(2, x"00000001", mm_m2s, mm_s2m);
		-- write_csr(1, x"0000000f", mm_m2s, mm_s2m);

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library simlib;
use simlib.sim.all;

package axi_mm_csr_pkg is
	constant ADDRESS_WIDTH : integer := 32;
	constant DATA_WIDTH : integer := 32;

	signal csr_clk : std_logic;

	type axi_mm_m2s_t is record
		awaddr : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
		awvalid : std_logic;
		araddr : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
		arvalid : std_logic;
		wdata : std_logic_vector(DATA_WIDTH -1 downto 0);
		wvalid : std_logic;
		rready : std_logic;
		bready : std_logic;
	end record;

	constant axi_mm_m2s_init : axi_mm_m2s_t := (
		awaddr => (others => '0'),
		awvalid => '0',
		araddr => (others => '0'),
		arvalid => '0',
		wdata => (others => '0'),
		wvalid => '0',
		rready => '0',
		bready => '0'
	);

	type axi_mm_s2m_t is record
		awready : std_logic;
		arready : std_logic;
		wready : std_logic;
		rdata : std_logic_vector(DATA_WIDTH -1 downto 0);
		rvalid : std_logic;
		bvalid : std_logic;
	end record;

	constant axi_mm_s2m_init : axi_mm_s2m_t := (
		awready => '0',
		arready => '0',
		wready => '0',
		rdata => (others => '0'),
		rvalid => '0',
		bvalid => '0'
	);

	-- write @value to register @addr
	procedure write_csr(addr : integer; value : std_logic_vector(DATA_WIDTH -1 downto 0);
				signal axi_m2s : out axi_mm_m2s_t; signal axi_s2m : in axi_mm_s2m_t);

	-- read register @addr and verify that it's equal to @compare
	procedure read_csr(addr : integer; compare : std_logic_vector(DATA_WIDTH -1 downto 0);
				signal axi_m2s : out axi_mm_m2s_t; signal axi_s2m : in axi_mm_s2m_t);

	-- read register @addr and verify that it's less-than-or-equal to @upr_bound
	procedure check_csr_lte(addr : integer; upr_bound : std_logic_vector(DATA_WIDTH -1 downto 0);
				signal axi_m2s : out axi_mm_m2s_t; signal axi_s2m : in axi_mm_s2m_t);

end package axi_mm_csr_pkg;

package body axi_mm_csr_pkg is

	-- write @value to register @addr
	procedure write_csr(addr : integer; 
						value : std_logic_vector(DATA_WIDTH - 1 downto 0);
						signal axi_m2s : out axi_mm_m2s_t;
						signal axi_s2m : in axi_mm_s2m_t) is
		variable rdy_a, rdy : boolean := True;
	begin
		wait_clk_cyc(csr_clk, 1);
		axi_m2s.awaddr <= std_logic_vector(to_unsigned(addr * 4, ADDRESS_WIDTH));
		axi_m2s.awvalid <= '1';
		axi_m2s.wdata <= value;
		axi_m2s.wvalid <= '1';
		wait_clk_cyc(csr_clk, 1);
		while rdy_a = True or rdy = True loop
			if axi_s2m.wready = '1' then
				axi_m2s.wvalid <= '0';
				rdy := False;
			end if;
			if axi_s2m.awready = '1' then
				axi_m2s.awvalid <= '0';
				rdy_a := False;
			end if;
			wait_clk_cyc(csr_clk, 1);
		end loop;
		wait_clk_cyc(csr_clk, 1);
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.bvalid = '0' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.bready <= '1';
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.bvalid = '0' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.bready <= '0';
		wait_clk_cyc(csr_clk, 1);
	end;

	-- read register @addr and verify that it's equal to @compare
	procedure read_csr(addr : integer;
						compare : std_logic_vector(DATA_WIDTH - 1 downto 0);
						signal axi_m2s : out axi_mm_m2s_t;
						signal axi_s2m : in axi_mm_s2m_t) is
	begin
		wait_clk_cyc(csr_clk, 1);
		axi_m2s.araddr <= std_logic_vector(to_unsigned(addr * 4, ADDRESS_WIDTH));
		axi_m2s.arvalid <= '1';
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.arready /= '1' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.arvalid <= '0';
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.rvalid /= '1' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.rready <= '1';
		check_equal(axi_s2m.rdata, compare, "csr register does not correspond with expected at register addr: " & to_string(addr));
		wait_clk_cyc(csr_clk, 1);
		axi_m2s.rready <= '0';
		wait_clk_cyc(csr_clk, 1);
	end;

	-- read register @addr and verify that it's less-than-or-equal to @upr_bound
	procedure check_csr_lte(addr : integer;
						upr_bound : std_logic_vector(DATA_WIDTH - 1 downto 0);
						signal axi_m2s : out axi_mm_m2s_t;
						signal axi_s2m : in axi_mm_s2m_t) is
	begin
		wait_clk_cyc(csr_clk, 1);
		axi_m2s.araddr <= std_logic_vector(to_unsigned(addr * 4, ADDRESS_WIDTH));
		axi_m2s.arvalid <= '1';
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.arready /= '1' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.arvalid <= '0';
		wait_clk_cyc(csr_clk, 1);
		while axi_s2m.rvalid /= '1' loop
			wait_clk_cyc(csr_clk, 1);
		end loop;
		axi_m2s.rready <= '1';
		check_relation(axi_s2m.rdata <= upr_bound, "Upper Bound exceeded");
		wait_clk_cyc(csr_clk, 1);
		axi_m2s.rready <= '0';
		wait_clk_cyc(csr_clk, 1);
	end;

end package body axi_mm_csr_pkg;
