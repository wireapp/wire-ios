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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import <zmessaging/ZMNotifications.h>
#import <zmessaging/ZMVoiceChannel.h>



@class ZMUser;
@class VoiceChannelStateChangeInfo;
@class VoiceChannelParticipantsChangeInfo;
@protocol ZMVoiceChannelStateObserver;
@protocol ZMVoiceChannelVoiceGainObserver;
@protocol ZMVoiceChannelParticipantsObserver;

@protocol ZMVoiceChannelStateObserverOpaqueToken
@end

@protocol ZMVoiceChannelParticipantsObserverOpaqueToken
@end

@interface ZMVoiceChannel (ChangeNotification)

- (id<ZMVoiceChannelStateObserverOpaqueToken>)addVoiceChannelStateObserver:(id<ZMVoiceChannelStateObserver>)observer;
- (void)removeVoiceChannelStateObserverForToken:(id<ZMVoiceChannelStateObserverOpaqueToken>)token;

+ (id<ZMVoiceChannelStateObserverOpaqueToken>)addGlobalVoiceChannelStateObserver:(id<ZMVoiceChannelStateObserver>)observer inUserSession:(ZMUserSession *)userSession;
+ (void)removeGlobalVoiceChannelStateObserverForToken:(id<ZMVoiceChannelStateObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession;

- (id<ZMVoiceChannelParticipantsObserverOpaqueToken>)addCallParticipantsObserver:(id<ZMVoiceChannelParticipantsObserver>)observer;
- (void)removeCallParticipantsObserverForToken:(id<ZMVoiceChannelParticipantsObserverOpaqueToken>)token;

@end




@interface ZMVoiceChannelParticipantVoiceGainChangedNotification : ZMNotification

@property (nonatomic, readonly) ZMVoiceChannel *voiceChannel;
@property (nonatomic, readonly) ZMUser *participant;
@property (nonatomic, readonly) double voiceGain;

+ (void)addObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer;
/// Passing @c nil for @a voiceChannel is a no-op, i.e. does not add the observer.
+ (void)addObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer forVoiceChannel:(ZMVoiceChannel *)voiceChannel;
+ (void)removeObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer;

@end



@protocol ZMVoiceChannelStateObserver <NSObject>

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)info;

@optional
- (void)voiceChannelJoinFailedWithError:(NSError *)error;
@end



@protocol ZMVoiceChannelParticipantsObserver

- (void)voiceChannelParticipantsDidChange:(VoiceChannelParticipantsChangeInfo *)info;

@end



@protocol ZMVoiceChannelVoiceGainObserver

- (void)voiceChannelParticipantVoiceGainDidChange:(ZMVoiceChannelParticipantVoiceGainChangedNotification *)info;

@end
