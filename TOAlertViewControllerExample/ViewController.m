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
                                              initWithTitle:@"Are you sure?" message:@"This action will take some time. Are you sure you wish to complete this action?"];
    [self presentViewController:alertController animated:YES completion:nil];


}

@end
