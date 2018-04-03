/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPSweepsBuilder.h"
#import "ESPRequest.h"

@interface ESPSweepsBuilder()
{
	NSMutableArray<ESPCustomSweepData*>* _sweeps;
}
@end

@implementation ESPSweepsBuilder

@synthesize maxSweepIndex = _maxSweepIndex;

-(id)init
{
	//must be initialized with a max sweep index
	return nil;
}

-(id)initWithMaxSweepIndex:(NSUInteger)maxSweepIndex
{
	if(self = [super init])
	{
		_maxSweepIndex = maxSweepIndex;
		_sweeps = [NSMutableArray<ESPCustomSweepData*> array];
	}
	return self;
}

-(NSArray<ESPFrequencyRange*>*)addSweep:(ESPCustomSweepData*)sweep error:(NSError**)error
{
	for(NSUInteger i=0; i<_sweeps.count; i++)
	{
		if(_sweeps[i].index==sweep.index)
		{
			[_sweeps removeObjectAtIndex:i];
			break;
		}
	}
	[_sweeps addObject:sweep];
	
	if(_sweeps.count>=(_maxSweepIndex+1))
	{
		NSMutableArray<ESPFrequencyRange*>* sweepRanges = [NSMutableArray<ESPFrequencyRange*> array];
		for(NSUInteger i=0; i<=_maxSweepIndex; i++)
		{
			BOOL foundSweep = NO;
			for(NSUInteger j=0; j<_sweeps.count; j++)
			{
				ESPCustomSweepData* cmpSweep = _sweeps[j];
				if(cmpSweep.index==i)
				{
					[sweepRanges addObject:cmpSweep.range];
					foundSweep = YES;
					break;
				}
			}
			if(!foundSweep)
			{
				//missing sweep
				[_sweeps removeAllObjects];
				if(error!=nil)
				{
					*error = [NSError errorWithDomain:ESPRequestErrorDomain code:ESPRequestErrorCodeReceivedBrokenData userInfo:@{NSLocalizedDescriptionKey:@"Received broken data"}];
				}
				return nil;
			}
		}
		[_sweeps removeAllObjects];
		return sweepRanges;
	}
	return nil;
}

-(void)removeAllSweeps
{
	[_sweeps removeAllObjects];
}

@end
