//
//  TOAlertView.h
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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
#import "TOAlertViewConstants.h"

@class TOAlertAction;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface TOAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat buttonCornerRadius;
@property (nonatomic, assign) CGSize buttonSpacing;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) UIEdgeInsets buttonInsets;
@property (nonatomic, assign) CGFloat maximumWidth;
@property (nonatomic, assign) UIEdgeInsets contentInsets;
@property (nonatomic, assign) CGFloat verticalTextSpacing;

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

@property (nonatomic, copy) void (^buttonTappedHandler)(void (^)(void));

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

- (void)sizeToFitInBoundSize:(CGSize)size;

- (void)addAction:(TOAlertAction *)action;
- (void)removeAction:(TOAlertAction *)action;
- (void)removeActionAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
