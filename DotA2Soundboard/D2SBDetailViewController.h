//
//  D2SBDetailViewController.h
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import "Soundboard.h"

@interface D2SBDetailViewController : UITableViewController <UISearchBarDelegate,UISearchDisplayDelegate,AVAudioPlayerDelegate,UIGestureRecognizerDelegate,UIActionSheetDelegate>

@property (strong,nonatomic) Soundboard* soundboard;
@property (assign,nonatomic) int requestedClip;
@property (strong,nonatomic) AVAudioPlayer* player;
@property (strong,nonatomic) UIDocumentInteractionController *dic;

@end
