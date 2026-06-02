# SPM Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Swift Package Manager support to TOAlertViewController without moving any existing source files or altering the `.xcodeproj`/`.podspec` builds.

**Architecture:** A new top-level `spm/` directory contains symlinks to the real Objective-C sources, with public headers under `spm/include/` (the SPM default `publicHeadersPath`). A root `Package.swift` declares a static library target rooted at `spm/`, depending on TORoundedButton via SPM. One guarded `#import` edit makes the TORoundedButton dependency resolvable across the module boundary. The existing test folder is wired in as the SPM test target.

**Tech Stack:** Swift Package Manager (`swift-tools-version:5.0`), Objective-C, iOS 15+, TORoundedButton 2.x.

---

## File Structure

- **Create** `Package.swift` — SPM manifest: static library product, TORoundedButton dependency, library target at `spm/`, test target at `TOAlertViewControllerTests/`.
- **Create** `spm/include/` — symlinks to the two public headers (the only exported surface).
- **Create** `spm/*.m`, `spm/Internal/*.{h,m}` — symlinks to the real implementation + internal headers.
- **Modify** `TOAlertViewController/Internal/TOAlertView.m:24` — guard the `TORoundedButton.h` import with `__has_include`.
- **Modify** `TOAlertViewControllerTests/TOAlertViewControllerTests.m` — add a guarded module-import smoke test.

> **Note on symlinks:** Steps below use relative symlinks so the repo stays portable. Paths are relative to the symlink's own location (the `ln -s` target is resolved relative to the directory containing the link).

---

### Task 1: Guard the TORoundedButton import

**Files:**
- Modify: `TOAlertViewController/Internal/TOAlertView.m:24`

- [ ] **Step 1: Replace the bare import with a guarded import**

Change line 24 from:

```objc
#import "TORoundedButton.h"
```

to:

```objc
#if __has_include(<TORoundedButton/TORoundedButton.h>)
#import <TORoundedButton/TORoundedButton.h>
#else
#import "TORoundedButton.h"
#endif
```

This mirrors the existing `__has_include` pattern in `TOAlertViewController.h`. Under CocoaPods/Xcode the angle-bracket form is absent, so it falls through to the quoted form — no behavior change there.

- [ ] **Step 2: Verify the existing Xcode/CocoaPods build still compiles this file**

Run: `git diff --stat TOAlertViewController/Internal/TOAlertView.m`
Expected: shows 1 file changed, the import block expanded. (Full Xcode build verification happens after the package builds in Task 5.)

- [ ] **Step 3: Commit**

```bash
git add TOAlertViewController/Internal/TOAlertView.m
git commit -m "Guard TORoundedButton import for cross-module resolution"
```

---

### Task 2: Create the `spm/` symlink tree

**Files:**
- Create: `spm/include/TOAlertViewController.h` (symlink)
- Create: `spm/include/TOAlertAction.h` (symlink)
- Create: `spm/TOAlertViewController.m` (symlink)
- Create: `spm/TOAlertAction.m` (symlink)
- Create: `spm/Internal/TOAlertView.{h,m}` (symlinks)
- Create: `spm/Internal/TOAlertDimmingView.{h,m}` (symlinks)
- Create: `spm/Internal/TOAlertBlurFilter.{h,m}` (symlinks)
- Create: `spm/Internal/TOAlertViewTransitioning.{h,m}` (symlinks)

- [ ] **Step 1: Create directories and public-header symlinks**

```bash
mkdir -p spm/include spm/Internal
ln -s ../../TOAlertViewController/TOAlertViewController.h spm/include/TOAlertViewController.h
ln -s ../../TOAlertViewController/TOAlertAction.h         spm/include/TOAlertAction.h
```

- [ ] **Step 2: Create root implementation symlinks**

```bash
ln -s ../TOAlertViewController/TOAlertViewController.m spm/TOAlertViewController.m
ln -s ../TOAlertViewController/TOAlertAction.m         spm/TOAlertAction.m
```

- [ ] **Step 3: Create internal source symlinks**

```bash
ln -s ../../TOAlertViewController/Internal/TOAlertView.h              spm/Internal/TOAlertView.h
ln -s ../../TOAlertViewController/Internal/TOAlertView.m              spm/Internal/TOAlertView.m
ln -s ../../TOAlertViewController/Internal/TOAlertDimmingView.h       spm/Internal/TOAlertDimmingView.h
ln -s ../../TOAlertViewController/Internal/TOAlertDimmingView.m       spm/Internal/TOAlertDimmingView.m
ln -s ../../TOAlertViewController/Internal/TOAlertBlurFilter.h        spm/Internal/TOAlertBlurFilter.h
ln -s ../../TOAlertViewController/Internal/TOAlertBlurFilter.m        spm/Internal/TOAlertBlurFilter.m
ln -s ../../TOAlertViewController/Internal/TOAlertViewTransitioning.h spm/Internal/TOAlertViewTransitioning.h
ln -s ../../TOAlertViewController/Internal/TOAlertViewTransitioning.m spm/Internal/TOAlertViewTransitioning.m
```

- [ ] **Step 4: Verify every symlink resolves**

Run:
```bash
find spm -type l -exec test -e {} \; -print | wc -l
find spm -type l ! -exec test -e {} \; -print
```
Expected: first command prints `12` (all links present); second command prints nothing (no broken links).

- [ ] **Step 5: Commit**

```bash
git add spm
git commit -m "Add spm/ symlink tree for Swift Package Manager"
```

---

### Task 3: Add the `Package.swift` manifest

**Files:**
- Create: `Package.swift`

- [ ] **Step 1: Write the manifest**

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

- [ ] **Step 2: Verify the manifest parses and dependencies resolve**

Run: `swift package describe --type json | head -40`
Expected: JSON describing the package; TORoundedButton resolved to a 2.x version. No manifest parse errors.

> If `swift package` reports it cannot resolve TORoundedButton, confirm network access to GitHub and that `2.0.0` is still the latest major. The resolution writes `Package.resolved`.

- [ ] **Step 3: Commit**

```bash
git add Package.swift Package.resolved
git commit -m "Add Package.swift manifest for SPM"
```

---

### Task 4: Add the SPM smoke test

**Files:**
- Modify: `TOAlertViewControllerTests/TOAlertViewControllerTests.m`

- [ ] **Step 1: Add a guarded module-import smoke test**

At the top of the file, immediately after `#import <XCTest/XCTest.h>` (line 9), add:

```objc
#if __has_include(<TOAlertViewController/TOAlertViewController.h>)
#import <TOAlertViewController/TOAlertViewController.h>
#endif
```

Then, inside `@implementation TOAlertViewControllerTests` (after the existing `testExample` method, before `@end`), add:

```objc
#if __has_include(<TOAlertViewController/TOAlertViewController.h>)
- (void)testModuleImportsAndInstantiates {
    TOAlertViewController *alert =
        [[TOAlertViewController alloc] initWithTitle:@"Title" message:@"Message"];
    XCTAssertNotNil(alert);
}
#endif
```

Under SPM the module resolves and this test runs. Under the Xcode test target (where the module may not be linked) `__has_include` is false and the test is omitted.

- [ ] **Step 2: Run the test under SPM and verify it passes**

Because the library uses UIKit, the package must be built/tested against an iOS
simulator via `xcodebuild` — plain `swift test` targets the macOS host and fails
on the missing UIKit. `xcodebuild` auto-generates a scheme from `Package.swift`
in the current directory.

Run:
```bash
xcodebuild test -scheme TOAlertViewController -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: build succeeds; `testModuleImportsAndInstantiates` and `testExample` both PASS; `** TEST SUCCEEDED **`.

> If no `iPhone 16` simulator exists, list available destinations with
> `xcrun simctl list devices available` and substitute one. The scheme name
> matches the library target (`TOAlertViewController`).

- [ ] **Step 3: Commit**

```bash
git add TOAlertViewControllerTests/TOAlertViewControllerTests.m
git commit -m "Add SPM module-import smoke test"
```

---

### Task 5: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Clean build the package for iOS**

Run:
```bash
xcodebuild -scheme TOAlertViewController -destination 'platform=iOS Simulator,name=iPhone 16' build
```
Expected: compiles all 6 `.m` files via the `spm/` symlinks, links TORoundedButton, `** BUILD SUCCEEDED **`.

> `swift build` is *not* used here: it targets the macOS host where UIKit is
> unavailable. The package is iOS-only, so all compilation goes through
> `xcodebuild` with an iOS Simulator destination.

- [ ] **Step 2: Run the SPM test suite for iOS**

Run:
```bash
xcodebuild test -scheme TOAlertViewController -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: all tests pass, `** TEST SUCCEEDED **`.

- [ ] **Step 3: Confirm the Xcode project still builds**

Run:
```bash
xcodebuild -project TOAlertViewControllerExample.xcodeproj -scheme TOAlertViewControllerExample -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO -quiet
```
Expected: `** BUILD SUCCEEDED **` — confirms the guarded `TOAlertView.m` import and shared test edit didn't regress the existing project.

> If the scheme name differs, list schemes with `xcodebuild -list -project TOAlertViewControllerExample.xcodeproj` and use the app scheme.

- [ ] **Step 4: Validate the podspec lint (optional, requires CocoaPods)**

Run: `pod lib lint TOAlertViewController.podspec --allow-warnings`
Expected: passes — confirms the podspec source globs are unaffected by the new `spm/` tree.

> Skip if CocoaPods is not installed; the `spm/` directory lives outside the podspec's `TOAlertViewController/**` glob so it cannot affect the lint.

---

## Notes for the implementer

- **Do not** move or copy any file out of `TOAlertViewController/`. The `spm/` entries are symlinks only.
- **Do not** hand-edit `TOAlertViewControllerExample.xcodeproj/project.pbxproj`. The user edits the Xcode project in parallel.
- The only edits to shipping source are the two guarded `__has_include` blocks (Task 1 and Task 4), both of which are inert outside SPM.
