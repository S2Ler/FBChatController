
#import <Foundation/Foundation.h>

@class FBChatMessengerModule;
@class FBChatSession;

@protocol FBChatMessengerModuleDelegate <NSObject>
- (void)messengerModule:(FBChatMessengerModule *)theMessenger
       didCreateNewChat:(FBChatSession *)theChat;
@end
