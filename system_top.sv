import uart_pkg::*;

module system_top(
	output logic TX,
	input logic RESET
);

logic oscillator_clock;
logic transmitUART = 0;
logic [7:0] message [0:10] = {"T", "e", "s", "t", " ", "S", "t", "r", "i", "n", "g"};
logic [4:0] message_len = 12;
logic [4:0] counter = 0;
logic [7:0] uart_buffer;
logic tx_ready = 1;
logic done = 0;

OSCH #(
	.NOM_FREQ("38.00")
)	c (
	.OSC(oscillator_clock),
	.STDBY(1'b0),
	.SEDSTDBY()
);

uart_tx #(
	.BAUD_RATE(9600),
	.PARITY(NONE),
	.CLOCK_FREQ(38_000_000)
) uart_tx_controller (
	.TRANSMIT(transmitUART),
	.READY(tx_ready),
	.TX(TX),
	.RESET(RESET),
	.CLOCK(oscillator_clock),
	.DATA(uart_buffer)
);

always_ff @(posedge oscillator_clock) begin
	if (!RESET) begin
		counter <= 0;
		done <= 0;
		transmitUART <= 0;
	end
	else begin
		if (tx_ready && done != 1) begin
			uart_buffer <= message[counter];
			transmitUART <= 1;
			counter <= counter + 1;
		end
		if (counter >= message_len) begin
			transmitUART <= 0;
			done <= 1;
		end
	end
end

endmodule