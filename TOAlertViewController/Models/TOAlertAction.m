//
//  TOAlertAction.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertAction.h"

@implementation TOAlertAction

+ (instancetype)actionWithTitle:(NSString *)title action:(void (^)(void))action
{
    TOAlertAction *alertAction = [[TOAlertAction alloc] init];
    alertAction.title = title;
    alertAction.action = action;
    return alertAction;
}

@end
