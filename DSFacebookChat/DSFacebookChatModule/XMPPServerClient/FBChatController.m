
#pragma mark - include
#import "FBChatController.h"
#import "FBChatMessengerModule.h"
#import "XMPPvCardTemp.h"
#import "XMPPPresence+photoHash.h"
#import "FBChatVCardClient.h"
#import "FBChatMessageType.h"
#import "XMPPReconnect.h"
#import "FBChatSession.h"
#import "XMPP.h"
#import "FBChatControllerErrors.h"
#import "XMPPIDTracker.h"
#import "DDLog.h"
#import "FBChatRosterClient.h"
#import "XMPPRosterMemoryStorage.h"
#import "TestFlight.h"

#pragma mark - props
@interface FBChatController()

@property (retain) NSMutableArray *modules;
@property (retain) XMPPStream *xmppStream;
@property (retain) XMPPIDTracker *IDTracker;
@property (nonatomic, retain) NSString *FBAppID;
@property (nonatomic, retain) NSString *FBAccessToken;
@property (assign) id<FBChatControllerDelegate> delegate;
@property (assign) id<FBChatControllerMessengerDelegate> messengerDelegate;
@property (retain) XMPPJID *JID;
@property (retain) FBChatRosterClient *roster;
@property (retain) FBChatMessengerModule *chat;
@property (retain) FBChatVCardClient *vCardClient;

- (void)setupXMPPStream;
- (void)goOnline;
- (void)goOffline;

@end

@implementation FBChatController
@synthesize vCardClient = _vCardClient;
@synthesize modules = _modules;
@synthesize FBAccessToken = _FBAccessToken;
@synthesize xmppStream = _xmppStream;
@synthesize JID = _JID;
@synthesize delegate = _delegate;
@synthesize IDTracker = _IDTracker;
@synthesize FBAppID = _FBAppID;
@synthesize messengerDelegate = _messengerDelegate;
@synthesize roster = _roster;
@synthesize chat = _chat;

- (void)dealloc {
  [_chat release];
  [_vCardClient release];  
  [_roster release];
  [_FBAccessToken release];
  [_FBAppID release];
  [_IDTracker release];
  [_xmppStream release];
  [_JID release];
  [_modules release];
  
  [super dealloc];
}

- (id)initWithAppID:(NSString *)theAppID              
      FBAccessToken:(NSString *)theFBAccessToken
       withDelegate:(id<FBChatControllerDelegate>)theDelegate
{  
  self = [super init];
	if (self != nil) {		
    _IDTracker 
    = [[XMPPIDTracker alloc] initWithDispatchQueue:dispatch_get_main_queue()];    
    _modules = [[NSMutableArray alloc] init];                 
    _FBAppID = [theAppID copy];
    _FBAccessToken = [theFBAccessToken copy];
    _delegate = theDelegate;
	}
	return self;
}

#pragma mark - public
- (NSError *)signInWithOnChatInputDelegate:(id<FBChatControllerMessengerDelegate>)theDelegate
{
  [TestFlight passCheckpoint:@"Sign In"];
  
  [self setMessengerDelegate:theDelegate];
  [self setupXMPPStream];
  
  if (![[self xmppStream] isDisconnected]) {
    return nil;
  }
  
  NSError *error = nil;  
  if (![[self xmppStream] connect:&error]) {
    return error;
  }
  
  return nil;
}

- (void)signOut 
{
  [TestFlight passCheckpoint:@"Sign Out"];
  DDLogInfo(@"Disconnecting from server");
  [self goOffline];
  [[self xmppStream] disconnect];
}

- (void)goOnline {
  DDLogInfo(@"Sending available presense");
  XMPPPresence *availablePresense = [XMPPPresence presence];
  
  [[self xmppStream] sendElement:availablePresense];  
}

- (void)goOffline {
  DDLogInfo(@"Sending unavailable presense");
  XMPPPresence *unavailablePresense = [XMPPPresence presenceWithType:@"unavailable"];
  
  [[self xmppStream] sendElement:unavailablePresense];  
}

- (NSArray *)whoIsAvailable
{
#warning returns all users, but show only available users
  return [[self roster] sortedUsersByAvailabilityName];
}

- (void)sendMessage:(NSString*)msg to:(XMPPJID *)theRecipient
{
  [TestFlight passCheckpoint:@"Send Message"];

  [[[self chat] chatWithJID:theRecipient] sendMessage:msg 
                                                 type:messageTypes.standard];
}

- (void)requestVCardForUser:(XMPPJID *)theJID
{
  [[self vCardClient] request_vCardForJID:theJID];    
}

- (XMPPvCardTemp *)vCardForUser:(XMPPJID *)theUser
{
  return [[self vCardClient] saved_vCardForJID:theUser];
}

#pragma mark - initialization of XMPP Stream

- (void)setupRoster
{
  XMPPRosterMemoryStorage *memoryStorage 
  = [[[XMPPRosterMemoryStorage alloc] init] autorelease];
  
  [self setRoster:   
   [[[FBChatRosterClient alloc] initWithRosterStorage:memoryStorage] autorelease]];
  [[self roster] addDelegate:self
               delegateQueue:dispatch_get_main_queue()];    
  
  [[self roster] activate:[self xmppStream]];
  [[self xmppStream] registerModule:[self roster]];  
}

- (void)setupChatMessenger
{
  [self setChat:[[[FBChatMessengerModule alloc] initWithDispatchQueue:nil] autorelease]];
  [[self chat] addDelegate:self delegateQueue:dispatch_get_main_queue()];
  [[self chat] activate:[self xmppStream]];
  [[self xmppStream] registerModule:[self chat]];
}

- (void)setupAutoreconnect
{
  XMPPReconnect *reconnector = [[[XMPPReconnect alloc] init] autorelease];
  [reconnector setAutoReconnect:YES];
  [reconnector setReconnectDelay:1.0];

  [reconnector activate:[self xmppStream]];
  [[self xmppStream] registerModule:reconnector];
}

- (void)setupVCardClient
{
  FBChatVCardClient *vCardClient 
  = [[FBChatVCardClient alloc] initWithIDTracker:[self IDTracker]];
  [vCardClient addDelegate:self delegateQueue:dispatch_get_main_queue()];
  [vCardClient activate:[self xmppStream]];
  [[self xmppStream] registerModule:vCardClient];  
  [self setVCardClient:[vCardClient autorelease]];
}

- (void)setupXMPPStream {
  XMPPStream *stream
  = [[[XMPPStream alloc] initWithFacebookAppId:[self FBAppID]] autorelease];  
  [stream setKeepAliveInterval:20];
  [self setXmppStream:stream];
  
  [stream addDelegate:self
        delegateQueue:dispatch_get_main_queue()];

  [self setupRoster];
  [self setupChatMessenger];
  [self setupAutoreconnect];
  [self setupVCardClient];
  /** NOTE: TBPresenseModule have to initialized after TBPubSubModule as it uses it */
//  [TBPubSubModule activateSharedInstanceWithStream:stream
//                                        serviceJID:[self JID]];
//  [TBPresenseModule activateSharedInstanceWithStream:stream];

//  [[TBRosterClient sharedInstance] setAutoRoster:YES];
//  [[TBSearchModule sharedInstance] registerWithStream:stream];//TODO: refactor as TBRosterClient
  
  [stream release];
}

#pragma mark - XMPPStreamDelegate
- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream 
{
  [TestFlight passCheckpoint:@"XMPP Stream Did Connect"];

  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
  if (![xmppStream isSecure]) {
    NSError *error = nil;
    BOOL result = [xmppStream secureConnection:&error];
    
    if (result == NO) {
      DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
    }
  } 
  else {
    NSError *error = nil;
    BOOL result = [xmppStream authenticateWithFacebookAccessToken:[self FBAccessToken]
                                                            error:&error];
//    BOOL result = [xmppStream authenticateWithFacebookAccessToken:@"123"
//                                                            error:&error];
    
    if (result == NO) {
      DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
    }
  }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender 
                      withError:(NSError *)error 
{
 
  [TestFlight passCheckpoint:@"XMPP Stream Did Disconnect"];

  if ([[self delegate] 
       respondsToSelector:@selector(chatController:didAuthenticateSuccessfully:error:)]) 
  {
    [[self delegate] chatController:self 
            didAuthenticateSuccessfully:YES
                                  error:error];
  }

  DDLogError(@"Disconnecting from server with error: {%@}", error);             
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender 
{
  [TestFlight passCheckpoint:@"XMPP Stream Did Auth"];

  [self goOnline];
  
  if ([[self delegate] 
       respondsToSelector:@selector(chatController:didAuthenticateSuccessfully:error:)]) 
  {
    [[self delegate] chatController:self 
          didAuthenticateSuccessfully:YES
                                error:nil];
  }
}

- (void)  xmppStream:(XMPPStream *)sender 
  didNotAuthenticate:(DDXMLElement *)error 
{
  [TestFlight passCheckpoint:@"XMPP Stream Did Not Auth"];

  DDLogError(@"Authecation failed: {%@}", error);
    
  if ([[self delegate]
       respondsToSelector:@selector(chatController:didAuthenticateSuccessfully:error:)]) 
  {
    NSError *error = [NSError errorWithDomain:FBChatControllerErrorDomain
                                         code:FBChatControllerNotAuthorizedCode
                                     userInfo:nil];
    [[self delegate] chatController:self 
          didAuthenticateSuccessfully:NO
                                error:error];
  }
}

- (void)  xmppStream:(XMPPStream *)sender 
  didReceivePresence:(XMPPPresence *)presence 
{
  NSString *presenceType = [presence type];
  NSString *presenceFromUser = [[presence from] user];

  DDLogInfo(@"Receive Presense: type: {%@}, from user: {%@}", 
            presenceType, presenceFromUser);
  
  NSString *presensePhotoHash = [presence photoHash];
  NSString *savedPhotoHash = [[self vCardClient] 
                              photoHashForForJID:[presence from]];
  if ([presensePhotoHash isEqualToString:savedPhotoHash] == NO)
  {
    [self requestVCardForUser:[presence from]];
  }

  if ([[self delegate]
       respondsToSelector:@selector(serverClient:didReceivePresense:fromUser:)]) 
  {
    [[self delegate] serverClient:self
               didReceivePresense:presenceType
                         fromUser:presenceFromUser];
  }
}

- (BOOL)xmppStream:(XMPPStream *)stream 
      didReceiveIQ:(XMPPIQ *)iq
{
  NSString *type = [iq type];
  
  if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"]) {
    return [_IDTracker invokeForID:[iq elementID]
                        withObject:iq];
  }
  else {
    return NO;
  }
}

#pragma mark - XMPPRosterDelegate
- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  if ([[self delegate] 
       respondsToSelector:@selector(chatControllerRosterChanged:)] == YES) 
  {
    [[self delegate] chatControllerRosterChanged:self];
  }
}

#pragma mark - FBChatMessenger
- (void)delegateMessage:(XMPPMessage *)theMessage
{
  if ([[self messengerDelegate] 
       respondsToSelector:@selector(chatController:didReceiveNewMessage:)] == YES)
  {
    [[self messengerDelegate] chatController:self
                        didReceiveNewMessage:theMessage];
  }
}

- (void)messengerModule:(FBChatMessengerModule *)theMessenger
       didCreateNewChat:(FBChatSession *)theChat
{
  [TestFlight passCheckpoint:@"Chat Created"];

  [theChat addDelegate:self
         delegateQueue:dispatch_get_main_queue()];
  [self delegateMessage:[[theChat history] lastObject]];
}

- (void)      chat:(FBChatSession *)theChat
 didRecieveMessage:(XMPPMessage *)theMessage
{
  [TestFlight passCheckpoint:@"Message received"];

  [self delegateMessage:theMessage];
}

- (void)   chat:(FBChatSession *)theChat
 didSendMessage:(XMPPMessage *)theMessage
{
  [TestFlight passCheckpoint:@"Message Sent"];

  [self delegateMessage:theMessage];
}

#pragma mark - VCardDelegate
- (void)vCardClient:(FBChatVCardClient *)the_vCardClient
      vCardReturned:(XMPPvCardTemp *)the_vCard
             forJID:(XMPPJID *)theJID
{
  if ([[self delegate] respondsToSelector:
       @selector(chatcontroller:didGetVCard:forJID:)] == YES)
  {
    [[self delegate] chatcontroller:self didGetVCard:the_vCard forJID:theJID];
  }
}

- (void)vCardClient:(FBChatVCardClient *)the_vCardClient 
uploaded_vCardFor:(XMPPJID *)theUpload_vCardJID
{
  
}

- (void)vCardClient:(FBChatVCardClient *)the_vCardClient
didFailUpload_vCardForJID:(XMPPJID *)theJID
{
  
}

@end
