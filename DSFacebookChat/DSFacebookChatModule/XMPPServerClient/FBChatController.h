
#import <Foundation/Foundation.h>
#import "FBChatControllerDelegate.h"
#import "FBChatControllerMessengerDelegate.h"
#import "XMPPStream.h"

@interface FBChatController : NSObject
<
XMPPStreamDelegate
> 

- (id)initWithAppID:(NSString *)theAppID  
      FBAccessToken:(NSString *)theFBAccessToken
       withDelegate:(id<FBChatControllerDelegate>)theDelegate;

/** 
 \return An Error if something wrong with settings for FBChatController.
    Connection errors is sent to delegate specified in 'init' method.
 */
- (NSError *)signInWithOnChatInputDelegate:(id<FBChatControllerMessengerDelegate>)theDelegate;

- (void)signOut;

@end
