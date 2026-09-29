`timescale 1ns/1ps

import uart_types_pkg::*;

module uart_tb();
	logic RESET = 1;
	logic clock;
	
	logic [7:0] tx_data;
	logic transmit_flag = 0;
	logic ready_flag;
	
	logic UART_LINK;
	
	uart_tx #(
		.BAUD_RATE(9600),
		.PARITY(NONE),
		.CLOCK_FREQ(38_000_000)
	) uart_tx_controller (
		.clock_i(clock),
		.reset_i(RESET),
		.transmit_flag_i(transmit_flag),
		.data_byte_i(tx_data),
		
		.uart_tx_o(UART_LINK),
		.ready_flag_o(ready_flag)
	);
	
	logic rx_i;
	logic [7:0] rx_data;
	logic data_ready_flag_o;
	logic data_valid_flag_o;
	
	uart_rx #(
		.BAUD_RATE(9600),
		.PARITY(NONE),
		.CLOCK_FREQ(38_000_000)
	) uart_rx_controller (
		.clock_i(clock),
		.reset_i(RESET),
		.uart_rx_i(UART_LINK),
		
		.data_byte_o(rx_data),
		.data_ready_flag_o(data_ready_flag_o),
		.data_valid_flag_o(data_valid_flag_o)
	);


	initial begin
		clock = 0;
		RESET = 1;
		tx_data = 8'b10101010;
		transmit_flag = 0;
		
		#5_000
		RESET = 0;
		
		#1_000
		RESET = 1;
		
		#1_000_000
		transmit_flag = 1;
		#500
		transmit_flag = 0;
		
		#5_000_000
		$finish;
	end
	
	always #13.158 clock = ~clock;
	
endmodule