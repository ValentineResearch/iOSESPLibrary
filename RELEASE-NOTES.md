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
# **ESP Library v2.0.1 – March 19, 2021**
* Added ESP Specification (3.006)
* Refactored for extendability

# **ESP Library2 v2.0.2 - October 29, 2021**
*Added support for remoting adjusting the V1 Gen2's volume settings. **(Only supported on versions V4.1027 and above)**

# **ESP Library2 v2.0.3 - September 19, 2023**
*Added support for the Ka Always Radar Priority and Fast Laser Detection features. **(Only supported on versions V4.1031 and above)**

# **ESP Library2 v2.0.4 – March 4, 2024**
* Added support for setting Ka sensitivity in the User Bytes. **(Only supported on versions V4.1032 and above)**
* Added support for detecting junked out alerts in respAlertData. **(Only supported on versions V4.1031 and above)**
* Added support for leaving the Bluetooth indicator on when turning off the main display on the V1 Gen2. **(Only supported on versions V4.1031 and above)**

# **ESP Library2 v2.0.5 – September, 2024**
* Added support for turning the Startup Sequence on or off. **(Only supported on versions V4.1035 and above)**
* Added support for turning the Resting Display on or off. **(Only supported on versions V4.1035 and above)**
* Added support for turning BSM Plus on or off. **(Only supported on versions V4.1035 and above)**

# **ESP Library2 v2.0.6 – December, 2024**
* Added support for the Tech Display. This includes adding a user bytes object for the Tech Display and providing the option to specify a target device on some existing functions.
* Added support for turning Auto Mute on or off. **(Only supported on versions V4.1036 and above)**
* Added support for displaying the current volume setting on the V1. **(Only supported on versions V4.1036 and above)**

# **ESP Library2 v2.0.7 - September, 2025**
* Added support for Photo radar settings in the user bytes **(Only supported on versions V4.1037 and above)**
* Added support for Photo radar type identification in the alert data **(Only supported on versions V4.1037 and above)**
* Added support for adjusting X and K band sensitivity **(Only supported on versions V4.1037 and above)**
* Added support for reading the saved and temporary volume together in the reqAllVolume packet. Temporary volume changes can be made be clearing the Save Volume bit in Aux 0 of the reqWriteVolume packet **(Only supported on versions V4.1037 and above)**
* Added the display active flag to the infDisplayData packet to indicate when the V1 display is active, or not "resting" **(Only supported on versions V4.1037 and above)**
* Added support for the resting display feature on the Tech Display **(Only supported on versions T1.0001 and above)**
* Added support for the extended frequency timeout feature on the Tech Display **(Only supported on versions T1.0001 and above)**

# **ESP Library2 v2.0.8 - September, 2025**
* Fixed an issue causing alerts on V1 Gen1 versions to be reported as photo**

