//
//  TOAlertAction.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A model object representing a single button in an alert view controller: its
/// title and the action performed when the user taps it.
NS_SWIFT_NAME(AlertAction)
@interface TOAlertAction : NSObject

/// The title text displayed for this action.
@property (nonatomic, copy) NSString *title;

/// The block executed when the user taps this button.
@property (nonatomic, copy, nullable) void (^action)(void);

/// Initializes a new alert action with the provided title and action block.
/// - Parameters:
///   - title: The title displayed in the button.
///   - action: The block triggered when the user taps the button.
- (instancetype)initWithTitle:(NSString *)title
                       action:(nullable void (^)(void))action NS_DESIGNATED_INITIALIZER;

/// Creates a new alert action with the provided title and action block.
/// - Parameters:
///   - title: The title displayed in the button.
///   - action: The block triggered when the user taps the button.
+ (instancetype)alertActionWithTitle:(NSString *)title
                              action:(nullable void (^)(void))action NS_SWIFT_UNAVAILABLE("Use init(title:action:)");

/// Returns whether the receiver equals `action` by comparing their titles.
/// - Parameter action: The action to compare against.
- (BOOL)isEqualToAlertAction:(nullable TOAlertAction *)action;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
