/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPPartialData.h"
#import "ESPPacket.h"

/*!
 *  ESPPartialDataBuilder
 *
 *  Discussion:
 *    Adds partial ESP packets together until they make a full packet. Long ESP Packets (longer than 20 bytes) are split into chunks using the following rules:
 *    1. The first byte of each chunk will be the Chunk Index Byte, which indicates the chunk index and the number of chunks in the packet.
 *    2. The maximum chunk size, including the Chunk Index Byte, is 20 bytes.
 *    3. Chunks will be transmitted in the correct order. There is not guarantee that the chunks will be received in the correct order so care must be taken when
 *        reassembling chunked packets.
 */
@interface ESPPartialDataBuilder : NSObject

/*! Adds a partial to attempt to build a full ESPPacket
	@param partial the partial to be added
	@returns a full ESPPacket if one can be constructed, or nil if a full ESPPacket cannot be constructed */
-(ESPPacket*)addPartial:(ESPPartialData*)partial;
/*! Removes all the added partials */
-(void)removeAllPartials;

@end
