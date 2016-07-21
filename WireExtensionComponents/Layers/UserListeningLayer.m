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


#import "UserListeningLayer.h"

#import "Geometry.h"



static NSString *const UserListeningLayerVoiceGainAnimationKey = @"voiceGainBoundsAnimation";



@interface UserListeningLayer ()

@property (nonatomic, strong) CALayer *circleLayer;
@property (nonatomic, assign) CGRect previousVoiceGainRect;

@end



@implementation UserListeningLayer

- (id)init
{
#if TARGET_OS_IPHONE
    return [self initWithCircleColor:[UIColor redColor]];
#else
    return [self initWithCircleColor:[NSColor redColor]];
#endif
}

#if TARGET_OS_IPHONE
- (id)initWithCircleColor:(UIColor *)ringColor
#else
- (id)initWithCircleColor:(NSColor *)ringColor
#endif
{
    self = [super init];
    if (self) {
        self.cicleContentScale = 1.05;
        self.circleLayer = [CALayer layer];
        self.circleLayer.backgroundColor = ringColor.CGColor;
    }
    return self;
}

#if TARGET_OS_IPHONE
+ (instancetype)userListeningLayerWithCircleColor:(UIColor *)circleColor;
#else
+ (instancetype)userListeningLayerWithCircleColor:(NSColor *)circleColor;
#endif
{
    UserListeningLayer *layer = [[UserListeningLayer alloc] initWithCircleColor:circleColor];
    return layer;
}

#if TARGET_OS_IPHONE
-(void)setCircleColor:(UIColor *)circleColor
#else
-(void)setCircleColor:(NSColor *)circleColor
#endif
{
    _circleColor = circleColor;
    self.circleLayer.backgroundColor = circleColor.CGColor;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    self.circleLayer.bounds = (CGRect){bounds.origin, {bounds.size.width * self.cicleContentScale, bounds.size.height * self.cicleContentScale}};
    self.circleLayer.cornerRadius = self.circleLayer.bounds.size.width / 2.0;
}

- (void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    self.circleLayer.position = position;
}

- (void)startAnimating
{
    if (nil != self.circleLayer.superlayer) {
        return;
    }
    [self addSublayer:self.circleLayer];
}

- (void)stopAnimating
{
    [self.circleLayer removeAnimationForKey:UserListeningLayerVoiceGainAnimationKey];
    [self.circleLayer removeFromSuperlayer];
}

- (void)setValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        [self setVoiceGain:[(NSNumber *)value floatValue]];
    }
}

@end

@implementation UserListeningLayer (VoiceGain)

- (void)setVoiceGain:(CGFloat)gain
{
    if (! self.circleLayer.superlayer || gain < 0.01 || gain > 1.0) {
        return;
    }
    
    if (CGRectEqualToRect(self.previousVoiceGainRect, CGRectZero)) {
        self.previousVoiceGainRect = self.circleLayer.bounds;
    }
    
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];

    CGRect oldBounds = self.circleLayer.bounds;
    CGRect newBounds = CGRectZero;

    CGFloat optimizedGain = CGClamp(0, 1, gain);
    CGFloat scale = self.cicleContentScale + optimizedGain;
    scale = CGMin(1.7, scale);
    
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    CGRect transformFrame = CGRectApplyAffineTransform(oldBounds, transform);
    transformFrame = CGRectIntegral(transformFrame);
    transformFrame = CGRectApplyAffineTransform(transformFrame, CGAffineTransformMakeScale(1.0, 1.0));
    newBounds = (CGRect){CGPointZero, transformFrame.size};
    
    // Decide if need to animate at all
    BOOL animate = (! CGRectEqualToRect(self.previousVoiceGainRect, newBounds));
    if (! animate) {
        return;
    }

#if TARGET_OS_IPHONE
    boundsAnimation.fromValue = [NSValue valueWithCGRect:self.circleLayer.bounds];
    boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
#else
    boundsAnimation.fromValue = [NSValue valueWithRect:self.circleLayer.bounds];
    boundsAnimation.toValue = [NSValue valueWithRect:newBounds];
#endif
    
    self.previousVoiceGainRect = newBounds;
    
    CABasicAnimation *cornerAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    cornerAnimation.toValue = @(newBounds.size.width / 2);
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithObjects:boundsAnimation, cornerAnimation, nil];
    group.repeatCount = 1;
    group.duration = 0.25;

    [self.circleLayer addAnimation:group forKey:UserListeningLayerVoiceGainAnimationKey];
}

@end
