//
//  TOAlertMessageText.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A resolved inline link: the URL stored via `NSLinkAttributeName` and the
/// character range it occupies within the attributed message.
@interface TOAlertLink : NSObject
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSRange range;
- (instancetype)initWithURL:(NSURL *)URL range:(NSRange)range NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/// A throwaway TextKit stack laid out to match a `UILabel`. Used to map touch
/// points to inline links and to compute the on-screen rects of a link range.
@interface TOAlertLinkLayout : NSObject
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                                    size:(CGSize)size
                           numberOfLines:(NSInteger)numberOfLines
                           lineBreakMode:(NSLineBreakMode)lineBreakMode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// The link located under `point` (in the label's coordinate space), or nil if
/// no `NSLinkAttributeName` is present at that location.
- (nullable TOAlertLink *)linkAtPoint:(CGPoint)point;

/// The bounding rects (NSValue-wrapped CGRects) enclosing `range`, one per line
/// the range spans, in the label's coordinate space.
- (NSArray<NSValue *> *)enclosingRectsForRange:(NSRange)range;
@end

/// Builds a display-ready copy of `message`, filling in `defaultFont` and
/// `defaultColor` for any unstyled range and applying `alignment` where no
/// paragraph style is set. Caller-supplied attributes are preserved.
FOUNDATION_EXPORT NSAttributedString *TOAlertNormalizedMessage(NSAttributedString *message,
                                                              UIFont *defaultFont,
                                                              UIColor *defaultColor,
                                                              NSTextAlignment alignment);

NS_ASSUME_NONNULL_END
