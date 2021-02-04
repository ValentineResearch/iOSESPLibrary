//
//  ESPScannerProtected.h
//  ESPLibrary
//
//  Created by Jonathan Davis on 3/24/20.
//  Copyright © 2020 Valentine Research, Inc. All rights reserved.
//
#import "ESPScanner.h"

@interface ESPScanner()

/**
 * Returns an array of CBUUID of the CBCharacteristics to discover from the V1 LE Service.
 */
-(NSArray<CBUUID*>*)_characteristicsToDiscover;

/**
 * Constructs a new ESPClient instance using the CBService and CBPeripheral.
 *
 * @param service a service discovered from CBperipharal
 * @param peripheral the bluetooth device a connection was made
 */
-(ESPClient*)_constructESPClientWith:(CBService*)service forPeripheral:(CBPeripheral*)peripheral;

@end
