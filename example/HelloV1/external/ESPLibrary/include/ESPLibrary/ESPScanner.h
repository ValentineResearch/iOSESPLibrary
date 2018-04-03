/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ESPClient.h"

extern NSString* const ESPScannerErrorDomain;

enum ESPScannerErrorCode
{
	//! Bluetooth low-energy is not supported on the current device
	ESPScannerErrorCodeBLEUnsupported = 101,
	//! Bluetooth is not turned on
	ESPScannerErrorCodeBLEPoweredOff = 102,
	//! The app doesn't have permission to use bluetooth
	ESPScannerErrorCodeBLENotAuthorized = 103,
	//! The ESP scanner is busy doing something else
	ESPScannerErrorCodeScannerBusy = 104,
	//! The ESP service could not be found on the CBPeripheral
	ESPScannerErrorCodeServiceNotFound = 105,
	//! Attempting to connect the peripheral timed out
	ESPScannerErrorCodeTimedOut = 106,
	//! The ESP device disconnected unexpectedly
	ESPScannerErrorCodeUnexpectedDisconnect = 107
};

@class ESPScanner;

//! Receives events from an ESPScanner object
@protocol ESPScannerDelegate <NSObject>

@optional
/*! Invoked when a scan has timed out
	@param scanner the scanner that finished */
-(void)espScannerDidTimeoutScan:(ESPScanner*)scanner;
/*! Invoked when a scan failed
	@param scanner the scanner that failed
	@param error the error describing the failure */
-(void)espScanner:(ESPScanner*)scanner didFailScanWithError:(NSError*)error;
/*! Invoked when a peripheral is discovered by the scanner
	@param scanner the scanner that discovered the peripheral
	@param peripheral the peripheral that was discovered */
-(void)espScanner:(ESPScanner*)scanner didDiscoverPeripheral:(CBPeripheral*)peripheral;
/* Invoked when ESPScanner::connectPeripheral: is called on a peripheral and it fails to connect
	@param scanner the scanner that failed
	@param peripheral the peripheral that could not be connected
	@param error the error describing the failure */
-(void)espScanner:(ESPScanner*)scanner didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error;
/*! Invoked when a peripheral has successfully connected and found the ESP service
	@param scanner the scanner that connected the peripheral
	@param client the client containing the connected peripheral */
-(void)espScanner:(ESPScanner*)scanner didConnectClient:(__kindof ESPClient*)client;
/*! Invoked when a connected ESP client/peripheral is disconnected
	@param scanner the scanner that connected the client
	@param client the client that disconnected
	@param error the error describing why the disconnection happened, or nil if the client was disconnected via ESPScanner::disconnectClient */
-(void)espScanner:(ESPScanner*)scanner didDisconnectClient:(__kindof ESPClient*)client error:(NSError*)error;

@end



//! The method to use to connect an ESPClient
typedef enum
{
	//! Allows you to manually decide which peripheral to connect to. When this mode is used, you must call ESPScanner::connectPeripheral: on your scanner object in order to connect to a discovered peripheral. By default, this mode doesn’t time out unless a timeout is given.
	ESPConnectModeManual,
	//! Automatically attempts to connect to the ESP device with the strongest RSSI after searching every 5 seconds, or the duration of the timeout if the timeout is less than 5 seconds. The default timeout for this mode is 5 seconds.
	ESPConnectModeStrongest,
	//! Automatically attempts to connect to the most recently connected ESP device that was discovered. If no recently connected ESP device is discovered before the scan times out, the scanner will attempt to connect the ESP device with the strongest RSSI. The default timeout for this mode is 5 seconds.
	ESPConnectModeRecent
} ESPConnectMode;

//! Scans for ESP devices
@interface ESPScanner : NSObject

/*! Initializes the scanner with a specified delegate
	@param delegate the delegate to receive scanner events
	@returns a newly initialized scanner */
-(id)initWithDelegate:(id<ESPScannerDelegate>)delegate;

/*! Starts scanning for ESP devices, or does nothing if already scanning. This method will not automatically connect any peripherals while scanning. Calling this method also clears any discovered peripherals. */
-(void)startScan;
/*! Starts scanning for ESP devices with a given mode, or does nothing if already scanning. Calling this method also clears any discovered peripherals.
	@param mode the mode to use while scanning to connect to an ESP device */
-(void)startScanWithMode:(ESPConnectMode)mode;
/*! Starts scanning for ESP devices and stops the scan after a given amount of time. Calling this method also clears any discovered peripherals
	@param mode the mode to use while scanning to connect to an ESP device
	@param timeout the amount of time to wait after starting the scan to stop the scan. If this value is less than or equal to 0, there is no timeout */
-(void)startScanWithMode:(ESPConnectMode)mode timeout:(NSTimeInterval)timeout;
/*! Starts scanning for the ESP device that has a UUID which matches the given UUID. If UUIDString is not nil, then peripherals will only be discovered if they match the UUID. If the ESP device with a matching UUID is found, the scanner will automatically try to connect to it. Calling this method also clears any discovered peripherals.
	@param UUIDString the UUID of the ESP device to search for, or nil to search for any ESP device
	@param timeout the amount of time to wait after starting the scan to stop the scan. If this value is less than or equal to 0, there is no timeout */
-(void)startScanForDeviceWithUUID:(NSString*)UUIDString timeout:(NSTimeInterval)timeout;
/*! Stops scanning for ESP devices, or does nothing if the scanner is not scanning */
-(void)stopScan;

/*! Connects a discovered peripheral
	@param peripheral the peripheral to connect */
-(void)connectPeripheral:(CBPeripheral*)peripheral;
/*! Disconnects the connected ESP device/peripheral and disconnects any peripheral in the process of connecting */
-(void)disconnectClient;

/*! Gives the RSSI of the specified peripheral (if the RSSI is known)
	@param peripheral the peripheral to find the RSSI of
	@returns an NSNumber representing the RSSI of the peripheral (in decibels), or nil if the RSSI is not known */
-(NSNumber*)RSSIOfPeripheral:(CBPeripheral*)peripheral;
/*! Finds the discovered peripheral with the given UUID, if it exists
	@param UUIDString the UUID of the peripheral to search for
	@returns a CBPeripheral with the given UUID, or nil if a matching peripheral could not be found */
-(CBPeripheral*)peripheralWithUUID:(NSString*)UUIDString;

/*! Clears the list of recent ESP device UUIDs. @see ESPScanner::recentDeviceUUIDs */
-(void)clearRecentUUIDs;
/*! Removes a recent device with the given UUID. @see ESPScanner::recentDeviceUUIDs
	@param UUIDString a string representing the UUID of the remembered device */
-(void)removeRecentUUID:(NSString*)UUIDString;

//! The delegate object specified to receive ESPScanner events
@property (nonatomic, weak) id<ESPScannerDelegate> delegate;
//! The class to use to instantiate the connected ESPClient
@property (nonatomic, readonly) Class clientClass;
//! Tells whether the scanner is currently scanning or not
@property (nonatomic, readonly, getter=isScanning) BOOL scanning;
//! The timestamp of when the scan began. This property is nil if the scanner is not scanning
@property (nonatomic, readonly) NSDate* scanStartDate;
//! The timeout value for the current scan, in seconds. A 0 or negative value means there is no timeout, or that the scanner is not currently scanning
@property (nonatomic, readonly) NSTimeInterval timeout;
//! Tells whether the scanner is attempting to connect a peripheral or not
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;
//! An array of the discovered peripherals
@property (nonatomic, readonly) NSArray<CBPeripheral*>* discoveredPeripherals;
//! The most recently connected to peripheral of the discovered peripherals, or nil if no recent peripheral has been discovered. This property is found by matching the first UUID in recentDeviceUUIDs with a discovered peripheral's UUID.
@property (nonatomic, readonly) CBPeripheral* mostRecentPeripheral;
//! The peripheral with the strongest signal of the discovered peripherals, or nil if no peripherals have been discovered
@property (nonatomic, readonly) CBPeripheral* strongestPeripheral;
//! The connected ESPClient, or nil if no peripheral has been connected
@property (nonatomic, readonly) __kindof ESPClient* connectedClient;
//! The NSUserDefaults used to save scanner settings. The default "suite name" is com.Valentine.ESPLibrary
@property (nonatomic, strong) NSUserDefaults* userDefaults;
//! The most recently connected to ESP devices' UUIDs, with the most recent device's UUID being the first in the array. If this array is set to an array larger than maximumRecentDevices, then elements are removed from the end of the array until its count is the same as maximumRecentDevices. This list is retrieved from and stored in the userDefaults object. @see ESPScanner::userDefaults
@property (nonatomic, copy) NSArray<NSString*>* recentDeviceUUIDs;
//! Controls whether the scanner should automatically add a device's UUID to the list of recent devices after connecting. By default this value is YES.
@property (nonatomic) BOOL automaticallyRemembersDevices;
//! The maximum number of recent devices to store. By default this value is 10 @see ESPScanner::recentDeviceUUIDs
@property (nonatomic) NSUInteger maximumRecentDevices;

@end
