# AquisitionApp MATLAB Application

## Description
The AquisitionApp is a MATLAB application designed to interface with an Arduino board for data acquisition. It allows users to configure communication settings, acquire voltage and current data, and display the results in real-time.

## Features
- Connection to Arduino board via a COM port
- Configuration of communication settings (baud rate, data bits, stop bits)
- Asynchronous acquisition of voltage and current data
- Visualization of acquired data on plots

## Requirements
- MATLAB (R2019b or later)
- A computer with a COM port (for Arduino communication)

## Usage
1. Launch MATLAB.
2. Create an instance of the `AquisitionApp` class: 
   ```matlab
   x = AquisitionApp();
   createComponents(x);
   x.startupFcn();
