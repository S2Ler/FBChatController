
#import <Foundation/Foundation.h>

typedef NSString FBChatMessageType;

typedef struct {
  FBChatMessageType *const standard;
  FBChatMessageType *const poke;
} FBChatMessageTypes;
extern FBChatMessageTypes messageTypes;