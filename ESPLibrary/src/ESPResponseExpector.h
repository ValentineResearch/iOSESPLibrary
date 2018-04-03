/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPClient.h"

@class ESPRequest;

/*!
 *  ESPResponseExpector
 *
 *  Discussion:
 *    Handles receiving of response packets from requests. Many request packet identifiers have a corresponding response packet identifier.
 *    The response expector expects a packet with the response identifier for a request and has its callback called when the packet is
 *    received.
 */
@interface ESPResponseExpector : NSObject

/*! Convenience method to allocate, initialize, and return a new response expector */
+(instancetype)expector;

/*! Adds a packet ID that identifies the type of response to be expected
	@param responseID the packet ID of the type of response to expect */
-(void)addResponseID:(ESPPacketID)responseID;
/*! Tells whether the given packet ID matches any of the expector's response IDs
	@param responseID the packet ID to look for
	@returns YES if the expector has a matching response ID, or NO if it does not have a matching response ID */
-(BOOL)hasResponseID:(ESPPacketID)responseID;
/*! Marks a request as sent. The given request's responseExpector property should be this response expector, and the method will throw an exception if it is not. When this method is called, the request's responseExpector property is set to nil to prevent a retain loop.
	@param request the request to mark as sent
	@param packet the packet that was sent for the request */
-(void)markSentRequest:(ESPRequest*)request withPacket:(ESPPacket*)packet;
/*! Checks if any of the request packets have the same memory address as the given packet
	@param packet the packet to compare packet data against
	@returns YES if the expector contains a matching packet, or NO if it does not contain a matching packet */
-(BOOL)hasPacketIdenticalTo:(ESPPacket*)packet;
/*! Checks if any of the request packets' identifiers and destinations match the given packet identifier and destination
	@param packetID the identifier of the packet to match against
	@param destination the destination of the packet to match against
	@returns YES if the expector contains a matching packet identifier, or NO if it does not contain a matching packet identifier */
-(BOOL)hasPacketWithID:(ESPPacketID)packetID destination:(ESPDeviceID)destination;
/*! Checks if any of the request packets' destinations match the given ESP device identifier
	@param destination the device identifier of the destination
	@returns YES if the expector contains a matching packet destination, or NO if it does not contain a matching packet destination */
-(BOOL)hasPacketWithDestination:(ESPDeviceID)destination;
/*! Checks if any of the request packets' identifiers match identifiers in the busy queue. If a packet does match, the index of the match is marked, and any subsequent checks will only check up to the previous match index
	@param busyQueue an array of packet identifiers
	@returns YES if the busy queue contains a matching packet identifier, or NO if the busy queue does not contain a matching packet identifier */
-(BOOL)isInBusyQueue:(NSArray<NSNumber*>*)busyQueue;
/*! Checks if the response expector has timed out with the given timeout value
	@param timeout the amount of time after the requests were sent to time out
	@returns YES if the expector has timed out, or NO if the expector has not timed out */
-(BOOL)isExpiredWithTimeout:(NSTimeInterval)timeout;
/*! Gets the date/time that a particular packet was sent
	@param packet the packet that was sent for this response expector
	@returns a date object with the sent timestamp, or nil if the packet is not associated with this response expector */
-(NSDate*)dateOfSentPacket:(ESPPacket*)packet;

/// The date/time that the first request was sent at, or nil if no requests have been marked as sent
@property (nonatomic, readonly) NSDate* requestTimestamp;
/// The packet identifiers of the expected responses
@property (nonatomic, readonly) NSArray<NSNumber*>* responseIDs;
/// An array of packets that have been sent and are awaiting a response
@property (nonatomic, readonly) NSArray<ESPPacket*>* sentPackets;
/// The callback to call when a response packet is received. The callback should return YES if the expector has finished its business, or NO if the expector is still waiting on more packets
@property (nonatomic, copy) BOOL(^packetRecievedCallback)(ESPPacket* packet);
/// The callback to call when a request fails in some way
@property (nonatomic, copy) void(^failureCallback)(NSError* error);

@end
