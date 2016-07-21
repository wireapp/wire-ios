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


#import "ColorPickerKnobView.h"
#import "UIColor+Mixing.h"



@interface ColorPickerKnobView ()

// shadow color that’s mixed out of the left and right components
@property (nonatomic, strong) UIColor *mixedShadowColor;

@end



@implementation ColorPickerKnobView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;

        self.leftProportion = 0.8;
        self.pickedUp = NO;
        self.clipsToBounds = NO;
        self.layer.masksToBounds = NO;

    }
    return self;
}


#pragma mark - Property get/set

- (void)setLeftColor:(UIColor *)leftColor
{
    if (leftColor != _leftColor) {
        _leftColor = leftColor;
        
        [self recomputeShadowColor];
        [self setNeedsDisplay];
    }
}

- (void)setRightColor:(UIColor *)rightColor
{
    if (rightColor != _rightColor) {
        _rightColor = rightColor;
        
        [self recomputeShadowColor];
        [self setNeedsDisplay];
    }
}

- (void)setLeftProportion:(CGFloat)leftProportion
{
    if (leftProportion != _leftProportion) {
        _leftProportion = leftProportion;
        [self recomputeShadowColor];
        [self setNeedsDisplay];
    }
}

- (void)recomputeShadowColor
{
    UIColor *leftColor = self.leftColor;
    UIColor *rightColor = self.rightColor;
	
    UIColor *shadowColor = [leftColor mix:rightColor amount:1 - self.leftProportion];
    self.layer.shadowColor = shadowColor.CGColor;
}

- (void)setPickedUp:(BOOL)pickedUp
{
    if (pickedUp != _pickedUp) {
        _pickedUp = pickedUp;
        if (_pickedUp) {

            if (self.layer.shadowOpacity < 1) {

                self.layer.shadowOpacity = 1;
                self.layer.shadowRadius = 2;
                self.layer.shadowOffset = (CGSize) {0, 0};
                [self recomputeShadowColor];

                CABasicAnimation *shadowFadeIn = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                shadowFadeIn.duration = 0.4;
                shadowFadeIn.fromValue = @(0);
                shadowFadeIn.toValue = @(1);
                shadowFadeIn.fillMode = kCAFillModeBackwards;
                shadowFadeIn.removedOnCompletion = YES;

                [self.layer addAnimation:shadowFadeIn forKey:@"shadowFadeIn"];

            }

        } else {

            if (self.layer.shadowOpacity > 0) {
                self.layer.shadowOpacity = 0;

                CABasicAnimation *shadowFadeOut = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
                shadowFadeOut.duration = 0.4;
                shadowFadeOut.fromValue = @(1);
                shadowFadeOut.toValue = @(0);
                shadowFadeOut.fillMode = kCAFillModeBackwards;
                shadowFadeOut.removedOnCompletion = YES;

                [self.layer addAnimation:shadowFadeOut forKey:@"shadowFadeOut"];

            }

        }
        [self setNeedsDisplay];
    }
}


#pragma mark - Drawing

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat strokeWidth = 2;
    CGFloat diameter = 24;

    CGContextSetLineWidth(ctx, strokeWidth);

    UIColor *leftColor = self.leftColor;
    CGContextSetStrokeColorWithColor(ctx, leftColor.CGColor);
    if (self.leftColor == self.rightColor) {
        // simple case - one color

        CGContextAddArc(ctx,
						self.bounds.size.width / 2,
						self.bounds.size.height / 2,
						diameter / 2 - strokeWidth / 2,
						-M_PI,
						M_PI,
						0);
		
        CGContextDrawPath(ctx, kCGPathStroke);

        if (self.pickedUp) {
            CGContextSetLineWidth(ctx, strokeWidth * 2);
            CGContextAddArc(ctx,
							self.bounds.size.width / 2,
							self.bounds.size.height / 2,
							diameter / 2,
							-M_PI,
							M_PI,
							0);
            CGContextDrawPath(ctx, kCGPathStroke);
        }

        return;
    }

    // more complex case - two colors

    CGFloat rightProportion = 1 - self.leftProportion;
    if ((rightProportion < 0) || (rightProportion > 1)) {
        [NSException raise:NSInvalidArgumentException format:@"The knob drawing left color proportion must be between 0 and 1."];
    }

    // Draw left part. (Note that the color for left part was already set above.)

    CGFloat circleFraction = rightProportion * M_PI;
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextAddArc(ctx, self.bounds.size.width / 2, self.bounds.size.height / 2, diameter / 2 - strokeWidth / 2, circleFraction, - circleFraction, 0);
    CGContextDrawPath(ctx, kCGPathStroke);

    if (self.pickedUp) {
        CGContextSetLineWidth(ctx, strokeWidth * 2);
        CGContextAddArc(ctx, self.bounds.size.width / 2, self.bounds.size.height / 2, diameter / 2, circleFraction, - circleFraction, 0);
        CGContextDrawPath(ctx, kCGPathStroke);
    }

    // Draw right part.

    CGContextSetStrokeColorWithColor(ctx, self.rightColor.CGColor);
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextAddArc(ctx, self.bounds.size.width / 2, self.bounds.size.height / 2, diameter / 2 - strokeWidth / 2, circleFraction, - circleFraction, 1);
    CGContextDrawPath(ctx, kCGPathStroke);

    if (self.pickedUp) {
        CGContextSetLineWidth(ctx, strokeWidth * 2);
        CGContextAddArc(ctx, self.bounds.size.width / 2, self.bounds.size.height / 2, diameter / 2, circleFraction, - circleFraction, 1);
        CGContextDrawPath(ctx, kCGPathStroke);
    }

}


#pragma mark - Touch handling (for UI feedback)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.pickedUp = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.pickedUp = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.pickedUp = NO;
}


@end
