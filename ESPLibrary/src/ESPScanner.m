/*
 * Copyright(c) 2016 Valentine Research, Inc
 * This file is part of the ESP Library, which is licensed under the MIT license.
 * You should have received a copy of the MIT license along with this file. If not, see http://opensource.org/licenses/MIT
 */

#import "ESPScanner.h"
#import "ESPScanner+ESPClient.h"

//#define LOGGING_ENABLED

#ifndef DEBUG
	#undef LOGGING_ENABLED
#endif

#ifdef LOGGING_ENABLED
	#define DebugLog(...) NSLog(__VA_ARGS__)
#else
	#define DebugLog(...)
#endif

NSString* const ESPScannerErrorDomain = @"ESPScannerErrorDomain";

@interface ESPScanner() <CBCentralManagerDelegate, CBPeripheralDelegate>
{
	CBCentralManager* _central;
	ESPConnectMode _mode;
	BOOL _waitingToStartScan;
	NSTimeInterval _scanTimeout;
	NSTimeInterval _scanStartTime;
	NSTimer* _delayTimer;
	NSTimer* _connectTimer;
	
	NSMutableArray<CBPeripheral*>* _discoveredPeripherals;
	NSMutableArray<NSNumber*>* _peripheralRSSIs;
	NSMutableArray<NSDate*>* _peripheralDates;
	CBPeripheral* _connectingPeripheral;
	
	BOOL _expectingDisconnect;
	NSString* _UUIDToFind;
}
-(void)_startScanWithMode:(ESPConnectMode)mode restrictingToUUID:(NSString*)UUIDString timeout:(NSTimeInterval)timeout;
-(void)_delayTimerDidFire:(NSTimer*)timer;
-(BOOL)_checkForConnectCandidate;
-(void)_connectDidTimeout:(NSTimer*)timer;

-(void)_setMostRecentDeviceUUID:(NSString*)deviceID;
@end

@implementation ESPScanner

@synthesize delegate = _delegate;
@synthesize scanning = _scanning;
@synthesize connectedClient = _connectedClient;
@synthesize userDefaults = _userDefaults;
@synthesize automaticallyRemembersDevices = _automaticallyRemembersDevices;
@synthesize maximumRecentDevices = _maximumRecentDevices;

-(id)initWithDelegate:(id<ESPScannerDelegate>)delegate
{
	if(self = [super init])
	{
		_delegate = delegate;
		_mode = ESPConnectModeManual;
		
		_scanning = NO;
		_connectedClient = nil;
		_userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.Valentine.ESPLibrary"];
		_automaticallyRemembersDevices = YES;
		_maximumRecentDevices = 10;
		
		_central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
		_scanTimeout = 0;
		_scanStartTime = 0;
		_delayTimer = nil;
		_connectTimer = nil;
		
		_discoveredPeripherals = [NSMutableArray<CBPeripheral*> array];
		_peripheralRSSIs = [NSMutableArray<NSNumber*> array];
		_peripheralDates = [NSMutableArray<NSDate*> array];
		_connectingPeripheral = nil;
		
		_expectingDisconnect = NO;
		_UUIDToFind = nil;
	}
	return self;
}

-(id)init
{
	if(self = [self initWithDelegate:nil])
	{
		//
	}
	return self;
}

-(void)dealloc
{
	if(_connectedClient!=nil)
	{
		[self disconnectClient];
	}
}

-(Class)clientClass
{
	return [ESPClient class];
}

-(NSNumber*)RSSIOfPeripheral:(CBPeripheral*)peripheral
{
	@synchronized (_discoveredPeripherals)
	{
		NSString* uuid = peripheral.identifier.UUIDString;
		for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
		{
			if([uuid isEqualToString:_discoveredPeripherals[i].identifier.UUIDString])
			{
				return _peripheralRSSIs[i];
			}
		}
		return nil;
	}
}

-(NSDate*)lastReportDateOfPeripheral:(CBPeripheral*)peripheral
{
	@synchronized(_discoveredPeripherals)
	{
		NSString* uuid = peripheral.identifier.UUIDString;
		for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
		{
			if([uuid isEqualToString:_discoveredPeripherals[i].identifier.UUIDString])
			{
				return _peripheralDates[i];
			}
		}
		return nil;
	}
}

-(CBPeripheral*)peripheralWithUUID:(NSString*)UUIDString
{
	@synchronized (_discoveredPeripherals)
	{
		for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
		{
			CBPeripheral* peripheral = _discoveredPeripherals[i];
			if([peripheral.identifier.UUIDString isEqualToString:UUIDString])
			{
				return peripheral;
			}
		}
		return nil;
	}
}

-(NSArray<CBPeripheral*>*)discoveredPeripherals
{
	@synchronized (_discoveredPeripherals)
	{
		return [NSArray<CBPeripheral*> arrayWithArray:_discoveredPeripherals];
	}
}

-(CBPeripheral*)mostRecentPeripheral
{
	@synchronized (_discoveredPeripherals)
	{
		if(_discoveredPeripherals.count==0)
		{
			return nil;
		}
		CBPeripheral* mostRecentPeripheral = nil;
		NSUInteger mostRecentPeripheralRank = NSUIntegerMax;
		NSArray<NSString*>* recentDeviceIDs = self.recentDeviceUUIDs;
		for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
		{
			CBPeripheral* peripheral = _discoveredPeripherals[i];
			NSString* deviceID = peripheral.identifier.UUIDString;
			for(NSUInteger j=0; j<recentDeviceIDs.count; j++)
			{
				NSString* cmpID = recentDeviceIDs[j];
				if([cmpID isEqualToString:deviceID])
				{
					if(j < mostRecentPeripheralRank)
					{
						mostRecentPeripheral = peripheral;
						mostRecentPeripheralRank = j;
					}
					break;
				}
			}
		}
		return mostRecentPeripheral;
	}
}

-(CBPeripheral*)strongestPeripheral
{
	@synchronized (_discoveredPeripherals)
	{
		if(_discoveredPeripherals.count==0)
		{
			return nil;
		}
		CBPeripheral* strongestPeripheral = _discoveredPeripherals[0];
		double strongestValue = [_peripheralRSSIs[0] doubleValue];
		if(strongestValue >= 127)
		{
			strongestValue = -99999;
		}
		for(NSUInteger i=1; i<_peripheralRSSIs.count; i++)
		{
			double rssi = [_peripheralRSSIs[i] doubleValue];
			if(rssi >= 127)
			{
				rssi = -99999;
			}
			if(rssi>strongestValue)
			{
				strongestValue = rssi;
				strongestPeripheral = _discoveredPeripherals[i];
			}
		}
		return strongestPeripheral;
	}
}

-(NSDate*)scanStartDate
{
	if(_scanning)
	{
		return [NSDate dateWithTimeIntervalSince1970:_scanStartTime];
	}
	return nil;
}

-(NSTimeInterval)timeout
{
	if(_scanning)
	{
		return _scanTimeout;
	}
	return 0;
}

-(BOOL)isConnecting
{
	if(_connectingPeripheral!=nil)
	{
		return YES;
	}
	return NO;
}

-(void)startScan
{
	[self startScanWithMode:ESPConnectModeManual];
}

-(void)startScanWithMode:(ESPConnectMode)mode
{
	NSTimeInterval scanTimeout = 0;
	if(mode == ESPConnectModeManual)
	{
		scanTimeout = -1;
	}
	else if(mode==ESPConnectModeStrongest || mode==ESPConnectModeRecent)
	{
		scanTimeout = 5.0;
	}
	[self startScanWithMode:mode timeout:scanTimeout];
}

-(void)startScanWithMode:(ESPConnectMode)mode timeout:(NSTimeInterval)timeout
{
	[self _startScanWithMode:mode restrictingToUUID:nil timeout:timeout];
}

-(void)startScanForDeviceWithUUID:(NSString*)UUIDString timeout:(NSTimeInterval)timeout
{
	[self _startScanWithMode:ESPConnectModeManual restrictingToUUID:UUIDString timeout:timeout];
}

-(void)_startScanWithMode:(ESPConnectMode)mode restrictingToUUID:(NSString*)UUIDString timeout:(NSTimeInterval)timeout
{
	DebugLog(@"preparing to start scan");
	if(!_scanning)
	{
		if(_central.state == CBManagerStateUnsupported)
		{
			//fail scan
			dispatch_async(dispatch_get_main_queue(), ^{
				DebugLog(@"failing scan. BTLE not supported");
                if(self->_delegate!=nil && [self->_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
				{
					NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLEUnsupported userInfo:@{NSLocalizedDescriptionKey:@"Bluetooth is not supported on this device"}];
                    [self->_delegate espScanner:self didFailScanWithError:error];
				}
			});
		}
		else if(_central.state == CBManagerStatePoweredOff)
		{
			//fail scan
			dispatch_async(dispatch_get_main_queue(), ^{
				DebugLog(@"failing scan. Bluetooth is off");
                if(self->_delegate!=nil && [self->_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
				{
					NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLEPoweredOff userInfo:@{NSLocalizedDescriptionKey:@"Bluetooth is powered off"}];
                    [self->_delegate espScanner:self didFailScanWithError:error];
				}
			});
		}
		else if(_central.state == CBManagerStateUnauthorized)
		{
			//fail scan
			dispatch_async(dispatch_get_main_queue(), ^{
				DebugLog(@"failing scan. Unauthorized");
                if(self->_delegate!=nil && [self->_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
				{
					NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLENotAuthorized userInfo:@{NSLocalizedDescriptionKey:@"This app is not authorized to use bluetooth"}];
                    [self->_delegate espScanner:self didFailScanWithError:error];
				}
			});
		}
		else
		{
			//removing old discovered peripherals
			@synchronized (_discoveredPeripherals)
			{
				DebugLog(@"clearing discovered peripherals");
				//if the scanner is currently connected, retain the connected peripheral
				CBPeripheral* retainedPeripheral = nil;
				NSNumber* retainedRSSI = nil;
				NSDate* retainedDate = nil;
				if(_connectedClient!=nil)
				{
					NSString* UUIDString = _connectedClient.peripheral.identifier.UUIDString;
					for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
					{
						CBPeripheral* cmpPeripheral = _discoveredPeripherals[i];
						if([cmpPeripheral.identifier.UUIDString isEqualToString:UUIDString])
						{
							retainedPeripheral = _discoveredPeripherals[i];
							retainedRSSI = _peripheralRSSIs[i];
							retainedDate = [NSDate date];
							break;
						}
					}
				}
				[_discoveredPeripherals removeAllObjects];
				[_peripheralRSSIs removeAllObjects];
				[_peripheralDates removeAllObjects];
				if(retainedPeripheral!=nil)
				{
					DebugLog(@"retaining peripheral with name %@", retainedPeripheral.name);
					[_discoveredPeripherals addObject:retainedPeripheral];
					[_peripheralRSSIs addObject:retainedRSSI];
					[_peripheralDates addObject:retainedDate];
				}
			}
			
			//start scan, and start delay timer if necessary
			DebugLog(@"starting scan");
			_scanning = YES;
			_mode = mode;
			_UUIDToFind = UUIDString;
			_scanTimeout = timeout;
			_scanStartTime = [[NSDate date] timeIntervalSince1970];
			switch(_mode)
			{
				default:
				case ESPConnectModeManual:
					if(_scanTimeout>0)
					{
						DebugLog(@"starting delay timer");
						_delayTimer = [NSTimer timerWithTimeInterval:_scanTimeout target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
						[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
					}
					break;
					
				case ESPConnectModeStrongest:
				case ESPConnectModeRecent:
					if(_scanTimeout>5.0 || _scanTimeout <= 0)
					{
						DebugLog(@"starting delay timer");
						_delayTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
						[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
					}
					else if(_scanTimeout > 0)
					{
						DebugLog(@"starting delay timer");
						_delayTimer = [NSTimer timerWithTimeInterval:_scanTimeout target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
						[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
					}
					break;
			}
			if(_central.state==CBManagerStatePoweredOn)
			{
				DebugLog(@"starting central manager scan");
				CBUUID* serviceUUID = [CBUUID UUIDWithString:ESPUUIDV1ConnectionLEService];
				[_central scanForPeripheralsWithServices:@[serviceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
			}
			else
			{
				DebugLog(@"waiting to start scan");
				_waitingToStartScan = YES;
			}
		}
	}
}

-(void)stopScan
{
	DebugLog(@"calling stopScan");
	if(_scanning)
	{
		DebugLog(@"actually stopping scan");
		_scanning = NO;
		_waitingToStartScan = NO;
		_scanTimeout = 0;
		_UUIDToFind = nil;
		_mode = ESPConnectModeManual;
		if(_delayTimer!=nil)
		{
			[_delayTimer invalidate];
			_delayTimer = nil;
		}
		[_central stopScan];
	}
}

-(void)connectPeripheral:(CBPeripheral*)peripheral
{
	DebugLog(@"preparing to connect to peripheral");
	//CONNECT step 1: something calls connectPeripheral:
	// it could be _delayTimerDidFire: calling it if the delay timer was started
	// or it could be from outside the library
	NSAssert(peripheral!=nil, @"peripheral cannot be nil");
	if(_connectingPeripheral!=nil)
	{
		if(_connectingPeripheral!=peripheral)
		{
			DebugLog(@"another peripheral is currently being connected already");
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
			{
				NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeScannerBusy userInfo:@{NSLocalizedDescriptionKey:@"Another peripheral is already being connected"}];
				[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
			}
		}
		else
		{
			DebugLog(@"attempting to connect the same peripheral twice. You shouldn't be doing this");
		}
	}
	else if(_connectedClient!=nil)
	{
		if(_connectedClient.peripheral!=peripheral)
		{
			DebugLog(@"another peripheral is currently connected already");
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
			{
				NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeScannerBusy userInfo:@{NSLocalizedDescriptionKey:@"Another client has already been connected"}];
				[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
			}
		}
		else
		{
			DebugLog(@"attempting to connect an already connected peripheral. You shouldn't be doing this");
		}
	}
	else
	{
		DebugLog(@"connecting peripheral with UUID: %@", peripheral.identifier.UUIDString);
		_connectingPeripheral = peripheral;
		_connectTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(_connectDidTimeout:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:_connectTimer forMode:NSRunLoopCommonModes];
		[_central connectPeripheral:peripheral options:@{}];
	}
}

-(void)_connectDidTimeout:(NSTimer*)timer
{
	DebugLog(@"Connecting took too long. Cancelling...");
	_connectTimer = nil;
	if(_connectingPeripheral!=nil)
	{
		DebugLog(@"Asking to cancel peripheral connection");
		[_central cancelPeripheralConnection:_connectingPeripheral];
	}
}

-(void)disconnectClient
{
	if(_connectingPeripheral!=nil)
	{
		[_central cancelPeripheralConnection:_connectingPeripheral];
	}
	else
	{
		if(_connectedClient==nil)
		{
			return;
		}
		_expectingDisconnect = YES;
		[_central cancelPeripheralConnection:_connectedClient.peripheral];
	}
}

-(void)_delayTimerDidFire:(NSTimer*)timer
{
	DebugLog(@"delay timer firing");
	_delayTimer = nil;
	if(_scanTimeout<=0)
	{
		DebugLog(@"unlimited scan timeout");
		if(_connectingPeripheral==nil)
		{
			DebugLog(@"preparing to check for connect candidate");
			[self _checkForConnectCandidate];
			_delayTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
			[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
		}
		else
		{
			DebugLog(@"waiting for peripheral to connect. delaying timer again");
			_delayTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
			[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
		}
	}
	else
	{
		if(_connectingPeripheral==nil)
		{
			NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
			if((now - _scanStartTime) >= _scanTimeout)
			{
				DebugLog(@"scan is timing out. giving one last connect attempt");
				//scan timed out. Give one last connect attempt
				if(![self _checkForConnectCandidate])
				{
					[self stopScan];
					if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScannerDidTimeoutScan:)])
					{
						[_delegate espScannerDidTimeoutScan:self];
					}
				}
			}
			else
			{
				[self _checkForConnectCandidate];
				NSTimeInterval remainingTime = (_scanStartTime + _scanTimeout) - now;
				if(remainingTime < 5.0)
				{
					_delayTimer = [NSTimer timerWithTimeInterval:remainingTime target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
					[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
				}
				else
				{
					_delayTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
					[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
				}
			}
		}
		else
		{
			_delayTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(_delayTimerDidFire:) userInfo:nil repeats:NO];
			[[NSRunLoop mainRunLoop] addTimer:_delayTimer forMode:NSRunLoopCommonModes];
		}
	}
}

-(BOOL)_checkForConnectCandidate
{
	DebugLog(@"checking for a connect candidate");
	switch(_mode)
	{
		case ESPConnectModeManual:
			DebugLog(@"manual mode. no connect candidate");
			return NO;
			
		case ESPConnectModeRecent:
			if(_discoveredPeripherals.count>0)
			{
				CBPeripheral* mostRecentPeripheral = self.mostRecentPeripheral;
				NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
				if(mostRecentPeripheral!=nil)
				{
					DebugLog(@"recent peripheral found");
					[self connectPeripheral:mostRecentPeripheral];
					return YES;
				}
				else if((now - _scanStartTime) >= _scanTimeout)
				{
					//the scan is timing out. fall through this case to case ESPConnectModeStrongest
					DebugLog(@"recent mode scan is timing out. Falling through to find strongest signal");
				}
				else
				{
					DebugLog(@"no recent peripherals found. no connect candidate");
					return NO;
				}
			}
			else
			{
				DebugLog(@"no recent peripherals found. no connect candidate");
				return NO;
			}
			
		case ESPConnectModeStrongest:
			if(_discoveredPeripherals.count>0)
			{
				CBPeripheral* peripheral = self.strongestPeripheral;
				DebugLog(@"strongest peripheral found");
				[self connectPeripheral:peripheral];
				return YES;
			}
			else
			{
				DebugLog(@"no strong peripherals found. no connect candidate");
				return NO;
			}
			break;
	}
	return NO;
}

-(void)clearRecentUUIDs
{
	self.recentDeviceUUIDs = @[];
}

-(void)removeRecentUUID:(NSString*)UUIDString
{
	NSMutableArray<NSString*>* deviceIDs = self.recentDeviceUUIDs.mutableCopy;
	for(NSUInteger i=0; i<deviceIDs.count; i++)
	{
		NSString* cmpID = deviceIDs[i];
		if([cmpID isEqualToString:UUIDString])
		{
			[deviceIDs removeObjectAtIndex:i];
			i = deviceIDs.count;
		}
	}
	self.recentDeviceUUIDs = deviceIDs;
}

-(void)_setMostRecentDeviceUUID:(NSString*)deviceID
{
	NSMutableArray<NSString*>* deviceIDs = self.recentDeviceUUIDs.mutableCopy;
	for(NSUInteger i=0; i<deviceIDs.count; i++)
	{
		NSString* cmpID = deviceIDs[i];
		if([cmpID isEqualToString:deviceID])
		{
			[deviceIDs removeObjectAtIndex:i];
			i = deviceIDs.count;
		}
	}
	[deviceIDs insertObject:deviceID atIndex:0];
	self.recentDeviceUUIDs = deviceIDs;
}

-(void)setRecentDeviceUUIDs:(NSArray<NSString*>*)mostRecentDeviceUUIDs
{
	NSMutableArray<NSString*>* recentUUIDs = mostRecentDeviceUUIDs.mutableCopy;
	while(recentUUIDs.count > _maximumRecentDevices)
	{
		[recentUUIDs removeLastObject];
	}
	[_userDefaults setObject:recentUUIDs forKey:@"RecentPeripheralUUIDs"];
	[_userDefaults synchronize];
}

-(NSArray<NSString*>*)recentDeviceUUIDs
{
	NSArray<NSString*>* deviceIDs = [_userDefaults objectForKey:@"RecentPeripheralUUIDs"];
	if(deviceIDs==nil)
	{
		deviceIDs = [NSArray<NSString*> array];
	}
	return deviceIDs;
}

-(void)setMaximumRecentDevices:(NSUInteger)maximumRecentDevices
{
	if(maximumRecentDevices!=_maximumRecentDevices)
	{
		_maximumRecentDevices = maximumRecentDevices;
		//this will remove the excess device UUIDs if there are any
		self.recentDeviceUUIDs = self.recentDeviceUUIDs;
	}
}

#pragma mark - CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager*)central
{
	DebugLog(@"updated central state");
	if(_scanning)
	{
		//if the central manager changes into a "dead" state while scanning, end the scan
		if(_central.state==CBManagerStateUnsupported)
		{
			DebugLog(@"failing scan. BTLE not supported");
			[self stopScan];
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
			{
				NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLEUnsupported userInfo:@{NSLocalizedDescriptionKey:@"Bluetooth is not supported on this device"}];
				[_delegate espScanner:self didFailScanWithError:error];
			}
		}
		else if(_central.state==CBManagerStatePoweredOff)
		{
			DebugLog(@"failing scan. Bluetooth is off");
			[self stopScan];
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
			{
				NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLEPoweredOff userInfo:@{NSLocalizedDescriptionKey:@"Bluetooth is powered off"}];
				[_delegate espScanner:self didFailScanWithError:error];
			}
		}
		else if(_central.state==CBManagerStateUnauthorized)
		{
			DebugLog(@"failing scan. Unauthorized");
			[self stopScan];
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailScanWithError:)])
			{
				NSError* error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeBLENotAuthorized userInfo:@{NSLocalizedDescriptionKey:@"This app is not authorized to use bluetooth"}];
				[_delegate espScanner:self didFailScanWithError:error];
			}
		}
		else if(_central.state==CBManagerStatePoweredOn)
		{
			DebugLog(@"central manager is powered on");
			if(_waitingToStartScan)
			{
				DebugLog(@"finished waiting for central. Starting scan");
				_waitingToStartScan = NO;
				CBUUID* serviceUUID = [CBUUID UUIDWithString:ESPUUIDV1ConnectionLEService];
				[_central scanForPeripheralsWithServices:@[serviceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
			}
		}
	}
}

-(void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary<NSString*,id>*)advertisementData RSSI:(NSNumber*)RSSI
{
	DebugLog(@"discovered peripheral with UUID: %@", peripheral.identifier.UUIDString);
	BOOL updatedPeripheral = NO;
	@synchronized (_discoveredPeripherals)
	{
		for(NSUInteger i=0; i<_discoveredPeripherals.count; i++)
		{
			CBPeripheral* cmpPeripheral = _discoveredPeripherals[i];
			if([cmpPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
			{
				_discoveredPeripherals[i] = peripheral;
				_peripheralRSSIs[i] = RSSI;
				_peripheralDates[i] = [NSDate date];
				updatedPeripheral = YES;
				break;
			}
		}
		if(!updatedPeripheral)
		{
			[_discoveredPeripherals addObject:peripheral];
			[_peripheralRSSIs addObject:RSSI];
			[_peripheralDates addObject:[NSDate date]];
		}
	}
	
	if(_UUIDToFind!=nil)
	{
		if([peripheral.identifier.UUIDString isEqualToString:_UUIDToFind])
		{
			if(_connectingPeripheral==nil)
			{
				[self connectPeripheral:peripheral];
			}
			
			if(updatedPeripheral)
			{
				if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didUpdatePeripheral:)])
				{
					[_delegate espScanner:self didUpdatePeripheral:peripheral];
				}
			}
			else
			{
				if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didDiscoverPeripheral:)])
				{
					[_delegate espScanner:self didDiscoverPeripheral:peripheral];
				}
			}
		}
	}
	else
	{
		if(_mode == ESPConnectModeRecent && _connectingPeripheral==nil)
		{
			NSString* recentUUID = self.recentDeviceUUIDs.firstObject;
			if(recentUUID!=nil && [peripheral.identifier.UUIDString isEqualToString:recentUUID])
			{
				[self connectPeripheral:peripheral];
			}
		}
		
		if(updatedPeripheral)
		{
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didUpdatePeripheral:)])
			{
				[_delegate espScanner:self didUpdatePeripheral:peripheral];
			}
		}
		else
		{
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didDiscoverPeripheral:)])
			{
				[_delegate espScanner:self didDiscoverPeripheral:peripheral];
			}
		}
	}
}

-(void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
	DebugLog(@"did connect peripheral with UUID %@\n. checking services...", peripheral.identifier.UUIDString);
	//CONNECT step 2: the peripheral successfuly connects. Start looking for services
	// if this doesn't get called, it's because centralManager:didFailToConnectPeripheral:error: was called
	
	[_connectTimer invalidate];
	_connectTimer = nil;
	
	//temporarily set the peripheral's delegate to self
	// so we can discover its services and characteristics
	peripheral.delegate = self;
	CBUUID* serviceUUID = [CBUUID UUIDWithString:ESPUUIDV1ConnectionLEService];
	[peripheral discoverServices:@[serviceUUID]];
}

-(void)centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
	DebugLog(@"failed to connect peripheral");
	_connectingPeripheral = nil;
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
	{
		[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
	}
	
	if(_scanTimeout > 0)
	{
		DebugLog(@"checking scan timeout");
		NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
		if((now - _scanStartTime) >= _scanTimeout)
		{
			DebugLog(@"scan has timed out");
			//scan timed out
			[self stopScan];
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScannerDidTimeoutScan:)])
			{
				[_delegate espScannerDidTimeoutScan:self];
			}
		}
	}
}

-(void)centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error
{
	DebugLog(@"peripheral disconnected");
	//if services were still being discovered
	if(_connectingPeripheral!=nil)
	{
		DebugLog(@"was trying to connect to peripheral, but failed");
		_connectingPeripheral = nil;
		peripheral.delegate = nil;
		if(!_expectingDisconnect)
		{
			if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
			{
				if(error==nil)
				{
					error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeTimedOut userInfo:@{NSLocalizedDescriptionKey:@"Connection timed out"}];
				}
				[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
			}
		}
		_expectingDisconnect = NO;
		
		if(_scanTimeout > 0)
		{
			DebugLog(@"checking scan timeout");
			NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
			if((now - _scanStartTime) >= _scanTimeout)
			{
				DebugLog(@"scan has timed out");
				//scan timed out
				[self stopScan];
				if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScannerDidTimeoutScan:)])
				{
					[_delegate espScannerDidTimeoutScan:self];
				}
			}
		}
		return;
	}
	else //if the ESPClient was already connected and has now been disconnected
	{
		NSAssert(_connectedClient.peripheral==peripheral, @"Unknown peripheral disconnected");
		
		if(error==nil && !_expectingDisconnect)
		{
			//Unexpected disconnect (this usually means bluetooth got turned off)
			error = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeUnexpectedDisconnect userInfo:@{NSLocalizedDescriptionKey:@"Device disconnected unexpectedly"}];
		}
		_expectingDisconnect = NO;
		
		ESPClient* client = _connectedClient;
		_connectedClient = nil;
		[client _handleDisconnect];
		if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didDisconnectClient:error:)])
		{
			[_delegate espScanner:self didDisconnectClient:client error:error];
		}
	}
}

#pragma mark - CBPeripheralDelegate

-(void)peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error
{
	if(error!=nil)
	{
		DebugLog(@"failed to find services");
		peripheral.delegate = nil;
		_expectingDisconnect = YES;
		[_central cancelPeripheralConnection:peripheral];
		if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
		{
			[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
		}
		return;
	}
	
	CBService* comService = nil;
	NSArray<CBService*>* services = peripheral.services;
	for(NSUInteger i=0; i<services.count; i++)
	{
		CBService* service = services[i];
		if([service.UUID.UUIDString isEqualToString:ESPUUIDV1ConnectionLEService])
		{
			comService = service;
			break;
		}
	}
	
	if(comService==nil)
	{
		DebugLog(@"unable to find V1CLE service");
		peripheral.delegate = nil;
		_expectingDisconnect = YES;
		[_central cancelPeripheralConnection:peripheral];
		if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
		{
			NSError* serviceError = [NSError errorWithDomain:ESPScannerErrorDomain code:ESPScannerErrorCodeServiceNotFound userInfo:@{NSLocalizedDescriptionKey:@"V1Connection LE service not found"}];
			[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:serviceError];
		}
		return;
	}
	
	//CONNECT step 3: the service was discovered. Now discover the characteristics
	CBUUID* V1OutClientInShort = [CBUUID UUIDWithString:ESPUUIDV1OutClientInShortCharacteristic];
	CBUUID* V1OutClientInLong = [CBUUID UUIDWithString:ESPUUIDV1OutClientInLongCharacteristic];
	CBUUID* ClientOutV1InShort = [CBUUID UUIDWithString:ESPUUIDClientOutV1InShortCharacteristic];
	CBUUID* ClientOutV1InLong = [CBUUID UUIDWithString:ESPUUIDClientOutV1InLongCharacteristic];
	
	NSArray<CBUUID*>* characteristics = @[V1OutClientInShort, V1OutClientInLong, ClientOutV1InShort, ClientOutV1InLong];
	
	DebugLog(@"found service. discovering characteristics");
	[peripheral discoverCharacteristics:characteristics forService:comService];
}

-(void)peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error
{
	if(error!=nil)
	{
		DebugLog(@"failed to discover characteristics");
		peripheral.delegate = nil;
		_expectingDisconnect = YES;
		[_central cancelPeripheralConnection:peripheral];
		if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didFailToConnectPeripheral:error:)])
		{
			[_delegate espScanner:self didFailToConnectPeripheral:peripheral error:error];
		}
		return;
	}
	
	CBCharacteristic* inShort = nil;
	CBCharacteristic* inLong = nil;
	CBCharacteristic* outShort = nil;
	CBCharacteristic* outLong = nil;
	
	NSArray<CBCharacteristic*>* characteristics = service.characteristics;
	for(NSUInteger i=0; i<characteristics.count; i++)
	{
		CBCharacteristic* characteristic = characteristics[i];
		if([characteristic.UUID.UUIDString isEqualToString:ESPUUIDV1OutClientInShortCharacteristic])
		{
			inShort = characteristic;
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
		else if([characteristic.UUID.UUIDString isEqualToString:ESPUUIDV1OutClientInLongCharacteristic])
		{
			inLong = characteristic;
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
		else if([characteristic.UUID.UUIDString isEqualToString:ESPUUIDClientOutV1InShortCharacteristic])
		{
			outShort = characteristic;
		}
		else if([characteristic.UUID.UUIDString isEqualToString:ESPUUIDClientOutV1InLongCharacteristic])
		{
			outLong = characteristic;
		}
	}
	
	DebugLog(@"found characteristics. finished connecting");
	//CONNECT step 4: peripheral found the service and its characteristics and successfully connected
	if(_mode!=ESPConnectModeManual || _UUIDToFind!=nil)
	{
		[self stopScan];
	}
	peripheral.delegate = nil;
	_connectingPeripheral = nil;
	_expectingDisconnect = NO;
	_connectedClient = [[self.clientClass alloc] initWithPeripheral:peripheral
													 inShort:inShort
													  inLong:inLong
													outShort:outShort
													 outLong:outLong];
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(espScanner:didConnectClient:)])
	{
		[_delegate espScanner:self didConnectClient:_connectedClient];
	}
	if(_automaticallyRemembersDevices)
	{
		[self _setMostRecentDeviceUUID:peripheral.identifier.UUIDString];
	}
}

@end
