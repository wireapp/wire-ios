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


#import "ConversationListIndicator.h"
#import "PingAnimationLayer.h"
#import "VoiceIndicatorLayer+MagicInit.h"
#import "UnreadIndicatorLayer.h"
#import "ConnectionRequestIndicatorLayer.h"
#import "UnsentIndicatorLayer.h"
#import "MissedCallIndicatorLayer.h"
#import "UIColor+WAZExtensions.h"
#import <WireExtensionComponents/WireStyleKit.h>


@interface ConversationListIndicator (ShowHide)

- (void)showUnreadIndicator;
- (void)showUnsentIndicator;
- (void)showConnectionRequestIndicator;
- (void)showMissedCallIndicator;
- (void)showVoiceIndicator;
- (void)hideVoiceIndicator;
- (void)showPingIndicator;
- (void)hidePingIndicator;
- (void)showInactiveCallIndicator;

@end



@interface ConversationListIndicator ()

@property (nonatomic, strong) UnreadIndicatorLayer *unreadIndicator;
@property (nonatomic, strong) UnsentIndicatorLayer *unsentIndicator;
@property (nonatomic, strong) ConnectionRequestIndicatorLayer *connectionRequestIndicator;
@property (nonatomic, strong) MissedCallIndicatorLayer *missedCallIndicator;
@property (nonatomic, strong) VoiceIndicatorLayer *voiceIndicatorLayer;
@property (nonatomic, strong) PingAnimationLayer *pingLayer;
@property (nonatomic, strong) CALayer *inactiveCallIndicatorLayer;

@end



@implementation ConversationListIndicator

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutAllLayers];
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)layoutAllLayers
{
    [self centerLayer:self.unreadIndicator];
    [self centerLayer:self.unsentIndicator];
    [self centerLayer:self.connectionRequestIndicator];
    [self centerLayer:self.pingLayer];
    [self centerLayer:self.voiceIndicatorLayer];
    [self centerLayer:self.missedCallIndicator];
    [self centerLayer:self.inactiveCallIndicatorLayer];
}

- (void)centerLayer:(CALayer *)layer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    [CATransaction commit];
}

- (void)hideAllIndicators
{
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    
    [self.unreadIndicator setHidden:YES];
    [self.missedCallIndicator setHidden:YES];
    [self.connectionRequestIndicator setHidden:YES];
    [self.unsentIndicator setHidden:YES];
    [self.inactiveCallIndicatorLayer setHidden:YES];
    
    [self hideVoiceIndicator];
    [self hidePingIndicator];
    
    [CATransaction commit];
}

- (void)setIndicatorType:(ZMConversationListIndicator)indicatorType
{
    if (_indicatorType == indicatorType) {
        return;
    }
    _indicatorType = indicatorType;
    
    [self hideAllIndicators];
    
    switch (indicatorType) {
            
        case ZMConversationListIndicatorUnreadMessages:
            [self showUnreadIndicator];
            break;
           
        case ZMConversationListIndicatorActiveCall:
            [self showVoiceIndicator];
            break;

        case ZMConversationListIndicatorKnock:
            [self showPingIndicator];
            break;
            
        case ZMConversationListIndicatorExpiredMessage:
            [self showUnsentIndicator];
            break;

        case ZMConversationListIndicatorMissedCall:
            [self showMissedCallIndicator];
            break;

        case ZMConversationListIndicatorPending:
            [self showConnectionRequestIndicator];
            break;
            
        case ZMConversationListIndicatorInactiveCall:
            [self showInactiveCallIndicator];
            break;
            
        default:
            break;
    }
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
    _unreadCount = unreadCount;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    [self.unreadIndicator setUnreadCount:unreadCount];
    [CATransaction commit];
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;

    self.unreadIndicator.color = foregroundColor;
    self.connectionRequestIndicator.color = foregroundColor;
    self.pingLayer.color = foregroundColor;
    self.voiceIndicatorLayer.circleColor = foregroundColor;

    if (self.inactiveCallIndicatorLayer) {
        UIImage *image = [WireStyleKit imageOfJoinongoingcallWithColor:foregroundColor];
        self.inactiveCallIndicatorLayer.contents = (id)image.CGImage;
    }
}

- (void)ensureAnimationsRunning
{
    if (self.indicatorType == ZMConversationListIndicatorActiveCall) {
        [self.voiceIndicatorLayer stopAnimating];
        [self.voiceIndicatorLayer startAnimating];
    }
}

- (BOOL)isDisplayingAnyIndicators
{
    return (self.indicatorType != ZMConversationListIndicatorNone || self.unreadCount != 0);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self ensureAnimationsRunning];
}

@end



@implementation ConversationListIndicator (ShowHide)

- (void)showUnreadIndicator
{
    if (self.unreadIndicator == nil) {
        self.unreadIndicator = [[UnreadIndicatorLayer alloc] initWithUnreadCount:self.unreadCount color:[UIColor accentColor]];
        [self.layer addSublayer:self.unreadIndicator];
        [self centerLayer:self.unreadIndicator];
    }
    [self.unreadIndicator setHidden:NO];
}

- (void)showUnsentIndicator
{
    if (self.unreadIndicator == nil) {
        self.unsentIndicator = [UnsentIndicatorLayer layer];
        [self.layer addSublayer:self.unsentIndicator];
        [self centerLayer:self.unsentIndicator];
    }
    [self.unsentIndicator setHidden:NO];
}

- (void)showConnectionRequestIndicator
{
    if (self.connectionRequestIndicator == nil) {
        self.connectionRequestIndicator = [ConnectionRequestIndicatorLayer layer];
        [self.layer addSublayer:self.connectionRequestIndicator];
        [self centerLayer:self.connectionRequestIndicator];
    }
    [self.connectionRequestIndicator setHidden:NO];
}

- (void)showInactiveCallIndicator
{
    if (! self.inactiveCallIndicatorLayer) {
        self.inactiveCallIndicatorLayer = [CALayer layer];
        UIImage *image = [WireStyleKit imageOfJoinongoingcallWithColor:[UIColor accentColor]];
        self.inactiveCallIndicatorLayer.contents = (id)image.CGImage;
        self.inactiveCallIndicatorLayer.bounds = (CGRect){CGPointZero, image.size};
        [self.layer addSublayer:self.inactiveCallIndicatorLayer];
        [self centerLayer:self.inactiveCallIndicatorLayer];
    }
    [self.inactiveCallIndicatorLayer setHidden:NO];
}

- (void)showMissedCallIndicator
{
    if (self.missedCallIndicator == nil) {
        self.missedCallIndicator = [MissedCallIndicatorLayer layer];
        [self.layer addSublayer:self.missedCallIndicator];
        [self centerLayer:self.missedCallIndicator];
    }
    [self.missedCallIndicator setHidden:NO];
}

- (void)showVoiceIndicator
{
    if (self.voiceIndicatorLayer == nil ) {
        self.voiceIndicatorLayer = [VoiceIndicatorLayer voiceIndicatorLayerForVoiceIndicatorWithMagicValuesWithRingColor:[UIColor accentColor]];
        self.voiceIndicatorLayer.bounds = CGRectMake(0, 0, 12, 12);
        [self.layer addSublayer:self.voiceIndicatorLayer];
        [self centerLayer:self.voiceIndicatorLayer];
    }
    
    [self.voiceIndicatorLayer setHidden:NO];
    [self.voiceIndicatorLayer startAnimating];
}

- (void)hideVoiceIndicator
{
    [self.voiceIndicatorLayer stopAnimating];
    [self.voiceIndicatorLayer setHidden:YES];
}

- (void)showPingIndicator
{
    if (self.pingLayer == nil) {
        self.pingLayer = [[PingAnimationLayer alloc] initWithColor:[UIColor accentColor]];
        [self.layer addSublayer:self.pingLayer];
        [self centerLayer:self.pingLayer];
    }
    
    [self.pingLayer setHidden:NO];
    [self.pingLayer startAnimating];
}

- (void)hidePingIndicator
{
    [self.pingLayer stopAnimating];
    [self.pingLayer setHidden:YES];
}

@end
