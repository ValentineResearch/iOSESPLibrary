/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPFrequency.h"

//! Stores a frequency range. This class internally uses ESPFrequencyMHz to store the frequencies, so its precision is limited to what the ESPFrequencyMHz datatype can store */
@interface ESPFrequencyRange : NSObject

/*! Initializes a frequency range with a min and max frequency of 0 MHz (null frequency)
	@returns a newly initialized frequency range */
-(id)init;
/*! Initializes a frequency range with a specified min and max frequency
	@param min the lower bound frequency in MHz
	@param max the upper bound frequency in MHz
	@returns a newly initialized frequency range */
-(id)initWithMinMHz:(ESPFrequencyMHz)min maxMHz:(ESPFrequencyMHz)max;
/*! Initializes a frequency range with a specified min and max frequency
	@param min the lower bound frequency in GHz
	@param max the upper bound frequency in GHz
	@returns a newly initialized frequency range */
-(id)initWithMinGHz:(ESPFrequencyGHz)min maxGHz:(ESPFrequencyGHz)max;
-(id)initWithFrequencyRange:(ESPFrequencyRange*)frequencyRange;

/*! Tells if the frequency range is equal to another frequency range
	@param frequencyRange the frequency range to compare
	@returns YES if they are equal, or NO if they are not equal */
-(BOOL)isEqualToFrequencyRange:(ESPFrequencyRange*)frequencyRange;
/*! Tells if a given frequency falls inside the frequency range
	@param frequency the frequency, in MHz, to check
	@returns YES if the frequency falls within the frequency range, or NO if it does not fall within the frequency */
-(BOOL)containsFrequency:(ESPFrequencyMHz)frequency;
/*! Tells if a another given frequency range falls inside the frequency range
	@param frequencyRange the frequency range to check
	@returns YES if the other given frequency range falls within the frequency range, or NO if it does not fall within the frequency range */
-(BOOL)containsFrequencyRange:(ESPFrequencyRange*)frequencyRange;
/*! Tells if the frequency range overlaps another frequency range
	@param frequencyRange the frequency range to check against
	@returns YES if the ranges overlap, or NO if the ranges do not overlap */
-(BOOL)overlapsFrequencyRange:(ESPFrequencyRange*)frequencyRange;
/*! Splits a frequency range to fit inside other frequency ranges
	@param sections the ranges to confine this frequency range to
	@returns an array of the parts of the frequency range that fit within the given section */
-(NSArray<ESPFrequencyRange*>*)splitRangeToFitSections:(NSArray<ESPFrequencyRange*>*)sections;
/*! Tells if the given range has a min and max frequency of 0
	@returns YES if both the min and max frequencies are 0, or NO if they are not 0 */
-(BOOL)isNull;

//! The lower bound frequency in MHz
@property (nonatomic) ESPFrequencyMHz minMHz;
//! The lower bound frequency in GHz
@property (nonatomic) ESPFrequencyGHz minGHz;

//! The upper bound frequency in MHz
@property (nonatomic) ESPFrequencyMHz maxMHz;
//! The upper bound frequency in GHz
@property (nonatomic) ESPFrequencyGHz maxGHz;

/*! Creates a new array from the input array and removes any frequency ranges with a min and max of 0
	@param frequencyRanges the array of frequency ranges
	@returns a new array created from the input array with all of the "null" frequency ranges removed */
+(NSArray<ESPFrequencyRange*>*)arrayByRemovingNullFrequencyRangesFromArray:(NSArray<ESPFrequencyRange*>*)frequencyRanges;

@end
