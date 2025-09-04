/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPAlertData.h"
#import "ESPDataUtils.h"
#import "V1VersionUtil.h"

@implementation ESPAlertData

@synthesize data = _data;

@synthesize v1Version = _v1Version;

-(id)init
{
	//must be initialized with data
	return nil;
}

-(id)initWithData:(NSData*)data v1Version:(NSUInteger)version
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:data];
        _v1Version = version;
	}
	return self;
}

-(id)initWithAlertData:(ESPAlertData*)alert
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:alert->_data];
        _v1Version = alert->_v1Version;
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
        case ESPAlertBandPhoto:
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
			return 8;
	}
}

-(BOOL)isPriority
{
	return ESPData_getBit(_data, 6, 7);
}

-(BOOL)isJunkAlert
{
    if(_v1Version < ALERT_DATA_INCLUDES_JUNK_FLAG_START_VERSION) {
        return FALSE;
    }
    
    return ESPData_getBit(_data, 6, 6);
}

-(ESPPhotoRadarType)getPhotoType
{
    if ( _v1Version < ALLOW_PHOTORADAR_START_VERSION ) {
        // Photo not available
        return prtNotPhoto;
    }
    
    Byte photoBits = (ESPData_getByte(_data, 6)) & 0x0F;
    return (ESPPhotoRadarType) photoBits;
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
    ESPAlertBand alertBand = ESPAlertBandInvalid;
    
    Byte bandVal = (ESPData_getByte(_data, 5) & 0b00011111);
    
	if(bandVal==0x01)
	{
        alertBand = ESPAlertBandLaser;
	}
	else if(bandVal==0x02)
	{
        alertBand = ESPAlertBandKa;
	}
	else if(bandVal==0x04)
	{
        alertBand = ESPAlertBandK;
	}
	else if(bandVal==0x08)
	{
        alertBand = ESPAlertBandX;
	}
	else if(bandVal==0x10)
	{
        alertBand = ESPAlertBandKu;
	}
    
    if ( (alertBand == ESPAlertBandK) && ( self.photoType != prtNotPhoto) ) {
        // Override the band and report Photo if necessary
        alertBand = ESPAlertBandPhoto;
    }
    
	return alertBand;
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
	return desc;
}

@end
