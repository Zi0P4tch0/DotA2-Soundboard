//
//  D2SBAppDelegate.h
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "D2SBMasterViewController.h"

@interface D2SBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet D2SBMasterViewController *masterViewController;

@end
