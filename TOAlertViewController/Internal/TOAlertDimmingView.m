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
#import "TOAlertBlurFilter.h"

// The resting gaussian blur radius (in points) shown behind the alert.
// Kept deliberately subtle to produce a 'depth-of-field' effect rather than
// fully obscuring the content. Tune to taste.
static const CGFloat kTOAlertDimmingBlurRadius = 4.0f;

// The backdrop's sampling resolution when there is no blur to hide it.
// 1.0 == full (native) resolution. As the radius grows, we drop toward the
// system's resting downsample scale (captured at install) so the (now hidden)
// downsampling stays cheap. See -backdropScaleForRadius:.
static const CGFloat kTOAlertBackdropFullScale = 1.0f;

#if TARGET_OS_SIMULATOR
// Private UIKit hook to opt into the iOS Simulator's 'Slow Animations' flag
extern float UIAnimationDragCoefficient(void);
#endif

// Scale an animation duration by the Simulator's slow-animations factor.
static NSTimeInterval TOAlertSlowmoAdjustedDuration(NSTimeInterval duration)
{
#if TARGET_OS_SIMULATOR
    return duration * (NSTimeInterval)UIAnimationDragCoefficient();
#else
    return duration;
#endif
}

@interface TOAlertDimmingView ()

// The visual effect view whose backdrop layer hosts our gaussian blur filter.
@property (nonatomic, strong) UIVisualEffectView *effectView;

// Cached reference to the (private) backdrop subview. Weak, since the effect
// view may rebuild it when the system appearance changes.
@property (nonatomic, weak) UIView *backdropView;

// The gaussian blur filter currently attached to the backdrop layer.
@property (nonatomic, strong) id blurFilter;

// Whether we successfully installed the gaussian filter (vs. falling back to a material).
@property (nonatomic, assign) BOOL usesGaussianFilter;

// Whether the blur has been configured at least once.
@property (nonatomic, assign) BOOL blurConfigured;

// The current gaussian blur radius (in points) driving the backdrop filter.
@property (nonatomic, assign) CGFloat blurRadius;

// The system's resting backdrop downsample scale (captured once at install),
// used as the fully-blurred end of the scale ramp. 0 until captured.
@property (nonatomic, assign) CGFloat backdropRestingScale;

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

    _blurRadius = 0.0f;

    self.effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.effectView.frame = self.bounds;
    self.effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.effectView];

    // Override the system blur with our own zero-radius filter right away so the
    // effect view doesn't briefly flash its default full-strength blur.
    [self ensureFilterInstalled];

    // The system can rebuild the effect view's internals (and drop our filter)
    // when returning from the background, so re-apply it on foreground.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ensureFilterInstalled)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lifecycle -

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self ensureFilterInstalled];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self ensureFilterInstalled];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    // A color transition seems to reset the filter. Unfortunately, resetting the
    // filter here is apparently too early in the display chain.
    // We call `setNeedsLayout` since deferring the reset to the next layout pass fixes it.
    self.backdropView = nil;
    self.blurFilter = nil;
    [self setNeedsLayout];
}

#pragma mark - Blur Filter Management -

// (Re)install the blur filter if it isn't currently attached.
// Configured to be safe to call from layout/lifecycle hooks
// without disturbing an in-flight animation.
- (void)ensureFilterInstalled {
    // The material fallback is a stable effect that needs no re-application.
    if (self.blurConfigured && !self.usesGaussianFilter) { return; }

    UIView *backdrop = TOAlertFindSubview(self.effectView, @"backdrop");
    if (backdrop == nil) { return; }

    // Already installed on the current backdrop — just keep the tint overlay hidden.
    if (self.usesGaussianFilter && self.blurFilter != nil &&
        backdrop == self.backdropView &&
        [backdrop.layer.filters containsObject:self.blurFilter]) {
        TOAlertFindSubview(self.effectView, @"subview").hidden = YES;
        return;
    }

    id filter = TOAlertMakeBlurFilter(@"gaussianBlur");
    if (filter == nil) {
        // SPI unavailable — fall back to a stable, subtle system material. Because
        // a complete effect is itself a resting value, it also survives backgrounding.
        self.usesGaussianFilter = NO;
        self.blurConfigured = YES;
        self.effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        self.effectView.alpha = (self.blurRadius > 0.0f) ? 1.0f : 0.0f;
        return;
    }

    // Capture the system's resting downsample scale once, before we start driving
    // it ourselves. This is the value the effect uses at full blur strength.
    if (self.backdropRestingScale <= 0.0f) {
        NSNumber *systemScale = [backdrop.layer valueForKey:@"scale"];
        self.backdropRestingScale = (systemScale.doubleValue > 0.0) ? systemScale.doubleValue : 0.25f;
    }

    // Name the filter so it can be targeted by the `filters.gaussianBlur.inputRadius`
    // animation key path used in -setBlurRadius:animated:duration:.
    [filter setValue:@"gaussianBlur" forKey:@"name"];
    [filter setValue:@(self.blurRadius) forKey:@"inputRadius"];
    [filter setValue:@YES forKey:@"inputNormalizeEdges"];

    backdrop.layer.filters = @[filter];
    self.backdropView = backdrop;
    self.blurFilter = filter;

    // Match the backdrop's resolution to the blur strength (see -backdropScaleForRadius:).
    [self setBackdropScale:[self backdropScaleForRadius:self.blurRadius] onLayer:backdrop.layer];

    // Hide the effect view's tint overlay so only the pure blur shows through.
    TOAlertFindSubview(self.effectView, @"subview").hidden = YES;

    self.effectView.alpha = 1.0f;
    self.usesGaussianFilter = YES;
    self.blurConfigured = YES;
}

#pragma mark - Backdrop Scale -

// The backdrop is downsampled (`scale` < 1) so the gaussian blur is cheap to
// compute. That downsampling is invisible while a strong blur covers it, but as
// the radius animates to zero it would expose a blocky, un-blurred backdrop that
// then snaps to full resolution on removal. UIKit avoids this for its own blur
// transitions by ramping the backdrop scale up to full resolution as the blur
// fades; we mirror that here so the backdrop sharpens in lockstep with the blur.
- (CGFloat)backdropScaleForRadius:(CGFloat)radius
{
    CGFloat resting = (self.backdropRestingScale > 0.0f) ? self.backdropRestingScale : 0.25f;
    CGFloat t = radius / kTOAlertDimmingBlurRadius;     // 0 at no blur, 1 at the resting blur
    t = MAX(0.0f, MIN(t, 1.0f));
    return kTOAlertBackdropFullScale + t * (resting - kTOAlertBackdropFullScale);
}

// The backdrop layer's current (model) scale, falling back to the value implied
// by the current radius if the private key is unavailable.
- (CGFloat)currentBackdropScale
{
    NSNumber *scale = [self.backdropView.layer valueForKey:@"scale"];
    return (scale != nil) ? scale.doubleValue : [self backdropScaleForRadius:_blurRadius];
}

// Set the backdrop's model scale without an implicit animation; -setBlurRadius:
// animated:duration: supplies the explicit one when a transition is wanted.
- (void)setBackdropScale:(CGFloat)scale onLayer:(CALayer *)layer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [layer setValue:@(scale) forKey:@"scale"];
    [CATransaction commit];
}

#pragma mark - Blur Radius -

- (void)setBlurRadius:(CGFloat)blurRadius
{
    _blurRadius = blurRadius;

    if (!self.usesGaussianFilter) {
        self.effectView.alpha = (blurRadius > 0.0f) ? 1.0f : 0.0f;
        return;
    }

    // Re-create the filter so the new radius becomes the layer's model value.
    // (ensureFilterInstalled also updates the backdrop scale to match.)
    self.backdropView = nil;
    self.blurFilter = nil;
    [self ensureFilterInstalled];
}

- (void)setBlurRadius:(CGFloat)blurRadius animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!animated) {
        self.blurRadius = blurRadius;
        return;
    }

    CGFloat currentRadius = _blurRadius;

    if (!self.usesGaussianFilter) {
        // Fallback path: cross-fade the material blur via its opacity.
        _blurRadius = blurRadius;
        [UIView animateWithDuration:duration animations:^{
            self.effectView.alpha = (blurRadius > 0.0f) ? 1.0f : 0.0f;
        }];
        return;
    }

    // Capture the presentation start points before re-creating the filter sets
    // the new model values.
    CGFloat currentScale = [self currentBackdropScale];

    // Set the model values (re-creates the filter and updates the backdrop scale),
    // then animate the presentation from the old values to the new ones.
    self.blurRadius = blurRadius;
    CGFloat targetScale = [self backdropScaleForRadius:blurRadius];

    CAMediaTimingFunction *timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"filters.gaussianBlur.inputRadius"];
    radiusAnimation.fromValue = @(currentRadius);
    radiusAnimation.toValue = @(blurRadius);
    radiusAnimation.duration = TOAlertSlowmoAdjustedDuration(duration);
    radiusAnimation.timingFunction = timing;

    // Sharpen/soften the backdrop in lockstep with the blur so it never reveals a
    // blocky, un-blurred frame as the radius approaches zero.
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"scale"];
    scaleAnimation.fromValue = @(currentScale);
    scaleAnimation.toValue = @(targetScale);
    scaleAnimation.duration = TOAlertSlowmoAdjustedDuration(duration);
    scaleAnimation.timingFunction = timing;

    [self.backdropView.layer addAnimation:radiusAnimation forKey:@"TOAlertBlurRadius"];
    [self.backdropView.layer addAnimation:scaleAnimation forKey:@"TOAlertBlurScale"];
}

#pragma mark - Public Animations -

- (void)playFadeInAnimationWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    }];

    [self setBlurRadius:kTOAlertDimmingBlurRadius animated:YES duration:duration];
}

- (void)playFadeOutAnimationWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = [UIColor clearColor];
    }];

    [self setBlurRadius:0.0f animated:YES duration:duration];
}

@end
