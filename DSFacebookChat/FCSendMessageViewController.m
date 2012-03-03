//
//  FCSendMessageViewController.m
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 3/3/12.
//  Copyright (c) 2012 AS IS. All rights reserved.
//

#import "FCSendMessageViewController.h"

@interface FCSendMessageViewController ()
@property (nonatomic, copy) message_block_t handler;
@end

@implementation FCSendMessageViewController
@synthesize messageTextView;
@synthesize handler = _handler;

- (id)initWithHandler:(message_block_t)theHandler
{
  self = [super init];
  if (self) {
    _handler = [theHandler copy];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
  [self setMessageTextView:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)sendMessage:(id)sender {
  if ([self handler] != NULL) {
    [self handler]([[self messageTextView] text]);
  }
}

- (void)dealloc {
  [messageTextView release];
  [_handler release];   
  [super dealloc];
}
@end
