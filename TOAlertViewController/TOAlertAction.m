//
//  TOAlertAction.m
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
