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

@end
