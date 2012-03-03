
#import <Foundation/Foundation.h>
#import "XMPPMessage.h"
#import "FBChatMessageType.h"

@interface XMPPMessage (XMPPMessage_Chat)
- (NSString *)body;
- (FBChatMessageType *)messageType;
- (BOOL)isRead;
/** Mark message as read */
- (void)setRead;
@end
