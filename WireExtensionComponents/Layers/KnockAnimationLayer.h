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



#import <Foundation/Foundation.h>

#import "AnimatedLayer.h"

@class KnockAnimationStep;
@class PulseLayer;



/// Works only with ScaleLayer
@interface KnockAnimationLayer : CALayer <AnimatedLayer>

// Array with KnockAnimationStep objects. Should be set before calling startAnimating
@property (nonatomic, copy) NSArray *animationSteps;
/// Allows to control the intensity of the animation. Default is 1.0, to reduce/increase change the number accordingly

/// The color of the circle
#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIColor *circleColor;
#else
@property (nonatomic, strong) NSColor *circleColor;
#endif

- (void)startAnimating;

- (void)stopAnimating;

@end



@interface KnockAnimationStep : NSObject

@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat toContentsScale;
@property (nonatomic, assign) CGFloat toOpacity;
@property (nonatomic, assign) BOOL startFromLastStepBounds;

/// See CAMediaTimingFunction.h. Default is kCAMediaTimingFunctionEaseOut
@property (nonatomic, copy) NSString *timingFunction;

+ (instancetype)knockAnimationStep;

@end
