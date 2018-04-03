/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/*!
 *  ESPPartialData
 *
 *  Discussion:
 *    A partial chunk of an ESPPacket. Long ESP Packets (longer than 20 bytes) will be split into chunks using the following rules:
 *    1. The first byte of each chunk will be the Chunk Index Byte, which indicates the chunk index and the number of chunks in the packet.
 *    2. The maximum chunk size, including the Chunk Index Byte, is 20 bytes.
 *    3. Chunks will be transmitted in the correct order. There is not guarantee that the chunks will be received in the correct order
 *      so care must be taken when reassembling chunked packets.
 */
@interface ESPPartialData : NSObject

/*! Initializes the partial from a received block of data
	@param data the block of data of the partial
	@returns a newly initialized partial */
-(id)initWithData:(NSData*)data;

/// The full data of the partial
@property (nonatomic, readonly) NSData* data;

/// The index of the partial
@property (nonatomic, readonly) NSUInteger index;
/// The total number of partials that make up a full ESPPacket
@property (nonatomic, readonly) NSUInteger count;
/// The partial ESPPacket data
@property (nonatomic, readonly) NSData* payload;

@end
