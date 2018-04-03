/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPPartialDataBuilder.h"

@interface ESPPartialDataBuilder()
{
	// Maps partials by partial count
	NSMutableDictionary<NSNumber*, NSMutableArray<ESPPartialData*>*>* _partialMap;
}
-(ESPPacket*)_constructPartials:(NSArray<ESPPartialData*>*)partials withCount:(NSUInteger)count;
@end

@implementation ESPPartialDataBuilder

-(id)init
{
	if(self = [super init])
	{
		_partialMap = [NSMutableDictionary<NSNumber*, NSMutableArray<ESPPartialData*>*> dictionary];
	}
	return self;
}

-(ESPPacket*)addPartial:(ESPPartialData*)partial
{
	if(partial.count==1)
	{
		//would probably never happen, but just in case it does
		return [[ESPPacket alloc] initWithData:partial.payload];
	}
	
	@synchronized(self)
	{
		NSMutableArray<ESPPartialData*>* partials = _partialMap[@(partial.count)];
		if(partials==nil)
		{
			partials = [NSMutableArray<ESPPartialData*> array];
			_partialMap[@(partial.count)] = partials;
		}
		for(NSUInteger i=0; i<partials.count; i++)
		{
			if(partials[i].index==partial.index)
			{
				//possible duplicate partial
				//clear partial list and add new partial
				[partials removeAllObjects];
				[partials addObject:partial];
				return nil;
			}
		}
		[partials addObject:partial];
		if(partials.count>=partial.count)
		{
			//there are enough packets to construct a full ESPPacket
			ESPPacket* packet = [self _constructPartials:partials withCount:partial.count];
			if(packet!=nil)
			{
				[_partialMap removeObjectForKey:@(partial.count)];
			}
			return packet;
		}
		return nil;
	}
}

-(ESPPacket*)_constructPartials:(NSArray<ESPPartialData*>*)partials withCount:(NSUInteger)count
{
	NSMutableData* data = [NSMutableData data];
	for(NSUInteger i=0; i<count; i++)
	{
		BOOL foundPartial = NO;
		for(NSUInteger j=(partials.count-1); j!=-1; j--)
		{
			ESPPartialData* partial = partials[j];
			if(partial.index==(i+1))
			{
				[data appendData:partial.payload];
				foundPartial = YES;
				break;
			}
		}
		if(!foundPartial)
		{
			return nil;
		}
	}
	return [[ESPPacket alloc] initWithData:data];
}

-(void)removeAllPartials
{
	@synchronized(self)
	{
		[_partialMap removeAllObjects];
	}
}

@end
