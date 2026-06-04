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

@end
