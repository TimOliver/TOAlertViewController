//
//  TOAlertView.h
//  TOAlertViewExample
//
//  Created by Tim Oliver on 3/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOAlertViewConstants.h"

@class TOAlertAction;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface TOAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat buttonCornerRadius;
@property (nonatomic, assign) CGFloat buttonSpacing;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

@property (nonatomic, assign) TOAlertViewStyle style;

@property (nonatomic, strong, null_resettable) UIColor *titleColor;
@property (nonatomic, strong, null_resettable) UIColor *messageColor;

@property (nonatomic, strong, null_resettable) UIColor *actionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *actionTextColor;

@property (nonatomic, strong, null_resettable) UIColor *defaultActionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *defaultActionTextColor;

@property (nonatomic, strong, null_resettable) UIColor *destructiveActionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionTextColor;

@property (nonatomic, readonly) NSArray<TOAlertAction *> *actions;
@property (nonatomic, strong, nullable) TOAlertAction *defaultAction;
@property (nonatomic, strong, nullable) TOAlertAction *destructiveAction;
@property (nonatomic, strong, nullable) TOAlertAction *cancelAction;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

- (void)sizeToFitInBoundSize:(CGSize)size;

- (void)addAction:(TOAlertAction *)action;
- (void)removeAction:(TOAlertAction *)action;
- (void)removeActionAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
