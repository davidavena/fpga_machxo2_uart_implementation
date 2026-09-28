package uart_types_pkg;

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
	} uart_state_t;

endpackage