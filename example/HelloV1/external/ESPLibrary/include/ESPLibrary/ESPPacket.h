/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

//! Represents the origin/destination fields in an ESPPacket
typedef Byte ESPDeviceID;
static const ESPDeviceID ESPDeviceConcealedDisplay = 0x00;
static const ESPDeviceID ESPDeviceRemoteAudio = 0x01;
static const ESPDeviceID ESPDeviceSavvy = 0x02;
static const ESPDeviceID ESPDeviceThirdParty1 = 0x03;
static const ESPDeviceID ESPDeviceThirdParty2 = 0x04;
static const ESPDeviceID ESPDeviceThirdParty3 = 0x05;
static const ESPDeviceID ESPDeviceV1ConnectionLE = 0x06;
static const ESPDeviceID ESPDeviceGeneralBroadcast = 0x08;
static const ESPDeviceID ESPDeviceV1WithoutChecksum = 0x09;
static const ESPDeviceID ESPDeviceV1WithChecksum = 0x0A;

//! Represents the packet ID in an ESPPacket
typedef Byte ESPPacketID;
static const ESPPacketID ESPPacketReqVersion = 0x01;
static const ESPPacketID ESPPacketRespVersion = 0x02;
static const ESPPacketID ESPPacketReqSerialNumber = 0x03;
static const ESPPacketID ESPPacketRespSerialNumber = 0x04;
static const ESPPacketID ESPPacketReqUserBytes = 0x11;
static const ESPPacketID ESPPacketRespUserBytes = 0x12;
static const ESPPacketID ESPPacketReqWriteUserBytes = 0x13;
static const ESPPacketID ESPPacketReqFactoryDefault = 0x14;
static const ESPPacketID ESPPacketReqWriteSweepDefinition = 0x15;
static const ESPPacketID ESPPacketReqAllSweepDefinitions = 0x16;
static const ESPPacketID ESPPacketRespSweepDefiniton = 0x17;
static const ESPPacketID ESPPacketReqDefaultSweeps = 0x18;
static const ESPPacketID ESPPacketReqMaxSweepIndex = 0x19;
static const ESPPacketID ESPPacketRespMaxSweepIndex = 0x20;
static const ESPPacketID ESPPacketRespSweepWriteResult = 0x21;
static const ESPPacketID ESPPacketReqSweepSections = 0x22;
static const ESPPacketID ESPPacketRespSweepSections = 0x23;
static const ESPPacketID ESPPacketReqDefaultSweepDefinitions = 0x24;
static const ESPPacketID ESPPacketRespDefaultSweepDefinition = 0x25;
static const ESPPacketID ESPPacketInfDisplayData = 0x31;
static const ESPPacketID ESPPacketReqTurnOffMainDisplay = 0x32;
static const ESPPacketID ESPPacketReqTurnOnMainDisplay = 0x33;
static const ESPPacketID ESPPacketReqMuteOn = 0x34;
static const ESPPacketID ESPPacketReqMuteOff = 0x35;
static const ESPPacketID ESPPacketReqChangeMode = 0x36;
static const ESPPacketID ESPPacketReqStartAlertData = 0x41;
static const ESPPacketID ESPPacketReqStopAlertData = 0x42;
static const ESPPacketID ESPPacketRespAlertData = 0x43;
static const ESPPacketID ESPPacketRespDataReceived = 0x61;
static const ESPPacketID ESPPacketReqBatteryVoltage = 0x62;
static const ESPPacketID ESPPacketRespBatteryVoltage = 0x63;
static const ESPPacketID ESPPacketRespUnsupportedPacket = 0x64;
static const ESPPacketID ESPPacketRespRequestNotProcessed = 0x65;
static const ESPPacketID ESPPacketInfV1Busy = 0x66;
static const ESPPacketID ESPPacketRespDataError = 0x67;
static const ESPPacketID ESPPacketReqSavvyStatus = 0x71;
static const ESPPacketID ESPPacketRespSavvyStatus = 0x72;
static const ESPPacketID ESPPacketReqVehicleSpeed = 0x73;
static const ESPPacketID ESPPacketRespVehicleSpeed = 0x74;
static const ESPPacketID ESPPacketReqOverrideThumbwheel = 0x75;
static const ESPPacketID ESPPacketReqSetSavvyUnmuteEnable = 0x76;


//! A packet that can be sent through an ESPClient
@interface ESPPacket : NSObject

-(id)init __attribute__((unavailable("You must use initWithData: or initWithDestination:origin:packetID:payload:checksum:")));

/*! Initializes a packet from a received block of data.
	@param data the block of data of the packet
	@returns a newly initialized packet, or nil if the data does not match the structure of an ESP packet */
-(id)initWithData:(NSData*)data;
/*! Initializes a packet with specified information.
	@param destination the destination of the packet
	@param origin the sender of the packet
	@param packetID the ID of the packet
	@param payload the payload data
	@param checksum tells whether to include a checksum
	@returns a newly initialized packet, or nil if the payload was too big */
-(id)initWithDestination:(ESPDeviceID)destination origin:(ESPDeviceID)origin packetID:(ESPPacketID)packetID payload:(NSData*)payload checksum:(BOOL)checksum;

/* Tells if this packet's data is equal to another packet's data
	@param packet the packet to compare against
	@returns YES if the packets are equal, or NO if the packets are not equal */
-(BOOL)isEqualToPacket:(ESPPacket*)packet;

/*! Verify the checksum. Only perform this check if you know the ESP packet has a checksum. Otherwise, it will most likely fail
	@returns YES if the checksum is valid, or NO if the checksum is not valid */
-(BOOL)isChecksumValid;

//! The full data of the packet
@property (nonatomic, readonly) NSData* data;

//! The destination field of the packet
@property (nonatomic, readonly) ESPDeviceID destination;
//! The origin field of the packet
@property (nonatomic, readonly) ESPDeviceID origin;
//! The packet identifier
@property (nonatomic, readonly) ESPPacketID packetID;
//! The payload of the packet, including the checksum (if any)
@property (nonatomic, readonly) NSData* payload;

@end
