//
//  TOAlertView.m
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

#import "TOAlertView.h"
#import "TORoundedButton.h"
#import "TOAlertAction.h"
#import "TOAlertLinkLayout.h"
#import "TOAlertMacros.h"

// The haptic played when a button is tapped, chosen to match the button's role.
typedef NS_ENUM(NSInteger, TOAlertButtonFeedback) {
    TOAlertButtonFeedbackDefault,      // neutral: cancel and regular actions
    TOAlertButtonFeedbackSuccess,      // the default (confirming) action
    TOAlertButtonFeedbackDestructive,  // the destructive (irreversible) action
};

// -------------------------------------------

@interface TOAlertView ()

@property (nonatomic, strong, readwrite) NSMutableArray *actions;

// All of the components of the alert view
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

// All of the button views we can display
@property (nonatomic, strong) NSMutableArray<TORoundedButton *> *buttons;
@property (nonatomic, strong) NSHashTable<TORoundedButton *> *fullWidthButtons;
@property (nonatomic, strong) TORoundedButton *defaultButton;
@property (nonatomic, strong) TORoundedButton *cancelButton;
@property (nonatomic, strong) TORoundedButton *destructiveButton;

// A dynamic list of the buttons to display, in the correct order
@property (nonatomic, readonly) NSArray<TORoundedButton *> *displayButtons;

// State Tracking
@property (nonatomic, assign) BOOL isDirty;

@property (nonatomic, strong) CAShapeLayer *linkHighlightLayer;
@property (nonatomic, strong, nullable) TOAlertLink *activeLink;

// Taptic Engine generators used to play impacts when the user taps a button
@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationFeedback;
@property (nonatomic, strong) UIImpactFeedbackGenerator *mediumImpactFeedback;

// Private helpers, dispatched directly since they are only ever called via [self …]
- (void)_alertViewCommonInit TOALERT_OBJC_DIRECT;
- (void)_setUpSubviews TOALERT_OBJC_DIRECT;
- (TORoundedButton *)_makeButtonWithAction:(TOAlertAction *)action
                                 textColor:(UIColor *)textColor
                           backgroundColor:(UIColor *)backgroundColor
                                  boldText:(BOOL)boldText
                                  feedback:(TOAlertButtonFeedback)feedback TOALERT_OBJC_DIRECT;
- (void)_configureDefaultColors TOALERT_OBJC_DIRECT;
- (void)_configureViewsForCurrentTheme TOALERT_OBJC_DIRECT;
- (void)_updateMessageLabel TOALERT_OBJC_DIRECT;
- (CGFloat)_heightForButton:(TORoundedButton *)button width:(CGFloat)width TOALERT_OBJC_DIRECT;
- (BOOL)_shouldPairLastTwoButtonsForWidth:(CGFloat)width TOALERT_OBJC_DIRECT;
- (void)_buttonTappedWithAction:(void (^)(void))action feedback:(TOAlertButtonFeedback)feedback TOALERT_OBJC_DIRECT;
- (nullable TOAlertLink *)_linkAtPointInMessageLabel:(CGPoint)point TOALERT_OBJC_DIRECT;
- (TOAlertLinkLayout *)_makeLinkLayout TOALERT_OBJC_DIRECT;
- (void)_showHighlightForLink:(TOAlertLink *)link TOALERT_OBJC_DIRECT;
- (void)_hideHighlight TOALERT_OBJC_DIRECT;
- (void)_animateHighlightToOpacity:(CGFloat)opacity TOALERT_OBJC_DIRECT;

@end

@implementation TOAlertView

#pragma mark - Class Creation -

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message {
    if (self = [super initWithFrame:CGRectZero]) {
        _title = [title copy];
        _message = [message copy];
        [self _alertViewCommonInit];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectZero]) { [self _alertViewCommonInit]; }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { [self _alertViewCommonInit]; }

    return self;
}

- (void)_alertViewCommonInit {
    _buttons = [NSMutableArray array];
    _fullWidthButtons = [NSHashTable weakObjectsHashTable];
    _cornerRadius = 30.0f;
    _buttonCornerRadius = 15.0f;
    _buttonSpacing = (CGSize){12.0f, 15.0f};
    _buttonHeight = 54.0f;
    _contentInsets = (UIEdgeInsets){23.0f, 25.0f, 17.0f, 25.0f};
    _maximumWidth = 375.0f;
    _verticalTextSpacing = 11.0f;
    _buttonInsets = (UIEdgeInsets){28.0f, 17.0f, 0.0f, 17.0f};
    _messageTextAlignment = NSTextAlignmentCenter;

    [self _setUpSubviews];
    [self _configureDefaultColors];
}

- (void)_setUpSubviews {
    // Make sure the container itself is clear
    [super setBackgroundColor:[UIColor clearColor]];

    // Create the actual background view placed in the container view
    _backgroundView = [[UIView alloc] initWithFrame:CGRectZero];

    if (@available(iOS 13.0, *)) {
#ifdef __IPHONE_13_0
        _backgroundView.layer.cornerCurve = kCACornerCurveContinuous;
#endif
    }
    _backgroundView.layer.cornerRadius = _cornerRadius;
    _backgroundView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundView.layer.shadowRadius = 35.0f;
    _backgroundView.layer.shadowOpacity = 0.15f;
    [self addSubview:_backgroundView];

    // Create the title label, shown at the top of the container
    UIFontMetrics *titleMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = _backgroundView.backgroundColor;
    _titleLabel.font = [titleMetrics scaledFontForFont:[UIFont systemFontOfSize:33.0f weight:UIFontWeightBold]];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.numberOfLines = 0;
    _titleLabel.text = _title;
    [self addSubview:_titleLabel];

    // Create the message label show below the title
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.textColor = [UIColor labelColor];
    _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _messageLabel.adjustsFontForContentSizeCategory = YES;
    _messageLabel.numberOfLines = 0;
    [self _updateMessageLabel];
    _messageLabel.userInteractionEnabled = YES;

    _linkHighlightLayer = [CAShapeLayer layer];
    _linkHighlightLayer.opacity = 0.0f;
    [_messageLabel.layer insertSublayer:_linkHighlightLayer atIndex:0];

    UILongPressGestureRecognizer *press =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(messageLabelPressed:)];
    press.minimumPressDuration = 0.0;       // recognise touch-down immediately
    press.cancelsTouchesInView = NO;
    [_messageLabel addGestureRecognizer:press];
    _messageLabel.backgroundColor = _backgroundView.backgroundColor;
    [self addSubview:_messageLabel];
}

- (TORoundedButton *)_makeButtonWithAction:(TOAlertAction *)action
                                textColor:(UIColor *)textColor
                          backgroundColor:(UIColor *)backgroundColor
                                 boldText:(BOOL)boldText
                                 feedback:(TOAlertButtonFeedback)feedback {
    __weak typeof(self) weakSelf = self;

    TORoundedButton *button;
    if (action.contentView) {
        // Custom-content action: hand the caller's view straight to the button and
        // render it full width, sized to its content (see layout in Task 3).
        button = [[TORoundedButton alloc] initWithContentView:action.contentView];
        button.accessibilityLabel = action.title;
        [self.fullWidthButtons addObject:button];
    } else {
        UIFontWeight fontWeight = boldText ? UIFontWeightBold : UIFontWeightMedium;
        UIFontMetrics *buttonTitleMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle3];
        UIFont *const buttonFont = [buttonTitleMetrics scaledFontForFont:[UIFont systemFontOfSize:19.0f weight:fontWeight]];

        button = [[TORoundedButton alloc] initWithText:action.title];
        button.textColor = textColor;
        button.textFont = buttonFont;
    }

    button.backgroundStyle = TORoundedButtonBackgroundStyleSolid;
    button.tintColor = backgroundColor;
    button.cornerRadius = _buttonCornerRadius;
    button.backgroundColor = [UIColor clearColor];
    button.tappedHandler = ^{ [weakSelf _buttonTappedWithAction:action.action feedback:feedback]; };
    return button;
}

// A neutral fill for the regular and cancel buttons: a light gray in Light
// mode, a mid gray in Dark mode. Resolves automatically as the system
// appearance changes.
+ (UIColor *)neutralButtonColor {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor systemGray3Color]
                                                                              : [UIColor systemGray5Color];
    }];
}

- (void)_configureDefaultColors {
    // Title and message text follow the system label color
    _titleColor = [UIColor labelColor];
    _messageColor = [UIColor labelColor];

    // The alert surface sits above the dimming view as a grouped background
    self.backgroundColor = [UIColor secondarySystemBackgroundColor];

    // Regular and cancel buttons use a neutral system gray, the default
    // (return) button uses the app tint, and destructive uses the system red.
    _actionButtonColor = [TOAlertView neutralButtonColor];
    _defaultActionButtonColor = self.tintColor;
    _destructiveActionButtonColor = [UIColor systemRedColor];

    // Button text: neutral buttons follow the label color, while the filled
    // default and destructive buttons use white for contrast against their fill.
    _actionTextColor = [UIColor labelColor];
    _defaultActionTextColor = [UIColor whiteColor];
    _destructiveActionTextColor = [UIColor whiteColor];

    // Mark as dirty so we can bulk update the button views
    self.isDirty = YES;
    [self setNeedsLayout];
}

- (void)_configureViewsForCurrentTheme {
    // Title label
    self.titleLabel.backgroundColor = self.backgroundColor;
    self.titleLabel.textColor = self.titleColor;

    // Message label
    self.messageLabel.backgroundColor = self.backgroundColor;
    self.messageLabel.textColor = self.messageColor;
    [self _updateMessageLabel];

    // Destructive button
    if (self.destructiveButton) {
        self.destructiveButton.textColor = self.destructiveActionTextColor;
        self.destructiveButton.tintColor = self.destructiveActionButtonColor;
    }

    // Default button
    if (self.defaultButton) {
        self.defaultButton.tintColor = self.tintColor;
        self.defaultButton.textColor = self.defaultActionTextColor;
    }

    // Cancel button
    if (self.cancelButton) {
        self.cancelButton.textColor = self.actionTextColor;
        self.cancelButton.tintColor = self.actionButtonColor;
    }

    // Other buttons
    for (TORoundedButton *button in self.buttons) {
        button.textColor = self.actionTextColor;
        button.tintColor = self.actionButtonColor;
    }
}

#pragma mark - Presentation Configuration -

- (void)_updateMessageLabel {
    self.messageLabel.textAlignment = self.messageTextAlignment;
    if (self.attributedMessage) {
        self.messageLabel.attributedText = TOAlertNormalizedMessage(self.attributedMessage,
                                                                    self.messageLabel.font,
                                                                    self.messageColor,
                                                                    self.tintColor,
                                                                    self.messageTextAlignment);
    } else {
        self.messageLabel.text = self.message;
    }
}

- (void)sizeToFitInBoundSize:(CGSize)size {
    CGRect frame = CGRectZero;

    // Width is either the maximum width, or the available size we have
    frame.size.width = MIN(_maximumWidth, size.width);

    // For sizing text, work out the usable width we have
    const CGFloat contentWidth = frame.size.width - (_contentInsets.left + _contentInsets.right);
    CGSize contentSize = (CGSize){contentWidth, CGFLOAT_MAX};

    // Work out the height we need to fit every element

    // Top and bottom insets
    frame.size.height += _contentInsets.top + _contentInsets.bottom;

    // Title label size
    frame.size.height += [self.titleLabel sizeThatFits:contentSize].height + _verticalTextSpacing;

    // Message label size
    frame.size.height += [self.messageLabel sizeThatFits:contentSize].height + _buttonInsets.top;

    // Sum the button rows. Plain rows use the fixed height; full-width custom
    // rows are measured against their content. The last two plain buttons may
    // share a row. Use the clamped frame width (not the raw bound size) so the
    // measured row heights match the widths layoutSubviews will lay out at.
    const CGFloat buttonWidth = frame.size.width - (_buttonInsets.left + _buttonInsets.right);
    NSArray<TORoundedButton *> *const displayButtons = self.displayButtons;
    const BOOL pairLastTwo = [self _shouldPairLastTwoButtonsForWidth:buttonWidth];
    const NSInteger rowCount = displayButtons.count - (pairLastTwo ? 1 : 0);

    for (NSInteger i = 0; i < (NSInteger)displayButtons.count; i++) {
        if (pairLastTwo && i == (NSInteger)displayButtons.count - 1) { continue; } // shares the previous row
        frame.size.height += [self _heightForButton:displayButtons[i] width:buttonWidth];
    }
    if (rowCount > 1) {
        frame.size.height += (rowCount - 1) * _buttonSpacing.height;
    }

    self.frame = frame;
}

// The laid-out height of a single button row. Full-width custom-content buttons
// are measured against their content; plain text buttons use the fixed height.
- (CGFloat)_heightForButton:(TORoundedButton *)button width:(CGFloat)width {
    if (![self.fullWidthButtons containsObject:button]) { return _buttonHeight; }

    UIView *const content = button.contentView;
    const UIEdgeInsets inset = button.contentInset;
    const CGFloat innerWidth = width - (inset.left + inset.right);

    CGFloat height = [content systemLayoutSizeFittingSize:(CGSize){innerWidth, UILayoutFittingCompressedSize.height}
                            withHorizontalFittingPriority:UILayoutPriorityRequired
                                  verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    if (height <= 0.0f) {
        height = [content sizeThatFits:(CGSize){innerWidth, CGFLOAT_MAX}].height;
    }
    return ceilf(height) + inset.top + inset.bottom;
}

// Whether the last two display buttons may share a row. Custom-content (full
// width) buttons never pair.
- (BOOL)_shouldPairLastTwoButtonsForWidth:(CGFloat)width {
    NSArray<TORoundedButton *> *const buttons = self.displayButtons;
    const NSInteger count = buttons.count;
    if (count <= 1) { return NO; }

    TORoundedButton *const last = buttons[count - 1];
    TORoundedButton *const secondLast = buttons[count - 2];
    if ([self.fullWidthButtons containsObject:last] || [self.fullWidthButtons containsObject:secondLast]) {
        return NO;
    }

    const CGFloat maxWidth = floorf(width - (self.buttonSpacing.width * 0.5f));
    return (last.minimumWidth < maxWidth && secondLast.minimumWidth < maxWidth);
}

- (NSArray<TORoundedButton *> *)displayButtons {
    NSMutableArray *buttons = [NSMutableArray array];

    // Destructive button always comes first, either on the left, or top
    if (self.destructiveButton) { [buttons addObject:self.destructiveButton]; }

    // Add all regular buttons
    [buttons addObjectsFromArray:self.buttons];

    // Cancel comes after destructive, but before default
    if (self.cancelButton) { [buttons addObject:self.cancelButton]; }

    // Add default button (Should be right by default)
    if (self.defaultButton) { [buttons addObject:self.defaultButton]; }

    return buttons;
}

#pragma mark - Layout -

- (void)layoutSubviews {
    [super layoutSubviews];

    // If necessary, set the new color theme
    if (self.isDirty) {
        [self _configureViewsForCurrentTheme];
        self.isDirty = NO;
    }

    // Layout the background
    self.backgroundView.frame = self.bounds;

    // For sizing text, work out the usable width we have
    const CGFloat contentWidth = self.bounds.size.width - (_contentInsets.left + _contentInsets.right);
    CGSize contentSize = (CGSize){contentWidth, CGFLOAT_MAX};

    // Track the vertical layout height
    CGFloat y = 0.0f;

    // Lay out the title view
    CGRect frame = self.titleLabel.frame;
    frame.size = [self.titleLabel sizeThatFits:contentSize];
    frame.size.width = contentWidth;
    frame.origin.x = _contentInsets.left;
    frame.origin.y = _contentInsets.top;
    self.titleLabel.frame = frame;

    y = CGRectGetMaxY(frame) + self.verticalTextSpacing;

    // Lay out the message label
    frame = self.messageLabel.frame;
    frame.size = [self.messageLabel sizeThatFits:contentSize];
    frame.origin.x = _contentInsets.left;
    frame.size.width = contentWidth;
    frame.origin.y = y;
    self.messageLabel.frame = frame;

    y = CGRectGetMaxY(frame) + self.buttonInsets.top;

    // Add any regular buttons
    const CGFloat buttonWidth = self.bounds.size.width - (_buttonInsets.left + _buttonInsets.right);
    const CGFloat midWidth = floorf((buttonWidth - _buttonSpacing.width) * 0.5f);

    NSArray<TORoundedButton *> *const displayButtons = self.displayButtons;
    const BOOL pairLastTwo = [self _shouldPairLastTwoButtonsForWidth:buttonWidth];

    for (NSInteger i = 0; i < (NSInteger)displayButtons.count; i++) {
        TORoundedButton *const button = displayButtons[i];
        const CGFloat rowHeight = [self _heightForButton:button width:buttonWidth];

        frame = CGRectZero;
        frame.size.width = buttonWidth;
        frame.size.height = rowHeight;
        frame.origin.x = _buttonInsets.left;
        frame.origin.y = y;

        if (pairLastTwo && i == (NSInteger)displayButtons.count - 2) {
            frame.size.width = midWidth;
            frame.size.height = _buttonHeight;
            button.frame = CGRectIntegral(frame);
            y += _buttonHeight + _buttonSpacing.height;
        } else if (pairLastTwo && i == (NSInteger)displayButtons.count - 1) {
            frame.origin.y = displayButtons[i - 1].frame.origin.y;
            frame.size.width = midWidth;
            frame.size.height = _buttonHeight;
            frame.origin.x = self.bounds.size.width - (_buttonInsets.left + midWidth);
            button.frame = CGRectIntegral(frame);
        } else {
            button.frame = CGRectIntegral(frame);
            y += rowHeight + _buttonSpacing.height;
        }
    }

    // Update the shadow path shape
    _backgroundView.layer.shadowPath =
        [UIBezierPath bezierPathWithRoundedRect:_backgroundView.bounds cornerRadius:_cornerRadius].CGPath;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    // When the system appearance (light/dark) changes, re-apply colors so the
    // buttons resolve their dynamic colors against the new trait environment.
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        self.isDirty = YES;
    }
    [self setNeedsLayout];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (!self.window) { return; }
    [self.notificationFeedback prepare];
    [self.mediumImpactFeedback prepare];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self _updateMessageLabel];
}

#pragma mark - Hit Testing -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Give inline links priority over the buttons: if the touch lands within a
    // link's padded tap area, route it to the message label — even when the
    // point falls outside the label itself (e.g. in the gap above the buttons).
    if (self.messageLabel.attributedText.length > 0) {
        CGPoint labelPoint = [self convertPoint:point toView:self.messageLabel];
        if ([[self _makeLinkLayout] linkAtPoint:labelPoint] != nil) {
            return self.messageLabel;
        }
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Interaction -

- (void)_buttonTappedWithAction:(void (^)(void))action feedback:(TOAlertButtonFeedback)feedback {
    // Play a haptic impact, with intensity being driven by the type of button
    switch (feedback) {
        case TOAlertButtonFeedbackSuccess:
            [self.notificationFeedback notificationOccurred:UINotificationFeedbackTypeSuccess];
            break;
        case TOAlertButtonFeedbackDestructive:
            [self.notificationFeedback notificationOccurred:UINotificationFeedbackTypeWarning];
            break;
        case TOAlertButtonFeedbackDefault:
            [self.mediumImpactFeedback impactOccurred];
            break;
    }

    // Execute the block associated with this button
    if (self.buttonTappedHandler) { self.buttonTappedHandler(action); }
}

#pragma mark - Haptic Generators -

- (UINotificationFeedbackGenerator *)notificationFeedback {
    if (!_notificationFeedback) {
        _notificationFeedback = [[UINotificationFeedbackGenerator alloc] init];
    }
    return _notificationFeedback;
}

- (UIImpactFeedbackGenerator *)mediumImpactFeedback {
    if (!_mediumImpactFeedback) {
        _mediumImpactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    }
    return _mediumImpactFeedback;
}

- (void)messageLabelPressed:(UILongPressGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.messageLabel];

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            TOAlertLink *link = [self _linkAtPointInMessageLabel:point];
            if (link == nil) { self.activeLink = nil; break; }
            self.activeLink = link;
            [self _showHighlightForLink:link];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.activeLink == nil) { break; }
            TOAlertLink *link = [self _linkAtPointInMessageLabel:point];
            if (link == nil || !NSEqualRanges(link.range, self.activeLink.range)) {
                [self _hideHighlight];
                self.activeLink = nil;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            TOAlertLink *link = self.activeLink;
            [self _hideHighlight];
            self.activeLink = nil;
            if (link && self.linkTappedHandler) { self.linkTappedHandler(link.URL, link.range); }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self _hideHighlight];
            self.activeLink = nil;
            break;
        }
        default: break;
    }
}

- (nullable TOAlertLink *)_linkAtPointInMessageLabel:(CGPoint)point {
    return [[self _makeLinkLayout] linkAtPoint:point];
}

- (TOAlertLinkLayout *)_makeLinkLayout {
    NSAttributedString *text = self.messageLabel.attributedText;
    return [[TOAlertLinkLayout alloc] initWithAttributedString:(text ?: [NSAttributedString new])
                                                         size:self.messageLabel.bounds.size
                                                numberOfLines:self.messageLabel.numberOfLines
                                                lineBreakMode:self.messageLabel.lineBreakMode];
}

- (void)_showHighlightForLink:(TOAlertLink *)link {
    NSArray<NSValue *> *const rects = [[self _makeLinkLayout] enclosingRectsForRange:link.range];

    UIBezierPath *const path = [UIBezierPath bezierPath];
    for (NSValue *value in rects) {
        CGRect rect = CGRectInset(value.CGRectValue, -3.0f, -3.0f);   // a little breathing room
        [path appendPath:[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:5.0f]];
    }

    // Apply the fill and path instantly — without this, Core Animation's implicit
    // animation cross-fades the fill color (default black → blue) on first show.
    // Only the opacity should animate (handled below).
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.linkHighlightLayer.fillColor = [self.tintColor colorWithAlphaComponent:0.2f].CGColor;
    self.linkHighlightLayer.path = path.CGPath;
    [CATransaction commit];

    [self _animateHighlightToOpacity:1.0f];
}

- (void)_hideHighlight {
    [self _animateHighlightToOpacity:0.0f];
}

- (void)_animateHighlightToOpacity:(CGFloat)opacity {
    CALayer *const presentation = self.linkHighlightLayer.presentationLayer;
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(presentation ? presentation.opacity : self.linkHighlightLayer.opacity);
    fade.toValue = @(opacity);
    fade.duration = 0.15;
    fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    self.linkHighlightLayer.opacity = opacity;   // set the model value so it sticks
    [self.linkHighlightLayer addAnimation:fade forKey:@"opacity"];
}

#pragma mark - Action Creation/Deletion -

- (void)setDefaultAction:(TOAlertAction *)defaultAction {
    if (defaultAction == _defaultAction) { return; }
    _defaultAction = defaultAction;

    self.isDirty = YES;
    [self setNeedsLayout];

    // If we set it to null, remove the button
    if (_defaultAction == nil) {
        [_defaultButton removeFromSuperview];
        _defaultButton = nil;
        return;
    }

    _defaultButton = [self _makeButtonWithAction:defaultAction
                                      textColor:self.defaultActionTextColor
                                backgroundColor:self.tintColor
                                       boldText:YES
                                       feedback:TOAlertButtonFeedbackSuccess];
    [self addSubview:_defaultButton];
}

- (void)setDestructiveAction:(TOAlertAction *)destructiveAction {
    if (destructiveAction == _destructiveAction) { return; }
    _destructiveAction = destructiveAction;

    self.isDirty = YES;
    [self setNeedsLayout];

    // If we set it to null, remove the button
    if (_destructiveAction == nil) {
        [_destructiveButton removeFromSuperview];
        _destructiveButton = nil;
        return;
    }

    _destructiveButton = [self _makeButtonWithAction:destructiveAction
                                          textColor:self.destructiveActionTextColor
                                    backgroundColor:_destructiveActionButtonColor
                                           boldText:NO
                                           feedback:TOAlertButtonFeedbackDestructive];
    [self addSubview:_destructiveButton];
}

- (void)setCancelAction:(TOAlertAction *)cancelAction {
    if (cancelAction == _cancelAction) { return; }
    _cancelAction = cancelAction;

    self.isDirty = YES;
    [self setNeedsLayout];

    // If we set it to null, remove the button
    if (_cancelAction == nil) {
        [_cancelButton removeFromSuperview];
        _cancelButton = nil;
        return;
    }

    _cancelButton = [self _makeButtonWithAction:cancelAction
                                     textColor:self.actionTextColor
                               backgroundColor:_actionButtonColor
                                      boldText:NO
                                      feedback:TOAlertButtonFeedbackDefault];
    [self addSubview:_cancelButton];
}

- (void)addAction:(TOAlertAction *)action {
    // Create data stores if needed
    if (!self.actions) { self.actions = [NSMutableArray array]; }
    if (!self.buttons) { self.buttons = [NSMutableArray array]; }

    NSMutableArray *actions = (NSMutableArray *)self.actions;

    // Add action to array
    [actions addObject:action];

    // Create button for it
    TORoundedButton *button = [self _makeButtonWithAction:action
                                               textColor:self.actionTextColor
                                         backgroundColor:self.actionButtonColor
                                                boldText:NO
                                                feedback:TOAlertButtonFeedbackDefault];
    [self.buttons addObject:button];
    [self addSubview:button];
}

- (void)removeAction:(TOAlertAction *)action {
    NSUInteger index = [self.actions indexOfObjectIdenticalTo:action];
    [self removeActionAtIndex:index];
}

- (void)removeActionAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.actions.count) { return; }

    TORoundedButton *button = self.buttons[index];
    [button removeFromSuperview];
    [self.buttons removeObjectAtIndex:index];

    [(NSMutableArray *)self.actions removeObjectAtIndex:index];
}

#pragma mark - Color/Theme Accessors -

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.backgroundView.backgroundColor = backgroundColor;
}
- (UIColor *)backgroundColor {
    return self.backgroundView.backgroundColor;
}

- (void)setTitleColor:(nullable UIColor *)titleColor {
    if (!titleColor) {
        _titleColor = [UIColor labelColor];
        return;
    }

    if (titleColor == _titleColor) { return; }
    _titleColor = titleColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setMessageColor:(UIColor *)messageColor {
    if (!messageColor) {
        _messageColor = [UIColor labelColor];
        return;
    }

    if (messageColor == _messageColor) { return; }
    _messageColor = messageColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setMessage:(NSString *)message {
    _message = [message copy];
    [self _updateMessageLabel];
    [self setNeedsLayout];
}

- (void)setAttributedMessage:(NSAttributedString *)attributedMessage {
    _attributedMessage = [attributedMessage copy];
    [self _updateMessageLabel];
    [self setNeedsLayout];
}

- (void)setMessageTextAlignment:(NSTextAlignment)messageTextAlignment {
    if (_messageTextAlignment == messageTextAlignment) { return; }
    _messageTextAlignment = messageTextAlignment;
    [self _updateMessageLabel];
    [self setNeedsLayout];
}

- (void)setDefaultActionButtonColor:(UIColor *)defaultActionButtonColor {
    if (!defaultActionButtonColor) {
        _defaultActionButtonColor = self.tintColor;
        return;
    }

    if (defaultActionButtonColor == _defaultActionButtonColor) { return; }
    _defaultActionButtonColor = defaultActionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDefaultActionTextColor:(UIColor *)defaultActionTextColor {
    if (!defaultActionTextColor) {
        _defaultActionTextColor = [UIColor whiteColor];
        return;
    }

    if (defaultActionTextColor == _defaultActionTextColor) { return; }
    _defaultActionTextColor = defaultActionTextColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setActionButtonColor:(UIColor *)actionButtonColor {
    if (!actionButtonColor) {
        _actionButtonColor = [TOAlertView neutralButtonColor];
        return;
    }

    if (actionButtonColor == _actionButtonColor) { return; }
    _actionButtonColor = actionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setActionTextColor:(UIColor *)actionTextColor {
    if (!actionTextColor) {
        _actionTextColor = [UIColor labelColor];
        return;
    }

    if (actionTextColor == _actionTextColor) { return; }
    _actionTextColor = actionTextColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDestructiveActionButtonColor:(UIColor *)destructiveActionButtonColor {
    if (!destructiveActionButtonColor) {
        _destructiveActionButtonColor = [UIColor systemRedColor];
        return;
    }

    if (destructiveActionButtonColor == _destructiveActionButtonColor) { return; }
    _destructiveActionButtonColor = destructiveActionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDestructiveActionTextColor:(UIColor *)destructiveActionTextColor {
    if (!destructiveActionTextColor) {
        _destructiveActionTextColor = [UIColor whiteColor];
        return;
    }

    if (destructiveActionTextColor == _destructiveActionTextColor) { return; }
    _destructiveActionTextColor = destructiveActionTextColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

@end
