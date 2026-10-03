package usart_types_pkg;

	typedef enum logic [1:0] {
		NONE,
		ODD,
		EVEN
	} parity_config_t;
	
	typedef enum logic [2:0] {
		FSM_IDLE,
		FSM_START,
		FSM_DATA,
		FSM_PARITY,
		FSM_STOP
	} usart_state_t;

	typedef enum logic [1:0] {
		ASYNCHRONOUS_UART,
		LEGACY_SYNCHRONOUS,
		SPI_MASTER_SYNCHRONOUS
	} usart_mode_t;

	typedef enum logic {
		CPOL_0,
		CPOL_1
	} usart_clock_polarity_t;
	
	typedef enum logic {
		CPHA_0,
		CPHA_1
	} usart_clock_phase_t;

endpackage