//
//  TOAlertDimmingView.m
//
//  Copyright 2019-2026 Timothy Oliver. All rights reserved.
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
#import "TOAlertBlurView.h"

// The resting gaussian blur radius (in points) shown behind the alert.
// Kept deliberately subtle to produce a 'depth-of-field' effect rather than
// fully obscuring the content. Tune to taste.
static const CGFloat kTOAlertDimmingBlurRadius = 14.0f;

@interface TOAlertDimmingView ()

// A blur view that darkens and softens the content behind the alert.
@property (nonatomic, strong) TOAlertBlurView *blurView;

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

    self.blurView = [[TOAlertBlurView alloc] initWithFrame:self.bounds];
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.blurView];
}

#pragma mark - Public Animations -

- (void)playFadeInAnimationWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    }];

    [self.blurView setBlurRadius:kTOAlertDimmingBlurRadius animated:YES duration:duration];
}

- (void)playFadeOutAnimationWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor clearColor];
    }];

    [self.blurView setBlurRadius:0.0f animated:YES duration:duration];
}

@end
