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
@import ZMUtilities;
@import ZMCDataModel;

#import "ZMMessageExpirationTimer.h"
#import "ZMPushMessageHandler.h"

@interface ZMMessageExpirationTimer ()

@property (nonatomic) id<ZMPushMessageHandler> localNotificationsDispatcher;
@property (nonatomic) NSString *entityName;
@property (nonatomic) NSPredicate *filter;

@end



@implementation ZMMessageExpirationTimer

ZM_EMPTY_ASSERTING_INIT()

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                                  entityName:(NSString *)entityName
                 localNotificationDispatcher:(id<ZMPushMessageHandler>)notificationDispatcher;
{
    return [self initWithManagedObjectContext:moc entityName:entityName localNotificationDispatcher:notificationDispatcher filter:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                                  entityName:(NSString *)entityName
                 localNotificationDispatcher:(id<ZMPushMessageHandler>)notificationDispatcher
                                      filter:(NSPredicate *)filter
{
    self = [super initWithManagedObjectContext:moc];
    if (self) {
        ZM_WEAK(self);
        self.timerCompletionBlock = ^(ZMMessage *message, NSDictionary * __unused userInfo) {
            ZM_STRONG(self);
            [self timerFiredForMessage:message];
        };
        self.localNotificationsDispatcher = notificationDispatcher;
        self.entityName = entityName;
        self.filter = filter;
    }
    return self;
}


- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    NSPredicate *predicate = [ZMMessage predicateForMessagesThatWillExpire];
    return [ZMMessage sortedFetchRequestWithPredicate:predicate];
}

- (void)addTrackedObjects:(NSSet *)objects;
{
    [self startTimerForObjects:objects];
}

- (void)objectsDidChange:(NSSet *)objects
{
    [self startTimerForObjects:objects];
}

- (void)startTimerForStoredMessages
{
    NSPredicate *predicate = [ZMMessage predicateForMessagesThatWillExpire];
    NSFetchRequest *request = [ZMMessage sortedFetchRequestWithPredicate:predicate];
    NSArray *expiringMessages = [self.moc executeFetchRequestOrAssert:request];
    [self startTimerForObjects:[NSSet setWithArray:expiringMessages]];
}


- (void)startTimerForObjects:(NSSet *)managedObjects
{
    NSDate *now = [NSDate date];
    for (ZMManagedObject *object in managedObjects) {
        if (![[[object class] entityName] isEqual: self.entityName]) {
            continue;
        }
        
        BOOL passedFilter = (self.filter == nil ||
                             (self.filter != nil && [self.filter evaluateWithObject:object]));
        if (!passedFilter) {
            continue;
        }
        
        if (! [[[object class] entityName] isEqualToString:self.entityName]) {
            continue;
        }
        
        ZMMessage *message = (ZMMessage *)object;
        
        if (message.expirationDate == nil) {
            continue;
        }
        
        if ([message.expirationDate compare:now] == NSOrderedAscending) {
            [message expire];
            [message.managedObjectContext enqueueDelayedSave];
        }
        else  {
            [super startTimerForMessageIfNeeded:message fireDate:message.expirationDate userInfo:@{}];
        }
    }
}

- (void)timerFiredForMessage:(ZMMessage *)message
{
    if (message.deliveryState == ZMDeliveryStateDelivered ||
        message.deliveryState == ZMDeliveryStateSent)
    {
        return;
    }
    
    [message expire];
    [message.managedObjectContext enqueueDelayedSave];
    [self.localNotificationsDispatcher didFailToSentMessage:message];
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
}

@end
