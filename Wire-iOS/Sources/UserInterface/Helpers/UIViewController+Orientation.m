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


#import "UIViewController+Orientation.h"


@implementation UIViewController (Orientation)

+ (UIInterfaceOrientationMask)wr_supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        // iPhone 5S and below: 320x480
        // iPhone 6: 375x667
        // iPhone 6 Plus: 414x736
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        // The way how UIScreen reports its bounds has changed in iOS 8.
        // Using MIN() and MAX() makes this code work for all iOS versions.
        CGFloat smallerDimension = MIN(screenSize.width, screenSize.height);
        CGFloat largerDimension = MAX(screenSize.width, screenSize.height);
        
        if (smallerDimension >= 400 && largerDimension >= 700 && NO)
            return UIInterfaceOrientationMaskAll;
        else
            return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    }
    else
    {
        // Don't need to examine screen dimensions on iPad
        return UIInterfaceOrientationMaskAll;
    }
}

@end
