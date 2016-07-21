 //
//  KeyboardFrameObserver.m
//  ZClient-iOS
//
//  Created by Tyson Chihaya on 11/5/14.
//  Copyright (c) 2014 Zeta Project Germany GmbH. All rights reserved.
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
