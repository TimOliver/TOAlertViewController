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

    // A change in appearance can cause the effect view to rebuild its backdrop,
    // discarding our filter, so force a re-install on the next pass.
    self.backdropView = nil;
    self.blurFilter = nil;
    [self ensureFilterInstalled];
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

    // Name the filter so it can be targeted by the `filters.gaussianBlur.inputRadius`
    // animation key path used in -setBlurRadius:animated:duration:.
    [filter setValue:@"gaussianBlur" forKey:@"name"];
    [filter setValue:@(self.blurRadius) forKey:@"inputRadius"];
    [filter setValue:@YES forKey:@"inputNormalizeEdges"];

    backdrop.layer.filters = @[filter];
    self.backdropView = backdrop;
    self.blurFilter = filter;

    // Hide the effect view's tint overlay so only the pure blur shows through.
    TOAlertFindSubview(self.effectView, @"subview").hidden = YES;

    self.effectView.alpha = 1.0f;
    self.usesGaussianFilter = YES;
    self.blurConfigured = YES;
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

    // Set the model value (re-creates the filter), then animate the presentation
    // from the old radius to the new one.
    self.blurRadius = blurRadius;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"filters.gaussianBlur.inputRadius"];
    animation.fromValue = @(currentRadius);
    animation.toValue = @(blurRadius);
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.backdropView.layer addAnimation:animation forKey:@"TOAlertBlurRadius"];
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
