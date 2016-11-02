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


@import ZMCSystem;

#import "ZMVoiceChannelNotifications+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMNotifications+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const ZMVoiceChannelParticipantVoiceGainChangedNotificationName = @"ZMVoiceChannelParticipantVoiceGainChangedNotificationName";

@interface TokensContainer : NSObject <ZMVoiceChannelStateObserverOpaqueToken>
@property (nonatomic, strong) VoiceChannelStateObserverToken* stateToken;
@property (nonatomic, strong) id joinObserver;
- (void)tearDown;
@end

@implementation TokensContainer

- (void)tearDown
{
    [self.stateToken tearDown];
    [[NSNotificationCenter defaultCenter] removeObserver:self.joinObserver];
}

@end


@implementation ZMVoiceChannel (ChangeNotification)

- (id<ZMVoiceChannelStateObserverOpaqueToken>)addVoiceChannelStateObserver:(id<ZMVoiceChannelStateObserver>)observer;
{
    TokensContainer* token = [[TokensContainer alloc] init];
    ZMConversation *conversation = self.conversation;
    token.stateToken = [conversation.managedObjectContext.globalManagedObjectContextObserver addVoiceChannelStateObserver:observer conversation:conversation];
    NSManagedObjectID *conversationId = conversation.objectID;
    ZM_WEAK(observer);

    token.joinObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ZMConversationVoiceChannelJoinFailedNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
        ZM_STRONG(observer);
        if ([conversationId isEqual:note.object] && [observer respondsToSelector:@selector(voiceChannelJoinFailedWithError:)]) {            
            [observer voiceChannelJoinFailedWithError:note.userInfo[@"error"]];
        }
    }];
    
    return token;
}

- (void)removeVoiceChannelStateObserverForToken:(id<ZMVoiceChannelStateObserverOpaqueToken>)token;
{
    [(TokensContainer *)token tearDown];
}

+ (id<ZMVoiceChannelStateObserverOpaqueToken>)addGlobalVoiceChannelStateObserver:(id<ZMVoiceChannelStateObserver>)observer managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    return (id) [managedObjectContext.globalManagedObjectContextObserver addGlobalVoiceChannelObserver:observer];
}

+ (void)removeGlobalVoiceChannelStateObserverForToken:(id<ZMVoiceChannelStateObserverOpaqueToken>)token managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    [managedObjectContext.globalManagedObjectContextObserver removeGlobalVoiceChannelStateObserverForToken:token];
}

+ (nonnull id<ZMVoiceChannelStateObserverOpaqueToken>)addGlobalVoiceChannelStateObserver:(nonnull id<ZMVoiceChannelStateObserver>)observer inUserSession:(nonnull id<ZMManagedObjectContextProvider>)userSession;
{
    return [self addGlobalVoiceChannelStateObserver:observer managedObjectContext:userSession.managedObjectContext];
}

+ (void)removeGlobalVoiceChannelStateObserverForToken:(id<ZMVoiceChannelStateObserverOpaqueToken>)token inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    [self removeGlobalVoiceChannelStateObserverForToken:token managedObjectContext:userSession.managedObjectContext];
}


- (id<ZMVoiceChannelParticipantsObserverOpaqueToken>)addCallParticipantsObserver:(id<ZMVoiceChannelParticipantsObserver>)observer
{
    return (id)[self.conversation.managedObjectContext.globalManagedObjectContextObserver addCallParticipantsObserver:observer voiceChannel:self];
}

- (void)removeCallParticipantsObserverForToken:(id<ZMVoiceChannelParticipantsObserverOpaqueToken>)token
{
    [self.conversation.managedObjectContext.globalManagedObjectContextObserver removeCallParticipantsObserverForToken:(id)token];
}

@end




@implementation ZMVoiceChannelParticipantVoiceGainChangedNotification

+ (instancetype)notificationWithConversation:(ZMConversation *)conversation participant:(ZMUser *)user voiceGain:(double)voiceGain;
{
    ZMVoiceChannelParticipantVoiceGainChangedNotification *note = [[self alloc] initWithName:ZMVoiceChannelParticipantVoiceGainChangedNotificationName object:conversation];
    if (note != nil) {
        note.voiceGain = voiceGain;
        note.participant = user;
    }
    return note;
}

+ (void)addObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer;
{
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(voiceChannelParticipantVoiceGainDidChange:) name:ZMVoiceChannelParticipantVoiceGainChangedNotificationName object:nil]);
}

+ (void)addObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer forVoiceChannel:(ZMVoiceChannel *)voiceChannel;
{
    if (voiceChannel == nil) {
        return;
    }
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(voiceChannelParticipantVoiceGainDidChange:) name:ZMVoiceChannelParticipantVoiceGainChangedNotificationName object:voiceChannel.conversation]);
}

+ (void)removeObserver:(id<ZMVoiceChannelVoiceGainObserver>)observer;
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMVoiceChannelParticipantVoiceGainChangedNotificationName object:nil];
}

- (ZMVoiceChannel *)voiceChannel;
{
    ZMConversation *conversation = self.object;
    return conversation.voiceChannel;
}

@end

