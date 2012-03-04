
#pragma mark - include
#import "FBChatVCardClient.h"
#import "XMPPvCardTemp.h"
#import "TBSettings.h"
#import "XMPPPresence+vCardUpdate.h"
#import "TBServerClient.h"
#import "DDLog.h"
#import "NSMutableArray+WeakReferences.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPIDTracker.h"


static FBChatVCardClient *sharedInstance = nil;
@interface FBChatVCardClient()
@end

@implementation FBChatVCardClient

- (void)dealloc {
  [_delegates release];
}

#pragma mark ----------------Singleton----------------
+ (FBChatVCardClient *)sharedInstance {
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[TBvCardClient alloc] init];
		}
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
	
	return nil;
}

- (id) init {
	self = [super init];
	if (self != nil) {		
    [[[TBServerClient sharedInstance] xmppStream] 
     addDelegate:self
     delegateQueue:dispatch_get_main_queue()];
    [[XMPPvCardCoreDataStorage sharedInstance] setSaveThreshold:1];
    _delegates = [[NSMutableArray mutableArrayUsingWeakReferences] retain];
	}
	return self;
}

#pragma mark - public
- (void)request_vCardForJID:(XMPPJID *)theJID 
{
  if ([[XMPPvCardCoreDataStorage sharedInstance]
       shouldFetchvCardTempForJID:theJID
       xmppStream:nil]) 
  {
    XMPPIQ *vCardIQ = [XMPPvCardTemp iqvCardRequestForJID:theJID];
    [[[TBServerClient sharedInstance] xmppStream] sendElement:vCardIQ];
  }
}

- (XMPPvCardTemp *)saved_vCardForJID:(XMPPJID *)theJID {
  XMPPvCardTemp *saved_vCard 
  = [[XMPPvCardCoreDataStorage sharedInstance] vCardTempForJID:theJID
                                                    xmppStream:nil];
  return saved_vCard;
}

- (void)uploadNew_vCard:(XMPPvCardTemp *)the_vCard {
  if (!the_vCard) return;
  
  DDXMLElement *vCardIQ = [DDXMLElement elementWithName:@"iq"];
  
  [vCardIQ addAttribute:[DDXMLNode attributeWithName:@"from" 
                                         stringValue:[[[TBServerClient sharedInstance]
                                                       JID] full]]];
  [vCardIQ addAttribute:[DDXMLNode attributeWithName:@"type"
                                         stringValue:@"set"]];
  
  NSString *iqID = [NSString stringWithFormat:@"%f",
                    [[NSDate date] timeIntervalSince1970]];

  [vCardIQ addAttribute:[DDXMLNode attributeWithName:@"id"
                                         stringValue:iqID]];
  [vCardIQ addChild:the_vCard];
  
  XMPPIQ *iq = [XMPPIQ iqFromElement:vCardIQ];
  
  XMPPIDTracker *idTracker = [[TBServerClient sharedInstance] IDTracker];
  [idTracker addID:[iq elementID]
            target:self
          selector:@selector(vCardUploadResultWithIQ:withInfo:)
           timeout:VCARD_UPLOAD_TIMEOUT];
  
  XMPPStream *stream = [[TBServerClient sharedInstance] xmppStream];
  [stream sendElement:iq];
}

#pragma mark - XMPPIDTracker
- (void)vCardUploadResultWithIQ:(XMPPIQ *)iq
                       withInfo:(id<XMPPTrackingInfo>)info {
  if (iq) {
    XMPPPresence *updatePresence = [XMPPPresence presence_vCardUpdateFrom:[iq to]];
    [[[TBServerClient sharedInstance] xmppStream] sendElement:updatePresence];
    
    for (id<TBvCardClientDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(vCardClient:uploaded_vCardFor:)]) {
        [delegate vCardClient:self
            uploaded_vCardFor:[iq to]];
      }
    }    
  } else {
    for (id<TBvCardClientDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(vCardClient:didFailUpload_vCardForJID:)]) {
        [delegate vCardClient:self
            didFailUpload_vCardForJID:[iq to]];
      }
    }
  }
}

#pragma mark - XMPPStreamDelegate
- (BOOL)xmppStream:(XMPPStream *)sender
      didReceiveIQ:(XMPPIQ *)iq {
  if ([[iq to] isEqualToJID:[sender myJID]] == NO) {
    return NO;
  }
  XMPPvCardTemp *vCard = [XMPPvCardTemp vCardTempCopyFromIQ:iq];
  
//#define SETUP_DEFAULT_VCARD
#ifdef SETUP_DEFAULT_VCARD
  if (vCard) {
    
    [vCard addChild:[DDXMLNode elementWithName:@"INFO"
                                   stringValue:@"this is my info and thanks for following me .  this is just for demostration to ... Some words isn't spelled weel but nether the less."]];
    [vCard addChild:[DDXMLNode elementWithName:@"X-GENDER"
                                   stringValue:@"male"]];
    [vCard addChild:[DDXMLNode elementWithName:@"FN"
                                   stringValue:@"Alexander Name"]];
    [vCard addChild:[DDXMLNode elementWithName:@"BDAY"
                                   stringValue:@"2011-8-26"]];
    [vCard addChild:[DDXMLNode elementWithName:@"NICKNAME"
                                   stringValue:@"Ultimate warrior"]];
    [vCard addChild:[DDXMLNode elementWithName:@"AVATARURL"
                                   stringValue:@"http://talkbaz.dyndns.org:8082/upload/c4/ca/1.png"]];
    XMPPIQ *update_vCard_iq = [XMPPIQ iq];
    [update_vCard_iq addAttribute:[DDXMLNode attributeWithName:@"id"
                                                   stringValue:@"v2"]];
    [update_vCard_iq addAttribute:[DDXMLNode attributeWithName:@"type"
                                                   stringValue:@"set"]];
    [update_vCard_iq addChild:vCard];
    [sender sendElement:update_vCard_iq];
  }
#endif
  
  if (vCard) {
    
    [[XMPPvCardCoreDataStorage sharedInstance]
     setvCardTemp:vCard
     forJID:[iq from]
     xmppStream:sender];

    for (id<TBvCardClientDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(vCardClient:vCardReturned:forJID:)]) {
        [delegate vCardClient:self
                vCardReturned:vCard
                       forJID:[iq from]];
      }
    }
    
    return YES;
  } else {
    return NO;
  }
}

#pragma mark - delegates
- (void)addDelegate:(id<TBvCardClientDelegate>)theDelegate {
  if ([_delegates containsObject:theDelegate] == NO) {
    [_delegates addObject:theDelegate];
  }
}

- (void)removeDelegate:(id<TBvCardClientDelegate>)theDelegate {
  [_delegates removeObject:theDelegate];
}

@end
