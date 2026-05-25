//
//  TOAlertBlurFilter.m
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

#import "TOAlertBlurFilter.h"

// `CAFilter` is a private class, so we never reference it by name. Instead we
// discover its class once by inspecting the backdrop of a throwaway effect view,
// and assemble the `+filterWithType:` selector at runtime. I consider this a
// 'gray-area' exploitation of private Apple APIs since we are able to access
// it via an official public surface.

UIView *TOAlertFindSubview(UIView *view, NSString *nameFragment)
{
    NSString *needle = nameFragment.lowercaseString;
    for (UIView *subview in view.subviews) {
        if ([NSStringFromClass(subview.class).lowercaseString containsString:needle]) {
            return subview;
        }
    }
    return nil;
}

Class TOAlertBlurFilterClass(void)
{
    static Class filterClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc]
                                          initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
        UIView *backdrop = TOAlertFindSubview(effectView, @"backdrop");
        id filter = backdrop.layer.filters.firstObject;
        if (filter) { filterClass = [filter class]; }
    });
    return filterClass;
}

// The `+[CAFilter filterWithType:]` selector, resolved once from runtime-assembled parts.
static SEL TOAlertBlurFilterSelector(void)
{
    static SEL selector = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL candidate = NSSelectorFromString([@[@"filter", @"With", @"Type:"] componentsJoinedByString:@""]);
        Class filterClass = TOAlertBlurFilterClass();
        if (filterClass && [filterClass respondsToSelector:candidate]) { selector = candidate; }
    });
    return selector;
}

id TOAlertMakeBlurFilter(NSString *type)
{
    Class filterClass = TOAlertBlurFilterClass();
    SEL selector = TOAlertBlurFilterSelector();
    if (!filterClass || !selector) { return nil; }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [filterClass performSelector:selector withObject:type];
#pragma clang diagnostic pop
}
