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

@end

NS_ASSUME_NONNULL_END
