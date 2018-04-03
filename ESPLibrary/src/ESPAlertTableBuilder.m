/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPAlertTableBuilder.h"

@interface ESPAlertTableBuilder()
{
	NSMutableArray<ESPAlertData*>* _alerts;
}
@end

@implementation ESPAlertTableBuilder

-(id)init
{
	if(self = [super init])
	{
		_alerts = [NSMutableArray<ESPAlertData*> array];
	}
	return self;
}

-(NSArray<ESPAlertData*>*)addAlert:(ESPAlertData*)alert
{
	if(alert.count==0)
	{
		[_alerts removeAllObjects];
		return @[];
	}
	//remove duplicates
	for(NSUInteger i=(_alerts.count-1); i!=-1; i--)
	{
		if(alert.index==_alerts[i].index)
		{
			[_alerts removeObjectAtIndex:i];
		}
	}
	//add alert
	[_alerts addObject:alert];
	//check if a full table can be built
	if(_alerts.count>=alert.count)
	{
		NSMutableArray<ESPAlertData*>* alertTable = [NSMutableArray<ESPAlertData*> array];
		for(NSUInteger i=1; i<=alert.count; i++)
		{
			BOOL foundAlert = NO;
			for(NSUInteger j=(_alerts.count-1); j!=-1; j--)
			{
				ESPAlertData* cmpAlert = _alerts[j];
				if(cmpAlert.count==alert.count && cmpAlert.index==i)
				{
					[alertTable addObject:cmpAlert];
					foundAlert = YES;
					break;
				}
			}
			if(!foundAlert)
			{
				return nil;
			}
		}
		[_alerts removeAllObjects];
		return alertTable;
	}
	return nil;
}

-(void)removeAllAlerts
{
	[_alerts removeAllObjects];
}

@end
