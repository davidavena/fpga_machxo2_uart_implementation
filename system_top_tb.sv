`timescale 1ns/1ps

import uart_types_pkg::*;

module system_top_tb();
	logic clock;
	logic TX;
	logic [7:0] data;
	logic TRANSMIT = 0;
	logic READY;
	logic RESET = 1;
	
	uart_tx #(
		.BAUD_RATE(9600),
		.PARITY(EVEN),
		.CLOCK_FREQ(38_000_000)
	) uart_tx_controller (
		.clock_i(clock),
		.reset_i(RESET),
		.transmit_flag_i(TRANSMIT),
		.data_byte_i(data),
		
		.uart_tx_o(TX),
		.ready_flag_o(READY)
	);

	initial begin
		data = 8'b01010101;
		clock = 0;
		TRANSMIT = 0;
		RESET = 1;
	end
	
	initial begin
		#50 
		RESET = 0;
		
		#1000
		RESET = 1;
		
		
		#1_000_000;
		TRANSMIT = 1;
		
		#100;
		TRANSMIT = 0;
		
		#3_000_000;
		RESET = 0;
		
		#1000;
		RESET = 1;
		data = 8'b10101010;
		
		#100;
		TRANSMIT = 1;
		
		#500;
		TRANSMIT = 0;
		
		#20_000_000;
		$finish;	
	end
	
	always #13.158 clock = ~clock;
	
endmodule