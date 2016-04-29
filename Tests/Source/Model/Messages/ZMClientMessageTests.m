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


#import "ZMMessageTests.h"
#import "MessagingTest+EventFactory.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMClientMessage.h"
#import "ZMAssetClientMessage.h"

@import CoreGraphics;

@interface ZMClientMessageTests : BaseZMMessageTests

@end



@implementation ZMClientMessageTests

- (void)testThatItDoesNotCreateTextMessagesFromUpdateEventIfThereIsAlreadyAClientMessageWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *clientMessage = [ZMClientMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    clientMessage.visibleInConversation = conversation;
    clientMessage.nonce = nonce;
    
    NSDictionary *data = @{
                           @"content" : self.name,
                           @"nonce" : nonce.transportString
                           };
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAdd data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMTextMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMTextMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.messages.firstObject, clientMessage);
}

- (void)testThatItUpdatesIsPlainTextOnAlreadyExistingClientMessageWithTheSameNonceWhenReceivingATextMessageFromUpdateEvent
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *clientMessage = [ZMClientMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    clientMessage.visibleInConversation = conversation;
    clientMessage.nonce = nonce;
    XCTAssertFalse(clientMessage.isPlainText);
    
    NSDictionary *data = @{
                           @"content" : self.name,
                           @"nonce" : nonce.transportString
                           };
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAdd data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMTextMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertTrue(clientMessage.isPlainText);
}

- (void)testThatItStoresClientAsMissing
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage:self.name encrypted:YES];
    [message missesRecipient:client];
    
    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);
}

- (void)testThatItRemovesMissingClient
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage:self.name encrypted:YES];
    [message missesRecipient:client];
    
    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);
    
    [message doesNotMissRecipient:client];
    
    XCTAssertEqual(message.missingRecipients.count, 0u);
}


- (void)testThatClientMessageIsMarkedAsDelivered
{
    ZMClientMessage *message = [self createClientTextMessage:self.name encrypted:YES];
    [message setExpirationDate];
    
    [message markAsDelivered];
    XCTAssertTrue(message.delivered);
    XCTAssertFalse(message.isExpired);
}

- (void)testThatResendingClientMessageResetsExpirationDate
{
    ZMClientMessage *message = [self createClientTextMessage:self.name encrypted:YES];
    
    [message resend];
    XCTAssertNotNil(message.expirationDate);
}

@end



@implementation ZMClientMessageTests (CreateClientMessageFromUpdateEvent)

- (void)testThatItCreatesClientMessagesFromUpdateEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut.eventID, [ZMEventID eventIDWithString:payload[@"id"]]);
    XCTAssertEqualObjects(sut.conversation, conversation);
    XCTAssertEqualObjects(sut.sender.remoteIdentifier.transportString, payload[@"from"]);
    XCTAssertEqualObjects(sut.serverTimestamp.transportString, payload[@"time"]);
    
    XCTAssertFalse(sut.isEncrypted);
    XCTAssertTrue(sut.isPlainText);
    XCTAssertEqualObjects(sut.nonce, nonce);
    AssertEqualData(sut.genericMessage.data, contentData);
}

- (void)testThatItCreatesOTRMessagesFromUpdateEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut.conversation, conversation);
    XCTAssertEqualObjects(sut.sender.remoteIdentifier.transportString, payload[@"from"]);
    XCTAssertEqualObjects(sut.serverTimestamp.transportString, payload[@"time"]);
    
    XCTAssertTrue(sut.isEncrypted);
    XCTAssertFalse(sut.isPlainText);
    XCTAssertEqualObjects(sut.nonce, nonce);
    AssertEqualData(sut.genericMessage.data, contentData);
}

- (void)testThatItDoesNotCreateClientMessagesIfThereIsAlreadyATextMessageWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMTextMessage *existingMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.messages.firstObject, existingMessage);
}

- (void)testThatItDoesNotCreateTextMessagesIfThereIsAlreadyAClientMessageWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *existingMessage = [ZMClientMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    
    NSDictionary *data = @{@"content": self.name, @"nonce": nonce.transportString};
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMTextMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMTextMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.messages.firstObject, existingMessage);
}

- (void)testThatItDoesNotCreateKnockMessagesIfThereIsAlreadyOtrKnockWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *existingMessage = [ZMClientMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage knockWithNonce:nonce.transportString];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    
    NSDictionary *data = @{@"nonce": nonce.transportString};
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationKnock data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMKnockMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMKnockMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.messages.firstObject, existingMessage);
}

- (void)testThatItDoesNotCreateOtrKnockIfThereIsAlreadyKnockMessageWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMKnockMessage *existingMessage = [ZMKnockMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    
    NSString *data = [ZMGenericMessage knockWithNonce:nonce.transportString].data.base64String;
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.messages.firstObject, existingMessage);
}

- (void)testThatItDoesNotCreateMessageFromClientActionMessage
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSString *data = [ZMGenericMessage sessionResetWithNonce:nonce.transportString].data.base64String;
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqual(conversation.messages.count, 0u);
}

- (void)testThatItUpdates_IsEncrypted_OnAnAlreadyExistingTextMessageWithTheSameNonceWhenReceivingAnOTRClientMessage
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMTextMessage *existingMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    XCTAssertFalse(existingMessage.isEncrypted);
    
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertTrue(existingMessage.isEncrypted);
}

- (void)testThatItUpdates_IsPlainText_OnAnAlreadyExistingClientMessageWithTheSameNonceWhenReceivingAnTextMessage
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *existingMessage = [ZMClientMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    
    NSDictionary *data = @{@"content": self.name, @"nonce": nonce.transportString};
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMTextMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMTextMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertTrue(existingMessage.isPlainText);
}


- (void)testThatItUpdates_IsEncrypted_OnAnAlreadyExistingAssetMessageWithTheSameNonceWhenReceivingAnOTRAssetMessage
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMImageMessage *existingMessage = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    XCTAssertFalse(existingMessage.isEncrypted);
    
    ZMGenericMessage *message = [ZMGenericMessage messageWithImageData:[self verySmallJPEGData] format:ZMImageFormatMedium nonce:nonce.transportString];
    NSData *contentData = message.data;
    NSDictionary *data = @{@"info": [contentData base64EncodedStringWithOptions:0]};
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRAsset data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMAssetClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertTrue(existingMessage.isEncrypted);
}

- (void)testThatItDoesNotUpdate_IsEncrypted_OnAnAlreadyExistingTextMessageWithTheSameNonceWhenReceivingANonEncryptedClientMessage
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMTextMessage *existingMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    XCTAssertFalse(existingMessage.isEncrypted);
    
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:self.name nonce:nonce.transportString];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertFalse(existingMessage.isEncrypted);
}

- (void)testThatItReturnsNilIfTheClientMessageContentIsInvalid
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSString *data = @"123";
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAdd data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        [self performIgnoringZMLogError:^{
            sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
        }];
    }];
    
    // then
    XCTAssertNil(sut);
    
}


@end


@implementation ZMClientMessageTests (ExternalMessage)

- (void)testThatCreatesEncryptedDataAndAddsItToGenericMessageAsBlob
{
    // given
    [self createSelfClient];
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;
    UserClient *firstClient = [self createClientForUser:otherUser createSessionWithSelfUser:YES];
    UserClient *secondClient =[self createClientForUser:otherUser createSessionWithSelfUser:YES];
    NSUUID *nonce = NSUUID.createUUID;
    ZMGenericMessageBuilder *builder = ZMGenericMessage.builder;
    ZMTextBuilder *textBuilder = ZMText.builder;
    textBuilder.content = [self textMessageRequiringExternalMessageWithNumberOfClients:2];
    builder.text = textBuilder.build;
    builder.messageId = nonce.transportString;
    ZMGenericMessage *textMessage = builder.build;
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.remoteIdentifier = NSUUID.createUUID;
    [conversation addParticipant:otherUser];
    
    XCTAssertTrue([self.syncMOC saveOrRollback]);
    
    // when
    NSData *data = [ZMClientMessage encryptedMessagePayloadDataWithGenericMessage:textMessage
                                                                     conversation:conversation
                                                             managedObjectContext:self.syncMOC
                                                                     externalData:nil];
    
    // then
    ZMNewOtrMessage *createdMessage = (ZMNewOtrMessage *)[ZMNewOtrMessage.builder mergeFromData:data].build;
    XCTAssertNotNil(createdMessage);
    XCTAssertTrue(createdMessage.hasBlob);
    
    NSArray <ZMClientId *>* clientIds = [createdMessage.recipients flattenWithBlock:^NSArray *(ZMUserEntry *userEntry) {
        return [userEntry.clients mapWithBlock:^ZMClientId *(ZMClientEntry *clientEntry) {
            return clientEntry.client;
        }];
    }];
    
    XCTAssertEqual(clientIds.count, 2lu);
    XCTAssertTrue([clientIds containsObject:firstClient.clientId]);
    XCTAssertTrue([clientIds containsObject:secondClient.clientId]);
}


- (void)testThatItDecryptsMessageWithExternalBlobCorrectly
{
    // given
    [self createSelfClient];
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;
    UserClient *firstClient = [self createClientForUser:otherUser createSessionWithSelfUser:YES];
    
    ZMUpdateEvent *messageEvent = [self encryptedExternalMessageFixtureWithBlobFromClient:firstClient];
    NSString *base64SHA = @"kKSSlbMxXEdd+7fekxB8Qr67/mpjjboBsr2wLcW7wzE=";
    NSString *base64OTRKey = @"4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w=";
    ZMExternalBuilder *builder = ZMExternal.builder;
    builder.sha256 = [[NSData alloc] initWithBase64EncodedString:base64SHA options:0];
    builder.otrKey = [[NSData alloc] initWithBase64EncodedString:base64OTRKey options:0];

    // when
    ZMGenericMessage *message = [ZMGenericMessage genericMessageFromUpdateEventWithExternal:messageEvent external:builder.build];
    
    // then
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.text.content, self.expectedExternalMessageText);
}

#pragma mark - Helper

- (NSString *)textMessageRequiringExternalMessageWithNumberOfClients:(NSUInteger)count
{
    NSMutableString *text = @"Long Text".mutableCopy;
    while ([text dataUsingEncoding:NSUTF8StringEncoding].length < ZMClientMessageByteSizeExternalThreshold / count) {
        [text appendString:text];
    }
    return text;
}

- (ZMUpdateEvent *)encryptedExternalMessageFixtureWithBlobFromClient:(UserClient *)fromClient
{
    NSError *error;
    NSURL *encryptedMessageURL = [self fileURLForResource:@"EncryptedBase64EncondedExternalMessageTestFixture" extension:@"txt"];
    NSString *encryptedMessageFixtureString = [[NSString alloc] initWithContentsOfURL:encryptedMessageURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    
    NSDictionary *payload = @{
                              @"conversation": NSUUID.createUUID.transportString,
                              @"data": @"CiQzMzRmN2Y3Yi1hNDk5LTQ1MTMtOTJhOC1hZTg4MDI0OTQ0ZTlCRAog4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7wSIJCkkpWzMVxHXfu33pMQfEK+u/5qY426AbK9sC3Fu8Mx",
                              @"external": encryptedMessageFixtureString,
                              @"from": fromClient.remoteIdentifier,
                              @"time": NSDate.date.transportString,
                              @"type": @"conversation.otr-message-add"
                              };
    
    return [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:NSUUID.createUUID];
}

- (NSString *)expectedExternalMessageText
{
    NSError *error;
    NSURL *messageFixtureURL = [self fileURLForResource:@"ExternalMessageTextFixture" extension:@"txt"];
    NSString *messageFixtureString = [[NSString alloc] initWithContentsOfURL:messageFixtureURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);

    return messageFixtureString;
}

@end
