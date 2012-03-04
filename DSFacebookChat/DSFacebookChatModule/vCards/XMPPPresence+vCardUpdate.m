
#import "XMPPPresence+vCardUpdate.h"
#import "XMPPJID.h"


@implementation XMPPPresence (XMPPPresense_vCardUpdate)
+ (id)presence_vCardUpdateFrom:(XMPPJID *)theFrom {
  XMPPPresence *presence = [XMPPPresence presence];
  
  [presence addAttribute:[DDXMLElement attributeWithName:@"from"
                                             stringValue:[theFrom full]]];
                                                            
  XMPPElement *update_xForm = [XMPPElement elementWithName:@"x"];
  [update_xForm addAttribute:
   [DDXMLNode attributeWithName:@"xmlns"
                    stringValue:@"vcard-temp:x:update"]];
  
  [presence addChild:update_xForm];
  return presence;
}
@end
