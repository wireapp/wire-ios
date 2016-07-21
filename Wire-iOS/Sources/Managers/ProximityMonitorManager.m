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


#import "ProximityMonitorManager.h"
#import "zmessaging+iOS.h"
#import "Constants.h"
#import "ZClientViewController.h"
#import "avs+iOS.h"
#import "Settings.h"
#import "Wire-Swift.h"


@interface ProximityMonitorManager() <ZMVoiceChannelStateObserver, AVSMediaManagerClientObserver>

@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;
@property (nonatomic) ZMVoiceChannelState lastVoiceChannelState;

@end



@implementation ProximityMonitorManager

- (id)init
{
    self = [super init];
    
    if (self) {
        self.voiceChannelStateObserverToken = [ZMVoiceChannel addGlobalVoiceChannelStateObserver:self inUserSession:[ZMUserSession sharedSession]];

        // Wait and then update initial state so that getting the voice channel doesn't affect startup time
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ZMVoiceChannel *activeVoiceChannel = [SessionObjectCache sharedCache].firstActiveVoiceChannel;
            self.lastVoiceChannelState = activeVoiceChannel.state;
            [self updateProximityMonitorState];
        });
        
        if (![[Settings sharedSettings] disableAVS]) {
            [AVSMediaManagerClientChangeNotification addObserver:self];
        }
    }
    return self;
}

- (void)dealloc
{
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
    [ZMVoiceChannel removeGlobalVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken inUserSession:[ZMUserSession sharedSession]];
}

- (void)updateProximityMonitorState
{
    // Don't use proximity monitoring on the ipad
    if (IS_IPAD) {
        return;
    }
    
    if (self.lastVoiceChannelState == ZMVoiceChannelStateOutgoingCall) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
    else {
        BOOL isConnectingOrActive = self.lastVoiceChannelState == ZMVoiceChannelStateSelfConnectedToActiveChannel ||
                                    self.lastVoiceChannelState == ZMVoiceChannelStateSelfIsJoiningActiveChannel ||
                                    self.lastVoiceChannelState == ZMVoiceChannelStateOutgoingCallInactive;
        
        if (isConnectingOrActive && [[AVSProvider shared] mediaManager].speakerEnabled == NO) {
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        }
        else {
            [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        }
    }
}

#pragma mark - ZMVoiceChannelStateObserver

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    self.lastVoiceChannelState = change.voiceChannel.state;
    [self updateProximityMonitorState];
}

#pragma mark - AVSMediaManagerClientObserver

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    if (notification.speakerEnableChanged) {
        [self updateProximityMonitorState];
    }
}

@end
