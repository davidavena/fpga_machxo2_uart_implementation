function void async_tx();
	case (usart_state)
		FSM_IDLE: begin
			shift_bit_on_tx_o(1'd1);
		end
		FSM_START: begin
			shift_bit_on_tx_o('0);
		end
		FSM_DATA: begin
			shift_bit_on_tx_o(latched_data_byte[bit_index]);
		end
		FSM_PARITY: begin
			bit_index <= '0;
			case (PARITY)
				EVEN: begin
					shift_bit_on_tx_o(^latched_data_byte);
				end
				ODD: begin
					shift_bit_on_tx_o(~^latched_data_byte);
				end
			endcase
		end
		FSM_STOP: begin
			bit_index <= '0;
			shift_bit_on_tx_o(1'd1);
		end
	endcase
endfunction

function void async_mode_state_machine();
	case (usart_state)
			FSM_IDLE: begin
				ready_flag_o = 1'b1;
				if (transmit_flag_i == 1'b1) begin
					start_fast_trigger = 1'b1;
					ready_flag_o = '0;
					next_usart_state = FSM_START;
				end else begin
					next_usart_state = FSM_IDLE;
				end
			end
			FSM_START: begin
				next_usart_state = FSM_DATA;
			end
			FSM_DATA: begin
				next_usart_state = FSM_DATA;
				if (bit_index == 3'd7) begin
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