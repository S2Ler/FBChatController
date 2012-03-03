
#import <Foundation/Foundation.h>
#import "XMPPModule.h"
#import "XMPPStream.h"

@class FBChatSession;

@interface FBChatMessengerModule : XMPPModule
<
XMPPStreamDelegate
> {
  /** key is XMPPJID with whom chat is open */
  NSMutableDictionary *_chats;
}

- (FBChatSession *)chatWithJID:(XMPPJID *)theJID;                        

+ (void)activateSharedInstanceWithStream:(XMPPStream *)theStream;

/** Call activateSharedInstanceWithStream: to get not nil result */
+ (FBChatMessengerModule *)sharedInstance;

@end
