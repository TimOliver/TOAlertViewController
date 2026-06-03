//
//  TOAlertMessageTextTests.m
//
//  Copyright 2019-2026 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <XCTest/XCTest.h>
#import "TOAlertMessageText.h"

@interface TOAlertMessageTextTests : XCTestCase
@end

@implementation TOAlertMessageTextTests

#pragma mark - Normalization -

- (void)testNormalizedMessageFillsDefaultFontColorAndAlignment {
    NSAttributedString *source = [[NSAttributedString alloc] initWithString:@"Hello"];
    UIFont *font = [UIFont systemFontOfSize:17.0f];
    NSAttributedString *result = TOAlertNormalizedMessage(source, font, UIColor.redColor,
                                                          UIColor.purpleColor, NSTextAlignmentCenter);

    NSDictionary *attrs = [result attributesAtIndex:0 effectiveRange:NULL];
    XCTAssertEqualObjects(attrs[NSFontAttributeName], font);
    XCTAssertEqualObjects(attrs[NSForegroundColorAttributeName], UIColor.redColor);
    NSParagraphStyle *style = attrs[NSParagraphStyleAttributeName];
    XCTAssertEqual(style.alignment, NSTextAlignmentCenter);
}

- (void)testNormalizedMessagePreservesExplicitColor {
    NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithString:@"AB"];
    [source addAttribute:NSForegroundColorAttributeName value:UIColor.blueColor range:NSMakeRange(0, 1)];
    NSAttributedString *result = TOAlertNormalizedMessage(source, [UIFont systemFontOfSize:17.0f],
                                                          UIColor.redColor, UIColor.purpleColor, NSTextAlignmentLeft);

    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
                          UIColor.blueColor);
    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:NULL],
                          UIColor.redColor);
}

- (void)testNormalizedMessageDefaultsLinkColorToAccent {
    NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithString:@"AB"];
    [source addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"https://example.com"] range:NSMakeRange(0, 1)];
    NSAttributedString *result = TOAlertNormalizedMessage(source, [UIFont systemFontOfSize:17.0f],
                                                          UIColor.redColor, UIColor.purpleColor, NSTextAlignmentLeft);

    // The link range takes the accent color for both text and underline...
    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
                          UIColor.purpleColor);
    XCTAssertEqualObjects([result attribute:NSUnderlineColorAttributeName atIndex:0 effectiveRange:NULL],
                          UIColor.purpleColor);
    // ...while non-link text still gets the default message color.
    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:NULL],
                          UIColor.redColor);
}

- (void)testNormalizedMessagePreservesExplicitLinkColor {
    NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithString:@"AB"];
    [source addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"https://example.com"] range:NSMakeRange(0, 1)];
    [source addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(0, 1)];
    NSAttributedString *result = TOAlertNormalizedMessage(source, [UIFont systemFontOfSize:17.0f],
                                                          UIColor.redColor, UIColor.purpleColor, NSTextAlignmentLeft);

    // A caller-supplied link color wins over the accent default.
    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
                          UIColor.greenColor);
}

#pragma mark - Link hit-testing -

// Build a normalized attributed string with a link over a known substring,
// laid out at a fixed size. Helpers derive hit points from the layout itself so
// the tests don't depend on exact font metrics.
- (TOAlertLinkLayout *)layoutForString:(NSString *)string
                             linkRange:(NSRange)linkRange
                                   URL:(id)URLValue
                                  size:(CGSize)size {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
    [text addAttribute:NSLinkAttributeName value:URLValue range:linkRange];
    NSAttributedString *normalized = TOAlertNormalizedMessage(text, [UIFont systemFontOfSize:17.0f],
                                                              UIColor.blackColor, UIColor.blueColor, NSTextAlignmentLeft);
    return [[TOAlertLinkLayout alloc] initWithAttributedString:normalized
                                                         size:size
                                                numberOfLines:0
                                                lineBreakMode:NSLineBreakByWordWrapping];
}

- (void)testLinkAtPointFindsLink {
    NSString *string = @"Tap Terms here";
    NSRange linkRange = [string rangeOfString:@"Terms"];
    NSURL *URL = [NSURL URLWithString:@"https://example.com/terms"];
    TOAlertLinkLayout *layout = [self layoutForString:string linkRange:linkRange URL:URL size:CGSizeMake(300, 200)];

    NSArray<NSValue *> *rects = [layout enclosingRectsForRange:linkRange];
    XCTAssertGreaterThan(rects.count, 0);
    CGRect rect = rects.firstObject.CGRectValue;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

    TOAlertLink *link = [layout linkAtPoint:center];
    XCTAssertNotNil(link);
    XCTAssertEqualObjects(link.URL, URL);
    XCTAssertTrue(NSEqualRanges(link.range, linkRange));
}

- (void)testLinkAtPointReturnsNilOutsideLink {
    NSString *string = @"Tap Terms here";
    NSRange linkRange = [string rangeOfString:@"Terms"];
    NSURL *URL = [NSURL URLWithString:@"https://example.com/terms"];
    TOAlertLinkLayout *layout = [self layoutForString:string linkRange:linkRange URL:URL size:CGSizeMake(300, 200)];

    // Center of the non-link word "Tap" should not resolve to the link.
    NSRange nonLink = [string rangeOfString:@"Tap"];
    CGRect rect = [layout enclosingRectsForRange:nonLink].firstObject.CGRectValue;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

    XCTAssertNil([layout linkAtPoint:center]);
}

- (void)testLinkAtPointResolvesStringValue {
    NSString *string = @"Tap Terms here";
    NSRange linkRange = [string rangeOfString:@"Terms"];
    // NSLinkAttributeName carrying a plain string rather than an NSURL.
    TOAlertLinkLayout *layout = [self layoutForString:string linkRange:linkRange
                                                  URL:@"https://example.com/terms" size:CGSizeMake(300, 200)];

    CGRect rect = [layout enclosingRectsForRange:linkRange].firstObject.CGRectValue;
    TOAlertLink *link = [layout linkAtPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
    XCTAssertNotNil(link);
    XCTAssertEqualObjects(link.URL.absoluteString, @"https://example.com/terms");
}

@end
