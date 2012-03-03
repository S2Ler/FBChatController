//
//  FCViewController.h
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBChatControllerMessengerDelegate.h"
#import "FBChatControllerDelegate.h"

@interface FCViewController : UIViewController
<
FBChatControllerDelegate,
FBChatControllerMessengerDelegate
>

@property (nonatomic, retain) FBChatController *chatController;

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end
