//
//  TOAlertViewController.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 25/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAlertViewController.h"
#import "TOAlertView.h"
#import "TOAlertDimmingView.h"

@interface TOAlertViewController ()

@property (nonatomic, strong) TOAlertDimmingView *dimmingView;
@property (nonatomic, strong) TOAlertView *alertView;

@end

@implementation TOAlertViewController

#pragma mark - View Controller Creation -

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message
{
    if (self = [super init]) {
        super.title = title;
        _message = [message copy];
        
        [self commonInit];
    }
    
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    self.alertView = [[TOAlertView alloc] initWithTitle:self.title message:self.message];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.dimmingView];
    [self.view addSubview:self.alertView];
}

#pragma mark - Lazy View Accessors -
- (TOAlertDimmingView *)dimmingView
{
    if (_dimmingView) { return _dimmingView; }
    _dimmingView = [[TOAlertDimmingView alloc] initWithFrame:self.view.bounds];
    return _dimmingView;
}

- (TOAlertView *)alertView
{
    if (_alertView) { return _alertView; }
    _alertView = [[TOAlertView alloc] initWithTitle:self.title message:self.message];
    return _alertView;
}

#pragma mark - Accessors -
- (void)setTitleColor:(UIColor *)titleColor {  }

- (void)setMessageColor:(UIColor *)messageColor { }

/** The background color of the default action button */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default action button text */
@property (nonatomic, strong, null_resettable) UIColor *defaultActionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the return action button */
@property (nonatomic, strong, null_resettable) UIColor *returnActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default return button text */
@property (nonatomic, strong, null_resettable) UIColor *returnActionTextColor UI_APPEARANCE_SELECTOR;

/** The background color of the destructive action button */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionButtonColor UI_APPEARANCE_SELECTOR;

/** The color of the default destructive button text */
@property (nonatomic, strong, null_resettable) UIColor *destructiveActionTextColor

@end
