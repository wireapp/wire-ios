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


#import "ConnectionRequestIndicatorLayer.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"


@interface ConnectionRequestIndicatorLayer ()

@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat pathLineWidth;

@end


@implementation ConnectionRequestIndicatorLayer

+ (instancetype)layer
{
    return [[ConnectionRequestIndicatorLayer alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _color = [UIColor accentColor];
        self.radius = [WAZUIMagic floatForIdentifier:@"list.connect_request_dot_radius"];
        self.pathLineWidth = [WAZUIMagic floatForIdentifier:@"list.connect_request_dot_line_width"];
        
        [self updateAppearance];
    }
    return self;
}

- (instancetype)initWithRadius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(UIColor *)color
{
    self = [super init];
    if (self) {
        _color = color;
        [self setupLayerWithRadius:radius lineWidth:lineWidth color:(UIColor *)color];
    }
    return self;
}

- (void)setupLayerWithRadius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(UIColor *)color
{
    self.radius = radius;
    self.pathLineWidth = lineWidth;
    
    self.bounds = CGRectMake(0, 0, 2 * radius, 2 * radius);
    self.strokeColor = color.CGColor;
    self.fillColor = [UIColor clearColor].CGColor;
    self.lineWidth = lineWidth;
    
    CGPathRef path = CGPathCreateWithEllipseInRect(self.bounds, &CGAffineTransformIdentity);
    self.path = path;
    CGPathRelease(path);
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.strokeColor = color.CGColor;
    [self updateAppearance];
}

- (void)updateAppearance
{
    [self setupLayerWithRadius:self.radius lineWidth:self.pathLineWidth color:self.color];
}

@end
