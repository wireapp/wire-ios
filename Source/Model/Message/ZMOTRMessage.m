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
        else if (self.delivered == NO) {
            return ZMDeliveryStatePending;
        }
        else {
            return ZMDeliveryStateDelivered;
        }
    }
    else {
        return [super deliveryState];
    }
}

- (void)markAsDelivered
{
    self.delivered = YES;
    [super markAsDelivered];
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

+ (id)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
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
    
    if (![conversation shouldAddEvent:updateEvent] || message.hasClientAction) {
        [conversation addEventToDownloadedEvents:updateEvent.eventID timeStamp:updateEvent.timeStamp];
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
    
    if (clientMessage == nil) {
        clientMessage = [messageClass insertNewObjectInManagedObjectContext:moc];
    } else if (![clientMessage.senderClientID isEqualToString:updateEvent.senderClientID]) {
        return nil;
    }
    
    clientMessage.isEncrypted = encrypted;
    clientMessage.isPlainText = !encrypted;
    clientMessage.nonce = nonce;
    clientMessage.senderClientID = updateEvent.senderClientID;
    [clientMessage updateWithGenericMessage:message updateEvent:updateEvent];
    [clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation messageWasAlreadyReceived:clientMessage.delivered];
    
    return clientMessage;

}

@end
