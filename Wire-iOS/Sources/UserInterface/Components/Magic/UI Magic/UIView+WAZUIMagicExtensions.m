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


#import "UIView+WAZUIMagicExtensions.h"
#import "WAZUIMagic.h"



@implementation UIView (WAZUIMagicExtensions)

+ (void)animateWithAnimationIdentifier:(id)identifier animations:(void (^)(void))animations options:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
    WAZUIMagic *m = [WAZUIMagic sharedMagic];
    NSString *curve = m[identifier][@"curve"];
    CGFloat duration = [m[identifier][@"duration"] floatValue];
    CGFloat delay = [m[identifier][@"delay"] floatValue];

    if ([curve isEqualToString:@"spring"]) {

        if ([[UIView class] respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
            CGFloat springDamping = [m[identifier][@"spring_damping"] floatValue];
            CGFloat springVelocity = [m[identifier][@"spring_velocity"] floatValue];
            [UIView animateWithDuration:duration
                                  delay:delay
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:springVelocity
                                options:options
                             animations:animations
                             completion:completion];

        } else {

            // if we get here, it means that we cannot execute the spring animation,
            // because we are not on iOS 7.
            // So let’s fall back to the fallback values.

            duration = [m[identifier][@"fallback_duration"] floatValue];
            delay = [m[identifier][@"fallback_delay"] floatValue];
            UIViewAnimationOptions animationCurve = [self animationOptionForValue:m[identifier][@"fallback_curve"]];

            [UIView animateWithDuration:duration
                                  delay:delay
                                options:animationCurve | options
                             animations:animations
                             completion:completion];

        }
    } else {

        // if it's not a spring animation, can use same code regardless of iOS version

        UIViewAnimationOptions animationCurve = [self animationOptionForValue:m[identifier][@"curve"]];
        [UIView animateWithDuration:duration
                              delay:delay
                            options:animationCurve | options
                         animations:animations
                         completion:completion];

    }

}

+ (UIViewAnimationOptions)animationOptionForValue:(NSString *)magicValue
{
    UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
    if ([magicValue isEqualToString:@"ease_in"]) {options = UIViewAnimationOptionCurveEaseIn;}
    else if ([magicValue isEqualToString:@"ease_out"]) {options = UIViewAnimationOptionCurveEaseOut;}
    else if ([magicValue isEqualToString:@"ease_in_out"]) {options = UIViewAnimationOptionCurveEaseInOut;}
    return options;
}

- (void)fadeOutAndRemoveFromSuperviewWithDurationIdentifier:(NSString *)identifier
{
    [self fadeOutAndRemoveFromSuperviewWithDurationIdentifier:identifier completion:NULL];
}

- (void)fadeOutAndRemoveFromSuperviewWithDurationIdentifier:(NSString *)identifier completion:(void (^)())completion
{
    float duration = [WAZUIMagic floatForIdentifier:identifier];
    [UIView animateWithDuration:duration animations:^ {
        self.alpha = 0;
    }                completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}


@end
