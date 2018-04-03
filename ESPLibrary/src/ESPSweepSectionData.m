/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPSweepSectionData.h"
#import "ESPDataUtils.h"

@interface ESPSweepSectionData()
@end

@implementation ESPSweepSectionData

@synthesize data = _data;

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [NSData dataWithData:data];
	}
	return self;
}

-(NSUInteger)numberOfSections
{
	if(_data.length>=15)
	{
		return 3;
	}
	else if(_data.length>=10)
	{
		return 2;
	}
	else if(_data.length>=5)
	{
		return 1;
	}
	return 0;
}

-(NSArray<ESPFrequencyRange*>*)sections
{
	NSUInteger numberOfSections = self.numberOfSections;
	NSUInteger dataIndex = 0;
	NSMutableArray<ESPFrequencyRange*>* sections = [NSMutableArray<ESPFrequencyRange*> array];
	for(NSUInteger i=0; i<numberOfSections; i++)
	{
		uint16_t upperMSB = ESPData_getByte(_data, dataIndex+1);
		upperMSB = (upperMSB << 8);
		uint16_t upperLSB = ESPData_getByte(_data, dataIndex+2);
		uint16_t lowerMSB = ESPData_getByte(_data, dataIndex+3);
		lowerMSB = (lowerMSB << 8);
		uint16_t lowerLSB = ESPData_getByte(_data, dataIndex+4);
		ESPFrequencyRange* section = [[ESPFrequencyRange alloc] initWithMinMHz:(ESPFrequencyMHz)(lowerLSB | lowerMSB) maxMHz:(ESPFrequencyMHz)(upperLSB | upperMSB)];
		[sections addObject:section];
		dataIndex += 5;
	}
	return sections;
}

-(NSArray<NSNumber*>*)sectionIndexes
{
	NSUInteger numberOfSections = self.numberOfSections;
	NSUInteger dataIndex = 0;
	NSMutableArray<NSNumber*>* indexes = [NSMutableArray<NSNumber*> array];
	for(NSUInteger i=0; i<numberOfSections; i++)
	{
		Byte indexByte = ESPData_getByte(_data, dataIndex);
		NSUInteger index = (NSUInteger)((indexByte  >> 4) & 0x0F);
		[indexes addObject:@(index)];
		dataIndex += 5;
	}
	return indexes;
}

-(NSUInteger)count
{
	NSUInteger numberOfSections = self.numberOfSections;
	if(numberOfSections==0)
	{
		return 0;
	}
	return (NSUInteger)(ESPData_getByte(_data, 0) & 0x0F);
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"count: %i\n", (int)self.count];
	NSArray<ESPFrequencyRange*>* sections = self.sections;
	NSArray<NSNumber*>* sectionIndexes = self.sectionIndexes;
	for(NSUInteger i=0; i<sections.count; i++)
	{
		[desc appendFormat:@"%@: %@\n", sectionIndexes[i], sections[i]];
	}
	return desc;
}

@end
