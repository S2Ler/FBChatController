
#pragma mark - include
#import "FBChatVCardClient.h"
#import "XMPPvCardTemp.h"
#import "XMPPPresence+vCardUpdate.h"
#import "DDLog.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPIDTracker.h"

@interface FBChatVCardClient()
@property (nonatomic, retain) XMPPIDTracker *IDTracker;
@end

@implementation FBChatVCardClient
@synthesize IDTracker = _IDTracker;

- (void)dealloc
{
  [_IDTracker release];
  [super dealloc];
}

- (id)initWithIDTracker:(XMPPIDTracker *)theIDTracker
{
	self = [super init];
  
	if (self != nil) {		
    [[XMPPvCardCoreDataStorage sharedInstance] setSaveThreshold:1];
    _IDTracker = [theIDTracker retain];
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
    [[self xmppStream] sendElement:vCardIQ];
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
  
  [[self IDTracker] addID:[iq elementID]
                   target:self
                 selector:@selector(vCardUploadResultWithIQ:withInfo:)
                  timeout:VCARD_UPLOAD_TIMEOUT];
  
  [[self xmppStream] sendElement:iq];
}

#pragma mark - XMPPIDTracker
- (void)vCardUploadResultWithIQ:(XMPPIQ *)iq
                       withInfo:(id<XMPPTrackingInfo>)info 
{
  if (iq) {
    XMPPPresence *updatePresence = [XMPPPresence presence_vCardUpdateFrom:[iq to]];
    [[self xmppStream] sendElement:updatePresence];
    
    [multicastDelegate vCardClient:self uploaded_vCardFor:[iq to]];
  } 
  else {
    [multicastDelegate vCardClient:self
         didFailUpload_vCardForJID:[iq to]];
  }
}

#pragma mark - XMPPStreamDelegate
- (BOOL)xmppStream:(XMPPStream *)sender
      didReceiveIQ:(XMPPIQ *)iq 
{
  if ([[iq to] isEqualToJID:[sender myJID]] == NO) {
    return NO;
  }
  
  XMPPvCardTemp *vCard = [XMPPvCardTemp vCardTempCopyFromIQ:iq];
    
  if (vCard) 
  {    
    [[XMPPvCardCoreDataStorage sharedInstance] setvCardTemp:vCard
                                                     forJID:[iq from]
                                                 xmppStream:sender];

    [multicastDelegate vCardClient:self
                     vCardReturned:vCard
                            forJID:[iq from]];
    
    return YES;
  } 
  else {
    return NO;
  }
}

@end
