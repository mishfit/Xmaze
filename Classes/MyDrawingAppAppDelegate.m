//
//  MyDrawingAppAppDelegate.m
//  MyDrawingApp
//
//  Created by joel johnson on 6/28/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MyDrawingAppAppDelegate.h"
#import "MyDrawingAppViewController.h"

@implementation MyDrawingAppAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
    [self.window setRootViewController:viewController];
    [window makeKeyAndVisible];

	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
