/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/*! Constants that the represent the Valentine One's display state */
typedef enum ESPDisplayState
{
    /// Indicates the Valentine One's display is off
	ESPDisplayStateOff = 0,
    /// Indicates the Valentine One's display is blinking
	ESPDisplayStateBlinking = 1,
    /// Indicates the Valentine One's display is on
	ESPDisplayStateOn = 2
} ESPDisplayState;

typedef Byte ESPV1Mode;
/// Constant that represents the Valentine operating mode is unknown
static const ESPV1Mode ESPV1ModeUnknown = 0;
/// Constant that represents the Valentine operating mode is either 'A' if using a USA profile or 'K & Ka' if using a Euro profile
static const ESPV1Mode ESPV1ModeAllBogeysOrKKa = 1;
/// Constant that represents the Valentine operating mode is little 'L' if using a USA profile or 'Ka' if using a Euro profile
static const ESPV1Mode ESPV1ModeLogicOrKa = 2;
/// Constant that represents the Valentine operating mode is big 'L'
static const ESPV1Mode ESPV1ModeAdvancedLogic = 3;

/*! Tells whether the given mode is a valid mode to set the V1 to
	@param mode the mode the evaluate
	@returns YES if the mode is valid, or NO if the mode is not valid */
BOOL ESPV1Mode_isValidMode(ESPV1Mode mode);

/*!
 *  ESPDisplayData
 *
 *  Discussion:
 *      A packet that represents an 'InfDisplayData' received from the Valentine One. You can use the data from this packet to recreate the Valentine One's display.
 */
@interface ESPDisplayData : NSObject

-(id)init __attribute__((unavailable("You must use initWithData: or initWithDisplayData:")));

/*! Initializes the display data from a received packet's payload
	@param data the payload data of an infDisplayData packet
	@returns a newly initialized display data object */
-(id)initWithData:(NSData*)data;
/*! Initialized the display data by copying from an existing display data object
	@param displayData the display data to copy from
	@returns a newly initialized display data object */
-(id)initWithDisplayData:(ESPDisplayData*)displayData;

/// The full payload data of the display data
@property (nonatomic, readonly) NSData* data;

/// Top segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentA;
/// Upper right segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentB;
/// Lower right segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentC;
/// Bottom segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentD;
/// Lower left segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentE;
/// Upper left segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentF;
/// Middle segment of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState segmentG;
/// Decimal point of the seven segment display on the ESP device
@property (nonatomic, readonly) ESPDisplayState decimalPoint;

/*! Tells whether the specified bargraph strength light is on
	@param index the index of the strength light
	@returns YES if the light is on, NO if the light is off */
-(BOOL)strengthLightAtIndex:(NSUInteger)index;
/// The total number of strength lights on the ESP device (8)
@property (nonatomic, readonly) NSUInteger strengthLightCount;

/// The state of bargraph strength light 0
@property (nonatomic, readonly) BOOL strengthLight0;
/// The state of bargraph strength light 1
@property (nonatomic, readonly) BOOL strengthLight1;
/// The state of bargraph strength light 2
@property (nonatomic, readonly) BOOL strengthLight2;
/// The state of bargraph strength light 3
@property (nonatomic, readonly) BOOL strengthLight3;
/// The state of bargraph strength light 4
@property (nonatomic, readonly) BOOL strengthLight4;
/// The state of bargraph strength light 5
@property (nonatomic, readonly) BOOL strengthLight5;
/// The state of bargraph strength light 6
@property (nonatomic, readonly) BOOL strengthLight6;
/// The state of bargraph strength light 7
@property (nonatomic, readonly) BOOL strengthLight7;

/// The display state of the laser "band"
@property (nonatomic, readonly) ESPDisplayState laser;
/// The display state of the Ka band
@property (nonatomic, readonly) ESPDisplayState Ka;
/// The display state of the K band
@property (nonatomic, readonly) ESPDisplayState K;
/// The display state of the X band
@property (nonatomic, readonly) ESPDisplayState X;

/// The display state of the front arrow
@property (nonatomic, readonly) ESPDisplayState front;
/// The display state of the side arrow
@property (nonatomic, readonly) ESPDisplayState side;
/// The display state of the rear arrow
@property (nonatomic, readonly) ESPDisplayState rear;

/// Tells the current mute status. (NO means not muted, YES means muted)
@property (nonatomic, readonly) BOOL soft;
/// Tells the accessories if a time slice is allowed. (NO means that all accessories can have a time slice after this packet, YES means that none of the accessories can have a time slice after this packet)
@property (nonatomic, readonly) BOOL tsHoldoff;
/// Tells whether the ESP device is actively searching for alerts. (NO means the device is not actively searching for alerts, YES means that the device has successfully signed on and is actively searching for alerts)
@property (nonatomic, readonly) BOOL systemStatus;
/// Tells the ESP device's front display status (NO means off, YES means on)
@property (nonatomic, readonly) BOOL displayOn;
/// Tells whether euro mode is enabled (NO means disabled, YES means enabled)
@property (nonatomic, readonly) BOOL euroMode;
/// Tells the custom sweep status (NO means custom sweeps have not been defined, YES means that custom sweeps have been defined and custom modes will be used if in euro mode)
@property (nonatomic, readonly) BOOL customSweep;
/// Tells whether the ESP device is operating in legacy mode (NO means normal operation, YES means legacy mode)
@property (nonatomic, readonly) BOOL legacy;

/// Tells the current mode of the V1. The mode is determined by reading the seven segment display data and the systemStatus bit. If the mode cannot be determined from the seven segment display, the mode is ESPV1ModeUnknown
@property (nonatomic, readonly) ESPV1Mode mode;

/// Tells whether the V1 is indicating a junk signal. This is determined by reading the seven segment display data and the systemStatus bit.
@property (nonatomic, readonly) BOOL junk;
/// Tells whether the V1 is indicating an error. This is determined by reading the seven segment display state, the strength lights, and the arrow lights.
@property (nonatomic, readonly) BOOL error;

/// @verbatim Method to determine if a "laser" alert is present. This value is determined by a bit-wise AND of the laser property and systemStatus and front or rear properties.
-(BOOL)isLaserAlerting;


@end
