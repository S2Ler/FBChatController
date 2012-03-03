
#import <Foundation/Foundation.h>
#import "FBChatControllerDelegate.h"
#import "XMPPStream.h"

@class XMPPJID;
@class XMPPIDTracker;

@interface FBChatController : NSObject
<
XMPPStreamDelegate
> 

@property (assign) id<FBChatControllerDelegate> delegate;

- (XMPPStream *)xmppStream;

/** Works on main queue */
- (XMPPIDTracker *)IDTracker;

@property (retain) XMPPJID *JID;

- (id)initWithAppID:(NSString *)theAppID  
      FBAccessToken:(NSString *)theFBAccessToken
       withDelegate:(id<FBChatControllerDelegate>)theDelegate;

/** \return nil if connection is successful */
- (NSError *)connect;

- (void)disconnect;

- (void)goOnline;
- (void)goOffline;

@end
