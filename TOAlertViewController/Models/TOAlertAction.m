//
//  TOAlertAction.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertAction.h"

@implementation TOAlertAction

- (instancetype)initWithTitle:(NSString *)title action:(void (^)(void))action
{
    if (self = [super init]) {
        _title = title;
        _action = action;
    }

    return self;
}

+ (instancetype)alertActionWithTitle:(NSString *)title action:(void (^)(void))action
{
    return [[[self class] alloc] initWithTitle:title action:action];
}

@end
