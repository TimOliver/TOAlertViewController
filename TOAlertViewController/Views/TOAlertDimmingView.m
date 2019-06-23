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
    self.backgroundColor = [UIColor clearColor];

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
    self.blurView.frame = self.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.blurView];
}

- (void)playFadeInAnimationWithDuration:(NSTimeInterval)duration
{
    // Animate the dimming view
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    }];

    // Reset if need be
    if (self.animator) {
        [self.animator stopAnimation:YES];
        self.animator = nil;
        self.blurView.effect = nil;
    }

    // Animate the blur view
    self.animator = [[UIViewPropertyAnimator alloc] initWithDuration:(duration/0.15f)*0.5f curve:UIViewAnimationCurveEaseOut animations:^{
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }];
    [self.animator startAnimation];

    // Pause the animation after the duration
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration*0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.animator pauseAnimation];
    });
}

- (void)playFadeOutAnimationWithDuration:(NSTimeInterval)duration
{
    // Animate the dimming view
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor clearColor];
    }];

    // Get the fraction of the animation, and flip it so we can reverse
    CGFloat fraction = 1.0f - self.animator.fractionComplete;
    [self.animator stopAnimation:YES];
    self.animator = nil;

    // Flip the animation
    self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.animator = [[UIViewPropertyAnimator alloc] initWithDuration:duration curve:UIViewAnimationCurveLinear animations:^{
        self.blurView.effect = nil;
    }];

    self.animator.fractionComplete = fraction;
    [self.animator startAnimation];
}

@end
