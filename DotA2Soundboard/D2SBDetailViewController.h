#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import "Soundboard.h"

@interface D2SBDetailViewController : UITableViewController <UISearchBarDelegate,UISearchDisplayDelegate,AVAudioPlayerDelegate,UIGestureRecognizerDelegate,UIActionSheetDelegate>

@property (nonatomic,strong) IBOutlet UIBarButtonItem *searchButton;

@property (strong,nonatomic) Soundboard* soundboard;
@property (assign,nonatomic) int requestedClip;
@property (strong,nonatomic) AVAudioPlayer* player;
@property (strong,nonatomic) UIDocumentInteractionController *dic;

-(IBAction)onSearchButtonClick:(id)sender;

@end
