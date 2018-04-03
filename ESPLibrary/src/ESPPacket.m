/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPPacket.h"
#import "ESPDataUtils.h"

@implementation ESPPacket

@synthesize data = _data;

-(id)init
{
	//must initialize with data
	return nil;
}

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [NSData dataWithData:data];
		if(_data.length<6)
		{
			//not big enough to be a valid ESP packet
			return nil;
		}
		Byte* bytes = (Byte*)_data.bytes;
		if(bytes[0]!=0xAA)
		{
			//no start of frame given
			return nil;
		}
		if((bytes[1] & 0xF0) != 0xD0)
		{
			//invalid pre-destination nibble
			return nil;
		}
		if((bytes[2] & 0xF0) != 0xE0)
		{
			//invalid pre-origin nibble
			return nil;
		}
		NSUInteger payloadLength = (NSUInteger)bytes[4];
		NSUInteger endOfFrameIndex = 5+payloadLength;
		if(endOfFrameIndex >= _data.length)
		{
			//invalid payload length or no end of frame
			return nil;
		}
		if(bytes[endOfFrameIndex]!=0xAB)
		{
			//invalid end of frame
			return nil;
		}
	}
	return self;
}

-(id)initWithDestination:(ESPDeviceID)destination origin:(ESPDeviceID)origin packetID:(ESPPacketID)packetID payload:(NSData*)payload checksum:(BOOL)checksum
{
	if(payload.length>255 || (checksum && payload.length>254))
	{
		return nil;
	}
	if(self = [super init])
	{
		size_t packetLength = 5 + (size_t)payload.length + (checksum?1:0) + 1;
		Byte* packetBytes = (Byte*)malloc(packetLength);
		
		packetBytes[0] = 0xAA;
		packetBytes[1] = 0xD0 | ((Byte)destination & 0x0F);
		packetBytes[2] = 0xE0 | ((Byte)origin & 0x0F);
		packetBytes[3] = packetID;
		packetBytes[4] = (Byte)payload.length + (checksum?1:0);
		for(NSUInteger i=0; i<payload.length; i++)
		{
			packetBytes[5+i] = ((Byte*)payload.bytes)[i];
		}
		if(checksum)
		{
			Byte checksum = 0;
			for(NSUInteger i=0; i<(5+payload.length); i++)
			{
				checksum += packetBytes[i];
			}
			packetBytes[5+payload.length] = checksum;
			packetBytes[5+payload.length+1] = 0xAB;
		}
		else
		{
			packetBytes[5+payload.length] = 0xAB;
		}
		
		_data = [NSData dataWithBytes:packetBytes length:(NSUInteger)packetLength];
		free(packetBytes);
	}
	return self;
}

-(BOOL)isEqualToPacket:(ESPPacket*)packet
{
	return [_data isEqualToData:packet->_data];
}

-(BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[ESPPacket class]])
	{
		return [self isEqualToPacket:object];
	}
	return NO;
}

-(BOOL)isChecksumValid
{
	Byte payloadLength = ESPData_getByte(_data, 4);
	NSUInteger checksumIndex = 5 + payloadLength - 1;
	Byte checksum = ((Byte*)_data.bytes)[checksumIndex];
	Byte calcChecksum = 0;
	for(NSUInteger i=0; i<checksumIndex; i++)
	{
		calcChecksum += ((Byte*)_data.bytes)[i];
	}
	if(calcChecksum!=checksum)
	{
		return NO;
	}
	return YES;
}

-(ESPDeviceID)destination
{
	return (ESPData_getByte(_data, 1) & 0x0F);
}

-(ESPDeviceID)origin
{
	return (ESPData_getByte(_data, 2) & 0x0F);
}

-(ESPPacketID)packetID
{
	return ESPData_getByte(_data, 3);
}

-(NSData*)payload
{
	Byte payloadLength = ESPData_getByte(_data, 4);
	return [_data subdataWithRange:NSMakeRange(5, (NSUInteger)payloadLength)];
}

-(NSString*)description
{
	return ESPData_toHexString(_data);
}

@end
