//
//  TOAlertViewController.h
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOAlertAction.h"
#import "TOAlertViewConstants.h"

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

/**
 Create a new instance of alert view with the supplied title and message.

 @param title The title text that will be displayed along the top
 @param message The message text displayed under the title
 @return A new instance of TOAlertView
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
