
#import <Foundation/Foundation.h>
#import "TBvCardClientDelegate.h"

@class XMPPJID;
@class XMPPvCardTemp;

@interface FBChatVCardClient : NSObject {
  NSMutableArray *_delegates;
}

- (void)addDelegate:(id<TBvCardClientDelegate>)theDelegate;
- (void)removeDelegate:(id<TBvCardClientDelegate>)theDelegate;

+ (FBChatVCardClient *)sharedInstance;

- (void)request_vCardForJID:(XMPPJID *)theJID;
- (XMPPvCardTemp *)saved_vCardForJID:(XMPPJID *)theJID;

- (void)uploadNew_vCard:(XMPPvCardTemp *)the_vCard;

@end
