# Modern Objective-C Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the entire TOAlertViewController library to match the modern Objective-C conventions of TORoundedButton (Tim Oliver's house style) and IGListKit, with no behavior change.

**Architecture:** A pure, behavior-preserving style refactor. A shared `Internal/TOAlertMacros.h` introduces a feature-guarded `objc_direct` macro; every file is brought to a single convention set (below). `TOAlertAction` is hardened into a proper value object. Public types gain `NS_SWIFT_NAME` to drop the `TO` prefix in Swift.

**Tech Stack:** Objective-C, UIKit, XCTest. Single Xcode project `TOAlertViewControllerExample.xcodeproj` (framework + example + tests). `xcodeproj` Ruby gem available for registering new files. SPM `Package.swift` present.

---

## Conventions (the spec — apply uniformly)

1. **Doc comments:** `///` DocC style on every public/interesting declaration (TORoundedButton style). Convert existing `/** … */` API doc blocks to `///`. Keep defaults-in-parens, e.g. `/// The corner radius of the alert view. (Default is 30.0)`. `/** … */` is acceptable only for inline ivar/section notes inside `.m` files. Internal helper headers keep their existing `/// :nodoc:` markers.
2. **Property attribute order:** `(nonatomic, <memory>, <nullability>, readonly/readwrite)` — e.g. `(nonatomic, copy, nullable)`, `(nonatomic, strong, null_resettable)`, `(nonatomic, assign)`. `assign` always explicit for scalars/structs.
3. **`objc_direct` on private helpers ONLY.** Apply `TOALERT_OBJC_DIRECT` (defined in Task 1) to private methods that are: defined by us, called only via `[self _foo]`, and **never** (a) an override of a UIKit/NSObject method, (b) a protocol method, (c) a property accessor, or (d) referenced by `@selector`/target-action/notification/KVO. Each file task lists its eligible methods explicitly.
4. **Leading-underscore private method names** (TORoundedButton style): rename private helper methods to `_camelCase`. When a renamed method is referenced by `@selector(...)` (e.g. gesture/notification targets), update the selector too — and such methods are NOT marked `objc_direct` (see rule 3).
5. **`*const` locals:** mark local variables that are never reassigned as `const` (e.g. `UIView *const backdrop = …;`, `const CGFloat duration = …;`). Do not const-qualify a local that is later mutated.
6. **`static inline` C helpers** for small pure predicates/utilities, prefixed `TOAlert`.
7. **`NS_SWIFT_NAME`** on the two public types to drop the `TO` prefix for Swift: `TOAlertViewController` → `AlertViewController`, `TOAlertAction` → `AlertAction`. Internal classes (`TOAlertView`, `TOAlertDimmingView`, etc.) are not public API and keep their names.
8. **License header:** keep the existing `//`-style banner unchanged in every file.
9. Preserve `instancetype`, the `if (self = [super init…]) { … } return self;` idiom, K&R braces, 4-space indent, and one-line guard clauses already in use.

## Verification commands

- **Build:** `xcodebuild build -project TOAlertViewControllerExample.xcodeproj -scheme TOAlertViewControllerExample -destination 'platform=iOS Simulator,name=iPhone 16e' 2>&1 | tail -3`
- **Test:** same with `test` instead of `build`. Expected: `** TEST SUCCEEDED **` (8 `TOAlertLinkLayoutTests` + 1 example test).
- Commit messages must NOT include a `Co-Authored-By` trailer.

---

### Task 0: Branch

- [ ] **Step 1: Create the working branch**

```bash
cd /Users/TiM/Developer/TOAlertViewController
git fetch origin
git checkout -b modern-objc-refinement origin/master
```

Expected: a clean branch off the latest `master` (which now contains the merged Swift work).

---

### Task 1: Shared `objc_direct` macro

**Files:**
- Create: `TOAlertViewController/Internal/TOAlertMacros.h`

- [ ] **Step 1: Create the macro header** (prepend the standard license banner from `TOAlertView.h:1-21`, filename `//  TOAlertMacros.h`):

```objc
#ifndef TOAlertMacros_h
#define TOAlertMacros_h

/// Marks a method as direct-dispatch (https://nshipster.com/direct/) where the
/// toolchain supports it, falling back to normal dispatch otherwise. Apply only
/// to private helpers that are never overridden, used as a selector, or accessed
/// dynamically.
#if defined(__has_attribute) && __has_attribute(objc_direct)
#define TOALERT_OBJC_DIRECT __attribute__((objc_direct))
#else
#define TOALERT_OBJC_DIRECT
#endif

#endif /* TOAlertMacros_h */
```

- [ ] **Step 2: Register the header in the Xcode project** (so it appears in the Internal group; headers need no target membership to be imported, but keep navigation consistent):

```bash
cd /Users/TiM/Developer/TOAlertViewController
ruby <<'RUBY'
require 'xcodeproj'
proj = Xcodeproj::Project.open('TOAlertViewControllerExample.xcodeproj')
view_ref = proj.files.find { |f| f.path && f.path.end_with?('TOAlertView.m') }
group = view_ref.parent
group.new_reference('TOAlertMacros.h') unless proj.files.any? { |f| f.path && f.path.end_with?('TOAlertMacros.h') }
proj.save
puts 'registered TOAlertMacros.h'
RUBY
```

- [ ] **Step 3: Build to confirm the project is still valid**

Run the build command. Expected: `** BUILD SUCCEEDED **` (nothing imports the macro yet; this just verifies the project edit).

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertMacros.h TOAlertViewControllerExample.xcodeproj/project.pbxproj
git commit -m "Add TOALERT_OBJC_DIRECT macro for direct-dispatch private methods"
```

---

### Task 2: `TOAlertAction` value object + Swift name

**Files:**
- Modify: `TOAlertViewController/TOAlertAction.h`
- Modify: `TOAlertViewController/TOAlertAction.m`

- [ ] **Step 1: Rewrite `TOAlertAction.h`** (keep the license banner; replace the body from `NS_ASSUME_NONNULL_BEGIN` to `NS_ASSUME_NONNULL_END`):

```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A model object representing a single button in an alert view controller: its
/// title and the action performed when the user taps it.
NS_SWIFT_NAME(AlertAction)
@interface TOAlertAction : NSObject

/// The title text displayed for this action.
@property (nonatomic, copy) NSString *title;

/// The block executed when the user taps this button.
@property (nonatomic, copy, nullable) void (^action)(void);

/// Initializes a new alert action with the provided title and action block.
/// - Parameters:
///   - title: The title displayed in the button.
///   - action: The block triggered when the user taps the button.
- (instancetype)initWithTitle:(NSString *)title
                       action:(nullable void (^)(void))action NS_DESIGNATED_INITIALIZER;

/// Creates a new alert action with the provided title and action block.
/// - Parameters:
///   - title: The title displayed in the button.
///   - action: The block triggered when the user taps the button.
+ (instancetype)alertActionWithTitle:(NSString *)title
                              action:(nullable void (^)(void))action NS_SWIFT_UNAVAILABLE("Use init(title:action:)");

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2: Rewrite `TOAlertAction.m`** (keep the banner; replace from `#import` down):

```objc
#import "TOAlertAction.h"

@implementation TOAlertAction

- (instancetype)initWithTitle:(NSString *)title action:(nullable void (^)(void))action {
    if (self = [super init]) {
        _title = [title copy];
        _action = [action copy];
    }

    return self;
}

+ (instancetype)alertActionWithTitle:(NSString *)title action:(nullable void (^)(void))action {
    return [[self alloc] initWithTitle:title action:action];
}

#pragma mark - Equality -

- (BOOL)isEqual:(nullable id)object {
    if (self == object) { return YES; }
    if (![object isKindOfClass:[TOAlertAction class]]) { return NO; }
    return [self isEqualToAlertAction:object];
}

- (BOOL)isEqualToAlertAction:(TOAlertAction *)action {
    if (action == nil) { return NO; }
    // Compare the title; action blocks are not meaningfully comparable.
    return (self.title == action.title) || [self.title isEqualToString:action.title];
}

- (NSUInteger)hash {
    return self.title.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; title = %@>",
                                      NSStringFromClass(self.class), self, self.title];
}

@end
```

Notes: `init`/`new` become unavailable but the factory still works (it calls the designated `initWithTitle:action:`). The previous `.m` assigned `_title = title;` without `copy`; this corrects it to `copy` to match the `copy` property attribute. `isEqualToAlertAction:` is internal-only (not declared in the header) — that's fine for an `.m`-local helper, but it is referenced from `isEqual:` so it must NOT be `objc_direct` if later annotated (leave it normal-dispatch).

- [ ] **Step 3: Build and test**

Run the test command. Expected: `** TEST SUCCEEDED **`. (The example app's `alertActionWithTitle:action:` calls still compile; `init`/`new` were never used on `TOAlertAction`.)

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewController/TOAlertAction.h TOAlertViewController/TOAlertAction.m
git commit -m "Harden TOAlertAction as a value object and add NS_SWIFT_NAME"
```

---

### Task 3: `TOAlertViewController` (public)

**Files:**
- Modify: `TOAlertViewController/TOAlertViewController.h`
- Modify: `TOAlertViewController/TOAlertViewController.m`

- [ ] **Step 1: Header — add the Swift name and convert docs to `///`.**

Add `NS_SWIFT_NAME(AlertViewController)` on the line above `@interface TOAlertViewController : UIViewController`:

```objc
NS_SWIFT_NAME(AlertViewController)
@interface TOAlertViewController : UIViewController
```

Convert every `/** … */` property/method doc block in the header to `///` form, preserving the wording and defaults-in-parens. Example transformation:

```objc
// before
/** The maximum width this controller may expand to on larger screens. (Default is 375.0f) */
@property (nonatomic, assign) CGFloat maximumWidth;
// after
/// The maximum width this controller may expand to on larger screens. (Default is 375.0)
@property (nonatomic, assign) CGFloat maximumWidth;
```

Apply this to all property/initializer/method doc comments in the file. Do not change attribute lists (they are already correct order after the Swift-interop branch).

- [ ] **Step 2: Implementation — `_commonInit` + direct dispatch.**

In `TOAlertViewController.m`, import the macro (after the existing imports):

```objc
#import "TOAlertMacros.h"
```

Rename the private `commonInit` to `_commonInit`, mark it direct, and update its two call sites (in `initWithNibName:bundle:`). Declare it in the existing class extension (`@interface TOAlertViewController () …`):

```objc
- (void)_commonInit TOALERT_OBJC_DIRECT;
```

Method definition:

```objc
- (void)_commonInit {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
}
```

Call site in `initWithNibName:bundle:`:

```objc
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _commonInit];
    }

    return self;
}
```

(The lazy `dimmingView`/`alertView` getters and the forwarding accessors are property accessors — leave them as normal dispatch, not `objc_direct`.)

- [ ] **Step 3: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewController/TOAlertViewController.h TOAlertViewController/TOAlertViewController.m
git commit -m "Modernize TOAlertViewController: Swift name, /// docs, direct-dispatch commonInit"
```

---

### Task 4: `TOAlertView` (internal — the largest file)

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertView.m` (and `.h` only if attribute ordering needs fixing)

- [ ] **Step 1: Import the macro** (after `#import "TOAlertLinkLayout.h"`):

```objc
#import "TOAlertMacros.h"
```

- [ ] **Step 2: Rename eligible private helpers to `_`-prefixed + `TOALERT_OBJC_DIRECT`, declaring them in the class extension.**

Eligible (custom helpers, never overrides/selectors/accessors): `alertViewCommonInit`, `setUpSubviews`, `makeButtonWithAction:textColor:backgroundColor:boldText:feedback:`, `configureDefaultColors`, `configureViewsForCurrentTheme`, `updateMessageLabel`, `numberOfButtonRowsForWidth:`, `buttonTappedWithAction:feedback:`, `linkAtPointInMessageLabel:`, `makeLinkLayout`, `showHighlightForLink:`, `hideHighlight`, `animateHighlightToOpacity:`.

Rename each to a leading-underscore name (e.g. `setUpSubviews` → `_setUpSubviews`, `makeLinkLayout` → `_makeLinkLayout`) and update all call sites. Add a declaration for each in the `TOAlertView ()` class extension with the macro, e.g.:

```objc
- (void)_setUpSubviews TOALERT_OBJC_DIRECT;
- (void)_updateMessageLabel TOALERT_OBJC_DIRECT;
- (void)_showHighlightForLink:(TOAlertLink *)link TOALERT_OBJC_DIRECT;
// …one line per eligible helper above…
```

**NOT eligible — leave as normal dispatch and do NOT underscore:**
- `messageLabelPressed:` — referenced by `@selector(messageLabelPressed:)` (gesture target).
- `buttonTappedWithAction:feedback:` — **is** eligible (called only via `[self …]` inside the `tappedHandler` block). Confirm there is no `@selector` reference before marking it direct; there is none.
- All UIView overrides: `initWithFrame:`, `initWithCoder:`, `setUpSubviews`-callers in init are fine, `layoutSubviews`, `traitCollectionDidChange:`, `tintColorDidChange`, `hitTest:withEvent:`, `sizeToFitInBoundSize:`(public, declared in header), and every property accessor (`setMessage:`, `setAttributedMessage:`, `setMessageTextAlignment:`, the color setters, `backgroundColor`, etc.) — normal dispatch.
- `displayButtons` (a declared readonly property getter) — normal dispatch.
- The class method `+neutralButtonColor` — leave as a class method (not instance-direct).

`messageLabelPressed:` may still be renamed to `_messageLabelPressed:` for consistency **only if** the `@selector(_messageLabelPressed:)` is updated to match; it must remain non-direct. To minimize risk, keep its current name `messageLabelPressed:`.

- [ ] **Step 3: `const` locals + `static inline` helper.**

Add `const` to never-reassigned locals. Concrete spots:
- In `_makeButtonWithAction:…`: `UIFont *const buttonFont = …;`, `TORoundedButton *const button = …;` (button is configured via dot-syntax, not reassigned → const OK).
- In `_showHighlightForLink:`: `NSArray<NSValue *> *const rects = …;`, `UIBezierPath *const path = [UIBezierPath bezierPath];` (the pointer isn't reassigned — `appendPath:` mutates the pointee, which `const` on the pointer still allows).
- In `layoutSubviews`/`sizeToFitInBoundSize:`: const-qualify locals that are computed once and not reassigned (e.g. `const CGFloat contentWidth = …;`). Do NOT const-qualify `frame`, `y`, or `contentSize` where they are mutated.
- In `_animateHighlightToOpacity:`: `CALayer *const presentation = self.linkHighlightLayer.presentationLayer;`.

Add a file-local pure helper near the top (after imports) and use it where a CGFloat is compared to zero in float-fuzzy ways if any exist; if there are no such comparisons, skip this (YAGNI — do not invent call sites).

- [ ] **Step 4: Convert any `/** */` to `///` and normalize `#pragma mark - X -`.**

The file already uses `#pragma mark - X -` and inline `//` comments; leave inline notes as-is. There are no public `/** */` blocks here (internal class). No doc-style changes needed beyond consistency.

- [ ] **Step 5: Build and test**

Run the test command. Expected: `** TEST SUCCEEDED **`. Pay attention to any "instance method not found" errors that would indicate a missed call-site rename.

- [ ] **Step 6: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertView.m TOAlertViewController/Internal/TOAlertView.h
git commit -m "Modernize TOAlertView: direct-dispatch private helpers and const locals"
```

---

### Task 5: `TOAlertLinkLayout` (internal)

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertLinkLayout.m`

- [ ] **Step 1: Import the macro** (after `#import "TOAlertLinkLayout.h"`):

```objc
#import "TOAlertMacros.h"
```

- [ ] **Step 2: Mark the private instance helper direct.**

`verticalCenteringOffset` is a private instance helper called only via `[self …]`. Rename to `_verticalCenteringOffset`, update its two call sites (in `linkAtPoint:` and `enclosingRectsForRange:`), and declare it in a class extension with the macro:

```objc
@interface TOAlertLinkLayout ()
- (CGFloat)_verticalCenteringOffset TOALERT_OBJC_DIRECT;
@end
```

`+URLFromLinkAttributeValue:` is a class helper used inside `linkAtPoint:` and a test would not reach it; leave it a normal class method (instance `objc_direct` does not apply to class methods here). The public methods (`initWithAttributedString:…`, `linkAtPoint:`, `enclosingRectsForRange:`) are declared in the header — normal dispatch.

- [ ] **Step 3: `const` locals.**

In `linkAtPoint:` the padding constants are already `const`. In `enclosingRectsForRange:`, `const CGFloat yOffset = [self _verticalCenteringOffset];` and `const NSRange glyphRange = …;` where not reassigned.

- [ ] **Step 4: Build and test**

Run the test command. Expected: `** TEST SUCCEEDED **` (the 8 `TOAlertLinkLayoutTests` directly exercise this file).

- [ ] **Step 5: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertLinkLayout.m
git commit -m "Modernize TOAlertLinkLayout: direct-dispatch helper and const locals"
```

---

### Task 6: `TOAlertDimmingView` (internal)

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertDimmingView.m`

- [ ] **Step 1: Import the macro** (after `#import "TOAlertBlurFilter.h"`).

- [ ] **Step 2: Rename eligible private helpers to `_`-prefixed + direct.**

Eligible: `commonInit`, `backdropScaleForRadius:`, `currentBackdropScale`, `setBackdropScale:onLayer:`. Rename to `_commonInit`, `_backdropScaleForRadius:`, `_currentBackdropScale`, `_setBackdropScale:onLayer:`; update call sites; declare in the class extension with `TOALERT_OBJC_DIRECT`.

**NOT eligible (leave as-is, non-direct, non-underscored):**
- `ensureFilterInstalled` — referenced by `@selector(ensureFilterInstalled)` in the `UIApplicationWillEnterForegroundNotification` observer.
- Overrides: `initWithFrame:`, `dealloc`, `didMoveToWindow`, `layoutSubviews`, `traitCollectionDidChange:`.
- Property accessors: `setBlurRadius:`, `setBlurRadius:animated:duration:`, and the public `playFadeInAnimationWithDuration:` / `playFadeOutAnimationWithDuration:` (declared in the header).

- [ ] **Step 3: `const` locals.**

E.g. in `ensureFilterInstalled`: `UIView *const backdrop = TOAlertFindSubview(self.effectView, @"backdrop");` (reassigned? no → const). In `setBlurRadius:animated:duration:`: `const CGFloat currentRadius = _blurRadius;`, `const CGFloat currentScale = [self _currentBackdropScale];`, `const CGFloat targetScale = …;`, `CAMediaTimingFunction *const timing = …;`. The existing `static const` file constants and `static` C functions already match the conventions — leave them.

- [ ] **Step 4: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertDimmingView.m
git commit -m "Modernize TOAlertDimmingView: direct-dispatch helpers and const locals"
```

---

### Task 7: `TOAlertViewTransitioning` + `TOAlertBlurFilter` (internal)

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertViewTransitioning.m`
- Modify: `TOAlertViewController/Internal/TOAlertBlurFilter.m`

- [ ] **Step 1: `TOAlertViewTransitioning.m` — `const` locals.**

This class has no private helpers to mark direct (its two methods are `UIViewControllerAnimatedTransitioning` protocol methods — normal dispatch). Apply `const` to never-reassigned locals in `animateTransition:`:

```objc
const NSTimeInterval duration = [self transitionDuration:transitionContext];
const UITransitionContextViewControllerKey key = _isReverse ? … : …;
UIViewController *const controller = [transitionContext viewControllerForKey:key];
const CGFloat zeroAlpha = 0.0f, fullAlpha = 1.0f;
const CGAffineTransform identity = CGAffineTransformIdentity;
const CGAffineTransform scaled = CGAffineTransformScale(CGAffineTransformIdentity, 0.85f, 0.85f);
```

(No `objc_direct` here, no underscore renames.)

- [ ] **Step 2: `TOAlertBlurFilter.m` — `const` locals.**

This file is C functions (`TOAlertFindSubview`, `TOAlertMakeBlurFilter`) already matching the "plain C function" convention. Add `const` to never-reassigned locals inside them (e.g. the matched subview, the resolved class/selector). Do not change the function signatures or the header.

- [ ] **Step 3: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertViewTransitioning.m TOAlertViewController/Internal/TOAlertBlurFilter.m
git commit -m "Apply const-correctness to transitioning and blur-filter helpers"
```

---

### Task 8: Full verification

- [ ] **Step 1: Full test run**

Run the test command. Expected: `** TEST SUCCEEDED **` with all 8 `TOAlertLinkLayoutTests` + the example test passing.

- [ ] **Step 2: SPM build for iOS (verify the package still compiles with all changes).**

```bash
cd /Users/TiM/Developer/TOAlertViewController
REPO="$(pwd)"
rm -rf /tmp/spmcheck /tmp/spmcheck-dd && mkdir -p /tmp/spmcheck
ln -s "$REPO/Package.swift" /tmp/spmcheck/Package.swift
ln -s "$REPO/TOAlertViewController" /tmp/spmcheck/TOAlertViewController
cd /tmp/spmcheck
xcodebuild -scheme TOAlertViewController -destination 'platform=iOS Simulator,name=iPhone 16e' -derivedDataPath /tmp/spmcheck-dd build 2>&1 | tail -3
cd "$REPO" && rm -rf /tmp/spmcheck /tmp/spmcheck-dd
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Swift-name sanity check.**

Confirm the de-prefixed names are present and the macro is applied:

```bash
cd /Users/TiM/Developer/TOAlertViewController
grep -rn "NS_SWIFT_NAME(AlertViewController)\|NS_SWIFT_NAME(AlertAction)" TOAlertViewController/
grep -rc "TOALERT_OBJC_DIRECT" TOAlertViewController/Internal/*.m TOAlertViewController/*.m
```

Expected: both `NS_SWIFT_NAME` lines found; `TOALERT_OBJC_DIRECT` appears in the modernized `.m` files.

- [ ] **Step 4: No behavior drift — diff review.**

```bash
git diff origin/master...HEAD -- '*.h' '*.m' | grep -E '^\+' | grep -iE 'TODO|FIXME|NSLog' || echo "no stray debug/markers"
```

Expected: `no stray debug/markers`.

---

## Self-Review Notes

- **Spec coverage:** `///` docs (Tasks 2,3 + conventions applied throughout) ✓; attribute ordering (convention, verified per file) ✓; `objc_direct` + underscore private methods (Tasks 3–6, with the dynamic-dispatch exclusion rule) ✓; `*const` locals (Tasks 4–7) ✓; `static inline` helpers (kept where they already exist; not invented — YAGNI) ✓; `NS_SWIFT_NAME` de-prefix (Tasks 2,3) ✓; `TOAlertAction` value object — designated init, `init`/`new` unavailable, `isEqual:`/`hash`/`description` (Task 2) ✓; shared macro header (Task 1) ✓.
- **Critical correctness rule:** `objc_direct`/underscore is excluded from overrides, protocol methods, property accessors, and `@selector` targets (`messageLabelPressed:`, `ensureFilterInstalled`). Each task enumerates eligible vs. ineligible methods.
- **Behavior preservation:** every task verified by build; Tasks 2, 4, 5, 8 additionally by the test suite (which covers `TOAlertLinkLayout`), and Task 8 by an isolated iOS SPM build.
- **Type/name consistency:** `TOALERT_OBJC_DIRECT` (Task 1) is the exact macro used in Tasks 3–6; `NS_SWIFT_NAME(AlertViewController)` / `NS_SWIFT_NAME(AlertAction)` are consistent across header and verification.
- **Note:** `TOAlertAction.m` previously stored `_title = title` without copying; Task 2 corrects this to `[title copy]` to honor the `copy` attribute — a latent-bug fix folded into the value-object work, not a behavior change for the (immutable-string) call sites in use.
