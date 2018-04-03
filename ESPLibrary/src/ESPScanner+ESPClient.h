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

-(id)initWithPeripheral:(CBPeripheral*)peripheral inShort:(CBCharacteristic*)inShort inLong:(CBCharacteristic*)inLong outShort:(CBCharacteristic*)outShort outLong:(CBCharacteristic*)outLong;
-(void)_handleDisconnect;

@end
