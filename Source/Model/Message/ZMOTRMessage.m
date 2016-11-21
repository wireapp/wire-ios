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


#import "ZMOTRMessage.h"
#import "ZMGenericMessage+UpdateEvent.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>
#import "ZMGenericMessageData.h"


@import ZMTransport;


NSString * const DeliveredKey = @"delivered";


@implementation ZMOTRMessage

@dynamic delivered;
@dynamic dataSet;
@dynamic missingRecipients;

- (NSString *)entityName;
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (NSSet *)ignoredKeys;
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[DeliveredKey, ZMMessageIsExpiredKey]];
}

- (void)missesRecipient:(UserClient *)recipient
{
    [self missesRecipients:[NSSet setWithObject:recipient]];
}

- (void)missesRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] addObjectsFromArray:recipients.allObjects];
}

- (void)doesNotMissRecipient:(UserClient *)recipient
{
    [self doesNotMissRecipients:[NSSet setWithObject:recipient]];
}

- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] minusSet:recipients];
}

- (ZMDeliveryState)deliveryState
{
    if (self.isEncrypted) {
        //we set server time stamp in awake from insert to be able to sort messages
        //probably we need to store "deliveryTimestamp" separately and check it here
        if (self.isExpired) {
            return ZMDeliveryStateFailedToSend;
        }
        if (self.delivered == NO) {
            return ZMDeliveryStatePending;
        }
        if (self.confirmations.count == 0){
            return ZMDeliveryStateSent;
        }
        return ZMDeliveryStateDelivered;
    }
    else {
        return [super deliveryState];
    }
}

- (NSString *)dataSetDebugInformation
{
    return [[self.dataSet mapWithBlock:^NSString *(ZMGenericMessageData *msg) {
        return [NSString stringWithFormat:@"<%@>: %@", NSStringFromClass(ZMGenericMessageData.class), msg.genericMessage];
    }].array componentsJoinedByString:@"\n"];
}

- (void)markAsSent
{
    self.delivered = YES;
    [super markAsSent];
}

- (void)expire
{
    [super expire];
}

- (void)resend
{
    self.delivered = NO;
    [super resend];
}

- (void)updateWithGenericMessage:(__unused ZMGenericMessage *)message updateEvent:(__unused ZMUpdateEvent *)updateEvent
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

+ (ZMMessage *)preExistingPlainMessageForGenericMessage:(ZMGenericMessage *)message
                                         inConversation:(ZMConversation *)conversation
                                 inManagedObjectContext:(NSManagedObjectContext *)moc
                                         prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    Class messageClass = [ZMGenericMessage entityClassForPlainMessageForGenericMessage:message];
    return [messageClass fetchMessageWithNonce:[NSUUID uuidWithTransportString:message.messageId]
                               forConversation:conversation
                        inManagedObjectContext:moc
                                prefetchResult:prefetchResult];
}


+ (MessageUpdateResult *)messageUpdateResultFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                                     inManagedObjectContext:(NSManagedObjectContext *)moc
                                             prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage genericMessageFromUpdateEvent:updateEvent];
    }
    @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@", e);
        return nil;
    }
    VerifyReturnNil(message != nil);
    
    BOOL encrypted = [updateEvent isEncrypted];
    
    ZMConversation *conversation = [self.class conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    if (message.hasLastRead && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMLastReadFromSelfConversation:message.lastRead inContext:moc];
    }
    if (message.hasCleared && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMClearedFromSelfConversation:message.cleared inContext:moc];
    }
    if (message.hasHidden && conversation.conversationType == ZMConversationTypeSelf) {
        ZMUser *user = [ZMUser fetchObjectWithRemoteIdentifier:updateEvent.senderUUID inManagedObjectContext:moc];
        [ZMMessage removeMessageWithRemotelyHiddenMessage:message.hidden fromUser:user inManagedObjectContext:moc];
        return nil;
    }
    if (message.hasDeleted) {
        [ZMMessage removeMessageWithRemotelyDeletedMessage:message.deleted inConversation:conversation senderID:updateEvent.senderUUID inManagedObjectContext:moc];
        return nil;
    }
    if (message.hasReaction) {
        
        // if we don't understand the reaction received, discard it
        if (message.reaction.emoji.length > 0 && [Reaction transportReactionFrom:message.reaction.emoji] == TransportReactionNone) {
            return nil;
        }
        
        [ZMMessage addReaction:message.reaction senderID:updateEvent.senderUUID conversation:conversation inManagedObjectContext:moc];
        return nil;
    }
    if (message.hasConfirmation) {
        ZMUser *sender = [ZMUser userWithRemoteID:updateEvent.senderUUID createIfNeeded:YES inContext:moc];
        [ZMMessageConfirmation createOrUpdateMessageConfirmation:message conversation:conversation sender:sender];
        return nil;
    }
    ZMMessage *clearedMessage;
    if (message.hasEdited) {
        clearedMessage = [ZMMessage clearedMessageForRemotelyEditedMessage:message inConversation:conversation senderID:updateEvent.senderUUID inManagedObjectContext:moc];
        if (clearedMessage == nil) {
            return nil;
        }
    }
    
    if (![conversation shouldAddEvent:updateEvent] || message.hasClientAction) {
        return nil;
    }
    
    ZMMessage *preExistingPlainMessage = [ZMOTRMessage preExistingPlainMessageForGenericMessage:message
                                                                                 inConversation:conversation
                                                                         inManagedObjectContext:moc
                                                                                 prefetchResult:prefetchResult];
    if (preExistingPlainMessage != nil) {
        preExistingPlainMessage.isEncrypted = encrypted;
        return nil;
    }
    
    NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
    
    Class messageClass = [ZMGenericMessage entityClassForGenericMessage:message];
    ZMOTRMessage *clientMessage = [messageClass fetchMessageWithNonce:nonce
                                                      forConversation:conversation
                                               inManagedObjectContext:moc
                                                       prefetchResult:prefetchResult];
    
    if (clientMessage.isZombieObject) {
        return nil;
    }
    
    BOOL isNewMessage = NO;
    if (clientMessage == nil) {
        clientMessage = [messageClass insertNewObjectInManagedObjectContext:moc];
        isNewMessage = YES;
    } else if (![clientMessage.senderClientID isEqualToString:updateEvent.senderClientID]) {
        return nil;
    }
    
    clientMessage.isEncrypted = encrypted;
    clientMessage.isPlainText = !encrypted;
    clientMessage.nonce = nonce;
    clientMessage.senderClientID = updateEvent.senderClientID;
    
    // In case of AssetMessages: If the payload does not match the sha265 digest, calling `updateWithGenericMessage:updateEvent` will delete the object.
    [clientMessage updateWithGenericMessage:message updateEvent:updateEvent];
    // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true. In addition the object will still have a managedObjectContext until the context is finally saved. In this case, we need to check the nonce (which would have previously been set) to avoid setting an invalid relationship between the deleted object and the conversation and / or sender
    if (clientMessage.isZombieObject || clientMessage.nonce == nil) {
        return nil;
    }
    
    if (clearedMessage == nil) {
        [clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation isUpdatingExistingMessage:clientMessage.delivered];
    } else if ([clientMessage isKindOfClass:[ZMClientMessage class]]) {
        [clientMessage updateWithTimestamp:clearedMessage.serverTimestamp senderUUID:clearedMessage.sender.remoteIdentifier forConversation:conversation isUpdatingExistingMessage:NO];
        [(ZMClientMessage *)clientMessage setUpdatedTimestamp:updateEvent.timeStamp];
    }
    
    [clientMessage unarchiveConversationIfNeeded:conversation];
    
    BOOL needsConfirmation = NO;
    if (isNewMessage && !clientMessage.sender.isSelfUser && conversation.conversationType == ZMConversationTypeOneOnOne) {
        needsConfirmation = YES;
    }
    
    MessageUpdateResult *result = [[MessageUpdateResult alloc] initWithMessage:clientMessage needsConfirmation:needsConfirmation wasInserted:isNewMessage];
    return result;
}


- (void)unarchiveConversationIfNeeded:(ZMConversation *)conversation
{
    if (!conversation.isArchived || conversation.isSilenced) {
        return;
    }
    
    BOOL olderThanClearTimestamp = (conversation.clearedTimeStamp != nil) &&
                                   ([self.serverTimestamp compare:conversation.clearedTimeStamp] == NSOrderedAscending);
    
    if (!olderThanClearTimestamp) {
        conversation.internalIsArchived = NO;
        [conversation updateArchivedChangedTimeStampIfNeeded:self.serverTimestamp andSync:NO];
    }
}

@end
