
#import <Foundation/Foundation.h>

@class FBChatController;

@protocol FBChatControllerDelegate <NSObject>
@optional
- (void)serverClient:(FBChatController *)theClient
  didReceivePresense:(NSString *)thePresenseType
            fromUser:(NSString *)theUserJID;

- (void)serverClient:(FBChatController *)theClient 
    didAuthenticateSuccessfully:(BOOL)theSuccessFlag;
@end
