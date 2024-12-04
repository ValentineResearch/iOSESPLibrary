/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPUserBytesBase.h"
#import "ESPDataUtils.h"

@interface ESPUserBytesBase() {}
@end

@implementation ESPUserBytesBase

@synthesize data = _data;

-(id)init
{
	if(self = [super init])
    {
        Byte defaultBytes[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
        _data = [[NSMutableData alloc] initWithBytes:defaultBytes length:6];
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

-(id)initWithUserBytes:(ESPUserBytesBase*)userBytes
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:userBytes->_data];
	}
	return self;
}

-(BOOL)isEqualToUserBytes:(ESPUserBytesBase*)userBytes
{
    return [_data isEqualToData:userBytes->_data];
}

-(void)resetToDefaults
{
	for(NSUInteger i=0; i<_data.length; i++)
	{
		ESPData_setByte(_data, i, 0xFF);
	}
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	return desc;
}

@end
