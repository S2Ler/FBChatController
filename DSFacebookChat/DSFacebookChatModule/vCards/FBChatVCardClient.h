
#import <Foundation/Foundation.h>
#import "FBChatVCardClientDelegate.h"
#import "XMPPModule.h"

@class XMPPJID;
@class XMPPvCardTemp;
@class XMPPIDTracker;

@interface FBChatVCardClient : XMPPModule 

- (id)initWithIDTracker:(XMPPIDTracker *)theIDTracker;

- (void)request_vCardForJID:(XMPPJID *)theJID;

- (XMPPvCardTemp *)saved_vCardForJID:(XMPPJID *)theJID;
- (NSString *)photoHashForForJID:(XMPPJID *)theJID;

@end
