//
//  AppDelegate.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 24/5/19.
//  Copyright © 2019-2026 Tim Oliver. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

#pragma mark - UISceneSession Lifecycle -

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

@end
