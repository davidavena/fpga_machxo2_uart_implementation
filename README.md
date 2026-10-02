# USART SystemVerilog Implementation

Personal first RTL design project, implemented in SystemVerilog for Lattice MachXO2 FPGAs.

Should be noted that project is currently heavily reliant on simulation.

## Hardware

- FPGA: LCMXO2-1200HC-4TG100I
- USB to UART: FT232RL

## Software
- IDE: Lattice Diamond
- Synthesis: Synplify Pro for Lattice
- Simulator: QuestaSim

## Main Features

- Selectable UART/USART TX and RX
- Configurable baud rate
- Parity checking

## Planned Features

- Custom packet framing protocol over USART
- Modbus over TTL
- CRC Checking
- Interfacing with typical hobbyist sensors

## Checklist

- ✅ UART TX/RX
- 🚧 USART TX/RX
- 🚧 Controller
- ⬛ Customizable Framing Protocol
- ⬛ CRC
- ⬛ Modbus Server
- ⬛ Modbus Client
