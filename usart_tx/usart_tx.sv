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
logic [COUNTER_WIDTH - 2:0]	clock_counter;

logic [7:0] latched_data_byte;
logic [2:0] bit_index;
logic start_fast_trigger;

logic enable_sync_clock_driver;

logic previous_usart_tx_clock;

logic initial_bit_sync_delay;

usart_state_t usart_state;
usart_state_t next_usart_state;

logic sync_clock_rising_edge;
logic sync_clock_switched;


`include "usart_tx_async.svh"
`include "usart_tx_legacy.svh"
`include "usart_tx_spi.svh"
`include "usart_tx_sync.svh"
`include "usart_tx_util_pkg.svh"

always_comb begin
	always_comb_defaults();
	if (usart_tx_clock_o && !previous_usart_tx_clock) begin
		sync_clock_rising_edge = 1;
	end else begin
		sync_clock_rising_edge = 0;
	end 
	case (TRANSMITTER_MODE)
		ASYNCHRONOUS_UART: begin
			async_mode_state_machine();
		end
		LEGACY_SYNCHRONOUS: begin
			legacy_sync_mode_state_machine();
		end
		SPI_MASTER_SYNCHRONOUS: begin
		end
	endcase
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

			if (!ready_flag_o) begin
				if (baud_counter < CLOCKS_PER_BIT && start_fast_trigger != 1'd1) begin
					baud_counter <= baud_counter + 1'd1;
					if (bit_index == 0 && next_usart_state == FSM_DATA) latched_data_byte <= data_byte_i;
					case (TRANSMITTER_MODE)
						ASYNCHRONOUS_UART: begin
							async_tx();
						end
						LEGACY_SYNCHRONOUS: begin
							synchronous_clock_driver();
							legacy_synchronous_tx();
						end
						SPI_MASTER_SYNCHRONOUS: begin
							synchronous_clock_driver();
							spi_master_tx();
						end
					endcase

				end else begin
					baud_counter <= '0;
					case (TRANSMITTER_MODE)
						ASYNCHRONOUS_UART: begin
							usart_state <= next_usart_state;
							bit_index_handler();
						end
						LEGACY_SYNCHRONOUS: begin
							if (next_usart_state == FSM_FIRST_BIT_INIT) baud_counter <= CLOCKS_PER_BIT / 2;
							if (usart_state <= FSM_START) usart_state = next_usart_state;		
						end
					endcase
				end
			end
		end
	end
end

// ALWAYS_COMB FUNCTIONS

function void always_comb_defaults();
	start_fast_trigger = '0;
	ready_flag_o = '0;
	next_usart_state = usart_state;
endfunction

// ALWAYS_FF FUNCTIONS

function void initialize_on_reset();
	usart_state <= FSM_IDLE;
	bit_index <= '0;
	baud_counter <= '0;
	latched_data_byte <= '0;
	usart_tx_o <= 1'd1;
	sync_clock_switched <= '0;
	usart_tx_clock_o <= '0;
	chip_select_registers_o <= '{default:1'd1};
endfunction

endmodule
