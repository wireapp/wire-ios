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


#import "PassthroughTouchesView.h"



@implementation PassthroughTouchesView

- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (! CGRectContainsPoint(self.bounds, point)) {return NO;}

    for (UIView *subview in self.subviews) {

        // Don’t consider hidden subviews in hit testing
        if (subview.hidden || subview.alpha == 0) {
            continue;
        }

        CGPoint translatedPoint = [self convertPoint:point toView:subview];
        if ([subview pointInside:translatedPoint withEvent:event]) {
            return YES;
        }

        // 1st level subviews did not match, so iterate through 2nd level

        for (UIView *subSubview in subview.subviews) {
            CGPoint translatedSubSubPoint = [self convertPoint:point toView:subSubview];
            if ([subview pointInside:translatedPoint withEvent:event] &&
                    [subSubview pointInside:translatedSubSubPoint withEvent:event]) {
                return YES;
            }
        }
    }

    return NO;
}

@end
