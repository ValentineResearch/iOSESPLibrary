/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import <Foundation/Foundation.h>

/// Represents the origin/destination fields in an ESPPacket
typedef Byte ESPDeviceID;
/// Represents the device identifier for a Concealed Display (CD)
static const ESPDeviceID ESPDeviceConcealedDisplay = 0x00;
/// Represents the device identifier for a Remote Audio (RA)
static const ESPDeviceID ESPDeviceRemoteAudio = 0x01;
/// Represents the device identifier for a Savvy
static const ESPDeviceID ESPDeviceSavvy = 0x02;
/// Represents the device identifier for a Third-Party ESP device (0x3)
static const ESPDeviceID ESPDeviceThirdParty1 = 0x03;
/// Represents the device identifier for a Third-Party ESP device (0x4)
static const ESPDeviceID ESPDeviceThirdParty2 = 0x04;
/// Represents the device identifier for a Third-Party ESP device (0x5)
static const ESPDeviceID ESPDeviceThirdParty3 = 0x05;
/// Represents the device identifier for a V1connection LE ESP Device
static const ESPDeviceID ESPDeviceV1ConnectionLE = 0x06;
/// Represents the device identifier for a all ESP device (General Broadcast)
static const ESPDeviceID ESPDeviceGeneralBroadcast = 0x08;
/// Represents the device identifier for a Valentine 1 without checksum
static const ESPDeviceID ESPDeviceV1WithoutChecksum = 0x09;
/// Represents the device identifier for a Valentine 1 with checksum
static const ESPDeviceID ESPDeviceV1WithChecksum = 0x0A;

/// Represents the packet ID in an ESPPacket
typedef Byte ESPPacketID;
/// Represents the packet identifier for a version request packet
static const ESPPacketID ESPPacketReqVersion = 0x01;
/// Represents the packet identifier for a version response packet
static const ESPPacketID ESPPacketRespVersion = 0x02;
/// Represents the packet identifier for a serial number request packet
static const ESPPacketID ESPPacketReqSerialNumber = 0x03;
/// Represents the packet identifier for a serial number response packet
static const ESPPacketID ESPPacketRespSerialNumber = 0x04;
/// Represents the packet identifier for a user bytes request packet
static const ESPPacketID ESPPacketReqUserBytes = 0x11;
/// Represents the packet identifier for a user bytes request packet
static const ESPPacketID ESPPacketRespUserBytes = 0x12;
/// Represents the packet identifier for a user bytes response packet
static const ESPPacketID ESPPacketReqWriteUserBytes = 0x13;
/// Represents the packet identifier for a factory default settings request packet
static const ESPPacketID ESPPacketReqFactoryDefault = 0x14;
/// Represents the packet identifier for a sweep defintion write request packet
static const ESPPacketID ESPPacketReqWriteSweepDefinition = 0x15;
/// Represents the packet identifier for an all sweep defintions request packet
static const ESPPacketID ESPPacketReqAllSweepDefinitions = 0x16;
/// Represents the packet identifier for a sweep defintions response packet
static const ESPPacketID ESPPacketRespSweepDefiniton = 0x17;
/// Represents the packet identifier for a sweep definition reset request packet
static const ESPPacketID ESPPacketReqDefaultSweeps = 0x18;
/// Represents the packet identifier for a max sweep index request packet
static const ESPPacketID ESPPacketReqMaxSweepIndex = 0x19;
/// Represents the packet identifier for a max sweep index response packet
static const ESPPacketID ESPPacketRespMaxSweepIndex = 0x20;
/// Represents the packet identifier for a sweep write result response packet
static const ESPPacketID ESPPacketRespSweepWriteResult = 0x21;
/// Represents the packet identifier for a sweep sections request packet
static const ESPPacketID ESPPacketReqSweepSections = 0x22;
/// Represents the packet identifier for a sweep sections response packet
static const ESPPacketID ESPPacketRespSweepSections = 0x23;
/// Represents the packet identifier for a default sweep definitions request packet
static const ESPPacketID ESPPacketReqDefaultSweepDefinitions = 0x24;
/// Represents the packet identifier for aa default sweep definitions response packet
static const ESPPacketID ESPPacketRespDefaultSweepDefinition = 0x25;
/// Represents the packet identifier for InfDisplayData packet
static const ESPPacketID ESPPacketInfDisplayData = 0x31;
/// Represents the packet identifier for a turn off main display request packet
static const ESPPacketID ESPPacketReqTurnOffMainDisplay = 0x32;
/// Represents the packet identifier for a turn on main display request packet
static const ESPPacketID ESPPacketReqTurnOnMainDisplay = 0x33;
/// Represents the packet identifier for a mute on request packet
static const ESPPacketID ESPPacketReqMuteOn = 0x34;
/// Represents the packet identifier for a mute off request packet
static const ESPPacketID ESPPacketReqMuteOff = 0x35;
/// Represents the packet identifier for a change mode request packet
static const ESPPacketID ESPPacketReqChangeMode = 0x36;
/// Represents the packet identifier for a start alert data request packet
static const ESPPacketID ESPPacketReqStartAlertData = 0x41;
/// Represents the packet identifier for a stop alert data request packet
static const ESPPacketID ESPPacketReqStopAlertData = 0x42;
/// Represents the packet identifier for alert data packet
static const ESPPacketID ESPPacketRespAlertData = 0x43;
/// Represents the packet identifier for response data packet
static const ESPPacketID ESPPacketRespDataReceived = 0x61;
/// Represents the packet identifier for a battery voltage request packet
static const ESPPacketID ESPPacketReqBatteryVoltage = 0x62;
/// Represents the packet identifier for a battery voltage response packet
static const ESPPacketID ESPPacketRespBatteryVoltage = 0x63;
/// Represents the packet identifier for a unsupported-packet packet
static const ESPPacketID ESPPacketRespUnsupportedPacket = 0x64;
/// Represents the packet identifier for a not processed packet
static const ESPPacketID ESPPacketRespRequestNotProcessed = 0x65;
/// Represents the packet identifier for a inf v1 busy packet
static const ESPPacketID ESPPacketInfV1Busy = 0x66;
/// Represents the packet identifier for a response data error packet
static const ESPPacketID ESPPacketRespDataError = 0x67;
/// Represents the packet identifier for a savvy status request packet
static const ESPPacketID ESPPacketReqSavvyStatus = 0x71;
/// Represents the packet identifier for a savvy status request packet
static const ESPPacketID ESPPacketRespSavvyStatus = 0x72;
/// Represents the packet identifier for a vehicle speed request packet
static const ESPPacketID ESPPacketReqVehicleSpeed = 0x73;
/// Represents the packet identifier for a vehicle speed response packet
static const ESPPacketID ESPPacketRespVehicleSpeed = 0x74;
/// Represents the packet identifier for a override thumbnail request packet
static const ESPPacketID ESPPacketReqOverrideThumbwheel = 0x75;
/// Represents the packet identifier for a set savvy unmute enabled request packet
static const ESPPacketID ESPPacketReqSetSavvyUnmuteEnable = 0x76;

/*!
 *  ESPPacket
 *
 *  Discussion:
 *    A packet that can be sent through an ESPClient. This class represents the data structure which data is transmitted and received between the ESP devices.
 */
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

/// The full data of the packet
@property (nonatomic, readonly) NSData* data;

/// The destination field of the packet.
@property (nonatomic, readonly) ESPDeviceID destination;
/// The origin field of the packet
@property (nonatomic, readonly) ESPDeviceID origin;
/// The packet identifier
@property (nonatomic, readonly) ESPPacketID packetID;
/// The payload of the packet, including the checksum (if any)
@property (nonatomic, readonly) NSData* payload;

@end
