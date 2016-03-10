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


#import "ZMNotificationDispatcher.h"
#import "ZMNotificationDispatcher+Private.h"
#import "ZMNotifications+Internal.h"
#import "ZMFunctional.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMFunctional.h"
#import "ZMManagedObjectContext.h"
#import "ZMConversationList+Internal.h"
#import "ZMCallParticipant.h"
#import "ZMVoiceChannelNotifications+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import "ZMUserDisplayNameGenerator.h"
#import "ZMEventID.h"
#import "ZMConversationList+Internal.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversationMessageWindow+Internal.h"
#import "ZMNotificationsFromObjectChanges.h"

#import <zmessaging/zmessaging-Swift.h>

static ZMLogLevel_t const ZMLogLevel ZM_UNUSED = ZMLogLevelWarn;

/// Set of ZMMessageWindowChangeToken. This collection is supposed to be used on the UI thread only
static NSMutableSet *WindowTokenList;



@interface ZMNotificationDispatcher ()

@property (nonatomic) NSManagedObjectContext *moc;
@property (nonatomic) ZMConversation *previousActiveVoiceChannelConversation;

@end



@implementation ZMNotificationDispatcher

- (instancetype)initWithContext:(NSManagedObjectContext *)moc
{
    ZMLogDebug(@"%@ %@: %@", self.class, NSStringFromSelector(_cmd), moc);
    VerifyReturnNil(moc != nil);
    Check(moc.zm_isUserInterfaceContext);
    self = [super init];
    if (self) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            WindowTokenList = [NSMutableSet set];
        });
        
        self.moc = moc;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(processChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:moc];
        
    }
    return self;
}

- (void)dealloc
{
    [self.moc performGroupedBlock:^{
        [WindowTokenList removeAllObjects];
    }];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)logChangeNotification:(NSNotification *)note;
{
    ZMLogDebug(@"%@", note.name);
    for (NSString *key in @[NSInsertedObjectsKey, NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSDeletedObjectsKey]) {
        NSSet *objects = note.userInfo[key];
        if (objects.count == 0) {
            continue;
        }
        BOOL const isUpdateOrRefresh = ([key isEqual:NSUpdatedObjectsKey] || [key isEqual:NSRefreshedObjectsKey]);
        ZMLogDebug(@"[%@]:", key);
        NSMutableArray *lines = [NSMutableArray array];
        for (NSManagedObject *mo in objects) {
            if (isUpdateOrRefresh) {
                [lines addObject:[NSString stringWithFormat:@"    <%@: %p> %@, keys: {%@}",
                                  mo.class, mo, mo.objectID.URIRepresentation,
                                  [[mo updatedKeysForChangeNotification].allObjects componentsJoinedByString:@", "]]];
            } else {
                [lines addObject:[NSString stringWithFormat:@"    <%@: %p> %@",
                                  mo.class, mo, mo.objectID.URIRepresentation]];
            }
        }
        ZM_ALLOW_MISSING_SELECTOR([lines sortUsingSelector:@selector(compare:)]);
        for (NSString *line in lines) {
            ZMLogDebug(@"%@", line);
        }
    }
}

- (void)processChangeNotification:(NSNotification *)note
{
    if (__builtin_expect((ZMLogLevelDebug <= ZMLogLevel),0)) {
        [self logChangeNotification:note];
    }
    
    [ZMNotificationsFromObjectChanges fireNotificationsForObjectDidChangeNotification:note managedObjectContext:self.moc previousActiveVoiceChannelConversation:self.previousActiveVoiceChannelConversation];
    self.previousActiveVoiceChannelConversation = [ZMVoiceChannel activeVoiceChannelInManagedObjectContext:self.moc].conversation;
}

@end



@implementation ZMNotificationDispatcher (Private)

+ (void)addConversationWindowChangeToken:(ZMMessageWindowChangeToken *)token
{
    [WindowTokenList addObject:token];
}

+ (void)removeConversationWindowChangeToken:(ZMMessageWindowChangeToken *)token
{
    [WindowTokenList removeObject:token];
    [token tearDown];
}

+ (void)notifyConversationWindowChangeTokensWithUpdatedMessages:(NSSet *)updatedMessages;
{
    for(ZMMessageWindowChangeToken *token in WindowTokenList) {
        [token conversationDidChange:updatedMessages.allObjects];
    }
}

@end
