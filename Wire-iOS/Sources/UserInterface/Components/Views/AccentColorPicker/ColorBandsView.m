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


#import "ColorBandsView.h"

#import "UIColor+WAZExtensions.h"



@interface ColorBandsView ()

@property (strong, nonatomic) NSArray *colors;

@end

@implementation ColorBandsView

- (instancetype)initWithColors:(NSArray *)colors
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.colors = colors;
        self.layer.masksToBounds = YES;
        // Initialization code
        self.clearsContextBeforeDrawing = YES;
        self.opaque = NO;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.bounds.size.height / 2;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat offset = 0;
    for (NSUInteger colorIndex = 0; colorIndex < self.colors.count; colorIndex++) {
        UIColor *color = self.colors[colorIndex];
        CGFloat currentBandWidth = [self.colorBandWidths[colorIndex] floatValue];
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        CGContextFillRect(ctx, CGRectMake(offset, 0, currentBandWidth, self.bounds.size.height));
        offset += currentBandWidth;
    }
}


@end
