
#import <Foundation/Foundation.h>
#import "XMPPRoster.h"

@interface FBChatRosterClient : XMPPRoster
<
XMPPRosterDelegate
>

- (NSArray *)sortedAllUsersByAvailabilityName;
- (NSArray *)sortedUsersByAvailabilityName;
- (NSArray *)sortedServicesByAvailabilityName;
- (NSArray *)sortedServicesJIDsByAvailabilityName;

#pragma mark - delegates methods
/*
 - (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence;
 
 //For in memory storage
 - (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender;
*/


@end

