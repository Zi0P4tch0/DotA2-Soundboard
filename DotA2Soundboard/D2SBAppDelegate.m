//
//  D2SBAppDelegate.m
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import "D2SBAppDelegate.h"

@implementation D2SBAppDelegate

@synthesize masterViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //Delete temporary directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpFiles)
    {
        [fileManager removeItemAtPath:file error:NULL];
    }
    
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    if ([[masterViewController downloadOperation] isExecuting])
    {
        [[masterViewController downloadOperation] pause];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[masterViewController downloadOperation] isPaused])
    {
        [[masterViewController downloadOperation] resume];
    }
}

@end
