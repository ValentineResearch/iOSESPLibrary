/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPSweepSectionsBuilder.h"

@interface ESPSweepSectionsBuilder()
{
	//maps section data by section count
	NSMutableDictionary<NSNumber*, NSMutableArray<ESPSweepSectionData*>*>* _sectionMap;
}
-(NSUInteger)_numberOfSectionsInArray:(NSArray<ESPSweepSectionData*>*)sectionDatas;
-(NSArray<ESPFrequencyRange*>*)_constructSections:(NSArray<ESPSweepSectionData*>*)sectionDatas withCount:(NSUInteger)count;
@end

@implementation ESPSweepSectionsBuilder

-(id)init
{
	if(self = [super init])
	{
		_sectionMap = [NSMutableDictionary<NSNumber*, NSMutableArray<ESPSweepSectionData*>*> dictionary];
	}
	return self;
}

-(NSUInteger)_numberOfSectionsInArray:(NSArray<ESPSweepSectionData*>*)sectionDatas
{
	NSUInteger numberOfSections = 0;
	for(NSUInteger i=0; i<sectionDatas.count; i++)
	{
		numberOfSections += sectionDatas[i].numberOfSections;
	}
	return numberOfSections;
}

-(NSArray<ESPFrequencyRange*>*)addSectionData:(ESPSweepSectionData*)sectionData
{
	if(sectionData.count <= sectionData.numberOfSections)
	{
		//just gonna trust that they're in the right order...
		return sectionData.sections;
	}
	else
	{
		NSMutableArray<ESPSweepSectionData*>* sectionDatas = _sectionMap[@(sectionData.count)];
		if(sectionDatas==nil)
		{
			sectionDatas = [NSMutableArray<ESPSweepSectionData*> array];
			_sectionMap[@(sectionData.count)] = sectionDatas;
		}
		[sectionDatas addObject:sectionData];
		if([self _numberOfSectionsInArray:sectionDatas]>=sectionData.count)
		{
			NSArray<ESPFrequencyRange*>* sections = [self _constructSections:sectionDatas withCount:sectionData.count];
			if(sections!=nil)
			{
				[_sectionMap removeObjectForKey:@(sectionData.count)];
			}
			return sections;
		}
		return nil;
	}
}

-(NSArray<ESPFrequencyRange*>*)_constructSections:(NSArray<ESPSweepSectionData*>*)sectionDatas withCount:(NSUInteger)count
{
	NSMutableArray<ESPFrequencyRange*>* sections = [NSMutableArray<ESPFrequencyRange*> array];
	for(NSUInteger i=0; i<count; i++)
	{
		BOOL foundSection = NO;
		for(NSUInteger j=(sectionDatas.count-1); j!=-1; j--)
		{
			ESPSweepSectionData* cmpSectionData = sectionDatas[i];
			NSArray<NSNumber*>* indexes = cmpSectionData.sectionIndexes;
			NSUInteger sectionIndex = -1;
			for(NSUInteger k=0; k<indexes.count; k++)
			{
				if([indexes[k] unsignedIntegerValue]==i)
				{
					sectionIndex = k;
					break;
				}
			}
			if(sectionIndex!=-1)
			{
				[sections addObject:cmpSectionData.sections[sectionIndex]];
				foundSection = YES;
				break;
			}
		}
		if(!foundSection)
		{
			return nil;
		}
	}
	return sections;
}

-(void)removeAllSectionData
{
	[_sectionMap removeAllObjects];
}

@end
