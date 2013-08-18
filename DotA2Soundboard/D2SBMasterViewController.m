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

#import "D2SBMasterViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "ActionSheetStringPicker.h"
#import "BlockAlertView.h"
#import "D2SBAppDelegate.h"
#import "D2SBDetailViewController.h"
#import "MBProgressHUD.h"
#import "Soundboard.h"

#define S3_BASE_URL @"https://s3-eu-west-1.amazonaws.com/d2sb/"

typedef enum {
    
    HEROES_XML
    
} XMLParserMode;

@interface D2SBMasterViewController () {
    
    @private
    NSMutableArray *_heroes;
    NSMutableArray *_soundboards;
    XMLParserMode _xmlParserMode;
}
@end

@implementation D2SBMasterViewController

@synthesize addSoundboardButton;
@synthesize downloadOperation;
@synthesize urlRequestParameters;
@synthesize isDownloading;

#pragma mark - View methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    D2SBAppDelegate *appDelegate = (D2SBAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    appDelegate.masterViewController = (D2SBMasterViewController*)self;
    
    _heroes = [[NSMutableArray alloc] initWithCapacity:HEROES_NO];
    _soundboards = [[NSMutableArray alloc] init];
    urlRequestParameters = nil;
    
        
    if (IS_IPHONE5)
    {
        //iPhone5
        NSString *image = [[NSBundle mainBundle] pathForResource:@"background-568h@2x" ofType:@"png"];
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
    }
    else
    {
        //Other iPhones
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
  
    //Heroes.xml parse
    NSString *heroesXmlPath = [[NSBundle mainBundle] pathForResource:@"heroes" ofType:@"xml"];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:heroesXmlPath]];
    xmlParser.delegate = self;
    _xmlParserMode = HEROES_XML;
    [xmlParser parse];
    
    [self reloadSoundboards];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL tutorialShown = [defaults boolForKey:@"tutorialShown"];
        
    if (!tutorialShown)
    {
        NSLog(@"Showing tutorial / Disabling \"addSoundboard\" button");
        
        [addSoundboardButton setEnabled:NO];
        
        MYIntroductionPanel *panelOne = [[MYIntroductionPanel alloc]
                                         initWithimage:nil
                                         title:NSLocalizedString(@"Welcome!",nil)
                                         description:NSLocalizedString(@"This simple tutorial will teach you how to use this amazing soundboard!",nil)];
    
        MYIntroductionPanel *panelTwo = [[MYIntroductionPanel alloc]
                                         initWithimage:nil
                                         title:NSLocalizedString(@"Heroes",nil)
                                         description:NSLocalizedString(@"There's a soundboard for each hero. As you will see, there's only one soundboard in the app right now (\"Announcer\", the default one).\n\nIn order to download an additional soundboard, you must tap the PLUS button, located in the upper right corner.",nil)];
        
        MYIntroductionPanel *panelThree = [[MYIntroductionPanel alloc]
                                         initWithimage:nil
                                         title:NSLocalizedString(@"That's it!",nil)
                                         description:NSLocalizedString(@"Click on a soundboard to open it.\nA list of the available clips will appear.\n\nSearch a clip by scrolling down the list or using the top search bar.\n\nTo play a clip, just click on it!\n\nTo view clip sharing options, just hold your finger on a clip for 1-2 seconds.",nil)];
    
        MYIntroductionView *introductionView = [[MYIntroductionView alloc]
                                                initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                headerImage:nil
                                                panels:@[panelOne,panelTwo,panelThree]];
        
        introductionView.delegate = self;
                
        [introductionView showInView:self.view];
        
        [defaults setBool:YES forKey:@"tutorialShown"];
        [defaults synchronize];
        
    }
    else
    {
        NSLog(@"No need to show tutorial");
    }
    
}

#pragma mark - Introduction view methods

-(void)introductionDidFinishWithType:(MYFinishType)finishType
{
    NSLog(@"End of tutorial / Enabling addSoundboard button");
    
    [addSoundboardButton setEnabled:YES];
}

#pragma mark - Soundboard related methods

-(BOOL)heroExists:(NSString*)heroName
{
    if ([heroName isEqualToString:@"Announcer"])
    {
        return YES;
    }
    return [_heroes containsObject:heroName];
}

-(BOOL)isSoundboardAvailable:(NSString*)heroName
{
    for (Soundboard *s in _soundboards)
    {
        if ([[s name] isEqualToString:heroName])
        {
            return YES;
        }
    }
    return NO;
}

-(void)reloadSoundboards
{
    NSLog(@"Reloading soundboards...");
    
    _soundboards = [[NSMutableArray alloc] init];
    
    //Folder check
    if (![[NSFileManager defaultManager] fileExistsAtPath:SOUNDBOARDS_DIR])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:SOUNDBOARDS_DIR withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:RINGTONES_DIR])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:RINGTONES_DIR withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //Announcer soundboard check
    NSString *announcerSoundboardPath = [SOUNDBOARDS_DIR stringByAppendingPathComponent:@"Announcer.sb"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:announcerSoundboardPath])
    {
        NSLog(@"First start. Copying \"Announcer.sb\" to SOUNDBOARDS_DIR.");
        NSString *announcerSoundboardBundlePath = [[NSBundle mainBundle] pathForResource:@"Announcer" ofType:@"sb"];
        [[NSFileManager defaultManager] copyItemAtPath:announcerSoundboardBundlePath toPath:announcerSoundboardPath error:NULL];
    }
    
    
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SOUNDBOARDS_DIR error:NULL];
        
    for(NSString* file in files)
    {
        if ([[file pathExtension] isEqualToString:@"sb"])
        {
            
            if ([Soundboard isValidSoundboard:[SOUNDBOARDS_DIR stringByAppendingPathComponent:file]])
            {
                [_soundboards addObject:[[Soundboard alloc] initWithFile:[SOUNDBOARDS_DIR stringByAppendingPathComponent:file]]];
                NSLog(@"Soundboard validated: %@",file);
            }
            else
            {
                NSLog(@"Removing invalid soundboard: %@",file);
                [[NSFileManager defaultManager] removeItemAtPath:[SOUNDBOARDS_DIR stringByAppendingPathComponent:file] error:NULL];
            }
            
        }
    }
    
    [self.tableView reloadData];
}

-(void)downloadSoundboard:(NSString*)heroName
{
    NSLog(@"Downloading soudboard for hero \"%@\"...",heroName);
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.labelText = NSLocalizedString(@"Downloading, please wait...",nil);
    hud.progress = 0;
    
    [addSoundboardButton setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSString *refinedValue = [[heroName stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"\'" withString:@"%27"];
        
        downloadOperation = [[AFAmazonS3Client alloc]
                             initWithAccessKeyID:@"AKIAI5PZZ6LV4RHLWWWQ"
                             secret:@"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"];
        downloadOperation.bucket = @"d2sb";
        
        NSString *output = [SOUNDBOARDS_DIR stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sb",refinedValue]];
        
        __unsafe_unretained typeof(self) weakSelf = self;
        __unsafe_unretained typeof(NSArray*) weakRequestParameters = urlRequestParameters;

        NSLog(@"Amazon S3 object path: \"%@\".",[NSString stringWithFormat:@"%@%@.sb",S3_BASE_URL,refinedValue]);
        
        [downloadOperation getObjectWithPath:[NSString stringWithFormat:@"/%@.sb",refinedValue]
                                outputStream:[NSOutputStream outputStreamToFileAtPath:output append:NO]
                                progress:^(NSUInteger bytesRead , long long totalBytesRead, long long expectedSize)
                                {
                                    if (!isDownloading)
                                    {
                                        isDownloading = YES;
                                    }
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        [hud setProgress:(float)totalBytesRead/(float)expectedSize];
                                        
                                    });
                                }
                                success:^(id responseObject)
                                {
                                    isDownloading = NO;
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        NSLog(@"Soundboard \"%@\" successfully downloaded!",[NSString stringWithFormat:@"%@.sb",refinedValue]);
                                        
                                        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                                        [weakSelf reloadSoundboards];
                                        [weakSelf.addSoundboardButton setEnabled:YES];
                                        
                                    });
                                    
                                        #ifdef USE_TESTFLIGHT
                                    [TestFlight passCheckpoint:@"DOWNLOAD_SOUNDBOARD"];
                                        #endif
                                    
                                    if (weakRequestParameters)
                                    {
                                        [weakSelf reloadSoundboards];
                                        [weakSelf performSegueWithIdentifier:@"detail" sender:weakSelf];
                                        
                                    }
                                }
                                failure:^(NSError *error)
                                {
                                    isDownloading = NO;
                                    
                                    if ([[NSFileManager defaultManager] fileExistsAtPath:output])
                                    {
                                        [[NSFileManager defaultManager] removeItemAtPath:output error:NULL];
                                    }
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                                        [weakSelf.addSoundboardButton setEnabled:YES];
                                        
                                    });
                                    
                                    NSLog(@"Error while downloading soundboard \"%@\": \"%@\"!",[NSString stringWithFormat:@"%@.sb",refinedValue],[error localizedDescription]);
                                    
                                    BlockAlertView *alert = [[BlockAlertView alloc]
                                                             initWithTitle:NSLocalizedString(@"Download Error!",nil)
                                                             message:[error localizedDescription]];
                                    
                                    [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
                                    
                                    [alert show];
                                
                                }
         ];
                
    
    }); //Dispatch-async end
    
    
}



-(IBAction)addSoundboard:(id)sender
{    
    NSMutableArray *allSoundboards = [_heroes mutableCopy];
    
    NSMutableArray *installedSoundboards = [[NSMutableArray alloc] init];
    
    for(Soundboard *s in _soundboards)
    {
        [installedSoundboards addObject:[s name]];
    }
    
    [allSoundboards removeObjectsInArray:installedSoundboards];
    
    if ([allSoundboards count])
    {
        ActionStringDoneBlock doneBlock = ^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue)
        {
            [self downloadSoundboard:selectedValue];
        };
        
        
        [ActionSheetStringPicker 
            showPickerWithTitle:NSLocalizedString(@"Available Soundboards",nil)
            rows:allSoundboards
            initialSelection:0
            doneBlock:doneBlock
            cancelBlock:nil
            origin:sender];
            
    }
    else
    {
        BlockAlertView *alert = [[BlockAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"Warning",nil)
                                 message:NSLocalizedString(@"You have downloaded all the available soundboards!",nil)];
        
        [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
        
        [alert show];

    }
    
}

#pragma mark - Tableview methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!isDownloading)
    {
        //Announcer is freaking untouchable! Mama, look at him! (Axe RIP)
        if ([[[_soundboards objectAtIndex:indexPath.row] name] isEqualToString:@"Announcer"] )
        {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *targetSoundboard = [[_soundboards objectAtIndex:indexPath.row] file];
        
        NSLog(@"User deleted \"%@\" soundboard.",targetSoundboard);
         #ifdef USE_TESTFLIGHT
        [TestFlight passCheckpoint:@"REMOVE_SOUNDBOARD"];
         #endif
        
        [[NSFileManager defaultManager] removeItemAtPath:targetSoundboard error:NULL];
                
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [_soundboards removeObjectAtIndex:indexPath.row];
        [self.tableView endUpdates];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return [_soundboards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    static NSString *CellIdentifier = @"Cell";
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Soundboard *soundboard = _soundboards[indexPath.row];
    
    //Hero Label
    UILabel *heroLabel = (UILabel*)[cell viewWithTag:101];
    [heroLabel setText:[soundboard name]];
    
    //Hero Subtitle
    UILabel *heroSubtitle = (UILabel*)[cell viewWithTag:103];
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[soundboard file] error:NULL];
    [heroSubtitle setText:[NSString stringWithFormat:NSLocalizedString(@"%d clips - Size: %.2f MB",nil),[soundboard numberOfClips],[dict fileSize]/(float)1048576]];
    
    //Hero Image
    UIImageView *heroImageView = (UIImageView*)[cell viewWithTag:102];
    NSString *iconFile = [NSString stringWithFormat:@"%@%@.png",NSTemporaryDirectory(),[soundboard name]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconFile])
    {
        NSData *iconData = [soundboard iconData];
        [iconData writeToFile:iconFile atomically:YES];
    }
    
    [heroImageView setImage:[UIImage imageWithContentsOfFile:iconFile]];
    
    [cell.layer setCornerRadius:15.0f];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setBorderColor:[UIColor grayColor].CGColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
    return cell;
}

#pragma mark - Segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"detail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        D2SBDetailViewController *destinationViewController = [segue destinationViewController];
        
        if (urlRequestParameters)
        {
            Soundboard *s;
            
            for(Soundboard *_s in _soundboards)
            {
                if ([[_s name] isEqualToString:[urlRequestParameters objectAtIndex:0]])
                {
                    s = _s;
                }
            }
            
            destinationViewController.soundboard = s;
            destinationViewController.requestedClip = (int)[[urlRequestParameters objectAtIndex:1] unsignedIntegerValue];
            
            urlRequestParameters = nil;
        }
        else
        {
            destinationViewController.soundboard = _soundboards[indexPath.row];
            destinationViewController.requestedClip = -1;
        }
    }
}

#pragma mark - NXSMLParser methods

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"hero"] && _xmlParserMode == HEROES_XML)
    {
        [_heroes addObject:[attributeDict valueForKey:@"name"]];
    }
}

@end
