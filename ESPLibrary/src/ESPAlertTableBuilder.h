/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPAlertData.h"

/*!
 *  ESPAlertTableBuilder
 *
 *  Discussion:
 *    Adds alerts together to make a full alert table
 */
@interface ESPAlertTableBuilder : NSObject

/*! Adds an alert to attempt to build a full alert table
	@param alert the alert to add
	@returns an array of alerts if a full alert table can be built, or nil if a full alert table cannot be built */
-(NSArray<ESPAlertData*>*)addAlert:(ESPAlertData*)alert;
/*! Removes all the added alerts */
-(void)removeAllAlerts;

@end
