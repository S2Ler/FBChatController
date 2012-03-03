
#import "NSString+Chat.h"


@implementation NSString (NSString_Chat)
+ (NSString *)messageIDNodeWithID:(NSString *)theID
                             type:(NSString *)theType {
  return [NSString stringWithFormat:@"%@;%@",
          theID, theType];
}

- (NSString *)messageIDFromIDNode {  
  NSRange delimeterRange = [self rangeOfString:@";"];
  
  if (delimeterRange.location != NSNotFound) {
    NSRange IDRange = NSMakeRange(0, delimeterRange.location);
    return [self substringWithRange:IDRange];
  } else {
    return nil;
  }
}

- (FBChatMessageType *)messageTypeFromIDNode {
  NSRange delimeterRange = [self rangeOfString:@";"];
  
  if (delimeterRange.location != NSNotFound) {
    NSRange typeRange = NSMakeRange(delimeterRange.location+1,
                                    [self length] -
                                    delimeterRange.location-1);
    return [self substringWithRange:typeRange];
  } else {
    return nil;
  }
}

@end
