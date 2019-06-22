//
//  TOAlertViewTransitioning.h
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 22/6/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TOAlertView;
@class TOAlertDimmingView;

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertViewTransitioning : NSObject<UIViewControllerAnimatedTransitioning>
- (instancetype)initWithAlertView:(TOAlertView *)alertView dimmingView:(TOAlertDimmingView *)dimmingView reverse:(BOOL)reverse;
@end

NS_ASSUME_NONNULL_END
