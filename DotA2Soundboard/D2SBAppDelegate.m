//
//  D2SBAppDelegate.m
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import "D2SBAppDelegate.h"

#import "BlockAlertView.h"
#import "iRate.h"

@implementation D2SBAppDelegate

@synthesize masterViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    
    //Delete temporary directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpFiles)
    {
        [fileManager removeItemAtPath:file error:NULL];
    }
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *urlString = [url absoluteString];
    
    if ([urlString hasPrefix:@"d2sb://"])
    {
        NSArray *urlTokens = [urlString componentsSeparatedByString:@"/"];
        
        if ([urlTokens count] != 4) return NO;
        
        NSString *hero = [[urlTokens objectAtIndex:2] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        hero =[hero stringByReplacingOccurrencesOfString:@"%27" withString:@"\'"];
        NSUInteger clipNumber = (NSUInteger)[[urlTokens objectAtIndex:3] integerValue];
        
        if (![masterViewController heroExists:hero])
        {
            BlockAlertView *alert = [[BlockAlertView alloc]
                                     initWithTitle:NSLocalizedString(@"Error!", nil)
                                     message:[NSString stringWithFormat:NSLocalizedString(@"Hero \"%@\" doesn't exist!", nil),hero]];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
            
            [alert show];
            
            return NO;
        }
        
        if (![masterViewController isSoundboardAvailable:hero])
        {
            NSString *msg = [NSString stringWithFormat:
                             NSLocalizedString(@"You must download \"%@\" soundboard in order to listen to this clip!", nil),hero];
            
            BlockAlertView *alert = [[BlockAlertView alloc]
                                     initWithTitle:NSLocalizedString(@"Info", nil)
                                     message:msg];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
            [alert addButtonWithTitle:NSLocalizedString(@"Download", nil) imageIdentifier:@"red" block:^(){}];
            
            [alert show];
            
            return NO;
        }
        
        masterViewController.urlRequestParameters = [[NSMutableArray alloc] initWithCapacity:2];
        [masterViewController.urlRequestParameters addObject:hero];
        [masterViewController.urlRequestParameters addObject:[NSNumber numberWithUnsignedInteger:clipNumber]];
        
        [masterViewController performSegueWithIdentifier:@"detail" sender:self];
        
        return YES;
    }
    
    return NO;
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
