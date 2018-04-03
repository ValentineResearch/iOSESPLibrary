//
//  ViewController.h
//  HelloV1
//
//  Created by lfinke_local on 3/21/17.
//  Copyright © 2017 Valentine Research Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESPLibrary.h"

@interface ViewController : UIViewController <ESPScannerDelegate, ESPClientDelegate>

@property (nonatomic, readonly) ESPScanner* scanner;


@property (weak, nonatomic) IBOutlet UIButton* connectButton;
@property (weak, nonatomic) IBOutlet UIButton* disconnectButton;
@property (weak, nonatomic) IBOutlet UIButton* readVersionButton;
@property (weak, nonatomic) IBOutlet UIButton* readV1CVersionButton;
@property (weak, nonatomic) IBOutlet UIButton* startAlertDataButton;
@property (weak, nonatomic) IBOutlet UIButton* stopAlertDataButton;
@property (weak, nonatomic) IBOutlet UIButton* readSweepsButton;

@property (weak, nonatomic) IBOutlet UILabel* laserLabel;
@property (weak, nonatomic) IBOutlet UILabel* kaLabel;
@property (weak, nonatomic) IBOutlet UILabel* kLabel;
@property (weak, nonatomic) IBOutlet UILabel* xLabel;

@property (weak, nonatomic) IBOutlet UILabel* frontLabel;
@property (weak, nonatomic) IBOutlet UILabel* sideLabel;
@property (weak, nonatomic) IBOutlet UILabel* rearLabel;

@property (weak, nonatomic) IBOutlet UILabel* statusLabel;
@property (weak, nonatomic) IBOutlet UILabel* versionLabel;
@property (weak, nonatomic) IBOutlet UILabel* v1CVersionLabel;
@property (weak, nonatomic) IBOutlet UITextView* alertTextBox;


- (IBAction)connect;
- (IBAction)disconnect;
- (IBAction)readV1Version;
- (IBAction)readV1CVersion;
- (IBAction)startAlertData;
- (IBAction)stopAlertData;
- (IBAction)readCustomSweeps;

@end
