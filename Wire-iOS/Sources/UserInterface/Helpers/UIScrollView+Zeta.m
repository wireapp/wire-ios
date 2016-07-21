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


#import "UIScrollView+Zeta.h"



@implementation UIScrollView (Zeta)

- (CGFloat)scrollOffsetFromBottom
{
    CGFloat offsetY = self.contentOffset.y;
    CGFloat boundsHeight = self.bounds.size.height;
    CGFloat contentHeight = self.contentSize.height;
    CGFloat bottomInset = self.contentInset.bottom;

    CGFloat distanceY = contentHeight - (offsetY + boundsHeight - bottomInset);

    return distanceY;
}

- (BOOL)isScrolledToBottom
{
    // For some reason distance from bottom is always off by a fraction of a point if the result of
    return self.scrollOffsetFromBottom <= 1;
}

- (BOOL)isContentOverflowing
{
    return self.contentSize.height > self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;
}

@end
