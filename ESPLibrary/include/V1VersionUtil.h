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

#define INITIAL_V1_GEN_2_VERSION_GROUP 40000

#define ALLOW_KA_SENSITIVITY_ADJUST_START_VERSION  41032

#define ALLOW_BT_ON_DISPLAY_OFF_START_VERSION   41032

#define ALERT_DATA_INCLUDES_JUNK_FLAG_START_VERSION 41032

#define ALLOW_STARTUP_SEQUENCE_DISABLE_START_VERSION  41035

#define ALLOW_RESTING_DISPLAY_DISABLE_START_VERSION  41035

#define ALLOW_BSM_PLUS_ENABLE_START_VERSION 41035

#define DEFAULT_V1_VERSION 41035

#define DEFAULT_V1_VERSION_STR @"V41035"

#endif /* V1VersionUtil_h */

/// Gets the integral part of the ESP device version string.
/// @param versionStr Non-null ESP device version string
NSUInteger getVersionFor(NSString* versionStr);

/// Returns the V1 version group for the specified version. This is useful for determing if the user settings belong to a V1 from a compatible generation.
/// @param version the version to convert into an NSUInteger.
NSUInteger getVersionGroup(NSUInteger version);
