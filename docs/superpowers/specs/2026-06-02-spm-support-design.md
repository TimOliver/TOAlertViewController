# Swift Package Manager support for TOAlertViewController

**Date:** 2026-06-02
**Status:** Approved (design)

## Goal

Add Swift Package Manager support to TOAlertViewController without disrupting the
existing CocoaPods and Xcode-project build paths. The library is Objective-C,
targets iOS 15+, and depends on TORoundedButton.

## Constraints

- Do **not** move existing source files. The `.xcodeproj` and `.podspec` must
  keep building from the current `TOAlertViewController/` tree unchanged.
- Match the conventions already established in the author's ecosystem
  (TORoundedButton): top-level `spm/` directory, static library product,
  `swift-tools-version:5.0`.
- Only public headers (`TOAlertViewController.h`, `TOAlertAction.h`) may be
  exported on the module surface. Internal headers stay private.

## Layout — top-level `spm/` directory (symlinks)

A new top-level `spm/` directory holds **symlinks** to the real sources, so the
canonical files stay in place for Xcode/CocoaPods. Placing it at the top level
(rather than an `include/` inside `TOAlertViewController/`) keeps the podspec's
`TOAlertViewController/**/*.{h,m}` glob from picking up the symlinks and
double-counting sources.

```
spm/
  include/                          # publicHeadersPath (SPM default)
    TOAlertViewController.h   -> ../../TOAlertViewController/TOAlertViewController.h
    TOAlertAction.h           -> ../../TOAlertViewController/TOAlertAction.h
  TOAlertViewController.m     -> ../TOAlertViewController/TOAlertViewController.m
  TOAlertAction.m             -> ../TOAlertViewController/TOAlertAction.m
  Internal/
    TOAlertView.h             -> ../../TOAlertViewController/Internal/TOAlertView.h
    TOAlertView.m             -> ../../TOAlertViewController/Internal/TOAlertView.m
    TOAlertDimmingView.h      -> ...
    TOAlertDimmingView.m      -> ...
    TOAlertBlurFilter.h       -> ...
    TOAlertBlurFilter.m       -> ...
    TOAlertViewTransitioning.h-> ...
    TOAlertViewTransitioning.m-> ...
```

Only `spm/include/` is exported, so the module surface is exactly the two public
headers. SPM auto-generates the module map from `include/`, giving consumers
`@import TOAlertViewController;` and `#import <TOAlertViewController/...>`.

### Header resolution

- Root `.m` files import public headers (`#import "TOAlertViewController.h"`,
  `#import "TOAlertAction.h"`). These resolve via the `include/` public-headers
  path, which is on the target's search path.
- Root `.m` files import internal headers (`#import "TOAlertView.h"`). These do
  **not** resolve relative to `spm/`, so the manifest adds
  `cSettings: [.headerSearchPath("Internal")]`.
- Internal `.m` files import sibling internal headers and `TOAlertAction.h`;
  siblings resolve relatively, the public header via `include/`.

## Source edit — TORoundedButton import

`TOAlertViewController/Internal/TOAlertView.m` currently does
`#import "TORoundedButton.h"`, which will not resolve across an SPM module
boundary. Wrap it in the same `__has_include` pattern already used elsewhere in
the codebase:

```objc
#if __has_include(<TORoundedButton/TORoundedButton.h>)
#import <TORoundedButton/TORoundedButton.h>
#else
#import "TORoundedButton.h"
#endif
```

This is safe under CocoaPods/Xcode (falls through to the quoted form). It edits
the real file, which the `spm/` symlink also reflects. This is the only change
to existing library source.

## Package.swift

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TOAlertViewController",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TOAlertViewController",
            type: .static,
            targets: ["TOAlertViewController"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/TimOliver/TORoundedButton",
            .upToNextMajor(from: "2.0.0")
        )
    ],
    targets: [
        .target(
            name: "TOAlertViewController",
            dependencies: ["TORoundedButton"],
            path: "spm",
            cSettings: [
                .headerSearchPath("Internal")
            ]
        ),
        .testTarget(
            name: "TOAlertViewControllerTests",
            dependencies: ["TOAlertViewController"],
            path: "TOAlertViewControllerTests",
            exclude: ["Info.plist"]
        )
    ]
)
```

- `type: .static` matches TORoundedButton rather than leaving linkage automatic.
- TORoundedButton pinned `.upToNextMajor(from: "2.0.0")` (current latest tag).

## Test target

The SPM test target points directly at the existing `TOAlertViewControllerTests/`
folder, excluding `Info.plist`. To verify the module actually links under SPM
without breaking the shared Xcode test target, the existing placeholder test
gains an `__has_include`-guarded smoke test:

```objc
#if __has_include(<TOAlertViewController/TOAlertViewController.h>)
#import <TOAlertViewController/TOAlertViewController.h>

- (void)testModuleImportsAndInstantiates {
    TOAlertViewController *alert =
        [[TOAlertViewController alloc] initWithTitle:@"Title" message:@"Message"];
    XCTAssertNotNil(alert);
}
#endif
```

Under SPM the module resolves and the test runs. Under the Xcode test target
(where the module may not be linked) `__has_include` is false and the test is
omitted — no behavior change there.

## Verification

- `swift build` succeeds (resolves TORoundedButton, compiles all sources).
- `swift test` runs the smoke test green.
- Existing Xcode project and CocoaPods builds remain unaffected (no source moved,
  guarded imports fall through).

## Out of scope

- No changes to the example app, CHANGELOG, or README beyond what is needed to
  document SPM availability (README update optional, can follow separately).
- No restructuring of the existing source tree.
