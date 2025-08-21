--
-- A utility package (though it contains just a single component)
-- which does single-bit clock domain crossing (CDC).
-- CDC is achieved by passing input data from the source
-- domain through 3 x registers to the sink clock domain.
--
library ieee;
use ieee.std_logic_1164.all;

package util is
	component bit_cdc is
		generic (
			RESET_VALUE : std_logic := '0'
		);
		port (
			clk : in std_logic;
			rst : in std_logic;
			din : in std_logic;
			dout : out std_logic
		);
	end component bit_cdc;
end package util;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_cdc is
	generic (
		RESET_VALUE : std_logic := '0'
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		din : in std_logic;
		dout : out std_logic
	);
end entity bit_cdc;

architecture rtl of bit_cdc is

	signal sreg : std_logic_vector(2 downto 0);

	-- Synth directive:
	-- Xilinx recommends that all synchronizer flip-flops have their ASYNC_REG property set to
	-- true in order to preserve the synchronizer cells through any logic optimization during
	-- synthesis and implementation, and to optimize their placement for best Mean Time Before
	-- Failure (MTBF) statistics.
	attribute ASYNC_REG : string;
	attribute ASYNC_REG of sreg : signal is "TRUE";

begin

	process(clk, rst)
	begin
		if rst = '1' then
			sreg <= (others => RESET_VALUE);
		elsif rising_edge(clk) then
			sreg <= sreg(sreg'high - 1 downto 0) & din;
		end if;
	end process;
	dout <= sreg(sreg'high);

end architecture rtl;
