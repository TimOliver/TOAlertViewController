//
//  TOAlertBlurFilter.h
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

/// :nodoc:
/// A collection of utilities for accessing the (usually private)
/// CAFilter class in an App Store-safe way. This lets us manually
/// control the amount of gaussian blur shown behind the alert view
/// without resorting to incredibly flakey UIKit animation hacking.

/// Loop through all subviews of the provided view and return the first
/// subview whose name contains the provided name fragment.
/// - Parameters:
///   - view: The view whose subviews we'll traverse.
///   - nameFragment: The name fragment belonging to the subview we want to match
UIView *_Nullable TOAlertFindSubview(UIView *view, NSString *nameFragment);

// Returns the `CALayer` instantiation selector `+ filterWithType`.
// It sanity checks that `CAFilter` actually responds to the selector,
// which will let us gracefully catch if Apple subsequently changes any of this behaviour.
id _Nullable TOAlertMakeBlurFilter(NSString *type);

NS_ASSUME_NONNULL_END
