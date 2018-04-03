/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ESPPacket.h"
#import "ESPAlertData.h"
#import "ESPUserBytes.h"
#import "ESPDisplayData.h"
#import "ESPCustomSweepData.h"
#import "ESPSavvyStatus.h"
#import "ESPFrequencyRange.h"

/*! Constants that represent ESP devices identifiers; these can be used to target a specific ESP device when requesting ESP data. */
typedef enum
{
	ESPRequestTargetValentineOne = 00,
	ESPRequestTargetConcealedDisplay = 01,
	ESPRequestTargetRemoteAudio = 02,
	ESPRequestTargetSavvy = 03,
	ESPRequestTargetV1ConnectionLE = 04,
	ESPRequestTargetThirdParty1 = 97,
	ESPRequestTargetThirdParty2 = 98,
	ESPRequestTargetThirdParty3 = 99
} ESPRequestTarget;

extern NSString* const ESPRequestErrorDomain;

/*!
 * Error codes that may occur when requesting data from the ESPClient.
 */
enum ESPRequestErrorCode
{
	/*! No response was received from the target device */
	ESPRequestErrorCodeNoResponse = 151,
	/*! The request could not be sent */
	ESPRequestErrorCodeNotSent = 152,
	/*! The received data was not in the correct format, or was missing parts */
	ESPRequestErrorCodeReceivedBrokenData = 153,
	/*! The request could not be processed by the target device, likely because the device's busy queue is full */
	ESPRequestErrorCodeNotProcessed = 154,
	/*! A packet sent by the request is not supported by the target device */
	ESPRequestErrorCodeUnsupportedPacket = 155,
	/*! A sent packet was malformed */
	ESPRequestErrorCodeDataError = 156,
	/*! The client has been disconnected from the ESP device */
	ESPRequestErrorCodeDisconnected = 157
};
@class ESPClient;

/*! Receives events from an ESPClient object */
@protocol ESPClientDelegate <NSObject>

@optional

/*! Invoked when an ESP packet is received. This method is called for every received packet, and can be used to get the full information from each received packet.
	@param client the client handling communication
	@param packet the received ESP packet */
-(void)espClient:(ESPClient*)client didReceivePacket:(ESPPacket*)packet;

/*! Invoked when a display data packet is received.
	@param client the client handling communication
	@param displayData the display data packet */
-(void)espClient:(ESPClient*)client didReceiveDisplayData:(ESPDisplayData*)displayData;
/*! Invoked when an entire alert table is received.
	@param client the client handling communication
	@param alertTable an array of ESPAlertData objects representing an alert table */
-(void)espClient:(ESPClient*)client didReceiveAlertTable:(NSArray<ESPAlertData*>*)alertTable;

/*! Invoked when legacy mode is either enabled or disabled on the ESP device. Legacy mode is assumed to be disabled by default.
	@param client the client handling communication
	@param legacyEnabled a BOOL representing whether legacy is enabled (YES) or disabled (NO) */
-(void)espClient:(ESPClient*)client didSetLegacyEnabled:(BOOL)legacyEnabled;

/*! Called when no packets have been received from a connected ESP device after 5 seconds.
	@param client the client handling communication */
-(void)espClientDidDetectPowerLoss:(ESPClient*)client;

@end

/*!
 *  ESPClient
 *
 *  Discussion:
 *    Class used for interacting with an ESP device. This class is responsible for receiving and dispatching ESP packets.
 */
@interface ESPClient : NSObject <CBPeripheralDelegate>

/*! Send an ESPPacket to the ESP device.
	@param packet the packet to send
	@returns YES if the packet was sent, or NO if the packet was too large or if the client was not connected */
-(BOOL)sendPacket:(ESPPacket*)packet;
/*! Send data to the ESP device.
	@param data the data to send
	@returns YES if the data was sent, or NO if the data was too large or if the client was not connected */
-(BOOL)sendData:(NSData*)data;


/*! This method is called whenever a valid ESPPacket is received. This method forwards received packets to their delegate methods, so the super method should be called when overriding.
	@param packet the received packet */
-(void)didReceivePacket:(ESPPacket*)packet;
/*! This method is called whenever an ESPPacket with a bad checksum is received.
	@param packet the received packet */
-(void)didReceivePacketWithBadChecksum:(ESPPacket*)packet;


/*! Requests the version number of the ESP device or one of its accessories
	@param target the target to send the request to
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestVersionFrom:(ESPRequestTarget)target completion:(void(^)(NSString* version, NSError* error))completion;
/*! Requests the serial number of the ESP device or one of its accessories
	@param target the target to send the request to
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSerialNumberFrom:(ESPRequestTarget)target completion:(void(^)(NSString* serial, NSError* error))completion;


/*! Requests the user bytes of the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestUserBytesFrom:(ESPRequestTarget)target completion:(void(^)(ESPUserBytes* userBytes, NSError* error))completion;
/*! Requests the user bytes of the Valentine One
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestUserBytes:(void(^)(ESPUserBytes* userBytes, NSError* error))completion;
/*! Writes the given user bytes to the ESP device
	@param userBytes the user bytes to write
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteUserBytes:(ESPUserBytes*)userBytes target:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Writes the given user bytes to the Valentine On
	@param userBytes the user bytes to write
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteUserBytes:(ESPUserBytes*)userBytes completion:(void(^)(NSError* error))completion;


/*! Requests the ESP device or one of its accessories to set its factory default settings
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteFactoryDefaultFor:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;


/*! Writes a single sweep definition to the ESP device
	@param sweep the custom sweep to write to the device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request */
-(void)requestWriteSweepDefinition:(ESPCustomSweepData*)sweep target:(ESPRequestTarget)target;
/*! Writes a single sweep definition to the Valentine One
	@param sweep the custom sweep to write to the device */
-(void)requestWriteSweepDefinition:(ESPCustomSweepData*)sweep;
/*! Writes all the given custom sweeps to the ESP device
	@param sweeps the sweeps (frequency ranges) to write to the device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteSweepDefinitions:(NSArray<ESPFrequencyRange*>*)sweeps target:(ESPRequestTarget)target completion:(void(^)(NSUInteger writeResult, NSError* error))completion;
/*! Writes all the given custom sweeps to the Valentine One
	@param sweeps the sweeps (frequency ranges) to write to the device
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteSweepDefinitions:(NSArray<ESPFrequencyRange*>*)sweeps completion:(void(^)(NSUInteger, NSError*))completion;
/*! Requests the sweep definitions from the ESP device. Some of the definitions returned may have frequencies of (0,0). These sweeps are not used and are considered "null" sweeps.
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestAllSweepDefinitionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>* sweeps, NSError* error))completion;
/*! Requests the sweep definitions from the Valentine One. Some of the definitions returned may have frequencies of (0,0). These sweeps are not used and are considered "null" sweeps.
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestAllSweepDefinitions:(void(^)(NSArray<ESPFrequencyRange*>* sweeps, NSError* error))completion;
/*! Requests the ESP device to reset its custom sweeps to the defaults
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteDefaultSweepsFor:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Requests the Valentine One to reset its custom sweeps to the defaults
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestWriteDefaultSweeps:(void(^)(NSError* error))completion;
/*! Requests the max sweep index from the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestMaxSweepIndexFrom:(ESPRequestTarget)target completion:(void(^)(NSUInteger maxSweepIndex, NSError* error))completion;
/*! Requests the max sweep index from the Valentine One
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestMaxSweepIndex:(void(^)(NSUInteger maxSweepIndex, NSError* error))completion;
/*! Requests the available custom sweep sections from the ESP device. Some of the sections returned may have frequencies of (0,0). These sections are not used and are considered "null" sections
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSweepSectionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>* sections, NSError* error))completion;
/*! Requests the available custom sweep sections from the Valentine One. Some of the sections returned may have frequencies of (0,0). These sections are not used and are considered "null" sections
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSweepSections:(void(^)(NSArray<ESPFrequencyRange*>* sections, NSError* error))completion;
/*! Requests the default custom sweep definitions from the ESP device. Some of the definitions returned may have frequencies of (0,0). These sweeps are not used and are considered "null" sweeps
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestDefaultSweepDefinitionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>* sweeps, NSError* error))completion;
/*! Requests the default custom sweep definitions from the Valentine One. Some of the definitions returned may have frequencies of (0,0). These sweeps are not used and are considered "null" sweeps
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestDefaultSweepDefinitions:(void(^)(NSArray<ESPFrequencyRange*>* sweeps, NSError* error))completion;


/*! Requests the ESP device to turn off its main display
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestTurnOffMainDisplayFor:(ESPRequestTarget)target completion:(void(^)(BOOL displayOn, NSError* error))completion;
/*! Requests the ESP device to turn on its main display
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestTurnOnMainDisplayFor:(ESPRequestTarget)target completion:(void(^)(BOOL displayOn, NSError* error))completion;
/*! Requests the ESP device to mute the current alerts
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestMuteOnFor:(ESPRequestTarget)target completion:(void(^)(BOOL muteOn, NSError* error))completion;
/*! Requests the Valentine One to mute the current alerts
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestMuteOn:(void(^)(BOOL muteOn, NSError* error))completion;
/*! Requests the ESP device to unmute all alerts that weren't muted by the ESP device's internal logic
	@note This will not unmute a laser alert
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestMuteOffFor:(ESPRequestTarget)target completion:(void(^)(BOOL muteOn, NSError* error))completion;
/*! Requests the Valentine One to unmute all alerts that weren't muted by the Valentine One's internal logic
	@note This will not unmute a laser alert
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestMuteOff:(void(^)(BOOL muteOn, NSError* error))completion;
/*! Requests the ESP device to change its mode
	@param mode the operating mode of the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs
	@throws NSInvalidArgumentException if the given mode is ESPV1ModeUnknown
	@note the ESPV1Mode in the response callback is determined by checking the seven segment display. If the mode cannot be determined, the value of "mode" will be ESPV1ModeUnknown */
-(void)requestChangeMode:(ESPV1Mode)mode target:(ESPRequestTarget)target completion:(void(^)(ESPV1Mode mode, NSError* error))completion;
/*! Requests the Valentine One to change its mode
	@param mode the operating mode of the Valentine One
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs
	@throws NSInvalidArgumentException if the given mode is ESPV1ModeUnknown
	@note the ESPV1Mode in the response callback is determined by checking the seven segment display. If the mode cannot be determined, the value of "mode" will be ESPV1ModeUnknown */
-(void)requestChangeMode:(ESPV1Mode)mode completion:(void(^)(ESPV1Mode mode, NSError* error))completion;


/*! Requests alert data to start being received from the ESP device to the current delegate
	@see ESPClientDelegate
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestStartAlertDataFor:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Requests alert data to start being received from the Valentine One to the current delegate
	@see ESPClientDelegate
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestStartAlertData:(void(^)(NSError*))completion;
/*! Requests alert data to stop being received from the ESP device to the current delegate
	@see ESPClientDelegate
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestStopAlertDataFor:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Requests alert data to stop being received from the Valentine One to the current delegate
	@see ESPClientDelegate
	@param completion a callback called if the request is successful, if the request times out, or if an error occurs */
-(void)requestStopAlertData:(void(^)(NSError* error))completion;


/*! Requests the current battery voltage of the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetValentineOne is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestBatteryVoltageFrom:(ESPRequestTarget)target completion:(void(^)(double voltage, NSError* error))completion;
/*! Requests the current battery voltage of the Valentine One
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestBatteryVoltage:(void(^)(double voltage, NSError* error))completion;


/*! Requests the current savvy status from the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetSavvy is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSavvyStatusFrom:(ESPRequestTarget)target completion:(void(^)(ESPSavvyStatus* savvyStatus, NSError* error))completion;
/*! Requests the current savvy status from the Savvy accessory
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSavvyStatus:(void(^)(ESPSavvyStatus* savvyStatus, NSError* error))completion;
/*! Requests the current vehicle speed from the ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetSavvy is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestVehicleSpeedFrom:(ESPRequestTarget)target completion:(void(^)(NSUInteger vehicleSpeedKPH, NSError* error))completion;
/*! Requests the current vehicle speed from the Savvy accessory
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestVehicleSpeed:(void(^)(NSUInteger vehicleSpeedKPH, NSError* error))completion;


/*! Requests the thumbwheel speed of the ESP device to be overridden
	@param speedKPH the speed, in KPH, to override the thumbwheel speed. If this value is greater than or equal to 255, the savvy will mute all speeds.
	@param target the target to send the request to. Currently only ESPRequestTargetSavvy is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestOverrideThumbwheel:(NSUInteger)speedKPH target:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Requests the thumbwheel speed of the Savvy to be overridden
	@param speedKPH the speed, in KPH, to override the thumbwheel speed. If this value is greater than or equal to 255, the Savvy will mute all speeds.
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestOverrideThumbwheel:(NSUInteger)speedKPH completion:(void(^)(NSError*))completion;
/*! Enables or disables the unmute functionality of the ESP device
	@param unmuteEnabled whether or not to automatically unmute the main ESP device
	@param target the target to send the request to. Currently only ESPRequestTargetSavvy is able to handle this type of request
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSetSavvyUnmuteEnabled:(BOOL)unmuteEnabled target:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion;
/*! Enables or disables the unmute functionality of the Savvy
	@param unmuteEnabled whether or not to automatically unmute the Valentine One
	@param completion a callback called if a response is received, if the request times out, or if an error occurs */
-(void)requestSetSavvyUnmuteEnabled:(BOOL)unmuteEnabled completion:(void(^)(NSError*))completion;


/// The delegate object to receive ESPClient events
@property (nonatomic, weak) id<ESPClientDelegate> delegate;

/// the CBPeripheral object that handles the BLE connection to the ESP device
@property (nonatomic, readonly) CBPeripheral* peripheral;
/// Tells whether the ESP device is in legacy mode or not. This property may be NO by default until enough display data packets are received with the legacy bit set to confirm that the ESP device is in legacy mode
@property (nonatomic, readonly, getter=isLegacy) BOOL legacy;
/// Tells whether the ESP device uses checksums. This property may be NO by default until enough packets are recieved to tell whether the ESP device has checksums
@property (nonatomic, readonly, getter=hasChecksums) BOOL checksums;
/// Tells whether the client is connected. Once disconnected, this specific client instance will never be reconnected and the ESPScanner class must be used to connect a new client
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
/// Tells whether a power loss has been detected. This means that a packet has not been received within the powerLossTimeout. @see ESPClient::powerLossTimeout
@property (nonatomic, readonly) BOOL powerLossDetected;

/// The amount of time after receiving a packet to "detect" a power loss if no further packets are received. The default value is 5 seconds
@property (nonatomic) NSTimeInterval powerLossTimeout;
/// The amount of time to wait after a request is sent for it to time out. The default value is 5 seconds
@property (nonatomic) NSTimeInterval requestTimeout;

/// Controls whether echo packets (packets sent to the V1 that are re-sent back to the client) should be recognized or not. Default value is NO
@property (nonatomic) BOOL reportsEchoedPackets;

@end
