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
