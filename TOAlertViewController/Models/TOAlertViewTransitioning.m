//
//  TOAlertViewTransitioning.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 22/6/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertViewTransitioning.h"

#import "TOAlertView.h"
#import "TOAlertDimmingView.h"

@interface TOAlertViewTransitioning ()

@property (nonatomic, assign) BOOL isReverse;
@property (nonatomic, weak) TOAlertView *alertView;
@property (nonatomic, weak) TOAlertDimmingView *dimmingView;

@end

@implementation TOAlertViewTransitioning

#pragma mark - Class Creation -

- (instancetype)initWithAlertView:(TOAlertView *)alertView dimmingView:(TOAlertDimmingView *)dimmingView reverse:(BOOL)reverse
{
    if (self = [super init]) {
        _isReverse = reverse;
        _alertView = alertView;
        _dimmingView = dimmingView;
    }

    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning Implementation -

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    // Play the transition twice as fast when dismissing so we can give control back to the user ASAP
    return self.isReverse ? 0.25f : 0.5f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval duration = [self transitionDuration:transitionContext];

    // Get the target view controller
    UITransitionContextViewControllerKey key = _isReverse ? UITransitionContextFromViewControllerKey : UITransitionContextToViewControllerKey;
    UIViewController *controller = [transitionContext viewControllerForKey:key];

    // Add it to the container
    [transitionContext.containerView addSubview:controller.view];

    // Play the fade in animation for the background
    if (!self.isReverse) {
        [self.dimmingView playFadeInAnimationWithDuration:duration];
    }
    else {
        [self.dimmingView playFadeOutAnimationWithDuration:duration];
    }

    CGFloat zeroAlpha = 0.0f, fullAlpha = 1.0f;
    CGAffineTransform identity = CGAffineTransformIdentity;
    CGAffineTransform scaled = CGAffineTransformScale(CGAffineTransformIdentity, 0.85f, 0.85f);

    // Fade in the alert view
    if (!self.isReverse) {
        self.alertView.alpha = zeroAlpha;
        self.alertView.transform = scaled;
    }

    // Animate the alert view zooming in
    [UIView animateWithDuration:duration
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:2.0f
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.alertView.alpha = self.isReverse ? zeroAlpha : fullAlpha;
                         self.alertView.transform = self.isReverse ? scaled : identity;
                     } completion:^(BOOL finished) {
                         [transitionContext completeTransition:finished];
                     }];
}

@end
