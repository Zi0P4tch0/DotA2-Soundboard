//
//  D2SBMasterViewController.h
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFNetworking.h"
#import "MYIntroductionView.h"

@interface D2SBMasterViewController : UITableViewController <NSXMLParserDelegate,MYIntroductionDelegate>

@property (nonatomic,strong) IBOutlet UIBarButtonItem *addSoundboardButton;
@property (nonatomic,strong) AFHTTPRequestOperation *downloadOperation;
@property (nonatomic,strong) NSMutableArray *urlRequestParameters;

-(void)reloadSoundboards;
-(IBAction)addSoundboard:(id)sender;

-(BOOL)heroExists:(NSString*)heroName;
-(BOOL)isSoundboardAvailable:(NSString*)heroName;

@end
