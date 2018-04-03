/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPFrequencyRange.h"

@implementation ESPFrequencyRange

@synthesize minMHz = _minMHz;
@synthesize maxMHz = _maxMHz;

-(id)init
{
	if(self = [super init])
	{
		_minMHz = 0;
		_maxMHz = 0;
	}
	return self;
}

-(id)initWithMinMHz:(ESPFrequencyMHz)min maxMHz:(ESPFrequencyMHz)max
{
	if(self = [super init])
	{
		_minMHz = min;
		_maxMHz = max;
	}
	return self;
}

-(id)initWithMinGHz:(ESPFrequencyGHz)min maxGHz:(ESPFrequencyGHz)max
{
	if(self = [super init])
	{
		_minMHz = ESPFrequency_GHz_to_MHz(min);
		_maxMHz = ESPFrequency_GHz_to_MHz(max);
	}
	return self;
}

-(id)initWithFrequencyRange:(ESPFrequencyRange*)frequencyRange
{
	if(self = [super init])
	{
		_minMHz = frequencyRange->_minMHz;
		_maxMHz = frequencyRange->_maxMHz;
	}
	return self;
}

+(instancetype)frequencyRangeWithMinMHz:(ESPFrequencyMHz)min maxMHz:(ESPFrequencyMHz)max
{
	return [[self alloc] initWithMinMHz:min maxMHz:max];
}

+(instancetype)frequencyRangeWithMinGHz:(ESPFrequencyGHz)min maxGHz:(ESPFrequencyGHz)max
{
	return [[self alloc] initWithMinGHz:min maxGHz:max];
}

+(instancetype)frequencyRangeWithFrequencyRange:(ESPFrequencyRange*)frequencyRange
{
	return [[self alloc] initWithFrequencyRange:frequencyRange];
}

+(instancetype)nullFrequencyRange
{
	return [[self alloc] initWithMinMHz:0 maxMHz:0];
}

-(BOOL)isEqualToFrequencyRange:(ESPFrequencyRange*)frequencyRange
{
	if(_minMHz==frequencyRange->_minMHz && _maxMHz==frequencyRange->_maxMHz)
	{
		return YES;
	}
	return NO;
}

-(BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[ESPFrequencyRange class]])
	{
		return [self isEqualToFrequencyRange:object];
	}
	return NO;
}

-(BOOL)containsFrequency:(ESPFrequencyMHz)frequency
{
	if(_minMHz <= frequency && frequency <= _maxMHz)
	{
		return YES;
	}
	return NO;
}

-(BOOL)containsFrequencyRange:(ESPFrequencyRange*)frequencyRange
{
	if(_minMHz <= frequencyRange->_minMHz && _maxMHz >= frequencyRange->_maxMHz)
	{
		return YES;
	}
	return NO;
}

-(BOOL)overlapsFrequencyRange:(ESPFrequencyRange*)frequencyRange
{
	if(_maxMHz > frequencyRange->_minMHz && _minMHz < frequencyRange->_maxMHz)
	{
		return YES;
	}
	return NO;
}

-(NSArray<ESPFrequencyRange*>*)splitRangeToFitSections:(NSArray<ESPFrequencyRange*>*)sections
{
	NSMutableArray<ESPFrequencyRange*>* parts = [NSMutableArray<ESPFrequencyRange*> array];
	for(NSUInteger i=0; i<sections.count; i++)
	{
		ESPFrequencyRange* section = sections[i];
		if(_minMHz < section->_maxMHz && _minMHz >= section->_minMHz)
		{
			if(_maxMHz >= section->_maxMHz)
			{
				[parts addObject:[[ESPFrequencyRange alloc] initWithMinMHz:_minMHz maxMHz:section->_maxMHz]];
			}
			else
			{
				[parts addObject:[[ESPFrequencyRange alloc] initWithMinMHz:_minMHz maxMHz:_maxMHz]];
			}
		}
		else if(_maxMHz > section->_minMHz && _maxMHz <= section->_maxMHz)
		{
			if(_minMHz <= section->_minMHz)
			{
				[parts addObject:[[ESPFrequencyRange alloc] initWithMinMHz:section->_minMHz maxMHz:_maxMHz]];
			}
			else
			{
				[parts addObject:[[ESPFrequencyRange alloc] initWithMinMHz:_minMHz maxMHz:_maxMHz]];
			}
		}
	}
	return parts;
}

-(BOOL)isNull
{
	if(_minMHz==0 && _maxMHz==0)
	{
		return YES;
	}
	return NO;
}

-(void)setMinGHz:(ESPFrequencyGHz)minGHz
{
	_minMHz = ESPFrequency_GHz_to_MHz(minGHz);
}

-(ESPFrequencyGHz)minGHz
{
	return ESPFrequency_MHz_to_GHz(_minMHz);
}

-(void)setMaxGHz:(ESPFrequencyGHz)maxGHz
{
	_maxMHz = ESPFrequency_GHz_to_MHz(maxGHz);
}

-(ESPFrequencyGHz)maxGHz
{
	return ESPFrequency_MHz_to_GHz(_maxMHz);
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"(%lu MHz - %lu MHz)", (unsigned long)_minMHz, (unsigned long)_maxMHz];
}

-(NSString*)debugDescription
{
	return [NSString stringWithFormat:@"(%lu MHz - %lu MHz)", (unsigned long)_minMHz, (unsigned long)_maxMHz];
}

+(NSArray<ESPFrequencyRange*>*)arrayByRemovingNullFrequencyRangesFromArray:(NSArray<ESPFrequencyRange*>*)frequencyRanges
{
	NSMutableArray<ESPFrequencyRange*>* nonNullFrequencyRanges = [NSMutableArray<ESPFrequencyRange*> array];
	for(NSUInteger i=0; i<frequencyRanges.count; i++)
	{
		ESPFrequencyRange* frequencyRange = frequencyRanges[i];
		if(![frequencyRange isNull])
		{
			[nonNullFrequencyRanges addObject:frequencyRange];
		}
	}
	return nonNullFrequencyRanges;
}

@end
