--------------------------------------------------------------------------------------------------------------
--
-- Description  : AXI-Lite application software interface to a timestamp counter running in a different clock domain.
--                The 64-bit timestamp counter is exposed to software through 2 x 32-bit AXI-Lite registers.
--
--                The timestamp counter clock domain crossing (CDC) is implemented by means of the "standard"
--                binary-to-gray-to-CDC-to-binary format conversion path. The timestamp counter output is Gray-coded
--                and registered at source, so the initial binary to gray conversion is not needed 'here'.
--
--                The current timestamp counter value is latched (snapped) into an output register which is
--                then read through 2 x consecutive read addresses / cycles.
--                This emulates an atomic read of the timestamp counter, i.e making sure that the counter
--                value doesn't change between the 2 x 32-bit reads.
--
-- Purpose      : To allow application software to read the current value of the timestamp counter.
--
--------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library demo;
use demo.util.bit_cdc;
use demo.format_conv.all;

entity timestamp_csr is
	generic (
		CSR_ADDR_WIDTH	: integer := 3;
		TSTAMP_WIDTH	: integer := 64
	);
	port (
		clk : in std_logic;		-- axi-lite clock
		tsclk : in std_logic;	-- timestamp clock
		rst : in std_logic;

		--tstamp_data_in  : in std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
		--tstamp_data_out : out std_logic_vector(TSTAMP_WIDTH - 1 downto 0);

		-- AXI-Lite CSR interface
		-- slave axi-lite write address channel signals
		s_axi_lite_awaddr : in std_logic_vector(2 downto 0);
		s_axi_lite_awvalid : in std_logic;
		s_axi_lite_awready : out std_logic;

		-- slave axi-lite read address channel signals
		s_axi_lite_araddr : in std_logic_vector(2 downto 0);
		s_axi_lite_arvalid : in std_logic;
		s_axi_lite_arready : out std_logic;

		-- slave axi-lite write data channel signals
		s_axi_lite_wdata : in std_logic_vector(31 downto 0);
		s_axi_lite_wvalid : in std_logic;
		s_axi_lite_wready : out std_logic;

		-- slave axi-lite read data channel signals
		s_axi_lite_rdata : out std_logic_vector(31 downto 0);
		s_axi_lite_rvalid : out std_logic;
		s_axi_lite_rready : in std_logic;

		-- slave axi-lite write response channel signals
		s_axi_lite_bvalid : out std_logic;
		s_axi_lite_bready : in std_logic
	);
end timestamp_csr;

architecture rtl of timestamp_csr is

	signal ts_bin_in : std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
	signal ts_gray_in : std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
	signal ts_cntr		: std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
	signal ts_cntr_bin_s	: std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
	-- we need to latch only half the timestamp
	signal ts_count_out	: std_logic_vector(TSTAMP_WIDTH/2 - 1 downto 0);
	signal gray_ts_data_s	: std_logic_vector(TSTAMP_WIDTH - 1 downto 0);

	-- csr control: we support 2 x 32-bit words only, so we just need to
	-- deal with a single address bit to distinguish between the two words.
	signal csr_read_address : std_logic_vector(0 downto 0);
	signal csr_write_address : std_logic_vector(0 downto 0);
	signal csr_write : std_logic;
	signal s_axi_lite_wready_i : std_logic;
	signal s_axi_lite_bvalid_i : std_logic;

	-- Synth directive:
	-- Xilinx recommends that all synchronizer flip-flops have their ASYNC_REG property set to
	-- true in order to preserve the synchronizer cells through any logic optimization during
	-- synthesis and implementation, and to optimize their placement for best Mean Time Before
	-- Failure (MTBF) statistics.
	attribute ASYNC_REG : string;
	attribute ASYNC_REG of gray_ts_data_s	: signal is "TRUE";

begin

	-----------------------------------------------------------------------------------------------
	-- Instantiate 64-Bit Timestamp Counter
	-----------------------------------------------------------------------------------------------
	tstmp_cntr : entity work.timestamp_counter
	port map (
		tsclk => tsclk,
		tsrst => rst,
		ts_bin_out => ts_bin_in,
		ts_gray_out => ts_gray_in
	);

	-- do CDC with registered gray source data & dest clock
	ts_data_sync : for i in 0 to TSTAMP_WIDTH - 1 generate
		ts_sync : bit_cdc
		port map (
			clk => clk,
			rst => rst,
			din => ts_gray_in(i),
			dout => gray_ts_data_s(i)
		);
	end generate;

	-- convert post-CDC gray data to bin
	ts_to_bin : gray_to_bin
	generic map (
		DATA_WIDTH => TSTAMP_WIDTH
	)
	port map (
		gray => gray_ts_data_s,
		bin => ts_cntr
	);

	-- register post-CDC bin data
	-- note ASYNC_REG property on ts_cntr_bin
	reg_bin_ts : process(clk, rst)
	begin
		if rst = '1' then
			ts_cntr_bin_s <= (others => '0');
		elsif rising_edge(clk) then
			ts_cntr_bin_s <= ts_cntr;
		end if;
	end process;

	--tstamp_data_out <= ts_cntr_bin_s;

	-- CONTROL AND STATUS REGISTERS (CSR)
	-- 0 [31:0] RO Timestamp[31:0]
	-- 1 [31:0] RO Timestamp[63:32]

	s_axi_lite_arready <= s_axi_lite_arvalid;
	csr_read_address <= s_axi_lite_araddr(CSR_ADDR_WIDTH - 1 downto CSR_ADDR_WIDTH - 1);
	csr_write_address <= s_axi_lite_awaddr(CSR_ADDR_WIDTH - 1 downto CSR_ADDR_WIDTH - 1);

	csr_write <= s_axi_lite_awvalid and s_axi_lite_wvalid;
	s_axi_lite_awready <= s_axi_lite_awvalid and s_axi_lite_wvalid;

	s_axi_lite_wready <= s_axi_lite_wready_i;
	s_axi_lite_bvalid <= s_axi_lite_bvalid_i;

	delay : process (clk, rst)
	begin
		if rst = '1' then
			s_axi_lite_rvalid <= '0';
		elsif rising_edge(clk) then
			if s_axi_lite_arvalid = '1' then
				s_axi_lite_rvalid <= '1';
			elsif s_axi_lite_rready = '1' then
				s_axi_lite_rvalid <= '0';
			end if;
		end if;
	end process;

	-- we don't have/need a write interface
	-- though this is what it would look like. 
	control_write : process (clk, rst)
	begin
		if rst = '1' then
			s_axi_lite_bvalid_i <= '0';
			s_axi_lite_wready_i <= '0';
		elsif rising_edge(clk) then
			s_axi_lite_wready_i <= csr_write;
			if s_axi_lite_wready_i = '1' and s_axi_lite_bvalid_i = '0' then
				s_axi_lite_bvalid_i <= '1';
			elsif s_axi_lite_bready = '1' then
				s_axi_lite_bvalid_i <= '0';
			end if;
			-- we don't have a WRITE interface
			--if csr_write = '1' then
			--	case csr_write_address is
			--		when "xxx" =>
			--		when others =>
			--	end case;
			--end if;
		end if;
	end process control_write;

	-- 'snap' the upper half of the counter when we read the lower half
	latch_on_read : process (clk, rst)
	begin
		if rst = '1' then
			ts_count_out <= (others => '0');
		elsif rising_edge(clk) then
			if s_axi_lite_arvalid = '1' and s_axi_lite_araddr(CSR_ADDR_WIDTH - 1 downto CSR_ADDR_WIDTH - 1) = "0" then
				-- we're reading timestamp[31:0], so latch timestamp[63:32]
				ts_count_out <= ts_cntr_bin_s(TSTAMP_WIDTH - 1 downto TSTAMP_WIDTH/2);
			end if;
		end if;
	end process;

	status_mux : process (csr_read_address, ts_count_out, ts_cntr_bin_s)
	begin
		s_axi_lite_rdata <= (others => '0');
		case csr_read_address is
	  		when "0" =>
				s_axi_lite_rdata <= ts_cntr_bin_s(31 downto 0);	-- live lsbits
			when "1" =>
				s_axi_lite_rdata <= ts_count_out;	-- latched msbits
			when others =>
				s_axi_lite_rdata <= x"FEC8137F";	-- default 'end-of-register-file'
		end case;
	end process status_mux;

end architecture rtl;
