# Attributed Message Links Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an attributed body message to `TOAlertViewController` with inline tappable links (reported via a block) and a configurable body-text alignment, with an animated rounded highlight on link press.

**Architecture:** A new internal `TOAlertMessageText` utility holds the pure, testable pieces — a TextKit layout wrapper (`TOAlertLinkLayout`) that maps touch points to inline links and computes link rects, plus a `TOAlertNormalizedMessage()` function that fills default styling into a caller's attributed string. `TOAlertView` renders the message through these helpers, hosts a zero-duration long-press recognizer for hit-testing, and animates a `CAShapeLayer` highlight. `TOAlertViewController` exposes `attributedMessage`, `messageTextAlignment`, and `linkTappedHandler` as thin forwarding accessors over its internal `TOAlertView`.

**Tech Stack:** Objective-C, UIKit, TextKit (`NSLayoutManager`/`NSTextStorage`/`NSTextContainer`), Core Animation, XCTest. Single Xcode project `TOAlertViewControllerExample.xcodeproj` containing the framework, example app, and test targets. New files are registered into targets with the `xcodeproj` Ruby gem (already installed).

**Spec:** `docs/superpowers/specs/2026-06-03-attributed-message-links-design.md`

---

## File Structure

- **Create:** `TOAlertViewController/Internal/TOAlertMessageText.h` / `.m` — `TOAlertLink` value object, `TOAlertLinkLayout` TextKit wrapper, and the `TOAlertNormalizedMessage()` styling function. One cohesive responsibility: turning the message model into styled, hit-testable text.
- **Create:** `TOAlertViewControllerTests/TOAlertMessageTextTests.m` — unit tests for the above (the highest-value, most regression-prone logic).
- **Modify:** `TOAlertViewController/Internal/TOAlertView.h` / `.m` — new `attributedMessage`, `messageTextAlignment`, `linkTappedHandler`; route the message label through the helpers; add the press recognizer + highlight layer.
- **Modify:** `TOAlertViewController/TOAlertViewController.h` / `.m` — public `attributedMessage`, `messageTextAlignment`, `linkTappedHandler` forwarding accessors.
- **Modify:** `TOAlertViewControllerExample/ViewController.m` — a "Terms of Service" demo to verify the feature visually.
- **Modify:** `README.md`, `CHANGELOG.md` — document usage and the VoiceOver limitation.

## Conventions for the executor

- **Build/test command** (adjust the simulator name if needed — list options with `xcrun simctl list devices available`):
  ```bash
  xcodebuild test \
    -project TOAlertViewControllerExample.xcodeproj \
    -scheme TOAlertViewControllerExample \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    2>&1 | tail -40
  ```
- **Build-only command** (for tasks verified by compilation + manual run):
  ```bash
  xcodebuild build \
    -project TOAlertViewControllerExample.xcodeproj \
    -scheme TOAlertViewControllerExample \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    2>&1 | tail -40
  ```
- Match the existing code style: `TO` prefix, `NS_ASSUME_NONNULL_BEGIN/END` in headers, 4-space indent, early-return guards.
- The copyright header block at the top of every source file should be copied verbatim from `TOAlertView.m` (lines 1–21) into new files, with the filename updated.

---

### Task 1: TextKit link helper + normalization (`TOAlertMessageText`)

**Files:**
- Create: `TOAlertViewController/Internal/TOAlertMessageText.h`
- Create: `TOAlertViewController/Internal/TOAlertMessageText.m`
- Test: `TOAlertViewControllerTests/TOAlertMessageTextTests.m`

- [ ] **Step 1: Create the header `TOAlertMessageText.h`**

(Prepend the standard copyright block from `TOAlertView.m:1-21`, with the filename line changed to `//  TOAlertMessageText.h`.)

```objc
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
```

- [ ] **Step 2: Create the implementation `TOAlertMessageText.m`**

(Prepend the standard copyright block, filename `//  TOAlertMessageText.m`.)

```objc
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
```

- [ ] **Step 3: Write the failing tests `TOAlertMessageTextTests.m`**

(Prepend the standard copyright block, filename `//  TOAlertMessageTextTests.m`.)

```objc
#import <XCTest/XCTest.h>
#import "TOAlertMessageText.h"

@interface TOAlertMessageTextTests : XCTestCase
@end

@implementation TOAlertMessageTextTests

#pragma mark - Normalization -

- (void)testNormalizedMessageFillsDefaultFontColorAndAlignment {
    NSAttributedString *source = [[NSAttributedString alloc] initWithString:@"Hello"];
    UIFont *font = [UIFont systemFontOfSize:17.0f];
    NSAttributedString *result = TOAlertNormalizedMessage(source, font, UIColor.redColor, NSTextAlignmentCenter);

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
                                                          UIColor.redColor, NSTextAlignmentLeft);

    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL],
                          UIColor.blueColor);
    XCTAssertEqualObjects([result attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:NULL],
                          UIColor.redColor);
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
                                                              UIColor.blackColor, NSTextAlignmentLeft);
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
```

- [ ] **Step 4: Register the three new files in the Xcode project**

The project uses explicit file references, so new files must be added to the targets that compile `TOAlertView.m` (framework + example app), and the helper `.m` plus the test `.m` must be added to the tests target. Run this from the repo root:

```bash
ruby <<'RUBY'
require 'xcodeproj'
proj = Xcodeproj::Project.open('TOAlertViewControllerExample.xcodeproj')

# Find the group + targets that already own TOAlertView.m
view_ref = proj.files.find { |f| f.path && f.path.end_with?('TOAlertView.m') }
raise 'TOAlertView.m reference not found' unless view_ref
group = view_ref.parent
source_targets = proj.targets.select { |t| t.source_build_phase.files_references.include?(view_ref) }

tests = proj.targets.find { |t| t.name == 'TOAlertViewControllerTests' }
raise 'tests target not found' unless tests

# Helper header + implementation, alongside TOAlertView.m in the Internal group
h_ref = group.new_reference('TOAlertViewController/Internal/TOAlertMessageText.h')
m_ref = group.new_reference('TOAlertViewController/Internal/TOAlertMessageText.m')
source_targets.each { |t| t.add_file_references([m_ref]) }
tests.add_file_references([m_ref])   # compile helper into the test bundle

# Test file in the tests group
tests_group = proj.main_group.find_subpath('TOAlertViewControllerTests', true)
test_ref = tests_group.new_reference('TOAlertViewControllerTests/TOAlertMessageTextTests.m')
tests.add_file_references([test_ref])

proj.save
puts "Registered files. Helper targets: #{source_targets.map(&:name).join(', ')} + #{tests.name}"
RUBY
```

Expected: prints `Registered files. Helper targets: TOAlertViewControllerExample, <framework target> + TOAlertViewControllerTests` and exits 0. If a `.h`/`.m` reference path resolves wrong, open the project in Xcode and confirm the files sit in the **Internal** group and have the right target membership before continuing.

- [ ] **Step 5: Run the tests to verify they pass**

Run the test command from *Conventions* above. Expected: the four `TOAlertMessageTextTests` pass (PASS). If the build fails because the new `.m` isn't compiled into the test target, re-check Step 4's target membership.

- [ ] **Step 6: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertMessageText.h \
        TOAlertViewController/Internal/TOAlertMessageText.m \
        TOAlertViewControllerTests/TOAlertMessageTextTests.m \
        TOAlertViewControllerExample.xcodeproj/project.pbxproj
git commit -m "Add TextKit link helper and message normalization with tests"
```

---

### Task 2: Render attributed message + alignment in `TOAlertView`

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertView.h`
- Modify: `TOAlertViewController/Internal/TOAlertView.m`

This task is verified by compilation; the rendering itself is checked visually in Task 5 (UIKit label rendering is not unit-tested, per the spec).

- [ ] **Step 1: Declare the new properties in `TOAlertView.h`**

Add after the existing `message` property (`TOAlertView.h:33`):

```objc
@property (nonatomic, copy, nullable) NSAttributedString *attributedMessage;
@property (nonatomic, assign) NSTextAlignment messageTextAlignment;
```

Add after the existing `buttonTappedHandler` (`TOAlertView.h:61`):

```objc
@property (nonatomic, copy, nullable) void (^linkTappedHandler)(NSURL *url, NSRange range);
```

- [ ] **Step 2: Import the helper and set the alignment default**

In `TOAlertView.m`, add to the imports (after line 25):

```objc
#import "TOAlertMessageText.h"
```

In `alertViewCommonInit` (`TOAlertView.m:79`), add alongside the other defaults (e.g. after `_buttonInsets = ...;` at line 88):

```objc
    _messageTextAlignment = NSTextAlignmentCenter;
```

- [ ] **Step 3: Route the message label through a single update method**

In `setUpSubviews` (`TOAlertView.m:125-131`), replace the message label's alignment/text lines:

```objc
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.numberOfLines = 0;
    _messageLabel.text = _message;
```

with:

```objc
    _messageLabel.numberOfLines = 0;
    [self updateMessageLabel];
```

Add this method (place it in the `#pragma mark - Presentation Configuration -` area, before `sizeToFitInBoundSize`):

```objc
- (void)updateMessageLabel {
    self.messageLabel.textAlignment = self.messageTextAlignment;
    if (self.attributedMessage) {
        self.messageLabel.attributedText = TOAlertNormalizedMessage(self.attributedMessage,
                                                                    self.messageLabel.font,
                                                                    self.messageColor,
                                                                    self.messageTextAlignment);
    } else {
        self.messageLabel.text = self.message;
    }
}
```

- [ ] **Step 4: Add setters that re-render and re-layout**

Add to `TOAlertView.m` (near the other accessors, e.g. after `setMessageColor:` at line 528):

```objc
- (void)setMessage:(NSString *)message {
    _message = [message copy];
    [self updateMessageLabel];
    [self setNeedsLayout];
}

- (void)setAttributedMessage:(NSAttributedString *)attributedMessage {
    _attributedMessage = [attributedMessage copy];
    [self updateMessageLabel];
    [self setNeedsLayout];
}

- (void)setMessageTextAlignment:(NSTextAlignment)messageTextAlignment {
    if (_messageTextAlignment == messageTextAlignment) { return; }
    _messageTextAlignment = messageTextAlignment;
    [self updateMessageLabel];
    [self setNeedsLayout];
}
```

- [ ] **Step 5: Re-normalize on theme changes**

So an attributed message picks up a new `messageColor` after a light/dark change, add a call at the end of `configureViewsForCurrentTheme` (after the message label block, `TOAlertView.m:198`):

```objc
    [self updateMessageLabel];
```

- [ ] **Step 6: Build to verify it compiles**

Run the build-only command from *Conventions*. Expected: BUILD SUCCEEDED. (Behavior unchanged for existing plain-message alerts: no `attributedMessage`, alignment still defaults to center.)

- [ ] **Step 7: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertView.h TOAlertViewController/Internal/TOAlertView.m
git commit -m "Render attributed message and configurable alignment in TOAlertView"
```

---

### Task 3: Link press detection + animated highlight in `TOAlertView`

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertView.m`

Verified by compilation; the interaction is exercised visually in Task 5.

- [ ] **Step 1: Add private state for the highlight + active link**

In the `TOAlertView ()` class extension (`TOAlertView.m:29-51`), add:

```objc
@property (nonatomic, strong) CAShapeLayer *linkHighlightLayer;
@property (nonatomic, strong, nullable) TOAlertLink *activeLink;
```

- [ ] **Step 2: Enable interaction, add the recognizer and highlight layer**

In `setUpSubviews`, immediately after `[self updateMessageLabel];` (added in Task 2) and before `[self addSubview:_messageLabel];`, add:

```objc
    _messageLabel.userInteractionEnabled = YES;

    _linkHighlightLayer = [CAShapeLayer layer];
    _linkHighlightLayer.opacity = 0.0f;
    [_messageLabel.layer insertSublayer:_linkHighlightLayer atIndex:0];

    UILongPressGestureRecognizer *press =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(messageLabelPressed:)];
    press.minimumPressDuration = 0.0;       // recognise touch-down immediately
    press.cancelsTouchesInView = NO;
    [_messageLabel addGestureRecognizer:press];
```

Note: the highlight is a translucent layer composited above the label's text (a layer's own text content always draws beneath its sublayers); at low alpha it reads as a press tint over the link.

- [ ] **Step 3: Handle the gesture states**

Add to the `#pragma mark - Interaction -` section (after `buttonTappedWithAction:`, `TOAlertView.m:396`):

```objc
- (void)messageLabelPressed:(UILongPressGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.messageLabel];

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            TOAlertLink *link = [self linkAtPointInMessageLabel:point];
            if (link == nil) { self.activeLink = nil; break; }
            self.activeLink = link;
            [self showHighlightForLink:link];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.activeLink == nil) { break; }
            TOAlertLink *link = [self linkAtPointInMessageLabel:point];
            if (link == nil || !NSEqualRanges(link.range, self.activeLink.range)) {
                [self hideHighlight];
                self.activeLink = nil;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            TOAlertLink *link = self.activeLink;
            [self hideHighlight];
            self.activeLink = nil;
            if (link && self.linkTappedHandler) { self.linkTappedHandler(link.URL, link.range); }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self hideHighlight];
            self.activeLink = nil;
            break;
        }
        default: break;
    }
}

- (nullable TOAlertLink *)linkAtPointInMessageLabel:(CGPoint)point {
    return [[self makeLinkLayout] linkAtPoint:point];
}

- (TOAlertLinkLayout *)makeLinkLayout {
    NSAttributedString *text = self.messageLabel.attributedText;
    return [[TOAlertLinkLayout alloc] initWithAttributedString:(text ?: [NSAttributedString new])
                                                         size:self.messageLabel.bounds.size
                                                numberOfLines:self.messageLabel.numberOfLines
                                                lineBreakMode:self.messageLabel.lineBreakMode];
}
```

- [ ] **Step 4: Build the highlight path and animate it**

Add (in the same Interaction section):

```objc
- (void)showHighlightForLink:(TOAlertLink *)link {
    NSArray<NSValue *> *rects = [[self makeLinkLayout] enclosingRectsForRange:link.range];

    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSValue *value in rects) {
        CGRect rect = CGRectInset(value.CGRectValue, -3.0f, -3.0f);   // a little breathing room
        [path appendPath:[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:5.0f]];
    }

    self.linkHighlightLayer.fillColor = [self.tintColor colorWithAlphaComponent:0.2f].CGColor;
    self.linkHighlightLayer.path = path.CGPath;
    [self animateHighlightToOpacity:1.0f];
}

- (void)hideHighlight {
    [self animateHighlightToOpacity:0.0f];
}

- (void)animateHighlightToOpacity:(CGFloat)opacity {
    CALayer *presentation = self.linkHighlightLayer.presentationLayer;
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(presentation ? presentation.opacity : self.linkHighlightLayer.opacity);
    fade.toValue = @(opacity);
    fade.duration = 0.15;
    fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    self.linkHighlightLayer.opacity = opacity;   // set the model value so it sticks
    [self.linkHighlightLayer addAnimation:fade forKey:@"opacity"];
}
```

- [ ] **Step 5: Build to verify it compiles**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertView.m
git commit -m "Detect link presses and animate a rounded highlight in TOAlertView"
```

---

### Task 4: Expose the public API on `TOAlertViewController`

**Files:**
- Modify: `TOAlertViewController/TOAlertViewController.h`
- Modify: `TOAlertViewController/TOAlertViewController.m`

- [ ] **Step 1: Declare the public properties in `TOAlertViewController.h`**

Add after the existing `message` property (`TOAlertViewController.h:39`):

```objc
/** An attributed body message. When set, it takes precedence over `message`.
    Inline links are added by the caller via `NSLinkAttributeName`. */
@property (nullable, nonatomic, copy) NSAttributedString *attributedMessage;

/** The alignment of the body message, plain or attributed. (Default is `NSTextAlignmentCenter`) */
@property (nonatomic, assign) NSTextAlignment messageTextAlignment;

/** Called when the user taps an inline link in `attributedMessage`, with the
    link's `NSURL` (from `NSLinkAttributeName`) and its character range. */
@property (nullable, nonatomic, copy) void (^linkTappedHandler)(NSURL *url, NSRange range);
```

- [ ] **Step 2: Add forwarding accessors in `TOAlertViewController.m`**

Add to the `#pragma mark - Theme Accessors -` neighbourhood (e.g. after the `messageColor` accessors, `TOAlertViewController.m:223`):

```objc
- (void)setAttributedMessage:(NSAttributedString *)attributedMessage {
    self.alertView.attributedMessage = attributedMessage;
}
- (NSAttributedString *)attributedMessage {
    return self.alertView.attributedMessage;
}

- (void)setMessageTextAlignment:(NSTextAlignment)messageTextAlignment {
    self.alertView.messageTextAlignment = messageTextAlignment;
}
- (NSTextAlignment)messageTextAlignment {
    return self.alertView.messageTextAlignment;
}

- (void)setLinkTappedHandler:(void (^)(NSURL *, NSRange))linkTappedHandler {
    self.alertView.linkTappedHandler = linkTappedHandler;
}
- (void (^)(NSURL *, NSRange))linkTappedHandler {
    return self.alertView.linkTappedHandler;
}
```

(No `viewDidLoad` wiring is needed — `linkTappedHandler` is a pure passthrough, unlike `buttonTappedHandler` which needs dismissal logic.)

- [ ] **Step 3: Build to verify it compiles**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewController/TOAlertViewController.h TOAlertViewController/TOAlertViewController.m
git commit -m "Expose attributedMessage, messageTextAlignment and linkTappedHandler"
```

---

### Task 5: Terms of Service demo in the example app

**Files:**
- Modify: `TOAlertViewControllerExample/ViewController.m`

- [ ] **Step 1: Add a button that presents the demo**

Replace `viewDidLoad` (`ViewController.m:18-21`) with:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

    UIButton *tosButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [tosButton setTitle:@"Show Terms of Service" forState:UIControlStateNormal];
    [tosButton addTarget:self action:@selector(showTermsAlert:) forControlEvents:UIControlEventTouchUpInside];
    tosButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tosButton];
    [NSLayoutConstraint activateConstraints:@[
        [tosButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [tosButton.topAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:60.0f]
    ]];
}
```

- [ ] **Step 2: Add the demo presentation method**

Add before the closing `@end` of `ViewController.m`:

```objc
- (void)showTermsAlert:(id)sender {
    NSString *body = @"To continue using this app, you must agree to the new Terms of Service. "
                      "Do you agree to the Terms of Service? If you choose not to agree, the app will close.\n\n"
                      "Terms of Service";
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:body];
    NSRange linkRange = [body rangeOfString:@"Terms of Service" options:NSBackwardsSearch];
    [message addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"https://example.com/terms"] range:linkRange];
    [message addAttribute:NSForegroundColorAttributeName value:UIColor.systemPinkColor range:linkRange];
    [message addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:linkRange];

    TOAlertViewController *alert = [[TOAlertViewController alloc] initWithTitle:@"Terms of Service updated"
                                                                       message:@""];
    alert.attributedMessage = message;
    alert.messageTextAlignment = NSTextAlignmentLeft;
    alert.linkTappedHandler = ^(NSURL *url, NSRange range) {
        NSLog(@"Tapped link: %@", url);
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    };
    alert.defaultAction = [TOAlertAction alertActionWithTitle:@"Agree" action:^{ NSLog(@"Agreed"); }];
    alert.cancelAction = [TOAlertAction alertActionWithTitle:@"Decline" action:^{ NSLog(@"Declined"); }];
    [self presentViewController:alert animated:YES completion:nil];
}
```

- [ ] **Step 3: Build, run, and verify visually**

Run the build-only command (BUILD SUCCEEDED), then launch the app in the simulator (or via Xcode). Tap **Show Terms of Service** and confirm:
- The body text is **left-aligned**.
- "Terms of Service" appears pink + underlined.
- Pressing it shows a **rounded highlight** that fades in/out.
- Releasing on it logs `Tapped link: https://example.com/terms`.
- Pressing then dragging off the link cancels the highlight without logging.

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewControllerExample/ViewController.m
git commit -m "Add Terms of Service link demo to the example app"
```

---

### Task 6: Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add a usage section to `README.md`**

Add a new section (place it after the existing usage/examples section — match the surrounding heading style):

````markdown
### Attributed messages with tappable links

Provide an `NSAttributedString` as the body and embed links with `NSLinkAttributeName`.
Taps are reported back through `linkTappedHandler`; your app decides what to do with the URL.

```objc
NSMutableAttributedString *message = [[NSMutableAttributedString alloc]
    initWithString:@"Please review the Terms of Service before continuing."];
NSRange linkRange = [message.string rangeOfString:@"Terms of Service"];
[message addAttribute:NSLinkAttributeName
                value:[NSURL URLWithString:@"https://example.com/terms"]
                range:linkRange];

TOAlertViewController *alert = [[TOAlertViewController alloc] initWithTitle:@"Terms updated" message:@""];
alert.attributedMessage = message;
alert.messageTextAlignment = NSTextAlignmentLeft;   // default is centered
alert.linkTappedHandler = ^(NSURL *url, NSRange range) {
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
};
```

> **Note:** inline links are detected and highlighted on tap, but VoiceOver does not
> currently expose them as separate accessible elements.
````

- [ ] **Step 2: Add a `CHANGELOG.md` entry**

Add a new entry at the top of the change list, matching the existing format (date `2026-06-03`):

```markdown
- Added `attributedMessage` for rich body text with tappable inline links (reported via `linkTappedHandler`).
- Added `messageTextAlignment` to control body-text alignment.
```

- [ ] **Step 3: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "Document attributed message links and alignment"
```

---

## Self-Review Notes

- **Spec coverage:** alignment (Tasks 2, 4) ✓; attributed message + `NSLinkAttributeName` (Tasks 1–4) ✓; block callback (Tasks 2–4) ✓; precedence of `attributedMessage` over `message` (Task 2, `updateMessageLabel`) ✓; normalization rules (Task 1 `TOAlertNormalizedMessage`) ✓; TextKit hit-testing Approach A (Tasks 1, 3) ✓; rounded animated highlight (Task 3) ✓; no URL-opening in the component — the example opens it, not the library (Task 5) ✓; VoiceOver limitation documented (Task 6) ✓; unit tests for the hit-test helper + normalization (Task 1) ✓; example demo (Task 5) ✓.
- **Type consistency:** `TOAlertLink` (`URL`, `range`), `TOAlertLinkLayout` (`linkAtPoint:`, `enclosingRectsForRange:`), `TOAlertNormalizedMessage(message, font, color, alignment)`, and `linkTappedHandler(NSURL *url, NSRange range)` are used identically across tasks.
- **Known constraint:** the highlight composites above the label's text at low alpha (a layer's own content always draws beneath its sublayers); accepted in the spec for a self-contained, animatable overlay.
```
