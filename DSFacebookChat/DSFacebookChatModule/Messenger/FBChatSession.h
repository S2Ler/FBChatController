
#import <Foundation/Foundation.h>
#import "XMPPMessage+Chat.h"
#import "FBChatMessageType.h"
#import "XMPPStream.h"
#import "FBChatSessionDelegate.h"

@class XMPPJID;
@class GCDMulticastDelegate;
@class DSQueue;

/** Chart between two JIDs */
@interface FBChatSession : NSObject
<
XMPPStreamDelegate
> {
  /** The JID of the user */
  XMPPJID *_myJID;
  
  /** The JID of the user with whom _myJID is chating */
  XMPPJID *_friendJID;
  
  id _multicastDelegate;
  
  XMPPStream *_stream;
  
  DSQueue *_unreadMessages;
  DSQueue *_history;
  
  dispatch_queue_t _chatQueue;
}

- (XMPPJID *)myJID;
- (XMPPJID *)friendJID;
- (BOOL)isMyMessage:(XMPPMessage *)theMessage;

/** Both JIDs should be full, or messages will be send between bare JIDs */
- (id)initWithMyJID:(XMPPJID *)theMyJID
          friendJID:(XMPPJID *)theFriendJID
             stream:(XMPPStream *)theStream
              queue:(dispatch_queue_t)theQueue;

/** \param theMessageType \see messageTypes */
- (void)sendMessage:(NSString *)theMessage
               type:(FBChatMessageType *)theMessageType;
/** All messages stored in history. Sorted from old date to new */
- (NSArray *)history;
- (NSInteger)unreadCount;
- (NSArray *)unreadMessagesMakeAllRead:(BOOL)theReadAllFlag;

#pragma mark - delegates
- (void)addDelegate:(id)theDelegate 
      delegateQueue:(dispatch_queue_t)theQueue;

- (void)removeDelegate:(id)theDelegate;

@end
