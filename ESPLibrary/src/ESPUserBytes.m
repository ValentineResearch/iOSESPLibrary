/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPUserBytes.h"
#import "ESPDataUtils.h"
#import "V1VersionUtil.h"

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

@interface ESPUserBytes() {
	NSMutableData* _data;
}
@end

@implementation ESPUserBytes

@synthesize v1Version = _v1Version;

-(id)init
{
	if(self = [super init])
    {
        Byte defaultBytes[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
        _data = [[NSMutableData alloc] initWithBytes:defaultBytes length:6];
        _v1Version = DEFAULT_V1_VERSION;
    }
	return self;
}

-(id)initWithV1Version:(NSUInteger)version {
    if(self = [self init])
    {
        _v1Version = version;
    }
    return self;
}

-(id)initWithData:(NSData*)data v1Version:(NSUInteger)version
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:data];
        _v1Version = version;
	}
	return self;
}

-(id)initWithUserBytes:(ESPUserBytes*)userBytes
{
	if(self = [super init])
	{
		_data = [[NSMutableData alloc] initWithData:userBytes->_data];
        _v1Version = userBytes->_v1Version;
	}
	return self;
}

-(BOOL)isEqualToUserBytes:(ESPUserBytes*)userBytes
{
    NSUInteger myVersionGroup = getVersionGroup(_v1Version);
    NSUInteger otherVersionGroup = getVersionGroup(userBytes->_v1Version);
    // If the version groups don't match, the user bytes cannot be considered equivalent
    if(myVersionGroup != otherVersionGroup) {
        return false;
    }
    return [_data isEqualToData:userBytes->_data];
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

- (void)setV1Version:(NSUInteger)v1Version {
    _v1Version = v1Version;
    // Whenever the v1 version changes we need to reset the internal bytes back to defaults.
    [self resetToDefaults];
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

-(void)setBargraphSensitivity:(ESPBargraphSensitivity)bargraphSensitivity {
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
    
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

-(ESPBargraphSensitivity)bargraphSensitivity {
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return 0;
    }
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
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
    
	ESPData_setBit(_data, 0, 5, KaFalseGuardOn);
}

-(BOOL)KaFalseGuardOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return ESPData_getBit(_data, 0, 5);
}

-(void)setKMutingOn:(BOOL)KMutingOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
    
	ESPData_setBit(_data, 0, 6, !KMutingOn);
}

-(BOOL)KMutingOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return !ESPData_getBit(_data, 0, 6);
}

-(void)setMuteVolumeState:(ESPMuteVolumeState)muteVolumeState {
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        // Set the appropriate user bytes on new version
        [self setMuteToMuteVolume: (muteVolumeState == ESPMuteVolumeLever) ? true : false];
        return;
    }
    
	BOOL bit;
	if(muteVolumeState==ESPMuteVolumeLever) {
		bit = YES;
	}
	else if(muteVolumeState==ESPMuteVolumeZero) {
		bit = NO;
	}
	else
	{
		bit = NO; //< to silence compiler warning
		NSAssert(NO, @"Invalid ESPMuteVolumeState value");
	}
	ESPData_setBit(_data, 0, 7, bit);
}

-(ESPMuteVolumeState)muteVolumeState {
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        return [self muteToMuteVolume] ? ESPMuteVolumeLever : ESPMuteVolumeZero;
    }
    
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
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
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
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return 0;
    }
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
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
    
	ESPData_setBit(_data, 1, 1, ESPByte_getBit((Byte)KMuteTimer, 0));
	ESPData_setBit(_data, 1, 2, ESPByte_getBit((Byte)KMuteTimer, 1));
	ESPData_setBit(_data, 1, 3, ESPByte_getBit((Byte)KMuteTimer, 2));
}

-(ESPKMuteTimerValue)KMuteTimer
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return 0;
    }
	Byte kMuteByte = ESPData_getByte(_data, 1);
	kMuteByte = ((kMuteByte >> 1) & 0b00000111);
	return (ESPKMuteTimerValue)kMuteByte;
}

-(void)setKInitialUnmute4LightsOn:(BOOL)KInitialUnmute4LightsOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
	ESPData_setBit(_data, 1, 4, KInitialUnmute4LightsOn);
}

-(BOOL)KInitialUnmute4LightsOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return ESPData_getBit(_data, 1, 4);
}

-(void)setKPersistantUnmute6LightsOn:(BOOL)KPersistantUnmute6LightsOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
	ESPData_setBit(_data, 1, 5, KPersistantUnmute6LightsOn);
}

-(BOOL)KPersistantUnmute6LightsOn
{
	return ESPData_getBit(_data, 1, 5);
}

-(void)setKRearMuteOn:(BOOL)KRearMuteOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
	ESPData_setBit(_data, 1, 6, !KRearMuteOn);
}

-(BOOL)KRearMuteOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return !ESPData_getBit(_data, 1, 6);
}

-(void)setKuBandOn:(BOOL)KuBandOn
{
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        ESPData_setBit(_data, 0, 7, !KuBandOn);
        return;
    }
	ESPData_setBit(_data, 1, 7, !KuBandOn);
}

-(BOOL)KuBandOn
{
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        return !ESPData_getBit(_data, 0, 7);
    }
    
	return !ESPData_getBit(_data, 1, 7);
}

-(void)setPopOn:(BOOL)popOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
	ESPData_setBit(_data, 2, 0, popOn);
}

-(BOOL)popOn
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return ESPData_getBit(_data, 2, 0);
}

-(void)setEuroOn:(BOOL)euroOn {
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        ESPData_setBit(_data, 1, 0, !euroOn);
        return;
    }
	ESPData_setBit(_data, 2, 1, !euroOn);
}

-(BOOL)euroOn
{
   // This isn't supported by the V1 gen 2 so do nothing
   if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
       return !ESPData_getBit(_data, 1, 0);
   }
	return !ESPData_getBit(_data, 2, 1);
}

-(void)setEuroXBandOn:(BOOL)euroXBandOn {
    // On the V1 gen 2 this bit is mapped to the X band bit
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return [self setXBandOn:euroXBandOn];
    }
	ESPData_setBit(_data, 2, 2, !euroXBandOn);
}

-(BOOL)euroXBandOn {
    // On V1 gen 2 this bit is mapped to the X band bit.
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return self.XBandOn;
    }
	return !ESPData_getBit(_data, 2, 2);
}

-(void)setFilterOn:(BOOL)filterOn {
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        ESPData_setBit(_data, 1, 1, filterOn);
        return;
    }
	ESPData_setBit(_data, 2, 3, !filterOn);
}

-(BOOL)filterOn {
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION) {
        return ESPData_getBit(_data, 1, 1);
    }
	return !ESPData_getBit(_data, 2, 3);
}

-(void)setForceLegacyCD:(BOOL)forceLegacyCD
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return;
    }
	ESPData_setBit(_data, 2, 4, !forceLegacyCD);
}

-(BOOL)forceLegacyCD
{
    // This isn't supported by the V1 gen 2 so do nothing
    if(_v1Version >= INITIAL_V1_GEN_2_VERSION){
        return false;
    }
	return !ESPData_getBit(_data, 2, 4);
}

-(void)setMuteToMuteVolume:(BOOL)useMuteVolume {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        // Set the appropriate user bytes on older version
        [self setMuteVolumeState: useMuteVolume ? ESPMuteVolumeLever : ESPMuteVolumeZero];
        return;
    }
    ESPData_setBit(_data, 0, 4, useMuteVolume);
}

- (BOOL)muteToMuteVolume {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return (self.muteVolumeState == ESPMuteVolumeLever);
    }
    return ESPData_getBit(_data, 0, 4);
}

- (void)setBogeyLockToneLoadAfterMuting:(BOOL)MemoLoudPostMute {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 0, 5, MemoLoudPostMute);
}

- (BOOL)BogeyLockToneLoadAfterMuting {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
   return ESPData_getBit(_data, 0, 5);
}

- (void)setMuteXAndKRear:(BOOL)MuteXAndKRear {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 0, 6, !MuteXAndKRear);
}

- (BOOL)MuteXAndKRear {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return !ESPData_getBit(_data, 0, 6);
}

- (void)setLaserRear:(BOOL)LaserRear {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 1, 2, LaserRear);
}

- (BOOL)LaserRear {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return ESPData_getBit(_data, 1, 2);
}

-(void)setCustomFrequencies:(BOOL)customFrequencies {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 1, 3, !customFrequencies);
}

- (BOOL)CustomFrequencies {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return !ESPData_getBit(_data, 1, 3);
}

-(void)setKaAlwaysRadarPriority:(BOOL)kaAlwaysRadarPriority {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 1, 4, !kaAlwaysRadarPriority);
}

- (BOOL)KaAlwaysRadarPriority {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return !ESPData_getBit(_data, 1, 4);
}

-(void)setFastLaserDetect:(BOOL)fastLaserDetect {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 1, 5, fastLaserDetect);
}

- (BOOL)FastLaserDetect {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return ESPData_getBit(_data, 1, 5);
}

-(void)setKaSensitivity:(ESPKaSensitivity)kaSensitivity {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    Byte kaSensitivityByte = (Byte)kaSensitivity;
    if ( kaSensitivityByte == 0 ){
        // Do not allow an invalid value
        kaSensitivityByte = (Byte)ESPKaFullSensitivity;
    }
    ESPData_setBit(_data, 1, 6, ESPByte_getBit(kaSensitivityByte, 0));
    ESPData_setBit(_data, 1, 7, ESPByte_getBit(kaSensitivityByte, 1));
}

- (ESPKaSensitivity)kaSensitivity {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return ESPKaFullSensitivity;
    }
    Byte kaSensitivityByte = ESPData_getByte(_data, 1);
    kaSensitivityByte = (kaSensitivityByte >> 6);
    return (ESPKaSensitivity)kaSensitivityByte;
}

-(void)setStartupSequenceOn:(bool)startupSequenceOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 2, 0, startupSequenceOn);
}

- (bool)StartupSequenceOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return true;
    }
    return ESPData_getBit(_data, 2, 0);
}

-(void)setRestingDisplayOn:(bool)restingDisplayOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 2, 1, restingDisplayOn);
}

- (bool)RestingDisplayOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return true;
    }
    return ESPData_getBit(_data, 2, 1);
}

-(void)setBSMPlusOn:(bool)bsmPlusOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return;
    }
    ESPData_setBit(_data, 2, 2, !bsmPlusOn);
}

- (bool)BSMPlusOn {
    if(_v1Version < INITIAL_V1_GEN_2_VERSION) {
        return false;
    }
    return !ESPData_getBit(_data, 2, 2);
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
