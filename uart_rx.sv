import uart_types_pkg::*;

module uart_rx #(
	parameter int 				BAUD_RATE 	= 9600,
	parameter parity_config_t 	PARITY 		= NONE,
	parameter int 				CLOCK_FREQ 	= 2_080_000
) (
	input logic 				clock_i,
	input logic 				reset_i,
	input logic					uart_rx_i,
	
	output logic [7:0] 		data_byte_o,
	output logic 				data_ready_flag_o,
	output logic				data_valid_flag_o
);

localparam int 					CLOCKS_PER_BIT = (CLOCK_FREQ / BAUD_RATE) - 1;
localparam int 					COUNTER_WIDTH = (CLOCKS_PER_BIT <= 1) ? 1 : $clog2(CLOCKS_PER_BIT);

logic [COUNTER_WIDTH - 1:0] 	baud_counter;

logic [2:0] bit_index;
logic current_bit;
logic input_synchronizer;
logic start_bit_triggered;
logic uart_rx_previous_bit;
logic delayTriggered;
logic correct_parity_bit;

uart_state_t uart_state = FSM_IDLE;
uart_state_t next_state;

always_comb begin
	next_state = uart_state;
	case (uart_state) 
		FSM_IDLE: begin
			if (start_bit_triggered) begin
				next_state = FSM_START;
			end else begin
				next_state = FSM_IDLE;
			end
		end
		FSM_START: begin
			next_state = FSM_DATA;
		end
		FSM_DATA: begin
			if (bit_index == 3'd7) begin
				if (PARITY == NONE) begin
					next_state = FSM_STOP;
				end else begin
					next_state = FSM_PARITY;
				end
			end else begin
				next_state = FSM_DATA;
			end
		end
		FSM_PARITY: begin
			next_state = FSM_STOP;
		end
		FSM_STOP: begin
			next_state = FSM_IDLE;
		end
	endcase
end

always_ff @(posedge clock_i) begin
	// RESET CONDITION
	if (!reset_i) begin
		bit_index <= '0;
		start_bit_triggered <= '0;
		delayTriggered <= '0;
		data_byte_o <= '0;
		baud_counter <= '0;
		data_ready_flag_o <= '0;
		data_valid_flag_o <= '0;
	end else begin
		input_synchronizer <= uart_rx_i;
		current_bit <= input_synchronizer;
		if (!start_bit_triggered) begin
			uart_rx_previous_bit <= input_synchronizer;
			if (uart_rx_previous_bit && !uart_rx_i) begin
				start_bit_triggered <= 1'd1;
				baud_counter <= CLOCKS_PER_BIT;
			end
		end else begin
			if (baud_counter < CLOCKS_PER_BIT) begin
				baud_counter <= baud_counter + 1'd1;
				case (next_state)
					FSM_DATA: begin
						if (!delayTriggered) begin
							delayTriggered <= 1'd1;
							baud_counter <= CLOCKS_PER_BIT / 2'd2;
						end
					end
				endcase
			end else begin
				uart_state <= next_state;
				baud_counter <= '0;
				case (uart_state)
					FSM_DATA: begin
						data_byte_o[bit_index] = current_bit;
						bit_index <= bit_index + 1'd1;
						if (bit_index == 3'd7) begin	
							bit_index <= '0;
						end
					end
					FSM_PARITY: begin
						automatic logic parity = ^data_byte_o;
						bit_index <= '0;
						if (PARITY == ODD && current_bit == parity) begin
							correct_parity_bit <= '0;
						end else if (PARITY == EVEN && current_bit != parity) begin
							correct_parity_bit <= '0;
						end else begin
							correct_parity_bit <= '1;
						end
					end
					FSM_STOP: begin
						start_bit_triggered <= '0;
						data_ready_flag_o = 1'd1;
						if (current_bit && correct_parity_bit) begin	
							data_valid_flag_o = 1'd1;
						end else begin
							data_valid_flag_o = '0;
						end
					end
				endcase
			end
		end
	end
end

endmodule