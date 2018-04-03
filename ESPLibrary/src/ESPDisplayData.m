/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPDisplayData.h"
#import "ESPDataUtils.h"

BOOL ESPV1Mode_isValidMode(ESPV1Mode mode)
{
	if(mode==ESPV1ModeAllBogeysOrKKa || mode==ESPV1ModeLogicOrKa || mode==ESPV1ModeAdvancedLogic)
	{
		return YES;
	}
	return NO;
}

@interface ESPDisplayData()
-(ESPDisplayState)_displayStateFromImage1:(BOOL)img1 image2:(BOOL)img2;
-(NSString*)_descriptionForDisplayState:(ESPDisplayState)displayState;
-(NSString*)_descriptionForV1Mode:(ESPV1Mode)mode;
@end

@implementation ESPDisplayData

@synthesize data = _data;

-(id)init
{
	//must be initialized with data
	return nil;
}

-(id)initWithData:(NSData*)data
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:data];
	}
	return self;
}

-(id)initWithDisplayData:(ESPDisplayData*)displayData
{
	if(self = [super init])
	{
		_data = [[NSData alloc] initWithData:displayData->_data];
	}
	return self;
}

-(ESPDisplayState)_displayStateFromImage1:(BOOL)img1 image2:(BOOL)img2
{
	if(img1 && img2)
	{
		return ESPDisplayStateOn;
	}
	else if(img1 || img2)
	{
		return ESPDisplayStateBlinking;
	}
	return ESPDisplayStateOff;
}

-(NSString*)_descriptionForDisplayState:(ESPDisplayState)displayState
{
	switch(displayState)
	{
		case ESPDisplayStateOn:
			return @"on";
			
		case ESPDisplayStateOff:
			return @"off";
			
		case ESPDisplayStateBlinking:
			return @"blinking";
	}
	return @"unknown";
}

-(NSString*)_descriptionForV1Mode:(ESPV1Mode)mode
{
	switch(mode)
	{
		case ESPV1ModeAllBogeysOrKKa:
			return @"All Bogeys / K & Ka";
			
		case ESPV1ModeLogicOrKa:
			return @"Logic / Ka";
			
		case ESPV1ModeAdvancedLogic:
			return @"Advanced Logic";
	}
	return @"unknown";
}

-(ESPDisplayState)segmentA
{
	BOOL img1 = ESPData_getBit(_data, 0, 0);
	BOOL img2 = ESPData_getBit(_data, 1, 0);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentB
{
	BOOL img1 = ESPData_getBit(_data, 0, 1);
	BOOL img2 = ESPData_getBit(_data, 1, 1);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentC
{
	BOOL img1 = ESPData_getBit(_data, 0, 2);
	BOOL img2 = ESPData_getBit(_data, 1, 2);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentD
{
	BOOL img1 = ESPData_getBit(_data, 0, 3);
	BOOL img2 = ESPData_getBit(_data, 1, 3);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentE
{
	BOOL img1 = ESPData_getBit(_data, 0, 4);
	BOOL img2 = ESPData_getBit(_data, 1, 4);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentF
{
	BOOL img1 = ESPData_getBit(_data, 0, 5);
	BOOL img2 = ESPData_getBit(_data, 1, 5);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)segmentG
{
	BOOL img1 = ESPData_getBit(_data, 0, 6);
	BOOL img2 = ESPData_getBit(_data, 1, 6);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)decimalPoint
{
	BOOL img1 = ESPData_getBit(_data, 0, 7);
	BOOL img2 = ESPData_getBit(_data, 1, 7);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(BOOL)strengthLightAtIndex:(NSUInteger)index
{
	if(index < 8)
	{
		return ESPData_getBit(_data, 2, index);
	}
	@throw [NSException exceptionWithName:NSRangeException reason:@"strength light index is out of range" userInfo:nil];
}

-(NSUInteger)strengthLightCount
{
	return 8;
}

-(BOOL)strengthLight0
{
	return [self strengthLightAtIndex:0];
}

-(BOOL)strengthLight1
{
	return [self strengthLightAtIndex:1];
}

-(BOOL)strengthLight2
{
	return [self strengthLightAtIndex:2];
}

-(BOOL)strengthLight3
{
	return [self strengthLightAtIndex:3];
}

-(BOOL)strengthLight4
{
	return [self strengthLightAtIndex:4];
}

-(BOOL)strengthLight5
{
	return [self strengthLightAtIndex:5];
}

-(BOOL)strengthLight6
{
	return [self strengthLightAtIndex:6];
}

-(BOOL)strengthLight7
{
	return [self strengthLightAtIndex:7];
}

-(ESPDisplayState)laser
{
	BOOL img1 = ESPData_getBit(_data, 3, 0);
	BOOL img2 = ESPData_getBit(_data, 4, 0);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)Ka
{
	BOOL img1 = ESPData_getBit(_data, 3, 1);
	BOOL img2 = ESPData_getBit(_data, 4, 1);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)K
{
	BOOL img1 = ESPData_getBit(_data, 3, 2);
	BOOL img2 = ESPData_getBit(_data, 4, 2);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)X
{
	BOOL img1 = ESPData_getBit(_data, 3, 3);
	BOOL img2 = ESPData_getBit(_data, 4, 3);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)front
{
	BOOL img1 = ESPData_getBit(_data, 3, 5);
	BOOL img2 = ESPData_getBit(_data, 4, 5);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)side
{
	BOOL img1 = ESPData_getBit(_data, 3, 6);
	BOOL img2 = ESPData_getBit(_data, 4, 6);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(ESPDisplayState)rear
{
	BOOL img1 = ESPData_getBit(_data, 3, 7);
	BOOL img2 = ESPData_getBit(_data, 4, 7);
	return [self _displayStateFromImage1:img1 image2:img2];
}

-(BOOL)isLaserAlerting
{
    ESPDisplayState laserState = self.laser;
    
    if( (laserState==ESPDisplayStateOn || laserState==ESPDisplayStateBlinking) && self.systemStatus){
        // The laser is on and system status is off, verify an alert is present
        if ( self.strengthLight0 != ESPDisplayStateOff && (self.front !=  ESPDisplayStateOff || self.side != ESPDisplayStateOff || self.rear != ESPDisplayStateOff) ){
            // There is an arrow on, and the signal strength LED is on, so this must be a laser alert
            return YES;
        }
    }
    
    return NO;
}

-(BOOL)soft
{
	return ESPData_getBit(_data, 5, 0);
}

-(BOOL)tsHoldoff
{
	return ESPData_getBit(_data, 5, 1);
}

-(BOOL)systemStatus
{
	return ESPData_getBit(_data, 5, 2);
}

-(BOOL)displayOn
{
	return ESPData_getBit(_data, 5, 3);
}

-(BOOL)euroMode
{
	return ESPData_getBit(_data, 5, 4);
}

-(BOOL)customSweep
{
	return ESPData_getBit(_data, 5, 5);
}

-(BOOL)legacy
{
	return ESPData_getBit(_data, 5, 6);
}

-(ESPV1Mode)mode
{
	if(self.systemStatus)
	{
		if(self.segmentA == ESPDisplayStateOn && self.segmentB == ESPDisplayStateOn && self.segmentC == ESPDisplayStateOn && self.segmentG == ESPDisplayStateOn && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOn && self.segmentD == ESPDisplayStateOff){
			//All Bogeys mode (1)
			return ESPV1ModeAllBogeysOrKKa;
		}
		else if(self.segmentA == ESPDisplayStateOff && self.segmentB == ESPDisplayStateOff && self.segmentC == ESPDisplayStateOff && self.segmentG == ESPDisplayStateOff && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOff && self.segmentD == ESPDisplayStateOn){
			//Logic Mode (2)
			return ESPV1ModeLogicOrKa;
		}
		else if(self.segmentA == ESPDisplayStateOff && self.segmentB == ESPDisplayStateOff && self.segmentC == ESPDisplayStateOff && self.segmentG == ESPDisplayStateOff && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOn && self.segmentD == ESPDisplayStateOn){
			//Advanced Logic Mode (3)
			return ESPV1ModeAdvancedLogic;
		}
		else if(self.segmentA == ESPDisplayStateOn && self.segmentB == ESPDisplayStateOff && self.segmentC == ESPDisplayStateOff && self.segmentG == ESPDisplayStateOff && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOn && self.segmentD == ESPDisplayStateOn){
			//K & Ka Custom Sweeps (1)
			return ESPV1ModeAllBogeysOrKKa;
		}
		else if(self.segmentA == ESPDisplayStateOff && self.segmentB == ESPDisplayStateOff && self.segmentC == ESPDisplayStateOff && self.segmentG == ESPDisplayStateOn && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOff && self.segmentD == ESPDisplayStateOn){
			//Ka Custom Sweeps (2)
			return ESPV1ModeLogicOrKa;
		}
		else if(self.segmentA == ESPDisplayStateOff && self.segmentB == ESPDisplayStateOn && self.segmentC == ESPDisplayStateOn && self.segmentG == ESPDisplayStateOff && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOn && self.segmentD == ESPDisplayStateOn){
			//K & Ka Photo (1)
			return ESPV1ModeAllBogeysOrKKa;
		}
		else if(self.segmentA == ESPDisplayStateOff && self.segmentB == ESPDisplayStateOff && self.segmentC == ESPDisplayStateOn && self.segmentG == ESPDisplayStateOff && self.segmentE == ESPDisplayStateOn && self.segmentF == ESPDisplayStateOff && self.segmentD == ESPDisplayStateOn){
			//Ka Photo (2)
			return ESPV1ModeLogicOrKa;
		}
	}
	return ESPV1ModeUnknown;
}

-(BOOL)junk
{
	if(self.systemStatus)
	{
		if(self.segmentA==ESPDisplayStateOff && self.segmentB==ESPDisplayStateBlinking && self.segmentC==ESPDisplayStateBlinking && self.segmentD==ESPDisplayStateBlinking && self.segmentE==ESPDisplayStateBlinking && self.segmentF==ESPDisplayStateOff && self.segmentG==ESPDisplayStateOff)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)error
{
	if(self.segmentA==ESPDisplayStateOn && self.segmentB==ESPDisplayStateOff && self.segmentC==ESPDisplayStateOff && self.segmentD==ESPDisplayStateOn && self.segmentE==ESPDisplayStateOn && self.segmentF==ESPDisplayStateOn && self.segmentG==ESPDisplayStateOn && self.front==ESPDisplayStateOff && self.side==ESPDisplayStateOff && self.rear==ESPDisplayStateOff && !self.strengthLight0 && !self.strengthLight1 && !self.strengthLight2 && !self.strengthLight3 && !self.strengthLight4 && !self.strengthLight5 && !self.strengthLight6 && !self.strengthLight7)
	{
		return YES;
	}
	return NO;
}

-(NSString*)debugDescription
{
	NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"segmentA: %@\n", [self _descriptionForDisplayState:self.segmentA]];
	[desc appendFormat:@"segmentB: %@\n", [self _descriptionForDisplayState:self.segmentB]];
	[desc appendFormat:@"segmentC: %@\n", [self _descriptionForDisplayState:self.segmentC]];
	[desc appendFormat:@"segmentD: %@\n", [self _descriptionForDisplayState:self.segmentD]];
	[desc appendFormat:@"segmentE: %@\n", [self _descriptionForDisplayState:self.segmentE]];
	[desc appendFormat:@"segmentF: %@\n", [self _descriptionForDisplayState:self.segmentF]];
	[desc appendFormat:@"segmentG: %@\n", [self _descriptionForDisplayState:self.segmentG]];
	[desc appendFormat:@"decimalPoint: %@\n", [self _descriptionForDisplayState:self.decimalPoint]];
	[desc appendString:@"\n"];
	for(NSUInteger i=0; i<self.strengthLightCount; i++)
	{
		[desc appendFormat:@"strengthLight%i: %@\n", (int)i, ([self strengthLightAtIndex:i] ? @"on" : @"off")];
	}
	[desc appendString:@"\n"];
	[desc appendFormat:@"laser: %@\n", [self _descriptionForDisplayState:self.laser]];
	[desc appendFormat:@"Ka: %@\n", [self _descriptionForDisplayState:self.Ka]];
	[desc appendFormat:@"K: %@\n", [self _descriptionForDisplayState:self.K]];
	[desc appendFormat:@"X: %@\n", [self _descriptionForDisplayState:self.X]];
	[desc appendString:@"\n"];
	[desc appendFormat:@"front: %@\n", [self _descriptionForDisplayState:self.front]];
	[desc appendFormat:@"side: %@\n", [self _descriptionForDisplayState:self.side]];
	[desc appendFormat:@"rear: %@\n", [self _descriptionForDisplayState:self.rear]];
	[desc appendString:@"\n"];
	[desc appendFormat:@"soft: %@\n", (self.soft ? @"on" : @"off")];
	[desc appendFormat:@"tsHoldoff: %@\n", (self.tsHoldoff ? @"on" : @"off")];
	[desc appendFormat:@"systemStatus: %@\n", (self.systemStatus ? @"on" : @"off")];
	[desc appendFormat:@"displayOn: %@\n", (self.displayOn ? @"on" : @"off")];
	[desc appendFormat:@"euroMode: %@\n", (self.euroMode ? @"on" : @"off")];
	[desc appendFormat:@"customSweep: %@\n", (self.customSweep ? @"on" : @"off")];
	[desc appendFormat:@"legacy: %@\n", (self.legacy ? @"on" : @"off")];
	[desc appendString:@"\n"];
	ESPV1Mode mode = self.mode;
	if(mode==ESPV1ModeUnknown)
	{
		[desc appendFormat:@"mode: %@\n", [self _descriptionForV1Mode:self.mode]];
	}
	else
	{
		[desc appendFormat:@"mode: %@   (%i)\n", [self _descriptionForV1Mode:self.mode], (int)self.mode];
	}
	[desc appendFormat:@"junk: %@\n", (self.junk ? @"yes" : @"no")];
	[desc appendFormat:@"error: %@\n", (self.error ? @"yes" : @"no")];
	return desc;
}

@end
