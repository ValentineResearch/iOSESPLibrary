/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPClient.h"
#import "ESPPacket.h"
#import "ESPResponseExpector.h"

/*!
 *  ESPRequest
 *
 *  Discussion:
 *    Holds data for a request to an ESP device
 */
@interface ESPRequest : NSObject

/*! Conveniance method to allocate, initialize, and return a new request
	@returns a newly created request */
+(instancetype)request;

/// The target device/accessory that will receive the request
@property (nonatomic) ESPRequestTarget target;

/// The packet identifier of the request
@property (nonatomic) ESPPacketID packetID;
/// The packet data of the request
@property (nonatomic, copy) NSData* packetData;

/// If a request expects a response, the response expector handles the response action
@property (nonatomic, strong) ESPResponseExpector* responseExpector;

/// The minimum amount of time needed to complete this request. Even if the timeout value is lower than this value, the request will not time out until at least this amount of time has passed after sending the request. By default, this value is 0 */
@property (nonatomic) NSTimeInterval minimumProcessingTime;

@end
