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



#import <WireExtensionComponents/WireExtensionComponents.h>
#import <PureLayout/PureLayout.h>

#import "MessageStatusIndicator.h"
#import "CachingFrameAnimationView.h"
#import "WAZUIMagicIOS.h"



@interface MessageStatusIndicator ()

@property (nonatomic, strong) CachingFrameAnimationView *pendingAnimation;
@property (nonatomic, strong) CachingFrameAnimationView *deliveryAnimation;
@property (nonatomic, strong) IconButton *resendButton;

@end



@implementation MessageStatusIndicator

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupMessageStatusIndicator];
    }
    return self;
}

- (instancetype)initWithPendingTimeElapsed:(NSTimeInterval)elapsedPendingTime
{
    self = [super init];
    if (self) {
        [self setupMessageStatusIndicator];
        [self setPendingStatusWithElapsedTime:elapsedPendingTime];
    }
    return self;
}

- (void)setupMessageStatusIndicator
{
    self.pendingAnimation = [[CachingFrameAnimationView alloc] initWithFrame:self.bounds name:@"sending_pending" repeat:NO];
    self.pendingAnimation.translatesAutoresizingMaskIntoConstraints = NO;
    self.pendingAnimation.hidden = YES;
    [self addSubview:self.pendingAnimation];
    
    self.deliveryAnimation = [[CachingFrameAnimationView alloc] initWithFrame:self.bounds name:@"sending_complete" repeat:NO];
    self.deliveryAnimation.hidden = YES;
    self.deliveryAnimation.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.deliveryAnimation];
    
    self.resendButton = [[IconButton alloc] init];
    self.resendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.resendButton.cas_styleClass = @"resend-button";
    [self.resendButton setIcon:ZetaIconTypeRedo withSize:ZetaIconSizeSearchBar forState:UIControlStateNormal];
    self.resendButton.hidden = YES;
    [self addSubview:self.resendButton];
    
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.pendingAnimation autoCenterInSuperview];
    [self.pendingAnimation autoSetDimensionsToSize:CGSizeMake(12, 12)];

    [self.deliveryAnimation autoCenterInSuperview];
    [self.deliveryAnimation autoSetDimensionsToSize:CGSizeMake(12, 12)];

    [self.resendButton autoCenterInSuperview];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
}

- (void)setDeliveryState:(ZMDeliveryState)deliveryState
{
    ZMDeliveryState previousState = _deliveryState;
    
    if (_deliveryState == deliveryState) {
        return;
    }
    _deliveryState = deliveryState;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showPendingAnimation) object:nil];
    
    switch (deliveryState) {
            
        case ZMDeliveryStateDelivered: {
            
            self.resendButton.hidden = YES;
            
            if (previousState != ZMDeliveryStateInvalid) {
                
                // fast forward pending and start delivery anim
                __weak __typeof(self) weakSelf = self;
                [self.pendingAnimation fastForwardToFrame:self.pendingAnimation.lastFrame in:0.15f onCompletion:^(void) {
                    __typeof(weakSelf) strongSelf = weakSelf;
                    strongSelf.pendingAnimation.hidden = YES;
                    strongSelf.deliveryAnimation.hidden = NO;
                    strongSelf.deliveryAnimation.onFinished = ^(FrameAnimationView *anim) {
                        anim.hidden = YES;
                        anim.onFinished = nil;
                    };
                    [strongSelf.deliveryAnimation startPlaying];
                }];
            }
            break;
        }
        case ZMDeliveryStatePending: {
            
            [self setPendingStatusWithElapsedTime:0];
            break;
        }
        case ZMDeliveryStateFailedToSend: {
            [self stopPendingAnimation];
            [self stopDeliveryAnimation];
            self.resendButton.hidden = NO;
            
            break;
        }
        case ZMDeliveryStateInvalid:
        default:
            
            if (previousState != ZMDeliveryStateDelivered) {
                [self stopPendingAnimation];
                [self stopDeliveryAnimation];
                self.resendButton.hidden = YES;
            }
            break;
    }
}

- (void)setPendingStatusWithElapsedTime:(NSTimeInterval)elapsedTime
{
    _deliveryState = ZMDeliveryStatePending;
    
    self.resendButton.hidden = YES;
    
    // start animation after delay
    WAZUIMagic *magic = [WAZUIMagic sharedMagic];
    NSTimeInterval delayBeforeStarting = [magic[@"content.message_status.delivery_indicator_delay"] floatValue];
    if (delayBeforeStarting == 0.0f) {
        delayBeforeStarting = 1.0f;
    }
    
    if (elapsedTime < delayBeforeStarting) {
        [self performSelector:@selector(showPendingAnimation) withObject:nil afterDelay:delayBeforeStarting - elapsedTime];
    }
    else {
        if (elapsedTime < (delayBeforeStarting + self.pendingAnimation.duration)) {
            [self showPendingAnimationWithElapsedTime:elapsedTime - delayBeforeStarting];
        }
        else {
            [self completePendingAnimation];
        }
    }
}

- (void)setResendButtonTarget:(id)target action:(SEL)action
{
    [self.resendButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)showPendingAnimation
{
    [self showPendingAnimationWithElapsedTime:0.0];
}

- (void)showPendingAnimationWithElapsedTime:(NSTimeInterval)elapsedTime
{
    if (elapsedTime >= self.pendingAnimation.duration) {
        [self completePendingAnimation];
        return;
    }
    
    if (ZMDeliveryStatePending == self.deliveryState) {
        
        self.pendingAnimation.hidden = NO;
        
        NSUInteger frameCount = self.pendingAnimation.lastFrame + 1;
        NSTimeInterval frameDuration = self.pendingAnimation.duration / frameCount;
        
        NSUInteger startFrame = (elapsedTime / frameDuration);
        
        if (startFrame >= self.pendingAnimation.frameCount) {
            startFrame = self.pendingAnimation.lastFrame;
        }
        
        if (startFrame == 0) {
            [self.pendingAnimation startPlaying];
        }
        else {
            [self.pendingAnimation fastForwardToFrame:startFrame in:0.0 onCompletion:^{
                [self.pendingAnimation startPlaying];
            }];
        }
    }
}

- (void)completePendingAnimation
{
    self.pendingAnimation.hidden = NO;
    [self.pendingAnimation fastForwardToFrame:self.pendingAnimation.lastFrame in:0.0f onCompletion:nil];
}

- (void)stopPendingAnimation
{
    [self.pendingAnimation stopPlaying];
    [self.pendingAnimation resetPlayer];
    self.pendingAnimation.hidden = YES;
}

- (void)stopDeliveryAnimation
{
    [self.deliveryAnimation stopPlaying];
    [self.deliveryAnimation resetPlayer];
    self.deliveryAnimation.hidden = YES;
}

- (void)setDarkStyle:(BOOL)darkStyle
{
    if (darkStyle == _darkStyle) {
        return;
    }
    
    _darkStyle = darkStyle;
    
    if (darkStyle) {
        self.pendingAnimation.tintColor = [UIColor colorWithWhite:0.52f alpha:1.0f];
        self.deliveryAnimation.tintColor = [UIColor colorWithWhite:0.52f alpha:1.0f];
    }
    else {
        self.pendingAnimation.tintColor = [UIColor whiteColor];
        self.deliveryAnimation.tintColor = [UIColor whiteColor];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.deliveryState == ZMDeliveryStateFailedToSend) {
        CGRect increasedBounds = CGRectInset(self.bounds, -20, -20);
        return CGRectContainsPoint(increasedBounds, point);
    }
    else {
        return [super pointInside:point withEvent:event];
    }
}

@end
