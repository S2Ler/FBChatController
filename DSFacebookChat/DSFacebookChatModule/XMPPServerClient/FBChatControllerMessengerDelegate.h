//
//  FBChatControllerMessengerDelegate.h
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 3/3/12.
//  Copyright (c) 2012 AS IS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPMessage;
@class FBChatController;

@protocol FBChatControllerMessengerDelegate <NSObject>
@optional
- (void)chatController:(FBChatController *)theController
  didReceiveNewMessage:(XMPPMessage *)theMessage;
@end
