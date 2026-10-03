function void spi_master_state_machine();
	case (usart_state)
		FSM_IDLE: begin
			ready_flag_o = 1'b1;
			if (transmit_flag_i == 1'b1) begin
				start_fast_trigger = 1'b1;
				next_usart_state = FSM_DATA;
			end else begin
				next_usart_state = FSM_IDLE;
			end
		end
		FSM_DATA: begin
			//usart_tx_o = latched_data_byte[bit_index];
			if (bit_index == 3'd7) begin
				next_usart_state = FSM_IDLE;
			end
		end
	endcase
endfunction

function void spi_master_tx();
endfunction

function void chip_enable_control();
	case (usart_state) 
		FSM_IDLE: chip_select_registers_o[chip_index] <= 1'd1;
	endcase
	
	case (next_usart_state)
		FSM_START: chip_select_registers_o[chip_index] <= '0;
	endcase
endfunction