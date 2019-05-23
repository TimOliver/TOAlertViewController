//
//  TOAlertView.h
//  TOAlertViewExample
//
//  Created by Tim Oliver on 3/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TOAlertViewStyle) {
    TOAlertViewStyleDefault,
    TOAlertViewStyleDark
};

// ======================================================

@interface TOAlertViewAction : NSObject

/** The title text that will displayed for this action */
@property (nonatomic, copy) NSString *title;

/** The action that will be executed if the user taps this button */
@property (nonatomic, copy) void (^action)(void);

@end

// ======================================================

@interface TOAlertView : UIView

/** The title text, displayed prominantly along the top of the alert view */
@property (nonatomic, copy) NSString *title;

/** A message displayed under the title, typically to advise the user on what choices they have. */
@property (nonatomic, copy) NSString *message;

/** The corner radius amount for the corners of the alert view (Default is 35) */
@property (nonatomic, assign) CGFloat cornerRadius;

/** The spacing between horizontally aligned buttons (Default is 4) */
@property (nonatomic, assign) CGFloat buttonSpacing;

/** The height of the buttons (Default is 50) */
@property (nonatomic, assign) CGFloat buttonHeight;

/** The insets of the content from the edge of the alert view. (Default is 30.0f, all directions) */
@property (nonatomic, assign) UIEdgeInsets contentInsets;

/** The visual style of the alert view; light or dark. Setting this will configure all views to default settings. */
@property (nonatomic, assign) TOAlertViewStyle style UI_APPEARANCE_SELECTOR;

/** The color of the title text (Default is black in light mode, white in dark mode) */
@property (nonatomic, strong, null_resettable) UIColor *titleColor UI_APPEARANCE_SELECTOR;

/** The color of the message text (Default is black in light mode, white in dark mode) */
@property (nonatomic, strong, null_resettable) UIColor *messageColor UI_APPEARANCE_SELECTOR;

/** The background color of the default action button */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default action button text */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the return action button */
@property (nonatomic, strong, null_resettable) UIColor *returnActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default return button text */
@property (nonatomic, strong, null_resettable) UIColor *returnActionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the destructive action button */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default destructive button text */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionTextColor UI_APPEARANCE_SELECTOR;

/** An array holding all of the default actions that were added to the view, in the order they were added. */
@property (nonatomic, strong, readonly) NSArray *defaultActions;

/** A return button is the default recommended action. Hitting 'Return' on a keyboard will also trigger it */
@property (nonatomic, strong, nullable) TOAlertViewAction *returnAction;

/** A destructive action is a bright red button, denoting tapping it will cause an irreversible action */
@property (nonatomic, strong, nullable) TOAlertViewAction *destructiveAction;

/**
 Create a new instance of alert view with the supplied title and message.

 @param title The title text that will be displayed along the top
 @param message The message text displayed under the title
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

/** Add a button with the normal appearence (Grey background with black text) */
- (void)addDefaultAction:(TOAlertViewAction *)action;

/** Remove a specific action from the view */
- (void)removeDefaultAction:(TOAlertViewAction *)action;

/** Remove a default action, given its index in the array */
- (void)removeDefaultActionAtIndex:(NSUInteger)index;

/** Set a single button that will be the default recommended action (White text on the app tint color) */
- (void)setReturnAction:(nullable TOAlertViewAction *)action;

/** Set a single button that will show in bright red, denoting an action that is dangerous or permanent */
- (void)setDestructiveAction:(nullable TOAlertViewAction *)action;

/** Present the alert view over all other content in the app's default window. */
- (void)show;

@end

NS_ASSUME_NONNULL_END
