
#import <Foundation/Foundation.h>

@class FBChatController;

@protocol FBChatControllerDelegate <NSObject>
@optional
- (void)serverClient:(FBChatController *)theClient
  didReceivePresense:(NSString *)thePresenseType
            fromUser:(NSString *)theUserJID;

/** 
 \param theError comes directly from XMPPFramework
 */
- (void)chatController:(FBChatController *)theClient 
    didAuthenticateSuccessfully:(BOOL)theSuccessFlag
               error:(NSError *)theError;

- (void)chatControllerRosterChanged:(FBChatController *)theClient;
@end
