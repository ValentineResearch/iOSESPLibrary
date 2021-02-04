/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPFrequencyRange.h"
#import "ESPCustomSweepData.h"

/*!
 *  ESPSweepsBuilder
 *
 *  Discussion:
 *    Adds sweeps together to make a full sweeps list
 */
@interface ESPSweepsBuilder : NSObject

/*! Initializes the sweeps builder with a max sweep index
	@param maxSweepIndex the index of the last sweep in the sweep list
	@returns a newly initialized sweeps builder */
-(id)initWithMaxSweepIndex:(NSUInteger)maxSweepIndex;

/*! Adds sweep data to attempt to make a full list of sweeps
	@param sweep the sweep data
	@param error a pointer to an error object that will be set if an error occurs constructing sweeps; If error is set, then the partial sweeps list has also been cleared
	@returns a full list of sweeps, or nil if a full list could not be constructed */
-(NSArray<ESPFrequencyRange*>*)addSweep:(ESPCustomSweepData*)sweep error:(NSError**)error;
/*! Remove all previously added sweeps
 */
-(void)removeAllSweeps;

/// The index of the last sweep in the sweep list
@property (nonatomic) NSUInteger maxSweepIndex;

@end
