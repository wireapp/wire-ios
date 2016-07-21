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



#import "UIView+Borders.h"

#import <QuartzCore/QuartzCore.h>



@implementation UIView (Borders)

- (void)setBorderWithColor:(UIColor *)color width:(CGFloat)width
{
    self.layer.borderWidth = width;
    self.layer.borderColor = color.CGColor;
}

- (void)enable1PixelRedBorder
{
    [self setBorderWithColor:[UIColor redColor] width:1.0];
}

- (void)enable1PixelGreenBorder
{
    [self setBorderWithColor:[UIColor greenColor] width:1.0];
}

- (void)enable1PixelBlueBorder
{
    [self setBorderWithColor:[UIColor blueColor] width:1.0];
}

- (void)enable1PixelOrangeBorder
{
    [self setBorderWithColor:[UIColor orangeColor] width:1.0];
}

- (void)enable1PixelPurpleBorder
{
    [self setBorderWithColor:[UIColor purpleColor] width:1.0];
}

@end
