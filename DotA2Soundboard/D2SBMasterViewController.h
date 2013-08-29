#import <UIKit/UIKit.h>

#import "AFAmazonS3Client.h"
#import "MYIntroductionView.h"

#define HEROES_NO 102

@interface D2SBMasterViewController : UITableViewController <NSXMLParserDelegate,MYIntroductionDelegate>

@property (nonatomic,strong) IBOutlet UIBarButtonItem *addSoundboardButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *donateButton;

@property (nonatomic,strong) AFAmazonS3Client *downloadOperation;
@property (nonatomic,assign) BOOL isDownloading;

@property (nonatomic,strong) NSMutableArray *urlRequestParameters;

-(void)reloadSoundboards;
-(IBAction)addSoundboard:(id)sender;
-(void)downloadSoundboard:(NSString*)heroName;

-(BOOL)heroExists:(NSString*)heroName;
-(BOOL)isSoundboardAvailable:(NSString*)heroName;

-(IBAction)donate:(id)sender;

@end
