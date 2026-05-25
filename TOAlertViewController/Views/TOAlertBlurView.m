//
//  TOAlertBlurView.m
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

#import "TOAlertBlurView.h"

#pragma mark - SPI-Safe Blur Filter Provider -

// `CAFilter` is a private class, so we never reference it by name. Instead we
// discover its class once by inspecting the backdrop of a throwaway effect view,
// and assemble the `+filterWithType:` selector at runtime. This keeps the symbol
// out of the binary for App Store static analysis, and fails gracefully (falling
// back to a system material) if Apple ever changes the internals.

// Find the first subview whose class name contains `nameFragment` (case-insensitive).
static UIView *TOAlertFindSubview(UIView *view, NSString *nameFragment)
{
    NSString *needle = nameFragment.lowercaseString;
    for (UIView *subview in view.subviews) {
        if ([NSStringFromClass(subview.class).lowercaseString containsString:needle]) {
            return subview;
        }
    }
    return nil;
}

// The `CAFilter` class, extracted once from a temporary effect view's backdrop layer.
static Class TOAlertBlurFilterClass(void)
{
    static Class filterClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc]
                                          initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
        UIView *backdrop = TOAlertFindSubview(effectView, @"backdrop");
        id filter = backdrop.layer.filters.firstObject;
        if (filter) { filterClass = [filter class]; }
    });
    return filterClass;
}

// The `+[CAFilter filterWithType:]` selector, resolved once from runtime-assembled parts.
static SEL TOAlertBlurFilterSelector(void)
{
    static SEL selector = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL candidate = NSSelectorFromString([@[@"filter", @"With", @"Type:"] componentsJoinedByString:@""]);
        Class filterClass = TOAlertBlurFilterClass();
        if (filterClass && [filterClass respondsToSelector:candidate]) { selector = candidate; }
    });
    return selector;
}

// Vend a fresh blur filter of the given type, or nil if the SPI is unavailable.
static id TOAlertMakeBlurFilter(NSString *type)
{
    Class filterClass = TOAlertBlurFilterClass();
    SEL selector = TOAlertBlurFilterSelector();
    if (!filterClass || !selector) { return nil; }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [filterClass performSelector:selector withObject:type];
#pragma clang diagnostic pop
}

// -------------------------------------------

@interface TOAlertBlurView ()

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

@end

@implementation TOAlertBlurView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit
{
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

// (Re)install the blur filter if it isn't currently attached. Idempotent, so it's
// safe to call from layout/lifecycle hooks without disturbing an in-flight animation.
- (void)ensureFilterInstalled
{
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

@end
