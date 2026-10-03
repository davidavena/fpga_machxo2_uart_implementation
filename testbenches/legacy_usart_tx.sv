`timescale 1ns/1ps

import usart_types_pkg::*;

module legacy_usart_tx_tb();

logic clock_i;
logic reset_n_i;
logic module_enable_i;
logic tx_transmit_flag;
logic [7:0] tx_data;


logic usart_tx_o;
logic usart_tx_clock_o;
logic tx_ready_flag;

usart_tx #(
	.BAUD_RATE(115200),
	.PARITY(NONE),
	.CLOCK_FREQ(38000000),
    .CLOCK_POLARITY(CPOL_0),
    .CLOCK_PHASE(CPHA_0),
    .TRANSMITTER_MODE(LEGACY_SYNCHRONOUS)
) usart_tx_module (
	.clock_i(clock_i),
	.reset_n_i(reset_n_i),
	.module_enable_i(module_enable_i),
	.transmit_flag_i(tx_transmit_flag),
	.data_byte_i(tx_data),
	
	.usart_tx_o(usart_tx_o),
    .usart_tx_clock_o(usart_tx_clock_o),
	.ready_flag_o(tx_ready_flag)
);

initial begin
    clock_i = 0;
    reset_n_i = 0;
    module_enable_i = 1;
    tx_transmit_flag = 0;

    #500
    reset_n_i = 1;
    tx_data = 8'b10100101;

    #500
    tx_transmit_flag = 1;

    #1000
    tx_transmit_flag = 0;

    #1_000_000
    $finish;

end

always #13.158 clock_i = ~clock_i;

endmodule