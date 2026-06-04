//
//  TOAlertViewControllerTests.m
//  TOAlertViewControllerTests
//
//  Created by Tim Oliver on 25/6/19.
//  Copyright © 2019-2026 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "TOAlertAction.h"
#import "TOAlertView.h"

@interface TOAlertViewControllerTests : XCTestCase

@end

@implementation TOAlertViewControllerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testActionContentViewDefaultsToNil {
    TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:@"Call" action:nil];
    XCTAssertNil(action.contentView);
}

- (void)testActionStoresContentView {
    UIView *view = [[UIView alloc] init];
    TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:@"Call" action:nil];
    action.contentView = view;
    XCTAssertEqual(action.contentView, view);
}

- (void)testContentViewDoesNotAffectEquality {
    TOAlertAction *a = [[TOAlertAction alloc] initWithTitle:@"Call" action:nil];
    TOAlertAction *b = [[TOAlertAction alloc] initWithTitle:@"Call" action:nil];
    a.contentView = [[UIView alloc] init];
    XCTAssertTrue([a isEqualToAlertAction:b]);
}

- (void)testCustomContentViewIsRenderedInHierarchy {
    UIView *custom = [[UIView alloc] init];
    TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:@"Call" action:nil];
    action.contentView = custom;

    TOAlertView *alertView = [[TOAlertView alloc] initWithTitle:@"Title" message:@"Message"];
    [alertView addAction:action];

    XCTAssertTrue([custom isDescendantOfView:alertView],
                  @"The action's contentView should be placed inside the alert view's button.");
}

- (void)testCustomContentButtonUsesTitleAsAccessibilityLabel {
    UIView *custom = [[UIView alloc] init];
    TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:@"Call 988" action:nil];
    action.contentView = custom;

    TOAlertView *alertView = [[TOAlertView alloc] initWithTitle:@"Title" message:@"Message"];
    [alertView addAction:action];

    UIView *ancestor = custom.superview;
    while (ancestor && ![NSStringFromClass(ancestor.class) isEqualToString:@"TORoundedButton"]) {
        ancestor = ancestor.superview;
    }
    XCTAssertNotNil(ancestor, @"Expected a TORoundedButton ancestor for the custom content view.");
    XCTAssertEqualObjects(ancestor.accessibilityLabel, @"Call 988");
}

@end
