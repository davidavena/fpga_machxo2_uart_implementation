`timescale 1ns/1ps

import uart_types_pkg::*;

module uart_tx_controller_tb();
	
	logic clock;
	logic reset;
	logic input_data_ready;
	logic [7:0] input_data;
	
	logic UART_TX_O;
	
	
	uart_tx_controller #(
		.PARITY_CONFIG(NONE),	
		.BAUD_RATE(115_200),
		.CLOCK_FREQ(38_000_000),
		.FIFO_BUFFER_SIZE(32)
	) DUT (
		.clock_i(clock),
		.reset_i(reset),
		.input_data_ready_i(input_data_ready),
		.input_data_i(input_data),
		.uart_tx_o(UART_TX_O),
		.buffer_full_flag_o(),
		.buffer_empty_flag_o()
	);
	
	logic [7:0] test_data [0:15];
	logic [3:0] counter;
	
	initial begin
		clock = 0;
		reset = 0;
		#500
		reset = 1;
		
		
		#5_000_000
		$finish;
	end
	always_ff @(posedge clock) begin
		if (reset) begin
			if (counter < 15) begin
				input_data <= test_data[counter];
				input_data_ready <= 1'd1;
				if (input_data_ready) begin
					input_data_ready <= '0;
					counter <= counter + 1'd1;
				end
			end else begin
				input_data_ready <= '0;
			end
		end else begin
			input_data_ready <= '0;
			input_data <= '0;
			counter <= '0;
			test_data <= {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
		end
	end


	always #13.158 clock = ~clock;
	
endmodule