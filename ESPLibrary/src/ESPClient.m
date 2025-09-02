/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPClient.h"
#import "ESPScanner+ESPClient.h"
#import "ESPRequest+ESPClient.h"
#import "ESPDataUtils.h"
#import "ESPPartialDataBuilder.h"
#import "ESPAlertTableBuilder.h"
#import "ESPSweepSectionsBuilder.h"
#import "ESPSweepsBuilder.h"
#import "ESPRequest.h"
#import "V1VersionUtil.h"

//#define LOGGING_ENABLED

#ifndef DEBUG
	#undef LOGGING_ENABLED
#endif

#ifdef LOGGING_ENABLED
	#define DebugLog(...) NSLog(__VA_ARGS__)
#else
	#define DebugLog(...)
#endif

NSString* const ESPRequestErrorDomain = @"ESPRequestErrorDomain";

#define V1ORIGIN ESPDeviceV1ConnectionLE
#define LOOPBACK_EXPIRE_TIME 3.0

@interface ESPClient()
{
	CBCharacteristic* _inShort;
	CBCharacteristic* _inLong;
	CBCharacteristic* _outShort;
	CBCharacteristic* _outLong;
	
	ESPPartialDataBuilder* _partialBuilder;
	ESPAlertTableBuilder* _alertTableBuilder;
	
	NSMutableArray<NSNumber*>* _v1BusyQueue;
	NSUInteger _v1BusyQueueClearWaitCount;
	
	NSMutableArray<ESPRequest*>* _requestQueue;
	NSMutableArray<NSDate*>* _requestQueueDates;
	NSMutableArray<ESPResponseExpector*>* _responseExpectors;
	
	BOOL _determinedV1Type;
	BOOL _lastV1TypeHadChecksums;
	NSUInteger _v1TypeDeterminationCount;
    NSUInteger _lastV1Version;
	
	NSTimer* _powerLossTimer;
	NSTimer* _requestTimeoutTimer;
    NSDate* _lastRxPacketTime;
	
	NSUInteger _legacyCounter;
	ESPDisplayData* _lastDisplayData;
	NSData* _lastSentData;
	ESPPacket* _lastSentPacket;
	
	NSMutableArray<NSData*>* _echoFilterWatch;
	NSMutableArray<NSDate*>* _echoFilterSendDates;
}

-(void)_handlePowerLossTimeout:(NSTimer*)timer;
-(void)_handleRequestTimeoutTimer:(NSTimer*)timer;
-(void)_startPowerLossTimer;

-(BOOL)_shouldAutomaticallyFailRequests;

-(BOOL)_checkLoopbackPackets:(NSData*)data;
@end

@implementation ESPClient

#define BUSY_QUEUE_WAIT_COUNT 3
#define TYPE_DETERMINATION_COUNT_MAX 8

@synthesize delegate = _delegate;
@synthesize peripheral = _peripheral;
@synthesize legacy = _legacy;
@synthesize checksums = _checksums;
@synthesize connected = _connected;
@synthesize powerLossDetected = _powerLossDetected;
@synthesize powerLossTimeout = _powerLossTimeout;
@synthesize requestTimeout = _requestTimeout;
@synthesize reportsEchoedPackets = _reportsEchoedPackets;

-(id)init
{
	if(self = [super init])
	{
		_peripheral = nil;
		_inShort = nil;
		_inLong = nil;
		_outShort = nil;
		_outLong = nil;
		
		_partialBuilder = [[ESPPartialDataBuilder alloc] init];
		_alertTableBuilder = [[ESPAlertTableBuilder alloc] init];
		
		_v1BusyQueue = [NSMutableArray<NSNumber*> array];
		_v1BusyQueueClearWaitCount = BUSY_QUEUE_WAIT_COUNT;
		_requestQueue = [NSMutableArray<ESPRequest*> array];
		_requestQueueDates = [NSMutableArray<NSDate*> array];
		_responseExpectors = [NSMutableArray<ESPResponseExpector*> array];
		
		_determinedV1Type = NO;
		_lastV1TypeHadChecksums = NO;
		_v1TypeDeterminationCount = 0;
        _lastV1Version = 0;
		
		_delegate = nil;
		_legacy = NO;
		_checksums = NO;
		_connected = NO;
		_powerLossDetected = NO;
		_powerLossTimeout = 5.0;
		_requestTimeout = 5.0;
		
		_legacyCounter = 0;
		_lastDisplayData = nil;
		_lastSentData = nil;
		_lastSentPacket = nil;
		
		_powerLossTimer = nil;
		_requestTimeoutTimer = nil;
        _lastRxPacketTime = nil;
		
		_reportsEchoedPackets = NO;
		_echoFilterWatch = [NSMutableArray array];
		_echoFilterSendDates = [NSMutableArray array];
	}
	return self;
}

-(id)initWithPeripheral:(CBPeripheral*)peripheral
				inShort:(CBCharacteristic*)inShort
				 inLong:(CBCharacteristic*)inLong
			   outShort:(CBCharacteristic*)outShort
				outLong:(CBCharacteristic*)outLong
{
	if(self = [self init])
	{
		_peripheral = peripheral;
		_inShort = inShort;
		_inLong = inLong;
		_outShort = outShort;
		_outLong = outLong;
		
		_connected = YES;
		_peripheral.delegate = self;
        
        // The power loss timer should always be running if we are connected
        [self _startPowerLossTimer];
		
		_requestTimeoutTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(_handleRequestTimeoutTimer:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_requestTimeoutTimer forMode:NSRunLoopCommonModes];
	}
	return self;
}

-(void)setPowerLossTimeout:(NSTimeInterval)powerLossTimeout
{
    NSTimeInterval oldPowerLossTimeout = _powerLossTimeout;
    _powerLossTimeout = powerLossTimeout;
    
    if ( oldPowerLossTimeout != _powerLossTimeout ){
        [self _startPowerLossTimer];
    }
}

-(void)setReportsEchoedPackets:(BOOL)reportsEchoedPackets
{
	if(_reportsEchoedPackets!=reportsEchoedPackets)
	{
		_reportsEchoedPackets = reportsEchoedPackets;
		if(_reportsEchoedPackets)
		{
			@synchronized(_echoFilterWatch)
			{
				[_echoFilterWatch removeAllObjects];
				[_echoFilterSendDates removeAllObjects];
			}
		}
	}
}

-(BOOL)sendPacket:(ESPPacket*)packet
{
	DebugLog(@"sending packet with id: %02x", packet.packetID);
	BOOL retVal = [self sendData:packet.data];
	if(retVal)
	{
		_lastSentPacket = packet;
	}
	return retVal;
}

-(BOOL)sendData:(NSData*)data
{
	if(!_connected)
	{
		return NO;
	}
	if(data.length<=20)
	{
		//short packet
		_lastSentData = data;
		if(!_reportsEchoedPackets)
		{
			@synchronized(_echoFilterWatch)
			{
				[_echoFilterWatch addObject:data];
				[_echoFilterSendDates addObject:[NSDate date]];
			}
		}
		[_peripheral writeValue:data forCharacteristic:_outShort type:CBCharacteristicWriteWithoutResponse];
		return YES;
	}
	else
	{
		//long packet
		NSMutableArray<NSData*>* chunks = [NSMutableArray<NSData*> array];
		while(data.length>19)
		{
			NSData* chunk = [data subdataWithRange:NSMakeRange(0, 19)];
			data = [data subdataWithRange:NSMakeRange(19, data.length-19)];
			[chunks addObject:chunk];
		}
		if(data.length>0)
		{
			[chunks addObject:data];
		}
		
		if(chunks.count>15)
		{
			//too many chunks to fit index/count in 4 bits! can't send this packet
			return NO;
		}
		
		//send packet piece by piece
		_lastSentData = data;
		if(!_reportsEchoedPackets)
		{
			@synchronized(_echoFilterWatch)
			{
				[_echoFilterWatch addObject:data];
				[_echoFilterSendDates addObject:[NSDate date]];
			}
		}
		for(NSUInteger i=0; i<chunks.count; i++)
		{
			NSData* chunk = chunks[i];
			Byte chunkPrefix = (((Byte)chunks.count) & 0x0F);
			chunkPrefix |= ((((Byte)i) << 4) & 0xF0);
			NSMutableData* piece = [NSMutableData dataWithBytes:(void*)&chunkPrefix length:1];
			[piece appendData:chunk];
			[_peripheral writeValue:piece forCharacteristic:_outLong type:CBCharacteristicWriteWithoutResponse];
		}
		return YES;
	}
}

-(void)_handleReceivedPacket:(ESPPacket*)packet
{
	if(!_reportsEchoedPackets)
	{
		//make sure the packet isn't a loopback packet
		if([self _checkLoopbackPackets:packet.data])
		{
			DebugLog(@"throwing away echoed packet with ID %02X", packet.packetID);
			//packet was an echoed packet. Throwing away...
			return;
		}
	}
	
	//reset the power loss status
	_powerLossDetected = NO;
    _lastRxPacketTime = [NSDate date];
    if ( _powerLossTimer == nil ){
        // Restart the power loss timer if it was turned off due to a power loss
        [self _startPowerLossTimer];
    }
	
	if((packet.origin==ESPDeviceV1WithChecksum && ![packet isChecksumValid])
	   || (packet.origin!=ESPDeviceV1WithoutChecksum && _determinedV1Type && _checksums && ![packet isChecksumValid]))
	{
		//don't trust this packet if the checksum isn't valid
		DebugLog(@"received packet with invalid checksum. ignoring");
		[self didReceivePacketWithBadChecksum:packet];
		return;
	}
	
	if(packet.packetID==ESPPacketInfDisplayData)
	{
		if(packet.origin==ESPDeviceV1WithChecksum)
		{
			if(!_checksums || !_determinedV1Type)
			{
				//count 8 packets with checksums to ensure V1 actually has checksums
				if(_lastV1TypeHadChecksums)
				{
					_v1TypeDeterminationCount++;
				}
				else
				{
					_v1TypeDeterminationCount = 1;
					_lastV1TypeHadChecksums = YES;
				}
				DebugLog(@"%i checksum packets", (int)_v1TypeDeterminationCount);
				if(_v1TypeDeterminationCount >= TYPE_DETERMINATION_COUNT_MAX)
				{
					_v1TypeDeterminationCount = 0;
					_checksums = YES;
					_determinedV1Type = YES;
					DebugLog(@"Checksums On");
				}
			}
		}
		else if(packet.origin==ESPDeviceV1WithoutChecksum)
		{
			if(_checksums || !_determinedV1Type)
			{
				//count 8 packets without checksums to ensure V1 actually doesn't have checksums
				if(!_lastV1TypeHadChecksums)
				{
					_v1TypeDeterminationCount++;
				}
				else
				{
					_v1TypeDeterminationCount = 1;
					_lastV1TypeHadChecksums = NO;
				}
				DebugLog(@"%i non-checksum packets", (int)_v1TypeDeterminationCount);
				if(_v1TypeDeterminationCount >= TYPE_DETERMINATION_COUNT_MAX)
				{
					DebugLog(@"Checksums Off");
					_checksums = NO;
					_determinedV1Type = YES;
				}
			}
		}
	}
	
	//handle misc packets
	if(_determinedV1Type)
	{
        if(packet.packetID==ESPPacketRespVersion && (packet.origin==ESPDeviceV1WithChecksum || packet.origin==ESPDeviceV1WithoutChecksum))
        {
            _lastV1Version=getVersionFor([[NSString alloc] initWithData:[self _payloadFromPacket:packet] encoding:NSASCIIStringEncoding]);
        }
		else if(packet.packetID==ESPPacketInfV1Busy)
		{
			@synchronized(_v1BusyQueue)
			{
				_v1BusyQueueClearWaitCount = BUSY_QUEUE_WAIT_COUNT;
				[_v1BusyQueue removeAllObjects];
				NSData* payload = [self _payloadFromPacket:packet];
				Byte* payloadBytes = (Byte*)payload.bytes;
				for(NSUInteger i=0; i<(_checksums?(payload.length-1):payload.length); i++)
				{
					ESPPacketID packetID = (ESPPacketID)payloadBytes[i];
					[_v1BusyQueue addObject:@(packetID)];
				}
			}
		}
		else if(packet.packetID==ESPPacketInfDisplayData)
		{
			@synchronized (_v1BusyQueue)
			{
				if(_v1BusyQueueClearWaitCount>0)
				{
					_v1BusyQueueClearWaitCount--;
					if(_v1BusyQueueClearWaitCount==0)
					{
						//clear busy queue if an infV1Busy packet has not been received after a few infDisplayData packets have been received
						[_v1BusyQueue removeAllObjects];
					}
				}
			}
		}
		else if(packet.packetID==ESPPacketRespRequestNotProcessed ||
				packet.packetID==ESPPacketRespUnsupportedPacket ||
				packet.packetID==ESPPacketRespDataError)
		{
			NSData* payload = [self _payloadFromPacket:packet];
			if(payload.length>=1)
			{
				ESPPacketID ignoredPacketID = (ESPPacketID)((Byte*)payload.bytes)[0];
				ESPDeviceID ignoredPacketDestination = packet.origin;
				ESPResponseExpector* failedExpector = nil;
				@synchronized(_responseExpectors)
				{
					for(NSUInteger i=(_responseExpectors.count-1); i!=-1; i--)
					{
						ESPResponseExpector* expector = _responseExpectors[i];
						if([expector hasPacketWithID:ignoredPacketID destination:ignoredPacketDestination])
						{
							failedExpector = expector;
							[_responseExpectors removeObjectAtIndex:i];
							break;
						}
					}
				}
				if(failedExpector!=nil)
				{
					NSError* error = nil;
					switch(packet.packetID)
					{
						case ESPPacketRespRequestNotProcessed:
							error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeNotProcessed userInfo:@{NSLocalizedDescriptionKey:@"Request could not be processed"}];
							break;
							
						case ESPPacketRespUnsupportedPacket:
							error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeUnsupportedPacket userInfo:@{NSLocalizedDescriptionKey:@"Unsupported packet"}];
							break;
							
						case ESPPacketRespDataError:
							error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeDataError userInfo:@{NSLocalizedDescriptionKey:@"Data error"}];
							break;
					}
					failedExpector.failureCallback(error);
				}
			}
		}
	}
	
	//check display data for legacy bit
	if(packet.packetID==ESPPacketInfDisplayData)
	{
		ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:[self _payloadFromPacket:packet]];
		_lastDisplayData = displayData;
		//check for 5 consecutive display data packets with the legacy bit set, since the V1 sometimes says it's in legacy mode when it's not
		if((displayData.legacy && !_legacy) || (!displayData.legacy && _legacy))
		{
			_legacyCounter++;
		}
		else
		{
			_legacyCounter = 0;
		}
		if(_legacyCounter>=5)
		{
			_legacy = displayData.legacy;
			_legacyCounter = 0;
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espClient:didSetLegacyEnabled:)])
			{
				[_delegate espClient:self didSetLegacyEnabled:_legacy];
			}
		}
	}
	
	//if the V1 type is known, the queue has room, and tsHoldoff isn't set, then dequeue a request
	if(_determinedV1Type && _v1BusyQueue.count<5 && (_lastDisplayData==nil || !_lastDisplayData.tsHoldoff))
	{
		ESPRequest* queuedRequest = nil;
		@synchronized(_requestQueue)
		{
			if(packet.packetID==ESPPacketInfDisplayData)
			{
				if(_requestQueue.count>0)
				{
					queuedRequest = _requestQueue[0];
					[_requestQueue removeObjectAtIndex:0];
					[_requestQueueDates removeObjectAtIndex:0];
				}
			}
		}
		if(queuedRequest!=nil)
		{
			[self _performRequest:queuedRequest];
		}
	}
	
	//call packet received delegate method
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(espClient:didReceivePacket:)])
	{
		[_delegate espClient:self didReceivePacket:packet];
	}
	
	//handle response expectors
	NSArray<ESPResponseExpector*>* expectors = nil;
	BOOL foundResponseExpector = NO;
	@synchronized(_responseExpectors)
	{
		expectors = [NSArray<ESPResponseExpector*> arrayWithArray:_responseExpectors];
	}
	for(NSUInteger i=0; i<expectors.count; i++)
	{
		ESPResponseExpector* expector = expectors[i];
		if(expector.responseIDs.count==0)
		{
			//since the expector doesn't have a designated response packet, the busy queue must be checked to see if the packet has been processed by the V1
			@synchronized(_v1BusyQueue)
			{
				if(![expector isInBusyQueue:_v1BusyQueue])
				{
					if(expector.packetRecievedCallback(nil))
					{
						@synchronized(_responseExpectors)
						{
							[_responseExpectors removeObjectIdenticalTo:expector];
						}
					}
				}
			}
		}
		else if(!foundResponseExpector && [expector hasResponseID:packet.packetID] && [expector hasPacketWithDestination:packet.origin])
		{
			//only one expector can match a received packet, unless it's infDisplayData, since infDisplayData isn't a response to a request
			if(packet.packetID!=ESPPacketInfDisplayData)
			{
				foundResponseExpector = YES;
			}
			if([self _handleResponsePacket:packet forResponseExpector:expector])
			{
				@synchronized(_responseExpectors)
				{
					[_responseExpectors removeObjectIdenticalTo:expector];
				}
			}
		}
	}
	//manually call check for timed out expectors
	[self _handleRequestTimeoutTimer:_requestTimeoutTimer];
	
	[self didReceivePacket:packet];
}

-(BOOL)_handleResponsePacket:(ESPPacket*)packet forResponseExpector:(ESPResponseExpector*)responseExpector
{
	return responseExpector.packetRecievedCallback(packet);
}

-(void)didReceivePacket:(ESPPacket*)packet
{
	//call display and alert data delegate methods
	if(packet.packetID==ESPPacketInfDisplayData)
	{
        ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:[self _payloadFromPacket:packet]];
		if(displayData!=nil && _delegate!=nil && [_delegate respondsToSelector:@selector(espClient:didReceiveDisplayData:)])
		{
			[_delegate espClient:self didReceiveDisplayData:displayData];
		}
	}
	else if(packet.packetID==ESPPacketRespAlertData)
	{
		ESPAlertData* alert = [[ESPAlertData alloc] initWithData:[self _payloadFromPacket:packet] v1Version:_lastV1Version];
        NSArray<ESPAlertData*>* alertTable = [_alertTableBuilder addAlert:alert];
		if(alertTable!=nil)
		{
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espClient:didReceiveAlertTable:)])
			{
				[_delegate espClient:self didReceiveAlertTable:alertTable];
			}
		}
	}
}

-(void)didReceivePacketWithBadChecksum:(ESPPacket*)packet
{
	//Open for implementation
}

-(void)_handlePowerLossTimeout:(NSTimer*)timer
{
    if ( !_powerLossDetected && (_lastRxPacketTime == nil || fabs([_lastRxPacketTime timeIntervalSinceNow]) >= _powerLossTimeout) ){
        // Timeout
        _powerLossDetected = YES;
        if(_delegate!=nil && [_delegate respondsToSelector:@selector(espClientDidDetectPowerLoss:)])
        {
            [_delegate espClientDidDetectPowerLoss:self];
        }
        
        // Stop the timer until data is restored
        [timer invalidate];
        _powerLossTimer = nil;
    }
}

// Kick off the power loss timer
-(void)_startPowerLossTimer
{
    if ( _powerLossTimer != nil ){
        [_powerLossTimer invalidate];
    }
    _powerLossTimer = [NSTimer timerWithTimeInterval:_powerLossTimeout target:self selector:@selector(_handlePowerLossTimeout:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_powerLossTimer forMode:NSRunLoopCommonModes];
}

-(void)_handleRequestTimeoutTimer:(NSTimer*)timer
{
	//check for expectors that have timed out
	NSMutableArray<ESPResponseExpector*>* timedOutExpectors = [NSMutableArray<ESPResponseExpector*> array];
	NSMutableArray<ESPResponseExpector*>* timedOutQueuedExpectors = [NSMutableArray<ESPResponseExpector*> array];
	@synchronized(_responseExpectors)
	{
		for(NSUInteger i=0; i<_responseExpectors.count; i++)
		{
			ESPResponseExpector* expector = _responseExpectors[i];
			if([expector isExpiredWithTimeout:_requestTimeout])
			{
				[_responseExpectors removeObjectAtIndex:i];
				i--;
				[timedOutExpectors addObject:expector];
			}
		}
		@synchronized(_requestQueue)
		{
			NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
			//find timed out requests
			for(NSUInteger i=(_requestQueue.count-1); i!=-1; i--)
			{
				ESPRequest* request = _requestQueue[i];
				NSTimeInterval requestTime = _requestQueueDates[i].timeIntervalSince1970;
				if((requestTime+request.minimumProcessingTime+_requestTimeout) <= nowTime)
				{
					//the request has timed out before it was able to be sent. Check if it can be removed
					ESPResponseExpector* expector = request.responseExpector;
					if(expector!=nil)
					{
						//If the request already has its expector waiting for a response, there's no need to time out, since the expector itself will time out and kill all of the queued requests
						NSUInteger expectorIndex = [_responseExpectors indexOfObjectIdenticalTo:expector];
						if(expectorIndex==NSNotFound)
						{
							//The expector was not already waiting, so it's safe to kill the queued request
							//Make sure the expector isn't already ready to be killed, though
							if([timedOutExpectors indexOfObjectIdenticalTo:expector]==NSNotFound
							   && [timedOutQueuedExpectors indexOfObjectIdenticalTo:expector]==NSNotFound)
							{
								[timedOutQueuedExpectors insertObject:expector atIndex:0];
							}
							[_requestQueue removeObjectAtIndex:i];
							[_requestQueueDates removeObjectAtIndex:i];
						}
					}
					else
					{
						[_requestQueue removeObjectAtIndex:i];
						[_requestQueueDates removeObjectAtIndex:i];
					}
				}
			}
			//remove requests with timed out expectors
			for(NSUInteger i=(_requestQueue.count-1); i!=-1; i--)
			{
				ESPRequest* request = _requestQueue[i];
				ESPResponseExpector* expector = request.responseExpector;
				if([timedOutExpectors indexOfObjectIdenticalTo:expector]!=NSNotFound
				   || [timedOutQueuedExpectors indexOfObjectIdenticalTo:expector]!=NSNotFound)
				{
					[_requestQueue removeObjectAtIndex:i];
					[_requestQueueDates removeObjectAtIndex:i];
				}
			}
		}
	}
	//call timed out expectors
	for(ESPResponseExpector* expector in timedOutExpectors)
	{
		DebugLog(@"timed out waiting for response expector:\n%@", expector.debugDescription);
		NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeNoResponse userInfo:@{NSLocalizedDescriptionKey:@"Request timed out"}];
		expector.failureCallback(error);
	}
	//call timed out queued expectors
	for(ESPResponseExpector* expector in timedOutQueuedExpectors)
	{
		DebugLog(@"timed out waiting for request to be sent for response expector:\n%@", expector.debugDescription);
		NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeNotSent userInfo:@{NSLocalizedDescriptionKey:@"Request could not be sent"}];
		expector.failureCallback(error);
	}
}

-(void)_handleDisconnect
{
	_peripheral.delegate = nil;
	
	_connected = NO;
	[_requestTimeoutTimer invalidate];
	_requestTimeoutTimer = nil;
	[_powerLossTimer invalidate];
	_powerLossTimer = nil;
    _lastRxPacketTime = nil;
	
	//fail all the response expectors
	NSArray<ESPResponseExpector*>* expectors = nil;
	NSMutableArray<ESPResponseExpector*>* failedExpectors = [NSMutableArray<ESPResponseExpector*> array];
	@synchronized(_responseExpectors)
	{
		expectors = [NSArray<ESPResponseExpector*> arrayWithArray:_responseExpectors];
		[_responseExpectors removeAllObjects];
	}
	for(NSUInteger i=0; i<expectors.count; i++)
	{
		ESPResponseExpector* expector = expectors[i];
		if([failedExpectors indexOfObjectIdenticalTo:expector]==NSNotFound)
		{
			[failedExpectors addObject:expector];
			NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"Device disconnected"}];
			expector.failureCallback(error);
		}
	}
	
	//fail all queued requests
	NSArray<ESPRequest*>* requests = nil;
	@synchronized(_requestQueue)
	{
		requests = [NSArray<ESPRequest*> arrayWithArray:_requestQueue];
		[_requestQueue removeAllObjects];
		[_requestQueueDates removeAllObjects];
	}
	for(NSUInteger i=0; i<requests.count; i++)
	{
		ESPResponseExpector* expector = requests[i].responseExpector;
		if(expector!=nil && [failedExpectors indexOfObjectIdenticalTo:expector]==NSNotFound)
		{
			[failedExpectors addObject:expector];
			NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"Device disconnected"}];
			expector.failureCallback(error);
		}
	}
}

-(ESPDeviceID)_destinationFromRequestTarget:(ESPRequestTarget)target
{
	switch(target)
	{
		case ESPRequestTargetValentineOne:
			if(_determinedV1Type)
			{
				if(_checksums)
				{
					return ESPDeviceV1WithChecksum;
				}
				return ESPDeviceV1WithoutChecksum;
			}
			return 0xFF;
			
		case ESPRequestTargetConcealedDisplay:
			return ESPDeviceConcealedDisplay;
			
		case ESPRequestTargetRemoteAudio:
			return ESPDeviceRemoteAudio;
			
		case ESPRequestTargetSavvy:
			return ESPDeviceSavvy;
			
		case ESPRequestTargetV1ConnectionLE:
			return ESPDeviceV1ConnectionLE;
			
		case ESPRequestTargetThirdParty1:
			return ESPDeviceThirdParty1;
			
		case ESPRequestTargetThirdParty2:
			return ESPDeviceThirdParty2;
			
		case ESPRequestTargetThirdParty3:
			return ESPDeviceThirdParty3;
	}
	return 0xFF;
}

-(BOOL)_shouldAutomaticallyFailRequests
{
	if(!_connected)
	{
		return YES;
	}
	return NO;
}

-(void)_queueRequest:(ESPRequest*)request
{
	if([self _shouldAutomaticallyFailRequests])
	{
		if(request.responseExpector!=nil)
		{
			if(!_connected)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"Device disconnected"}];
				request.responseExpector.failureCallback(error);
			}
			else
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeNotSent userInfo:@{NSLocalizedDescriptionKey:@"Request could not be sent"}];
				request.responseExpector.failureCallback(error);
			}
		}
		return;
	}
	@synchronized(_requestQueue)
	{
		[_requestQueue addObject:request];
		[_requestQueueDates addObject:[NSDate date]];
	}
}

-(void)_clearRequests {
    // Remove all pending request. We don't care about completing them
    @synchronized(_requestQueue)
    {
        [_requestQueue removeAllObjects];
        [_requestQueueDates removeAllObjects];
    }
}

-(void)_performRequest:(ESPRequest*)request
{
	NSAssert(request.packetID!=0xFF, @"ESPRequest uses invalid packet ID 0xFF");
	if([self _shouldAutomaticallyFailRequests])
	{
		if(request.responseExpector!=nil)
		{
			if(!_connected)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"Device disconnected"}];
				request.responseExpector.failureCallback(error);
			}
			else
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeNotSent userInfo:@{NSLocalizedDescriptionKey:@"Unable to send request"}];
				request.responseExpector.failureCallback(error);
			}
		}
		return;
	}
	ESPDeviceID destination = [self _destinationFromRequestTarget:request.target];
	ESPPacket* packet = [[ESPPacket alloc] initWithDestination:destination origin:V1ORIGIN packetID:request.packetID payload:request.packetData checksum:_checksums];
	if(request.responseExpector!=nil)
	{
		@synchronized(_responseExpectors)
		{
			ESPResponseExpector* expector = request.responseExpector;
			[expector markSentRequest:request withPacket:packet];
			
			NSUInteger expectorIndex = [_responseExpectors indexOfObjectIdenticalTo:expector];
			if(expectorIndex==NSNotFound)
			{
				[_responseExpectors addObject:expector];
			}
		}
	}
	[self sendPacket:packet];
}

-(NSData*)_payloadFromPacket:(ESPPacket*)packet
{
	NSData* payload = packet.payload;
	if((_checksums || packet.origin==ESPDeviceV1WithChecksum) && packet.origin!=ESPDeviceV1WithoutChecksum)
	{
		if(payload.length>=1)
		{
			return [payload subdataWithRange:NSMakeRange(0, payload.length-1)];
		}
		else
		{
			return [NSData data];
		}
	}
	else
	{
		return payload;
	}
}

-(BOOL)_requestIsInBusyQueue:(ESPResponseExpector*)expector
{
	return [expector isInBusyQueue:_v1BusyQueue];
}

-(BOOL)_checkLoopbackPackets:(NSData*)data
{
	@synchronized(_echoFilterWatch)
	{
		//remove expired loopback watch packets
		NSTimeInterval now = [NSDate date].timeIntervalSince1970;
		for(NSUInteger i=(_echoFilterWatch.count-1); i!=-1; i--)
		{
			NSTimeInterval sendTime = _echoFilterSendDates[i].timeIntervalSince1970;
			if((now-sendTime)>=LOOPBACK_EXPIRE_TIME)
			{
				//loopback packet expired. Presumed dead and not looping back
				[_echoFilterWatch removeObjectAtIndex:i];
				[_echoFilterSendDates removeObjectAtIndex:i];
			}
		}
		
		//check for matching loopback watch packet
		for(NSUInteger i=0; i<_echoFilterWatch.count; i++)
		{
			NSData* cmpData = _echoFilterWatch[i];
			if([cmpData isEqualToData:data])
			{
				[_echoFilterWatch removeObjectAtIndex:i];
				[_echoFilterSendDates removeObjectAtIndex:i];
				return YES;
			}
		}
		return NO;
	}
}



#pragma mark - Request Methods

-(void)requestVersionFrom:(ESPRequestTarget)target completion:(void(^)(NSString*, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqVersion;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespVersion];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		NSString* version = [[NSString alloc] initWithData:payload encoding:NSASCIIStringEncoding];
		if(completion!=nil)
		{
			completion(version, nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(nil, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestSerialNumberFrom:(ESPRequestTarget)target completion:(void(^)(NSString*, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqSerialNumber;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespSerialNumber];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		NSString* serial = [[NSString alloc] initWithData:payload encoding:NSASCIIStringEncoding];
		if(completion!=nil)
		{
			completion(serial, nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(nil, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestUserBytesDataFrom:(ESPRequestTarget)target completion:(void(^)(NSData* userBytes, NSError* error))completion {
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqUserBytes;
    request.packetData = [NSData data];
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    [expector addResponseID:ESPPacketRespUserBytes];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        NSData* payload = [self _payloadFromPacket:packet];
        if(completion!=nil)
        {
            completion(payload, nil);
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(nil, error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestUserDataBytes:(void(^)(NSData* userBytes, NSError* error))completion {
    [self requestUserBytesDataFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestUserBytesFrom:(ESPRequestTarget)target forVersion:(NSUInteger)version completion:(void(^)(ESPUserBytesBase* userBytes, NSError* error))completion;
{
    [self requestUserBytesDataFrom:target completion:^(NSData *userBytes, NSError *error) {
         if ( completion != nil ) {
            if ( error == nil ){
                if ( target == ESPRequestTargetTechDisplay ){
                    ESPTechDisplayUserBytes* espUserBytes = [[ESPTechDisplayUserBytes alloc] initWithData:userBytes t1Version:version];
                    completion (espUserBytes, nil);
                }
                else {
                    ESPV1UserBytes* espUserBytes = [[ESPV1UserBytes alloc] initWithData:userBytes v1Version:version];
                    completion (espUserBytes, nil);
                }
            }
            else {
                completion (nil, error);
            }
        }
    }];
}

-(void)requestUserBytesforV1Version:(NSUInteger)version completion:(void(^)(ESPV1UserBytes* userBytes, NSError* error))completion 
{
    [self requestUserBytesFrom:ESPRequestTargetValentineOne forVersion:version completion:^(ESPUserBytesBase* userBytes, NSError* error){
        if ( error == nil ){
            completion ((ESPV1UserBytes*)userBytes, nil);
        }
        else {
            completion (nil, error);
        }
    }];
}

-(void)requestWriteUserBytes:(ESPUserBytesBase*)userBytes target:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
    [self requestWriteUserBytesData:userBytes.data target:target completion:completion];
}

-(void)requestWriteUserBytesData:(NSData*)data target:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
    NSData* userBytesData = [[NSMutableData alloc] initWithData:data];
	if(userBytesData.length>6)
	{
		userBytesData = [userBytesData subdataWithRange:NSMakeRange(0, 6)];
	}
	else if(userBytesData.length<6)
	{
		NSMutableData* data = [NSMutableData dataWithData:userBytesData];
		while(data.length<6)
		{
			Byte b = 0xFF;
			[data appendBytes:(void*)&b length:1];
		}
		userBytesData = data;
	}
	
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqWriteUserBytes;
	request.packetData = userBytesData;
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestWriteUserBytes:(ESPUserBytesBase*)userBytes completion:(void(^)(NSError*))completion
{
	[self requestWriteUserBytes:userBytes target:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestWriteFactoryDefaultFor:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqFactoryDefault;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestWriteSweepDefinition:(ESPCustomSweepData*)sweep target:(ESPRequestTarget)target
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqWriteSweepDefinition;
	request.packetData = sweep.data;
	request.responseExpector = nil;
	
	[self _queueRequest:request];
}

-(void)requestWriteSweepDefinition:(ESPCustomSweepData*)sweep
{
	[self requestWriteSweepDefinition:sweep target:ESPRequestTargetValentineOne];
}

-(void)requestWriteSweepDefinitions:(NSArray<ESPFrequencyRange*>*)sweeps target:(ESPRequestTarget)target completion:(void(^)(NSUInteger, NSError*))completion
{
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespSweepWriteResult];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		if(payload.length>=1)
		{
			NSUInteger writeResult = (NSUInteger)ESPData_getByte(payload, 0);
			if(completion!=nil)
			{
				completion(writeResult, nil);
			}
		}
		else
		{
			if(completion!=nil)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				completion(0, error);
			}
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(0, error);
		}
	};
	
	for(NSUInteger i=0; i<sweeps.count; i++)
	{
		BOOL commit = NO;
		if(i==(sweeps.count-1))
		{
			commit = YES;
		}
		
		ESPRequest* request = [ESPRequest request];
		request.target = target;
		request.packetID = ESPPacketReqWriteSweepDefinition;
		request.packetData = [[ESPCustomSweepData alloc] initWithIndex:i range:sweeps[i] commit:commit].data;
		request.responseExpector = expector;
		
		[self _queueRequest:request];
	}
}

-(void)requestWriteSweepDefinitions:(NSArray<ESPFrequencyRange*>*)sweeps completion:(void(^)(NSUInteger, NSError*))completion
{
	[self requestWriteSweepDefinitions:sweeps target:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestAllSweepDefinitionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	[self requestMaxSweepIndexFrom:target completion:^(NSUInteger maxSweepIndex, NSError* error){
		if(error==nil)
		{
			ESPSweepsBuilder* sweepsBuilder = [[ESPSweepsBuilder alloc] initWithMaxSweepIndex:maxSweepIndex];
			
			ESPRequest* request = [ESPRequest request];
			request.target = target;
			request.packetID = ESPPacketReqAllSweepDefinitions;
			request.packetData = [NSData data];
			
			ESPResponseExpector* expector = [ESPResponseExpector expector];
			[expector addResponseID:ESPPacketRespSweepDefiniton];
			expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
				NSData* payload = [self _payloadFromPacket:packet];
				ESPCustomSweepData* sweep = [[ESPCustomSweepData alloc] initWithData:payload];
				DebugLog(@"received sweep with index %i", (int)sweep.index);
				NSError* sweepError = nil;
				NSArray<ESPFrequencyRange*>* sweeps = [sweepsBuilder addSweep:sweep error:&sweepError];
				if(sweepError!=nil)
				{
					if(completion!=nil)
					{
						completion(nil, sweepError);
					}
					return YES;
				}
				else if(sweeps!=nil)
				{
					if(completion!=nil)
					{
						completion(sweeps, nil);
					}
					return YES;
				}
				return NO;
			};
			expector.failureCallback = ^(NSError* error){
				if(completion!=nil)
				{
					completion(nil, error);
				}
			};
			request.responseExpector = expector;
			
			[self _queueRequest:request];
		}
		else
		{
			if(completion!=nil)
			{
				completion(nil, error);
			}
		}
	}];
}

-(void)requestAllSweepDefinitions:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	[self requestAllSweepDefinitionsFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestWriteDefaultSweepsFor:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqDefaultSweeps;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestWriteDefaultSweeps:(void(^)(NSError*))completion
{
	[self requestWriteDefaultSweepsFor:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestMaxSweepIndexFrom:(ESPRequestTarget)target completion:(void(^)(NSUInteger, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqMaxSweepIndex;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespMaxSweepIndex];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		if(payload.length>0)
		{
			NSUInteger maxSweepIndex = (NSUInteger)ESPData_getByte(payload, 0);
			if(completion!=nil)
			{
				completion(maxSweepIndex, nil);
			}
		}
		else
		{
			if(completion!=nil)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				completion(0, error);
			}
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(0, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestMaxSweepIndex:(void(^)(NSUInteger, NSError*))completion
{
	[self requestMaxSweepIndexFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestSweepSectionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	ESPSweepSectionsBuilder* builder = [[ESPSweepSectionsBuilder alloc] init];
	
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqSweepSections;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespSweepSections];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		ESPSweepSectionData* sectionData = [[ESPSweepSectionData alloc] initWithData:payload];
		NSArray<ESPFrequencyRange*>* sections = [builder addSectionData:sectionData];
		if(sections!=nil)
		{
			if(completion!=nil)
			{
				completion(sections, nil);
			}
			return YES;
		}
		return NO;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(nil, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestSweepSections:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	[self requestSweepSectionsFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestDefaultSweepDefinitionsFrom:(ESPRequestTarget)target completion:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	[self requestMaxSweepIndexFrom:target completion:^(NSUInteger maxSweepIndex, NSError* error){
		if(error==nil)
		{
			ESPSweepsBuilder* sweepsBuilder = [[ESPSweepsBuilder alloc] initWithMaxSweepIndex:maxSweepIndex];
			
			ESPRequest* request = [ESPRequest request];
			request.target = target;
			request.packetID = ESPPacketReqDefaultSweepDefinitions;
			request.packetData = [NSData data];
			
			ESPResponseExpector* expector = [ESPResponseExpector expector];
			[expector addResponseID:ESPPacketRespDefaultSweepDefinition];
			expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
				NSData* payload = [self _payloadFromPacket:packet];
				ESPCustomSweepData* sweep = [[ESPCustomSweepData alloc] initWithData:payload];
				NSError* sweepError = nil;
				NSArray<ESPFrequencyRange*>* sweeps = [sweepsBuilder addSweep:sweep error:&sweepError];
				if(sweepError!=nil)
				{
					if(completion!=nil)
					{
						completion(nil, sweepError);
					}
					return YES;
				}
				else if(sweeps!=nil)
				{
					if(completion!=nil)
					{
						completion(sweeps, nil);
					}
					return YES;
				}
				return NO;
			};
			expector.failureCallback = ^(NSError* error){
				if(completion!=nil)
				{
					completion(nil, error);
				}
			};
			request.responseExpector = expector;
			
			[self _queueRequest:request];
		}
		else
		{
			if(completion!=nil)
			{
				completion(nil, error);
			}
		}
	}];
}

-(void)requestDefaultSweepDefinitions:(void(^)(NSArray<ESPFrequencyRange*>*, NSError*))completion
{
	[self requestDefaultSweepDefinitionsFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestTurnOffMainDisplayFor:(ESPRequestTarget)target completion:(void(^)(BOOL,NSError*))completion
{
    // Call the new function that supports leaving the Bluetooth indicator on with the default option of having the Bluetooth indicator turned off.
    [self requestTurnOffMainDisplayFor:target withBluetoothIndicatorOn:FALSE completion:completion];
}
-(void)requestTurnOffMainDisplayFor:(ESPRequestTarget)target withBluetoothIndicatorOn:(BOOL) btIndOn completion:(void(^)(BOOL,NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqTurnOffMainDisplay;
    if ( _lastV1Version >=  ALLOW_BT_ON_DISPLAY_OFF_START_VERSION ){
        // Construct an NSData holding the aux0 byte
        Byte auxData [] = { btIndOn ? 0x01 : 0x00 };
        request.packetData = [[NSData alloc] initWithBytes:auxData length:1] ;
    }
    else {
        // Don't send aux1 if the V1 doesn't support
        request.packetData = [NSData data];
    }
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
    if ( target == ESPRequestTargetTechDisplay ){
        // There is no response from the Tech Display to indicate whether or not this was successful. Execute the success callback if the command was sent.
        expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
            if(completion!=nil)
            {
                completion(false, nil);
            }
            return YES;
        };
    }
    else {
        // Wait for display data from the V1 to verify the display is in the correct state
        [expector addResponseID:ESPPacketInfDisplayData];
        __block NSUInteger packetsLeft = 42;
        __weak ESPResponseExpector* _expector = expector;
        expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
            if([self _requestIsInBusyQueue:_expector])
            {
                return NO;
            }
            NSData* payload = [self _payloadFromPacket:packet];
            ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:payload];
            if(displayData.displayOn)
            {
                packetsLeft--;
                if(packetsLeft==0)
                {
                    if(completion!=nil)
                    {
                        completion(displayData.displayOn, nil);
                    }
                    return YES;
                }
                return NO;
            }
            else
            {
                if(completion!=nil)
                {
                    completion(displayData.displayOn, nil);
                }
                return YES;
            }
        };
    }
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			BOOL displayOn = NO;
            if(self->_lastDisplayData!=nil)
			{
                displayOn = self->_lastDisplayData.displayOn;
			}
			completion(displayOn, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestTurnOnMainDisplayFor:(ESPRequestTarget)target completion:(void(^)(BOOL,NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqTurnOnMainDisplay;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
    if ( target == ESPRequestTargetTechDisplay ){
        // There is no response from the Tech Display to indicate whether or not this was successful. Execute the success callback if the command was sent.
        expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
            if(completion!=nil)
            {
                completion(true, nil);
            }
            return YES;
        };
    }
    else {
        // Wait for display data from the V1 to verify the display is in the correct state
        [expector addResponseID:ESPPacketInfDisplayData];
        __block NSUInteger packetsLeft = 42;
        __weak ESPResponseExpector* _expector = expector;
        expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
            if([self _requestIsInBusyQueue:_expector])
            {
                return NO;
            }
            NSData* payload = [self _payloadFromPacket:packet];
            ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:payload];
            if(displayData.displayOn)
            {
                if(completion!=nil)
                {
                    completion(displayData.displayOn, nil);
                }
                return YES;
            }
            else
            {
                packetsLeft--;
                if(packetsLeft==0)
                {
                    if(completion!=nil)
                    {
                        completion(displayData.displayOn, nil);
                    }
                    return YES;
                }
                return NO;
            }
        };
    }
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			BOOL displayOn = NO;
            if(self->_lastDisplayData!=nil)
			{
                displayOn = self->_lastDisplayData.displayOn;
			}
			completion(displayOn, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestMuteOnFor:(ESPRequestTarget)target completion:(void(^)(BOOL, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqMuteOn;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketInfDisplayData];
	__block NSUInteger packetsLeft = 42;
	__weak ESPResponseExpector* _expector = expector;
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if([self _requestIsInBusyQueue:_expector])
		{
			return NO;
		}
		NSData* payload = [self _payloadFromPacket:packet];
		ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:payload];
		if(displayData.soft)
		{
			if(completion!=nil)
			{
				completion(displayData.soft, nil);
			}
			return YES;
		}
		else
		{
			packetsLeft--;
			if(packetsLeft==0)
			{
				if(completion!=nil)
				{
					completion(displayData.soft, nil);
				}
				return YES;
			}
			return NO;
		}
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			BOOL muteOn = NO;
            if(self->_lastDisplayData!=nil)
			{
                muteOn = self->_lastDisplayData.soft;
			}
			completion(muteOn, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestMuteOn:(void(^)(BOOL, NSError*))completion
{
	[self requestMuteOnFor:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestMuteOffFor:(ESPRequestTarget)target completion:(void(^)(BOOL, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqMuteOff;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketInfDisplayData];
	__block NSUInteger packetsLeft = 42;
	__weak ESPResponseExpector* _expector = expector;
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if([self _requestIsInBusyQueue:_expector])
		{
			return NO;
		}
		NSData* payload = [self _payloadFromPacket:packet];
		ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:payload];
		if(displayData.soft)
		{
			packetsLeft--;
			if(packetsLeft==0)
			{
				if(completion!=nil)
				{
					completion(displayData.soft, nil);
				}
				return YES;
			}
			return NO;
		}
		else
		{
			if(completion!=nil)
			{
				completion(displayData.soft, nil);
			}
			return YES;
		}
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			BOOL muteOn = NO;
            if(self->_lastDisplayData!=nil)
			{
                muteOn = self->_lastDisplayData.soft;
			}
			completion(muteOn, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestMuteOff:(void(^)(BOOL, NSError*))completion
{
	[self requestMuteOffFor:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestChangeMode:(ESPV1Mode)mode target:(ESPRequestTarget)target completion:(void(^)(ESPV1Mode, NSError*))completion
{
	if(mode==ESPV1ModeUnknown)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"mode cannot be ESPV1ModeUnknown" userInfo:nil];
	}
	
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqChangeMode;
	request.packetData = [NSData dataWithBytes:(void*)&mode length:1];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketInfDisplayData];
	__block NSUInteger packetsLeft = 42;
	__weak ESPResponseExpector* _expector = expector;
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if([self _requestIsInBusyQueue:_expector])
		{
			return NO;
		}
		NSData* payload = [self _payloadFromPacket:packet];
		ESPDisplayData* displayData = [[ESPDisplayData alloc] initWithData:payload];
		ESPV1Mode mode = displayData.mode;
		if(mode==ESPV1ModeUnknown)
		{
			packetsLeft--;
			if(packetsLeft==0)
			{
				if(completion!=nil)
				{
					completion(mode, nil);
				}
				return YES;
			}
			return NO;
		}
		else
		{
			if(completion!=nil)
			{
				completion(mode, nil);
			}
			return YES;
		}
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(ESPV1ModeUnknown, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestChangeMode:(ESPV1Mode)mode completion:(void(^)(ESPV1Mode, NSError*))completion
{
	[self requestChangeMode:mode target:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestCurrentVolumeFrom:(ESPRequestTarget)target completion:(void (^)(NSData * volumeSettings, NSError * error))completion {
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqCurrentVolume;
    request.packetData = [NSData data];
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    [expector addResponseID:ESPPacketRespCurrentVolume];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        NSData* payload = [self _payloadFromPacket:packet];
        if(payload.length>=2)
        {
            // Extract the main and muted volume from the payload
            Byte mainVolByte = ESPData_getByte(payload, 0);
            Byte mutedVolByte = ESPData_getByte(payload, 1);
            
            Byte defaultBytes[] = { mainVolByte, mutedVolByte};
            // Construct an NSData holding the volumes settings
            NSData* _volumeSettings = [[NSData alloc] initWithBytes:defaultBytes length:2];
            completion(_volumeSettings, nil);
        }
        else
        {
            if(completion!=nil)
            {
                NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
                completion(0, error);
            }
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(0, error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestCurrentVolume:(void (^)(NSData * volumeSettings, NSError * error))completion
{
    [self requestCurrentVolumeFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestAllVolumeFrom:(ESPRequestTarget)target completion:(void (^)(NSData * volumeSettings, NSError * error))completion {
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqAllVolume;
    request.packetData = [NSData data];
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    [expector addResponseID:ESPPacketRespAllVolume];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        NSData* payload = [self _payloadFromPacket:packet];
        if(payload.length>=4)
        {
            // Extract the main and muted volume from the payload
            Byte currentMainVolByte = ESPData_getByte(payload, 0);
            Byte currentMutedVolByte = ESPData_getByte(payload, 1);
            Byte savedMainVolByte = ESPData_getByte(payload, 2);
            Byte savedMutedVolByte = ESPData_getByte(payload, 3);
            
            Byte defaultBytes[] = {currentMainVolByte, currentMutedVolByte, savedMainVolByte, savedMutedVolByte};
            // Construct an NSData holding the volumes settings
            NSData* _volumeSettings = [[NSData alloc] initWithBytes:defaultBytes length:4];
            completion(_volumeSettings, nil);
        }
        else
        {
            if(completion!=nil)
            {
                NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
                completion(0, error);
            }
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(0, error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestAllVolume:(void (^)(NSData * volumeSettings, NSError * error))completion
{
    [self requestAllVolumeFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestWriteVolume:(NSData*)volumeSettings target:(ESPRequestTarget)target completion:(void(^)(NSError* error))completion
{
    if(volumeSettings.length>3)
    {
        volumeSettings = [volumeSettings subdataWithRange:NSMakeRange(0, 3)];
    }
    else if(volumeSettings.length<3)
    {
        NSMutableData* data = [NSMutableData dataWithData:volumeSettings];
        while(data.length<3)
        {
            Byte b = 0xFF;
            [data appendBytes:(void*)&b length:1];
        }
        volumeSettings = data;
    }
    
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqWriteVolume;
    request.packetData = volumeSettings;
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        if(completion!=nil)
        {
            completion(nil);
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestWriteVolume:(NSData*)volumeSettings completion:(void(^)(NSError* error))completion
{
    [self requestWriteVolume:volumeSettings target:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestAbortAudioDelay:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqAbortAudioDelay;
    request.packetData = [NSData data];
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        if(completion!=nil)
        {
            completion(nil);
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestDisplayCurrentVolume:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
    ESPRequest* request = [ESPRequest request];
    request.target = target;
    request.packetID = ESPPacketReqDisplayCurrentVolume;
    request.packetData = [NSData data];
    
    ESPResponseExpector* expector = [ESPResponseExpector expector];
    expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
        if(completion!=nil)
        {
            completion(nil);
        }
        return YES;
    };
    expector.failureCallback = ^(NSError* error){
        if(completion!=nil)
        {
            completion(error);
        }
    };
    request.responseExpector = expector;
    
    [self _queueRequest:request];
}

-(void)requestStartAlertDataFor:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqStartAlertData;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespAlertData];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestStartAlertData:(void(^)(NSError*))completion
{
	[self requestStartAlertDataFor:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestStopAlertDataFor:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqStopAlertData;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestStopAlertData:(void(^)(NSError*))completion
{
	[self requestStopAlertDataFor:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestBatteryVoltageFrom:(ESPRequestTarget)target completion:(void(^)(double, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqBatteryVoltage;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespBatteryVoltage];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		if(payload.length>=2)
		{
			Byte intByte = ESPData_getByte(payload, 0);
			Byte decByte = ESPData_getByte(payload, 1);
			if(decByte < 100)
			{
				double batteryVoltage = ((double)intByte) + (((double)decByte)/100.0);
				if(completion!=nil)
				{
					completion(batteryVoltage, nil);
				}
			}
			else
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				completion(0, error);
			}
		}
		else
		{
			if(completion!=nil)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				completion(0, error);
			}
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(0, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestBatteryVoltage:(void(^)(double, NSError*))completion
{
	[self requestBatteryVoltageFrom:ESPRequestTargetValentineOne completion:completion];
}

-(void)requestSavvyStatusFrom:(ESPRequestTarget)target completion:(void(^)(ESPSavvyStatus*, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqSavvyStatus;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespSavvyStatus];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		ESPSavvyStatus* savvyStatus = [[ESPSavvyStatus alloc] initWithData:payload];
		if(completion!=nil)
		{
			completion(savvyStatus, nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(nil, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestSavvyStatus:(void(^)(ESPSavvyStatus*, NSError*))completion
{
	[self requestSavvyStatusFrom:ESPRequestTargetSavvy completion:completion];
}

-(void)requestVehicleSpeedFrom:(ESPRequestTarget)target completion:(void(^)(NSUInteger, NSError*))completion
{
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqVehicleSpeed;
	request.packetData = [NSData data];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	[expector addResponseID:ESPPacketRespVehicleSpeed];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		NSData* payload = [self _payloadFromPacket:packet];
		if(payload.length>=1)
		{
			NSUInteger vehicleSpeedKPH = (NSUInteger)ESPData_getByte(payload, 0);
			if(completion!=nil)
			{
				completion(vehicleSpeedKPH, nil);
			}
		}
		else
		{
			if(completion!=nil)
			{
				NSError* error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				completion(0, error);
			}
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(0, error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestVehicleSpeed:(void(^)(NSUInteger, NSError*))completion
{
	[self requestVehicleSpeedFrom:ESPRequestTargetSavvy completion:completion];
}

-(void)requestOverrideThumbwheel:(NSUInteger)speedKPH target:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	Byte speedKPHByte = 0;
	if(speedKPH < 255)
	{
		speedKPHByte = (Byte)speedKPH;
	}
	else
	{
		speedKPHByte = 0xFF;
	}
	
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqOverrideThumbwheel;
	request.packetData = [NSData dataWithBytes:(void*)&speedKPHByte length:1];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestOverrideThumbwheel:(NSUInteger)speedKPH completion:(void(^)(NSError*))completion
{
	[self requestOverrideThumbwheel:speedKPH target:ESPRequestTargetSavvy completion:completion];
}

-(void)requestSetSavvyUnmuteEnabled:(BOOL)unmuteEnabled target:(ESPRequestTarget)target completion:(void(^)(NSError*))completion
{
	Byte unmuteByte = unmuteEnabled ? 1 : 0;
	
	ESPRequest* request = [ESPRequest request];
	request.target = target;
	request.packetID = ESPPacketReqSetSavvyUnmuteEnable;
	request.packetData = [NSData dataWithBytes:(void*)&unmuteByte length:1];
	
	ESPResponseExpector* expector = [ESPResponseExpector expector];
	expector.packetRecievedCallback = ^BOOL (ESPPacket* packet){
		if(completion!=nil)
		{
			completion(nil);
		}
		return YES;
	};
	expector.failureCallback = ^(NSError* error){
		if(completion!=nil)
		{
			completion(error);
		}
	};
	request.responseExpector = expector;
	
	[self _queueRequest:request];
}

-(void)requestSetSavvyUnmuteEnabled:(BOOL)unmuteEnabled completion:(void(^)(NSError*))completion
{
	[self requestSetSavvyUnmuteEnabled:unmuteEnabled target:ESPRequestTargetSavvy completion:completion];
}


#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
	if([characteristic.UUID isEqual:_inShort.UUID])
	{
		//short packet
		ESPPacket* packet = [[ESPPacket alloc] initWithData:characteristic.value];
		if(packet!=nil) //if packet was not ill-formed
		{
			[self _handleReceivedPacket:packet];
		}
	}
	else if([characteristic.UUID isEqual:_inLong.UUID])
	{
		//partial packet
		ESPPartialData* partial = [[ESPPartialData alloc] initWithData:characteristic.value];
		ESPPacket* packet = [_partialBuilder addPartial:partial];
		if(packet!=nil) //if packet was completely built and not ill-formed
		{
			[self _handleReceivedPacket:packet];
		}
	}
}

-(void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error
{
    if(error!=nil)
	{
		//an error occured sending the packet
		NSData* sentData = _lastSentData;
		ESPPacket* sentPacket = _lastSentPacket;
		
		//remove the packet from the loopback filter if necessary
		if(!_reportsEchoedPackets)
		{
			[self _checkLoopbackPackets:sentData];
		}
		
		ESPResponseExpector* failedExpector = nil;
		@synchronized(_responseExpectors)
		{
			for(NSUInteger i=0; i<_responseExpectors.count; i++)
			{
				ESPResponseExpector* expector = _responseExpectors[i];
				if([expector hasPacketIdenticalTo:sentPacket])
				{
					failedExpector = expector;
					[_responseExpectors removeObjectAtIndex:i];
					break;
				}
			}
		}
		if(failedExpector!=nil)
		{
			@synchronized(_requestQueue)
			{
				//remove queued requests that have the same expector
				for(NSUInteger i=(_requestQueue.count-1); i!=-1; i--)
				{
					if(_requestQueue[i].responseExpector==failedExpector)
					{
						[_requestQueue removeObjectAtIndex:i];
						[_requestQueueDates removeObjectAtIndex:i];
					}
				}
			}
			failedExpector.failureCallback(error);
		}
	}
}

@end
