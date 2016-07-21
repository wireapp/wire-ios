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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
@compatibility_alias View UIView;
@compatibility_alias Color UIColor;
#else
@compatibility_alias View NSView;
@compatibility_alias Color NSColor;
#endif

@interface FrameAnimationView : View

+ (instancetype)frameAnimationNamed:(NSString *)name repeat:(BOOL)isRepeating;
- (instancetype)initWithName:(NSString *)resourceName repeat:(BOOL)isRepeating;
- (instancetype)initWithFrame:(CGRect)frame name:(NSString *)resourceName repeat:(BOOL)isRepeating;

- (void)startPlaying;
- (void)stopPlaying;
- (void)resetPlayer;
- (void)fastForwardToFrame:(NSUInteger)frame in:(NSTimeInterval)seconds onCompletion:(dispatch_block_t)completion;

@property (nonatomic, strong)   Color         *tintColor;
@property (nonatomic, assign)   CGFloat        framesPerTick;
@property (nonatomic, readonly) NSUInteger     frameCount;
@property (nonatomic, readonly) NSUInteger     lastFrame;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, copy)     void         (^onFinished)(FrameAnimationView*);

@end
