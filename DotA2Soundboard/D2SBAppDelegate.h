#import <UIKit/UIKit.h>

#import "D2SBMasterViewController.h"

#define BASE_DIR @"/var/mobile/Library/D2SB"
#define SOUNDBOARDS_DIR [BASE_DIR stringByAppendingPathComponent:@"Soundboards"]
#define RINGTONES_DIR [BASE_DIR stringByAppendingPathComponent:@"Ringtones"]
#define TMP_DIR @"/tmp/D2SB/"

@interface D2SBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet D2SBMasterViewController *masterViewController;

@end
