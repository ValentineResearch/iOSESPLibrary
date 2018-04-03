/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/*! Gets a byte from NSData
	@param data the data to retreive the byte from
	@param index the index of the byte
	@returns the byte at the given index, or 0 if the index was outside the range of data */
Byte ESPData_getByte(NSData* data, NSUInteger index);
/*! Gets a bit from NSData
	@param data the data to retreive the bit from
	@param byteIndex the index of the byte
	@param bitIndex the index of the bit in the byte (must be 0-7)
	@returns YES for 1, NO for 0, or NO if the byte index was outside the range of data */
BOOL ESPData_getBit(NSData* data, NSUInteger byteIndex, NSUInteger bitIndex);
/*! Gets a bit from a Byte
	@param byte the byte to retrieve the bit from
	@param bitIndex the index of the bit in the byte (must be 0-7)
	@returns YES for 1, NO for 0 */
BOOL ESPByte_getBit(Byte byte, NSUInteger bitIndex);

/*! Sets a byte in NSMutableData. Automatically resizes the data with 0 padding if the index is outside the range of data
	@param data the data to set the byte in
	@param index the index of the byte
	@param byte the value of the byte to set */
void ESPData_setByte(NSMutableData* data, NSUInteger index, Byte byte);
/*! Sets a bit in NSMutableData. utomatically resizes the data with 0 padding if the byte index is outside the range of data
	@param data the data to set the bit in
	@param byteIndex the index of the byte
	@param bitIndex the index of the bit in the byte (must be 0-7)
	@param bit the value of the bit (YES for 1, NO for 0) */
void ESPData_setBit(NSMutableData* data, NSUInteger byteIndex, NSUInteger bitIndex, BOOL bit);

/*! Creates a hex string from bytes of data
	@param data the data to create the hex string for
	@returns a hex string representing the bytes of the data */
NSString* ESPData_toHexString(NSData* data);
