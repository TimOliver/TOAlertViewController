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

// Title label color
- (void)setTitleColor:(UIColor *)titleColor { self.alertView.titleColor = titleColor; }
- (UIColor *)titleColor { return self.alertView.titleColor; }

// Message label color
- (void)setMessageColor:(UIColor *)messageColor {self.alertView.messageColor = messageColor; }
- (UIColor *)messageColor { return self.alertView.messageColor; }

// Color of default action button background
- (void)setActionButtonColor:(UIColor *)actionButtonColor
{
    self.alertView.actionButtonColor = actionButtonColor;
}
- (UIColor *)actionButtonColor { return self.alertView.actionButtonColor; }

// Color of default action button text
- (void)setActionTextColor:(UIColor *)actionTextColor
{
    self.alertView.actionTextColor = actionTextColor;
}
- (UIColor *)actionTextColor { return self.alertView.actionTextColor; }

// Color of the default action button background
- (void)setDefaultActionButtonColor:(UIColor *)defaultActionButtonColor
{
    self.alertView.defaultActionButtonColor = defaultActionButtonColor;
}
- (UIColor *)defaultActionButtonColor { return self.alertView.defaultActionButtonColor; }

// Color of the default action button text
- (void)setDefaultActionTextColor:(UIColor *)defaultActionTextColor
{
    self.alertView.defaultActionTextColor = defaultActionTextColor;
}
- (UIColor *)defaultActionTextColor { return self.alertView.defaultActionTextColor; }

// Color of the destruction action button background
- (void)setDestructiveActionButtonColor:(UIColor *)destructiveActionButtonColor
{
    self.alertView.destructiveActionButtonColor = destructiveActionButtonColor;
}
- (UIColor *)destructiveActionButtonColor { return self.alertView.destructiveActionButtonColor; }

// Color of the destructive action button text
- (void)setDestructiveActionTextColor:(UIColor *)destructiveActionTextColor
{
    self.alertView.destructiveActionTextColor = destructiveActionTextColor;
}
- (UIColor *)destructiveActionTextColor { return self.alertView.destructiveActionTextColor; }

@end
