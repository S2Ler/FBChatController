
#import <Foundation/Foundation.h>
#import "XMPPPresence.h"

@class XMPPJID;

@interface XMPPPresence (XMPPPresense_vCardUpdate)
+ (id)presence_vCardUpdateFrom:(XMPPJID *)theFrom;
@end
