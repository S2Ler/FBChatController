
#import <Foundation/Foundation.h>
#import "FBChatMessageType.h"

/** <message id="messageID;messageType">  
 "messageID;messageType" is IDNode */
@interface NSString (NSString_Chat)
+ (NSString *)messageIDNodeWithID:(NSString *)theID
                             type:(NSString *)theType;

- (NSString *)messageIDFromIDNode;

- (FBChatMessageType *)messageTypeFromIDNode;
@end
