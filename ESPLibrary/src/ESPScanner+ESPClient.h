/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPScanner.h"
#import "ESPClient.h"

static NSString* const ESPUUIDV1ConnectionLEService = @"92A0AFF4-9E05-11E2-AA59-F23C91AEC05E";

static NSString* const ESPUUIDV1OutClientInShortCharacteristic = @"92A0B2CE-9E05-11E2-AA59-F23C91AEC05E";
static NSString* const ESPUUIDV1OutClientInLongCharacteristic = @"92A0B4E0-9E05-11E2-AA59-F23C91AEC05E";
static NSString* const ESPUUIDClientOutV1InShortCharacteristic = @"92A0B6D4-9E05-11E2-AA59-F23C91AEC05E";
static NSString* const ESPUUIDClientOutV1InLongCharacteristic = @"92A0B8D2-9E05-11E2-AA59-F23C91AEC05E";

@interface ESPClient()
/*! Initialzies the ESPClient
    @param peripheral the connected remote Bluetooth device
    @param inShort the input CBCharacteristic for receiving 'short' data from the V1connectionLEService on peripheral
    @param inLong the input CBCharacteristic for receiving 'long' data from the V1connectionLEService on peripheral.
    @param outShort the output CBCharacteristic for sending 'short' data to the V1connectionLEService on peripheral
    @param outLong the output CBCharacteristic for sending 'long' data to the V1connectionLEService on peripheral.
 */
-(id)initWithPeripheral:(CBPeripheral*)peripheral inShort:(CBCharacteristic*)inShort inLong:(CBCharacteristic*)inLong outShort:(CBCharacteristic*)outShort outLong:(CBCharacteristic*)outLong;
/*! Invoked when a disconnection event occurs. Ideally the connection state should be reset and resources released/close. */
-(void)_handleDisconnect;

@end
