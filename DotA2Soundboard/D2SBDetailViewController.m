//
//  D2SBDetailViewController.m
//  DotA2Soundboard
//
//  Created by Matteo Pacini on 18/07/13.
//  Copyright (c) 2013 Matteo Pacini. All rights reserved.
//

#import "D2SBDetailViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import "BlockAlertView.h"
#import "D2SBMasterViewController.h"
#import "MBProgressHUD.h"

@implementation D2SBDetailViewController {
    
    @private
    NSMutableArray *_clipsTitles;
    NSMutableArray *_searchedClips;
    UITableViewCell *_previouslySelectedCell;
    UITableView *_activeTableView;
    UILongPressGestureRecognizer *_lpgr;
    NSUInteger _pressedClipIndex;
    
}

@synthesize soundboard;
@synthesize player;
@synthesize requestedClip;
@synthesize dic;
@synthesize searchButton;

#pragma mark - View methods

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (IS_IPHONE5)
    {
        //iPhone5
        NSString *image = [[NSBundle mainBundle] pathForResource:@"background-568h@2x" ofType:@"png"];
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
        //self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
    }
    else
    {
        //Other iPhones
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
        //self.searchDisplayController.searchResultsTableView.backgroundColor  = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
    
    //self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
    //self.searchDisplayController.searchResultsTableView.bounces = NO;
    
    self.navigationItem.title = [soundboard name];
    
    _clipsTitles = [[NSMutableArray alloc] initWithCapacity:[soundboard numberOfClips]];
    _searchedClips = [[NSMutableArray alloc] init];
    
    int clipsno = [soundboard numberOfClips];
    
    for(int i=0;i<clipsno;i++)
    {
        [_clipsTitles addObject:[soundboard clipTitleAtIndex:i]];
    }
    
    _lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _lpgr.minimumPressDuration = 1.5;
    [self.tableView addGestureRecognizer:_lpgr];
    
    //Search button
    searchButton.image = [UIImage imageNamed:@"magnify.png"];
    
    //Search bar hideout
    CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
    CGFloat searchBarHeight = searchBarFrame.size.height;
    CGPoint offsetFrame = CGPointMake(0,searchBarHeight);
    [self.tableView setContentOffset:offsetFrame];
        
    //Handle request
    if (requestedClip >= 0 && requestedClip <= [_clipsTitles count]-1)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:requestedClip inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        [TestFlight passCheckpoint:@"CLIP_PLAYED_FROM_URL"];
    }
}

-(IBAction)onSearchButtonClick:(id)sender
{
    [self.tableView scrollRectToVisible:self.searchDisplayController.searchBar.frame animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    NSString *urlString = [NSString stringWithFormat:@"d2sb://%@/%03d",[soundboard name],_pressedClipIndex];
    urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"\'" withString:@"%27"];
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Copy Link", nil)])
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.URL = [NSURL URLWithString:urlString];
        
        BlockAlertView *alert = [[BlockAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"Success!",nil)
                                 message:NSLocalizedString(@"Link has been copied to clipboard!",nil)];
        
        [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
        
        [alert show];
        
        NSLog(@"Clip URL copied to clipboard: \"%@\".",urlString);
        
         #ifdef USE_TESTFLIGHT
        [TestFlight passCheckpoint:@"URL_SHARE"];
         #endif
    }
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Save Clip", nil)])
    {
        NSData *clipData = [soundboard clipDataFromClipAtIndex:_pressedClipIndex];
        NSString *output = [RINGTONES_DIR stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - \"%@\".mp3",[soundboard name],[soundboard clipTitleAtIndex:_pressedClipIndex]]];
        
        [clipData writeToFile:output atomically:YES];
        
        BlockAlertView *alert = [[BlockAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"Success!",nil)
                                 message:NSLocalizedString(@"Clip has been saved to D2SB Documents!\n\nConnect your device to iTunes and go to the App section to retrieve the saved content.",nil)];
        
        [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
        
        [alert show];
        
        NSLog(@"Clip saved to RINGTONES_DIR: \"%@\".",output);
        
         #ifdef USE_TESTFLIGHT
        [TestFlight passCheckpoint:@"CLIP_SAVE"];
         #endif

    }
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Share Link (WhatsApp)",nil)])
    {
        NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@",urlString]];
        
        NSLog(@"WhatsApp URL: \"%@\".",whatsappURL);

        if ([[UIApplication sharedApplication] canOpenURL: whatsappURL])
        {
            [[UIApplication sharedApplication] openURL: whatsappURL];
            
             #ifdef USE_TESTFLIGHT
            [TestFlight passCheckpoint:@"URL_SHARE_WHATSAPP"];
             #endif
        }
        else
        {
            BlockAlertView *alert = [[BlockAlertView alloc]
                                     initWithTitle:NSLocalizedString(@"Error",nil)
                                     message:NSLocalizedString(@"WhatsApp is not installed!",nil)];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
            
            [alert show];
        }

    }
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"Share Clip (WhatsApp)",nil)])
    {
        NSData *clipData = [soundboard clipDataFromClipAtIndex:_pressedClipIndex];
        NSString *output = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - \"%@\".waa",[soundboard name],[soundboard clipTitleAtIndex:_pressedClipIndex]]];
        
        [clipData writeToFile:output atomically:YES];
        
        dic = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:output]];
        
        if(![dic presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES])
        {
            BlockAlertView *alert = [[BlockAlertView alloc]
                                     initWithTitle:NSLocalizedString(@"Error",nil)
                                     message:NSLocalizedString(@"WhatsApp is not installed!",nil)];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil) imageIdentifier:@"gray" block:^(){}];
            
            [alert show];
        }
        else
        {
             #ifdef USE_TESTFLIGHT
            [TestFlight passCheckpoint:@"CLIP_SHARE_WHATSAPP"];
             #endif
        }
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)recognizer{
    
    if (_lpgr.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"Long press detected ");
        
        CGPoint p = [_lpgr locationInView:_activeTableView];
        NSIndexPath *indexPath = [_activeTableView indexPathForRowAtPoint:p];
        NSString *clipTitle = nil;
        
        if (_activeTableView == self.searchDisplayController.searchResultsTableView)
        {
            clipTitle = [_searchedClips objectAtIndex:indexPath.row];
        }
        else
        {
            clipTitle = [_clipsTitles objectAtIndex:indexPath.row];
        }
        
        _pressedClipIndex = [soundboard clipIndexFromTitle:clipTitle];
         
                
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                        initWithTitle:NSLocalizedString(@"Actions", nil)
                                        delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                        destructiveButtonTitle:nil
                                        otherButtonTitles:
                                            NSLocalizedString(@"Copy Link", nil),
                                            NSLocalizedString(@"Save Clip", nil),
                                            NSLocalizedString(@"Share Link (WhatsApp)",nil),
                                            NSLocalizedString(@"Share Clip (WhatsApp)",nil),nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        [actionSheet showInView:self.tableView];
        
    }
}

#pragma mark - AVAudioPlayer delegate methods

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    UITableViewCell *currentCell = nil;
    
    if (_activeTableView == self.tableView) {
        currentCell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    } else {
        currentCell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:
                       [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow]];
    }
    
    
    [currentCell.layer setBorderColor:[UIColor grayColor].CGColor];
    [currentCell.layer setBorderWidth:1.0f];
        
}

#pragma mark - Tableview methods


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //Cell stuff
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [_previouslySelectedCell.layer setBorderColor:[UIColor grayColor].CGColor];
    [_previouslySelectedCell.layer setBorderWidth:1.0f];
    
    [currentCell.layer setBorderColor:[UIColor greenColor].CGColor];
    [currentCell.layer setBorderWidth:4.0f];
     
    //Audio
    NSData *clipData = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        
        clipData = [soundboard clipDataFromClipAtIndex:[soundboard clipIndexFromTitle:[_searchedClips objectAtIndex:indexPath.row]]];
        NSLog(@"Playing clip \"%@\"(index %d) of soundboard \"%@\"...",
              [_searchedClips objectAtIndex:indexPath.row],
              [soundboard clipIndexFromTitle:[_searchedClips objectAtIndex:indexPath.row]],
              [soundboard name]);
    }
    else
    {
        clipData = [soundboard clipDataFromClipAtIndex:indexPath.row];
        NSLog(@"Playing clip \"%@\"(index %d) of soundboard \"%@\"...",
              [_clipsTitles objectAtIndex:indexPath.row],
              indexPath.row,
              [soundboard name]);
    }
    
    if (player && [player isPlaying])
    {
        [player stop];
    }
    
    NSString* clipFile =  [NSString stringWithFormat:@"%@clip.mp3", NSTemporaryDirectory()];
    [clipData writeToFile:clipFile atomically:NO];
    
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:clipFile] error:&error];
    player.delegate = self;
        
    [player prepareToPlay];
    [player play];
    
    _previouslySelectedCell = currentCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    _activeTableView = tableView;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [_searchedClips count];
    }
    else
    {
         return [_clipsTitles count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    static NSString *CellIdentifier = @"Cell";
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //Clip title
    UILabel *clipTitleLabel = (UILabel*)[cell viewWithTag:101];
    clipTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    clipTitleLabel.numberOfLines = 5;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        [clipTitleLabel setText:[NSString stringWithFormat:@"\"%@\"",[_searchedClips objectAtIndex:indexPath.row]]];
    }
    else
    {        
        [clipTitleLabel setText:[NSString stringWithFormat:@"\"%@\"",[_clipsTitles objectAtIndex:indexPath.row]]];
    }
    
    
    //Hero image
    UIImageView *heroImageView = (UIImageView*)[cell viewWithTag:102];
    NSString *iconFile = [NSString stringWithFormat:@"%@%@.png",NSTemporaryDirectory(),[soundboard name]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconFile])
    {
        NSData *iconData = [soundboard iconData];
        [iconData writeToFile:iconFile atomically:NO];
    }
    
    [heroImageView setImage:[UIImage imageWithContentsOfFile:iconFile]];
    
    [cell.layer setCornerRadius:15.0f];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setBorderColor:[UIColor grayColor].CGColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
    return cell;
}


#pragma mark - SearchDisplayController delegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@",searchString];
    _searchedClips = [[_clipsTitles filteredArrayUsingPredicate:predicate] mutableCopy];
    
    return YES;
}

-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    
    if (IS_IPHONE5)
    {
        //iPhone5
        NSString *image = [[NSBundle mainBundle] pathForResource:@"background-568h@2x" ofType:@"png"];
        tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
    }
    else
    {
        //Other iPhones
        tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight = 80;
    tableView.bounces = NO;
    
     #ifdef USE_TESTFLIGHT
    [TestFlight passCheckpoint:@"CLIP_SEARCH"];
     #endif
    
}


@end

