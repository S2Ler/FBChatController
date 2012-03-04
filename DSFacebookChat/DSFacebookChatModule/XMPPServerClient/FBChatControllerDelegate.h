
#import <Foundation/Foundation.h>

@class FBChatController;
@class XMPPvCardTemp;
@class XMPPJID;

@protocol FBChatControllerDelegate <NSObject>
@optional
- (void)serverClient:(FBChatController *)theClient
  didReceivePresense:(NSString *)thePresenseType
            fromUser:(NSString *)theUserJID;

/** 
 \param theError comes directly from XMPPFramework
 */
- (void)      chatController:(FBChatController *)theClient 
 didAuthenticateSuccessfully:(BOOL)theSuccessFlag
                       error:(NSError *)theError;

- (void)chatControllerRosterChanged:(FBChatController *)theClient;

- (void)chatcontroller:(FBChatController *)theController
           didGetVCard:(XMPPvCardTemp *)theVCard
                forJID:(XMPPJID *)theJID;
@end
