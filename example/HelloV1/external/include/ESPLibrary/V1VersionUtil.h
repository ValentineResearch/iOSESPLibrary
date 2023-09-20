//
//  V1VersionUtil.h
//  ESPLibrary
//
//  Created by Jonathan Davis on 11/9/19.
//  Copyright © 2019 Valentine Research, Inc. All rights reserved.
//

#ifndef V1VersionUtil_h
#define V1VersionUtil_h

#define INITIAL_V1_GEN_2_VERSION 40000

#define MAX_V1_GEN_2_VERSION 49999

#define DEFAULT_V1_VERSION 41031

#define INITIAL_V1_GEN_2_VERSION_GROUP 40000

#define DEFAULT_V1_VERSION_STR @"V41031"

#endif /* V1VersionUtil_h */

/// Gets the integral part of the ESP device version string.
/// @param versionStr Non-null ESP device version string
NSUInteger getVersionFor(NSString* versionStr);

/// Returns the V1 version group for the specified version. This is useful for determing if the user settings belong to a V1 from a compatible generation.
/// @param version the version to convert into an NSUInteger.
NSUInteger getVersionGroup(NSUInteger version);
