//
//  TOAlertBlurView.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
/// A view that applies a uniform gaussian blur to the content behind it.
///
/// Unlike pausing a `UIViewPropertyAnimator` partway through a `UIVisualEffectView`
/// transition, the blur intensity here is a stable model value on the backdrop
/// layer, so a partial blur persists across app backgrounding and foregrounding.
@interface TOAlertBlurView : UIView

/// The gaussian blur radius (in points) applied to the content behind this view.
/// Defaults to 0 (no blur). Setting this updates the blur immediately.
@property (nonatomic, assign) CGFloat blurRadius;

/// Animate the blur radius to a new value.
/// @param blurRadius The target blur radius, in points.
/// @param animated Whether to animate the transition.
/// @param duration The duration of the animation, if animated.
- (void)setBlurRadius:(CGFloat)blurRadius animated:(BOOL)animated duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
