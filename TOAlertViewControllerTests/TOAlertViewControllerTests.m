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

- (void)testCustomContentRowGrowsToFitContentHeight {
    UIView *(^makeRow)(CGFloat) = ^UIView *(CGFloat height) {
        UIView *row = [[UIView alloc] init];
        row.translatesAutoresizingMaskIntoConstraints = NO; // measured via Auto Layout
        [row.heightAnchor constraintEqualToConstant:height].active = YES;
        return row;
    };

    TOAlertView *(^makeAlert)(CGFloat) = ^TOAlertView *(CGFloat rowHeight) {
        TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:@"Resource" action:nil];
        action.contentView = makeRow(rowHeight);
        TOAlertView *alert = [[TOAlertView alloc] initWithTitle:@"Title" message:@"Message"];
        [alert addAction:action];
        [alert sizeToFitInBoundSize:CGSizeMake(375.0f, 2000.0f)];
        return alert;
    };

    CGFloat shortHeight = CGRectGetHeight(makeAlert(40.0f).frame);
    CGFloat tallHeight = CGRectGetHeight(makeAlert(160.0f).frame);
    XCTAssertGreaterThan(tallHeight - shortHeight, 100.0f,
                         @"A 120pt-taller content view should make the alert ~120pt taller.");
}

- (void)testCustomContentButtonIsFullWidth {
    TOAlertView *alert = [[TOAlertView alloc] initWithTitle:@"Title" message:@"Message"];
    NSMutableArray<UIView *> *rows = [NSMutableArray array];
    for (NSInteger i = 0; i < 2; i++) {
        UIView *row = [[UIView alloc] init];
        row.translatesAutoresizingMaskIntoConstraints = NO; // measured via Auto Layout
        [row.heightAnchor constraintEqualToConstant:60.0f].active = YES;
        [rows addObject:row];
        TOAlertAction *action = [[TOAlertAction alloc] initWithTitle:[NSString stringWithFormat:@"Row %ld", (long)i] action:nil];
        action.contentView = row;
        [alert addAction:action];
    }

    [alert sizeToFitInBoundSize:CGSizeMake(375.0f, 2000.0f)];
    [alert layoutIfNeeded];

    UIView *button0 = rows[0].superview;
    UIView *button1 = rows[1].superview;
    while (button0 && ![NSStringFromClass(button0.class) isEqualToString:@"TORoundedButton"]) button0 = button0.superview;
    while (button1 && ![NSStringFromClass(button1.class) isEqualToString:@"TORoundedButton"]) button1 = button1.superview;

    XCTAssertNotNil(button0);
    XCTAssertNotNil(button1);
    XCTAssertNotEqualWithAccuracy(CGRectGetMinY(button0.frame), CGRectGetMinY(button1.frame), 1.0f);
    XCTAssertEqualWithAccuracy(CGRectGetWidth(button0.frame), CGRectGetWidth(button1.frame), 1.0f);
}

- (void)testPlainTextButtonSizingUnchanged {
    TOAlertView *alert = [[TOAlertView alloc] initWithTitle:@"Title" message:@"Message"];
    [alert addAction:[[TOAlertAction alloc] initWithTitle:@"OK" action:nil]];
    [alert sizeToFitInBoundSize:CGSizeMake(375.0f, 2000.0f)];
    XCTAssertGreaterThan(CGRectGetHeight(alert.frame), 0.0f);
}

@end
