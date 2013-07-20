//
//  D2SBMasterViewController.m
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import "D2SBMasterViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "ActionSheetStringPicker.h"
#import "D2SBDetailViewController.h"
#import "MBProgressHUD.h"
#import "Soundboard.h"

#define DOCUMENTS [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define CDN_BASE_URL @"https://dl.dropboxusercontent.com/u/26014957/Soundboards/"

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

#pragma mark - View methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _heroes = [[NSMutableArray alloc] init];
    _soundboards = [[NSMutableArray alloc] init];
    
        
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f)
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
	
}

#pragma mark - Soundboards-related methods

-(void)reloadSoundboards
{
    _soundboards = [[NSMutableArray alloc] init];
    
    //Announcer soundboard check
    NSString *announcerSoundboardPath = [DOCUMENTS stringByAppendingPathComponent:@"Announcer.sb"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:announcerSoundboardPath])
    {
        NSString *announcerSoundboardBundlePath = [[NSBundle mainBundle] pathForResource:@"Announcer" ofType:@"sb"];
        [[NSFileManager defaultManager] copyItemAtPath:announcerSoundboardBundlePath toPath:announcerSoundboardPath error:NULL];
    }
    
    
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DOCUMENTS error:NULL];
        
    for(NSString* file in files)
    {
        if ([[file pathExtension] isEqualToString:@"sb"])
        {
            
            if ([Soundboard isValidSoundboard:[DOCUMENTS stringByAppendingPathComponent:file]])
            {
                [_soundboards addObject:[[Soundboard alloc] initWithFile:[DOCUMENTS stringByAppendingPathComponent:file]]];
                NSLog(@"Soundboard validated: %@",file);
            }
            else
            {
                NSLog(@"Removing invalid soundboard: %@",file);
                [[NSFileManager defaultManager] removeItemAtPath:[DOCUMENTS stringByAppendingPathComponent:file] error:NULL];
            }
            
        }
    }
    
    [self.tableView reloadData];
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
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeAnnularDeterminate;
            hud.labelText = NSLocalizedString(@"Downloading, please wait...",nil);
            hud.progress = 0;
            
            [addSoundboardButton setEnabled:NO];
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                NSString *refinedValue = [selectedValue stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                NSString *downloadUrl = [NSString stringWithFormat:@"%@%@.sb",CDN_BASE_URL,refinedValue];

                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
                downloadOperation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
                
               
                NSString *output = [DOCUMENTS stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sb",refinedValue]];
                                                
                downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:output append:NO];
                
                [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long expectedSize) {
                                        
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [hud setProgress:(float)totalBytesRead/(float)expectedSize];
                        
                    });
                    
                }];
                __unsafe_unretained typeof(self) weakSelf = self;
                [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        
                    //SUCCESS
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                        [weakSelf reloadSoundboards];
                        [weakSelf.addSoundboardButton setEnabled:YES];
                        
                    });
                    
                } failure:^(AFHTTPRequestOperation *op, NSError *error) {
                    
                    
                    //FAILURE
                    if ([[NSFileManager defaultManager] fileExistsAtPath:output])
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:output error:NULL];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                        [weakSelf.addSoundboardButton setEnabled:YES];
                        
                    });
                    
                    UIAlertView *alert = [[UIAlertView alloc]
                                            initWithTitle:NSLocalizedString(@"Error!",nil)
                                            message:[error localizedDescription]
                                            delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                                            otherButtonTitles: nil];
                    [alert show];
                 
                }];
                [downloadOperation start];

            });
           
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
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Warning",nil)
                              message:NSLocalizedString(@"You have downloaded all the available soundboards!",nil)
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                              otherButtonTitles: nil];
        [alert show];

    }
    
}

#pragma mark - Tableview methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Announcer is freaking untouchable! Mama, look at him! (Axe RIP)
    if ([[[_soundboards objectAtIndex:indexPath.row] name] isEqualToString:@"Announcer"] )
    {
        return NO;
    }
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *targetSoundboard = [[_soundboards objectAtIndex:indexPath.row] file];
        
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }

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
        [iconData writeToFile:iconFile atomically:NO];
    }
    
    [heroImageView setImage:[UIImage imageWithContentsOfFile:iconFile]];
            
    return cell;
}

#pragma mark - Segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"detail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        D2SBDetailViewController *destinationViewController = [segue destinationViewController];
        destinationViewController.soundboard = _soundboards[indexPath.row];
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
