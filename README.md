# MAE106 Lab 2 - Data acquisition systems and filters

Code for Lab 2, written for the ESP32-C3 Super Mini. Lab directions are in `directions/mae_106_lab_2.pdf`.

## VScode setup

1. Install Visual Studio Code and the PlatformIO IDE extension (VScode will offer it as a recommended extension when you open this folder).
2. Clone or download this repo and open the `mae_106_lab_2/` folder in VScode.
3. Connect the ESP32-C3 Super Mini to the computer with a USB cable. The board, framework, and serial settings are already configured in `platformio.ini`, so you do not need to select a board manually, and PlatformIO auto-detects the communication port (COM port on Windows).

## Troubleshooting

- Plugging the USB cable in and out can solve many connection problems.
- If PlatformIO cannot find the board, the cable (make sure it supports data, not just charging) or the ESP32 itself may be bad.
- If an upload fails, hold the BOOT button while plugging in the board to put it into upload mode.

## Serial Monitor and Serial Plotter extensions

PlatformIO has no built-in serial plotter. As an alternative to copying values into Excel, separate Serial Monitor and Serial Plotter extensions can be installed in VScode the same way PlatformIO was: open the Extensions view (Ctrl + Shift + X), search for "Serial Monitor" or "Serial Plotter", and click Install.

To open the Serial Monitor, click its tab in the bottom panel (next to Terminal), choose the board's COM port and a baud rate of 115200, then click Start Monitoring. To open the Serial Plotter, press Ctrl + Shift + P to open the Command Palette and search for "Serial Plotter: Open pane", then select the same port and baud rate. Only one program can use the COM port at a time, so stop the monitor/plotter before uploading new code.
