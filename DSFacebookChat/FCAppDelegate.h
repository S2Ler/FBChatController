//
//  FCAppDelegate.h
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class FCViewController;

@interface FCAppDelegate : UIResponder 
<
UIApplicationDelegate,
FBSessionDelegate
>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) FCViewController *viewController;

@end
