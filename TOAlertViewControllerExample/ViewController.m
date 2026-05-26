//
//  ViewController.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 24/5/19.
//  Copyright © 2019-2026 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOAlertViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *showButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addShowButton];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)didTap:(id)sender {
    TOAlertViewController *alertController = [[TOAlertViewController alloc]
        initWithTitle:@"Are you sure?"
              message:@"This action may take some time to complete. Are you sure you wish to perform this action?"];

    alertController.defaultAction = [TOAlertAction alertActionWithTitle:@"Yes"
                                                                 action:^{ NSLog(@"Default Button Tapped!"); }];
    alertController.cancelAction = [TOAlertAction alertActionWithTitle:@"Cancel"
                                                                action:^{ NSLog(@"Cancel Button Tapped!"); }];
    //    alertController.destructiveAction = [TOAlertAction alertActionWithTitle:@"Delete" action:^{ NSLog(@"Delete Button Tapped!"); }];
    //    [alertController addAction:[TOAlertAction alertActionWithTitle:@"More Info" action:^{ NSLog(@"More info Button Tapped!"); }]];

    // The alert automatically follows the system light/dark appearance.
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Configure Show Button

- (void)addShowButton {
    UIButtonConfiguration *configuration;
    if (@available(iOS 26.0, *)) {
        // Liquid Glass capsule on iOS 26 and above.
        configuration = [UIButtonConfiguration prominentGlassButtonConfiguration];
    } else {
        // Tinted capsule fallback on iOS 15–25.
        configuration = [UIButtonConfiguration filledButtonConfiguration];
    }
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    configuration.buttonSize = UIButtonConfigurationSizeLarge;
    configuration.attributedTitle =
        [[NSAttributedString alloc] initWithString:@"Show Alert"
                                        attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f]}];
    // The configuration title is kept only to size the capsule; hide it (clear),
    // because glass blends its colour with the tint and can't render true white.
    configuration.baseForegroundColor = [UIColor whiteColor];

    UIButton *showButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    [showButton addTarget:self action:@selector(didTap:) forControlEvents:UIControlEventTouchUpInside];
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:showButton];
    _showButton = showButton;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect buttonFrame = CGRectZero;
    buttonFrame.size.height = CGRectGetHeight(_showButton.frame);
    buttonFrame.size.width = 300.0f;
    buttonFrame.origin.y = CGRectGetMidY(self.view.bounds) - (buttonFrame.size.height * 0.5);
    buttonFrame.origin.x = CGRectGetMidX(self.view.bounds) - 150.0f;
    _showButton.frame = buttonFrame;
}

@end
