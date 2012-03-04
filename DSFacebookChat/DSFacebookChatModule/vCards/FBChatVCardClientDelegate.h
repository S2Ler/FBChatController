
#import <Foundation/Foundation.h>

@class FBChatVCardClient;
@class XMPPvCardTemp;
@class XMPPJID;

@protocol FBChatVCardClientDelegate <NSObject>
@optional
- (void)vCardClient:(FBChatVCardClient *)the_vCardClient
      vCardReturned:(XMPPvCardTemp *)the_vCard
             forJID:(XMPPJID *)theJID;

- (void)vCardClient:(FBChatVCardClient *)the_vCardClient 
  uploaded_vCardFor:(XMPPJID *)theUpload_vCardJID;

- (void)vCardClient:(FBChatVCardClient *)the_vCardClient
didFailUpload_vCardForJID:(XMPPJID *)theJID;

@end
