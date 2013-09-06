///////////////////////////////////////////////////////////////////////////////
//                                                                           //
// This file is part of DotA2 Soundboard.                                    //
//                                                                           //
// DotA2 Soundboard is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by      //
// the Free Software Foundation, either version 3 of the License, or         //
// (at your option) any later version.                                       //
//                                                                           //
// DotA2 Soundboard is distributed in the hope that it will be useful,       //
// but WITHOUT ANY WARRANTY; without even the implied warranty of            //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             //
// GNU General Public License for more details.                              //
//                                                                           //
// You should have received a copy of the GNU General Public License         //
// along with DotA2 Soundboard.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

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
