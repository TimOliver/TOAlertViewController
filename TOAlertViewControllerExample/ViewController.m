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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

    UIButton *tosButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [tosButton setTitle:@"Show Terms of Service" forState:UIControlStateNormal];
    [tosButton addTarget:self action:@selector(showTermsAlert:) forControlEvents:UIControlEventTouchUpInside];
    tosButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tosButton];
    [NSLayoutConstraint activateConstraints:@[
        [tosButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [tosButton.topAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:60.0f]
    ]];
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

- (void)showTermsAlert:(id)sender {
    NSString *body = @"To continue using this app, you must agree to the new Terms of Service. "
                      "Do you agree to the Terms of Service? If you choose not to agree, the app will close.\n\n"
                      "Terms of Service";
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:body];
    NSRange linkRange = [body rangeOfString:@"Terms of Service" options:NSBackwardsSearch];
    [message addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"https://example.com/terms"] range:linkRange];
    [message addAttribute:NSForegroundColorAttributeName value:UIColor.systemPinkColor range:linkRange];
    [message addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:linkRange];

    TOAlertViewController *alert = [[TOAlertViewController alloc] initWithTitle:@"Terms of Service updated"
                                                                       message:@""];
    alert.attributedMessage = message;
    alert.messageTextAlignment = NSTextAlignmentLeft;
    alert.linkTappedHandler = ^(NSURL *url, NSRange range) {
        NSLog(@"Tapped link: %@", url);
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    };
    alert.defaultAction = [TOAlertAction alertActionWithTitle:@"Agree" action:^{ NSLog(@"Agreed"); }];
    alert.cancelAction = [TOAlertAction alertActionWithTitle:@"Decline" action:^{ NSLog(@"Declined"); }];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
