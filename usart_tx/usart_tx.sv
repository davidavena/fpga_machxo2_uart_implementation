import usart_types_pkg::*;

module usart_tx #(
	parameter int 				BAUD_RATE 	= 9600,
	parameter parity_config_t 	PARITY 		= NONE,
	parameter usart_clock_polarity_t 	CLOCK_POLARITY = CPOL_0,
	parameter usart_clock_phase_t		CLOCK_PHASE = CPHA_0,
	parameter usart_mode_t 		TRANSMITTER_MODE = ASYNCHRONOUS_UART,
	parameter int 				CLOCK_FREQ 	= 2080000,
	parameter int				CHIP_SELECT_COUNT = 0
) (
	input logic 				clock_i,
	input logic 				reset_n_i,
	input logic 				module_enable_i,
	input logic 				transmit_flag_i,
	input logic [7:0] 			data_byte_i,
	input logic [$clog2(CHIP_SELECT_COUNT):0]	chip_index,

	output logic				usart_tx_o,
	output logic				usart_tx_clock_o,
	output logic [$clog2(CHIP_SELECT_COUNT):0]	chip_select_registers_o,
	output logic 				ready_flag_o
);

localparam int 					CLOCKS_PER_BIT = (CLOCK_FREQ / BAUD_RATE) - 1;
localparam int 					COUNTER_WIDTH = (CLOCKS_PER_BIT <= 1) ? 1 : $clog2(CLOCKS_PER_BIT + 1);

logic [COUNTER_WIDTH - 1:0] 	baud_counter;

logic [7:0] latched_data_byte;
logic [2:0] bit_index;

logic start_fast_trigger;
usart_state_t usart_state;
usart_state_t next_state;

always_comb begin
	always_comb_defaults();

	if (TRANSMITTER_MODE != ASYNCHRONOUS_UART) begin
		sync_mode_state_machine();
	end
	else begin
		async_mode_state_machine();
	end
end

always_ff @(posedge clock_i) begin
	// RESET CONDITION
	if (!reset_n_i) begin
		initialize_on_reset();
	end else begin
		if (module_enable_i) begin
			case (TRANSMITTER_MODE)
				ASYNCHRONOUS_UART: begin
				end
				LEGACY_SYNCHRONOUS: begin
					chip_enable_control();
					set_clock_polarity_during_idle();
				end
				SPI_MASTER_SYNCHRONOUS: begin
					chip_enable_control();
					set_clock_polarity_during_idle();
				end
			endcase

			if (baud_counter < CLOCKS_PER_BIT && ready_flag_o == 0 && start_fast_trigger != 1'd1) begin
				baud_counter <= baud_counter + 1'd1;
				case (TRANSMITTER_MODE)
					ASYNCHRONOUS_UART: begin
						async_tx();
					end
					LEGACY_SYNCHRONOUS: begin
						legacy_synchronous_tx();
					end
					SPI_MASTER_SYNCHRONOUS: begin
						spi_master_tx();
					end
				endcase

			end else begin
				baud_counter <= '0;
				usart_state <= next_state;
				bit_index_handler();
				if (bit_index == 0 && next_state == FSM_DATA) latched_data_byte <= data_byte_i;
			end
		end
	end
end

// ALWAYS_COMB FUNCTIONS

function void always_comb_defaults();
	start_fast_trigger = '0;
	ready_flag_o = '0;
	next_state = usart_state;
endfunction

function void sync_mode_state_machine();
	case (usart_state)
		FSM_IDLE: begin
			ready_flag_o = 1'b1;
			if (transmit_flag_i == 1'b1) begin
				start_fast_trigger = 1'b1;
				next_state = FSM_DATA;
			end else begin
				next_state = FSM_IDLE;
			end
		end
		FSM_DATA: begin
			//usart_tx_o = latched_data_byte[bit_index];
			if (bit_index == 3'd7) begin
				next_state = FSM_IDLE;
			end
		end
	endcase
endfunction

function void async_mode_state_machine();
	case (usart_state)
			FSM_IDLE: begin
				ready_flag_o = 1'b1;
				if (transmit_flag_i == 1'b1) begin
					start_fast_trigger = 1'b1;
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
					case (PARITY)
						NONE: begin
							next_state = FSM_STOP;
						end
						default: begin
							next_state = FSM_PARITY;
						end
					endcase
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
endfunction

// ALWAYS_FF FUNCTIONS

function void chip_enable_control();
	case (usart_state) 
		FSM_IDLE: chip_select_registers_o[chip_index] <= 1'd1;
	endcase
	
	case (next_state)
		FSM_DATA: chip_select_registers_o[chip_index] <= '0;
	endcase
endfunction

function void initialize_on_reset();
	usart_state <= FSM_IDLE;
	bit_index <= '0;
	baud_counter <= '0;
	latched_data_byte <= '0;
	chip_select_registers_o <= '{default:'0};
endfunction

function void set_clock_polarity_during_idle();
	if (usart_state == FSM_IDLE) begin
		case (CLOCK_POLARITY)
			CPOL_0: begin
				usart_tx_clock_o <= '0;
			end
			CPOL_1: begin
				usart_tx_clock_o <= 1'd1;
			end
		endcase
	end
endfunction

function void bit_index_handler();
	case (usart_state)
		FSM_DATA: begin
			if (bit_index < 7) bit_index <= bit_index + 1'd1;
		end
		default: begin
			if (bit_index == 7) bit_index <= '0;
		end
	endcase
	

endfunction

function void async_tx();
	case (usart_state)
		FSM_IDLE: begin
			usart_tx_o <= 1'd1;
		end
		FSM_START: begin
			usart_tx_o <= '0;
		end
		FSM_DATA: begin
			usart_tx_o <= latched_data_byte[bit_index];
		end
		FSM_PARITY: begin
			bit_index <= '0;
			case (PARITY)
				EVEN: begin
					usart_tx_o = ^latched_data_byte;
				end
				ODD: begin
					usart_tx_o = ~^latched_data_byte;
				end
			endcase
		end
		FSM_STOP: begin
			usart_tx_o <= 1'd1;
		end
	endcase
endfunction

function void spi_master_tx();
	
endfunction

function void legacy_synchronous_tx();
endfunction

endmodule
