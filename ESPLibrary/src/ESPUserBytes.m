/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPUserBytes.h"
#import "ESPDataUtils.h"

NSUInteger ESPKMuteTimerValue_toSeconds(ESPKMuteTimerValue value)
{
	switch(value)
	{
		case ESPKMuteTimer3:
			return 3;
			
		case ESPKMuteTimer4:
			return 4;
			
		case ESPKMuteTimer5:
			return 5;
			
		case ESPKMuteTimer7:
			return 7;
			
		case ESPKMuteTimer10:
			return 10;
			
		case ESPKMuteTimer15:
			return 15;
			
		case ESPKMuteTimer20:
			return 20;
			
		case ESPKMuteTimer30:
			return 30;
	}
	return 0;
}

ESPKMuteTimerValue ESPKMuteTimerValue_fromSeconds(NSUInteger seconds)
{
	if(seconds <= 3)
	{
		return ESPKMuteTimer3;
	}
	else if(seconds <= 4)
	{
		return ESPKMuteTimer4;
	}
	else if(seconds <= 5)
	{
		return ESPKMuteTimer5;
	}
	else if(seconds <= 7)
	{
		return ESPKMuteTimer7;
	}
	else if(seconds <= 10)
	{
		return ESPKMuteTimer10;
	}
	else if(seconds <= 15)
	{
		return ESPKMuteTimer15;
	}
	else if(seconds <= 20)
	{
		return ESPKMuteTimer20;
	}
	return ESPKMuteTimer30;
}

@interface ESPUserBytes()
{
	NSMutableData* _data;
}
@end

@implementation ESPUserBytes

-(id)init
{
	if(self = [super init])
	{
		Byte defaultBytes[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
		_data = [[NSMutableData alloc] initWithBytes:defaultBytes length:6];
	}
	return self;
}

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:data];
	}
	return self;
}

-(id)initWithUserBytes:(ESPUserBytes*)userBytes
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:userBytes->_data];
	}
	return self;
}

-(BOOL)isEqualToUserBytes:(ESPUserBytes*)userBytes
{
	if(self.XBandOn==userBytes.XBandOn && self.KBandOn==userBytes.KBandOn && self.KaBandOn==userBytes.KaBandOn && self.laserOn==userBytes.laserOn && self.bargraphSensitivity==userBytes.bargraphSensitivity && self.KaFalseGuardOn==userBytes.KaFalseGuardOn && self.KMutingOn==userBytes.KMutingOn && self.muteVolumeState==userBytes.muteVolumeState && self.postMuteBogeyLockVolumeState==userBytes.postMuteBogeyLockVolumeState && self.KMuteTimer==userBytes.KMuteTimer && self.KInitialUnmute4LightsOn==userBytes.KInitialUnmute4LightsOn && self.KPersistantUnmute6LightsOn==userBytes.KPersistantUnmute6LightsOn && self.KRearMuteOn==userBytes.KRearMuteOn && self.KuBandOn==userBytes.KuBandOn && self.popOn==userBytes.popOn && self.euroOn==userBytes.euroOn && self.euroXBandOn==userBytes.euroXBandOn && self.filterOn==userBytes.filterOn && self.forceLegacyCD==userBytes.forceLegacyCD)
	{
		return YES;
	}
	return NO;
}

-(BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[ESPUserBytes class]])
	{
		return [self isEqualToUserBytes:object];
	}
	return NO;
}

-(void)resetToDefaults
{
	for(NSUInteger i=0; i<_data.length; i++)
	{
		ESPData_setByte(_data, i, 0xFF);
	}
}

-(NSData*)data
{
	return [NSData dataWithData:_data];
}

-(void)setXBandOn:(BOOL)XBandOn
{
	ESPData_setBit(_data, 0, 0, XBandOn);
}

-(BOOL)XBandOn
{
	return ESPData_getBit(_data, 0, 0);
}

-(void)setKBandOn:(BOOL)KBandOn
{
	ESPData_setBit(_data, 0, 1, KBandOn);
}

-(BOOL)KBandOn
{
	return ESPData_getBit(_data, 0, 1);
}

-(void)setKaBandOn:(BOOL)KaBandOn
{
	ESPData_setBit(_data, 0, 2, KaBandOn);
}

-(BOOL)KaBandOn
{
	return ESPData_getBit(_data, 0, 2);
}

-(void)setLaserOn:(BOOL)laserOn
{
	ESPData_setBit(_data, 0, 3, laserOn);
}

-(BOOL)laserOn
{
	return ESPData_getBit(_data, 0, 3);
}

-(void)setBargraphSensitivity:(ESPBargraphSensitivity)bargraphSensitivity
{
	BOOL bit;
	if(bargraphSensitivity==ESPBargraphSensitivityNormal)
	{
		bit = YES;
	}
	else if(bargraphSensitivity==ESPBargraphSensitivityResponsive)
	{
		bit = NO;
	}
	else
	{
		bit = NO; //< to silence compiler warning
		NSAssert(NO, @"Invalid ESPBargraphSensitivity value");
	}
	ESPData_setBit(_data, 0, 4, bit);
}

-(ESPBargraphSensitivity)bargraphSensitivity
{
	BOOL bit = ESPData_getBit(_data, 0, 4);
	if(bit)
	{
		return ESPBargraphSensitivityNormal;
	}
	else
	{
		return ESPBargraphSensitivityResponsive;
	}
}

-(void)setKaFalseGuardOn:(BOOL)KaFalseGuardOn
{
	ESPData_setBit(_data, 0, 5, KaFalseGuardOn);
}

-(BOOL)KaFalseGuardOn
{
	return ESPData_getBit(_data, 0, 5);
}

-(void)setKMutingOn:(BOOL)KMutingOn
{
	ESPData_setBit(_data, 0, 6, !KMutingOn);
}

-(BOOL)KMutingOn
{
	return !ESPData_getBit(_data, 0, 6);
}

-(void)setMuteVolumeState:(ESPMuteVolumeState)muteVolumeState
{
	BOOL bit;
	if(muteVolumeState==ESPMuteVolumeLever)
	{
		bit = YES;
	}
	else if(muteVolumeState==ESPMuteVolumeZero)
	{
		bit = NO;
	}
	else
	{
		bit = NO; //< to silence compiler warning
		NSAssert(NO, @"Invalid ESPMuteVolumeState value");
	}
	ESPData_setBit(_data, 0, 7, bit);
}

-(ESPMuteVolumeState)muteVolumeState
{
	BOOL bit = ESPData_getBit(_data, 0, 7);
	if(bit)
	{
		return ESPMuteVolumeLever;
	}
	else
	{
		return ESPMuteVolumeZero;
	}
}

-(void)setPostMuteBogeyLockVolumeState:(ESPPostMuteBogeyLockVolumeState)postMuteBogeyLockVolumeState
{
	BOOL bit;
	if(postMuteBogeyLockVolumeState==ESPPostMuteBogeyLockVolumeKnob)
	{
		bit = YES;
	}
	else if(postMuteBogeyLockVolumeState==ESPPostMuteBogeyLockVolumeLever)
	{
		bit = NO;
	}
	else
	{
		bit = NO; //< to silence compiler warning
		NSAssert(NO, @"Invalid ESPPostMuteBogeyLockVolumeState value");
	}
	ESPData_setBit(_data, 1, 0, bit);
}

-(ESPPostMuteBogeyLockVolumeState)postMuteBogeyLockVolumeState
{
	BOOL bit = ESPData_getBit(_data, 1, 0);
	if(bit)
	{
		return ESPPostMuteBogeyLockVolumeKnob;
	}
	else
	{
		return ESPPostMuteBogeyLockVolumeLever;
	}
}

-(void)setKMuteTimer:(ESPKMuteTimerValue)KMuteTimer
{
	ESPData_setBit(_data, 1, 1, ESPByte_getBit((Byte)KMuteTimer, 0));
	ESPData_setBit(_data, 1, 2, ESPByte_getBit((Byte)KMuteTimer, 1));
	ESPData_setBit(_data, 1, 3, ESPByte_getBit((Byte)KMuteTimer, 2));
}

-(ESPKMuteTimerValue)KMuteTimer
{
	Byte kMuteByte = ESPData_getByte(_data, 1);
	kMuteByte = ((kMuteByte >> 1) & 0b00000111);
	return (ESPKMuteTimerValue)kMuteByte;
}

-(void)setKInitialUnmute4LightsOn:(BOOL)KInitialUnmute4LightsOn
{
	ESPData_setBit(_data, 1, 4, KInitialUnmute4LightsOn);
}

-(BOOL)KInitialUnmute4LightsOn
{
	return ESPData_getBit(_data, 1, 4);
}

-(void)setKPersistantUnmute6LightsOn:(BOOL)KPersistantUnmute6LightsOn
{
	ESPData_setBit(_data, 1, 5, KPersistantUnmute6LightsOn);
}

-(BOOL)KPersistantUnmute6LightsOn
{
	return ESPData_getBit(_data, 1, 5);
}

-(void)setKRearMuteOn:(BOOL)KRearMuteOn
{
	ESPData_setBit(_data, 1, 6, !KRearMuteOn);
}

-(BOOL)KRearMuteOn
{
	return !ESPData_getBit(_data, 1, 6);
}

-(void)setKuBandOn:(BOOL)KuBandOn
{
	ESPData_setBit(_data, 1, 7, !KuBandOn);
}

-(BOOL)KuBandOn
{
	return !ESPData_getBit(_data, 1, 7);
}

-(void)setPopOn:(BOOL)popOn
{
	ESPData_setBit(_data, 2, 0, popOn);
}

-(BOOL)popOn
{
	return ESPData_getBit(_data, 2, 0);
}

-(void)setEuroOn:(BOOL)euroOn
{
	ESPData_setBit(_data, 2, 1, !euroOn);
}

-(BOOL)euroOn
{
	return !ESPData_getBit(_data, 2, 1);
}

-(void)setEuroXBandOn:(BOOL)euroXBandOn
{
	ESPData_setBit(_data, 2, 2, !euroXBandOn);
}

-(BOOL)euroXBandOn
{
	return !ESPData_getBit(_data, 2, 2);
}

-(void)setFilterOn:(BOOL)filterOn
{
	ESPData_setBit(_data, 2, 3, !filterOn);
}

-(BOOL)filterOn
{
	return !ESPData_getBit(_data, 2, 3);
}

-(void)setForceLegacyCD:(BOOL)forceLegacyCD
{
	ESPData_setBit(_data, 2, 4, !forceLegacyCD);
}

-(BOOL)forceLegacyCD
{
	return !ESPData_getBit(_data, 2, 4);
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"XBandOn: %@\n", (self.XBandOn ? @"yes" : @"no")];
	[desc appendFormat:@"KBandOn: %@\n", (self.KBandOn ? @"yes" : @"no")];
	[desc appendFormat:@"KaBandOn: %@\n", (self.KaBandOn ? @"yes" : @"no")];
	[desc appendFormat:@"laserOn: %@\n", (self.laserOn ? @"yes" : @"no")];
	NSString* bargraphSensitivityString = nil;
	switch(self.bargraphSensitivity)
	{
		case ESPBargraphSensitivityNormal:
			bargraphSensitivityString = @"normal";
			break;
			
		case ESPBargraphSensitivityResponsive:
			bargraphSensitivityString = @"responsive";
			break;
			
		default:
			bargraphSensitivityString = @"invalid";
			break;
	}
	[desc appendFormat:@"bargraphSensitivity: %@\n", bargraphSensitivityString];
	[desc appendFormat:@"KaFalseGuardOn: %@\n", (self.KaFalseGuardOn ? @"yes" : @"no")];
	[desc appendFormat:@"KMutingOn: %@\n", (self.KMutingOn ? @"yes" : @"no")];
	NSString* muteVolumeStateString = nil;
	switch(self.muteVolumeState)
	{
		case ESPMuteVolumeZero:
			muteVolumeStateString = @"zero";
			break;
			
		case ESPMuteVolumeLever:
			muteVolumeStateString = @"lever";
			break;
			
		default:
			muteVolumeStateString = @"invalid";
			break;
	}
	[desc appendFormat:@"muteVolumeState: %@\n", muteVolumeStateString];
	NSString* postMuteBogeyLockVolumeStateString = nil;
	switch(self.postMuteBogeyLockVolumeState)
	{
		case ESPPostMuteBogeyLockVolumeKnob:
			postMuteBogeyLockVolumeStateString = @"knob";
			break;
			
		case ESPPostMuteBogeyLockVolumeLever:
			postMuteBogeyLockVolumeStateString = @"lever";
			break;
			
		default:
			postMuteBogeyLockVolumeStateString = @"invalid";
			break;
	}
	[desc appendFormat:@"postMuteBogeyLockVolumeState: %@\n", postMuteBogeyLockVolumeStateString];
	NSString* KMuteTimerString = @(ESPKMuteTimerValue_toSeconds(self.KMuteTimer)).stringValue;
	[desc appendFormat:@"KMuteTimer: %@ seconds\n", KMuteTimerString];
	[desc appendFormat:@"KInitialUnmute4LightsOn: %@\n", (self.KInitialUnmute4LightsOn ? @"yes" : @"no")];
	[desc appendFormat:@"KPersistantUnmute6LightsOn: %@\n", (self.KPersistantUnmute6LightsOn ? @"yes" : @"no")];
	[desc appendFormat:@"KRearMuteOn: %@\n", (self.KRearMuteOn ? @"yes" : @"no")];
	[desc appendFormat:@"KuBandOn: %@\n", (self.KuBandOn ? @"yes" : @"no")];
	[desc appendFormat:@"popOn: %@\n", (self.popOn ? @"yes" : @"no")];
	[desc appendFormat:@"euroOn: %@\n", (self.euroOn ? @"yes" : @"no")];
	[desc appendFormat:@"euroXBandOn: %@\n", (self.euroXBandOn ? @"yes" : @"no")];
	[desc appendFormat:@"filterOn: %@\n", (self.filterOn ? @"yes" : @"no")];
	[desc appendFormat:@"forceLegacyCD: %@\n", (self.forceLegacyCD ? @"yes" : @"no")];
	return desc;
}

@end
