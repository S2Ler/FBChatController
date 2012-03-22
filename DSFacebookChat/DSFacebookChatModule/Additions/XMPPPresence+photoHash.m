//
//  XMPPPresence+photoHash.m
//  DSFacebookChat
//
//  Created by S2Ler on 3/17/12.
//  Copyright (c) 2012 AS IS. All rights reserved.
//

#import "XMPPPresence+photoHash.h"
#import "NSXMLElement+XMPP.h"

@implementation XMPPPresence (photoHash)
- (NSString *)photoHash
{
  return [[[self elementForName:@"x"] elementForName:@"photo"] stringValue];
}
@end
