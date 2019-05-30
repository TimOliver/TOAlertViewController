//
//  TOAlertDimmingView.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 31/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertDimmingView.h"

@implementation TOAlertDimmingView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor blackColor];
    self.alpha = 0.4f;
}

@end
