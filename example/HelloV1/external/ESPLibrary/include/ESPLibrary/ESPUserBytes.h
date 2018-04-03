/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

typedef enum
{
	ESPBargraphSensitivityResponsive = 0,
	ESPBargraphSensitivityNormal = 1
} ESPBargraphSensitivity;

typedef enum
{
	ESPMuteVolumeZero = 0,
	ESPMuteVolumeLever = 1,
} ESPMuteVolumeState;

typedef enum
{
	ESPPostMuteBogeyLockVolumeLever = 0,
	ESPPostMuteBogeyLockVolumeKnob = 1
} ESPPostMuteBogeyLockVolumeState;

typedef enum
{
	ESPKMuteTimer3 = 0b000,
	ESPKMuteTimer4 = 0b100,
	ESPKMuteTimer5 = 0b010,
	ESPKMuteTimer7 = 0b110,
	ESPKMuteTimer10 = 0b111,
	ESPKMuteTimer15 = 0b001,
	ESPKMuteTimer20 = 0b101,
	ESPKMuteTimer30 = 0b011
} ESPKMuteTimerValue;

/*! Converts a KMuteTimerValue enum to an unsigned integer with the value of the number of seconds that the enum value represents
	@param value the KMuteTimerValue to convert to seconds
	@returns an unsigned integer representing a number of seconds */
NSUInteger ESPKMuteTimerValue_toSeconds(ESPKMuteTimerValue value);
/*! Converts an unsigned integer to the closest KMuteTimerValue. Values are rounded up.
	@param seconds the number of seconds in the K mute timer
	@returns a KMuteTimerValue enum */
ESPKMuteTimerValue ESPKMuteTimerValue_fromSeconds(NSUInteger seconds);

//! The "user bytes" of an ESP device. For more info on the V1's internal settings, see http://www.valentine1.com/Lab/techreport3.asp
@interface ESPUserBytes : NSObject

/*! Initializes user bytes with default values
	@returns a newly initialized user bytes object */
-(id)init;
/*! Initializes user bytes with the payload data of a received packet
	@param data the payload data from a respUserBytes or reqWriteUserBytes packet
	@returns a newly initialized user bytes object */
-(id)initWithData:(NSData*)data;
/*! Initializes user bytes by copying data from another user bytes object
	@param userBytes the user bytes to copy from
	@returns a newly initialized user bytes object */
-(id)initWithUserBytes:(ESPUserBytes*)userBytes;

/*! Tells whether the the user bytes are equal to another set of user bytes
	@param userBytes the user bytes to compare
	@returns YES if equal, NO if not equal */
-(BOOL)isEqualToUserBytes:(ESPUserBytes*)userBytes;

/*! Sets all the user bytes back to 0xFF, the default value */
-(void)resetToDefaults;

//! The full payload data of the user bytes
@property (nonatomic, readonly) NSData* data;

//! Toggles X band detection
@property (nonatomic) BOOL XBandOn;
//! Toggles K band detection
@property (nonatomic) BOOL KBandOn;
//! Toggles Ka band detection
@property (nonatomic) BOOL KaBandOn;
//! Toggles laser detection
@property (nonatomic) BOOL laserOn;
//! Adjusts the response of the signal-strength meter for Ka band
@property (nonatomic) ESPBargraphSensitivity bargraphSensitivity;
//! Toggles the Ka False-Alarm Guard feature
@property (nonatomic) BOOL KaFalseGuardOn;
//! Toggles initial muting of K-band under certain circumstances
@property (nonatomic) BOOL KMutingOn;
//! Controls whether muted volume can be adjusted via the control lever on the V1
@property (nonatomic) ESPMuteVolumeState muteVolumeState;
//! Controls how the volume of any Bogey Lock Tones are adjusted after pressing mute
@property (nonatomic) ESPPostMuteBogeyLockVolumeState postMuteBogeyLockVolumeState;
//! Sets a time period of automatic muting of K-band alerts
@property (nonatomic) ESPKMuteTimerValue KMuteTimer;
//! Toggles an automatic override of the K mute timer if the K-band signal strength exceeds 4 LEDs
@property (nonatomic) BOOL KInitialUnmute4LightsOn;
//! Toggles an automatic override of the K mute timer if the K-band signal strength slowly rises to 6 LEDs
@property (nonatomic) BOOL KPersistantUnmute6LightsOn;
//! Toggles automatic muting of K-band alerts from the rear
@property (nonatomic) BOOL KRearMuteOn;
//! Toggles Ku band detection
@property (nonatomic) BOOL KuBandOn;
//! Toggles POP radar detection
@property (nonatomic) BOOL popOn;
//! Toggles Euro Mode
@property (nonatomic) BOOL euroOn;
//! Toggles Euro X band detection
@property (nonatomic) BOOL euroXBandOn;
//! Toggles the Traffic Monitor Filter/Junk-K Fighter
@property (nonatomic) BOOL filterOn;
//! Toggles forced Legacy (pre-ESP) Concealed Display operation
@property (nonatomic) BOOL forceLegacyCD;

@end
