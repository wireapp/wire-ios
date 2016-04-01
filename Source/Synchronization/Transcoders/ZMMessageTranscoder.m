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


@import ZMUtilities;
@import ZMTransport;
@import Cryptobox;
@import ZMUtilities;

#import "ZMMessageTranscoder+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUpdateEvent.h"
#import "ZMUser+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMMessageExpirationTimer.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMAssetPreprocessingTracker.h"

#import "ZMLocalNotificationDispatcher.h"

#import <zmessaging/zmessaging-Swift.h>
#import "CBCryptoBox+UpdateEvents.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ZMOperationLoop.h"

static char* const ZMLogTag ZM_UNUSED = "MessageTranscoder";

typedef NS_ENUM(int8_t, ZMAssetTag) {
    ZMAssetTagInvalid,
    ZMAssetTagPreview,
    ZMAssetTagMedium,
};


#pragma mark - Message transcoder
@interface ZMMessageTranscoder ()

@property (nonatomic) ZMUpstreamInsertedObjectSync *upstreamObjectSync;
@property (nonatomic) NSMutableSet *pendingObjectIDRequest;
@property (nonatomic) ZMMessageExpirationTimer *messageExpirationTimer;
@property (nonatomic) ZMLocalNotificationDispatcher *localNotificationDispatcher;

@end



@implementation ZMMessageTranscoder


+ (instancetype)textMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
{
    return [[ZMTextMessageTranscoder alloc] initWithManagedObjectContext:moc upstreamInsertedObjectSync:nil localNotificationDispatcher:dispatcher messageExpirationTimer:nil];
}

+ (instancetype)systemMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
{
    return [[ZMSystemMessageTranscoder alloc] initWithManagedObjectContext:moc upstreamInsertedObjectSync:nil localNotificationDispatcher:dispatcher messageExpirationTimer:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc entityName:(NSString *)entityName localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher;
{
    ZMUpstreamInsertedObjectSync *upstreamObjectSync = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self entityName:entityName managedObjectContext:moc];
    ZMMessageExpirationTimer *messageTimer = [[ZMMessageExpirationTimer alloc] initWithManagedObjectContext:moc entityName:entityName localNotificationDispatcher:dispatcher];
    return [self initWithManagedObjectContext:moc upstreamInsertedObjectSync:upstreamObjectSync localNotificationDispatcher:dispatcher messageExpirationTimer:messageTimer];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
{
    NOT_USED(moc);
    RequireString(NO, "Can't use default init");
    return nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamObjectSync localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer;
{
    self = [super initWithManagedObjectContext:moc];
    if (self) {
        self.localNotificationDispatcher = dispatcher;
        self.upstreamObjectSync = upstreamObjectSync;
        self.messageExpirationTimer = expirationTimer;
    }
    return self;
}

- (BOOL)hasPendingMessages
{
    return self.messageExpirationTimer.hasMessageTimersRunning || self.upstreamObjectSync.hasCurrentlyRunningRequests;
}

- (void)tearDown
{
    [super tearDown];
    [self.messageExpirationTimer tearDown];
}

- (BOOL)isSlowSyncDone
{
    return YES;
}

- (void)setNeedsSlowSync
{
    // nop
}

- (NSArray *)contextChangeTrackers
{
    return @[self.upstreamObjectSync, self.messageExpirationTimer];
}

- (NSArray *)requestGenerators;
{
    return @[self.upstreamObjectSync];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(BOOL)liveEvents
       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;
{
    NSArray *messages = [self createMessagesFromEvents:events prefetchResult:prefetchResult];
    
    if (liveEvents) {
        for (ZMMessage *message in messages) {
            [message.conversation resortMessagesWithUpdatedMessage:message];
        }
    }
}

- (NSArray<ZMMessage *> *)createMessagesFromEvents:(__unused NSArray<ZMUpdateEvent *>*)events
                                    prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    // This is supposed to be subclassed
    return @[];
}

@end



@import ZMProtos;

@implementation ZMMessageTranscoder (ZMUpstreamTranscoder)

- (BOOL)shouldProcessUpdatesBeforeInserts;
{
    return NO;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMMessage * __unused)message forKeys:(NSSet * __unused)keys;
{
    ZMTrapUnableToGenerateRequest(keys, self);
    return nil;
}

- (ZMUpstreamRequest *)requestForInsertingObject:(ZMMessage *)message forKeys:(NSSet *)keys;
{
    if (message.isExpired) {
        ZMLogDebug(@"<%@: %p> is expired.", message.class, message);
        return nil;
    }
    ZMLogDebug(@"<%@: %p> will expire in %g s.", message.class, message, message.expirationDate.timeIntervalSinceNow);
    
    VerifyReturnNil(message.conversation.remoteIdentifier != nil);
    
    ZMTransportRequest *request = [self requestForInsertingObject:message];
    [self.messageExpirationTimer stopTimerForMessage:message];
    [request expireAtDate:message.expirationDate];
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:request];
}

- (ZMTransportRequest *)requestForInsertingObject:(ZMMessage *__unused)message
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (ZMManagedObject *)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMMessage *)message;
{
    // Don't post messages until the conversation has been created:
    if (message.conversation.remoteIdentifier == nil) {
        return message.conversation;
    }

    // Messages should time out within 1 minute. But image messages never time out. In case there is a bug
    // and one image message gets stuck in a non-sent state (but not expired), that message will block any future
    // message in that conversation forver. This happened with some buggy builds (ie.g. internal 2838).
    // In order to recover from this situation for people that used a buggy client, we can set a cap
    // to the amount of time that a "non-delivered" message will block future messages.
    // This will also prevent looking too far back in time for ALL messages in a conversation. Only messages
    // that are more recent than X minutes will be considered. The expected "pending messages" should expire
    // within a minute anyway. The server timestamp of the pending messages (since they are not delivered)
    // is set using the local timestamp so we can safely check with the current messge timestamp (not delivered,
    // so also a local timestamp). Of course the user could change the local clock in between sending messages
    // but this is quite an edge case.
    const NSTimeInterval MaxDelayToConsiderForBlockingObject = 3 * 60; // 3 minutes
    
    __block ZMMessage *blockingMessage;
    [message.conversation.messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ZMMessage *previousMessage, __unused NSUInteger idx, BOOL *stop) {
        BOOL objectIsTooOldToBlock = [message.serverTimestamp timeIntervalSinceDate:previousMessage.serverTimestamp] > MaxDelayToConsiderForBlockingObject;
        if(objectIsTooOldToBlock) {
            *stop = YES;
            return;
        }
        BOOL sameMessage = previousMessage == message || [previousMessage.nonce isEqual:message.nonce];
        BOOL previousNotDelivered = previousMessage.deliveryState == ZMDeliveryStatePending;
        BOOL previousIsEarlier = [previousMessage.serverTimestamp compare:message.serverTimestamp] == NSOrderedAscending;
        
        if ( !sameMessage && previousNotDelivered && previousIsEarlier) {
            blockingMessage = previousMessage;
            *stop = YES;
        }
    }];
    return blockingMessage;
}

- (void)updateMessage:(ZMMessage *)message fromResponse:(ZMTransportResponse *)response updatedKeys:(NSSet *)updatedKeys;
{
    [self.messageExpirationTimer stopTimerForMessage:message];
    [message removeExpirationDate];
    [message markAsDelivered];
    [message updateWithPostPayload:response.payload.asDictionary updatedKeys:updatedKeys];
}

- (void)updateInsertedObject:(ZMMessage *)message request:(__unused ZMUpstreamRequest *)upstreamRequest response:(ZMTransportResponse *)response;
{
    [self updateMessage:message fromResponse:response updatedKeys:[NSSet set]];
}

- (BOOL)updateUpdatedObject:(ZMTextMessage *)message
            requestUserInfo:(NSDictionary *__unused)requestUserInfo
                   response:(ZMTransportResponse *)response
                keysToParse:(NSSet *)keysToParse
{
    [self updateMessage:message fromResponse:response updatedKeys:keysToParse];
    return NO;
}

- (ZMManagedObject *)objectToRefetchForFailedUpdateOfObject:(ZMTextMessage *)message;
{
    return message.conversation;
}

- (void)requestExpiredForObject:(ZMTextMessage *)message forKeys:(NSSet *)keys
{
    NOT_USED(keys);
    [message expire];
    [self.localNotificationDispatcher didFailToSentMessage:message];
}


@end


#pragma mark - Text message transcoder
@implementation ZMTextMessageTranscoder

- (ZMTransportRequest *)requestForInsertingObject:(ZMTextMessage __unused *)message
{
    return nil;
}

- (NSArray<ZMMessage *> *)createMessagesFromEvents:(NSArray<ZMUpdateEvent *>*)events
                                    prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSMutableArray *createdMessages = [NSMutableArray array];
    for(ZMUpdateEvent *event in events) {
        if (event.type == ZMUpdateEventConversationMessageAdd) {
            ZMMessage *msg = [self processTextMessageAddEvent:event prefetchResult:prefetchResult];
            if(msg != nil) {
                [createdMessages addObject:msg];
            }
        }
    }
    return createdMessages;
}

- (ZMTextMessage *)processTextMessageAddEvent:(ZMUpdateEvent *)event
                               prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;
{
    return [ZMTextMessage createOrUpdateMessageFromUpdateEvent:event
                                        inManagedObjectContext:self.managedObjectContext
                                                prefetchResult:prefetchResult];
}

- (NSArray<id<ZMContextChangeTracker>> *)contextChangeTrackers {
    return @[];
}

- (NSArray<id<ZMRequestGenerator>> *)requestGenerators {
    return @[];
}

- (NSSet<NSUUID *> *)messageNoncesToPrefetchToProcessEvents:(NSArray<ZMUpdateEvent *> *)events
{
    return [events mapWithBlock:^NSUUID *(ZMUpdateEvent *event) {
        switch (event.type) {
            case ZMUpdateEventConversationMessageAdd:
                return event.messageNonce;
                
            default:
                return nil;
        }
    }].set;
}

@end




#pragma mark - System message transcoder
@implementation ZMSystemMessageTranscoder

- (NSArray<ZMMessage *> *)createMessagesFromEvents:(NSArray<ZMUpdateEvent *> *)events
                                    prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    NSMutableArray *createdMessages = [NSMutableArray array];
    for(ZMUpdateEvent *event in events) {
        ZMMessage *msg = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:event
                                                        inManagedObjectContext:self.managedObjectContext
                                                                prefetchResult:nil // system messages don't have nonces anyway
                          ];
        if(msg != nil) {
            [createdMessages addObject:msg];
        }
    }
    return createdMessages;
}

- (ZMUpstreamRequest *)requestForInsertingObject:(ZMManagedObject *__unused)managedObject forKeys:(NSSet *__unused)keys
{
    return nil;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMManagedObject *__unused)managedObject forKeys:(NSSet *__unused)keys
{
    return nil;
}
            
- (NSArray<id<ZMContextChangeTracker>> *)contextChangeTrackers
{
    return @[];
}
            
- (NSArray<id<ZMRequestGenerator>> *)requestGenerators
{
    return @[];
}

@end


