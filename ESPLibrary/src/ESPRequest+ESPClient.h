/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPRequest.h"
#import "ESPClient.h"

@interface ESPClient()
/*! Return the Destination/DeviceID for the specified request target
    @param target the target ESP device to send a request
 */
-(ESPDeviceID)_destinationFromRequestTarget:(ESPRequestTarget)target;
/*! Adds request to the top of the send queue
    @param request ESPRequest to be sent
 */
-(void)_queueRequest:(ESPRequest*)request;
/*! Clears all pending requests */
-(void)_clearRequests;
/*! Performs the specified ESPRequest
    @param request the ESPRequest to perform
 */
-(void)_performRequest:(ESPRequest*)request;
/*! Returns the payload for the specified ESPPacket
    @param packet the target packet whose payload should be returned
 */
-(NSData*)_payloadFromPacket:(ESPPacket*)packet;
/*! Indicates if there is request in the busy queue for the specified response expector.
    @param expector the expector of the request to check for busy
 */
-(BOOL)_requestIsInBusyQueue:(ESPResponseExpector*)expector;
/*! Responds to an incomplete ESPRequest
    @param packet response to an ESPRequest
    @param responseExpector a callback awaiting a response
 */
-(BOOL)_handleResponsePacket:(ESPPacket*)packet forResponseExpector:(ESPResponseExpector*)responseExpector;

@end
