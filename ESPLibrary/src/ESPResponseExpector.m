/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPResponseExpector.h"
#import "ESPRequest.h"

@interface ESPResponseExpector()
{
	NSMutableArray<NSNumber*>* _responseIDs;
	NSMutableArray<ESPRequest*>* _requests;
	NSMutableArray<ESPPacket*>* _packets;
	NSMutableArray<NSDate*>* _sendTimes;
	NSUInteger _lastBusyQueueIndex;
}
@end

@implementation ESPResponseExpector

@synthesize packetRecievedCallback = _packetRecievedCallback;
@synthesize failureCallback = _failureCallback;

-(id)init
{
	if(self = [super init])
	{
		_responseIDs = [NSMutableArray<NSNumber*> array];
		_requests = [NSMutableArray<ESPRequest*> array];
		_packets = [NSMutableArray<ESPPacket*> array];
		_sendTimes = [NSMutableArray<NSDate*> array];
		_packetRecievedCallback = nil;
		_failureCallback = nil;
		_lastBusyQueueIndex = -1;
	}
	return self;
}

+(instancetype)expector
{
	return [[[self class] alloc] init];
}

-(void)addResponseID:(ESPPacketID)responseID
{
	[_responseIDs addObject:@(responseID)];
}

-(BOOL)hasResponseID:(ESPPacketID)responseID
{
	return [_responseIDs containsObject:@(responseID)];
}

-(NSArray<NSNumber*>*)responseIDs
{
	return [NSArray<NSNumber*> arrayWithArray:_responseIDs];
}

-(void)markSentRequest:(ESPRequest*)request withPacket:(ESPPacket*)packet
{
	if(request.responseExpector!=self)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"request's responseExpector does not match" userInfo:nil];
	}
	NSDate* now = [NSDate date];
	@synchronized(_requests)
	{
		[_requests addObject:request];
		[_packets addObject:packet];
		[_sendTimes addObject:now];
	}
	request.responseExpector = nil;
}

-(NSArray<ESPPacket*>*)sentPackets
{
	@synchronized(_requests)
	{
		return [NSArray arrayWithArray:_packets];
	}
}

-(NSDate*)requestTimestamp
{
	@synchronized(_requests)
	{
		if(_sendTimes.count > 0)
		{
			return _sendTimes.firstObject;
		}
		return nil;
	}
}

-(NSDate*)dateOfSentPacket:(ESPPacket*)packet
{
	@synchronized(_requests)
	{
		NSUInteger packetIndex = [_packets indexOfObjectIdenticalTo:packet];
		if(packetIndex!=NSNotFound)
		{
			return _sendTimes[packetIndex];
		}
		return nil;
	}
}

-(BOOL)hasPacketIdenticalTo:(ESPPacket*)packet
{
	@synchronized(_requests)
	{
		NSUInteger packetIndex = [_packets indexOfObjectIdenticalTo:packet];
		if(packetIndex!=NSNotFound)
		{
			return YES;
		}
		return NO;
	}
}

-(BOOL)hasPacketWithID:(ESPPacketID)packetID destination:(ESPDeviceID)destination
{
	@synchronized(_requests)
	{
		for(NSUInteger i=0; i<_packets.count; i++)
		{
			ESPPacket* packet = _packets[i];
			if(packet.packetID==packetID && packet.destination==destination)
			{
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)hasPacketWithDestination:(ESPDeviceID)destination
{
	@synchronized(_requests)
	{
		for(NSUInteger i=0; i<_packets.count; i++)
		{
			if(_packets[i].destination==destination)
			{
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)isInBusyQueue:(NSArray<NSNumber*>*)busyQueue
{
	ESPPacket* lastPacket = nil;
	@synchronized(_requests)
	{
		lastPacket = [_packets lastObject];
	}
	if(lastPacket==nil)
	{
		return NO;
	}
	ESPPacketID lastPacketID = lastPacket.packetID;
	for(NSUInteger i=0; i<busyQueue.count; i++)
	{
		ESPPacketID packetID = (ESPPacketID)[busyQueue[i] charValue];
		if(packetID==lastPacketID)
		{
			if(_lastBusyQueueIndex==-1 || _lastBusyQueueIndex>=i)
			{
				_lastBusyQueueIndex = i;
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)isExpiredWithTimeout:(NSTimeInterval)timeout
{
	NSTimeInterval now = [NSDate date].timeIntervalSince1970;
	@synchronized(_requests)
	{
		//all expector requests must time out for the expector to time out
		for(NSUInteger i=0; i<_requests.count; i++)
		{
			ESPRequest* request = _requests[i];
			NSTimeInterval sendTime = _sendTimes[i].timeIntervalSince1970;
			if((sendTime+timeout)>now || (sendTime+request.minimumProcessingTime)>now)
			{
				return NO;
			}
		}
		return YES;
	}
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendString:@"Awaiting Response IDs: "];
	for(NSUInteger i=0; i<_responseIDs.count; i++)
	{
		ESPPacketID responseID = (ESPPacketID)_responseIDs[i].charValue;
		[desc appendFormat:@"%02X", responseID];
		if(i!=(_responseIDs.count-1))
		{
			[desc appendString:@", "];
		}
	}
	[desc appendString:@"\nSent Request IDs: "];
	@synchronized(_requests)
	{
		for(NSUInteger i=0; i<_packets.count; i++)
		{
			ESPPacketID packetID = _packets[i].packetID;
			[desc appendFormat:@"%02X", packetID];
			if(i!=(_packets.count-1))
			{
				[desc appendString:@", "];
			}
		}
	}
	return desc;
}

@end
