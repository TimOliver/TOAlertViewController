//
//  TOAlertViewController.h
//
//  Copyright 2019-2026  Timothy Oliver. All rights reserved.
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

#if __has_include(<TOAlertViewController/TOAlertAction.h>)
#import <TOAlertViewController/TOAlertAction.h>
#else
#import "TOAlertAction.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertViewController : UIViewController

/** The title text displayed along the top of the alert. */
@property (nullable, nonatomic, copy) NSString *title;

/** A message displayed under the title, typically to advise the user on what choices they have. */
@property (nullable, nonatomic, copy) NSString *message;

/** An attributed body message. When set, it takes precedence over `message`.
    Inline links are also possible using `NSLinkAttributeName`. */
@property (nullable, nonatomic, copy) NSAttributedString *attributedMessage;

/** The alignment of the body message, plain or attributed. (Default is `NSTextAlignmentCenter`) */
@property (nonatomic, assign) NSTextAlignment messageTextAlignment;

/** Called when the user taps an inline link in `attributedMessage`, with the
    link's `NSURL` (from `NSLinkAttributeName`) and its character range. */
@property (nullable, nonatomic, copy) void (^linkTappedHandler)(NSURL *url, NSRange range);

/** The maximum width this controller may expand to on larger screens. (Default is 375.0f) */
@property (nonatomic, assign) CGFloat maximumWidth;

/** The corner radius amount for the corners of the alert view (Default is 30) */
@property (nonatomic, assign) CGFloat cornerRadius;

/** The corner radius of the buttons (default is 15.0f) */
@property (nonatomic, assign) CGFloat buttonCornerRadius;

/** The vertical spacing between the title and message labels (Default is 11) */
@property (nonatomic, assign) CGFloat verticalTextSpacing;

/** The spacing between horizontally and vertically aligned buttons (Default is 8 both ways) */
@property (nonatomic, assign) CGSize buttonSpacing;

/** The height of the buttons (Default is 50) */
@property (nonatomic, assign) CGFloat buttonHeight;

/** The insets of the content from the edge of the alert view. (Default is {23, 25, 17, 25}) */
@property (nonatomic, assign) UIEdgeInsets contentInsets;

/** The insets of the region containing the buttons (Default is {28, 17, 0, 17.}) */
@property (nonatomic, assign) UIEdgeInsets buttonInsets;

/** The list of regular actions added to this controller */
@property (nonatomic, readonly) NSArray<TOAlertAction *> *actions;

/** A default action, which will use the same tint color as the app. Pressing 'Return' on a keyboard will trigger this action. Set to nil to remove it. */
@property (nonatomic, strong, nullable) TOAlertAction *defaultAction;

/** A cancel action, which by default will always close the dialog when tapped. Pressing Command-. on a keyboard will trigger it. Set to nil to remove it. */
@property (nonatomic, strong, nullable) TOAlertAction *cancelAction;

/** A destructive action, colored red indicating this operation will perform something irreversible. Set to nil to remove it. */
@property (nonatomic, strong, nullable) TOAlertAction *destructiveAction;

/** The color of the title text (Default follows the system label color, adapting to light and dark mode) */
@property (nonatomic, strong, null_resettable) UIColor *titleColor UI_APPEARANCE_SELECTOR;

/** The color of the message text (Default follows the system label color, adapting to light and dark mode) */
@property (nonatomic, strong, null_resettable) UIColor *messageColor UI_APPEARANCE_SELECTOR;

/** The background color of the default action button */
@property (nonatomic, strong, null_resettable) UIColor *actionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default action button text */
@property (nonatomic, strong, null_resettable) UIColor *actionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the return action button */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default return button text */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the destructive action button */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default destructive button text */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionTextColor UI_APPEARANCE_SELECTOR;

/**
 Create a new instance of alert view with just a title.

 @param title The title text that will be displayed along the top
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title;

/**
 Create a new instance of alert view with the supplied title and message.

 @param title The title text that will be displayed along the top
 @param message The message text displayed under the title
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 Create a new instance of alert view with the supplied title and an attributed
 message. Inline links may be embedded via `NSLinkAttributeName`.

 @param title The title text that will be displayed along the top
 @param attributedMessage The attributed message displayed under the title
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title attributedMessage:(NSAttributedString *)attributedMessage;

/** The designated initializer (inherited from `UIViewController`). The `initWithTitle:` family above are conveniences over this. */
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

/** Unavailable — alerts are created programmatically, not from a storyboard or nib. */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/** Adds a new regular action to the new alert view controller */
- (void)addAction:(TOAlertAction *)action;

/** Removes a specific action from the alert controller  */
- (void)removeAction:(TOAlertAction *)action;

/** Removes a regular action at a specific index */
- (void)removeActionAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

//! Project version number for TOAlertViewControllerFramework.
FOUNDATION_EXPORT double TOAlertViewControllerVersionNumber;

//! Project version string for TOAlertViewControllerFramework.
FOUNDATION_EXPORT const unsigned char TOAlertViewControllerVersionString[];
