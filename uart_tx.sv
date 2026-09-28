import uart_pkg::*;

module uart_tx #(
	parameter int BAUD_RATE = 9600,
	parameter parity_config_t PARITY = NONE,
	parameter int CLOCK_FREQ = 2_080_000
) (
	output logic TX,
	input logic CLOCK,
	input logic RESET,
	input logic [7:0] DATA,
	input logic TRANSMIT,
	output logic READY
);

localparam int CLOCKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
localparam int COUNTER_WIDTH = (CLOCKS_PER_BIT <= 1) ? 1 : $clog2(CLOCKS_PER_BIT);

logic [COUNTER_WIDTH-1:0] baud_counter = 1'd0;

logic [7:0] data;
logic [2:0] bit_index = 1'd0;

logic jumpstart = 0;

uart_state_t uart_state = FSM_IDLE;
uart_state_t next_state;

always_comb begin
	jumpstart = 0;
	READY = 0;
	TX = 1;
	next_state = uart_state;
	case (uart_state)
		FSM_IDLE: begin
			READY = 1;
			if (TRANSMIT == 1) begin
				jumpstart = 1;
				next_state = FSM_START;
			end 
			else begin
				jumpstart = 0;
				next_state = FSM_IDLE;
			end
		end
		FSM_START: begin
			TX = 0;
			next_state = FSM_DATA;
		end
		FSM_DATA: begin
			TX = data[bit_index];
			if (bit_index == 7) begin
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
		FSM_PARITY: begin
			next_state = FSM_STOP;
			if (PARITY == EVEN) begin
				TX = ^data;
			end
			else begin
				TX = ~^data;
			end
		end
		FSM_STOP: begin
			TX = 1;
			next_state = FSM_IDLE;
		end
	endcase
end

always_ff @(posedge CLOCK) begin
	if (!RESET) begin
		uart_state <= FSM_IDLE;
		bit_index <= 0;
		baud_counter <= 0;
	end
	else begin
		if (uart_state == FSM_IDLE) begin
			data <= DATA;
		end
		if (baud_counter < CLOCKS_PER_BIT - 1 && READY == 0 && jumpstart != 1) begin
			baud_counter <= baud_counter + 1;
		end
		else begin
			baud_counter <= 0;
			uart_state <= next_state;
			case (uart_state)
				FSM_DATA: begin
					if (bit_index == 7) begin
						bit_index <= 0;
					end
					else begin
						bit_index <= bit_index +1;
					end
				end
			endcase
		end
	end
end

endmodule