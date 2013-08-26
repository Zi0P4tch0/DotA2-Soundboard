///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//  This file is part of DotA2Soundboard.                                    //
//                                                                           //
//  DotA2Soundboard is free software: you can redistribute it and/or modify  //
//  it under the terms of the GNU General Public License as published by     //
//  the Free Software Foundation, either version 3 of the License, or        //
//  any later version.                                                       //
//                                                                           //
//  DotA2Soundboard is distributed in the hope that it will be useful,       //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of           //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            //
//  GNU General Public License for more details.                             //
//                                                                           //
//  You should have received a copy of the GNU General Public License        //
//  along with DotA2Soundboard.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

#import "D2SBAppDelegate.h"

#import "BlockAlertView.h"

@implementation D2SBAppDelegate

@synthesize masterViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    #ifdef USE_TESTFLIGHT
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    #pragma clang diagnostic pop
    [TestFlight takeOff:@"199939d9-306c-42a5-b564-567df94977bf"];
    #endif
    
    //Delete temporary files
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&error];
    if (error)
    {
        NSLog(@"Error while obtaining NSTemporaryDirectory contents: \"%@\".",[error localizedDescription]);
    }
    for (NSString *file in tmpFiles)
    {
        error = nil;
        NSLog(@"Deleting temporary file: \"%@\"...",file);
        [fileManager removeItemAtPath:file error:&error];
        if (error)
        {
            NSLog(@"Error while removing temporary file: \"%@\".",[error localizedDescription]);
        }
    }
        
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *urlString = [url absoluteString];
    
    if ([urlString hasPrefix:@"d2sb://"])
    {
        NSLog(@"Opening URL: \"%@\".",urlString);
        
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
        
        masterViewController.urlRequestParameters = [[NSMutableArray alloc] initWithCapacity:2];
        [masterViewController.urlRequestParameters addObject:hero];
        [masterViewController.urlRequestParameters addObject:[NSNumber numberWithUnsignedInteger:clipNumber]];
        
        if (![masterViewController isSoundboardAvailable:hero])
        {
            NSString *msg = [NSString stringWithFormat:
                             NSLocalizedString(@"You must download \"%@\" soundboard in order to listen to this clip!", nil),hero];
            
            BlockAlertView *alert = [[BlockAlertView alloc]
                                     initWithTitle:NSLocalizedString(@"Info", nil)
                                     message:msg];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Download", nil) imageIdentifier:@"red" block:^(){
                
                [masterViewController downloadSoundboard:hero];
                
                
            }];
            [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
            
            [alert show];
            
            return NO;
        }
        
        [masterViewController performSegueWithIdentifier:@"detail" sender:self];
        
        return YES;
    }
    
    return NO;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
    if ([[masterViewController downloadOperation] isExecuting])
    {
        [[masterViewController downloadOperation] pause];
    }
     */
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
    /*
    if ([[masterViewController downloadOperation] isPaused])
    {
        [[masterViewController downloadOperation] resume];
    }
     */
}

@end
