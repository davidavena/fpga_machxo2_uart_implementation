import uart_types_pkg::*;

module uart_tx #(
	parameter int 				BAUD_RATE 	= 9600,
	parameter parity_config_t 	PARITY 		= NONE,
	parameter int 				CLOCK_FREQ 	= 2_080_000
) (
	input logic 				clock_i,
	input logic 				reset_i,
	input logic 				transmit_flag_i,
	input logic [7:0] 			data_byte_i,

	output logic				uart_tx_o,
	output logic 				ready_flag_o
);

localparam int 					CLOCKS_PER_BIT = (CLOCK_FREQ / BAUD_RATE) - 1;
localparam int 					COUNTER_WIDTH = (CLOCKS_PER_BIT <= 1) ? 1 : $clog2(CLOCKS_PER_BIT + 1);

logic [COUNTER_WIDTH - 1:0] 	baud_counter;

logic [7:0] latched_data_byte;
logic [2:0] bit_index;

logic start_fast_trigger;
uart_state_t uart_state;
uart_state_t next_state;

always_comb begin
	start_fast_trigger = '0;
	ready_flag_o = '0;
	uart_tx_o = 1'b1;
	next_state = uart_state;
	
	case (uart_state)
		// UART IDLE
		FSM_IDLE: begin
			ready_flag_o = 1'b1;
			if (transmit_flag_i == 1'b1) begin
				start_fast_trigger = 1'b1;
				next_state = FSM_START;
			end 
			else begin
				start_fast_trigger = '0;
				next_state = FSM_IDLE;
			end
		end
		// UART START
		FSM_START: begin
			uart_tx_o = '0;
			next_state = FSM_DATA;
		end
		// UART DATA
		FSM_DATA: begin
			uart_tx_o = latched_data_byte[bit_index];
			if (bit_index == 3'd7) begin
				if (PARITY == NONE) begin
					next_state = FSM_STOP;
				end
				else begin
					next_state = FSM_PARITY;
				end
			end
			else begin
				next_state = FSM_DATA;
			end
		end
		// UART PARITY BIT
		FSM_PARITY: begin
			next_state = FSM_STOP;
			if (PARITY == EVEN) begin
				uart_tx_o = ^latched_data_byte;
			end
			else begin
				uart_tx_o = ~^latched_data_byte;
			end
		end
		// UART STOP
		FSM_STOP: begin
			uart_tx_o = 1'b1;
			next_state = FSM_IDLE;
		end
	endcase
end

always_ff @(posedge clock_i) begin
	// RESET CONDITION
	if (!reset_i) begin
		uart_state <= FSM_IDLE;
		bit_index <= '0;
		baud_counter <= '0;
		latched_data_byte <= '0;
	end
	else begin
		if (baud_counter < CLOCKS_PER_BIT && ready_flag_o == 0 && start_fast_trigger != 1) begin
			baud_counter <= baud_counter + 1'd1;
		end
		else begin
			if (next_state == FSM_START) begin
				latched_data_byte <= data_byte_i;
			end
			baud_counter <= '0;
			uart_state <= next_state;
			case (uart_state)
				FSM_DATA: begin
					if (bit_index == 3'd7) begin
						bit_index <= '0;
					end
					else begin
						bit_index <= bit_index + 1'd1;
					end
				end
			endcase
		end
	end
end

endmodule