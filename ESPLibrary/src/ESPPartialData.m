/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPPartialData.h"
#import "ESPDataUtils.h"

@implementation ESPPartialData

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
		_data = [NSData dataWithData:data];
	}
	return self;
}

-(NSUInteger)index
{
	return (NSUInteger)((ESPData_getByte(_data, 0) >> 4) & 0x0F);
}

-(NSUInteger)count
{
	return (NSUInteger)(ESPData_getByte(_data, 0) & 0x0F);
}

-(NSData*)payload
{
	return [_data subdataWithRange:NSMakeRange(1, _data.length-1)];
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"index: %i\n", (int)self.index];
	[desc appendFormat:@"count: %i\n", (int)self.count];
	[desc appendFormat:@"payload: %@\n", ESPData_toHexString(self.payload)];
	return desc;
}

@end
