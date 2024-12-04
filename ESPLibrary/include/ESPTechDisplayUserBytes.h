/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPUserBytesBase.h"

/// The "user bytes" of an ESP device. For more info on the V1's internal settings, see http://www.valentine1.com/Lab/techreport3.asp
@interface ESPTechDisplayUserBytes : ESPUserBytesBase

/// Initializes user bytes with default values
/// @return a newly initialized user bytes object
-(id)init;

/// Initializes user bytes with default values and the provided v1 version.
/// @param version Version of the attached V1
/// @return a newly initialized user bytes object
-(id)initWithT1Version:(NSUInteger)version;
/// Initializes user bytes with the payload data of a received packet
/// @param data the payload data from a respUserBytes or reqWriteUserBytes packet
/// @param version the version of the target V1
/// @return a newly initialized user bytes object
-(id)initWithData:(NSData*)data t1Version:(NSUInteger)version;
/// Initializes user bytes by copying data from another user bytes object
/// @param userBytes the user bytes to copy from
/// @return a newly initialized user bytes object
-(id)initWithUserBytes:(ESPTechDisplayUserBytes*)userBytes;

/// Tells whether the the user bytes are equal to another set of user bytes
/// @param userBytes the user bytes to compare
/// @return YES if equal, NO if not equal
-(BOOL)isEqualToUserBytes:(ESPTechDisplayUserBytes*)userBytes;

/// Sets all the user bytes back to 0xFF, the default value
-(void)resetToDefaults;

/// Version of the V1 this instance of user bytes belongs too
@property (nonatomic) NSUInteger t1Version;

/// Toggles V1 Display On/Off
@property (nonatomic) BOOL V1DisplayOn;
/// Toggles Tech Display On/Off
@property (nonatomic) BOOL TechDisplayOn;
/// Toggles Extended Recall Mode Timeout On/Off
@property (nonatomic) BOOL ExtendedRecallModeTimeoutOn;

@end
