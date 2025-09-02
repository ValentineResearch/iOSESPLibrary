/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPTechDisplayUserBytes.h"
#import "ESPDataUtils.h"
#import "TechDisplayVersionUtil.h"



@interface ESPTechDisplayUserBytes() {
}
@end

@implementation ESPTechDisplayUserBytes

@synthesize t1Version = _t1Version;

-(id)init
{
	if(self = [super init])
    {
        _t1Version = DEFAULT_TECHDISPLAY_VERSION;
    }
	return self;
}

-(id)initWithT1Version:(NSUInteger)version {
    if(self = [self init])
    {
        _t1Version = version;
    }
    return self;
}

-(id)initWithData:(NSData*)data t1Version:(NSUInteger)version
{
	if(self = [super initWithData:data])
	{
        _t1Version = version;
	}
	return self;
}

-(id)initWithUserBytes:(ESPTechDisplayUserBytes*)userBytes
{
	if(self = [super init])
	{
		self.data = [[NSMutableData alloc] initWithData:userBytes.data];
        _t1Version = userBytes->_t1Version;
	}
	return self;
}

-(BOOL)isEqualToUserBytes:(ESPTechDisplayUserBytes*)userBytes
{
    return [super isEqualToUserBytes:userBytes];
}

-(void)resetToDefaults
{
    [super resetToDefaults];
}

- (void)setT1Version:(NSUInteger)t1Version {
    _t1Version = t1Version;
    // Whenever the version changes we need to reset the internal bytes back to defaults.
    [self resetToDefaults];
}

-(void)setV1DisplayOn:(BOOL)displayOn
{
	ESPData_setBit(self.data, 0, 0, !displayOn);
}

-(BOOL)V1DisplayOn
{
	return !ESPData_getBit(self.data, 0, 0);
}

-(void)setTechDisplayOn:(BOOL)displayOn
{
    ESPData_setBit(self.data, 0, 1, displayOn);
}

-(BOOL)TechDisplayOn
{
    return ESPData_getBit(self.data, 0, 1);
}

-(void)setExtendedRecallModeTimeoutOn:(BOOL)on
{
    ESPData_setBit(self.data, 0, 2, !on);
}

-(BOOL)ExtendedRecallModeTimeoutOn
{
    return !ESPData_getBit(self.data, 0, 2);
}

-(void)setRestingDisplayEnabled:(BOOL)on
{
    ESPData_setBit(self.data, 0, 3, on);
}

-(BOOL)restingDisplayEnabled
{
    return ESPData_getBit(self.data, 0, 3);
}

-(void)setExtendedAlertFrequencyOn:(BOOL)on
{
    ESPData_setBit(self.data, 0, 4, !on);
}

-(BOOL)extendedAlertFrequencyOn
{
    return !ESPData_getBit(self.data, 0, 4);
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"V1DisplayOn: %@\n", (self.V1DisplayOn ? @"yes" : @"no")];
	[desc appendFormat:@"TechDisplayOn: %@\n", (self.TechDisplayOn ? @"yes" : @"no")];
	return desc;
}

@end
