//
//  FCSendMessageViewController.h
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 3/3/12.
//  Copyright (c) 2012 AS IS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^message_block_t)(NSString *);

@interface FCSendMessageViewController : UIViewController
@property (retain, nonatomic) IBOutlet UITextField *messageTextView;
- (IBAction)sendMessage:(id)sender;
- (id)initWithHandler:(message_block_t)theHandler;
@end
