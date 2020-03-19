# **ESP Library v2.0 – March 19, 2020**
* Added support for ESP Specification 3.005

# Library Structure
Interaction with the Valentine one and ESP devices has been localized in to a new class called ESPClient. This class is the public interface for the ESP Library. It contains all methods for exchanging ESP data with the Valentine One and its accessories.

The old callback scheme that required you to register for every packet type that you wanted to receive callbacks for has been replaced with the ESPClientDelegate. ESPClientDelegate has several delegation methods that allow for receiving display data, alert tables and other ESP data. The delegate also provides notifications when the Valentine One loses power or enters/exist Legacy mode.

In addition to the ESPClientDelegate, the ESP Library now makes extensive use of completion blocks to return responses to ESP requests. The completion block will be triggered either when the requested data has been received or in the occurrence of an error. This is often a simple way to retrieve data from the ESP bus and is the recommended technique. To find more information on the Blocking pattern visit: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html

V1connection LE Discovery
Scanning for V1connection LE devices is no longer handled by BTDiscovery. Instead, scanning and connecting functionality has been refactored to ESPScanner. Once the scanner makes a connection with a V1connection LE, it will return an ESPClient instance, using the registered ESPScannerDelegate. 
Interface Changes
* All classes have been renamed to be prefixed with ‘ESP’. For example, AlertData has been renamed to ESPAlertData.
 
| Old File	| Equivalent File |
|-----------|-----------------|
| AlertCollection.h	| No equivalent	   
| AlertData.h	| ESPAlertData.h	   
| AlertOutput.h	| No equivalent	   
| BTDiscovery.h	| No equivalent	   
| CustomSweep.h	| No equivalent	   
| CustomSweepObject.h	| ESPCustomSweepData.h	   
| DeviceInformation.h	| No equivalent	   
| DisplayAndAudio.h	| No equivalent	   
| DisplayData.h	| ESPDisplayData.h	   
| ESPPacket.h	| ESPPacket.h	   
| ESPPacketCollection.h	| No equivalent	   
| Miscellaneous.h	| No equivalent	   
| PacketAction.h	| No equivalent	   
| PacketTypes.h	| No equivalent	   
| SavvySpecific.h	| No equivalent	   
| SavvyStatus.h	| ESPSavvyStatus.h	   
| SendRequest.h	| No equivalent	   
| UserSetupOptions.h	| No equivalent	   
| ValentineCommunicationService.h	| No equivalent	   
| SendRequest.h	| No equivalent	   
| UserBytes.h	| ESPUserByte.h	 

* Methods in all data object classes have been replaced with properties. For example, UserBytes.EuroOn() has been replaced with a bool property named euroOn in the ESPUserBytes class.
* Enums throughout the library have been renamed to be prefixed with ‘ESP’.
