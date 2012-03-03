
#import <Foundation/Foundation.h>

@class FBChatSession;
@class XMPPMessage;

@protocol FBChatSessionDelegate <NSObject>
/** use [theMessage setRead] if the message was 
 read by user (e.g. displayed to him).
 You can you [theChart unreadCount] and releated messages to get info about
 unread messages or get all of them. */
- (void)chat:(FBChatSession *)theChat
  didRecieveMessage:(XMPPMessage *)theMessage;
- (void)chat:(FBChatSession *)theChat
  didSendMessage:(XMPPMessage *)theMessage;
@end
