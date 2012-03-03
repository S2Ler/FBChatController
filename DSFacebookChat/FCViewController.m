//
//  FCViewController.m
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCViewController.h"
#import "FBChatController.h"
#import "XMPPUser.h"
#import "XMPPMessage+Chat.h"

@interface FCViewController ()
@property (nonatomic, retain) NSArray *availableUsers;
@end

@implementation FCViewController
@synthesize tableView = _tableView;
@synthesize chatController = _chatController;
@synthesize availableUsers = _availableUsers;

- (id)init
{
  self = [super init];
  if (self) {

  }
  return self;
}

- (void)chatController:(FBChatController *)theClient 
didAuthenticateSuccessfully:(BOOL)theSuccessFlag
               error:(NSError *)theError
{  
  if (theSuccessFlag == NO) {
    UIAlertView *alert 
    = [[UIAlertView alloc] 
       initWithTitle:[NSString stringWithFormat:@"Error Domain: %@", [theError domain]]
       message:[NSString stringWithFormat:@"Error Code: %d", [theError code]]                                                          
       delegate:nil 
       cancelButtonTitle:@"OK"
       otherButtonTitles:nil];
    [alert show];   
    [alert release];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
  [_tableView release];
  [super dealloc];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  NSInteger rows = [[self availableUsers] count];
  
  return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CELL_ID = @"CELL_ID";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID];
  
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:CELL_ID] autorelease];    
  }
  
  id<XMPPUser> user = [[self availableUsers] objectAtIndex:[indexPath row]];
  [[cell textLabel] setText:[user nickname]];

  if ([user isOnline]) {
    [[cell contentView] setBackgroundColor:[UIColor greenColor]];
  }
  else {
    [[cell contentView] setBackgroundColor:[UIColor redColor]];
  }
  
  return cell;
}

#pragma mark - FBChatController
- (void)chatControllerRosterChanged:(FBChatController *)theClient
{
  NSArray *availableUsers = [theClient whoIsAvailable];
  DDLogVerbose(@"%@", availableUsers);
  
  [self setAvailableUsers:availableUsers];
  [[self tableView] reloadData];
}
@end
