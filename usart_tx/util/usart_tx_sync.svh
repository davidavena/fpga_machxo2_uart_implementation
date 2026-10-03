function void sync_shift_bit(logic value);
	case ({CLOCK_POLARITY, CLOCK_PHASE})
		{CPOL_0, CPHA_0}: begin
			if (!sync_clock_rising_edge) shift_bit_on_tx_o(value);
		end
		{CPOL_0, CPHA_1}: begin
			if (sync_clock_rising_edge) shift_bit_on_tx_o(value);
		end
		{CPOL_1, CPHA_0}: begin
			if (sync_clock_rising_edge) shift_bit_on_tx_o(value);
		end
		{CPOL_1, CPHA_1}: begin
			if (!sync_clock_rising_edge) shift_bit_on_tx_o(value);
		end
	endcase
endfunction

function void set_clock_polarity_during_idle();
	if (!enable_sync_clock_driver) begin
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

function void synchronous_clock_driver();
	if (enable_sync_clock_driver) begin
		if (clock_counter < CLOCKS_PER_BIT / 2'd2) begin
			clock_counter <= clock_counter + 1'd1;
		end else begin
			sync_clock_switched <= 1'd1;
			clock_counter <= '0;
			usart_tx_clock_o <= ~usart_tx_clock_o;
			previous_usart_tx_clock <= usart_tx_clock_o;
		end
	end
endfunction