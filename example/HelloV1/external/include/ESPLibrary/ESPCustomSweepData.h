/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPFrequencyRange.h"


/*!
 *  ESPCustomSweepData
 *
 *  Discussion:
 *      A packet that represents a single custom sweep (sweep definition) received from the Valentine One.
 */
@interface ESPCustomSweepData : NSObject

-(id)init __attribute__((unavailable("You must use initWithData:, initWithIndex:range:commit:, initWithIndex:lowerEdge:upperEdge:commit:, or initWithCustomSweepData:")));

/*! Initializes a custom sweep from a received packet's payload
	@param data the payload data from a reqWriteSweepDefinition or respSweepDefinition packet
	@returns a newly initialized custom sweep */
-(id)initWithData:(NSData*)data;
/*! Initializes a custom sweep with an index, frequency range, and commit bit
	@param index the index of the custom sweep
	@param range the frequency range of the sweep
	@param commit the commit bit of the sweep, which tells whether the sweep is the last sweep being sent
	@returns a newly initialized custom sweep */
-(id)initWithIndex:(NSUInteger)index range:(ESPFrequencyRange*)range commit:(BOOL)commit;
/*! Initializes a custom sweep with an index, frequency range, and commit bit
	@param index the index of the custom sweep
	@param lowerEdge the lower bound frequency of the sweep
	@param upperEdge the upper bound frequency of the sweep
	@param commit the commit bit of the sweep, which tells whether the sweep is the last sweep being sent
	@returns a newly initialized custom sweep */
-(id)initWithIndex:(NSUInteger)index lowerEdge:(ESPFrequencyMHz)lowerEdge upperEdge:(ESPFrequencyMHz)upperEdge commit:(BOOL)commit;
/*! Initializes a custom sweep by copying data from another custom sweep
	@param customSweepData the custom sweep to copy from
	@returns a newly initialized custom sweep */
-(id)initWithCustomSweepData:(ESPCustomSweepData*)customSweepData;

/// The full payload data of the custom sweep
@property (nonatomic, readonly) NSData* data;

/// The index of the sweep
@property (nonatomic, readonly) NSUInteger index;
/// The range of the sweep
@property (nonatomic, copy, readonly) ESPFrequencyRange* range;
/// The commit bit of the sweep
@property (nonatomic, readonly) BOOL commit;

@end
