# TOAlertViewController — Attributed message with tappable links + configurable alignment

**Date:** 2026-06-03
**Status:** Approved (design)

## Summary

Add the ability to set an attributed body message on `TOAlertViewController`, with
inline tappable links (e.g. a "Terms of Service" link), and make the body text
alignment configurable. Link taps are reported to the host app through a new
delegate protocol; the host app decides what to do with the tapped URL. Tapping a
link shows an animated rounded highlight as pressed-state feedback.

The motivating use case is a "Terms of Service updated" dialog with a left-aligned
body paragraph and an inline, tappable "Terms of Service" link.

## Goals

1. **Configurable body alignment** — expose `messageTextAlignment`, defaulting to the
   current centered look so existing consumers are unaffected.
2. **Attributed body message** — expose `attributedMessage` (`NSAttributedString`).
   Inline link URLs are carried via the standard `NSLinkAttributeName` attribute.
3. **Tappable links via delegate** — a `TOAlertViewControllerDelegate` protocol
   reports the tapped `NSURL` and its `NSRange`. The component does **not** open URLs
   itself; the host app decides (Safari, in-app web view, analytics, etc.).
4. **Pressed-state feedback** — an animated rounded highlight overlay behind the
   tapped link's glyph rect(s).

## Non-goals

- The component will **not** open URLs itself (no `UIApplication openURL:` / Safari
  inside the library).
- **VoiceOver link accessibility** (exposing the inline link as its own accessible
  element) is a documented follow-up, not part of this work. See *Known limitations*.
- No block-based callback — delegate only (decided during brainstorming).

## Decisions (from brainstorming)

| Question | Decision |
|----------|----------|
| Link behavior | Tappable; host app handles the URL |
| How the URL is set | Baked into `attributedMessage` via `NSLinkAttributeName` |
| Callback style | Delegate protocol (not a block) |
| Default alignment | `NSTextAlignmentCenter` (preserve current look) |
| Link detection | Approach A — keep `UILabel`, add TextKit hit-testing |
| Tap feedback | Rounded overlay highlight (animated) |

## Public API (`TOAlertViewController.h`)

```objc
@class TOAlertViewController;

@protocol TOAlertViewControllerDelegate <NSObject>
@optional
/// Called when the user taps an inline link in the attributed message.
/// @param url   The NSURL stored on the tapped range via NSLinkAttributeName.
/// @param range The character range of the tapped link within the attributed message.
- (void)alertViewController:(TOAlertViewController *)alertViewController
           didTapLinkWithURL:(NSURL *)url
                     inRange:(NSRange)range;
@end

@interface TOAlertViewController : UIViewController

/// An attributed body message. When set, it takes precedence over `message`.
/// Inline links are added by the caller via `NSLinkAttributeName`.
@property (nullable, nonatomic, copy) NSAttributedString *attributedMessage;

/// The alignment applied to the body message (plain or attributed).
/// Defaults to `NSTextAlignmentCenter`.
@property (nonatomic, assign) NSTextAlignment messageTextAlignment;

/// Receives link-tap callbacks.
@property (nullable, nonatomic, weak) id<TOAlertViewControllerDelegate> delegate;

@end
```

### Precedence rules

- If `attributedMessage` is non-nil, it is rendered and `message` is ignored.
- If only `message` is set, behavior is unchanged from today.
- `messageTextAlignment` applies in both cases.

## Internal wiring (`TOAlertView`)

`TOAlertView` (internal) gains matching inputs and a callback block, keeping it
decoupled from the public delegate/protocol — the same separation the codebase
already uses for actions.

```objc
// TOAlertView.h (internal)
@property (nullable, nonatomic, copy) NSAttributedString *attributedMessage;
@property (nonatomic, assign) NSTextAlignment messageTextAlignment;
@property (nullable, nonatomic, copy) void (^linkTappedHandler)(NSURL *url, NSRange range);
```

`TOAlertViewController` sets `alertView.linkTappedHandler` to a block that forwards
to `self.delegate alertViewController:didTapLinkWithURL:inRange:` (guarded by
`respondsToSelector:`, since the method is `@optional`).

## Rendering

When `attributedMessage` is set, build a **normalized** mutable copy before assigning
to `messageLabel.attributedText`:

1. For any range missing `NSFontAttributeName`, fill in the label's default body font
   (`UIFontTextStyleBody`, the value currently used at `TOAlertView.m:127`).
2. For any range missing `NSForegroundColorAttributeName`, fill in `messageColor`.
3. If the string has no paragraph style, apply one with `messageTextAlignment` across
   the whole range. (Ranges that already carry a paragraph style are left as the
   caller specified.)

This guarantees consistent default styling while honoring explicit caller attributes.
For the plain-`message` path, set `messageLabel.text` and
`messageLabel.textAlignment = messageTextAlignment` as today.

**Sizing:** no change required. Both `sizeToFitInBoundSize` (`TOAlertView.m:246`) and
`layoutSubviews` (`TOAlertView.m:335`) measure the message via
`[self.messageLabel sizeThatFits:]`, which already accounts for `attributedText`.

## Link detection — Approach A (TextKit hit-testing)

- Set `messageLabel.userInteractionEnabled = YES`.
- Attach a **`UILongPressGestureRecognizer` with `minimumPressDuration = 0`** to the
  label. (A plain tap recognizer can't drive a touch-down highlight; the zero-duration
  long-press gives `Began` / `Changed` / `Ended` / `Cancelled` states.)
- A TextKit helper maps a touch point to a link:
  - Build a throwaway `NSTextStorage` (from the label's `attributedText`) +
    `NSLayoutManager` + `NSTextContainer`.
  - Configure the container to match the label: `lineFragmentPadding = 0`,
    `maximumNumberOfLines = messageLabel.numberOfLines`,
    `lineBreakMode = messageLabel.lineBreakMode`, size = label bounds.
  - Account for vertical centering when the laid-out text is shorter than the label
    bounds (offset the touch point by the used-rect inset).
  - Find the glyph/character index under the point, read `NSLinkAttributeName` via
    `-attribute:atIndex:effectiveRange:`. Return `(NSURL, NSRange)` or `nil`.

### Gesture flow

| State | Action |
|-------|--------|
| `Began` | hit-test → if over a link, animate highlight in, remember the active link |
| `Changed` | finger moved off the active link range → animate highlight out (treat as cancel) |
| `Ended` | still over the active link → fire `linkTappedHandler`; animate highlight out |
| `Cancelled` | animate highlight out, no callback |

When there are no links (plain `message`, or attributed text without
`NSLinkAttributeName`), the hit-test returns `nil` and behavior is identical to today.

## Rounded overlay highlight

- On `Began` over a link, get the link's enclosing rect(s) via
  `-[NSLayoutManager enumerateEnclosingRectsForGlyphRange:withinSelectedGlyphRange:inTextContainer:usingBlock:]`
  (handles a link that wraps across lines).
- Build a rounded `UIBezierPath` from the union of those rects and set it on a
  `CAShapeLayer` inserted behind the label's text.
- Animate `opacity` 0→1 on `Began`, 1→0 on `Ended`/`Cancelled`/off-range `Changed`.
- Default fill: a translucent tint (`tintColor` at low alpha). Could be promoted to an
  appearance-customizable property later; not in scope now.

## Known limitations

- **VoiceOver:** `UILabel` does not expose inline link sub-ranges as separate
  accessible elements, so the link is not independently focusable by VoiceOver. This
  will be documented in the README as a follow-up. Building custom
  `UIAccessibilityElement`s for link ranges is deliberately out of scope (YAGNI).

## Testing

- **Unit test (`TOAlertViewControllerTests`):** the TextKit hit-test helper is pure
  logic — given an `NSAttributedString` with a known link range and a point inside vs.
  outside that range, assert it returns the expected `NSURL`/`NSRange` (or `nil`). This
  is the highest-value, most regression-prone piece.
- **Example app (`TOAlertViewControllerExample`):** add a "Terms of Service updated"
  demo alert with a left-aligned attributed body and an inline tappable "Terms of
  Service" link, wired to the delegate, to verify the highlight animation and tap flow
  visually.
- **Regression:** confirm an existing plain-`message`, centered alert is byte-for-byte
  unchanged.

## Documentation

- Update `README.md` with the attributed-message + delegate usage and the VoiceOver
  limitation note.
- Add a `CHANGELOG.md` entry.
