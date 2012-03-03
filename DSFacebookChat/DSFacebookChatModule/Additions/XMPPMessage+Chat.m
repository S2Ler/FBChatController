
#import "XMPPMessage+Chat.h"
#import "DDXMLElementAdditions.h"

@implementation XMPPMessage (XMPPMessage_Chat)
- (NSString *)body {
  return [[self elementForName:@"body"] stringValue];
}

- (BOOL)isRead {
  return NO;//_isRead;
}

- (FBChatMessageType *)messageType {
  return messageTypes.standard;
}

- (void)setRead {
  ;
}

@end
