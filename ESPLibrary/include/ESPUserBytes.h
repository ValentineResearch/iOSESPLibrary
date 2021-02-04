/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/*! Constants that represent possible Bargraph sensitivities values */
typedef enum
{
    /// Bargraph sensitivity is Responsive = (0)
	ESPBargraphSensitivityResponsive = 0,
    /// Bargraph sensitivity is Normal = (1)
	ESPBargraphSensitivityNormal = 1
} ESPBargraphSensitivity;

/*! Constants that represent possible mute volume values */
typedef enum
{
    //* Muted volume is set to zero = (0)
	ESPMuteVolumeZero = 0,
    //* Mute volume uses the control lever = (1)
	ESPMuteVolumeLever = 1,
} ESPMuteVolumeState;

/*! Constants that represent possible Bogey-Lock Tone values after pressing mute */
typedef enum
{
    //* Bogey-Lock Tone volume uses the control lever = (0)
	ESPPostMuteBogeyLockVolumeLever = 0,
    //* Bogey-Lock Tone volume uses the control knob = (1)
	ESPPostMuteBogeyLockVolumeKnob = 1
} ESPPostMuteBogeyLockVolumeState;

/*! Constants that represent time periods in seconds of automatic muting at the of K-Band alerts  */
typedef enum
{
    //* 3 seconds of initial muting
	ESPKMuteTimer3 = 0b000,
    //* 4 seconds of initial muting
	ESPKMuteTimer4 = 0b001,
    //* 5 seconds of initial muting
	ESPKMuteTimer5 = 0b010,
    //* 7 seconds of initial muting
	ESPKMuteTimer7 = 0b011,
    //* 10 seconds of initial muting
	ESPKMuteTimer10 = 0b111,
    //* 15 seconds of initial muting
	ESPKMuteTimer15 = 0b100,
    //* 20 seconds of initial muting
	ESPKMuteTimer20 = 0b101,
    //* 30 seconds of initial muting
	ESPKMuteTimer30 = 0b110
} ESPKMuteTimerValue;

/*! Converts a KMuteTimerValue enum to an unsigned integer with the value of the number of seconds that the enum value represents
	@param value the KMuteTimerValue to convert to seconds
	@returns an unsigned integer representing a number of seconds */
NSUInteger ESPKMuteTimerValue_toSeconds(ESPKMuteTimerValue value);
/*! Converts an unsigned integer to the closest KMuteTimerValue. Values are rounded up.
	@param seconds the number of seconds in the K mute timer
	@returns a KMuteTimerValue enum */
ESPKMuteTimerValue ESPKMuteTimerValue_fromSeconds(NSUInteger seconds);

/*!
 *  ESPUserBytes
 *
 *  Discussion:
 *      The "user bytes" of an ESP device. For more info on the V1's internal settings, see http://www.valentine1.com/Lab/techreport3.asp
 */
@interface ESPUserBytes : NSObject

/*! Initializes user bytes with default values
	@returns a newly initialized user bytes object */
-(id)init;

/**
 * Initializes user bytes with default values and the provided v1 version.
 * @param version Version of the attached V1
 * @return a newly initialized user bytes object
 */
-(id)initWithV1Version:(NSUInteger)version;
/*! Initializes user bytes with the payload data of a received packet
	@param data the payload data from a respUserBytes or reqWriteUserBytes packet
    @param version the version of the target V1
	@returns a newly initialized user bytes object */
-(id)initWithData:(NSData*)data v1Version:(NSUInteger)version;
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

/// The full payload data of the user bytes
@property (nonatomic, readonly) NSData* data;
/// Version of the V1 this instance of user bytes belongs too
@property (nonatomic) NSUInteger v1Version;

/// Toggles X band detection
@property (nonatomic) BOOL XBandOn;
/// Toggles K band detection
@property (nonatomic) BOOL KBandOn;
/// Toggles Ka band detection
@property (nonatomic) BOOL KaBandOn;
/// Toggles laser detection
@property (nonatomic) BOOL laserOn;
/// Adjusts the response of the signal-strength meter for Ka band
@property (nonatomic) ESPBargraphSensitivity bargraphSensitivity;
/// Toggles the Ka False-Alarm Guard feature
@property (nonatomic) BOOL KaFalseGuardOn;
/// Toggles initial muting of K-band under certain circumstances
@property (nonatomic) BOOL KMutingOn;
/// Controls whether muted volume can be adjusted via the control lever on the V1
@property (nonatomic) ESPMuteVolumeState muteVolumeState;
/// Controls how the volume of any Bogey Lock Tones are adjusted after pressing mute
@property (nonatomic) ESPPostMuteBogeyLockVolumeState postMuteBogeyLockVolumeState;
/// Sets a time period of automatic muting of K-band alerts
@property (nonatomic) ESPKMuteTimerValue KMuteTimer;
/// Toggles an automatic override of the K mute timer if the K-band signal strength exceeds 4 LEDs
@property (nonatomic) BOOL KInitialUnmute4LightsOn;
/// Toggles an automatic override of the K mute timer if the K-band signal strength slowly rises to 6 LEDs
@property (nonatomic) BOOL KPersistantUnmute6LightsOn;
/// Toggles automatic muting of K-band alerts from the rear
@property (nonatomic) BOOL KRearMuteOn;
/// Toggles Ku band detection
@property (nonatomic) BOOL KuBandOn;
/// Toggles POP radar detection
@property (nonatomic) BOOL popOn;
/// Toggles Euro Mode
@property (nonatomic) BOOL euroOn;
/// Toggles Euro X band detection
@property (nonatomic) BOOL euroXBandOn;
/// Toggles the Traffic Monitor Filter/Junk-K Fighter
@property (nonatomic) BOOL filterOn;
/// Toggles forced Legacy (pre-ESP) Concealed Display operation
@property (nonatomic) BOOL forceLegacyCD;
/// Toggles Mute to Muted Volume
@property (nonatomic) BOOL muteToMuteVolume;
/// Toggles load bogey lock tones after muting
@property (nonatomic) BOOL BogeyLockToneLoadAfterMuting;
/// Toggles automatic X & K rear alert muting
@property (nonatomic) BOOL MuteXAndKRear;
/// Toggles rear Laser alerts
@property (nonatomic) BOOL LaserRear;
/// Toglles Custom Frequencies
@property (nonatomic) BOOL CustomFrequencies;

@end
