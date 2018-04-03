/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPRequest.h"
#import "ESPDataUtils.h"

@implementation ESPRequest

@synthesize target = _target;
@synthesize packetID = _packetID;
@synthesize packetData = _packetData;
@synthesize responseExpector = _responseExpector;
@synthesize minimumProcessingTime = _minimumProcessingTime;

-(id)init
{
	if(self = [super init])
	{
		_target = ESPRequestTargetValentineOne;
		_packetID = 0xFF;
		_packetData = [NSData data];
		_responseExpector = nil;
		_minimumProcessingTime = 0;
	}
	return self;
}

+(instancetype)request
{
	return [[[self class] alloc] init];
}

-(void)setPacketData:(NSData*)packetData
{
	_packetData = [NSData dataWithData:packetData];
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	NSString* targetString = nil;
	switch(_target)
	{
		case ESPRequestTargetValentineOne:
			targetString = @"Valentine One";
			break;
			
		case ESPRequestTargetV1ConnectionLE:
			targetString = @"V1Connection LE";
			break;
			
		case ESPRequestTargetConcealedDisplay:
			targetString = @"Concealed Display";
			break;
			
		case ESPRequestTargetRemoteAudio:
			targetString = @"Remote Audio";
			break;
			
		case ESPRequestTargetSavvy:
			targetString = @"Savvy";
			break;
			
		case ESPRequestTargetThirdParty1:
			targetString = @"Third Party 1";
			break;
			
		case ESPRequestTargetThirdParty2:
			targetString = @"Third Party 2";
			break;
			
		case ESPRequestTargetThirdParty3:
			targetString = @"Third Party 3";
			break;
			
		default:
			targetString = @"Unknown";
			break;
	}
	[desc appendFormat:@"target: %@\n", targetString];
	[desc appendFormat:@"packetID: %02X\n", _packetID];
	[desc appendFormat:@"packetData: %@\n", ESPData_toHexString(_packetData)];
	[desc appendFormat:@"minimumProcessingTime: %f seconds\n", _minimumProcessingTime];
	return desc;
}

@end
