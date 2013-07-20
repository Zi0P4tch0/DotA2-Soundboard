//
//  D2SBMasterViewController.h
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFNetworking.h"

@interface D2SBMasterViewController : UITableViewController <NSXMLParserDelegate>

@property (nonatomic,strong) IBOutlet UIBarButtonItem *addSoundboardButton;
@property (nonatomic,strong) AFHTTPRequestOperation *downloadOperation;
@property (nonatomic,strong) NSString *soundboardBeingDownloaded;

-(void)reloadSoundboards;
-(IBAction)addSoundboard:(id)sender;

@end
