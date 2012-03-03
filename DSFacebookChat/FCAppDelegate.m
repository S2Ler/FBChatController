//
//  FCAppDelegate.m
//  DSFacebookChat
//
//  Created by Alexander Belyavskiy on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCAppDelegate.h"
#import "FBChatController.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "FCViewController.h"

#define APP_ID @"243173989101903"

@interface FCAppDelegate()
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, retain) FBChatController *chat;

- (void)setupChat;
@end

@implementation FCAppDelegate
@synthesize facebook = _facebook;
@synthesize chat = _chat;
@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
  [_chat release];
  [_window release];
  [_viewController release];
  [_facebook release];
  [super dealloc];
}

- (void)setupChat
{
  [self setChat:[[[FBChatController alloc] initWithAppID:APP_ID
                                           FBAccessToken:[[self facebook] accessToken] withDelegate:[self viewController]] autorelease]];
  [[self viewController] setChatController:[self chat]];
  NSError *error = [[self chat] signInWithOnChatInputDelegate:[self viewController]];
  if (error != nil) {
    DDLogError(@"%@", error);
  }  
}

- (BOOL)            application:(UIApplication *)application 
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  
  self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
  // Override point for customization after application launch.
  self.viewController = [[[FCViewController alloc] init] autorelease];
  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  
  _facebook = [[Facebook alloc] initWithAppId:APP_ID andDelegate:self];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:@"FBAccessTokenKey"] 
      && [defaults objectForKey:@"FBExpirationDateKey"]) {
    _facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
    _facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
  }
  if (![_facebook isSessionValid]) {
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"xmpp_login", 
                            nil];
    [_facebook authorize:permissions];
    [permissions release];
  }
  else {
    [self setupChat];
  }
  
  return YES;
}

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [[self facebook] handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [[self facebook] handleOpenURL:url]; 
}

- (void)fbDidLogin {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[[self facebook] accessToken] forKey:@"FBAccessTokenKey"];
  [defaults setObject:[[self facebook] expirationDate] forKey:@"FBExpirationDateKey"];
  [defaults synchronize];
  [self setupChat];
}

- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt
{
  DDLogVerbose(@"accessToke: %@, expiredAt: %@", accessToken, expiresAt);
  [self setupChat];
}

- (void)fbDidLogout
{
  
}

- (void)fbSessionInvalidated
{
  
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
  
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

@end
