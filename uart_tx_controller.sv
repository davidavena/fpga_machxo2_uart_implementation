import uart_types_pkg::*;

module uart_tx_controller #(
	parameter parity_config_t PARITY_CONFIG = NONE,	
	parameter logic [31:0] BAUD_RATE = 9600,
	parameter logic [31:0] CLOCK_FREQ = 2_080_00,
	parameter logic [7:0] FIFO_BUFFER_SIZE = 32
) (
	input logic clock_i,
	input logic reset_i,
	input logic input_data_ready_i,
	input logic [7:0] input_data_i,
	output logic uart_tx_o,
	output logic buffer_full_flag_o,
	output logic buffer_empty_flag_o
);

logic [$clog2(FIFO_BUFFER_SIZE) - 1:0] write_pointer;
logic [$clog2(FIFO_BUFFER_SIZE) - 1:0] read_pointer;
logic [7:0] fifo_buffer [0:FIFO_BUFFER_SIZE - 1];

logic tx_ready_flag;
logic tx_transmit_flag;
logic [7:0] tx_data;
logic hold_time_counter;

uart_tx #(
	.BAUD_RATE(BAUD_RATE),
	.PARITY(PARITY_CONFIG),
	.CLOCK_FREQ(CLOCK_FREQ)
) uart_tx_module (
	.clock_i(clock_i),
	.reset_i(reset_i),
	.transmit_flag_i(tx_transmit_flag),
	.data_byte_i(tx_data),
	
	.uart_tx_o(uart_tx_o),
	.ready_flag_o(tx_ready_flag)
);

always_comb begin
	buffer_empty_flag_o = '0;
	buffer_full_flag_o = '0;
	if (write_pointer == read_pointer) begin
		buffer_empty_flag_o = 1'd1;
	end 
	if (write_pointer < read_pointer) begin
		buffer_full_flag_o = 1'd1;
	end
end

always_ff @(posedge clock_i) begin
	if (!reset_i) begin
		write_pointer <= '0;
		read_pointer <= '0;
		tx_data <= '0;
		tx_transmit_flag <= '0;
		hold_time_counter <= '0;
		fifo_buffer <= '{default:'0};
	end else begin
		if (!buffer_empty_flag_o && tx_ready_flag) begin
			if (hold_time_counter == 0) begin
				tx_data <= fifo_buffer[read_pointer];
				tx_transmit_flag <= 1'd1;
			end
		end
		// assert transmit flag high for extra clock cycle
		if (tx_transmit_flag) begin
			tx_transmit_flag <= '0;
			read_pointer <= read_pointer + 1'd1;
		end
		if (!buffer_full_flag_o && input_data_ready_i) begin
			fifo_buffer[write_pointer] <= input_data_i;
			write_pointer <= write_pointer + 1;
		end
	end
end

		
endmodule