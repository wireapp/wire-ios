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


#import "ZMVoiceChannel.h"
@class ZMCallTimer;
@class AVSFlowManager;


@protocol ZMCallTimerClient <NSObject>

- (void)callTimerDidFire:(ZMCallTimer *)timer;

@end



@interface ZMVoiceChannel ()

@property (nonatomic, copy) NSString *currentVideoDeviceID;

- (instancetype)initWithConversation:(ZMConversation *)conversation NS_DESIGNATED_INITIALIZER;
- (ZMVoiceChannelState)stateForIsSelfJoined:(BOOL)selfJoined otherJoined:(BOOL)otherJoined isDeviceActive:(BOOL)isDeviceActive flowActive:(BOOL)flowActive isIgnoringCall:(BOOL)isIgnoringCall;
+ (ZMVoiceChannelParticipantState *)participantStateForCallUserWithIsJoined:(BOOL)joined flowActive:(BOOL)flowActive;
+ (instancetype)activeVoiceChannelInManagedObjectContext:(NSManagedObjectContext *)moc;

+ (void)setLastSessionIdentifier:(NSString *)sessionID; ///< Thread safe setter
+ (NSString *)lastSessionIdentifier; ///< Thread safe getter

+ (void)setLastSessionStartDate:(NSDate *)date; ///< Thread safe setter
+ (NSDate *)lastSessionStartDate; ///< Thread safe getter



- (void)updateActiveFlowParticipants:(NSArray *)newParticipants;
- (void)addCallParticipant:(ZMUser *)participant;
- (void)removeCallParticipant:(ZMUser *)participant;
- (void)removeAllCallParticipants;
- (void)leaveOnAVSError;

- (void)updateForStateChange;
// removes call participants and resets state to no call whatsoever
- (void)resetCallState;


+ (NSComparator)conferenceComparator;
- (AVSFlowManager *)flowManager;
@end


@interface ZMVoiceChannel (TimerClient) <ZMCallTimerClient>

- (void)callTimerDidFire:(ZMCallTimer *)timer;
- (void)startTimer;
- (void)resetTimer;

@end


@interface ZMVoiceChannelParticipantState ()

@property (nonatomic) ZMVoiceChannelConnectionState connectionState;
@property (nonatomic) BOOL muted;
@property (nonatomic) BOOL isSendingVideo;
@end



@interface ZMConversation (CallParticipants)

@property (nonatomic, readonly) NSOrderedSet *callParticipants;
@property (nonatomic, readonly) ZMVoiceChannelState voiceChannelState;
// this will fetch conversation with active call participants, works across devices
@property (nonatomic, readonly) ZMConversation *firstOtherConversationWithActiveCall;
@property (nonatomic, readonly) BOOL hasActiveVoiceChannel;

@end
