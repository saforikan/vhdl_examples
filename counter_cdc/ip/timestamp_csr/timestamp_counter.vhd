--
--	64-bit Gray-coded (Hardware Timestamp) Counter
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library demo;
use demo.util.all;
use demo.format_conv.all;

entity timestamp_counter is
	generic (
		TSTAMP_WIDTH : integer := 64
	);
	port (
		tsclk : in std_logic;
		tsrst : in std_logic;
		ts_bin_out : out std_logic_vector(TSTAMP_WIDTH - 1 downto 0);
		ts_gray_out : out std_logic_vector(TSTAMP_WIDTH - 1 downto 0)
	);
end entity timestamp_counter;

architecture rtl of timestamp_counter is
	signal ts_counter : unsigned(TSTAMP_WIDTH - 1  downto 0);
	signal gray_cnt : std_logic_vector(TSTAMP_WIDTH - 1 downto 0);

begin
	tstamp_counter : process(tsclk, tsrst)
	begin
		if tsrst = '1' then
			ts_counter <= (others => '0');
		elsif rising_edge(tsclk) then
			ts_counter <= ts_counter + 1;
		end if;
	end process;

	ts_bin_out(TSTAMP_WIDTH - 1  downto 0) <= std_logic_vector(ts_counter);

	-- convert counter to gray
	to_gray : bin_to_gray generic map(DATA_WIDTH => 64)
	port map(
		bin => std_logic_vector(ts_counter),
		gray => gray_cnt
	);

	-- register gray counter output
	reg_gray : process(tsclk)
	begin
		if rising_edge(tsclk) then
			ts_gray_out <= gray_cnt;
		end if;
	end process;

end architecture;
