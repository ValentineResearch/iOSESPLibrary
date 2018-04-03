/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPRequest.h"
#import "ESPClient.h"

@interface ESPClient()

-(ESPDeviceID)_destinationFromRequestTarget:(ESPRequestTarget)target;

-(void)_queueRequest:(ESPRequest*)request;
-(void)_performRequest:(ESPRequest*)request;
-(NSData*)_payloadFromPacket:(ESPPacket*)packet;

-(BOOL)_requestIsInBusyQueue:(ESPResponseExpector*)expector;

-(BOOL)_handleResponsePacket:(ESPPacket*)packet forResponseExpector:(ESPResponseExpector*)responseExpector;

@end
