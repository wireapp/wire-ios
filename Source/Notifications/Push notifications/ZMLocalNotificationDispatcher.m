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


@import ZMCSystem;
@import ZMTransport;
@import ZMUtilities;
@import ZMCDataModel;

#import "ZMLocalNotificationDispatcher+Testing.h"
#import "ZMLocalNotification.h"
#import "ZMBadge.h"
#import "ZMPushRegistrant.h"
#import <zmessaging/zmessaging-Swift.h>

NSString * ZMLocalNotificationDispatcherUIApplicationClass = @"UIApplication";
NSString * const ZMConversationCancelNotificationForIncomingCallNotificationName = @"ZMConversationCancelNotificationForIncomingCallNotification";


@interface ZMLocalNotificationDispatcher ()

@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic) NSArray *eventsNotifications;
@property (nonatomic) NSMutableSet *failedMessageNotifications;
@property (nonatomic) BOOL isTornDown;
@property (nonatomic) ZMApplication *sharedApplication;


@end



@implementation ZMLocalNotificationDispatcher

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc sharedApplication:(ZMApplication *)sharedApplication
{
    self = [super init];
    if (self) {
        self.syncMOC = moc;
        self.eventsNotifications = [NSArray array];
        self.failedMessageNotifications = [NSMutableSet set];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelNotificationsForNote:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelNotificationForIncomingCallInConversation:) name:ZMConversationCancelNotificationForIncomingCallNotificationName object:nil];

        self.sharedApplication = sharedApplication;
    }
    return self;
}

- (void)tearDown;
{
    self.isTornDown = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllNotifications];
}

- (void)dealloc
{
    Require(self.isTornDown);
}


- (void)cancelNotificationForIncomingCallInConversation:(NSNotification *)notification
{
    ZMConversation *conversation = (id)notification.object;
    if ([conversation isIgnoringCall]) {
        [self cancelNotificationForConversation:conversation];
    }
}
- (void)cancelNotificationsForNote:(NSNotification *)note
{
    if ([self.sharedApplication applicationState] == UIApplicationStateBackground) {
        return;
    }
    ZMConversation *uiConversation = note.object;
    [self.syncMOC performGroupedBlock:^{
        ZMConversation *syncConversation = (id)[self.syncMOC objectWithID:uiConversation.objectID];
        [self cancelNotificationForConversation:syncConversation];
    }];
}

- (void)cancelAllNotifications
{
    for (ZMLocalNotificationForEvent *note in self.eventsNotifications) {
        for (UILocalNotification *notification in note.notifications) {
            [self.sharedApplication cancelLocalNotification:notification];
        }
    }
    for(ZMLocalNotificationForExpiredMessage *note in self.failedMessageNotifications) {
        [self.sharedApplication cancelLocalNotification:note.uiNotification];
    }
    [self.failedMessageNotifications removeAllObjects];
    
    self.eventsNotifications = [NSArray array];
}

- (void)cancelNotificationForConversation:(ZMConversation *)conversation
{
    NSMutableArray *notifications = [NSMutableArray array];
    
    for (ZMLocalNotificationForEvent *note in self.eventsNotifications) {
        if (note.conversation == conversation) {
            for (UILocalNotification *notification in note.notifications) {
                [self.sharedApplication cancelLocalNotification:notification];
            }
        }
        else {
            [notifications addObject:note];
        }
    }
    
    [self cancelAllMessageFailedNotificationsForConversations:conversation];
    
    self.eventsNotifications = notifications;
}

- (void)didReceiveUpdateEvents:(NSArray <ZMUpdateEvent *>*)events notificationID:(NSUUID *)notificationID
{
    ZMLogPushKit(@"Processing push events (a) %p (count = %u)", events, (unsigned) events.count);    
    for (ZMUpdateEvent *event in events) {
        
        ZMLocalNotificationForEvent *note = [self notificationForEvent:event];
        if (note != nil && note.notifications.count > 0) {
            UIApplication *sharedApplication = self.sharedApplication;
            UILocalNotification *localNote = note.notifications.lastObject;
            ZMLogPushKit(@"Scheduling local notification <%@: %p> '%@'", localNote.class, localNote, localNote.alertBody);
            [sharedApplication scheduleLocalNotification:localNote];
            [APNSPerformanceTracker trackVOIPNotificationInNotificationDispatcher:notificationID analytics:self.syncMOC.analytics];
        }
    }
}

- (void)didFailToSentMessage:(ZMMessage *)message;
{
    if (message.visibleInConversation == nil || message.conversation.conversationType == ZMConversationTypeSelf) {
        return;
    }
    ZMLocalNotificationForExpiredMessage *note = [[ZMLocalNotificationForExpiredMessage alloc] initWithExpiredMessage:message];
    [self.sharedApplication scheduleLocalNotification:note.uiNotification];
    [self.failedMessageNotifications addObject:note];
}

- (void)didFailToSendMessageInConversation:(ZMConversation *)conversation;
{
    ZMLocalNotificationForExpiredMessage *note = [[ZMLocalNotificationForExpiredMessage alloc] initWithConversation:conversation];
    [self.sharedApplication scheduleLocalNotification:note.uiNotification];
    [self.failedMessageNotifications addObject:note];
}


- (void)cancelAllMessageFailedNotificationsForConversations:(ZMConversation *)conversation;
{
    NSMutableSet *toRemove = [NSMutableSet set];
    for(ZMLocalNotificationForExpiredMessage *note in self.failedMessageNotifications) {
        if(note.conversation == conversation) {
            [toRemove addObject:note];
            [self.sharedApplication cancelLocalNotification:note.uiNotification];
        }
    }
    
    [self.failedMessageNotifications minusSet:toRemove];
}

- (ZMLocalNotificationForEvent *)notificationForEvent:(ZMUpdateEvent *)event
{
    switch (event.type) {
        case ZMUpdateEventConversationAssetAdd:
        case ZMUpdateEventConversationConnectRequest:
        case ZMUpdateEventConversationKnock:
        case ZMUpdateEventConversationMessageAdd:
        case ZMUpdateEventConversationMemberJoin:
        case ZMUpdateEventConversationMemberLeave:
        case ZMUpdateEventConversationRename:
        case ZMUpdateEventUserConnection:
        case ZMUpdateEventConversationCreate:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        case ZMUpdateEventUserContactJoin:
        case ZMUpdateEventCallState:
            return [self localNotificationForEvent:event];
            
        case ZMUpdateEventConversationVoiceChannel:
        case ZMUpdateEventCallCandidatesAdd:
        case ZMUpdateEventCallCandidatesUpdate:
        case ZMUpdateEventCallDeviceInfo:
        case ZMUpdateEventCallFlowActive:
        case ZMUpdateEventCallFlowAdd:
        case ZMUpdateEventCallFlowDelete:
        case ZMUpdateEventCallParticipants:
        case ZMUpdateEventCallRemoteSDP:
        case ZMUpdateEventConversationMemberUpdate:
        case ZMUpdateEventConversationTyping:
        case ZMUpdateEventUnknown:
        case ZMUpdateEventUserNew:
        case ZMUpdateEventUserUpdate:
        case ZMUpdateEvent_LAST:
            return nil;
            
        default:
            return nil;
    }
}


- (ZMLocalNotificationForEvent *)localNotificationForEvent:(ZMUpdateEvent *)event
{
    __block ZMLocalNotificationForEvent *newNote;
    __block NSUInteger convIndex;
    __block BOOL foundIdenticalNotification = NO;
    
    [self.eventsNotifications enumerateObjectsUsingBlock:^(ZMLocalNotificationForEvent *note, NSUInteger idx, BOOL *stop) {
        if ([note containsIdenticalEvent:event]) {
            foundIdenticalNotification = YES;
            *stop = YES;
            return;
        }
        newNote = [note copyByAddingEvent:event];
        if (newNote != nil) {
            convIndex = idx;
            *stop = YES;
        }
    }];
    
    if (foundIdenticalNotification) {
        return nil;
    }
 
    NSMutableArray *notifications = [NSMutableArray arrayWithArray:self.eventsNotifications];
    if (newNote == nil) {
        newNote = [ZMLocalNotificationForEvent notificationForEvent:event managedObjectContext:self.syncMOC application:self.sharedApplication];
        if(newNote == nil) {
            return nil;
        }
        [notifications addObject:newNote];
    }
    else {
        notifications[convIndex] = newNote;
    }
    self.eventsNotifications = [NSArray arrayWithArray:notifications];

    return newNote;
}

@end
