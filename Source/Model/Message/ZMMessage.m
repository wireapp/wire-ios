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


@import ZMUtilities;
@import ZMProtos;
@import MobileCoreServices;
@import ImageIO;


#import "ZMMessage+Internal.h"
#import "ZMConversation.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Timestamps.h"
#import "ZMConversation+Transport.h"

#import "ZMConversation+UnreadCount.h"
#import "ZMUpdateEvent+ZMCDataModel.h"
#import "ZMClientMessage.h"

#import <ZMCDataModel/ZMCDataModel-Swift.h>


static NSTimeInterval ZMDefaultMessageExpirationTime = 60;

NSString * const ZMMessageEventIDDataKey = @"eventID_data";
NSString * const ZMMessageIsEncryptedKey = @"isEncrypted";
NSString * const ZMMessageIsPlainTextKey = @"isPlainText";
NSString * const ZMMessageIsExpiredKey = @"isExpired";
NSString * const ZMMessageMissingRecipientsKey = @"missingRecipients";
NSString * const ZMMessageServerTimestampKey = @"serverTimestamp";
NSString * const ZMMessageImageTypeKey = @"imageType";
NSString * const ZMMessageIsAnimatedGifKey = @"isAnimatedGIF";
NSString * const ZMMessageMediumRemoteIdentifierDataKey = @"mediumRemoteIdentifier_data";
NSString * const ZMMessageMediumRemoteIdentifierKey = @"mediumRemoteIdentifier";
NSString * const ZMMessageOriginalDataProcessedKey = @"originalDataProcessed";
NSString * const ZMMessageMediumDataLoadedKey = @"mediumDataLoaded";
NSString * const ZMMessageOriginalSizeDataKey = @"originalSize_data";
NSString * const ZMMessageOriginalSizeKey = @"originalSize";
NSString * const ZMMessageConversationKey = @"visibleInConversation";
NSString * const ZMMessageEventIDKey = @"eventID";
NSString * const ZMMessageExpirationDateKey = @"expirationDate";
NSString * const ZMMessageNameKey = @"name";
NSString * const ZMMessageNeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
NSString * const ZMMessageNonceDataKey = @"nonce_data";
NSString * const ZMMessageSenderKey = @"sender";
NSString * const ZMMessageSystemMessageTypeKey = @"systemMessageType";
NSString * const ZMMessageSystemMessageClientsKey = @"clients";
NSString * const ZMMessageTextKey = @"text";
NSString * const ZMMessageUserIDsKey = @"users_ids";
NSString * const ZMMessageUsersKey = @"users";
NSString * const ZMMessageClientsKey = @"clients";
NSString * const ZMMessageAddedUsersKey = @"addedUsers";
NSString * const ZMMessageRemovedUsersKey = @"removedUsers";
NSString * const ZMMessageNeedsUpdatingUsersKey = @"needsUpdatingUsers";
NSString * const ZMMessageHiddenInConversationKey = @"hiddenInConversation";
NSString * const ZMMessageSenderClientIDKey = @"senderClientID";

@interface ZMMessage ()

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)context prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;

// wasAlreadyReceived parameter means that update event updates already existing message (i.e. for image messages)
// it will affect updating serverTimestamp and messages sorting
- (void)updateWithUpdateEvent:(ZMUpdateEvent *)event forConversation:(ZMConversation *)conversation messageWasAlreadyReceived:(BOOL)wasAlreadyReceived;

- (void)updateTimestamp:(NSDate *)timestamp messageWasAlreadyReceived:(BOOL)wasAlreadyReceived;

@property (nonatomic) NSSet *missingRecipients;

@end;



@interface ZMMessage (CoreDataForward)

@property (nonatomic) BOOL isExpired;
@property (nonatomic) NSDate *expirationDate;

@end


@interface ZMImageMessage (CoreDataForward)

@property (nonatomic) NSData *primitiveMediumData;

@end



@implementation ZMMessage

@dynamic missingRecipients;
@dynamic isExpired;
@dynamic expirationDate;
@dynamic senderClientID;

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
{
    return [self createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:nil];
}

+ (BOOL)isDataAnimatedGIF:(NSData *)data
{
    if(data.length == 0) {
        return NO;
    }
    BOOL isAnimated = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    VerifyReturnValue(source != NULL, NO);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    if(UTTypeConformsTo((__bridge CFStringRef) type, kUTTypeGIF)) {
        isAnimated = CGImageSourceGetCount(source) > 1;
    }
    CFRelease(source);
    return isAnimated;
}

- (BOOL)isUnreadMessage
{
    return (self.conversation != nil) && (self.conversation.lastReadServerTimeStamp != nil) && (self.serverTimestamp != nil) && ([self.serverTimestamp compare:self.conversation.lastReadServerTimeStamp] == NSOrderedDescending);
}

- (BOOL)shouldGenerateUnreadCount
{
    return YES;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    return [NSPredicate predicateWithValue:NO];
}

+ (NSString *)remoteIdentifierKey;
{
    return ZMMessageNonceDataKey;
}

+ (NSString *)entityName;
{
    return @"Message";
}

+ (NSString *)sortKey;
{
    return ZMMessageNonceDataKey;
}

+ (void)setDefaultExpirationTime:(NSTimeInterval)defaultExpiration
{
    ZMDefaultMessageExpirationTime = defaultExpiration;
}

+ (NSTimeInterval)defaultExpirationTime
{
    return ZMDefaultMessageExpirationTime;
}

+ (void)resetDefaultExpirationTime
{
    ZMDefaultMessageExpirationTime = ZMTransportRequestDefaultExpirationInterval;
}

- (void)resend;
{
    self.isExpired = NO;
    [self setExpirationDate];
}

- (void)setExpirationDate
{
    self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:[self.class defaultExpirationTime]];
}

- (void)removeExpirationDate;
{
    self.expirationDate = nil;
}

- (void)markAsDelivered
{
    self.isExpired = NO;
}

- (void)expire;
{
    self.isExpired = YES;
    [self removeExpirationDate];
    self.conversation.hasUnreadUnsentMessage = YES;
}

- (void)updateTimestamp:(NSDate *)timestamp messageWasAlreadyReceived:(BOOL)wasAlreadyReceived
{
    if (wasAlreadyReceived) {
        self.serverTimestamp = [NSDate lastestOfDate:self.serverTimestamp and:timestamp];
    } else if (timestamp != nil) {
        self.serverTimestamp = timestamp;
    }
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [NSMutableSet setWithObjects:ZMMessageEventIDKey, ZMMessageEventIDDataKey, ZMMessageIsExpiredKey, nil];
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.nonce = [[NSUUID alloc] init];
    self.serverTimestamp = [self dateIgnoringNanoSeconds];
}

- (NSDate *)dateIgnoringNanoSeconds
{
    double currentMilliseconds = floor([[NSDate date] timeIntervalSince1970]*1000);
    return [NSDate dateWithTimeIntervalSince1970:(currentMilliseconds/1000)];
}


- (NSUUID *)nonce;
{
    return [self transientUUIDForKey:@"nonce"];
}

- (void)setNonce:(NSUUID *)nonce;
{
    [self setTransientUUID:nonce forKey:@"nonce"];
}

- (ZMEventID *)eventID;
{
    return [self transientEventIDForKey:ZMMessageEventIDKey];
}

- (void)setEventID:(ZMEventID *)eventID;
{
    [self setTransientEventID:eventID forKey:ZMMessageEventIDKey];
}

+ (NSSet *)keyPathsForValuesAffectingEventID;
{
    return [NSSet setWithObject:ZMMessageEventIDDataKey];
}

+ (NSArray *)defaultSortDescriptors;
{
    static NSArray *sd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSortDescriptor *serverTimestamp = [NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:YES];
        sd = @[serverTimestamp];
    });
    return sd;
}

- (NSComparisonResult)compare:(ZMMessage *)other;
{
    for (NSSortDescriptor *sd in [[self class] defaultSortDescriptors]) {
        NSComparisonResult r = [sd compareObject:self toObject:other];
        if (r != NSOrderedSame) {
            return r;
        }
    }
    return NSOrderedSame;
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent forConversation:(ZMConversation *)conversation messageWasAlreadyReceived:(BOOL)wasAlreadyReceived;
{
    ZMEventID *eventID = updateEvent.eventID;
    NSDate *serverTimestamp = updateEvent.timeStamp;
    NSUUID *senderUUID = updateEvent.senderUUID;
    
    self.eventID = [ZMEventID latestOfEventID:self.eventID and:eventID];
    [self updateTimestamp:serverTimestamp messageWasAlreadyReceived:wasAlreadyReceived];
    
    
    /**
     * Florian, the 07.06.16
     * In some cases, the conversation relationship assignement crashes for the reason that both object are coming from a different context.
     * I think this is a bug on Apple's side as the sender assignement also has caused a crash for the same reason (https://rink.hockeyapp.net/manage/apps/42908/app_versions/558/crash_reasons/123911635?order=asc&sort_by=date&type=crashes#crash_data)
     *  
     * There is no way that the user and self (the message) are in different context as we EXPLICITLY fetch(or create) it from the self.managedObjectContext
     *
     * And after a thourough digging in the code, the conversation ALSO can't come from a different context, as both prefetched batches and fetch creation is done on SyncMOC (same for message).
     
     * I try to fetch the conversation from the self context as an attempt workaround.
     *
     * This issue was only reported on iOS 9.3.2.
     */
    
    if (self.managedObjectContext != conversation.managedObjectContext) {
        conversation = [ZMConversation conversationWithRemoteID:conversation.remoteIdentifier createIfNeeded:NO inContext:self.managedObjectContext];
    }
    
    self.visibleInConversation = conversation;
    self.sender = [ZMUser userWithRemoteID:senderUUID createIfNeeded:YES inContext:self.managedObjectContext];
    
    if (self.sender.isSelfUser) {
        // if the message was sent by the selfUser we don't want to send a lastRead event, since we consider this message to be already read
        [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:self.serverTimestamp andSync:NO];
    }
    [conversation updateWithMessage:self timeStamp:serverTimestamp eventID:eventID];
}

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSUUID *conversationUUID = event.conversationUUID;
    
    VerifyReturnNil(conversationUUID != nil);
    
    if (nil != prefetchResult.conversationsByRemoteIdentifier[conversationUUID]) {
        return prefetchResult.conversationsByRemoteIdentifier[conversationUUID];
    }
    
    return [ZMConversation conversationWithRemoteID:conversationUUID createIfNeeded:YES inContext:moc];
}

- (void)removeMessage
{
    self.hiddenInConversation = self.conversation;
    self.visibleInConversation = nil;
}

+ (void)removeMessageWithRemotelyHiddenMessage:(ZMMessageHide *)hiddenMessage fromUser:(ZMUser *)user inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    if(user != selfUser) {
        return;
    }
    
    NSUUID *conversationID = [NSUUID uuidWithTransportString:hiddenMessage.conversationId];
    ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:moc];
    
    NSUUID *messageID = [NSUUID uuidWithTransportString:hiddenMessage.messageId];
    ZMMessage *message = [ZMMessage fetchMessageWithNonce:messageID forConversation:conversation inManagedObjectContext:moc];
    [message removeMessage];
}

+ (void)removeMessageWithRemotelyDeletedMessage:(ZMMessageDelete *)deletedMessage inConversation:(ZMConversation *)conversation senderID:(NSUUID *)senderID inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    NSUUID *messageID = [NSUUID uuidWithTransportString:deletedMessage.messageId];
    ZMMessage *message = [ZMMessage fetchMessageWithNonce:messageID forConversation:conversation inManagedObjectContext:moc];

    // Only the sender of the original message can delete it
    if (![senderID isEqual:message.sender.remoteIdentifier]) {
        return;
    }
    
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];

    // Only clients other than self should see the system message
    if (nil != message && ![senderID isEqual:selfUser.remoteIdentifier]) {
        [conversation appendDeletedForEveryoneSystemMessageWithTimestamp:message.serverTimestamp sender:message.sender];
    }
    
    [message removeMessage];
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    NSUUID *nonce;
    ZMUpdateEventType eventType = [ZMUpdateEvent updateEventTypeForEventTypeString:[payload optionalStringForKey:@"type"]];
    if (eventType == ZMUpdateEventConversationMessageAdd ||
        eventType == ZMUpdateEventConversationKnock) {
        nonce = [[payload dictionaryForKey:@"data"] uuidForKey:@"nonce"];
    }
    else if (eventType == ZMUpdateEventConversationClientMessageAdd ||
             eventType == ZMUpdateEventConversationOtrMessageAdd) {
        
        //if event is otr message than payload should be already decrypted and should contain generic message data

        NSString *base64Content = [payload stringForKey:@"data"];
        ZMGenericMessage *message;
        @try {
            message = [ZMGenericMessage messageWithBase64String:base64Content];
        }
        @catch(NSException *e) {
            ZMLogError(@"Cannot create message from protobuffer: %@ event payload: %@", e, payload);
            return;
        }
        nonce = [NSUUID uuidWithTransportString:message.messageId];
    }
    else if (eventType == ZMUpdateEventUnknown) {
        return;
    }
    
    if (nonce != nil && ![self.nonce isEqual:nonce]) {
        ZMLogWarn(@"send message response nonce does not match");
        return;
    }
    
    BOOL updatedTimestamp = NO;
    NSDate *timestamp = [payload dateForKey:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else if( ! [timestamp isEqualToDate:self.serverTimestamp]) {
        self.serverTimestamp = timestamp;
        updatedTimestamp = YES;
    }
    [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:timestamp andSync:YES];
    [self.conversation updateLastServerTimeStampIfNeeded:timestamp];
    [self.conversation updateLastModifiedDateIfNeeded:timestamp];
 
    
    ZMEventID *eventID = [payload eventForKey:@"id"];
    [self.conversation addEventToDownloadedEvents:eventID timeStamp:timestamp];
    if ((self.eventID == nil) ||
        ([eventID compare:self.eventID] == NSOrderedAscending))
    {
        self.eventID = eventID;
    }
    
    if (eventID != nil) {
        [self.conversation updateLastReadEventIDIfNeededWithEventID:eventID];
        [self.conversation updateLastEventIDIfNeededWithEventID:eventID];
    }
    
    if (updatedTimestamp) {
        [self.conversation resortMessagesWithUpdatedMessage:self];
    }
}

- (NSString *)shortDebugDescription;
{
    // This will make "seconds since" easier to read:
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = YES;
    
    return [NSString stringWithFormat:@"<%@: %p> id: %@, conversation: %@, event: %@, nonce: %@, sender: %@, server timestamp: %@",
            self.class, self,
            self.objectID.URIRepresentation.lastPathComponent,
            self.conversation.objectID.URIRepresentation.lastPathComponent,
            self.eventID.transportString,
            [self.nonce.UUIDString.lowercaseString substringToIndex:4],
            self.sender.objectID.URIRepresentation.lastPathComponent,
            [formatter stringFromNumber:@(self.serverTimestamp.timeIntervalSinceNow)]
            ];
}

+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce forConversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc
{
    return [self fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:moc prefetchResult:nil];
}


+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce forConversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSSet <ZMMessage *>* prefetchedMessages = prefetchResult.messagesByNonce[nonce];
    
    if (nil != prefetchedMessages) {
        for (ZMMessage *prefetchedMessage in prefetchedMessages) {
            if ([prefetchedMessage isKindOfClass:[self class]]) {
                return prefetchedMessage;
            }
        }
    }
    
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageNonceDataKey, [nonce data]];
    
    BOOL checkedAllHiddenMessages = NO;
    BOOL checkedAllVisibleMessage = NO;

    if (![conversation hasFaultForRelationshipNamed:ZMConversationMessagesKey]) {
        checkedAllVisibleMessage = YES;
        for (ZMMessage *message in conversation.messages) {
            if (message.isFault) {
                checkedAllVisibleMessage = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }
    
    if (![conversation hasFaultForRelationshipNamed:ZMConversationHiddenMessagesKey]) {
        checkedAllHiddenMessages = YES;
        for (ZMMessage *message in conversation.hiddenMessages) {
            if (message.isFault) {
                checkedAllHiddenMessages = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }

    if (checkedAllVisibleMessage && checkedAllHiddenMessages) {
        return nil;
    }

    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[noncePredicate, conversationPredicate]];
    NSFetchRequest *fetchRequest = [self.class sortedFetchRequestWithPredicate:predicate];
    fetchRequest.fetchLimit = 2;
    fetchRequest.includesSubentities = YES;
    
    NSArray* fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    VerifyString([fetchResult count] <= 1, "More than one message with the same nonce in the same conversation");
    return fetchResult.firstObject;
}


+ (NSPredicate *)predicateForMessagesThatWillExpire;
{
    return [NSPredicate predicateWithFormat:@"%K == 0 && %K != NIL",
            ZMMessageIsExpiredKey,
            ZMMessageExpirationDateKey];
}


+ (BOOL)doesEventTypeGenerateMessage:(ZMUpdateEventType)type;
{
    return
        (type == ZMUpdateEventConversationAssetAdd) ||
        (type == ZMUpdateEventConversationMessageAdd) ||
        (type == ZMUpdateEventConversationClientMessageAdd) ||
        (type == ZMUpdateEventConversationOtrMessageAdd) ||
        (type == ZMUpdateEventConversationOtrAssetAdd) ||
        (type == ZMUpdateEventConversationKnock) ||
        [ZMSystemMessage doesEventTypeGenerateSystemMessage:type];
}


+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *__unused)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *__unused)moc
                                      prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass(self), NSStringFromSelector(_cmd));
    return nil;
}

+ (void)addEventToDownloadedEvents:(ZMUpdateEvent *)event inConversation:(ZMConversation *)conversation
{
    ZMEventID *eventID = event.eventID;
    NSDate *timeStamp = event.timeStamp;

    if (eventID != nil) {
        [conversation addEventToDownloadedEvents:eventID timeStamp:timeStamp];
        conversation.lastEventID = conversation.lastEventID != nil ? [ZMEventID latestOfEventID:eventID and:conversation.lastEventID] : eventID;
    }
}

+ (NSPredicate *)predicateForMessageInConversation:(ZMConversation *)conversation withNonces:(NSSet<NSUUID *> *)nonces;
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    NSSet *noncesData = [nonces mapWithBlock:^NSData*(NSUUID *uuid) {
        return uuid.data;
    }];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K IN %@", noncesData];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, noncePredicate]];
}

@end



@implementation ZMMessage (PersistentChangeTracking)

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    return [NSPredicate predicateWithFormat:@"%K == NULL && %K == 0",
            ZMMessageEventIDDataKey,
            ZMMessageIsExpiredKey];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSArray *newKeys = @[
                             ZMMessageConversationKey,
                             ZMMessageExpirationDateKey,
                             ZMMessageImageTypeKey,
                             ZMMessageIsAnimatedGifKey,
                             ZMMessageMediumRemoteIdentifierDataKey,
                             ZMMessageNameKey,
                             ZMMessageNonceDataKey,
                             ZMMessageOriginalDataProcessedKey,
                             ZMMessageOriginalSizeDataKey,
                             ZMMessageSenderKey,
                             ZMMessageServerTimestampKey,
                             ZMMessageSystemMessageTypeKey,
                             ZMMessageTextKey,
                             ZMMessageUserIDsKey,
                             ZMMessageEventIDDataKey,
                             ZMMessageUsersKey,
                             ZMMessageClientsKey,
                             ZMMessageIsEncryptedKey,
                             ZMMessageIsPlainTextKey,
                             ZMMessageHiddenInConversationKey,
                             ZMMessageMissingRecipientsKey,
                             ZMMessageMediumDataLoadedKey,
                             ZMMessageAddedUsersKey,
                             ZMMessageRemovedUsersKey,
                             ZMMessageNeedsUpdatingUsersKey,
                             ZMMessageSenderClientIDKey
                             ];
        ignoredKeys = [keys setByAddingObjectsFromArray:newKeys];
    });
    return ignoredKeys;
}

@end



#pragma mark - Text message

@implementation ZMTextMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"TextMessage";
}

- (NSString *)shortDebugDescription;
{
    return [[super shortDebugDescription] stringByAppendingFormat:@", \'%@\'", self.text];
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
    NSString *text = [eventData stringForKey:@"content"];
    NSUUID *nonce = [eventData uuidForKey:@"nonce"];
    
    VerifyReturnNil(nonce != nil);
    
    ZMConversation *conversation = [self conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    ZMClientMessage *preExistingClientMessage = [ZMClientMessage fetchMessageWithNonce:nonce
                                                                       forConversation:conversation
                                                                inManagedObjectContext:moc
                                                                        prefetchResult:prefetchResult];
    if(preExistingClientMessage != nil) {
        preExistingClientMessage.isPlainText = YES;
        return nil;
    }
    if (![conversation shouldAddEvent:updateEvent]) {
        [ZMMessage addEventToDownloadedEvents:updateEvent inConversation:conversation];
        return nil;
    }
    
    ZMTextMessage *message = [ZMTextMessage fetchMessageWithNonce:nonce
                                                  forConversation:conversation
                                           inManagedObjectContext:moc
                                               prefetchResult:prefetchResult];
    if(message == nil) {
        message = [ZMTextMessage insertNewObjectInManagedObjectContext:moc];
    }
    
    message.isPlainText = YES;
    message.isEncrypted = NO;
    message.nonce = nonce;
    [message updateWithUpdateEvent:updateEvent forConversation:conversation messageWasAlreadyReceived:(message.eventID != nil)];
    message.text = text;
    
    return message;
}

- (NSString *)messageText
{
    return self.text;
}

- (LinkPreview *)linkPreview
{
    return nil;
}

- (id<ZMTextMessageData>)textMessageData
{
    return self;
}

- (NSData *)imageData
{
    return nil;
}

- (BOOL)hasImageData
{
    return NO;
}

- (NSString *)imageDataIdentifier
{
    return nil;
}

@end





# pragma mark - Knock message

@implementation ZMKnockMessage

+ (NSString *)entityName;
{
    return @"KnockMessage";
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    if (updateEvent.type != ZMUpdateEventConversationKnock) {
        return nil;
    }
    
    NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
    NSUUID *nonce = [eventData uuidForKey:@"nonce"];
    VerifyReturnNil(nonce != nil);
    
    ZMConversation *conversation = [self conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    if (![conversation shouldAddEvent:updateEvent]) {
        [ZMMessage addEventToDownloadedEvents:updateEvent inConversation:conversation];
        return nil;
    }
    
    ZMClientMessage *preExistingClientMessage = [ZMClientMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:moc];
    if(preExistingClientMessage != nil) {
        preExistingClientMessage.isPlainText = YES;
        return nil;
    }
    
    ZMKnockMessage *message = [ZMKnockMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:moc];
    if(message == nil) {
        message = [ZMKnockMessage insertNewObjectInManagedObjectContext:moc];
    }
    
    message.nonce = nonce;
    [message updateWithUpdateEvent:updateEvent forConversation:conversation messageWasAlreadyReceived:(message.eventID != nil)];
    message.isEncrypted = NO;
    message.isPlainText = YES;
    return message;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    return self;
}

@end



# pragma mark - System message

@implementation ZMSystemMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"SystemMessage";
}

@dynamic systemMessageType;
@dynamic users;
@dynamic clients;
@dynamic addedUsers;
@dynamic removedUsers;
@dynamic needsUpdatingUsers;

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMSystemMessageType type = [self.class systemMessageTypeFromEventType:updateEvent.type];
    if(type == ZMSystemMessageTypeInvalid) {
        return nil;
    }
    
    ZMConversation *conversation = [self conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    if ((conversation.conversationType != ZMConversationTypeGroup) &&
        ((updateEvent.type == ZMUpdateEventConversationMemberJoin) ||
         (updateEvent.type == ZMUpdateEventConversationMemberLeave) ||
         (updateEvent.type == ZMUpdateEventConversationMemberUpdate) ||
         (updateEvent.type == ZMUpdateEventConversationMessageAdd) ||
         (updateEvent.type == ZMUpdateEventConversationClientMessageAdd) ||
         (updateEvent.type == ZMUpdateEventConversationOtrMessageAdd) ||
         (updateEvent.type == ZMUpdateEventConversationOtrAssetAdd)
         ))
    {
        return nil;
    }
    
    if (![conversation shouldAddEvent:updateEvent]){
        [ZMMessage addEventToDownloadedEvents:updateEvent inConversation:conversation];
        return nil;
    }
    
    if (type == ZMSystemMessageTypeMissedCall)
    {
        NSString *reason = [[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"reason"];
        if (![reason isEqualToString:@"missed"]) {
            return nil;
        }
    }
    
    NSMutableSet *usersSet = [NSMutableSet set];
    for(NSString *userId in [[updateEvent.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"])
    {
        ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:userId] createIfNeeded:YES inContext:moc];
        [usersSet addObject:user];
    }

    ZMEventID *eventID = updateEvent.eventID;
    VerifyReturnNil(eventID != nil);
    
    ZMSystemMessage *message = [ZMSystemMessage fetchMessageWithID:eventID forConversation:conversation];
    if(message == nil) {
        message = [ZMSystemMessage insertNewObjectInManagedObjectContext:moc];
    }
    message.systemMessageType = type;
    message.visibleInConversation = conversation;
    
    [message updateWithUpdateEvent:updateEvent forConversation:conversation messageWasAlreadyReceived:(message.eventID != nil)];
    
    if (![usersSet isEqual:[NSSet setWithObject:message.sender]]) {
        [usersSet removeObject:message.sender];
    }
    message.users = usersSet;

    NSString *messageText = [[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"message"];
    NSString *name = [[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"name"];
    if (messageText != nil) {
        message.text = messageText;
    }
    else if (name != nil) {
        message.text = name;
    }

    message.isEncrypted = NO;
    message.isPlainText = YES;
    return message;
}

- (ZMDeliveryState)deliveryState
{
    // SystemMessages are either from the BE or inserted on device
    return ZMDeliveryStateDelivered;
}

+ (ZMSystemMessage *)fetchMessageWithID:(ZMEventID *)eventID forConversation:(ZMConversation *)conversation
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation, ZMMessageHiddenInConversationKey, conversation];
    NSPredicate *eventIDPredicate = [NSPredicate predicateWithFormat:@"eventID_data == %@", eventID.encodeToData];
    NSCompoundPredicate *compound = [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, eventIDPredicate]];
    
    NSArray *result = [conversation.managedObjectContext executeFetchRequestOrAssert:[ZMSystemMessage sortedFetchRequestWithPredicate:compound]];
    if(result.count) {
        return result[0];
    }
    return nil;
}

+ (ZMSystemMessage *)fetchStartedUsingOnThisDeviceMessageForConversation:(ZMConversation *)conversation
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation, ZMMessageHiddenInConversationKey, conversation];
    NSPredicate *eventIDPredicate = [NSPredicate predicateWithFormat:@"%K == %d", ZMMessageSystemMessageTypeKey, ZMSystemMessageTypeNewClient];
    NSPredicate *containsSelfClient = [NSPredicate predicateWithFormat:@"ANY %K == %@", ZMMessageSystemMessageClientsKey, [ZMUser selfUserInContext:conversation.managedObjectContext].selfClient];
    NSCompoundPredicate *compound = [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, eventIDPredicate, containsSelfClient]];
    
    NSArray *result = [conversation.managedObjectContext executeFetchRequestOrAssert:[ZMSystemMessage sortedFetchRequestWithPredicate:compound]];
    if(result.count) {
        return result[0];
    }
    return nil;
}

+ (ZMSystemMessage *)fetchLatestPotentialGapSystemMessageInConversation:(ZMConversation *)conversation
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:NO]];
    request.fetchBatchSize = 1;
    request.predicate = [self predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:conversation];
    NSArray *result = [conversation.managedObjectContext executeFetchRequestOrAssert:request];
    return result.firstObject;
}

+ (NSPredicate *)predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:(ZMConversation *)conversation
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageConversationKey, conversation];
    NSPredicate *missingMessagesTypePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageSystemMessageTypeKey, @(ZMSystemMessageTypePotentialGap)];
    NSPredicate *needsUpdatingUsersPredicate = [NSPredicate predicateWithFormat:@"%K == YES", ZMMessageNeedsUpdatingUsersKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, missingMessagesTypePredicate, needsUpdatingUsersPredicate]];
}

+ (NSPredicate *)predicateForSystemMessagesInsertedLocally
{
    return [NSPredicate predicateWithFormat:@"class == %@ AND %K == NULL", [ZMSystemMessage class], ZMMessageEventIDDataKey];
}

- (void)updateNeedsUpdatingUsersIfNeeded
{
    if (self.systemMessageType == ZMSystemMessageTypePotentialGap && self.needsUpdatingUsers == YES) {
        BOOL (^matchUnfetchedUserBlock)(ZMUser *) = ^BOOL(ZMUser *user) {
            return user.name == nil;
        };
        
        self.needsUpdatingUsers = [self.addedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock] ||
                                  [self.removedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock];
    }
}

+ (ZMSystemMessageType)systemMessageTypeFromEventType:(ZMUpdateEventType)type
{
    NSNumber *number = self.eventTypeToSystemMessageTypeMap[@(type)];
    if(number == nil) {
        return ZMSystemMessageTypeInvalid;
    }
    else {
        return (ZMSystemMessageType) number.integerValue;
    }
}

+ (BOOL)doesEventTypeGenerateSystemMessage:(ZMUpdateEventType)type;
{
    return [self.eventTypeToSystemMessageTypeMap.allKeys containsObject:@(type)];
}

+ (NSDictionary *)eventTypeToSystemMessageTypeMap   
{
    return @{
             @(ZMUpdateEventConversationMemberJoin) : @(ZMSystemMessageTypeParticipantsAdded),
             @(ZMUpdateEventConversationMemberLeave) : @(ZMSystemMessageTypeParticipantsRemoved),
             @(ZMUpdateEventConversationRename) : @(ZMSystemMessageTypeConversationNameChanged),
             @(ZMUpdateEventConversationConnectRequest) : @(ZMSystemMessageTypeConnectionRequest),
             @(ZMUpdateEventConversationVoiceChannelDeactivate) : @(ZMSystemMessageTypeMissedCall)
             };
}

- (id<ZMSystemMessageData>)systemMessageData
{
    return self;
}

- (BOOL)shouldGenerateUnreadCount;
{
    return self.systemMessageType == ZMSystemMessageTypeMissedCall;
}


@end

