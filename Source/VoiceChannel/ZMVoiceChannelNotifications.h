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


#import "ZMNotifications.h"
#import "ZMVoiceChannel.h"



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

- (nullable id<ZMVoiceChannelStateObserverOpaqueToken>)addVoiceChannelStateObserver:(nonnull id<ZMVoiceChannelStateObserver>)observer;
- (void)removeVoiceChannelStateObserverForToken:(nonnull id<ZMVoiceChannelStateObserverOpaqueToken>)token;

+ (nullable id<ZMVoiceChannelStateObserverOpaqueToken>)addGlobalVoiceChannelStateObserver:(nonnull id<ZMVoiceChannelStateObserver>)observer managedObjectContext:(nonnull NSManagedObjectContext *)managedObjectContext;
+ (void)removeGlobalVoiceChannelStateObserverForToken:(nonnull id<ZMVoiceChannelStateObserverOpaqueToken>)token managedObjectContext:(nonnull NSManagedObjectContext *)managedObjectContext;

+ (nonnull id<ZMVoiceChannelStateObserverOpaqueToken>)addGlobalVoiceChannelStateObserver:(nonnull id<ZMVoiceChannelStateObserver>)observer inUserSession:(nonnull id<ZMManagedObjectContextProvider>)userSession;
+ (void)removeGlobalVoiceChannelStateObserverForToken:(nonnull id<ZMVoiceChannelStateObserverOpaqueToken>)token inUserSession:(nonnull id<ZMManagedObjectContextProvider>)userSession;

- (nonnull id<ZMVoiceChannelParticipantsObserverOpaqueToken>)addCallParticipantsObserver:(nullable id<ZMVoiceChannelParticipantsObserver>)callParticipantsObserver;
- (void)removeCallParticipantsObserverForToken:(nonnull  id<ZMVoiceChannelParticipantsObserverOpaqueToken>)token;

@end




@interface ZMVoiceChannelParticipantVoiceGainChangedNotification : ZMNotification

@property (nonatomic, readonly, nonnull) ZMVoiceChannel *voiceChannel;
@property (nonatomic, readonly, nonnull) ZMUser *participant;
@property (nonatomic, readonly) double voiceGain;

+ (void)addObserver:(nonnull id<ZMVoiceChannelVoiceGainObserver>)observer;
/// Passing @c nil for @a voiceChannel is a no-op, i.e. does not add the observer.
+ (void)addObserver:(nonnull  id<ZMVoiceChannelVoiceGainObserver>)observer forVoiceChannel:(nonnull ZMVoiceChannel *)voiceChannel;
+ (void)removeObserver:(nonnull id<ZMVoiceChannelVoiceGainObserver>)observer;

@end



@protocol ZMVoiceChannelStateObserver <NSObject>

- (void)voiceChannelStateDidChange:(nonnull VoiceChannelStateChangeInfo *)info;

@optional
- (void)voiceChannelJoinFailedWithError:(nonnull NSError *)error;
@end



@protocol ZMVoiceChannelParticipantsObserver

- (void)voiceChannelParticipantsDidChange:(nonnull VoiceChannelParticipantsChangeInfo *)info;

@end



@protocol ZMVoiceChannelVoiceGainObserver

- (void)voiceChannelParticipantVoiceGainDidChange:(nonnull ZMVoiceChannelParticipantVoiceGainChangedNotification *)info;

@end
