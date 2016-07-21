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


#import "CameraFocusRing.h"



@implementation CameraFocusRing

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.contentMode = UIViewContentModeRedraw;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    const CGFloat outerWidth = 3;
    const CGFloat innerWidth = 2;
    
    CGRect ringRect = CGRectMake(outerWidth / 2, outerWidth / 2, rect.size.width - outerWidth, rect.size.height - outerWidth);
    
    // FocusShadow Drawing
    UIColor* shadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.4];
    UIBezierPath* focusShadowPath = [UIBezierPath bezierPathWithOvalInRect:ringRect];
    [shadowColor setStroke];
    focusShadowPath.lineWidth = outerWidth;
    [focusShadowPath stroke];
    
    // FocusRing Drawing
    UIBezierPath* focusRingPath = [UIBezierPath bezierPathWithOvalInRect:ringRect];
    [UIColor.whiteColor setStroke];
    focusRingPath.lineWidth = innerWidth;
    [focusRingPath stroke];
}

@end
