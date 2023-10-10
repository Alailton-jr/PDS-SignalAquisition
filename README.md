# ADC and UART Data Logger

This is a C code project for an ADC and UART data logger. The code reads analog data from an ADC and transmits it through UART. It is designed to measure voltage and current at 6kHz.

## Features

- Data logging of voltage and current measurements.
- Usage of ADC for data acquisition.
- UART communication for data transmission.
- Written in C.
- PlatformIO compatible.

## Requirements

- [PlatformIO](https://platformio.org/)

## Installation

1. Clone or download this project.
2. Open the project folder in PlatformIO.

## Usage

1. Configure your hardware setup to connect the ADC and UART.
2. Build and upload the code to your microcontroller using PlatformIO.
3. Monitor the data using a UART terminal program.

## Configuration

You may need to adjust the following settings in the code:

- Baud rate for UART communication.
- ADC channel and reference voltage settings.
- Timer settings for data acquisition frequency.

## Contributors

- Alailton Alves

## License

This project is licensed under the [License Name].

