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


#import "CameraExposureSlider.h"



@implementation CameraExposureSlider

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
    const CGFloat borderWidth = outerWidth - innerWidth;
    const CGFloat clipWidth = 10;
    const CGFloat clipHeight = 32;
    
    UIColor* color = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.4];
    
    CGFloat knobOffset = fabs((CGRectGetHeight(rect) - clipHeight) * self.value);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGMutablePathRef linePath = CGPathCreateMutable();
    CGPathMoveToPoint(linePath, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect) + outerWidth / 2);
    CGPathAddLineToPoint(linePath, NULL, CGRectGetMidX(rect), CGRectGetMaxY(rect) - outerWidth / 2);
    
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectInfinite];
    [clipPath appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(rect) - clipWidth, knobOffset, clipWidth * 2, clipHeight)]];
    clipPath.usesEvenOddFillRule = YES;
    [clipPath addClip];
    
    CGContextAddPath(context, linePath);
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, outerWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    UIBezierPath *innerClipPath = [UIBezierPath bezierPathWithRect:CGRectInfinite];
    [innerClipPath appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(rect) - clipWidth - borderWidth / 2, knobOffset - borderWidth / 2, clipWidth * 2 + borderWidth, clipHeight + borderWidth)]];
    innerClipPath.usesEvenOddFillRule = YES;
    [innerClipPath addClip];
    
    CGContextAddPath(context, linePath);
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, innerWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
    
    [self drawKnobAtPoint:CGPointMake(CGRectGetMidX(rect), knobOffset + clipHeight / 2)];
    
    CGPathRelease(linePath);
}

- (void)drawKnobAtPoint:(CGPoint)point
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, point.x, point.y);
    
    UIColor* shadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.4];
    
    // Draw center circle
    UIBezierPath* centerCircle = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-5, -5, 10, 10)];
    
    [shadowColor setStroke];
    centerCircle.lineWidth = 3;
    [centerCircle stroke];
    
    [[UIColor whiteColor] setStroke];
    centerCircle.lineWidth = 2;
    [centerCircle stroke];
    
    UIBezierPath *dotShadow = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10, -1.5, 3, 3)];
    UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10.5, -1, 2, 2)];
    
    // Draw surrounding circles
    for (CGFloat i = 0; i < 8; i++) {
        CGContextRotateCTM(context, 2 * M_PI * (i / 8));
        
        [shadowColor setFill];
        [dotShadow fill];
        
        [[UIColor whiteColor] setFill];
        [dot fill];
    }
}

- (void)setValue:(CGFloat)value
{
    _value = MAX(MIN(value, 1), 0);
    [self setNeedsDisplay];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(26, UIViewNoIntrinsicMetric);
}

@end
