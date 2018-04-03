/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>
#import "ESPFrequencyRange.h"

/*!
 *  ESPSweepSectionData
 *
 *  Discussion:
 *    Represents a respSweepSections packet
 */
@interface ESPSweepSectionData : NSObject

/*! Initializes the sweep sections from the payload of an ESPPacket
	@param data the payload data from a respSweepSections packet
	@returns a newly initialized sweep section data */
-(id)initWithData:(NSData*)data;

/// The full data of the sweep sections
@property (nonatomic, readonly) NSData* data;

/// The number of sections that were in the packet
@property (nonatomic, readonly) NSUInteger numberOfSections;
/// The sweep sections in the packet
@property (nonatomic, readonly) NSArray<ESPFrequencyRange*>* sections;
/// The sweep section indexes in the packet
@property (nonatomic, readonly) NSArray<NSNumber*>* sectionIndexes;
/// The total number of sections
@property (nonatomic, readonly) NSUInteger count;

@end
