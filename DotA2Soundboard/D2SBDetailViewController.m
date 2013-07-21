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

#import "MBProgressHUD.h"

@implementation D2SBDetailViewController {
    
    @private
    NSMutableArray *_clipsTitles;
    NSMutableArray *_searchedClips;
    UITableViewCell *_previouslySelectedCell;
    UITableView *_activeTableView;
    UILongPressGestureRecognizer *_lpgr;
    
}

@synthesize soundboard;
@synthesize player;
@synthesize requestedClip;

#pragma mark - View methods

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f)
    {
        //iPhone5
        NSString *image = [[NSBundle mainBundle] pathForResource:@"background-568h@2x" ofType:@"png"];
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
        self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:image]];
    }
    else
    {
        //Other iPhones
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
        self.searchDisplayController.searchResultsTableView.backgroundColor  = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
    
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
    self.searchDisplayController.searchResultsTableView.bounces = NO;
    
    self.navigationItem.title = [soundboard name];
    
    _clipsTitles = [[NSMutableArray alloc] init];
    _searchedClips = [[NSMutableArray alloc] init];
    
    int clipsno = [soundboard numberOfClips];
    
    for(int i=0;i<clipsno;i++)
    {
        [_clipsTitles addObject:[soundboard clipTitleAtIndex:i]];
    }
    
    if (requestedClip >= 0 && requestedClip <= [_clipsTitles count]-1)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:requestedClip inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    
    _lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _lpgr.minimumPressDuration = 2;
    [self.tableView addGestureRecognizer:_lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)recognizer{
    
    if (_lpgr.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [_lpgr locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        
        if (_activeTableView == self.searchDisplayController.searchResultsTableView)
        {
            indexPath = [NSIndexPath indexPathForRow: [soundboard clipIndexFromTitle:[_searchedClips objectAtIndex:indexPath.row]] inSection:0];
        }
        
        NSString *urlString = [NSString stringWithFormat:@"d2sb://%@/%03d",[soundboard name],indexPath.row];
        urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"\'" withString:@"%27"];
        
        NSLog(@"%@",urlString);
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.URL = [NSURL URLWithString:urlString];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.opacity = 0.5f;
        hud.labelText = NSLocalizedString(@"Link copied to clipboard.",nil);
        
        [hud hide:YES afterDelay:2];
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
    }
    else
    {
        clipData = [soundboard clipDataFromClipAtIndex:indexPath.row];
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
    _activeTableView = tableView;
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
        
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

@end

