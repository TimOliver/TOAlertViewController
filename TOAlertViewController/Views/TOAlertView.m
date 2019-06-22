//
//  TOAlertView.m
//  TOAlertViewExample
//
//  Created by Tim Oliver on 3/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertView.h"
#import "TORoundedButton.h"
#import "TOAlertAction.h"
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
@property (nonatomic, strong) TORoundedButton *defaultButton;
@property (nonatomic, strong) TORoundedButton *cancelButton;
@property (nonatomic, strong) TORoundedButton *destructiveButton;

// A dynamic list of the buttons to display, in the correct order
@property (nonatomic, readonly) NSArray<TORoundedButton *> *displayButtons;

// State Tracking
@property (nonatomic, assign) BOOL isDirty;
@property (nonatomic, readonly) BOOL isDarkMode;

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
    _buttonCornerRadius = 15.0f;
    _buttonSpacing = (CGSize){8.0f, 8.0f};
    _buttonHeight = 50.0f;
    _contentInsets = (UIEdgeInsets){23.0f, 25.0f, 17.0f, 25.0f};
    _maximumWidth = 375.0f;
    _verticalTextSpacing = 9.0f;
    _buttonInsets = (UIEdgeInsets){20.0f, 17.0f, 0.0f, 17.0f};

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
        #ifdef __IPHONE_13_0
        _backgroundView.layer.cornerCurve = kCACornerCurveContinuous;
        #endif
    }
    _backgroundView.layer.cornerRadius = _cornerRadius;
    _backgroundView.backgroundColor = [UIColor whiteColor];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundView.layer.shadowRadius = 35.0f;
    _backgroundView.layer.shadowOpacity = 0.15f;
    [self addSubview:_backgroundView];

    // Create the title label, shown at the top of the container
    UIFontMetrics *titleMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = _backgroundView.backgroundColor;
    _titleLabel.font = [titleMetrics scaledFontForFont:[UIFont systemFontOfSize:29.0f weight:UIFontWeightBold]];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.text = _title;
    [self addSubview:_titleLabel];

    // Create the message label show below the title
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.textColor = [UIColor blackColor];
    _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _messageLabel.adjustsFontForContentSizeCategory = YES;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.numberOfLines = 0;
    _messageLabel.text = _message;
    _messageLabel.backgroundColor = _backgroundView.backgroundColor;
    [self addSubview:_messageLabel];
}

- (TORoundedButton *)makeButtonWithTitle:(NSString *)title textColor:(UIColor *)textColor backgroundColor:(UIColor *)backgroundColor
{
    TORoundedButton *button = [[TORoundedButton alloc] initWithText:title];
    button.tintColor = backgroundColor;
    button.cornerRadius = _buttonCornerRadius;
    button.textColor = textColor;
    button.backgroundColor = [UIColor clearColor];
    return button;
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
    CGFloat white = isDarkMode ? 0.35f : 0.9f;
    _actionButtonColor = [UIColor colorWithWhite:white alpha:1.0f];
    _defaultActionButtonColor = self.tintColor;
    _destructiveActionButtonColor = [UIColor redColor];

    // Set text colors for all button types
    _actionTextColor = defaultColor;
    _defaultActionTextColor = [UIColor whiteColor];
    _destructiveActionTextColor = [UIColor whiteColor];

    // Mark as dirty so we can bulk update the button views
    self.isDirty = YES;
    [self setNeedsLayout];
}

- (void)configureViewsForCurrentTheme
{
    // Title label
    self.titleLabel.backgroundColor = self.backgroundColor;
    self.titleLabel.textColor = self.titleColor;

    // Message label
    self.messageLabel.backgroundColor = self.backgroundColor;
    self.messageLabel.textColor = self.messageColor;

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

- (void)sizeToFitInBoundSize:(CGSize)size
{
    CGRect frame = CGRectZero;

    // Width is either the maximum width, or the available size we have
    frame.size.width = MIN(_maximumWidth, size.width);

    // For sizing text, work out the usable width we have
    CGFloat contentWidth = frame.size.width - (_contentInsets.left + _contentInsets.right);
    CGSize contentSize = (CGSize){contentWidth, CGFLOAT_MAX};

    // Work out the height we need to fit every element

    // Top and bottom insets
    frame.size.height += _contentInsets.top + _contentInsets.bottom;

    // Title label size
    frame.size.height += [self.titleLabel sizeThatFits:contentSize].height + _verticalTextSpacing;
    
    // Message label size
    frame.size.height += [self.messageLabel sizeThatFits:contentSize].height + _buttonInsets.top;

    // Work out the number of rows for buttons
    CGFloat buttonWidth = size.width - (_buttonInsets.left + _buttonInsets.right);
    NSInteger numberOfRows = [self numberOfButtonRowsForWidth:buttonWidth];

    // Add button height
    frame.size.height += numberOfRows *_buttonHeight;

    // Add button padding
    frame.size.height += (numberOfRows - 1) * _buttonSpacing.height;

    self.frame = frame;
}

- (NSInteger)numberOfButtonRowsForWidth:(CGFloat)width
{
    // Return none if absolutely no actions are set
    if (!self.defaultAction &&
        !self.cancelAction &&
        !self.destructiveAction &&
        self.actions.count == 0) { return 0; }

    // Work out the maximum number of rows
    NSInteger numberOfRows = self.actions.count;
    if (self.defaultAction) { numberOfRows++; }
    if (self.destructiveAction) { numberOfRows++; }
    if (self.cancelAction) { numberOfRows++; }

    // With padding, the maximum size a button may be
    CGFloat maxWidth = floorf(width - (self.buttonSpacing.width * 0.5f));

    // Until we need it, only the default, cancel and destructive buttons may be placed on the same row
    // Normal actions are always full width

    // Default and cancel exist, and they are both small enough
    if (self.defaultAction && self.cancelAction &&
        self.defaultButton.minimumWidth < maxWidth &&
        self.cancelButton.minimumWidth < maxWidth)
    {
        numberOfRows--;
    }
    else if (self.destructiveAction && self.cancelAction &&
             self.destructiveButton.minimumWidth < maxWidth &&
             self.cancelButton.minimumWidth < maxWidth)
    {
        numberOfRows--;
    }
    else if (self.destructiveAction && self.defaultAction &&
             self.destructiveButton.minimumWidth < maxWidth &&
             self.defaultButton.minimumWidth < maxWidth)
    {
        numberOfRows--;
    }

    return numberOfRows;
}

- (NSArray<TORoundedButton *> *)displayButtons
{
    NSMutableArray *buttons = [NSMutableArray array];
    [buttons addObjectsFromArray:self.buttons];

    // Destructive button, in split is always on the left side
    if (self.destructiveButton) { [buttons addObject:self.destructiveButton]; }

    // Cancel is on the right for destructive, left for default
    if (self.cancelButton) { [buttons addObject:self.cancelButton]; }

    // Add default button (Should be right by default)
    if (self.defaultButton) { [buttons addObject:self.defaultButton]; }

    return buttons;
}

#pragma mark - Layout -

- (void)layoutSubviews
{
    [super layoutSubviews];

    // If necessary, set the new color theme
    if (self.isDirty) {
        [self configureViewsForCurrentTheme];
        self.isDirty = NO;
    }

    // Layout the background
    self.backgroundView.frame = self.bounds;

    // For sizing text, work out the usable width we have
    CGFloat contentWidth = self.bounds.size.width - (_contentInsets.left + _contentInsets.right);
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
    frame.origin.x =_contentInsets.left;
    frame.size.width = contentWidth;
    frame.origin.y = y;
    self.messageLabel.frame = frame;

    y = CGRectGetMaxY(frame) + self.buttonInsets.top;

    // Add any regular buttons
    NSInteger i = 0;
    CGFloat buttonWidth = self.bounds.size.width - (_buttonInsets.left + _buttonInsets.right);
    CGFloat midWidth = floorf((buttonWidth - _buttonSpacing.width) * 0.5f);

    NSArray<TORoundedButton *> *displayButtons = self.displayButtons;
    for (TORoundedButton *button in displayButtons) {
        frame = CGRectZero;
        frame.size.width = contentWidth;
        frame.size.height = _buttonHeight;
        frame.origin.x = _buttonInsets.left;
        frame.origin.y = y;

        // For the second last button, change its width to half if both support it
        if (i == displayButtons.count - 2) {
            if (button.minimumWidth < midWidth && displayButtons[i+1].minimumWidth < midWidth) {
                frame.size.width = midWidth;
            }
        }
        else if (i == displayButtons.count - 1) {
            if (button.minimumWidth < midWidth && displayButtons[i-1].minimumWidth < midWidth) {
                frame.origin.y = displayButtons[i-1].frame.origin.y;
                frame.size.width = midWidth;
                frame.origin.x = self.bounds.size.width - (_buttonInsets.left + midWidth);
            }
        }

        y += _buttonSpacing.height + _buttonHeight;

        button.frame = CGRectIntegral(frame);

        i++;
    }

    // Update the shadow path shape
    _backgroundView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_backgroundView.bounds cornerRadius:_cornerRadius].CGPath;
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

#pragma mark - Action Creation/Deletion -

- (void)setDefaultAction:(TOAlertAction *)defaultAction
{
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

    _defaultButton = [self makeButtonWithTitle:defaultAction.title
                                     textColor:self.defaultActionTextColor
                               backgroundColor:self.tintColor];
    [self addSubview:_defaultButton];
}

- (void)setDestructiveAction:(TOAlertAction *)destructiveAction
{
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

    _destructiveButton = [self makeButtonWithTitle:destructiveAction.title
                                         textColor:self.destructiveActionTextColor
                                   backgroundColor:_destructiveActionButtonColor];
    [self addSubview:_destructiveButton];
}

- (void)setCancelAction:(TOAlertAction *)cancelAction
{
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

    _cancelButton = [self makeButtonWithTitle:cancelAction.title
                                    textColor:self.actionTextColor
                              backgroundColor:_actionButtonColor];
    [self addSubview:_cancelButton];
}

#pragma mark - Color/Theme Accessors -

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundView.backgroundColor = backgroundColor;
}
- (UIColor *)backgroundColor { return self.backgroundView.backgroundColor; }

- (void)setStyle:(TOAlertViewStyle)style
{
    _style = style;
    [self configureColorsForTheme:_style];
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
