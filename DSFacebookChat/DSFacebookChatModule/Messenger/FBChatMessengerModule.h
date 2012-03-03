
#import <Foundation/Foundation.h>
#import "XMPPModule.h"
#import "XMPPStream.h"

@class FBChatSession;

@interface FBChatMessengerModule : XMPPModule
<
XMPPStreamDelegate
> 

- (FBChatSession *)chatWithJID:(XMPPJID *)theJID;                        

@end
