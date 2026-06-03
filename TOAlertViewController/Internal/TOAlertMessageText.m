//
//  TOAlertMessageText.m
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

#import "TOAlertMessageText.h"

@implementation TOAlertLink

- (instancetype)initWithURL:(NSURL *)URL range:(NSRange)range {
    if (self = [super init]) {
        _URL = URL;
        _range = range;
    }
    return self;
}

@end

// -------------------------------------------

@interface TOAlertLinkLayout ()
@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, strong) NSLayoutManager *layoutManager;
@property (nonatomic, strong) NSTextContainer *textContainer;
@end

@implementation TOAlertLinkLayout

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                                    size:(CGSize)size
                           numberOfLines:(NSInteger)numberOfLines
                           lineBreakMode:(NSLineBreakMode)lineBreakMode {
    if (self = [super init]) {
        _textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
        _layoutManager = [[NSLayoutManager alloc] init];
        _textContainer = [[NSTextContainer alloc] initWithSize:size];

        // Match how UILabel lays out: no padding, the label's line count and
        // break mode.
        _textContainer.lineFragmentPadding = 0.0f;
        _textContainer.maximumNumberOfLines = numberOfLines;
        _textContainer.lineBreakMode = lineBreakMode;

        [_layoutManager addTextContainer:_textContainer];
        [_textStorage addLayoutManager:_layoutManager];

        // Force layout up front so geometry queries below are valid.
        [_layoutManager ensureLayoutForTextContainer:_textContainer];
    }
    return self;
}

- (nullable TOAlertLink *)linkAtPoint:(CGPoint)point {
    if (self.textStorage.length == 0) { return nil; }

    CGPoint adjusted = [self pointAdjustedForVerticalCentering:point];

    CGFloat fraction = 0.0f;
    NSUInteger glyphIndex = [self.layoutManager glyphIndexForPoint:adjusted
                                                   inTextContainer:self.textContainer
                                    fractionOfDistanceThroughGlyph:&fraction];

    // glyphIndexForPoint clamps to the nearest glyph; reject points that fall
    // beyond the end of the tapped glyph (i.e. past the text entirely).
    if (fraction >= 1.0f) { return nil; }

    NSUInteger charIndex = [self.layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    if (charIndex >= self.textStorage.length) { return nil; }

    NSRange range = NSMakeRange(0, 0);
    id value = [self.textStorage attribute:NSLinkAttributeName
                                   atIndex:charIndex
                            effectiveRange:&range];
    NSURL *URL = [TOAlertLinkLayout URLFromLinkAttributeValue:value];
    if (URL == nil) { return nil; }

    return [[TOAlertLink alloc] initWithURL:URL range:range];
}

- (NSArray<NSValue *> *)enclosingRectsForRange:(NSRange)range {
    NSMutableArray<NSValue *> *rects = [NSMutableArray array];
    NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range
                                                   actualCharacterRange:NULL];
    CGFloat yOffset = [self verticalCenteringOffset];

    [self.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange
                                   withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                                            inTextContainer:self.textContainer
                                                 usingBlock:^(CGRect rect, BOOL *stop) {
        rect.origin.y += yOffset;
        [rects addObject:[NSValue valueWithCGRect:rect]];
    }];

    return rects;
}

// UILabel vertically centers text shorter than its bounds. Apply the same
// offset so points/rects map into the label's coordinate space.
- (CGFloat)verticalCenteringOffset {
    CGRect usedRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
    CGFloat slack = self.textContainer.size.height - usedRect.size.height;
    return MAX(0.0f, slack * 0.5f);
}

- (CGPoint)pointAdjustedForVerticalCentering:(CGPoint)point {
    return CGPointMake(point.x, point.y - [self verticalCenteringOffset]);
}

// NSLinkAttributeName values may be an NSURL or an NSString per Apple's docs.
+ (nullable NSURL *)URLFromLinkAttributeValue:(nullable id)value {
    if ([value isKindOfClass:[NSURL class]]) { return (NSURL *)value; }
    if ([value isKindOfClass:[NSString class]]) { return [NSURL URLWithString:(NSString *)value]; }
    return nil;
}

@end

// -------------------------------------------

NSAttributedString *TOAlertNormalizedMessage(NSAttributedString *message,
                                             UIFont *defaultFont,
                                             UIColor *defaultColor,
                                             UIColor *linkColor,
                                             NSTextAlignment alignment) {
    NSMutableAttributedString *result = [message mutableCopy];
    NSRange fullRange = NSMakeRange(0, result.length);
    if (fullRange.length == 0) { return result; }

    [result beginEditing];

    // Fill in the default font where none is set.
    [result enumerateAttribute:NSFontAttributeName inRange:fullRange options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value == nil) { [result addAttribute:NSFontAttributeName value:defaultFont range:range]; }
    }];

    // Inline links default to the accent color for both their text and their
    // underline, unless the caller specified their own. This runs before the
    // generic color fill below so links don't pick up the plain message color.
    [result enumerateAttribute:NSLinkAttributeName inRange:fullRange options:0
                    usingBlock:^(id link, NSRange linkRange, BOOL *stop) {
        if (link == nil) { return; }
        [result enumerateAttribute:NSForegroundColorAttributeName inRange:linkRange options:0
                        usingBlock:^(id value, NSRange range, BOOL *s) {
            if (value == nil) { [result addAttribute:NSForegroundColorAttributeName value:linkColor range:range]; }
        }];
        [result enumerateAttribute:NSUnderlineColorAttributeName inRange:linkRange options:0
                        usingBlock:^(id value, NSRange range, BOOL *s) {
            if (value == nil) { [result addAttribute:NSUnderlineColorAttributeName value:linkColor range:range]; }
        }];
    }];

    // Fill in the default color where none is set.
    [result enumerateAttribute:NSForegroundColorAttributeName inRange:fullRange options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value == nil) { [result addAttribute:NSForegroundColorAttributeName value:defaultColor range:range]; }
    }];

    // Apply alignment only to ranges that carry no paragraph style of their own.
    [result enumerateAttribute:NSParagraphStyleAttributeName inRange:fullRange options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value == nil) {
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            style.alignment = alignment;
            [result addAttribute:NSParagraphStyleAttributeName value:style range:range];
        }
    }];

    [result endEditing];
    return result;
}
