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
#import "TOAlertMacros.h"

@import BlurUIKit;

// The resting gaussian blur radius (in points) shown behind the alert.
// Kept deliberately subtle to produce a 'depth-of-field' effect rather than
// fully obscuring the content. Tune to taste.
static const CGFloat kTOAlertDimmingBlurRadius = 4.0f;

@interface TOAlertDimmingView ()

// The visual effect view whose blur radius BlurUIKit drives.
@property (nonatomic, strong) UIVisualEffectView *effectView;

// Whether BlurUIKit can adjust the effect's radius (vs. falling back to a material cross-fade).
@property (nonatomic, assign) BOOL supportsBlurRadius;

- (void)_commonInit TOALERT_OBJC_DIRECT;
- (void)_setBlurVisible:(BOOL)visible TOALERT_OBJC_DIRECT;

@end

@implementation TOAlertDimmingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) { [self _commonInit]; }

    return self;
}

- (void)_commonInit {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor clearColor];

    self.effectView =
        [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.effectView.frame = self.bounds;
    self.effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.effectView];

    // BlurUIKit reports UIKit's default radius until we change it, and zero when the
    // blur can't be adjusted (eg, Reduce Transparency, or the internals have changed).
    self.supportsBlurRadius = (self.effectView.blurEffectRadius > 0.0f);
    if (!self.supportsBlurRadius) {
        // Fall back to a stable, subtle system material that we cross-fade via its opacity.
        self.effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        self.effectView.alpha = 0.0f;
        return;
    }

    // Start with no blur right away so the effect view doesn't briefly flash its default
    // full-strength blur, and hide its tint overlay so only the pure blur shows through.
    self.effectView.blurEffectRadius = 0.0f;
    self.effectView.dimmingAlpha = 0.0f;
}

#pragma mark - Blur -

- (void)_setBlurVisible:(BOOL)visible {
    if (self.supportsBlurRadius) {
        self.effectView.blurEffectRadius = visible ? kTOAlertDimmingBlurRadius : 0.0f;
    } else {
        self.effectView.alpha = visible ? 1.0f : 0.0f;
    }
}

#pragma mark - Public Animations -

- (void)playFadeInAnimationWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration
                     animations:^{
                         self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
                         [self _setBlurVisible:YES];
                     }];
}

- (void)playFadeOutAnimationWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration
                     animations:^{
                         self.backgroundColor = [UIColor clearColor];
                         [self _setBlurVisible:NO];
                     }];
}

@end
