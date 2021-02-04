//
//  ESPClientProtected.h
//  ESPLibrary
//
//  Created by Jonathan Davis on 3/24/20.
//  Copyright © 2020 Valentine Research, Inc. All rights reserved.
//
#import "ESPClient.h"

@interface ESPClient()

/*! Processes the specified ESPPacket received from Bluetooth
    @param packet the ESPPacket to process
 */
-(void)_handleReceivedPacket:(ESPPacket*)packet;

@end
