/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPCustomSweepData.h"
#import "ESPDataUtils.h"

@implementation ESPCustomSweepData

@synthesize data = _data;

-(id)init
{
	//Must be initialized with data
	return nil;
}

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:data];
	}
	return self;
}

-(id)initWithIndex:(NSUInteger)index range:(ESPFrequencyRange*)range commit:(BOOL)commit
{
	if(self = [super init])
	{
		if(index > 63)
		{
			@throw [NSException exceptionWithName:NSRangeException reason:@"Sweep index is above the max sweep index of 63" userInfo:nil];
		}
		Byte sweepBytes[5] = {0,0,0,0,0};
		Byte indexByte = (((Byte)index) & 0b00111111);
		indexByte |= (1 << 7);
		if(commit)
		{
			indexByte |= (1 << 6);
		}
		sweepBytes[0] = indexByte;
		ESPFrequencyMHz lowerEdge = range.minMHz;
		ESPFrequencyMHz upperEdge = range.maxMHz;
		sweepBytes[1] = (Byte)((upperEdge & 0xFF00) >> 8);
		sweepBytes[2] = (Byte)(upperEdge & 0x00FF);
		sweepBytes[3] = (Byte)((lowerEdge & 0xFF00) >> 8);
		sweepBytes[4] = (Byte)(lowerEdge & 0x00FF);
		_data = [[NSData alloc] initWithBytes:(void*)sweepBytes length:5];
	}
	return self;
}

-(id)initWithIndex:(NSUInteger)index lowerEdge:(ESPFrequencyMHz)lowerEdge upperEdge:(ESPFrequencyMHz)upperEdge commit:(BOOL)commit
{
	if(self = [super init])
	{
		if(index > 63)
		{
			@throw [NSException exceptionWithName:NSRangeException reason:@"Sweep index is above the max sweep index of 63" userInfo:nil];
		}
		Byte sweepBytes[5] = {0,0,0,0,0};
		Byte indexByte = (((Byte)index) & 0b00111111);
		indexByte |= (1 << 7);
		if(commit)
		{
			indexByte |= (1 << 6);
		}
		sweepBytes[0] = indexByte;
		sweepBytes[1] = (Byte)((upperEdge & 0xFF00) >> 8);
		sweepBytes[2] = (Byte)(upperEdge & 0x00FF);
		sweepBytes[3] = (Byte)((lowerEdge & 0xFF00) >> 8);
		sweepBytes[4] = (Byte)(lowerEdge & 0x00FF);
		_data = [[NSData alloc] initWithBytes:(void*)sweepBytes length:5];
	}
	return self;
}

-(id)initWithCustomSweepData:(ESPCustomSweepData*)customSweepData
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:customSweepData->_data];
	}
	return self;
}

-(NSUInteger)index
{
	return (NSUInteger)(ESPData_getByte(_data, 0) & 0b00111111);
}

-(ESPFrequencyRange*)range
{
	uint16_t upperMSB = (uint16_t)ESPData_getByte(_data, 1);
	uint16_t upperLSB = (uint16_t)ESPData_getByte(_data, 2);
	upperMSB = (upperMSB << 8);
	ESPFrequencyMHz upperEdge = (ESPFrequencyMHz)(upperMSB | upperLSB);
	
	uint16_t lowerMSB = (uint16_t)ESPData_getByte(_data, 3);
	uint16_t lowerLSB = (uint16_t)ESPData_getByte(_data, 4);
	lowerMSB = (lowerMSB << 8);
	ESPFrequencyMHz lowerEdge = (ESPFrequencyMHz)(lowerMSB | lowerLSB);
	
	return [[ESPFrequencyRange alloc] initWithMinMHz:lowerEdge maxMHz:upperEdge];
}

-(BOOL)commit
{
	if(ESPData_getByte(_data, 0) & 0b01000000)
	{
		return YES;
	}
	return NO;
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"index: %lu\n", (unsigned long)self.index];
	[desc appendFormat:@"range: %@\n", self.range];
	[desc appendFormat:@"commit: %@\n", (self.commit ? @"yes": @"no")];
	return desc;
}

@end
