//
//  MyDrawingView.h
//  MyDrawingApp
//
//  Created by joel johnson on 6/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MyDrawingView : UIView {
	UIColor* currentColor;
	UIColor* fillColor;
    NSTimer *  randomMain;
}

@property (strong) UIColor* currentColor;
@property (strong) UIColor* fillColor;
@end
