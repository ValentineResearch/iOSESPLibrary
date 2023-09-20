/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/// The "status" of a SAVVY ESP device.
@interface ESPSavvyStatus : NSObject

/// Initializes savvy status with default values
/// @return a newly initialized savvy status
-(id)init;
/// Initializes the savvy status from a received packet's payload
/// @param data the payload data from a respSavvyStatus packet
/// @return a newly initialized savvy status
-(id)initWithData:(NSData*)data;
/// Initializes the savvy status by copying data from another savvy status
/// @param savvyStatus the savvy status to copy from
/// @return a newly initialized savvy status
-(id)initWithSavvyStatus:(ESPSavvyStatus*)savvyStatus;

/// Tells whether the savvy status is equal to another savvy status
/// @param savvyStatus the status to compare against
/// @return YES if they are equal, NO if they are not
-(BOOL)isEqualToSavvyStatus:(ESPSavvyStatus*)savvyStatus;

/// The full payload data of the savvy status
@property (nonatomic, readonly) NSData* data;

/// The speed threshold of the savvy, in KPH
@property (nonatomic, readonly) Byte thresholdKPH;

/// Tells whether the savvy thumbwheel has been overridden by the user
@property (nonatomic, readonly) BOOL overriddenByUser;
/// Tells whether unmute functionality is enabled on the savvy
@property (nonatomic, readonly) BOOL unmuteEnabled;

@end
