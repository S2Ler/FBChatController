
#import <Foundation/Foundation.h>

@class FBChatController;
@class XMPPvCardTemp;
@class XMPPJID;

@protocol FBChatControllerDelegate <NSObject>
@optional
/** Called when user changes his status */
- (void)serverClient:(FBChatController *)theClient
  didReceivePresense:(NSString *)thePresenseType
            fromUser:(NSString *)theUserJID;

/** 
 \param theSuccessFlag if YES - chatController successfully logged in FacebookChat,
 if NO - theError won't be nil.
 \param theError comes directly from XMPPFramework.  
 Can have a wide range of different error codes, domains
 */
- (void)      chatController:(FBChatController *)theClient 
 didAuthenticateSuccessfully:(BOOL)theSuccessFlag
                       error:(NSError *)theError;

/** Call on everychanges in Roster: user becomes available, user deleted from roster, etc.
 You should reload your users table on this method. */
- (void)chatControllerRosterChanged:(FBChatController *)theClient;

/** This method called when new vCard return from the server */
- (void)chatcontroller:(FBChatController *)theController
           didGetVCard:(XMPPvCardTemp *)theVCard
                forJID:(XMPPJID *)theJID;
@end
