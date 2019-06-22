//
//  TOAlertDimmingView.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 31/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertDimmingView.h"

@interface TOAlertDimmingView()

@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIViewPropertyAnimator *animator;

@end

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
    //self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
    self.blurView.frame = self.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.blurView];

    self.animator = [[UIViewPropertyAnimator alloc] initWithDuration:2.0f curve:UIViewAnimationCurveLinear animations:^{
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview == nil) { return; }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.animator startAnimation];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.66f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.animator pauseAnimation];
        });
    });
}

//- (void)pauseBlurEffectAfterDelay:(CGFloat)delay
//{
//    NSTimeInterval time = delay + CFAbsoluteTimeGetCurrent();
//    CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, time, 0, 0, 0, ^(CFRunLoopTimerRef timer) {
//        CALayer *blurLayer = self.blurView.layer;
//        CFTimeInterval pausedTime = [blurLayer convertTime:CACurrentMediaTime() fromLayer:nil];
//        blurLayer.speed = 0.0f;
//        blurLayer.timeOffset = pausedTime;
//    });
//
//    CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes);
//}

@end
