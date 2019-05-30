//
//  TOAlertViewController.h
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TOAlertViewConstants.h"
#import "TOAlertAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertViewController : UIViewController

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

/** The list of regular actions added to this controller */
@property (nonatomic, readonly) NSArray *actions;

/** A default action, which will use the same tint color as the app. Pressing 'Return' on a keyboard will trigger this action. */
@property (nonatomic, strong) TOAlertAction *defaultAction;

/** A cancel action, which by default will always close the dialog when tapped. Pressing Command-. on a keyboard will trigger it. */
@property (nonatomic, strong) TOAlertAction *cancelAction;

/** A destructive action, colored red indicatinf this operation will perform something irreversible. */
@property (nonatomic, strong) TOAlertAction *destructiveAction;

/** The visual style of the alert view; light or dark. Setting this will configure all views to default settings. */
@property (nonatomic, assign) TOAlertViewStyle style UI_APPEARANCE_SELECTOR;

/** The color of the title text (Default is black in light mode, white in dark mode) */
@property (nonatomic, strong, null_resettable) UIColor *titleColor UI_APPEARANCE_SELECTOR;

/** The color of the message text (Default is black in light mode, white in dark mode) */
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
 Create a new instance of alert view with the supplied title and message.

 @param title The title text that will be displayed along the top
 @param message The message text displayed under the title
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;


/** Adds a new regular action to the new alert view controller */
- (void)addAction:(TOAlertAction *)action;

/** Removes a specific action from the alert controller  */
- (void)removeAction:(TOAlertAction *)action;

/** Removes a regular action at a specific index */
- (void)removeActionAtIndex:(NSUInteger)index;

/** Sets a default action that will be tinted to the app tint color.
    Pressing return on an attacked keyboard will also trigger it.
 */
- (void)setDefaultAction:(nullable TOAlertAction *)action;

/** Sets a cancel action that by default will close the dialog.
 Pressing Command-. on an attacked keyboard will also trigger it.
 */
- (void)setCancelButton:(nullable TOAlertAction *)action;

/** Sets a red colored button denoting an irreversible operation will occur.
 */
- (void)setDestructiveAction:(nullable TOAlertAction *)action;

@end

NS_ASSUME_NONNULL_END
