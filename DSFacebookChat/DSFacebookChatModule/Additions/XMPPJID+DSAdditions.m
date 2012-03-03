
#import "XMPPJID+DSAdditions.h"

@implementation XMPPJID (DSAdditions)
- (BOOL)isEqualBareToJID:(XMPPJID *)theJID {
  if (theJID == nil) return NO;
	
	if (user) {
		if (![user isEqualToString:theJID->user]) return NO;
	}
	else {
		if (theJID->user) return NO;
	}
	
	if (domain) {
		if (![domain isEqualToString:theJID->domain]) return NO;
	}
	else {
		if (theJID->domain) return NO;
	}
  
  return YES;
}
@end
