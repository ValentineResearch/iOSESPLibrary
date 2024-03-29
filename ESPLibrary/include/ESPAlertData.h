/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPFrequency.h"

/// Constants that the represent the alert bands of alert determined by the Valentine One
typedef enum
{
	/// The band of an alert data packet with invalid band data
	ESPAlertBandInvalid = -1,
	/// "Laser" band is currently not supported by the V1
	ESPAlertBandLaser = 0x01,
    /// Ka band alert
	ESPAlertBandKa = 0x02,
    /// K band alert
	ESPAlertBandK = 0x04,
    /// X band alert
	ESPAlertBandX = 0x08,
    /// Ku band alert
	ESPAlertBandKu = 0x10,
} ESPAlertBand;

/// Constants that the represent the direction of an alert determined by the Valentine One
typedef enum
{
	/// The direction of an alert data packet with invalid direction data
	ESPAlertDirectionInvalid = -1,
    /// Front direction
	ESPAlertDirectionFront = 0x04,
    /// Side direction
	ESPAlertDirectionSide = 0x02,
    /// Rear direction
	ESPAlertDirectionRear = 0x01
} ESPAlertDirection;

/// A packet that represents an alert detected by the Valentine One.
@interface ESPAlertData : NSObject
/// Default initializer that always returns nil; DO NOT CALL
/// @see initWithData:(NSData)
-(id)init __attribute((unavailable("You must use initWithData: or initWithAlertData:")));

/// Initializes the alert from a received packet's payload
/// @param data the payload data of a respAlertData packet
/// @param version the version of the target V1
/// @return a newly initialized alert
-(id)initWithData:(NSData*)data v1Version:(NSUInteger)version;
/// Initializes a new alert by copying information from an existing alert
/// @param alert the alert to copy from
/// @return a newly initialized alert
-(id)initWithAlertData:(ESPAlertData*)alert;

/// Version of the V1 this instance of alert data belongs too
@property (nonatomic) NSUInteger v1Version;

/// Tells if the given alert is equal to this alert
/// @param alertData the alert to compare
/// @return YES if the alerts are equal, or NO if they are not equal
-(BOOL)isEqualToAlertData:(ESPAlertData*)alertData;

/// The full payload data of the alert
@property (nonatomic, readonly) NSData* data;

/// The number of alerts in the alert table
@property (nonatomic, readonly) NSUInteger count;
/// The index of the alert in the alert table
@property (nonatomic, readonly) NSUInteger index;

/// The frequency of the alert
@property (nonatomic, readonly) ESPFrequencyMHz frequency;

/// The front signal strength (0-255)
@property (nonatomic, readonly) NSUInteger frontSignalStrength;
/// The rear signal strength (0-255)
@property (nonatomic, readonly) NSUInteger rearSignalStrength;
/// The alert signal strength to use for the bargraph (0-255)
@property (nonatomic, readonly) NSUInteger alertSignalStrength;

/// The bargraph strength indicator strength (0-8)
@property (nonatomic, readonly) NSUInteger bargraphSignalStrength;

/// Tells if this alert is a priority alert
@property (nonatomic, readonly, getter=isPriority) BOOL priority;

/// Tells if this alert is was junked out
@property (nonatomic, readonly, getter=isJunkAlert) BOOL junkAlert;

/// The direction of the alert
@property (nonatomic, readonly) ESPAlertDirection direction;
/// The band of the alert
@property (nonatomic, readonly) ESPAlertBand band;

/// Represents how far an alert may deviate in its frequency
@property (nonatomic, readonly) ESPFrequencyMHz deviance;

@end
