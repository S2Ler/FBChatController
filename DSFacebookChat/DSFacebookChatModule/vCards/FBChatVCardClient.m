
#pragma mark - include
#import "FBChatVCardClient.h"
#import "XMPPvCardTemp.h"
#import "XMPPPresence+vCardUpdate.h"
#import "DDLog.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPIDTracker.h"

@interface FBChatVCardClient()
@property (nonatomic, retain) XMPPIDTracker *IDTracker;
@property (nonatomic, retain) NSOperationQueue *vCardRequests;

@end

@implementation FBChatVCardClient
@synthesize IDTracker = _IDTracker;
@synthesize vCardRequests = _vCardRequests;

- (void)dealloc
{
  [_IDTracker release];
  [_vCardRequests release];
  [super dealloc];
}

- (NSString *)moduleName {
  return NSStringFromClass([self class]);
}

- (id)initWithIDTracker:(XMPPIDTracker *)theIDTracker
{
	self = [super init];
  
	if (self != nil) {		
    [[XMPPvCardCoreDataStorage sharedInstance] setSaveThreshold:200];

    _IDTracker = [theIDTracker retain];
    _vCardRequests = [[NSOperationQueue alloc] init];
    [_vCardRequests setSuspended:NO];
    [_vCardRequests setMaxConcurrentOperationCount:1];
	}
  
	return self;
}

#pragma mark - public
- (void)request_vCardForJID:(XMPPJID *)theJID 
{
  __block id weakXMPPStream = [self xmppStream];
  
  [[self vCardRequests] addOperationWithBlock:^{    
    if ([[XMPPvCardCoreDataStorage sharedInstance]
         shouldFetchvCardTempForJID:theJID
         xmppStream:nil]) 
    {
      XMPPIQ *vCardIQ = [XMPPvCardTemp iqvCardRequestForJID:theJID];
      
      [weakXMPPStream sendElement:vCardIQ];            
    }
  }];
}

+ (XMPPvCardTemp *)saved_vCardForJID:(XMPPJID *)theJID {
  XMPPvCardTemp *saved_vCard 
  = [[XMPPvCardCoreDataStorage sharedInstance] vCardTempForJID:theJID
                                                    xmppStream:nil];
  return saved_vCard;
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
