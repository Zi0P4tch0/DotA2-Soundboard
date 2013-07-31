//
//  D2SBMasterViewController.h
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFAmazonS3Client.h"
#import "MYIntroductionView.h"

#define DOCUMENTS [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define SOUNDBOARDS_DIR [DOCUMENTS stringByAppendingPathComponent:@"Soundboards"]
#define RINGTONES_DIR DOCUMENTS

#define HEROES_NO 102

@interface D2SBMasterViewController : UITableViewController <NSXMLParserDelegate,MYIntroductionDelegate>

@property (nonatomic,strong) IBOutlet UIBarButtonItem *addSoundboardButton;
@property (nonatomic,strong) AFAmazonS3Client *downloadOperation;
@property (nonatomic,assign) BOOL isDownloading;

@property (nonatomic,strong) NSMutableArray *urlRequestParameters;

-(void)reloadSoundboards;
-(IBAction)addSoundboard:(id)sender;
-(void)downloadSoundboard:(NSString*)heroName;

-(BOOL)heroExists:(NSString*)heroName;
-(BOOL)isSoundboardAvailable:(NSString*)heroName;

@end
