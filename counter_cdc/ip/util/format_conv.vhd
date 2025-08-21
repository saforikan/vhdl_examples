--
-- Binary/Gray Format Conversion Package
--
library IEEE;
use IEEE.std_logic_1164.all;

package format_conv is
	component bin_to_gray is
		generic (
			DATA_WIDTH : integer := 64
		);
		port (
			bin : in std_logic_vector(DATA_WIDTH - 1 downto 0);
			gray : out std_logic_vector(DATA_WIDTH - 1 downto 0)
		);
	end component bin_to_gray;

	component gray_to_bin is
		generic (
			DATA_WIDTH : integer := 64
		);
		port (
			gray : in std_logic_vector(DATA_WIDTH - 1 downto 0);
			bin : out std_logic_vector(DATA_WIDTH - 1 downto 0)
		);
	end component gray_to_bin;
end package format_conv;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bin_to_gray is
	generic (
		DATA_WIDTH : integer := 64
	);
	port (
		bin : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		gray : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end entity bin_to_gray;

architecture syn of bin_to_gray is
begin
	gray <= bin xor ('0' & bin(DATA_WIDTH - 1 downto 1));
end architecture syn;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gray_to_bin is
	generic (
		DATA_WIDTH : integer := 64
	);
	port (
		gray : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		bin : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end entity gray_to_bin;

architecture syn of gray_to_bin is
	signal bin_i : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
	bin_i(DATA_WIDTH - 1) <= gray(DATA_WIDTH - 1);
	gray_gen : for i in DATA_WIDTH - 2 downto 0 generate
		bin_i(i) <= bin_i(i + 1) xor gray(i);
	end generate;
	bin <= bin_i;
end architecture syn;
