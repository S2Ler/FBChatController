
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

/** Work on main queue */
- (XMPPIDTracker *)IDTracker;

@property (retain) XMPPJID *JID;
@property (retain) NSString *password;
@property (retain) NSString *host;
@property (retain) NSString *hostPort;

- (id)initWithAppID:(NSString *)theAppID  
      FBAccessToken:(NSString *)theFBAccessToken
       withDelegate:(id<FBChatControllerDelegate>)theDelegate;

/** \return nil if connection is successful */
- (NSError *)connect;

- (void)disconnect;

/** Set JID and password properties before. */
- (void)goOnline;

/** Set JID and password properties before. */
- (void)goOffline;

- (void)beginSendingGeolocInfo;

@end
