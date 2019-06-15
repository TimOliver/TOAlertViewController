//
//  TOAlertView.m
//  TOAlertViewExample
//
//  Created by Tim Oliver on 3/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertView.h"
#import "TORoundedButton.h"
#import "TOAlertViewConstants.h"

// -------------------------------------------

@interface TOAlertView ()

// All of the components of the alert view
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

// All of the button views we can display
@property (nonatomic, strong) NSMutableArray<TORoundedButton *> *buttons;
@property (nonatomic, strong) TORoundedButton *returnButton;
@property (nonatomic, strong) TORoundedButton *destructiveButton;

// State Tracking
@property (nonatomic, assign) BOOL isDirty;
@property (nonatomic, readonly) BOOL isDarkMode;

// The window in charge of presenting this alert
@property (nonatomic, strong) UIWindow *window;

@end

@implementation TOAlertView

#pragma mark - Class Creation -

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message
{
    if (self = [super initWithFrame:CGRectZero]) {
        _title = [title copy];
        _message = [message copy];
        [self alertViewCommonInit];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self alertViewCommonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self alertViewCommonInit];
    }

    return self;
}

- (void)alertViewCommonInit
{
    _buttons = [NSMutableArray array];
    _cornerRadius = 30.0f;
    _buttonSpacing = 4.0f;
    _buttonHeight = 50.0f;
    _contentInsets = (UIEdgeInsets){30.0f, 30.0f, 30.0f, 30.0f};

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self configureColorsForTheme:_style];
    [self setUpSubviews];
}

- (void)setUpSubviews
{
    // Make sure the container itself is clear
    [super setBackgroundColor:[UIColor clearColor]];

    // Create the actual background view placed in the container view
    _backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 13.0, *)) {
        _backgroundView.layer.cornerCurve = kCACornerCurveContinuous;
    }
    _backgroundView.layer.cornerRadius = 35.0f;
    _backgroundView.backgroundColor = [UIColor whiteColor];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_backgroundView];

    // Create the title label, shown at the top of the container
    UIFontMetrics *titleMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = _backgroundView.backgroundColor;
    _titleLabel.font = [titleMetrics scaledFontForFont:[UIFont systemFontOfSize:27.0f weight:UIFontWeightBold]];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.text = _title;
    [self addSubview:_titleLabel];

    // Create the message label show below the title
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.textColor = [UIColor blackColor];
    _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _messageLabel.adjustsFontForContentSizeCategory = YES;
    _messageLabel.numberOfLines = 0;
    _messageLabel.text = _message;
    _messageLabel.backgroundColor = _backgroundView.backgroundColor;
    [self addSubview:_messageLabel];
}

- (void)configureColorsForTheme:(TOAlertViewStyle)style
{
    BOOL isDarkMode = (style == TOAlertViewStyleDark);

    // Set text colors
    UIColor *defaultColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    _titleColor   = defaultColor;
    _messageColor = defaultColor;

    // Set background color of alert view
    UIColor *backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.116 alpha:1.0f] : [UIColor whiteColor];
    self.backgroundColor = backgroundColor;

    // Set background colors of all button types
    CGFloat white = isDarkMode ? 0.3f : 0.7f;
    _actionButtonColor = [UIColor colorWithWhite:white alpha:1.0f];
    _defaultActionButtonColor = self.tintColor;
    _destructiveActionButtonColor = [UIColor redColor];

    // Set text colors for all button types
    _actionTextColor = defaultColor;
    _defaultActionTextColor = [UIColor whiteColor];
    _destructiveActionTextColor = [UIColor whiteColor];
}

#pragma mark - Presentation Configuration -
- (void)sizeToFitInBoundSize:(CGSize)size
{
    self.frame = (CGRect){0,0,300,300};
}

#pragma mark - Layout -

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Lay out the title view
    [self.titleLabel sizeToFit];
    CGRect frame = self.titleLabel.frame;
    frame.origin.x = 30.0f;
    frame.origin.y = 25.0f;
    frame.size.width = 240.0f;
    self.titleLabel.frame = frame;

    // Lay out the message label
    frame = self.messageLabel.frame;
    frame.size = [self.messageLabel sizeThatFits:(CGSize){240.0f, CGFLOAT_MAX}];
    frame.origin.x = 30.0f;
    frame.origin.y = 70.0f;
    self.messageLabel.frame = frame;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsLayout];
}

#pragma mark - Private Accessors -

- (BOOL)isDarkMode
{
    return (self.style == TOAlertViewStyleDark);
}

#pragma mark - Public Accessors -

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundView.backgroundColor = backgroundColor;
}
- (UIColor *)backgroundColor { return self.backgroundView.backgroundColor; }

- (void)setStyle:(TOAlertViewStyle)style
{
    _style = style;
}

- (void)setTitleColor:(nullable UIColor *)titleColor
{
    if (!titleColor) {
        _titleColor = self.isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        return;
    }

    if (titleColor == _titleColor) { return; }
    _titleColor = titleColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (!messageColor) {
        _messageColor = self.isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        return;
    }

    if (messageColor == _messageColor) { return; }
    _messageColor = messageColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDefaultActionButtonColor:(UIColor *)defaultActionButtonColor
{
    if (!defaultActionButtonColor) {
        CGFloat white = self.isDarkMode ? 0.3f : 0.7f;
        _defaultActionButtonColor = [UIColor colorWithWhite:white alpha:1.0f];
        return;
    }

    if (defaultActionButtonColor == _defaultActionButtonColor) { return; }
    _defaultActionButtonColor = defaultActionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDefaultActionTextColor:(UIColor *)defaultActionTextColor
{
    if (!defaultActionTextColor) {
        _defaultActionTextColor = self.isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
        return;
    }

    if (defaultActionTextColor == _defaultActionTextColor) { return; }
    _defaultActionTextColor = defaultActionTextColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setActionButtonColor:(UIColor *)actionButtonColor
{
    if (!actionButtonColor) {
        _actionButtonColor = self.tintColor;
        return;
    }

    if (actionButtonColor == _actionButtonColor) { return; }
    _actionButtonColor = actionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setActionTextColor:(UIColor *)actionTextColor
{
    if (!actionTextColor) {
        _actionTextColor = [UIColor whiteColor];
        return;
    }

    if (actionTextColor == _actionTextColor) { return; }
    _actionTextColor = actionTextColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDestructiveActionButtonColor:(UIColor *)destructiveActionButtonColor
{
    if (!destructiveActionButtonColor) {
        _destructiveActionButtonColor = [UIColor redColor];
        return;
    }

    if (destructiveActionButtonColor == _destructiveActionButtonColor) { return; }
    _destructiveActionButtonColor = destructiveActionButtonColor;
    _isDirty = YES;
    [self setNeedsLayout];
}

- (void)setDestructiveActionTextColor:(UIColor *)destructiveActionTextColor
{
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
