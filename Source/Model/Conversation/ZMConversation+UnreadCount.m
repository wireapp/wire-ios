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


@import WireUtilities;
@import WireTransport;

#import "ZMConversation+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMClientMessage.h"
#import "NSManagedObjectContext+zmessaging.h"

#import <WireDataModel/WireDataModel-Swift.h>

NSString *const ZMConversationInternalEstimatedUnreadCountKey = @"internalEstimatedUnreadCount";
NSString *const ZMConversationLastUnreadKnockDateKey = @"lastUnreadKnockDate";
NSString *const ZMConversationLastUnreadMissedCallDateKey = @"lastUnreadMissedCallDate";
NSString *const ZMConversationLastReadLocalTimestampKey = @"lastReadLocalTimestamp";



@implementation ZMConversation (Internal_UnreadCount)

@dynamic lastUnreadKnockDate;
@dynamic lastUnreadMissedCallDate;

- (void)setLastUnreadKnockDate:(NSDate *)lastUnreadKnockDate
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "lastUnreadKnockDate should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationLastUnreadKnockDateKey];
    [self setPrimitiveValue:lastUnreadKnockDate forKey:ZMConversationLastUnreadKnockDateKey];
    [self didChangeValueForKey:ZMConversationLastUnreadKnockDateKey];
}

- (void)setLastUnreadMissedCallDate:(NSDate *)lastUnreadMissedCallDate
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "lastUnreadMissedCallDate should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationLastUnreadMissedCallDateKey];
    [self setPrimitiveValue:lastUnreadMissedCallDate forKey:ZMConversationLastUnreadMissedCallDateKey];
    [self didChangeValueForKey:ZMConversationLastUnreadMissedCallDateKey];
}

- (BOOL)hasUnreadKnock
{
    return (self.lastUnreadKnockDate != nil);
}

+ (NSSet *)keyPathsForValuesAffectingHasUnreadKnock
{
    return [NSSet setWithObjects:ZMConversationLastUnreadKnockDateKey,  nil];
}

- (BOOL)hasUnreadMissedCall
{
    return (self.lastUnreadMissedCallDate != nil);
}

+ (NSSet *)keyPathsForValuesAffectingHasUnreadMissedCall
{
    return [NSSet setWithObjects:ZMConversationLastUnreadMissedCallDateKey,  nil];
}

@end



@implementation ZMConversation (UnreadCount)

@dynamic internalEstimatedUnreadCount;
@dynamic hasUnreadUnsentMessage;

+ (NSUInteger)unreadConversationCountInContext:(NSManagedObjectContext *)moc;
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMConversation entityName]];
    request.predicate = [self predicateForConversationConsideredUnread];
    
    NSSet *conversations = [[moc registeredObjects] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self.class == %@", ZMConversation.class]];
    ZMConversation *conv = [conversations anyObject];
    NOT_USED(conv);
    return [moc countForFetchRequest:request error:nil];
}

+ (NSPredicate *)predicateForConversationConsideredUnread;
{
    NSPredicate *notSilencedPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMConversationIsSilencedKey, @NO];
    NSPredicate *notSelfConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeSelf];
    NSPredicate *notInvalidConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeInvalid];
    NSPredicate *pendingConnection = [NSPredicate predicateWithFormat:@"%K != nil AND %K.status == %d", ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConnectionStatusPending];
    NSPredicate *unreadMessages = [NSPredicate predicateWithFormat:@"%K > 0", ZMConversationInternalEstimatedUnreadCountKey];
    NSPredicate *acceptablePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[pendingConnection, unreadMessages]];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSilencedPredicate, notSelfConversation, notInvalidConversation, acceptablePredicate]];
}

- (void)setInternalEstimatedUnreadCount:(int64_t)internalEstimatedUnreadCount
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "internalEstimatedUnreadCount should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationInternalEstimatedUnreadCountKey];
    [self setPrimitiveValue:@(internalEstimatedUnreadCount) forKey:ZMConversationInternalEstimatedUnreadCountKey];
    [self didChangeValueForKey:ZMConversationInternalEstimatedUnreadCountKey];
}

- (ZMConversationListIndicator)unreadListIndicator;
{
    if (self.hasUnreadUnsentMessage) {
        return ZMConversationListIndicatorExpiredMessage;
    } else if (self.hasUnreadMissedCall) {
        return ZMConversationListIndicatorMissedCall;
    } else if (self.hasUnreadKnock) {
        return ZMConversationListIndicatorKnock;
    } else if (self.estimatedUnreadCount != 0) {
        return ZMConversationListIndicatorUnreadMessages;
    }
    return ZMConversationListIndicatorNone;
}

+ (NSSet *)keyPathsForValuesAffectingUnreadListIndicator
{
    return [NSSet setWithObjects:ZMConversationLastUnreadMissedCallDateKey, ZMConversationLastUnreadKnockDateKey, ZMConversationInternalEstimatedUnreadCountKey, ZMConversationLastReadServerTimeStampKey, ZMConversationHasUnreadUnsentMessageKey,  nil];
}


// MARK - Initial fetch when calling awake from fetch

- (NSFetchRequest *)fetchRequestForUnreadMessages
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        return nil;
    }
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMMessage entityName]];
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K != %@ AND %K > %@",
                         ZMMessageConversationKey, self,
                         ZMMessageSenderKey, selfUser,
                         ZMMessageServerTimestampKey, self.lastReadServerTimeStamp];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:YES]];
    return request;
}

- (BOOL)didUpdateConversationWhileFetchingUnreadMessages
{
    if (nil == self.managedObjectContext) {
        return NO;
    }
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"timestamps should only be managed from the Sync Context");
        return NO;
    }
    if (self.conversationType == ZMConversationTypeSelf) {
        return NO;
    }
    
    NSArray *messages;
    if (self.lastReadServerTimeStamp != nil) {
        NSFetchRequest *request = [self fetchRequestForUnreadMessages];
        messages  = [self.managedObjectContext executeFetchRequestOrAssert:request];
    }
    else {
        messages = self.messages.array;
    }
    
    NSMutableArray *timeStamps = [NSMutableArray array];
    __block NSDate *lastKnockDate = nil;
    __block NSDate *lastMissedCallDate = nil;
    [messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ZMMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        NOT_USED(idx);
        NOT_USED(stop);
        if ([message shouldGenerateUnreadCount]) {
            [timeStamps insertObject:message.serverTimestamp atIndex:0];
            if (lastKnockDate == nil){
                BOOL isKnockMessage =  ([message isKindOfClass:[ZMKnockMessage class]]) ||
                                        ([message isKindOfClass:[ZMClientMessage class]] && [(ZMClientMessage *)message genericMessage].hasKnock);
                if (isKnockMessage) {
                    lastKnockDate = message.serverTimestamp;
                }
            }
            if (lastMissedCallDate == nil) {
                BOOL isMissedCallMessage =  ([message isKindOfClass:[ZMSystemMessage class]]) &&
                                            ([(ZMSystemMessage *)message systemMessageType] == ZMSystemMessageTypeMissedCall);
                if (isMissedCallMessage) {
                    lastMissedCallDate = message.serverTimestamp;
                }
            }
        }
    }];
    self.unreadTimeStamps = [NSMutableOrderedSet orderedSetWithArray:timeStamps];

    // The first time we check we overwrite whatever is stored - therefore we set authoratitive to YES
    BOOL didUpdateKnock = [self updateLastUnreadKnock:lastKnockDate authoritative:YES];
    BOOL didUpdateCall = [self updateLastUnreadMissedCall:lastMissedCallDate authoritative:YES];
    BOOL didUpdateUnread = [self updateUnreadCount];
    
    return (didUpdateCall || didUpdateKnock || didUpdateUnread);
}



- (BOOL)updateUnreadCount
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"internalEstimatedUnreadCount should only be changed from the Sync Context");
        return NO;
    }
    
    int64_t newCount = (long long)self.unreadTimeStamps.count;
    if (newCount != self.internalEstimatedUnreadCount) {
        self.internalEstimatedUnreadCount = newCount;
        return YES;
    }
    return NO;
}

- (BOOL)updateLastUnreadKnock:(NSDate *)newDate authoritative:(BOOL)authoritative
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"lastUnreadKnockDate should only be changed from the Sync Context");
        return NO;
    }
    
    if (self.lastUnreadKnockDate == nil && newDate == nil) {
        return NO;
    }
    NSComparisonResult result = [newDate compare:self.lastUnreadKnockDate];
    if (self.lastUnreadKnockDate == nil || newDate == nil ||
        (authoritative && result != NSOrderedSame) || result == NSOrderedDescending)
    {
        self.lastUnreadKnockDate = newDate;
        return YES;
    }
    return NO;
}

- (BOOL)updateLastUnreadMissedCall:(NSDate *)newDate authoritative:(BOOL)authoritative
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        return NO;
    }
    
    if (self.lastUnreadMissedCallDate == nil && newDate == nil) {
        return NO;
    }
    NSComparisonResult result = [newDate compare:self.lastUnreadMissedCallDate];
    if (self.lastUnreadMissedCallDate == nil || newDate == nil ||
        (authoritative && result != NSOrderedSame) || result == NSOrderedDescending)
    {
        self.lastUnreadMissedCallDate = newDate;
        return YES;
    }
    return NO;
}


// MARK - Inserting a message

- (void)insertTimeStamp:(NSDate *)serverTimeStamp
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"unreadTimeStamps should only be changed from the Sync Context");
        return;
    }
    
    if (serverTimeStamp == nil) {
        return;
    }
    
    BOOL isOlderThanOrSameAsLastRead = (self.lastReadServerTimeStamp != nil &&
                                        ([self.lastReadServerTimeStamp compare:serverTimeStamp] != NSOrderedAscending));
    if (isOlderThanOrSameAsLastRead) {
        return;
    }
    
    if (self.unreadTimeStamps == nil){
        self.unreadTimeStamps = [NSMutableOrderedSet orderedSet];
    }
    if (self.unreadTimeStamps.count == 0 ||
        [(NSDate *)self.unreadTimeStamps.lastObject compare:serverTimeStamp] == NSOrderedAscending)
    {
        [self.unreadTimeStamps addObject:serverTimeStamp];
    }
    else {
        NSUInteger index = [self.unreadTimeStamps indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(NSDate *stamp, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            BOOL isOlderThanTimeStampToInsert = ([stamp compare:serverTimeStamp] == NSOrderedAscending);
            *stop = isOlderThanTimeStampToInsert;
            return isOlderThanTimeStampToInsert;
        }];
        if (index != NSNotFound && (index+1 < self.unreadTimeStamps.count)) {
            [self.unreadTimeStamps insertObject:serverTimeStamp atIndex:index+1];
        }
    }
    
    [self updateUnreadCount];
}




// MARK - Setting lastReadServerTimeStamp

- (void)updateUnread
{
    if (nil == self.managedObjectContext) {
        return;
    }
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"unreadTimeStamps should only be changed from the Sync Context");
        return;
    }
    if (self.lastReadServerTimeStamp == nil && self.internalEstimatedUnreadCount == 0) {
        return;
    }
    if (self.unreadTimeStamps == nil) {
        [self didUpdateConversationWhileFetchingUnreadMessages];
    }
    else {
        [self didUpdateTimestamps];
        [self resetHasUnreadKnockIfNeeded];
        [self resetHasUnreadMissedCallIfNeeded];
    }
}

- (BOOL)didUpdateTimestamps
{
    if (self.unreadTimeStamps.count == 0 ||
        [(NSDate *)self.unreadTimeStamps.firstObject compare:self.lastReadServerTimeStamp] == NSOrderedDescending)
    {
        return NO;
    }
    
    if ([(NSDate *)self.unreadTimeStamps.lastObject compare:self.lastReadServerTimeStamp] != NSOrderedDescending) {
        [self.unreadTimeStamps removeAllObjects];
    }
    else {
        NSUInteger index = [self.unreadTimeStamps.array indexOfObjectPassingTest:^BOOL(NSDate *timeStamp, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            BOOL isNewerThanLastRead = ([timeStamp compare:self.lastReadServerTimeStamp] == NSOrderedDescending);
            *stop = isNewerThanLastRead;
            return isNewerThanLastRead;
        }];
        if (index != NSNotFound) {
            [self.unreadTimeStamps removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, index)]];
        }
    }
    return [self updateUnreadCount];
}



- (BOOL)resetHasUnreadKnockIfNeeded
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"lastUnreadKnockDate should only be changed from the Sync Context");
        return NO;
    }
    if (self.lastUnreadKnockDate == nil || self.lastReadServerTimeStamp == nil) {
        return NO;
    }
    
    if ([self.lastUnreadKnockDate compare:self.lastReadServerTimeStamp] != NSOrderedDescending) {
        self.lastUnreadKnockDate = nil;
        return YES;
    }
    return NO;
}



- (BOOL)resetHasUnreadMissedCallIfNeeded
{
    if(!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"lastUnreadMissedCallDate should only be reset from the Sync Context");
        return NO;
    }
    
    if (self.lastUnreadMissedCallDate == nil || self.lastReadServerTimeStamp == nil) {
        return NO;
    }
    
    if ([self.lastUnreadMissedCallDate compare:self.lastReadServerTimeStamp] != NSOrderedDescending) {
        self.lastUnreadMissedCallDate = nil;
        return YES;
    }
    return NO;
}


// MARK - Receiving messages that insert an unread call or knock

- (void)updateUnreadMessagesWithMessage:(ZMMessage *)message
{
    if (!self.managedObjectContext.zm_isSyncContext) {
        ZMLogWarn(@"unread message properties should only be changed from the Sync Context");
        return;
    }
    VerifyReturn(message != nil);
    if (![message.visibleInConversation isEqual:self]) {
        return;
    }
    if (message.sender.isSelfUser || ![message shouldGenerateUnreadCount]) {
        return;
    }
    [self didUpdateUnreadKnockForKnock:message];
    [self didUpdateUnreadMissedCallWithMessage:message];
}

- (BOOL)didUpdateUnreadKnockForKnock:(ZMMessage *)message;
{
    if ([message isKindOfClass:[ZMKnockMessage class]]) {
        ZMKnockMessage *knockMessage = (id)message;
        if (knockMessage.serverTimestamp == nil ||
            [knockMessage.serverTimestamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending)
        {
            return NO;
        }
    } else if ([message isKindOfClass:[ZMClientMessage class]]) {
        ZMClientMessage *clientMessage = (id)message;
        if (!clientMessage.genericMessage.hasKnock ||
            clientMessage.serverTimestamp == nil ||
            [clientMessage.serverTimestamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending)
        {
            return NO;
        }
    } else {
        return NO;
    }
    return [self updateLastUnreadKnock:message.serverTimestamp authoritative:NO];
}

- (BOOL)didUpdateUnreadMissedCallWithMessage:(ZMMessage *)message
{
    if (![message isKindOfClass:[ZMSystemMessage class]]) {
        return NO;
    }
    
    if ([(ZMSystemMessage *)message systemMessageType] != ZMSystemMessageTypeMissedCall) {
        return NO;
    }
    return [self updateLastUnreadMissedCall:message.serverTimestamp authoritative:NO];
}


@end

