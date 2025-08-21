# vhdl_examples
VHDL example code

## counter_cdc
Clock domain crossing (CDC) of a 64-bit (e.g. timestamp) counter.

The primary module is located in the 'ip/timestamp_csr/' folder which contains the following files:
- timestamp_counter.vhd
	Implements a 64-bit counter which runs in the 'tsclk' domain and emits both binary and registered gray-coded outputs.

- timestamp_csr.vhd
	The 'top-level' module runs in the 'csr_clk' domain and integrates the timestamp counter module.
	It performs a CDC of the gray-coded counter output and makes the counter value available as 2 x
	32-bit words through an AXI_Lite (memory-mapped) interface.
	s 
	This module imptm.

- timestamp_csr_tb.vhd
	A testbench, based on the VUnit unit testing framework and the GHDL simulator.
	It supports two relatively simple test cases, to demonstrate the test infrastructure, rather than
	test coverage per se.

- timestamp_csr_tb_read_early.gtkw and timestamp_csr_tb_read_later.gtkw
	Simulation waveforms of the two test cases, viewable with a VCD viewer such as GTKWave.
	
The 'ip/util/' folder contains two utility packages, in support of CDC binary/gray format
conversion, while the 'ip/sim' folder contains support packages for testing the AXI-Lite interface.

Finally, the 'vunit' folder contains:
- run.py
	The VUnit test app
- graph.sh	
	A shell script to produce simulation waveforms for the test cases.

