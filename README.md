# FPGA UART Communication Stack

Personal first RTL design project, implemented in SystemVerilog for Lattice MachXO2 FPGAs.

## Hardware

- FPGA: LCMXO2-1200HC-4TG100I
- USB to UART: FT232RL

## Main Features

- UART TX and RX
- Configurable baud rate 
- Optional parity generation and checking

## Additional Custom Features

- Custom packet framing protocol over UART
- CRC Checking
- Interfacing with typical hobbyist sensors
