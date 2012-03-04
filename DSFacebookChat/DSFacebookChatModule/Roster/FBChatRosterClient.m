
#import "FBChatRosterClient.h"
#import "XMPPRoster.h"
#import "XMPPRosterMemoryStorage.h"
#import "XMPPStream.h"
#import "DDLog.h"
#import "XMPPUser.h"

#pragma mark - props
@interface FBChatRosterClient()
@property (nonatomic, retain) XMPPRoster *rosterModule;
@end

@implementation FBChatRosterClient
@synthesize rosterModule = _rosterModule;

- (void)dealloc {
  [_rosterModule release];

  [super dealloc];
}

- (NSArray *)sortedAllUsersByAvailabilityName
{
  if ([[self xmppRosterStorage] isKindOfClass:[XMPPRosterMemoryStorage class]]) {
    XMPPRosterMemoryStorage *storage = (id)[self xmppRosterStorage];
    return [storage sortedUsersByAvailabilityName];
  } else {
    DDLogError(@"Isn't supported yet");
    abort();
  }  
}

- (NSArray *)sortedUsersByAvailabilityName 
{
  NSArray *allUsers = [self sortedAllUsersByAvailabilityName];
  
  NSMutableArray *users = [NSMutableArray array];
  
  for (id<XMPPUser> anyUser in allUsers) {
    if ([[anyUser jid] isFullWithUser] == YES ||
        [[anyUser jid] isBareWithUser] == YES) {
      [users addObject:anyUser];
    }
  }
  
  return users;  
}

- (NSArray *)sortedServicesJIDsByAvailabilityName
{
  NSArray *allUsers = [self sortedAllUsersByAvailabilityName];
  
  NSMutableArray *servicesJIDs = [NSMutableArray array];
  
  for (id<XMPPUser> user in allUsers) {
    XMPPJID *jid = [user jid];
    
    if ([jid isBareWithUser] == NO) {
      [servicesJIDs addObject:[[jid copy] autorelease]];       
    }
  }
  
  return servicesJIDs;
}

- (NSArray *)sortedServicesByAvailabilityName
{
  NSArray *allUsers = [self sortedAllUsersByAvailabilityName];
  
  NSMutableArray *services = [NSMutableArray array];
  
  for (id<XMPPUser> anyUser in allUsers) {
    if ([[anyUser jid] isFullWithUser] == NO &&
        [[anyUser jid] isBareWithUser] == NO) {
      [services addObject:anyUser];
    }
  }
  
  return services; 
}

@end
