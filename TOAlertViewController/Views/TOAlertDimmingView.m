//
//  TOAlertDimmingView.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
