import usart_types_pkg::*;

module usart_rx_controller #(
	parameter parity_config_t PARITY_CONFIG = NONE,	
	parameter logic [31:0] BAUD_RATE = 9600,
	parameter logic [31:0] CLOCK_FREQ = 2_080_00,
	parameter logic [7:0] FIFO_BUFFER_SIZE = 32
) (
	input logic clock_i,
	input logic reset_n_i,
	input logic usart_rx_i,
	input logic controller_enable_i,
	input logic read_pointer_o,
	
	output logic [7:0] received_data_o [0:FIFO_BUFFER_SIZE - 1],
	output logic data_ready_o
);

logic [$clog2(FIFO_BUFFER_SIZE) - 1: 0] write_pointer;

always_comb begin
	data_ready_o = '0;
	if (write_pointer != read_pointer_o) begin
		data_ready_o = 1'd1;
	end 	
end

always_ff @(posedge clock_i) begin
end



endmodule