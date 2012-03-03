
#pragma mark - include
#import "FBChatSession.h"
#import "XMPPJID.h"
#import "GCDMulticastDelegate.h"
#import "DSQueue.h"
#import "XMPPStream.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"
#import "DSQueue.h"
#import "NSString+Chat.h"
#import "XMPPJID+DSAdditions.h"

#pragma mark - props
@interface FBChatSession()
@end

#pragma mark - private
@interface FBChatSession(Private)
@end

@implementation FBChatSession
#pragma mark - synth

- (XMPPJID *)friendJID {
  __block XMPPJID *result = nil;
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    result = [_friendJID copy];
    
    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  return [result autorelease];
}

- (XMPPJID *)myJID {
  __block XMPPJID *result = nil;
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    result = [_myJID copy];
    
    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  return [result autorelease];  
}

- (BOOL)isMyMessage:(XMPPMessage *)theMessage {
  __block BOOL result = NO;
  [theMessage retain];
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([[theMessage from] isEqualToJID:_myJID]) {
      result = YES;
    } else {
      result = NO;
    }
    
    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  [theMessage release];
  
  return result;
}

#pragma mark - memory
- (void)dealloc {
  [_myJID release];
  [_friendJID release];
  [_multicastDelegate release];
  [_stream removeDelegate:self
            delegateQueue:_chatQueue];
  [_stream release];
  [_unreadMessages release];
   
  [super dealloc];    
}

#pragma mark - init
- (id)initWithMyJID:(XMPPJID *)theMyJID
          friendJID:(XMPPJID *)theFriendJID 
             stream:(XMPPStream *)theStream 
              queue:(dispatch_queue_t)theQueue {
  self = [super init];
  
  if (self) {
    _myJID = [theMyJID copy];
    _friendJID = [theFriendJID copy];    
    _multicastDelegate = [[GCDMulticastDelegate alloc] init];
    _stream = [theStream retain];         
    _unreadMessages = [[DSQueue alloc] init];
    _history = [[DSQueue alloc] initWithCapacity:30];    
    
    if (theQueue)
		{
			_chatQueue = theQueue;
			dispatch_retain(_chatQueue);
		}
		else
		{
			const char *moduleQueueName = [NSStringFromClass([self class]) UTF8String];
			_chatQueue = dispatch_queue_create(moduleQueueName, NULL);
		}
    
    [_stream addDelegate:self
           delegateQueue:_chatQueue];
  }
  
  return self;
}

#pragma mark - delegates
- (void)addDelegate:(id)theDelegate 
      delegateQueue:(dispatch_queue_t)theQueue {
  [_multicastDelegate addDelegate:theDelegate
                    delegateQueue:theQueue];
}

- (void)removeDelegate:(id)theDelegate {
  [_multicastDelegate removeDelegate:theDelegate];
}

#pragma mark - unread messages
- (NSInteger)unreadCount {
  __block NSInteger unreadCount = 0;
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    unreadCount = [_unreadMessages count];
    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  return unreadCount;  
}

- (NSArray *)unreadMessagesMakeAllRead:(BOOL)theReadAllFlag {  
  __block DSQueue *unreadMessagesDeepCopy = nil;
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    unreadMessagesDeepCopy 
    = [[NSKeyedUnarchiver unarchiveObjectWithData:
        [NSKeyedArchiver archivedDataWithRootObject:_unreadMessages]] retain];
    
    if (theReadAllFlag) {
      [_unreadMessages removeAll];
    }
    
    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  NSArray *undreadArray = [unreadMessagesDeepCopy array];
  [unreadMessagesDeepCopy autorelease];
  
  return undreadArray;
}

- (NSArray *)history {
  __block DSQueue *historyCopy = nil;
  
  dispatch_block_t block = ^{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    historyCopy 
    = [[NSKeyedUnarchiver unarchiveObjectWithData:
        [NSKeyedArchiver archivedDataWithRootObject:_history]] retain];

    for (id message in [historyCopy objectEnumerator]) {
      [XMPPMessage messageFromElement:message];
    }

    [pool release];
  };
  
  if (dispatch_get_current_queue() == _chatQueue) {
    block();
  } else {
    dispatch_sync(_chatQueue, block);
  }
  
  NSArray *historyArray = [historyCopy array];
  [historyCopy autorelease];
  
  return historyArray;
}

- (void)sendMessage:(NSString *)theMessage
               type:(FBChatMessageType *)theMessageType {
  dispatch_block_t block = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
    NSXMLElement *body 
    = [NSXMLElement elementWithName:@"body" stringValue:theMessage];
		
		XMPPMessage *message = [XMPPMessage message];
    
    [message addAttributeWithName:@"from" stringValue:[_myJID full]];
		[message addAttributeWithName:@"to" stringValue:[_friendJID full]];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
    NSString *messageIDNode = [NSString messageIDNodeWithID:[_stream generateUUID]
                                                       type:theMessageType];
    [message addAttributeWithName:@"id" stringValue:messageIDNode];
		[message addChild:body];
		
    [_history push:message];
		[_stream sendElement:message];
    [_multicastDelegate chat:self
              didSendMessage:message];
		
		[pool drain];
	};
	
	if (dispatch_get_current_queue() == _chatQueue)
		block();
	else
		dispatch_sync(_chatQueue, block);
}

#pragma mark - XMPPStreamDelegate
- (void)xmppStream:(XMPPStream *)sender 
 didReceiveMessage:(XMPPMessage *)message {
  if ([message isChatMessageWithBody] == NO) {
    return;
  }
  
  XMPPJID *from = [message from];
  XMPPJID *to = [message to];
  
  if ([from isEqualBareToJID:_friendJID] &&
      [to isEqualBareToJID:_myJID]) {
    [_unreadMessages push:message];
    [_history push:message];
    
    [_multicastDelegate chat:self
           didRecieveMessage:message];
    
    if ([message isRead] == YES) {
      [_unreadMessages pop];
    }
  }
}
@end