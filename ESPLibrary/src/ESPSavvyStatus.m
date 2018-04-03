/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPSavvyStatus.h"
#import "ESPDataUtils.h"

@interface ESPSavvyStatus()
{
	NSMutableData* _data;
}
@end

@implementation ESPSavvyStatus

-(id)init
{
	if(self = [super init])
	{
		Byte bytes[] = {0x00, 0x00};
		_data = [[NSMutableData alloc] initWithBytes:bytes length:2];
	}
	return self;
}

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:data];
	}
	return self;
}

-(id)initWithSavvyStatus:(ESPSavvyStatus*)savvyStatus
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:savvyStatus->_data];
	}
	return self;
}

-(BOOL)isEqualToSavvyStatus:(ESPSavvyStatus*)savvyStatus
{
	if(self.thresholdKPH==savvyStatus.thresholdKPH && self.overriddenByUser==savvyStatus.overriddenByUser && self.unmuteEnabled==savvyStatus.unmuteEnabled)
	{
		return YES;
	}
	return NO;
}

-(BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[ESPSavvyStatus class]])
	{
		return [self isEqualToSavvyStatus:object];
	}
	return NO;
}

-(NSData*)data
{
	return [NSData dataWithData:_data];
}

-(Byte)thresholdKPH
{
	return ESPData_getByte(_data, 0);
}

-(BOOL)overriddenByUser
{
	return ESPData_getBit(_data, 1, 0);
}

-(BOOL)unmuteEnabled
{
	return ESPData_getBit(_data, 1, 1);
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"thresholdKPH: %lu KPH\n", (unsigned long)self.thresholdKPH];
	[desc appendFormat:@"overriddenByUser: %@\n", (self.overriddenByUser ? @"yes" : @"no")];
	[desc appendFormat:@"unmuteEnabled: %@\n", (self.unmuteEnabled ? @"yes" : @"no")];
	return desc;
}

@end
