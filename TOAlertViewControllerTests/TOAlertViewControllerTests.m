//
//  TOAlertViewControllerTests.m
//  TOAlertViewControllerTests
//
//  Created by Tim Oliver on 25/6/19.
//  Copyright © 2019-2026 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#if __has_include(<TOAlertViewController/TOAlertViewController.h>)
#import <TOAlertViewController/TOAlertViewController.h>
#endif

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

#if __has_include(<TOAlertViewController/TOAlertViewController.h>)
- (void)testModuleImportsAndInstantiates {
    TOAlertViewController *alert =
        [[TOAlertViewController alloc] initWithTitle:@"Title" message:@"Message"];
    XCTAssertNotNil(alert);
}
#endif

@end
