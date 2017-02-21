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

@import ZMCDataModel;
@import WireRequestStrategy;

#import "ZMClientMessageTranscoder+Internal.h"
#import "ZMMessageTranscoder+Internal.h"
#import "ZMMessageExpirationTimer.h"

#import <WireMessageStrategy/WireMessageStrategy-Swift.h>

@interface ZMClientMessageTranscoder()

@property (nonatomic) ClientMessageRequestFactory *requestsFactory;
@property (nonatomic, weak) id <ClientRegistrationDelegate> clientRegistrationStatus;
@property (nonatomic, weak) id<DeliveryConfirmationDelegate> apnsConfirmationStatus;

@end


@implementation ZMClientMessageTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                 localNotificationDispatcher:(id<ZMPushMessageHandler>)dispatcher
                    clientRegistrationStatus:(id<ClientRegistrationDelegate>)clientRegistrationStatus
                      apnsConfirmationStatus:(id<DeliveryConfirmationDelegate>)apnsConfirmationStatus;
{
    ZMUpstreamInsertedObjectSync *clientTextMessageUpstreamSync = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self entityName:[ZMClientMessage entityName] filter:nil managedObjectContext:moc];
    ZMMessageExpirationTimer *messageTimer = [[ZMMessageExpirationTimer alloc] initWithManagedObjectContext:moc entityName:[ZMClientMessage entityName] localNotificationDispatcher:dispatcher filter:nil];
    
    self = [super initWithManagedObjectContext:moc
                    upstreamInsertedObjectSync:clientTextMessageUpstreamSync
                   localNotificationDispatcher:dispatcher
                        messageExpirationTimer:messageTimer];
    if (self) {
        self.requestsFactory = [ClientMessageRequestFactory new];
        self.clientRegistrationStatus = clientRegistrationStatus;
        self.apnsConfirmationStatus = apnsConfirmationStatus;
        [self deleteEphemeralMessagesIfNeeded];
    }
    return self;
}

- (void)deleteEphemeralMessagesIfNeeded
{
    [ZMMessage deleteOldEphemeralMessages:self.managedObjectContext];
    [self.managedObjectContext saveOrRollback];
}

- (ZMTransportRequest *)requestForInsertingObject:(ZMClientMessage *)message
{
    ZMTransportRequest *request = [self.requestsFactory upstreamRequestForMessage:message forConversationWithId:message.conversation.remoteIdentifier];
    if ([message isKindOfClass:ZMClientMessage.class] && message.genericMessage.hasConfirmation && self.apnsConfirmationStatus.needsToSyncMessages) {
        [request forceToVoipSession]; // we might receive a message while in the background
    }
    return request;
}

- (void)updateInsertedObject:(ZMOTRMessage *)message request:(ZMUpstreamRequest *)upstreamRequest response:(ZMTransportResponse *)response;
{
    [super updateInsertedObject:message request:upstreamRequest response:response];
    [message parseMissingClientsResponse:response clientDeletionDelegate:self.clientRegistrationStatus];

    // if it's reaction
    if ([message isKindOfClass:[ZMClientMessage class]] && !message.isZombieObject) {
        
        ZMClientMessage *clientMessage = (id)message;
        if (clientMessage.genericMessage.hasReaction) {
            [message.managedObjectContext deleteObject:clientMessage];
        }
        if (clientMessage.genericMessage.hasConfirmation) {
            [self.apnsConfirmationStatus didConfirmMessage:clientMessage.nonce];
            [message.managedObjectContext deleteObject:clientMessage]; // we don't need the message anymore
        }
    }
}

- (BOOL)updateUpdatedObject:(ZMAssetClientMessage *)message requestUserInfo:(NSDictionary *)requestUserInfo response:(ZMTransportResponse *)response keysToParse:(NSSet *)keysToParse
{
    BOOL result = [super updateUpdatedObject:message requestUserInfo:requestUserInfo response:response keysToParse:keysToParse];
    [message parseMissingClientsResponse:response clientDeletionDelegate:self.clientRegistrationStatus];
    
    return result;
}

- (BOOL)shouldRetryToSyncAfterFailedToUpdateObject:(ZMClientMessage *)message request:(ZMUpstreamRequest *__unused)upstreamRequest response:(ZMTransportResponse *)response keysToParse:(NSSet * __unused)keys
{
    return [message parseMissingClientsResponse:response clientDeletionDelegate:self.clientRegistrationStatus];
}

- (BOOL)shouldCreateRequestToSyncObject:(ZMManagedObject *)managedObject forKeys:(NSSet<NSString *> *)keys withSync:(id)sync;
{
    if ([managedObject isKindOfClass:[ZMClientMessage class]]) {
        ZMClientMessage *message = (ZMClientMessage *)managedObject;
        if (message.genericMessage.hasConfirmation) {
            NSUUID *messageNonce = [NSUUID uuidWithTransportString:message.genericMessage.confirmation.messageId];
            ZMClientMessage *sentMessage = (ZMClientMessage *)[ZMMessage fetchMessageWithNonce:messageNonce forConversation:message.conversation inManagedObjectContext:message.managedObjectContext];
            return (sentMessage.sender != nil) || (message.conversation.connectedUser != nil) || (message.conversation.otherActiveParticipants.count > 0);
        }
    }
    return YES;
}

- (ZMManagedObject *)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMClientMessage *)message;
{
    return message.dependentObjectNeedingUpdateBeforeProcessing;
}

- (ZMMessage *)messageFromUpdateEvent:(ZMUpdateEvent *)event
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    MessageUpdateResult *updateResult;
    switch (event.type) {
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        {
            updateResult = [ZMOTRMessage messageUpdateResultFromUpdateEvent:event
                                                     inManagedObjectContext:self.managedObjectContext
                                                             prefetchResult:prefetchResult];
            
            id<DeliveryConfirmationDelegate> strongStatus = self.apnsConfirmationStatus;
            if ([strongStatus.class sendDeliveryReceipts]) {
                if (updateResult.needsConfirmation) {
                    ZMClientMessage *confirmation = [updateResult.message confirmReception];
                    if (event.source == ZMUpdateEventSourcePushNotification) {
                        [strongStatus needsToConfirmMessage:confirmation.nonce];
                    }
                }
            }
            if (event.source == ZMUpdateEventSourcePushNotification && updateResult.message != nil)
            {
                ZMGenericMessage *genericMessage = [ZMGenericMessage genericMessageFromUpdateEvent:event];
                if (genericMessage != nil) {
                    [self.localNotificationDispatcher processGenericMessage:genericMessage];
                }
                [self.localNotificationDispatcher processMessage:(ZMOTRMessage *)updateResult.message];
            }
            break;
        }
        default:
            return nil;
    }
    
    [updateResult.message markAsSent];
    return updateResult.message;
}


@end
