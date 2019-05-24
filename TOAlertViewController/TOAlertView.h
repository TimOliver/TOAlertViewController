//
//  TOAlertView.h
//  TOAlertViewExample
//
//  Created by Tim Oliver on 3/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOAlertViewConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat buttonSpacing;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

@property (nonatomic, assign) TOAlertViewStyle style;

@property (nonatomic, strong, null_resettable) UIColor *titleColor;
@property (nonatomic, strong, null_resettable) UIColor *messageColor;

@property (nonatomic, strong, null_resettable) UIColor *defaultActionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *defaultActionTextColor;

@property (nonatomic, strong, null_resettable) UIColor *returnActionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *returnActionTextColor;

@property (nonatomic, strong, null_resettable) UIColor *destructiveActionButtonColor;
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionTextColor;

@end

NS_ASSUME_NONNULL_END
