function void legacy_sync_mode_state_machine();
	case (usart_state)
		FSM_IDLE: begin
			ready_flag_o = 1'b1;
			if (transmit_flag_i == 1'b1) begin
				start_fast_trigger = 1'b1;
				ready_flag_o = '0;
				next_usart_state = FSM_CS;
			end else begin
				next_usart_state = FSM_IDLE;
			end
		end
		FSM_CS: begin
			next_usart_state = FSM_CLOCK_ALIGN;
		end
		FSM_CLOCK_ALIGN: begin
			next_usart_state = FSM_FIRST_BIT_INIT;
		end
		FSM_FIRST_BIT_INIT: begin
			next_usart_state = FSM_START;
		end
		FSM_START: begin
			next_usart_state = FSM_DATA;
		end
		FSM_DATA: begin
			if (bit_index == 3'd7) begin
				next_usart_state = FSM_DATA;
				case (PARITY)
					NONE: begin
						next_usart_state = FSM_STOP;
					end
					default: begin
						next_usart_state = FSM_PARITY;
					end
				endcase
			end
		end
		FSM_PARITY: begin
			next_usart_state = FSM_STOP;
		end
		FSM_STOP: begin
			next_usart_state = FSM_IDLE;
		end
	endcase
endfunction

function void legacy_sync_state_machine_handler();
	if (sync_clock_switched && !sync_clock_rising_edge) begin
		bit_index_handler();
		usart_state <= next_usart_state;
	end 
endfunction

function void legacy_synchronous_tx();
	if (sync_clock_switched) begin
		sync_clock_switched <= '0;
	end
	case (usart_state) 
		FSM_IDLE: begin
			usart_tx_o <= 1'd1;
			chip_select_registers_o <= '{default:1'd1};
		end
		FSM_CS: begin
			chip_select_registers_o[chip_index] <= '0;
		end
		FSM_CLOCK_ALIGN: begin
			usart_tx_clock_o <= '0;
		end
		FSM_FIRST_BIT_INIT: begin
			shift_bit_on_tx_o('0);
		end
		FSM_START: begin
			shift_bit_on_tx_o('0);
		end
		FSM_DATA: begin
			sync_shift_bit(latched_data_byte[bit_index]);
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
			baud_counter <= '0;
			chip_select_registers_o <= '{default:1'd1};
			usart_tx_o <= 1'd1;
		end
	endcase

	legacy_sync_state_machine_handler();
endfunction
