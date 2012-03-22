
#import <Foundation/Foundation.h>
#import "FBChatControllerDelegate.h"
#import "FBChatControllerMessengerDelegate.h"
#import "XMPPStream.h"
#import "FBChatVCardClientDelegate.h"
#import "XMPPUser.h"
#import "XMPPMessage+Chat.h"
#import "XMPPvCardTemp.h"

@interface FBChatController : NSObject
<
XMPPStreamDelegate,
FBChatVCardClientDelegate
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

- (NSArray *)whoIsAvailable;
- (void)sendMessage:(NSString*)msg to:(XMPPJID *)theRecipient;

#pragma mark - users photos

/** \return Previous cached with requestVCardForUser: user's vCard.
 General UseCase: 
 1. Call this method.
 2. If it returns nil, call requestVCardForUser: */
- (XMPPvCardTemp *)vCardForUser:(XMPPJID *)theUser;

/** Request JID's vCard from the server asynchronously. 
 The result will be delivered through delegate supplied with init method through
 message: chatcontroller:didGetVCard:forJID:
 vCards are cached in CoreData and can be gotten with vCardForUser: message.
 */
- (void)requestVCardForUser:(XMPPJID *)theJID;

@end
