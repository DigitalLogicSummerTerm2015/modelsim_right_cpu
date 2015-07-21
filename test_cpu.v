`timescale 1ns/1ns
module test_cpu();
	
	reg reset;
	reg clk;
	wire [7:0]led;
	wire [11:0]digi;
	wire [7:0]switch;
	wire dout;
	reg din;
	
	
	CPU cpu1(dout,led,digi,switch,din,clk,reset);
	initial begin
		reset = 1;
		clk = 0;
		
		#4 reset = 0;
		#2  reset=1;
		#3  din = 1;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 1;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 1;
		#104160 din = 1;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 1;
		#104160 din = 1;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 0;
		#104160 din = 1;
		#104160 din = 1;
		#2000000 $stop;
		
		
	end
	
	always #5 clk = ~clk;
		
endmodule
