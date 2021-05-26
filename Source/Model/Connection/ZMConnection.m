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

#import "ZMConnection+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import <WireDataModel/WireDataModel-Swift.h>


NSString * const ZMConnectionStatusKey = @"status";

static NSString * const ToUserKey = @"to";
static NSString * const RemoteIdentifierDataKey = @"remoteIdentifier_data";
static NSString * const ExistsOnBackendKey = @"existsOnBackend";
static NSString * const LastUpdateDateInGMTKey = @"lastUpdateDateInGMT";

@interface ZMConnection (CoreDataForward)

@property (nonatomic) ZMConnectionStatus primitiveStatus;

@end



@implementation ZMConnection

+ (NSString *)entityName;
{
    return @"Connection";
}

+ (NSString *)sortKey;
{
    return LastUpdateDateInGMTKey;
}

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user existingConversation:(ZMConversation *)conversation
{
    VerifyReturnValue(user.connection == nil, user.connection);
    RequireString(user != nil, "Can not create a connection to <nil> user.");
    ZMConnection *connection = [self insertNewObjectInManagedObjectContext:user.managedObjectContext];
    connection.to = user;
    connection.lastUpdateDate = [NSDate date];
    connection.status = ZMConnectionStatusSent;
    if (conversation == nil) {
        connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:user.managedObjectContext];
       
        [connection addWithUser:user];
        
        connection.conversation.creator = [ZMUser selfUserInContext:user.managedObjectContext];
    }
    else {
        connection.conversation = conversation;
        ///TODO: add user if not exists in participantRoles??
    }
    connection.conversation.conversationType = ZMConversationTypeConnection;
    connection.conversation.lastModifiedDate = connection.lastUpdateDate;
    return connection;
}

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user;
{
    return [self insertNewSentConnectionToUser:user existingConversation:nil];
}

- (BOOL)hasValidConversation
{
    return (self.status != ZMConnectionStatusPending) && (self.conversation.conversationType != ZMConversationTypeInvalid);
}

- (NSDate *)lastUpdateDate;
{
    return self.lastUpdateDateInGMT;
}

- (void)setLastUpdateDate:(NSDate *)lastUpdateDate;
{
    self.lastUpdateDateInGMT = lastUpdateDate;
}

@dynamic message;
@dynamic status;
@dynamic to;

@end



@implementation ZMConnection (Internal)

@dynamic conversation;
@dynamic to;
@dynamic existsOnBackend;
@dynamic lastUpdateDateInGMT;

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    NSPredicate *hasToUser = [NSPredicate predicateWithFormat:@"%K != NULL", ToUserKey];
    NSPredicate *existsOnBackend = [NSPredicate predicateWithFormat:@"%K == 0", ExistsOnBackendKey];
    NSPredicate *notInvalid = [NSPredicate predicateWithFormat:@"%K != %@", ZMConnectionStatusKey, @(ZMConnectionStatusInvalid)];
    NSPredicate *toUserHasRemoteIdData = [NSPredicate predicateWithFormat:@"%K.%K != NULL", ToUserKey, RemoteIdentifierDataKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[hasToUser, existsOnBackend, notInvalid, toUserHasRemoteIdData]];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *hasToUser = [NSPredicate predicateWithFormat:@"%K != NULL", ToUserKey];
    NSPredicate *existsOnBackend = [NSPredicate predicateWithFormat:@"%K == 1", ExistsOnBackendKey];
    NSPredicate *blocked = [NSPredicate predicateWithFormat:@"%K == %@", ZMConnectionStatusKey, @(ZMConnectionStatusBlocked)];
    NSPredicate *ignored = [NSPredicate predicateWithFormat:@"%K == %@", ZMConnectionStatusKey, @(ZMConnectionStatusIgnored)];
    NSPredicate *accepted = [NSPredicate predicateWithFormat:@"%K == %@", ZMConnectionStatusKey, @(ZMConnectionStatusAccepted)];
    NSPredicate *cancelled = [NSPredicate predicateWithFormat:@"%K == %@", ZMConnectionStatusKey, @(ZMConnectionStatusCancelled)];
    NSPredicate *connections = [NSCompoundPredicate orPredicateWithSubpredicates:@[blocked, ignored, accepted, cancelled]];
    NSPredicate *toUserHasRemoteIdData = [NSPredicate predicateWithFormat:@"%K.%K != NULL", ToUserKey, RemoteIdentifierDataKey];
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeUpdatedUpstream];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[hasToUser, existsOnBackend, connections, toUserHasRemoteIdData, superPredicate]];
}

- (NSString *)statusAsString
{
    return [[self class] stringForStatus:self.status];
}

struct stringAndStatus {
    CFStringRef string;
    ZMConnectionStatus status;
} const statusStrings[] = {
    {CFSTR("accepted"), ZMConnectionStatusAccepted},
    {CFSTR("pending"), ZMConnectionStatusPending},
    {CFSTR("blocked"), ZMConnectionStatusBlocked},
    {CFSTR("ignored"), ZMConnectionStatusIgnored},
    {CFSTR("sent"), ZMConnectionStatusSent},
    {CFSTR("cancelled"), ZMConnectionStatusCancelled},
    {CFSTR("missing-legalhold-consent"), ZMConnectionStatusBlockedMissingLegalholdConsent},
    {NULL, ZMConnectionStatusInvalid},
};

- (void)setStatus:(ZMConnectionStatus)status;
{
    [self willChangeValueForKey:ZMConnectionStatusKey];
    NSNumber *oldStatus = [self primitiveValueForKey:ZMConnectionStatusKey];
    [self setPrimitiveValue:@(status) forKey:ZMConnectionStatusKey];
    [self didChangeValueForKey:ZMConnectionStatusKey];
    NSNumber *newStatus = [self primitiveValueForKey:ZMConnectionStatusKey];
    
    if (![oldStatus isEqual:@(ZMConnectionStatusAccepted)] &&
        [newStatus isEqual:@(ZMConnectionStatusAccepted)]) {
        self.to.needsToBeUpdatedFromBackend = YES;
    }
    
    if (![oldStatus isEqual:newStatus]) {
        [self invalidateTopConversationCache];
    }
}

+ (ZMConnectionStatus)statusFromString:(NSString *)string
{
    for (struct stringAndStatus const *s = statusStrings; s->string != NULL; ++s) {
        if ([string isEqualToString:(__bridge NSString *) s->string]) {
            return s->status;
        }
    }
    return ZMConnectionStatusInvalid;
}

+ (NSString *)stringForStatus:(ZMConnectionStatus)status;
{
    for (struct stringAndStatus const *s = statusStrings; s->string != NULL; ++s) {
        if (s->status == status) {
            return (__bridge NSString *) s->string;
        }
    }
    return nil;
}

- (void)updateFromTransportData:(NSDictionary *)transportData;
{
    const ZMConnectionStatus status = [ZMConnection statusFromString:[transportData stringForKey:@"status"]];
    if (status == ZMConnectionStatusInvalid) {
        ZMLogWarn(@"Invalid 'status' in connection: %@", transportData);
    } else {
        self.status = status;
    }
    
    NSUUID *toUUID = [transportData uuidForKey:@"to"];
    if (toUUID == nil) {
        ZMLogWarn(@"Invalid 'to'-UUID in connection: %@", transportData);
    } else if (! [toUUID isEqual:self.to.remoteIdentifier]) {
        ZMLogError(@"'to' UUID in connection doesn't match previous value.");
    }
    
    NSDate *lastUpdateDate = [transportData dateFor:@"last_update"];
    if(lastUpdateDate == nil) {
        ZMLogWarn(@"Invalid 'last_update' in connection: %@", transportData);
    } else {
        self.lastUpdateDateInGMT = lastUpdateDate;
    }
    
    NSUUID *conversationID = [transportData uuidForKey:@"conversation"];
    if(conversationID == nil) {
        ZMLogWarn(@"Invalid 'conversation'-UUID in connection: %@", transportData);
    } else {
        if (self.conversation != nil) {
            if (! [self.conversation.remoteIdentifier isEqual:conversationID]) {
                ZMLogError(@"Conversation UUID in connection doesn't match previous value.");
                ZMConversation *realConversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:self.managedObjectContext];
                self.conversation = realConversation;
                self.conversation.needsToBeUpdatedFromBackend = YES;
            }
            // The conversation will not have any modified date until the first message, use connection date in the meantime
            self.conversation.lastModifiedDate = lastUpdateDate;
        } else {
            self.conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:self.managedObjectContext];
            self.conversation.needsToBeUpdatedFromBackend = YES;
        }
    }
    
    NSString *message;
    if (transportData[@"message"] != [NSNull null]) {
        message = [transportData stringForKey:@"message"];
    }
    if (message != nil) {
        self.message = message;
    }
}

+ (instancetype)connectionWithUserUUID:(NSUUID *)UUID inContext:(NSManagedObjectContext *)moc
{
    VerifyReturnNil(UUID != nil);
    
    // We must only ever call this on the sync context. Otherwise, there's a race condition
    // where the UI and sync contexts could both insert the same conversation (same UUID) and we'd end up
    // having two duplicates of that connection, and we'd have a really hard time recovering from that.
    //
    RequireString(moc.zm_isSyncContext, "Race condition!");
    
    ZMConnection *result = [self fetchConnectionWithUserUUID:UUID managedObjectContext:moc];
    
    if (result != nil) {
        return result;
    } else {
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:moc];
        ZMUser *user = [ZMUser userWithRemoteID:UUID createIfNeeded:NO inContext:moc];
        
        if (user == nil) {
            user = [ZMUser userWithRemoteID:UUID createIfNeeded:YES inContext:moc];
            user.needsToBeUpdatedFromBackend = YES;
        }
        
        connection.to = user;
        connection.existsOnBackend = YES;
        return connection;
    }
    return nil;
}

+ (ZMConnection *)connectionFromTransportData:(NSDictionary *)transportData managedObjectContext:(NSManagedObjectContext *)moc
{
    NSUUID *conversationID = [transportData uuidForKey:@"conversation"];
    if(conversationID == nil) {
        ZMLogError(@"Invalid 'conversation'-UUID in connection: %@", transportData);
        return nil;
    }
    
    const ZMConnectionStatus status = [ZMConnection statusFromString:transportData[ZMConnectionStatusKey]];
    BOOL cancelled = status == ZMConnectionStatusCancelled;

    if (!cancelled) {
        // Make sure this conversation has its type set to 'connection' in stead of 'invalid' in case it was just created.
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:moc];
        if (conversation.conversationType == ZMConversationTypeInvalid) {
            conversation.conversationType = ZMConversationTypeConnection;
        }
    }
    
    if (status == ZMConnectionStatusInvalid) {
        // This happens for ZMUpdateEvents from the push channel. Those don't have a status.
        if (transportData[@"status"] != nil) {
            ZMLogError(@"Invalid 'status' in connection: %@", transportData);
        }
        return nil;
    }
    
    NSUUID *toUUID = [transportData uuidForKey:@"to"];
    if(toUUID == nil) {
        ZMLogError(@"Invalid 'to'-UUID in connection: %@", transportData);
        return nil;
    } else if ([toUUID isEqual:[ZMUser selfUserInContext:moc].remoteIdentifier]) {
        ZMLogError(@"Invalid 'to'-UUID in connection referencing self user: %@", transportData);
        return nil;
    }
    
    NSDate *lastUpdateDate = [transportData dateFor:@"last_update"];
    if(lastUpdateDate == nil) {
        ZMLogError(@"Invalid 'last_update' in connection: %@", transportData);
        return nil;
    }
    
    NSString *message;
    if(transportData[@"message"] != [NSNull null]) {
        message = [transportData stringForKey:@"message"];
    }
    
    ZMConnection *connection = [self.class fetchConnectionWithUserUUID:toUUID managedObjectContext:moc];
    
    if (connection == nil) {
        if (!cancelled) {
            connection = [ZMConnection insertNewObjectInManagedObjectContext:moc];
        }
        else {
            return nil;
        }
    }
    
    if (!cancelled) {
        connection.to = [ZMUser userWithRemoteID:toUUID createIfNeeded:YES inContext:moc];
        if (connection.to.isInserted || status == ZMConnectionStatusPending) {
            connection.to.needsToBeUpdatedFromBackend = YES;
        }
        
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:moc];
        [conversation addParticipantAndUpdateConversationStateWithUser:connection.to role:nil];
    }

    ZMConnectionStatus const oldStatus = connection.status;
    connection.status = status;
    connection.message = message;
    connection.lastUpdateDateInGMT = lastUpdateDate;
    connection.existsOnBackend = YES;
    
    [self createOrMergeConversationWithRemoteIdentifier:conversationID forConnection:connection inContext:moc];
    [self updateConnection:connection fromPreviousStatus:oldStatus];

    return connection;
}

+ (void)updateConnection:(ZMConnection *)connection fromPreviousStatus:(ZMConnectionStatus)oldStatus
{
    if (oldStatus == ZMConnectionStatusSent && (connection.status == ZMConnectionStatusAccepted)) {
        connection.conversation.conversationType = ZMConversationTypeOneOnOne;
        connection.needsToBeUpdatedFromBackend = YES; // Do we really need that?
        [connection.conversation updateLastModified:connection.lastUpdateDate];
        
        if (connection.conversation.isArchived) {
            // When a connection is accepted we always want to bring it out of the archive
            connection.conversation.isArchived = NO;
        }
    }
    
    //Handle race condition when at the same time we send request to the user and this user also send us connection request
    //so we recieve from backend the same connection object but with other status (ZMConnectionStatusPending)
    if ((oldStatus == ZMConnectionStatusSent) && (connection.status == ZMConnectionStatusPending)) {
        connection.status = ZMConnectionStatusAccepted;
        [connection setLocallyModifiedKeys:[NSSet setWithObject:ZMConnectionStatusKey]];
    }
    
    if (connection.status == ZMConnectionStatusSent) {
        [connection.conversation updateLastModified:connection.lastUpdateDate];
    }
    
    if (connection.status == ZMConnectionStatusCancelled) {
        connection.to.connection = nil;
        connection.to = nil;
        connection.conversation.conversationType = ZMConversationTypeInvalid;
    }
}

+ (void)createOrMergeConversationWithRemoteIdentifier:(NSUUID *)conversationID forConnection:(ZMConnection *)connection inContext:(NSManagedObjectContext *)moc
{
    if (connection.conversation == nil) {
        connection.conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:moc];
        connection.conversation.conversationType = [self conversationTypeForConnectionStatus:connection.status];
        if (connection.status == ZMConnectionStatusPending) {
            connection.conversation.creator = connection.to;
        }
    } else {
        if (connection.conversation.remoteIdentifier == nil) {
            [connection.conversation mergeWithExistingConversationWithRemoteID:conversationID];
        }
        else if (![connection.conversation.remoteIdentifier isEqual:conversationID]) {
            RequireString(NO, "BE error? -> One-on-one conversation with remoteIdentifier %s received different remoteIdentifier %s", connection.conversation.remoteIdentifier.transportString.UTF8String, conversationID.transportString.UTF8String);
        }
    }
    
    connection.conversation.needsToBeUpdatedFromBackend = YES;
}

+ (ZMConversationType)conversationTypeForConnectionStatus:(ZMConnectionStatus)status
{
    switch (status) {
        case ZMConnectionStatusPending:
        case ZMConnectionStatusIgnored:
        case ZMConnectionStatusSent:
            return ZMConversationTypeConnection;
            break;
            
        case ZMConnectionStatusAccepted:
        case ZMConnectionStatusBlocked:
            return ZMConversationTypeOneOnOne;
            break;
            
        default:
            return ZMConversationTypeInvalid;
    }
}

- (void)updateConversationType
{
    self.conversation.conversationType = [self.class conversationTypeForConnectionStatus:self.status];
}

+ (ZMConnection *)fetchConnectionWithUserUUID:(NSUUID *)uuid managedObjectContext:(NSManagedObjectContext *)moc
{
    // check if it exists already
    NSFetchRequest *fetchRequest = [self.class sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"to.remoteIdentifier_data == %@", [uuid data]]];
    NSArray* fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    RequireString([fetchResult count] <= 1, "More than one connection with the same 'to' field: %s", uuid.transportString.UTF8String);
    return [fetchResult firstObject];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *keys = [NSMutableArray array];
        [keys addObjectsFromArray:self.entity.attributesByName.allKeys];
        [keys addObjectsFromArray:self.entity.relationshipsByName.allKeys];
        [keys removeObject:ZMConnectionStatusKey];
        ignoredKeys = [NSSet setWithArray:keys];
    });
    return ignoredKeys;
}

+ (NSPredicate *)predicateForFilteringResults
{
    static NSPredicate *predicate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        predicate = [NSPredicate predicateWithFormat:@"%K != %d",
                     ZMConnectionStatusKey, ZMConnectionStatusCancelled];
    });
    return predicate;
}

@end



