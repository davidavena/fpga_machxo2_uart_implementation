function void shift_bit_on_tx_o(logic value);
	usart_tx_o <= value;	
endfunction

function void bit_index_handler();
	case (usart_state)
		FSM_DATA: begin
			if (bit_index < 3'd7) bit_index <= bit_index + 1'd1;
		end
		default: begin
			if (bit_index == 3'd7) bit_index <= '0;
		end
	endcase
endfunction