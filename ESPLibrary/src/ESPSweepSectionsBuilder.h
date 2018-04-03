/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPSweepSectionData.h"

/*!
 *  ESPSweepSectionsBuilder
 *
 *  Discussion:
 *    Adds sweep section data together to make a full list of sweep sections
 */
@interface ESPSweepSectionsBuilder : NSObject

/*! Adds sweep section data to attempt to make a full list of sweep sections
	@param sectionData the sweep section data
	@returns a full list of sweep sections, or nil if a full list could not be constructed */
-(NSArray<ESPFrequencyRange*>*)addSectionData:(ESPSweepSectionData*)sectionData;
/*! Removes all section data */
-(void)removeAllSectionData;

@end
