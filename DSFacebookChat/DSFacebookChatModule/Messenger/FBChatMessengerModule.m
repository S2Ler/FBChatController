
#pragma mark - include
#import "FBChatMessengerModule.h"
#import "XMPPJID.h"
#import "FBChatSession.h"
#import "FBChatMessengerModuleDelegate.h"
#import "XMPPStream.h"
#import "XMPPMessage.h"

static FBChatMessengerModule *sharedInstance = nil;

@implementation FBChatMessengerModule

- (id)initWithDispatchQueue:(dispatch_queue_t)queue {
  self = [super initWithDispatchQueue:queue];
  if (self) {
    _chats = [[NSMutableDictionary alloc] init];
  }
  return self;
}

+ (FBChatMessengerModule *)sharedInstance
{ 
  return sharedInstance;
}

- (NSString *)moduleName {
  return NSStringFromClass([self class]);
}

+ (void)activateSharedInstanceWithStream:(XMPPStream *)theStream {
  static dispatch_once_t once;
  dispatch_once(&once, ^ {
    sharedInstance = [[FBChatMessengerModule alloc] initWithDispatchQueue:nil];
    [sharedInstance activate:theStream];
    [theStream registerModule:sharedInstance];
  });  
}

#pragma mark - public
- (FBChatSession *)chatWithJID:(XMPPJID *)theJID {
  FBChatSession *chat = [_chats objectForKey:[theJID bareJID]];
  
  if (!chat) {
    chat = [[[FBChatSession alloc] initWithMyJID:[xmppStream myJID]
                                friendJID:theJID
                                   stream:xmppStream
                                    queue:moduleQueue] autorelease];
    [_chats setObject:chat
               forKey:[theJID bareJID]];
  }
  
  return chat;
}

#pragma mark  - 
- (void)xmppStream:(XMPPStream *)sender 
 didReceiveMessage:(XMPPMessage *)message {
  if ([message isChatMessageWithBody] == NO) {
    return;
  }
  
  XMPPJID *from = [message from];
  
  FBChatSession *chat = [_chats objectForKey:[from bareJID]];
  
  /* If there is chat in _chats then it should handle chat by it self.
   Otherwise we have to create a new one and forward unhandled message to it */
  if (!chat) {
    FBChatSession *newChat = [[FBChatSession alloc]
                    initWithMyJID:[sender myJID]
                    friendJID:from
                    stream:sender                    
                    queue:moduleQueue];
    chat = newChat;
    [newChat xmppStream:sender
      didReceiveMessage:message];
    [_chats setObject:newChat
               forKey:[from bareJID]];
    [newChat release];
    [multicastDelegate messengerModule:self
                      didCreateNewChat:chat]; 
  }                  
}


@end
