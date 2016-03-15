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


@import UIKit;
@import CoreTelephony;
@import ZMUtilities;
@import ZMCSystem;
@import ZMTransport;

#import "ZMVoiceChannel+Internal.h"
#import "ZMVoiceChannel+Testing.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUserSession+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import <zmessaging/zmessaging-Swift.h>
#import "AVSFlowManager.h"
#import "ZMAVSBridge.h"
#import "NSError+ZMConversationInternal.h"


@implementation ZMVoiceChannelParticipantState

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:[ZMVoiceChannelParticipantState class]]) {
        return NO;
    }
    ZMVoiceChannelParticipantState *other = object;
    return ((other.connectionState == self.connectionState) &&
            (other.muted == self.muted));
}

- (NSString *)description;
{
    NSString *d;
    switch (self.connectionState) {
        default:
        case ZMVoiceChannelConnectionStateInvalid:
            d = @"Invalid";
            break;
        case ZMVoiceChannelConnectionStateNotConnected:
            d = @"NotConnected";
            break;
        case ZMVoiceChannelConnectionStateConnecting:
            d = @"Connecting";
            break;
        case ZMVoiceChannelConnectionStateConnected:
            d = @"Connected";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p> %@%@", self.class, self,
            d,
            self.muted ? @" muted" : @""];
}

@end




@interface ZMVoiceChannel ()

- (ZMVoiceChannelState)stateForIsSelfJoined:(BOOL)selfJoined otherJoined:(BOOL)otherJoined isDeviceActive:(BOOL)isDeviceActive flowActive:(BOOL)flowActive isIgnoringCall:(BOOL)isIgnoringCall;


@property (nonatomic) ZMTimer *timer;

@property (nonatomic) CTCallCenter *callCenter;

@end



@implementation ZMConversation (CallParticipants)

@dynamic callParticipants;

- (BOOL)hasActiveVoiceChannel
{
    return (self.callDeviceIsActive) || (self.callParticipants.count != 0);
}

- (ZMConversation *)firstOtherConversationWithActiveCall
{
    ZMConversation *otherActiveConversation = [self firstOtherConversationWithActiveCallOnCurrentDevice];
    if (otherActiveConversation == nil) {
        // If we don't have conversation with active call on this device,
        // there still could be conversation with active call on another device,
        // so we fetch conversations with call participants
        
        NSFetchRequest *request = [ZMConversation sortedFetchRequestWithPredicateFormat:@"(%K.@count > 0) AND self != %@",
                                   ZMConversationCallParticipantsKey,
                                   self];
        NSArray *result = [self.managedObjectContext executeFetchRequestOrAssert:request];
        otherActiveConversation = [result firstObjectMatchingWithBlock:^BOOL(ZMConversation *conv) {
            return (conv.voiceChannelState == ZMVoiceChannelStateDeviceTransferReady || conv.isIgnoringCall == NO);
        }];
    }
    return otherActiveConversation;
}

- (ZMVoiceChannelState)voiceChannelState
{
    VerifyReturnValue(self.managedObjectContext != nil, ZMVoiceChannelStateInvalid);

    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    ZMUser *otherUser = [self.callParticipants.array firstObjectMatchingWithBlock:^BOOL(ZMUser *user) {
        return user != selfUser;
    }];

    const BOOL selfJoined = [self.callParticipants containsObject:selfUser];
    const BOOL otherJoined = otherUser != nil;
    const BOOL isDeviceActive = self.callDeviceIsActive;
    const BOOL flowActive = self.isFlowActive;
    
    return [self.voiceChannel stateForIsSelfJoined:selfJoined otherJoined:otherJoined isDeviceActive:isDeviceActive flowActive:flowActive isIgnoringCall:self.isIgnoringCall];
}

+ (NSSet *)keyPathsForValuesAffectingVoiceChannelState {
    return [NSSet setWithArray:@[@"callParticipants", ZMConversationCallDeviceIsActiveKey, @"activeFlowParticipants"]];
}

@end





@implementation ZMVoiceChannel

- (instancetype)initWithConversation:(ZMConversation *)conversation;
{
    VerifyReturnNil(conversation != nil);
    self = [super init];
    if (self) {
        _conversation = conversation;
        NSManagedObjectContext *context = self.conversation.managedObjectContext;
        if (context.zm_isUserInterfaceContext) {
            self.callCenter = context.globalManagedObjectContextObserver.callCenter;
        }
    }
    return self;
}

- (instancetype)initWithConversation:(ZMConversation *)conversation callCenter:(CTCallCenter *)callCenter
{
    self = [self initWithConversation:conversation];
    self.callCenter = callCenter;
    return self;
}

static NSString *lastSessionIdentifier;
static NSDate *lastSessionStartDate;
static dispatch_queue_t lastSessionIdentifierIsolation(void)
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("ZMVoiceChannel.lastSessionIdentifier", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (void)setLastSessionIdentifier:(NSString *)sessionID;
{
    sessionID = [sessionID copy];
    dispatch_barrier_async(lastSessionIdentifierIsolation(), ^{
        lastSessionIdentifier = sessionID;
    });
}

+ (NSString *)lastSessionIdentifier;
{
    __block NSString *result;
    dispatch_sync(lastSessionIdentifierIsolation(), ^{
        result = [lastSessionIdentifier copy];
    });
    return result;
}

+ (void)setLastSessionStartDate:(NSDate *)date;
{
    date = [date copy];
    dispatch_barrier_async(lastSessionIdentifierIsolation(), ^{
        lastSessionStartDate = date;
    });
}

+ (NSDate *)lastSessionStartDate;
{
    __block NSDate *result;
    dispatch_sync(lastSessionIdentifierIsolation(), ^{
        result = [lastSessionStartDate copy];
    });
    return result;
}

- (AVSFlowManager *)flowManager
{
    return [[ZMAVSBridge flowManagerClass] getInstance];
}

- (ZMVoiceChannelState)stateForIsSelfJoined:(BOOL)selfJoined otherJoined:(BOOL)otherJoined isDeviceActive:(BOOL)isDeviceActive flowActive:(BOOL)flowActive isIgnoringCall:(BOOL)isIgnoringCall
{
    const BOOL selfActiveInCall = selfJoined || isDeviceActive;
    ZMConversation *conversation = self.conversation;
    
    if (!conversation.isSelfAnActiveMember) {
        return ZMVoiceChannelStateNoActiveUsers;
    }
    else if (isIgnoringCall) {
        if (conversation.conversationType == ZMConversationTypeOneOnOne ||
            (conversation.isOutgoingCall && !otherJoined)) // we cancelled an outgoing call
        {
            return ZMVoiceChannelStateNoActiveUsers;
        }
        
        if (otherJoined) {
            return ZMVoiceChannelStateIncomingCallInactive;
        }
        else {
            return ZMVoiceChannelStateNoActiveUsers;
        }
    }
    else if (selfJoined && !isDeviceActive && !conversation.isOutgoingCall)
    {
        return ZMVoiceChannelStateDeviceTransferReady;
    }
    else if(selfActiveInCall && !otherJoined) {
        return [self currentOutgoingCallState];
    }
    else if (!selfActiveInCall && otherJoined) {
        return [self currentIncomingCallState];
    }
    else if (selfActiveInCall && otherJoined) {
        if (flowActive) {
            return ZMVoiceChannelStateSelfConnectedToActiveChannel;
        }
        else if (conversation.isOutgoingCall && conversation.conversationType == ZMConversationTypeOneOnOne){
            return [self currentOutgoingCallState];
        }
        else {
            return ZMVoiceChannelStateSelfIsJoiningActiveChannel;
        }
    } else {
        return  ZMVoiceChannelStateNoActiveUsers;
    }
    
}


- (ZMVoiceChannelState)currentOutgoingCallState
{
    return self.conversation.callTimedOut ? ZMVoiceChannelStateOutgoingCallInactive :ZMVoiceChannelStateOutgoingCall;
}

- (ZMVoiceChannelState)currentIncomingCallState
{
    return self.conversation.callTimedOut ? ZMVoiceChannelStateIncomingCallInactive : ZMVoiceChannelStateIncomingCall;

}

- (void)startOrCancelTimerForState:(ZMVoiceChannelState)state
{
    switch (state) {
        case ZMVoiceChannelStateNoActiveUsers:
        case ZMVoiceChannelStateSelfConnectedToActiveChannel:
        case ZMVoiceChannelStateSelfIsJoiningActiveChannel:
        case ZMVoiceChannelStateDeviceTransferReady:
        case ZMVoiceChannelStateInvalid:
            [self resetTimer];
            break;
        case ZMVoiceChannelStateOutgoingCall:
        case ZMVoiceChannelStateIncomingCall:
            if (self.conversation.callParticipants.count > 0) {
                [self startTimer];
            } else {
                // the timer should only be started when there are callParticipants
                // if there are no call participants, but callDeviceIsActive is set, we were previously joined
                [self resetTimer];
            }
            break;
        case ZMVoiceChannelStateIncomingCallInactive:
        case ZMVoiceChannelStateOutgoingCallInactive:
            break;
    }
}

- (ZMVoiceChannelState)state;
{
    return self.conversation.voiceChannelState;
}

+ (instancetype)activeVoiceChannelInSession:(ZMUserSession *)session;
{
    return [self activeVoiceChannelInManagedObjectContext:session.managedObjectContext];
}

+ (instancetype)activeVoiceChannelInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    __block ZMConversation *activeConversation;
    [ZMConversation enumerateObjectsInContext:moc withBlock:^(ZMManagedObject *object, BOOL *stop) {
        ZMConversation *conversation = (ZMConversation *)object;
        if(conversation.voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel) {
            *stop = YES;
            activeConversation = conversation;
        }
    }];
    return activeConversation.voiceChannel;
}

- (void)join
{
    ZMConversation *conv = self.conversation;
    
    if ([self hasOngoingGSMCall]) {
        dispatch_async(dispatch_get_main_queue(), ^{
                [CallingInitialisationNotification notifyCallingFailedWithErrorCode:ZMVoiceChannelErrorCodeOngoingGSMCall];
            });
        return;
    }
   
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ZMTransportSessionShouldKeepWebsocketOpenNotificationName object:self userInfo:@{ZMTransportSessionShouldKeepWebsocketOpenKey: @YES}];
    });
    
    if(!conv.callDeviceIsActive) {
        [ZMUserSession appendAVSLogMessageForConversation:conv withMessage:@"Self user wants to join voice channel"];
    }
    conv.isOutgoingCall = (conv.callParticipants.count == 0);
    conv.isIgnoringCall = NO;
    conv.callDeviceIsActive = YES;
}


- (BOOL)hasOngoingGSMCall
{
    NSSet *connectedCalls = [self.callCenter.currentCalls filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CTCall *call, ZM_UNUSED id bindings) {
        return [call.callState isEqualToString:CTCallStateConnected];
    }]];
    if (connectedCalls.count > 0) {
        return YES;
    }
    return NO;
}


- (void)leave;
{
    [self leaveWithReason:ZMCallStateReasonToLeaveUser];
}

- (void)leaveOnAVSError
{
    [self leaveWithReason:ZMCallStateReasonToLeaveAVSError];
}

- (void)leaveWithReason:(ZMCallStateReasonToLeave)reasonToLeave
{
    ZMConversation *conv = self.conversation;
    
    if (conv.isVideoCall) {
        [self.flowManager setVideoSendState:FLOWMANAGER_VIDEO_SEND_NONE forConversation:conv.remoteIdentifier.transportString];
    }
    
    if (conv.callDeviceIsActive) {
        NSString *leaveMessage = [NSString stringWithFormat:@"Left voice channel: reason is %@", [ZMCallStateReasonToLeaveDescriber reasonToLeaveToString:reasonToLeave]];
        [ZMUserSession appendAVSLogMessageForConversation:conv withMessage:leaveMessage];
    }
    conv.callDeviceIsActive = NO;
    conv.reasonToLeave = reasonToLeave;
    
    if (conv.conversationType != ZMConversationTypeOneOnOne) {
        conv.isIgnoringCall = YES; // when selfUser leaves call we don't want it to ring
    }
    
    if (conv.callParticipants.count <= 2) {
        [self resetCallState];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMTransportSessionShouldKeepWebsocketOpenNotificationName object:self userInfo:@{ZMTransportSessionShouldKeepWebsocketOpenKey: @NO}];
}

+ (NSComparator)conferenceComparator
{
    Class flowManagerClass = [ZMAVSBridge flowManagerClass];
    NSComparator result = [flowManagerClass conferenceComparator];
    if (result == nil) {
        result = ^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        };
    }
    return result;
}

- (void)updateActiveFlowParticipants:(NSArray *)newParticipants
{
    ZMConversation *conv = self.conversation;
    if ([conv.activeFlowParticipants isEqual:newParticipants]) {
        return;
    }
    if (conv.isOutgoingCall) {
        conv.isOutgoingCall = NO; // reset outgoingCall State, so that the phone does not start ringing if the flow gets interrupted
    }
    NSMutableOrderedSet *mutableParticipants = [NSMutableOrderedSet orderedSetWithArray:newParticipants];

    [mutableParticipants zm_sortUsingComparator:[self.class conferenceComparator] valueGetter:^id(ZMUser *user) {
        return user.remoteIdentifier.UUIDString;
    }];

    conv.activeFlowParticipants = [NSOrderedSet orderedSetWithOrderedSet:mutableParticipants];
    [self updateForStateChange];
}

- (void)addCallParticipant:(ZMUser *)participant
{
    NSMutableOrderedSet *participants = [self.conversation mutableOrderedSetValueForKey:ZMConversationCallParticipantsKey];
    [participants addObject:participant];
    
    [self reSortCallParticipants:participants];

    [self updateForStateChange];    
}

- (void)removeCallParticipant:(ZMUser *)participant
{
    ZMConversation *conversation = self.conversation;
    
    NSMutableOrderedSet *participants = [conversation mutableOrderedSetValueForKey:ZMConversationCallParticipantsKey];
    [participants removeObject:participant];
    
    if (participant.isSelfUser) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZMTransportSessionShouldKeepWebsocketOpenNotificationName
                                                            object:self
                                                          userInfo:@{ZMTransportSessionShouldKeepWebsocketOpenKey: @NO}];
    }
    
    if (participants.count > 0) {
        [self reSortCallParticipants:participants];
        if (participant.isSelfUser) {
            conversation.isIgnoringCall = YES;
        }
    }
    else {
        [self resetCallState];
    }

    [self updateForStateChange];
}

- (void)reSortCallParticipants:(NSMutableOrderedSet *)participants
{    
    [participants zm_sortUsingComparator:[self.class conferenceComparator] valueGetter:^id(ZMUser *user) {
        return user.remoteIdentifier.UUIDString;
    }];
}

- (void)removeAllCallParticipants
{
    if (self.conversation.callParticipants.count == 0) {
        return;
    }
    [self resetCallState];
    [self updateForStateChange];
}

- (void)resetCallState
{
    ZMConversation *conversation = self.conversation;
    NSMutableOrderedSet *callParticipants = [conversation mutableOrderedSetValueForKey:ZMConversationCallParticipantsKey];
    [callParticipants removeAllObjects];
    
    conversation.callTimedOut = NO;
    conversation.isIgnoringCall = NO;
    conversation.isOutgoingCall = NO;
    conversation.isVideoCall = NO;
    conversation.isSendingVideo = NO;
    conversation.isFlowActive = NO;
    conversation.activeFlowParticipants = [NSOrderedSet orderedSet];
    conversation.otherActiveVideoCallParticipants = [NSOrderedSet orderedSet];
    if (conversation.managedObjectContext.zm_isSyncContext) {
        [conversation.managedObjectContext zm_resetCallTimer:conversation];
    }
}

- (void)enumerateParticipantStatesWithBlock:(void(^)(ZMUser *user, ZMVoiceChannelConnectionState connectionState, BOOL muted))block;
{
    [self.conversation.callParticipants.array enumerateObjectsUsingBlock:^(ZMUser *user, ZM_UNUSED NSUInteger idx, ZM_UNUSED BOOL *stop) {
        if(block) {
            ZMVoiceChannelParticipantState *state = [self participantStateForUser:user];
            block(user, state.connectionState, state.muted);
        }
    }];
}

- (NSOrderedSet *)participants;
{
    ZMConversation *conversation = self.conversation;
    ZMUser *selfUser = [ZMUser selfUserInContext:conversation.managedObjectContext];
    NSMutableOrderedSet *participants = conversation.callParticipants.mutableCopy;
    [participants removeObject:selfUser];
    return participants;
}

+ (ZMVoiceChannelParticipantState *)participantStateForCallUserWithIsJoined:(BOOL)joined flowActive:(BOOL)flowActive
{
    ZMVoiceChannelParticipantState *state = [[ZMVoiceChannelParticipantState alloc] init];
    if (! joined) {
        state.connectionState = ZMVoiceChannelConnectionStateNotConnected;
    } else if (flowActive) {
        state.connectionState = ZMVoiceChannelConnectionStateConnected;
    } else {
        state.connectionState = ZMVoiceChannelConnectionStateConnecting;
    }
    return state;
}

- (ZMVoiceChannelParticipantState *)participantStateForUser:(ZMUser *)user;
{
    ZMConversation *conversation = self.conversation;
    const BOOL joined = [conversation.callParticipants containsObject:user];
    const BOOL flowActive = user.isSelfUser ? conversation.isFlowActive : [conversation.activeFlowParticipants containsObject:user];
    ZMVoiceChannelParticipantState *state = [self.class participantStateForCallUserWithIsJoined:joined flowActive:flowActive];
    state.isSendingVideo = user.isSelfUser ? conversation.isSendingVideo : [conversation.otherActiveVideoCallParticipants containsObject:user];
    return state;
}

- (ZMVoiceChannelConnectionState)selfUserConnectionState;
{
    ZMConversation *conv = self.conversation;
    ZMVoiceChannelParticipantState *state = [self participantStateForUser:[ZMUser selfUserInContext:conv.managedObjectContext]];
    return state.connectionState;
}

- (void)ignoreIncomingCall
{
    ZMConversation *conv = self.conversation;
    
    if(!conv.isIgnoringCall) {
        [ZMUserSession appendAVSLogMessageForConversation:conv withMessage:@"Self user wants to ignore incoming call"];
    }
    conv.isIgnoringCall = YES;
}

- (void)updateForStateChange
{
    [self startOrCancelTimerForState:self.state];
    
    if (self.conversation.isVideoCall) {
        NSError *error = nil;
        if (self.state == ZMVoiceChannelStateIncomingCall || self.state == ZMVoiceChannelStateOutgoingCall) {

            [self setVideoSendState:FLOWMANAGER_VIDEO_PREVIEW error:&error];
            
            if (nil != error) {
                ZMLogError(@"Cannot set video send state: %@", error);
            }
        }
        else if (self.state == ZMVoiceChannelStateNoActiveUsers) {
            [self setVideoSendState:FLOWMANAGER_VIDEO_SEND_NONE error:&error];
            
            if (nil != error) {
                ZMLogError(@"Cannot set video send state: %@", error);
            }
        }
    }
}


- (void)tearDown
{
    if (!self.conversation.managedObjectContext.zm_isSyncContext) {
        return;
    }
    [self resetTimer];
}

- (id<CallingInitialisationObserverToken>)addCallingInitializationObserver:(id<CallingInitialisationObserver>)observer;
{
    ZM_WEAK(observer);
    return (id<CallingInitialisationObserverToken>)[CallingInitialisationNotification addObserverWithBlock:^(CallingInitialisationNotification * notification) {
        ZM_STRONG(observer);
        if ([observer respondsToSelector:@selector(couldNotInitialiseCallWithError:)]) {
            [observer couldNotInitialiseCallWithError:notification.error];
        }
    }];
}

- (void)removeCallingInitialisationObserver:(id<CallingInitialisationObserverToken>)token;
{
    [CallingInitialisationNotification removeObserver:token];
}


@end


@implementation ZMVoiceChannel (TimerClient)

- (void)startTimer
{
    ZMConversation *conversation = self.conversation;
    RequireString(conversation.managedObjectContext.zm_isSyncContext, "Timer can not be started on uiContext");
    [conversation.managedObjectContext zm_addAndStartCallTimer:conversation];
}

- (void)resetTimer
{
    ZMConversation *conversation = self.conversation;
    RequireString(conversation.managedObjectContext.zm_isSyncContext, "Timer can not be reset on uiContext");
    [conversation.managedObjectContext zm_resetCallTimer:conversation];
    conversation.callTimedOut = NO;
}

- (void)callTimerDidFire:(ZMCallTimer * __unused)timer
{
    ZMConversation *syncConv = self.conversation;
    RequireString(syncConv.managedObjectContext.zm_isSyncContext, "Firing timer was started on wrong context");

    NSManagedObjectContext *context = [NSManagedObjectContext createUserInterfaceContext];
    ZMConversation *uiConv = (id)[context objectWithID:syncConv.objectID];
    if (uiConv == nil || uiConv.isZombieObject) {
        return;
    }
    
    [context performGroupedBlock:^{
        if (uiConv.conversationType == ZMConversationTypeGroup ||
            (uiConv.conversationType == ZMConversationTypeOneOnOne && !uiConv.isOutgoingCall)) {
            uiConv.callTimedOut = YES;
        } else if (uiConv.conversationType == ZMConversationTypeOneOnOne && uiConv.isOutgoingCall) {
            [uiConv.voiceChannel leave];
        }
        [context enqueueDelayedSave];
    }];
}

@end



@implementation ZMVoiceChannel (ZMDebug)

+ (NSAttributedString *)voiceChannelDebugInformationInUserSession:(ZMUserSession *)userSession;
{
    return [self voiceChannelDebugInformationInContext:userSession.managedObjectContext];
}

+ (NSAttributedString *)voiceChannelDebugInformationInContext:(NSManagedObjectContext * __unused)moc;
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    UIFont *font = [UIFont systemFontOfSize:11];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:11];

    NSDictionary *attributes = @{NSFontAttributeName: font};
    NSDictionary *boldAttributes = @{NSFontAttributeName: boldFont};

    void(^append)(NSString *) = ^(NSString *text){
        NSAttributedString *s = [[NSAttributedString alloc] initWithString:text ?: @"" attributes:attributes];
        [result appendAttributedString:s];
    };
    void(^appendBold)(NSString *) = ^(NSString *text){
        NSAttributedString *s = [[NSAttributedString alloc] initWithString:text ?: @"" attributes:boldAttributes];
        [result appendAttributedString:s];
    };

    // Session ID
    append(@"Session ID: ");
    appendBold(self.lastSessionIdentifier);
    append(@"\n");

    // Session date:
    append(@"Session start date: ");
    NSDate *date = [self lastSessionStartDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.dateStyle = kCFDateFormatterLongStyle;
    formatter.timeStyle = kCFDateFormatterLongStyle;
    appendBold(date == nil ? @"" : [formatter stringFromDate:date]);
    append(@"\n");
    // Session date in GMT:
    append(@"Session start date (GMT): ");
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    appendBold(date == nil ? @"" : [formatter stringFromDate:date]);
    append(@"\n");

    return result;
}

@end
