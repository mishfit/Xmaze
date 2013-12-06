//
//  MyDrawingAppAppDelegate.h
//  MyDrawingApp
//
//  Created by joel johnson on 6/28/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyDrawingAppViewController;

@interface MyDrawingAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MyDrawingAppViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MyDrawingAppViewController *viewController;

@end

