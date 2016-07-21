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


#import "UnreadIndicatorLayer.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"



@implementation UnreadIndicatorLayer

+ (instancetype)layer
{
    return [[UnreadIndicatorLayer alloc] initWithUnreadCount:0 color:[UIColor accentColor]];
}

- (instancetype)initWithUnreadCount:(NSUInteger)unreadCount color:(UIColor *)color
{
    self = [super init];
    if (self) {
        self.color = color;
        self.unreadCount = unreadCount;
    }
    
    return self;
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
    _unreadCount = unreadCount;
    
    CGFloat radius = [[self class] unreadDotRadiusForUnreadCount:unreadCount];
    self.bounds = CGRectMake(0, 0, 2 * radius, 2 * radius);
    self.anchorPoint = CGPointMake(0.5, 0.5);
    self.cornerRadius = radius;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.backgroundColor = color.CGColor;
}

+ (CGFloat)unreadDotRadiusForUnreadCount:(NSInteger)unreadCount
{
    WAZUIMagic *magic = [WAZUIMagic sharedMagic];
    
    __block CGFloat radius = 0;
    [magic[@"list.unread_indicator_radiuses"] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (unreadCount >= [obj[0] integerValue]) {
            radius = [obj[1] floatValue];
            *stop = YES;
        }
    }];
    
    return radius;
}

@end
