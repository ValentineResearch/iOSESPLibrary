/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

Byte ESPData_getByte(NSData* data, NSUInteger index)
{
	if(data.length>index)
	{
		return ((Byte*)data.bytes)[index];
	}
	return 0x00;
}

BOOL ESPData_getBit(NSData* data, NSUInteger byteIndex, NSUInteger bitIndex)
{
	assert(bitIndex<8);
	Byte byte = ESPData_getByte(data, byteIndex);
	return (BOOL)((byte >> bitIndex) & 0x01);
}

BOOL ESPByte_getBit(Byte byte, NSUInteger bitIndex)
{
	assert(bitIndex<8);
	return (BOOL)((byte >> bitIndex) & 0x01);
}

void ESPData_setByte(NSMutableData* data, NSUInteger index, Byte byte)
{
	while(index>=data.length)
	{
		Byte emptyByte = 0;
		[data appendBytes:&emptyByte length:1];
	}
	[data replaceBytesInRange:NSMakeRange(index, 1) withBytes:(void*)&byte length:1];
}

void ESPData_setBit(NSMutableData* data, NSUInteger byteIndex, NSUInteger bitIndex, BOOL bit)
{
	assert(bitIndex<8);
	Byte byte = ESPData_getByte(data, byteIndex);
	if(bit)
	{
		byte |= 1 << bitIndex;
	}
	else
	{
		byte &= ~(1 << bitIndex);
	}
	ESPData_setByte(data, byteIndex, byte);
}

NSString* ESPData_toHexString(NSData* data)
{
	NSMutableString* str = [NSMutableString string];
	NSUInteger length = data.length;
	unsigned char* bytes = (unsigned char*)data.bytes;
	for(NSUInteger i=0; i<length; i++)
	{
		[str appendFormat:@"%02X", (unsigned int)bytes[i]];
		if(i<(length-1))
		{
			[str appendString:@" "];
		}
	}
	return str;
}
