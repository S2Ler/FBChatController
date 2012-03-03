
#pragma mark - include
#import "FBChatController.h"
#import "FBChatMessengerModule.h"
#import "XMPP.h"
#import "FBChatControllerErrors.h"
#import "XMPPIDTracker.h"
#import "DDLog.h"

#pragma mark - props
@interface FBChatController()

@property (retain) NSMutableArray *modules;
@property (retain) XMPPStream *xmppStream;
@property (retain) XMPPIDTracker *IDTracker;
@property (nonatomic, retain) NSString *FBAppID;
@property (nonatomic, retain) NSString *FBAccessToken;
@property (assign) id<FBChatControllerDelegate> authDelegate;
@property (assign) id<FBChatControllerMessengerDelegate> messengerDelegate;
@property (retain) XMPPJID *JID;

- (void)setupXMPPStream;
- (void)goOnline;
- (void)goOffline;

@end

@implementation FBChatController
@synthesize modules = _modules;
@synthesize FBAccessToken = _FBAccessToken;
@synthesize xmppStream = _xmppStream;
@synthesize JID = _JID;
@synthesize authDelegate = _delegate;
@synthesize IDTracker = _IDTracker;
@synthesize FBAppID = _FBAppID;
@synthesize messengerDelegate = _messengerDelegate;

- (void)dealloc {
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
	}
	return self;
}

#pragma mark - public
- (NSError *)signInWithOnChatInputDelegate:(id<FBChatControllerMessengerDelegate>)theDelegate
{
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
  DDLogInfo(@"Disconnecting from server");
  [self goOffline];
  [[self xmppStream] disconnect];
}

- (void)goOnline {
//  [[TBPresenseModule sharedInstance] sendSavedPresense];
}

- (void)goOffline {
  DDLogInfo(@"Sending unavailable presense");
  XMPPPresence *unavailablePresense = [XMPPPresence presenceWithType:@"unavailable"];
  
  [[self xmppStream] sendElement:unavailablePresense];  
}

#pragma mark - initialization of XMPP Stream
- (void)setupXMPPStream {
  XMPPStream *stream = [[XMPPStream alloc] initWithFacebookAppId:[self FBAppID]];
  [stream addDelegate:self
        delegateQueue:dispatch_get_main_queue()];

//  [TBRosterClient activateSharedInstanceWithStream:stream];
  [FBChatMessengerModule activateSharedInstanceWithStream:stream];
  
  /** NOTE: TBPresenseModule have to initialized after TBPubSubModule as it uses it */
//  [TBPubSubModule activateSharedInstanceWithStream:stream
//                                        serviceJID:[self JID]];
//  [TBPresenseModule activateSharedInstanceWithStream:stream];

//  [[TBRosterClient sharedInstance] setAutoRoster:YES];
//  [[TBSearchModule sharedInstance] registerWithStream:stream];//TODO: refactor as TBRosterClient
  
  [self setXmppStream:stream];
  [stream release];
}

#pragma mark - XMPPStreamDelegate
- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream 
{
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
//    BOOL result = [xmppStream authenticateWithFacebookAccessToken:[self FBAccessToken]
//                                                            error:&error];
    BOOL result = [xmppStream authenticateWithFacebookAccessToken:@"123"
                                                            error:&error];
    
    if (result == NO) {
      DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
    }
  }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender 
                      withError:(NSError *)error 
{
  DDLogError(@"Disconnecting from server with error: {%@}", error);             
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender 
{
  [self goOnline];
  
  if ([[self authDelegate] 
       respondsToSelector:@selector(serverClient:didAuthenticateSuccessfully:error:)]) 
  {
    [[self authDelegate] serverClient:self 
          didAuthenticateSuccessfully:YES
                                error:nil];
  }
}

- (void)  xmppStream:(XMPPStream *)sender 
  didNotAuthenticate:(DDXMLElement *)error 
{
  DDLogError(@"Authecation failed: {%@}", error);
    
  if ([[self authDelegate]
       respondsToSelector:@selector(serverClient:didAuthenticateSuccessfully:error:)]) 
  {
    NSError *error = [NSError errorWithDomain:FBChatControllerErrorDomain
                                         code:FBChatControllerNotAuthorizedCode
                                     userInfo:nil];
    [[self authDelegate] serverClient:self 
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

  if ([_delegate
       respondsToSelector:@selector(serverClient:didReceivePresense:fromUser:)]) 
  {
    [_delegate serverClient:self
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

@end
