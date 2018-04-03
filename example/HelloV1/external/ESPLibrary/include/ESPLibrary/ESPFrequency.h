/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

//! frequency represented in MHz
typedef uint16_t ESPFrequencyMHz;
//! frequency represented in GHz
typedef double ESPFrequencyGHz;

//! The maximum frequency that can be represented in the ESPFrequencyMHz data type
#define ESPFrequencyMHzMax UINT16_MAX

//! Converts GHz frequencies to MHz frequencies with a precision of 3 decimal places in the GHz frequency
ESPFrequencyMHz ESPFrequency_GHz_to_MHz(ESPFrequencyGHz GHz);
//! Converts MHz frequencies to GHz frequencies with a precision of 3 decimal places in the GHz frequency
ESPFrequencyGHz ESPFrequency_MHz_to_GHz(ESPFrequencyMHz MHz);
