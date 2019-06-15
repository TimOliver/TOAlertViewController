//
//  ViewController.m
//  TOAlertViewControllerExample
//
//  Created by Tim Oliver on 24/5/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOAlertViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)didTap:(id)sender
{
    TOAlertViewController *alertController = [[TOAlertViewController alloc]
                                              initWithTitle:@"Are you sure?" message:@"This action may take some time to complete. Are you sure you wish to perform this action?"];

    alertController.defaultAction = [TOAlertAction actionWithTitle:@"Yes" action:nil];
    alertController.cancelAction = [TOAlertAction actionWithTitle:@"Cancel" action:nil];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
