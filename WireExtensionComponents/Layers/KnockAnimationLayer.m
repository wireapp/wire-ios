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



#import "KnockAnimationLayer.h"
#import "PulseLayer.h"

#if TARGET_OS_MAC
#import <QuartzCore/QuartzCore.h>
#endif



static NSString *const kScaleAnimation = @"ScaleAnimation";



@interface KnockAnimationLayer ()

@property (nonatomic, strong, readwrite) PulseLayer *scaledLayer;

@end

@implementation KnockAnimationLayer

- (id)init
{
    if (self = [super init]) {
        self.scaledLayer = [PulseLayer layer];
        self.scaledLayer.hidden = YES;
        [self addSublayer:self.scaledLayer];
    }
    return self;
}

- (void)layoutSublayers
{
    [super layoutSublayers];

    BOOL boundsHasChanged = NO;
    const CGRect superBounds = [[self superlayer] bounds];
    if (! CGRectEqualToRect(superBounds, self.scaledLayer.bounds)) {
        boundsHasChanged = YES;
    }

    self.scaledLayer.bounds = (CGRect){CGPointZero, superBounds.size};
    self.scaledLayer.position = (CGPoint){superBounds.size.width / 2, superBounds.size.height / 2};
    self.scaledLayer.cornerRadius = superBounds.size.width / 2;
    
    if (boundsHasChanged && [self isAnimating]) {
        [self stopAnimating];
        [self startAnimating];
    }
}

#if TARGET_OS_IPHONE
- (void)setCircleColor:(UIColor *)circleColor
#else
- (void)setCircleColor:(NSColor *)circleColor
#endif
{
    _circleColor = circleColor;
    self.scaledLayer.backgroundColor = circleColor.CGColor;
}

- (void)startAnimating
{
    if (nil != [self.scaledLayer animationForKey:kScaleAnimation]) {
        return;
    }
    if (0 == [self.animationSteps count]) {
        return;
    }
    self.scaledLayer.hidden = NO;
    self.scaledLayer.backgroundColor = self.circleColor.CGColor;


    CGFloat stepOpacity = self.scaledLayer.opacity;
    CGRect stepBounds = [self.scaledLayer bounds];
    CGRect startBounds = [self.scaledLayer bounds];

    CGFloat totalDuration = 0.0;
    NSMutableArray *animationGroups = [NSMutableArray array];
    for (KnockAnimationStep *step in self.animationSteps) {
        CAAnimationGroup *stepAnimationGroup = [CAAnimationGroup animation];

        // Animate the bounds
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        CGRect oldBounds = (step.startFromLastStepBounds) ? stepBounds: startBounds;
        CGRect newBounds = CGRectZero;
        CGFloat scale = step.toContentsScale;
        CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
        CGRect transformFrame = CGRectApplyAffineTransform(oldBounds, transform);
        transformFrame = CGRectIntegral(transformFrame);
        transformFrame = CGRectApplyAffineTransform(transformFrame, CGAffineTransformMakeScale(1.0, 1.0));
        newBounds = (CGRect){CGPointZero, transformFrame.size};
#if TARGET_OS_IPHONE
        boundsAnimation.fromValue = [NSValue valueWithCGRect:oldBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
#else
        boundsAnimation.fromValue = [NSValue valueWithRect:oldBounds];
        boundsAnimation.toValue = [NSValue valueWithRect:newBounds];
#endif
        stepBounds = newBounds;


        // Animate the opacity
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:stepOpacity];
        opacityAnimation.toValue = [NSNumber numberWithFloat:step.toOpacity];
        stepOpacity = step.toOpacity;

        // Animate the corners
        CABasicAnimation *cornerAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnimation.fromValue = @(oldBounds.size.width / 2);
        cornerAnimation.toValue = @(newBounds.size.width / 2);



        stepAnimationGroup.beginTime = totalDuration;
        stepAnimationGroup.animations = @[boundsAnimation, opacityAnimation, cornerAnimation];
        stepAnimationGroup.duration = step.duration;
        stepAnimationGroup.timingFunction = [CAMediaTimingFunction functionWithName:step.timingFunction];


        totalDuration += step.duration;
        [animationGroups addObject:stepAnimationGroup];
    }

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithArray:animationGroups];
    group.duration = totalDuration;
    group.repeatCount = CGFLOAT_MAX;
    [self.scaledLayer addAnimation:group forKey:kScaleAnimation];
}

- (void)stopAnimating
{
    [self.scaledLayer removeAnimationForKey:kScaleAnimation];
    self.scaledLayer.hidden = NO;
}

#pragma mark - Private

- (BOOL)isAnimating
{
    CAAnimation *animation = [self.scaledLayer animationForKey:kScaleAnimation];
    
    return (nil == animation) ? NO: YES;
}


@end


@implementation KnockAnimationStep

- (id)init
{
    if (self = [super init]) {
        self.duration = 1.0;
        self.toContentsScale = 1.0;
        self.toOpacity = 1.0;
        self.timingFunction = kCAMediaTimingFunctionEaseOut;
    }
    return self;
}


+ (instancetype)knockAnimationStep
{
    return [[KnockAnimationStep alloc] init];
}

@end
