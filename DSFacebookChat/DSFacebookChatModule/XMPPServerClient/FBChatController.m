
#pragma mark - include
#import "FBChatController.h"
#import "FBChatMessengerModule.h"
#import "XMPP.h"
#import "XMPPIDTracker.h"
#import "DDLog.h"

static FBChatController *sharedInstance = nil;

#pragma mark - props
@interface FBChatController(){
  XMPPStream *_xmppStream;
  XMPPIDTracker *_IDTracker;
  
  XMPPJID *_JID;
  NSString *_password;
  NSString *_host;
  NSString *_hostPort;
  
  id<FBChatControllerDelegate> _delegate;
  
  NSMutableArray *_modules;
}

@property (retain) XMPPStream *xmppStream;
@property (retain) XMPPIDTracker *IDTracker;
@property (nonatomic, retain) NSString *FBAppID;
@property (nonatomic, retain) NSString *FBAccessToken;
@end

#pragma mark - private
@interface FBChatController(Private)
- (void)setupXMPPStream;
@end


@implementation FBChatController
@synthesize FBAccessToken = _FBAccessToken;
@synthesize xmppStream = _xmppStream;
@synthesize JID = _JID;
@synthesize password = _password;
@synthesize delegate = _delegate;
@synthesize host = _host;
@synthesize hostPort = _hostPort;
@synthesize IDTracker = _IDTracker;
@synthesize FBAppID = _FBAppID;

- (void)dealloc {
  [_FBAccessToken release];
  [_FBAppID release];
  [_IDTracker release];
  [_xmppStream release];
  [_JID release];
  [_password release];
  [_host release];
  [_hostPort release];
  [_modules release];
  
  [super dealloc];
}

#pragma mark ----------------Singleton----------------
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
	
	return nil;
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
- (NSError *)connect {
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

- (void)disconnect {
  DDLogInfo(@"Disconnecting from server");
  [self goOffline];
  [[self xmppStream] disconnect];
}

- (void)goOnline {
  DDLogInfo(@"Sending available presense");
  
//  [[TBPresenseModule sharedInstance] sendSavedPresense];
}

- (void)goOffline {
  DDLogInfo(@"Sending unavailable presense");
  XMPPPresence *unavailablePresense = [XMPPPresence presenceWithType:@"unavailable"];
  
  [[self xmppStream] sendElement:unavailablePresense];  
}

- (void)beginSendingGeolocInfo {      
//  [[TBGeolocModule sharedInstance] sendNewLocation];
  static dispatch_queue_t q = NULL;
  
  if (q == NULL) {
    q = dispatch_queue_create("com.fbchatcontroller.location.update",
                              NULL);
  }
  
  dispatch_async(q, ^{
    [NSThread sleepForTimeInterval:20];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      [self beginSendingGeolocInfo];
    });
  });
}

#pragma mark - initialization of XMPP Stream
- (void)setupXMPPStream {
  XMPPStream *stream = [[XMPPStream alloc] initWithFacebookAppId:[self FBAppID]];
  [stream addDelegate:self
        delegateQueue:dispatch_get_main_queue()];

//  [TBRosterClient activateSharedInstanceWithStream:stream];
//  [TBGeolocModule activateSharedInstanceWithStream:stream];
//  [TBMapModule activateSharedInstanceWithStream:stream];
  [FBChatMessengerModule activateSharedInstanceWithStream:stream];
//  [TBAddonModule activateSharedInstanceWithStream:stream];
  
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
- (void)xmppStreamDidConnect:(XMPPStream *)xmppStream {
  DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
  if (![xmppStream isSecure])
  {
    NSError *error = nil;
    BOOL result = [xmppStream secureConnection:&error];
    
    if (result == NO)
    {
      DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
    }
  } 
  else 
  {
    NSError *error = nil;
    BOOL result = [xmppStream authenticateWithFacebookAccessToken:[self FBAccessToken]
                                                            error:&error];
    
    if (result == NO)
    {
      DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
    }
  }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender 
                      withError:(NSError *)error {
  DDLogError(@"Disconnecting from server with error: {%@}", error);             
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
  [self goOnline];
  
  if ([[self delegate] respondsToSelector:@selector(serverClient:didAuthenticateSuccessfully:)]) {
    [[self delegate] serverClient:self
      didAuthenticateSuccessfully:YES];
  }
}

- (void)xmppStream:(XMPPStream *)sender 
didNotAuthenticate:(DDXMLElement *)error {
  DDLogError(@"Authecation failed: {%@}", error);
  
  if ([[self delegate] respondsToSelector:@selector(serverClient:didAuthenticateSuccessfully:)]) {
    [[self delegate] serverClient:self
      didAuthenticateSuccessfully:NO];
  }
}

- (void)xmppStream:(XMPPStream *)sender 
didReceivePresence:(XMPPPresence *)presence {
  NSString *presenceType = [presence type];
//  NSString *username = [[sender myJID] user];
  NSString *presenceFromUser = [[presence from] user];
  
  DDLogInfo(@"Receive Presense: type: {%@}, from user: {%@}", 
            presenceType, presenceFromUser);

  if ([_delegate respondsToSelector:@selector(serverClient:didReceivePresense:fromUser:)]) {
    [_delegate serverClient:self
         didReceivePresense:presenceType
                   fromUser:presenceFromUser];
  }
}

- (BOOL)xmppStream:(XMPPStream *)stream 
      didReceiveIQ:(XMPPIQ *)iq
{
  NSString *type = [iq type];
  
  if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"])
  {
    return [_IDTracker invokeForID:[iq elementID]
                        withObject:iq];
  }
  else
  {
    return NO;
  }
}

@end
