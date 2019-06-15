//
//  TOAlertAction.h
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertAction : NSObject

/** The title text that will displayed for this action */
@property (nonatomic, copy) NSString *title;

/** The action that will be executed if the user taps this button */
@property (nonatomic, copy, nullable) void (^action)(void);

/**
 Initializes a new alert action object with the provided title and action block.
 @param title The title that will be displayed in the button
 @param action The block that will be triggered when the user taps on that button
*/
- (instancetype)initWithTitle:(NSString *)title action:(nullable void (^)(void))action;

/**
 Creates a new alert action object with the provided title and action block.
 @param title The title that will be displayed in the button
 @param action The block that will be triggered when the user taps on that button
 */
+ (instancetype)alertActionWithTitle:(NSString *)title action:(nullable void (^)(void))action;

@end

NS_ASSUME_NONNULL_END
