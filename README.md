# iOS ESP Library
The Extended Serial Protocol (ESP) is a communications protocol defined by Valentine Research. It enables two-way communication and data sharing between the Valentine One (V1) radar locator and other ESP-enabled devices. In addition to handling the setup and teardown of Bluetooth connections, this library will do the work of handling the ESP requirements and parsing the ESP packet data into a more usable format.  
## ESP iOS Basics
The main interface to the iOS ESP Library is through the ESPClient class. The ESPClient will handle all ESP packet construction and parsing. The library will use its own threads to send requests to the V1connection LE and to read the ESP data from the V1connection LE. Use the ESPScanner to initiate a scan for a V1connection LE. When a connection is established, the scanner returns a valid ESPClient instance using the register ESPScannerDelegate. Data is transferred from the library to the host app using callbacks. Continuous data, such as alert and display data, requires the app to register an ESPClientDelegate instance. The display data delegate method will be called whenever the data is received. The alert table delegate method will be called whenever a complete alert table is received, and not for each alert data received. One time data, such as a version request, does not require a separate registration method. Instead, the request method takes the completion block as a parameter.
## Sample Integration
The Hello V1 app offers a sample integration to demonstrate how easy it is to start communicating with the V1. The following functionality is demonstrated:
* Determine if the iOS device supports Bluetooth Low Energy (BLE). 
* Connect and disconnect from a V1connection LE.
* Register for display data and implement the display data callback method.
* Register for alert data and implement the alert data callback method.
* Read the firmware version and current custom sweeps from the V1. This demonstrates the techniques used to send a request to the V1 and to receive the response.
