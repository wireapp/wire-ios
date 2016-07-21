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


#import "UnsentIndicatorLayer.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"



@implementation UnsentIndicatorLayer

+ (instancetype)layer
{
    return [[UnsentIndicatorLayer alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        CGFloat radius = 6;
        UIColor *color = [UIColor colorWithRed:1.0 green:0.823 blue:0 alpha:1.0];
        [self setupWithRadius:radius color:color];
    }
    return self;
}

- (instancetype)initWithRadius:(CGFloat)radius color:(UIColor *)color
{
    self = [super init];
    if (self) {
        [self setupWithRadius:radius color:color];
    }
    return self;
}

- (void)setupWithRadius:(CGFloat)radius color:(UIColor *)color
{
    self.backgroundColor = color.CGColor;
    self.bounds = CGRectMake(0, 0, 2 * radius, 2 * radius);
    self.cornerRadius = radius;
    self.contentsScale = [[UIScreen mainScreen] scale];
    
    UIImage *exclMark = [UIImage imageForIcon:ZetaIconTypeExclamationMark fontSize:8 color:[UIColor blackColor]];
    self.contents = (id)exclMark.CGImage;
    self.contentsGravity = kCAGravityCenter;
    
}

@end
