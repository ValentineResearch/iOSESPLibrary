/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/// The base class for "user bytes" of an ESP device.
@interface ESPUserBytesBase : NSObject

/// Initializes user bytes with default values
/// @return a newly initialized user bytes object
-(id)init;
/// Initializes user bytes with the payload data of a received packet
/// @param data the payload data from a respUserBytes or reqWriteUserBytes packet
/// @return a newly initialized user bytes object
-(id)initWithData:(NSData*)data;
/// Initializes user bytes by copying data from another user bytes object
/// @param userBytes the user bytes to copy from
/// @return a newly initialized user bytes object
-(id)initWithUserBytes:(ESPUserBytesBase*)userBytes;

/// Tells whether the the user bytes are equal to another set of user bytes
/// @param userBytes the user bytes to compare
/// @return YES if equal, NO if not equal
-(BOOL)isEqualToUserBytes:(ESPUserBytesBase*)userBytes;

/// Sets all the user bytes back to 0xFF, the default value
-(void)resetToDefaults;

///// The full payload data of the user bytes
@property (nonatomic) NSMutableData* data;

@end
