//
//  V1VersionUtil.m
//  ESPLibrary
//
//  Created by Jonathan Davis on 11/9/19.
//  Copyright © 2019 Valentine Research, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "V1VersionUtil.h"

NSUInteger getVersionFor(NSString* versionStr) {
    NSUInteger versionVal = 0;
    NSUInteger mult = 1;

    const char* versionString = [versionStr UTF8String];
    size_t versionLength = (size_t)strlen(versionString);
    for(size_t i=(versionLength-1); i!=-1; i--)
    {
       char c = versionString[i];
       if(c>='0' && c<='9')
       {
           NSUInteger charVal = (NSUInteger)(c-'0');
           versionVal += (charVal*mult);
           mult *= 10;
       }
    }
    return versionVal;
}

NSUInteger getVersionGroup(NSUInteger version) {
    if(version >= INITIAL_V1_GEN_2_VERSION) {
        double versionD = INITIAL_V1_GEN_2_VERSION_GROUP / ((double) 10000.0);
        return floor(versionD);
    }
    double versionD = version / ((double) 10000.0);
    return floor(versionD);
}
