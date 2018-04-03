/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPAlertData.h"
#import "ESPDataUtils.h"

@implementation ESPAlertData

@synthesize data = _data;

-(id)init
{
	//must be initialized with data
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

-(id)initWithAlertData:(ESPAlertData*)alert
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:alert->_data];
	}
	return self;
}

-(BOOL)isEqualToAlertData:(ESPAlertData*)alertData
{
	return [_data isEqualToData:alertData->_data];
}

-(BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[ESPAlertData class]])
	{
		return [self isEqualToAlertData:object];
	}
	return NO;
}

-(BOOL)isWithinDevianceWindow:(ESPAlertData*)alert
{
	if(self.band != alert.band)
	{
		return NO;
	}
	ESPFrequencyMHz freq = self.frequency;
	ESPFrequencyMHz cmpFreq = alert.frequency;
	ESPFrequencyMHz minFreq = MIN(freq, cmpFreq);
	ESPFrequencyMHz maxFreq = MAX(freq, cmpFreq);
	if((maxFreq - minFreq) > self.deviance)
	{
		return NO;
	}
	return YES;
}

-(NSUInteger)count
{
	return (NSUInteger)(ESPData_getByte(_data, 0) & 0x0F);
}

-(NSUInteger)index
{
	return (NSUInteger)((ESPData_getByte(_data, 0) >> 4) & 0x0F);
}

-(ESPFrequencyMHz)frequency
{
	uint16_t msb = (uint16_t)ESPData_getByte(_data, 1);
	uint16_t lsb = (uint16_t)ESPData_getByte(_data, 2);
	msb = (msb << 8);
	uint16_t freq = (lsb | msb);
	return (ESPFrequencyMHz)freq;
}

-(NSUInteger)frontSignalStrength
{
	return (NSUInteger)ESPData_getByte(_data, 3);
}

-(NSUInteger)rearSignalStrength
{
	return (NSUInteger)ESPData_getByte(_data, 4);
}

//! The alert signal strength to use for the bargraph (0-255)
-(NSUInteger)alertSignalStrength
{
    switch(self.direction)
    {
        default:
        case ESPAlertDirectionInvalid:
            return 0;
            
        case ESPAlertDirectionFront:
            return self.frontSignalStrength;
            break;
            
        case ESPAlertDirectionSide:
            return MAX(self.frontSignalStrength, self.rearSignalStrength);
            break;
            
        case ESPAlertDirectionRear:
            return self.rearSignalStrength;
            break;
    }
}

-(NSUInteger)bargraphSignalStrength
{
    NSUInteger signalStrength = [self alertSignalStrength];
	
	switch(self.band)
	{
		case ESPAlertBandInvalid:
			return 0;
			
		case ESPAlertBandX:
			if(signalStrength>=0xD0)
			{
				return 8;
			}
			else if(signalStrength>=0xC5)
			{
				return 7;
			}
			else if(signalStrength>=0xBD)
			{
				return 6;
			}
			else if(signalStrength>=0xB4)
			{
				return 5;
			}
			else if(signalStrength>=0xAA)
			{
				return 4;
			}
			else if(signalStrength>=0xA0)
			{
				return 3;
			}
			else if(signalStrength>=0x96)
			{
				return 2;
			}
			else if(signalStrength>=0x01)
			{
				return 1;
			}
			return 0;
			
		case ESPAlertBandK:
		case ESPAlertBandKu:
			if(signalStrength>=0xC2)
			{
				return 8;
			}
			else if(signalStrength>=0xB8)
			{
				return 7;
			}
			else if(signalStrength>=0xAE)
			{
				return 6;
			}
			else if(signalStrength>=0xA4)
			{
				return 5;
			}
			else if(signalStrength>=0x9A)
			{
				return 4;
			}
			else if(signalStrength>=0x90)
			{
				return 3;
			}
			else if(signalStrength>=0x88)
			{
				return 2;
			}
			else if(signalStrength>=0x01)
			{
				return 1;
			}
			return 0;
			
		case ESPAlertBandKa:
			if(signalStrength>=0xBA)
			{
				return 8;
			}
			else if(signalStrength>=0xB3)
			{
				return 7;
			}
			else if(signalStrength>=0xAC)
			{
				return 6;
			}
			else if(signalStrength>=0xA5)
			{
				return 5;
			}
			else if(signalStrength>=0x9E)
			{
				return 4;
			}
			else if(signalStrength>=0x97)
			{
				return 3;
			}
			else if(signalStrength>=0x90)
			{
				return 2;
			}
			else if(signalStrength>=0x01)
			{
				return 1;
			}
			return 0;
			
		case ESPAlertBandLaser:
			return 0;
	}
}

-(BOOL)isPriority
{
	return ESPData_getBit(_data, 6, 7);
}

-(ESPAlertDirection)direction
{
	Byte dirVal = ((ESPData_getByte(_data, 5) >> 5) & 0b00000111);
	if(dirVal==0x01)
	{
		return ESPAlertDirectionFront;
	}
	else if(dirVal==0x02)
	{
		return ESPAlertDirectionSide;
	}
	else if(dirVal==0x04)
	{
		return ESPAlertDirectionRear;
	}
	return ESPAlertDirectionInvalid;
}

-(ESPAlertBand)band
{
	Byte bandVal = (ESPData_getByte(_data, 5) & 0b00011111);
	if(bandVal==0x01)
	{
		return ESPAlertBandLaser;
	}
	else if(bandVal==0x02)
	{
		return ESPAlertBandKa;
	}
	else if(bandVal==0x04)
	{
		return ESPAlertBandK;
	}
	else if(bandVal==0x08)
	{
		return ESPAlertBandX;
	}
	else if(bandVal==0x10)
	{
		return ESPAlertBandKu;
	}
	return ESPAlertBandInvalid;
}

-(ESPFrequencyMHz)deviance
{
	switch(self.band)
	{
		case ESPAlertBandInvalid:
			return 0;
			
		case ESPAlertBandLaser:
			return 0;
			
		case ESPAlertBandKa:
			return 6;
			
		case ESPAlertBandK:
			return 5;
			
		case ESPAlertBandX:
			return 2;
			
		case ESPAlertBandKu:
			return 6;
	}
	return 0;
}

-(ESPFrequencyMHz)lowerWindowEdge
{
	ESPFrequencyMHz freq = self.frequency;
	ESPFrequencyMHz deviance = self.deviance;
	if(freq < deviance)
	{
		return 0;
	}
	return freq - deviance;
}

-(ESPFrequencyMHz)upperWindowEdge
{
	ESPFrequencyMHz freq = self.frequency;
	ESPFrequencyMHz deviance = self.deviance;
	if((ESPFrequencyMHzMax-deviance)<freq)
	{
		return ESPFrequencyMHzMax;
	}
	return freq + deviance;
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"count: %lu\n", (unsigned long)self.count];
	[desc appendFormat:@"index: %lu\n", (unsigned long)self.index];
	[desc appendFormat:@"frequency: %lu MHz\n", (unsigned long)self.frequency];
	[desc appendFormat:@"frontSignalStrength: %lu\n", (unsigned long)self.frontSignalStrength];
	[desc appendFormat:@"rearSignalStrength: %lu\n", (unsigned long)self.rearSignalStrength];
	[desc appendFormat:@"bargraphSignalStrength: %lu\n", (unsigned long)self.bargraphSignalStrength];
	[desc appendFormat:@"priority: %@\n", (self.priority ? @"yes" : @"no")];
	NSString* directionString = nil;
	switch(self.direction)
	{
		case ESPAlertDirectionFront:
			directionString = @"front";
			break;
			
		case ESPAlertDirectionSide:
			directionString = @"side";
			break;
			
		case ESPAlertDirectionRear:
			directionString = @"rear";
			break;
			
		default:
		case ESPAlertDirectionInvalid:
			directionString = @"invalid";
			break;
	}
	[desc appendFormat:@"direction: %@\n", directionString];
	NSString* bandString = nil;
	switch(self.band)
	{
		case ESPAlertBandK:
			bandString = @"K";
			break;
			
		case ESPAlertBandX:
			bandString = @"X";
			break;
			
		case ESPAlertBandKa:
			bandString = @"Ka";
			break;
			
		case ESPAlertBandKu:
			bandString = @"Ku";
			break;
			
		case ESPAlertBandLaser:
			bandString = @"Laser";
			break;
			
		default:
		case ESPAlertBandInvalid:
			bandString = @"invalid";
			break;
	}
	[desc appendFormat:@"band: %@\n", bandString];
	[desc appendFormat:@"deviance: %lu MHz\n", (unsigned long)self.deviance];
	[desc appendFormat:@"lowerWindowEdge: %lu MHz\n", (unsigned long)self.lowerWindowEdge];
	[desc appendFormat:@"upperWindowEdge: %lu MHz\n", (unsigned long)self.upperWindowEdge];
	return desc;
}

@end
