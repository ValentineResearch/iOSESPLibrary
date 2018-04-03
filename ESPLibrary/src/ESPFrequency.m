/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPFrequency.h"

ESPFrequencyMHz ESPFrequency_GHz_to_MHz(ESPFrequencyGHz GHz)
{
	return (ESPFrequencyMHz)(GHz*1000);
}

ESPFrequencyGHz ESPFrequency_MHz_to_GHz(ESPFrequencyMHz MHz)
{
	return ((ESPFrequencyGHz)MHz)/1000;
}
