//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

#import "KeyboardFrameObserver.h"
#import "UIView+Zeta.h"



@interface KeyboardFrameObserver ()

@property (nonatomic, strong) NSDictionary *currentKeyboardInfo;

@end



@implementation KeyboardFrameObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    self.currentKeyboardInfo = [notification.userInfo copy];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.currentKeyboardInfo = nil;
}

- (CGRect)keyboardFrame
{
    if (self.currentKeyboardInfo) {
        return [[self.currentKeyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    } else {
        return CGRectZero;
    }
}

- (CGRect)keyboardFrameInView:(UIView *)view
{
    return [UIView keyboardFrameInView:view forKeyboardInfo:self.currentKeyboardInfo];
}

- (BOOL)keyboardIsVisible
{
    CGRect screenRect = [[self.currentKeyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect visibleRect = CGRectIntersection([UIScreen mainScreen].bounds, screenRect);
    
    return visibleRect.size.height > 0;
}

@end
