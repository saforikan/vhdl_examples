library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sim is
	procedure wait_clk_cyc(signal clk : in std_logic; constant num : in integer := 1);
end package sim;

package body sim is

	procedure wait_clk_cyc(signal clk : in std_logic; constant num : in integer := 1) is
	begin
		for i in 1 to num loop
			wait until rising_edge(clk);
		end loop;
	end procedure;

end package body sim;

