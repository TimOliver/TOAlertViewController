//
//  TOAlertDimmingView.h
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 31/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOAlertDimmingView : UIView

- (void)playFadeInAnimationWithDuration:(NSTimeInterval)duration;
- (void)playFadeOutAnimationWithDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
