//
//  ViewController.m
//  HelloV1
//
//  Created by lfinke_local on 3/21/17.
//  Copyright © 2017 Valentine Research Inc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()
-(UIColor*)colorForDisplayState:(ESPDisplayState)displayState;
-(UIColor*)bluetoothColorForDisplayState:(ESPDisplayState)displayState;
@end

@implementation ViewController

@synthesize scanner = _scanner;

@synthesize connectButton = _connectButton;
@synthesize disconnectButton = _disconnectButton;
@synthesize readVersionButton = _readVersionButton;
@synthesize readV1CVersionButton = _readV1CVersionButton;
@synthesize startAlertDataButton = _startAlertDataButton;
@synthesize stopAlertDataButton = _stopAlertDataButton;
@synthesize readSweepsButton = _readSweepsButton;

@synthesize laserLabel = _laserLabel;
@synthesize kaLabel = _kaLabel;
@synthesize kLabel = _kLabel;
@synthesize xLabel = _xLabel;

@synthesize frontLabel = _frontLabel;
@synthesize sideLabel = _sideLabel;
@synthesize rearLabel = _rearLabel;

@synthesize statusLabel = _statusLabel;
@synthesize versionLabel = _versionLabel;
@synthesize v1CVersionLabel = _v1CVersionLabel;
@synthesize alertTextBox = _alertTextBox;

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	_scanner = [[ESPScanner alloc] initWithDelegate:self];
	
	_disconnectButton.enabled = NO;
	
	_readVersionButton.enabled = NO;
	_readV1CVersionButton.enabled = NO;
	_startAlertDataButton.enabled = NO;
	_stopAlertDataButton.enabled = NO;
	_readSweepsButton.enabled = NO;
}

-(IBAction)connect
{
	_statusLabel.text = @"Scanning";
	_connectButton.enabled = NO;
	[_scanner startScanWithMode:ESPConnectModeRecent];
}

-(IBAction)disconnect
{
	[_scanner stopScan];
	[_scanner disconnectClient];
}

-(IBAction)readV1Version
{
	[_scanner.connectedClient requestVersionFrom:ESPRequestTargetValentineOne completion:^(NSString* version, NSError* error){
		if(error!=nil)
		{
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error Reading V1 Version" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else
		{
			_versionLabel.text = version;
            _versionLabel.textColor = UIColor.blackColor;
		}
	}];
}

-(IBAction)readV1CVersion
{
	[_scanner.connectedClient requestVersionFrom:ESPRequestTargetV1ConnectionLE completion:^(NSString* version, NSError* error){
		if(error!=nil)
		{
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error Reading V1C LE Version" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else
		{
			_v1CVersionLabel.text = version;
            _v1CVersionLabel.textColor = UIColor.blackColor;
		}
	}];
}

-(IBAction)startAlertData
{
	[_scanner.connectedClient requestStartAlertDataFor:ESPRequestTargetValentineOne completion:^(NSError* error){
		if(error!=nil)
		{
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error Starting Alert Data" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else
		{
			_startAlertDataButton.enabled = NO;
			_stopAlertDataButton.enabled = YES;
		}
	}];
}

-(IBAction)stopAlertData
{
	[_scanner.connectedClient requestStopAlertDataFor:ESPRequestTargetValentineOne completion:^(NSError* error){
		if(error!=nil)
		{
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error Stopping Alert Data" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else
		{
			_stopAlertDataButton.enabled = NO;
			_startAlertDataButton.enabled = YES;
		}
	}];
}

-(IBAction)readCustomSweeps
{
	[_scanner.connectedClient requestAllSweepDefinitionsFrom:ESPRequestTargetValentineOne completion:^(NSArray<ESPFrequencyRange*>* sweeps, NSError* error){
		if(error!=nil)
		{
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error Reading Sweeps" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else
		{
			NSMutableString* sweepsString = [NSMutableString string];
			for(ESPFrequencyRange* sweep in sweeps)
			{
				[sweepsString appendFormat:@"%@\n", sweep];
			}
			
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Custom Sweeps" message:sweepsString preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
	}];
}

-(UIColor*)colorForDisplayState:(ESPDisplayState)displayState
{
	switch(displayState)
	{
		case ESPDisplayStateOn:
			return [UIColor redColor];
			
		case ESPDisplayStateBlinking:
			return [UIColor orangeColor];
			
		case ESPDisplayStateOff:
			return [UIColor blackColor];
	}
	return [UIColor blackColor];
}

-(UIColor*)bluetoothColorForDisplayState:(ESPDisplayState)displayState
{
    switch(displayState)
    {
        case ESPDisplayStateOn:
            return [UIColor blueColor];
            
        case ESPDisplayStateBlinking:
            return [UIColor blueColor];
            
        case ESPDisplayStateOff:
            return [UIColor blackColor];
    }
    return [UIColor blackColor];
}


#pragma mark - ESPScannerDelegate

-(void)espScanner:(ESPScanner*)scanner didFailScanWithError:(NSError*)error
{
	_statusLabel.text = @"Disconnected";
	_connectButton.enabled = YES;
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Scan Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)espScannerDidTimeoutScan:(ESPScanner*)scanner
{
	_statusLabel.text = @"Disconnected";
	_connectButton.enabled = YES;
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Scan Timed Out" message:@"No V1 Connection dongles were found" preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)espScanner:(ESPScanner*)scanner didConnectClient:(__kindof ESPClient*)client
{
	_statusLabel.text = @"Connected";
    _statusLabel.textColor = [UIColor blackColor];
    _versionLabel.textColor = [UIColor blackColor];
    _v1CVersionLabel.textColor = [UIColor blackColor];
    
	_disconnectButton.enabled = YES;
	_connectButton.enabled = NO;
	
	_readVersionButton.enabled = YES;
	_readV1CVersionButton.enabled = YES;
	_startAlertDataButton.enabled = YES;
	_stopAlertDataButton.enabled = YES;
	_readSweepsButton.enabled = YES;
	
	client.delegate = self;
}

-(void)espScanner:(ESPScanner*)scanner didDisconnectClient:(__kindof ESPClient*)client error:(NSError*)error
{
	_statusLabel.text = @"Disconnected";
	_versionLabel.text = @"Unknown";
	_v1CVersionLabel.text = @"Unknown";
	_disconnectButton.enabled = NO;
	_connectButton.enabled = YES;
	
	_readVersionButton.enabled = NO;
	_readV1CVersionButton.enabled = NO;
	_startAlertDataButton.enabled = NO;
	_stopAlertDataButton.enabled = NO;
	_readSweepsButton.enabled = NO;
	    
    _versionLabel.textColor = [UIColor blackColor];
    _v1CVersionLabel.textColor =[UIColor blackColor];
	_laserLabel.textColor = [UIColor blackColor];
	_kaLabel.textColor = [UIColor blackColor];
	_kLabel.textColor = [UIColor blackColor];
	_xLabel.textColor = [UIColor blackColor];
	
	_frontLabel.textColor = [UIColor blackColor];
	_sideLabel.textColor = [UIColor blackColor];
	_rearLabel.textColor = [UIColor blackColor];
    
    _bluetooth.textColor = [UIColor blackColor];
    _mute.textColor = [UIColor blackColor];
	
	_alertTextBox.text = @"";
	
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"V1 Disconnected" message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - ESPClientDelegate

-(void)espClient:(ESPClient*)client didReceiveDisplayData:(ESPDisplayData*)displayData
{
	_laserLabel.textColor = [self colorForDisplayState:displayData.laser];
	_kaLabel.textColor = [self colorForDisplayState:displayData.Ka];
	_kLabel.textColor = [self colorForDisplayState:displayData.K];
	_xLabel.textColor = [self colorForDisplayState:displayData.X];
	
	_frontLabel.textColor = [self colorForDisplayState:displayData.front];
	_sideLabel.textColor = [self colorForDisplayState:displayData.side];
	_rearLabel.textColor = [self colorForDisplayState:displayData.rear];
    
    _bluetooth.textColor = [self bluetoothColorForDisplayState:displayData.bluetooth];
    _mute.textColor = [self colorForDisplayState:displayData.mute];
}

-(void)espClient:(ESPClient*)client didReceiveAlertTable:(NSArray<ESPAlertData*>*)alertTable
{
	if(alertTable.count==0)
	{
		_alertTextBox.text = @"No Alerts";
	}
	else
	{
		NSMutableString* alertsString = [NSMutableString string];
		NSUInteger alertCounter = 0;
		for(ESPAlertData* alert in alertTable)
		{
			NSString* bandString = nil;
			switch(alert.band)
			{
				case ESPAlertBandLaser:
					bandString = @"laser";
					break;
					
				case ESPAlertBandK:
					bandString = @"K";
					break;
					
				case ESPAlertBandX:
					bandString = @"X";
					break;
					
				case ESPAlertBandKa:
					bandString = @"Ka";
					break;
					
				case ESPAlertBandKu:
					bandString = @"Ku";
					break;
					
				case ESPAlertBandInvalid:
					bandString = @"Invalid";
					break;
			}
			
			NSString* directionString = nil;
			switch(alert.direction)
			{
				case ESPAlertDirectionFront:
					directionString = @"front";
					break;
					
				case ESPAlertDirectionSide:
					directionString = @"side";
					break;
					
				case ESPAlertDirectionRear:
					directionString = @"rear";
					break;
					
				case ESPAlertDirectionInvalid:
					directionString = @"invalid";
					break;
			}
			
			[alertsString appendFormat:@"%lu: %@ %@ - %lu MHz\n", (unsigned long)alertCounter, directionString, bandString, (unsigned long)alert.frequency];
			
			alertCounter++;
		}
		_alertTextBox.text = alertsString;
	}
}

@end
