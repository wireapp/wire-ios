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


#import "MissedCallIndicatorLayer.h"



@implementation MissedCallIndicatorLayer

+ (instancetype)layer
{
    return [[MissedCallIndicatorLayer alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        CGFloat radius = 6;
        [self setupWithRadius:radius color:[UIColor whiteColor]];
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
    self.backgroundColor = [color colorWithAlphaComponent:0.24].CGColor;
    self.bounds = (CGRect) {CGPointZero, {2 * radius, 2 * radius}};
    self.cornerRadius = radius;
    
    CALayer *secondCircle = [CALayer layer];
    
    secondCircle.backgroundColor = [color colorWithAlphaComponent:0.4].CGColor;
    secondCircle.bounds = (CGRect) {CGPointZero, {2.0/3.0 * 2*radius, 2.0/3.0 * 2*radius}};
    secondCircle.position = (CGPoint){self.bounds.size.width/2, self.bounds.size.height/2};
    secondCircle.cornerRadius = 2.0/3.0 * radius;
    
    CALayer *inMostCircle = [CALayer layer];
    
    inMostCircle.backgroundColor = color.CGColor;
    inMostCircle.bounds = (CGRect) {CGPointZero, {1.0/3.0 * 2*radius, 1.0/3.0 * 2*radius}};
    inMostCircle.position = (CGPoint){secondCircle.bounds.size.width/2, secondCircle.bounds.size.height/2};
    inMostCircle.cornerRadius = 1.0/3.0 * radius;
    
    [secondCircle addSublayer:inMostCircle];
    [self addSublayer:secondCircle];
}

@end
