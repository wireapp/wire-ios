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


#import "ZMMessageTests.h"
#import "MessagingTest+EventFactory.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMClientMessage.h"
#import "NSString+RandomString.h"
#import "WireDataModelTests-Swift.h"
#import <WireDataModel/WireDataModel-Swift.h>

@import CoreGraphics;
@import WireLinkPreview;
@import WireDataModel;

@interface ZMClientMessageTests : BaseZMMessageTests
@end

@implementation ZMClientMessageTests

- (void)testThatItDoesNotCreateTextMessagesFromUpdateEventIfThereIsAlreadyAClientMessageWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *clientMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    clientMessage.visibleInConversation = conversation;
    
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
    XCTAssertEqual(conversation.lastMessage, clientMessage);
}

- (void)testThatItStoresClientAsMissing
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage];
    [message missesRecipient:client];
    
    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);
}

- (void)testThatItRemovesMissingClient
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage];
    [message missesRecipient:client];
    
    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);
    
    [message doesNotMissRecipient:client];
    
    XCTAssertEqual(message.missingRecipients.count, 0u);
}


- (void)testThatClientMessageIsMarkedAsDelivered
{
    ZMClientMessage *message = [self createClientTextMessage];
    [message setExpirationDate];
    
    [message markAsSent];
    XCTAssertTrue(message.delivered);
    XCTAssertFalse(message.isExpired);
}

- (void)testThatResendingClientMessageResetsExpirationDate
{
    ZMClientMessage *message = [self createClientTextMessage];
    
    [message resend];
    XCTAssertNotNil(message.expirationDate);
}

- (void)testThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet
{
    int16_t states[] = {
        ZMLinkPreviewStateWaitingToBeProcessed,
        ZMLinkPreviewStateDownloaded,
        ZMLinkPreviewStateProcessed ,
        ZMLinkPreviewStateUploaded,
        ZMLinkPreviewStateDone
    };
    
    for (unsigned long i = 0; i < sizeof(states) / sizeof(ZMLinkPreviewState); i++) {
        [self assertThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet:states[i] shouldSet:states[i] != ZMLinkPreviewStateDone];
    }
}

- (void)assertThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet:(ZMLinkPreviewState)state shouldSet:(BOOL)shouldSet
{
    // given
    ZMClientMessage *message = [self createClientTextMessage];
    XCTAssertFalse([message.keysThatHaveLocalModifications containsObject:ZMClientMessageLinkPreviewStateKey]);
    
    // when
    message.linkPreviewState = state;
    
    // then
    XCTAssertEqual([message.keysThatHaveLocalModifications containsObject:ZMClientMessageLinkPreviewStateKey], shouldSet);
}

- (void)testThatAInsertedClientMessageHasADefaultLinkPreviewStateDone
{
    ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
}

- (void)testThatAAppendedClientMessageHasLinkPreviewStateWaitingToBeProcessed
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:self.name];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateWaitingToBeProcessed);
}

- (void)testThatAAppendedClientMessageWithFlagToNotFetchPreviewSetHasLinkPreviewStateDone
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:self.name fetchLinkPreview:NO];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
}

@end



@implementation ZMClientMessageTests (CreateClientMessageFromUpdateEvent)

- (void)testThatItCreatesClientMessagesFromUpdateEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:self.name mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
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
    XCTAssertEqualObjects(sut.conversation, conversation);
    XCTAssertEqualObjects(sut.sender.remoteIdentifier.transportString, payload[@"from"]);
    XCTAssertEqualObjects(sut.serverTimestamp.transportString, payload[@"time"]);
    
    XCTAssertEqualObjects(sut.nonce, nonce);
    AssertEqualData(sut.genericMessage.data, contentData);
}

- (void)testThatItCreatesOTRMessagesFromUpdateEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSString *senderClientID = [NSString createAlphanumericalString];
    NSUUID *nonce = [NSUUID createUUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:self.name mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    NSData *contentData = message.data;
    
    NSDictionary *data = @{ @"sender": senderClientID, @"text" : [contentData base64EncodedStringWithOptions:0] };
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
    XCTAssertEqualObjects(sut.senderClientID, senderClientID);
    
    XCTAssertEqualObjects(sut.nonce, nonce);
    AssertEqualData(sut.genericMessage.data, contentData);
}

- (void)testThatItDoesNotCreateOTRMessageIfItsIdentifierIsInvalid
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];

    NSString *senderClientID = [NSString createAlphanumericalString];
    NSUUID *nonce = [NSUUID createUUID];
    ZMGenericMessage *prototype = [ZMGenericMessage messageWithContent:[ZMText textWith:self.name mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    ZMGenericMessageBuilder *builder = [ZMGenericMessage builderWithPrototype:prototype];
    [builder setMessageId:@"please-fail"];

    ZMGenericMessage *message = [builder build];
    NSData *contentData = message.data;

    NSDictionary *data = @{ @"sender": senderClientID, @"text" : [contentData base64EncodedStringWithOptions:0] };
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
    XCTAssertEqual(sut.conversation.lastMessage.systemMessageData.systemMessageType, ZMSystemMessageTypeInvalid);
}

- (void)testThatItDoesNotCreateKnockMessagesIfThereIsAlreadyOtrKnockWithTheSameNonce
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMKnock knock] nonce:NSUUID.createUUID];
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
    XCTAssertEqual(conversation.lastMessage, existingMessage);
}

- (void)testThatItDoesNotCreateMessageFromClientActionMessage
{
    // given
    NSString *senderClientID = [NSString createAlphanumericalString];
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSDictionary *data = @{ @"sender": senderClientID, @"text" : [ZMGenericMessage clientAction:ZMClientActionRESETSESSION nonce:nonce].data.base64String };
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
    XCTAssertEqual(conversation.allMessages.count, 0u);
}

- (void)testThatItDoesNotCreateMessageFromAvailabilityMessage
{
    // given
    NSString *senderClientID = [NSString createAlphanumericalString];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    NSDictionary *data = @{ @"sender": senderClientID, @"text" : [ZMGenericMessage messageWithContent:[ZMAvailability availability:AvailabilityAway] nonce:NSUUID.createUUID].data.base64String };
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
    XCTAssertEqual(conversation.allMessages.count, 0u);
}

- (void)testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWithoutASenderClientID
{
    // given
    NSString *initialText = @"initial text";
    NSString *modifiedText = @"modified text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    
    ZMGenericMessage *modifiedMessage =     [ZMGenericMessage messageWithContent:[ZMText textWith:modifiedText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWithTheSameNonceButDifferentClient
{
    // given
    NSString *initialText = @"initial text";
    NSString *modifiedText = @"modified text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    NSString *unknownSender = [NSString createAlphanumericalString];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message =     [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    ZMGenericMessage *modifiedMessage =     [ZMGenericMessage messageWithContent:[ZMText textWith:modifiedText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    NSDictionary *data = @{ @"sender" : unknownSender, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(sut);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWhichDoesntContainLinkPreviewUpdate
{
    // given
    NSString *initialText = @"initial text";
    NSString *modifiedText = @"modified text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message =     [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:NSUUID.createUUID];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:modifiedText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWhichContainLinkPreviewUpdateButModifiedText
{
    // given
    NSString *initialText = @"initial text";
    NSString *modifiedText = @"modified text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:NSUUID.createUUID];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    ZMLinkPreview *linkPreview = [ZMLinkPreview linkPreviewWithOriginalURL:@"http://www.sunet.se" permanentURL:@"http://www.sunet.se" offset:0 title:@"Test" summary:nil imageAsset:nil];
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:modifiedText mentions:@[] linkPreviews:@[linkPreview] replyingTo:nil] nonce:nonce];
    
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItUpdates_AnAlreadyExistingClientMessageWhichContainLinkPreviewUpdate
{
    // given
    NSString *initialText = @"initial text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    ZMLinkPreview *linkPreview = [ZMLinkPreview linkPreviewWithOriginalURL:@"http://www.sunet.se" permanentURL:@"http://www.sunet.se" offset:0 title:@"Test" summary:nil imageAsset:nil];
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[linkPreview] replyingTo:nil] nonce:nonce];
    
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertNotNil(existingMessage.linkPreview);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItUpdates_AnAlreadyExistingEphemeralClientMessageWhichContainLinkPreviewUpdate
{
    // given
    NSString *initialText = @"initial text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce timeout:3600];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    ZMLinkPreview *linkPreview = [ZMLinkPreview linkPreviewWithOriginalURL:@"http://www.sunet.se" permanentURL:@"http://www.sunet.se" offset:0 title:@"Test" summary:nil imageAsset:nil];
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[linkPreview] replyingTo:nil] nonce:nonce timeout:3600];
    
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertTrue(existingMessage.isEphemeral);
    XCTAssertNotNil(existingMessage.linkPreview);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItIgnores_AnyAdditionalFieldsInTheLinkPreviewUpdate
{
    // given
    NSString *initialText = @"initial text";
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    UserClient *selfClient = [self createSelfClient];
    
    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;
    
    // We add a quote to the link preview update
    ZMLinkPreview *linkPreview = [ZMLinkPreview linkPreviewWithOriginalURL:@"http://www.sunet.se" permanentURL:@"http://www.sunet.se" offset:0 title:@"Test" summary:nil imageAsset:nil];
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[linkPreview] replyingTo:existingMessage] nonce:nonce];
    
    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertNotNil(existingMessage.linkPreview);
    XCTAssertFalse(existingMessage.genericMessage.textData.hasQuote);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}

- (void)testThatItIgnoresBlacklistedLinkPreview
{
    // given
    NSString *initialText = @"initial text";

    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];

    UserClient *selfClient = [self createSelfClient];

    ZMClientMessage *existingMessage = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    [existingMessage addData:message.data];
    existingMessage.visibleInConversation = conversation;
    existingMessage.sender = self.selfUser;
    existingMessage.senderClientID = selfClient.remoteIdentifier;

    // We add a quote to the link preview update
    ZMLinkPreview *linkPreview = [ZMLinkPreview linkPreviewWithOriginalURL:@"http://www.youtube.com/watch" permanentURL:@"http://www.youtube.com/watch" offset:0 title:@"YouTube" summary:nil imageAsset:nil];
    ZMGenericMessage *modifiedMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:initialText mentions:@[] linkPreviews:@[linkPreview] replyingTo:existingMessage] nonce:nonce];

    NSDictionary *data = @{ @"sender" : selfClient.remoteIdentifier, @"recipient": selfClient.remoteIdentifier, @"text": modifiedMessage.data.base64String };
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddOTRMessage data:data time:[NSDate date] fromUser:self.selfUser];

    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);

    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];

    // then
    XCTAssertNotNil(sut);
    XCTAssertNotNil(existingMessage.firstZMLinkPreview);
    XCTAssertNil(existingMessage.linkPreview); // do not return a link preview even if it's included in the protobuf
    XCTAssertFalse(existingMessage.genericMessage.textData.hasQuote);
    XCTAssertEqualObjects(existingMessage.textMessageData.messageText, initialText);
}


- (void)testThatItReturnsNilIfTheClientMessageIsZombie
{
    // given
    NSUUID *nonce = [NSUUID createUUID];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *existingMessage = (ZMClientMessage *)[conversation appendMessageWithText:@"Initial"];
    existingMessage.nonce = nonce;
    existingMessage.visibleInConversation = conversation;
    
    ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMText textWith:self.name mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    NSData *contentData = message.data;
    
    NSString *data = [contentData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationAddClientMessage data:data];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    ZMFetchRequestBatch *prefetch = [[ZMFetchRequestBatch alloc] init];
    [prefetch addNoncesToPrefetchMessages:[NSSet setWithObject:existingMessage.nonce]];
    ZMFetchRequestBatchResult *prefetchResult = [prefetch executeInManagedObjectContext:self.uiMOC];
    
    XCTAssertEqual([prefetchResult.messagesByNonce[existingMessage.nonce] count], 1u);
    XCTAssertEqual([prefetchResult.messagesByNonce[existingMessage.nonce] anyObject], existingMessage);
    XCTAssertFalse(existingMessage.isZombieObject);
    
    // when
    [self.uiMOC deleteObject:existingMessage];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue(existingMessage.isZombieObject);
    
    // when
    __block ZMClientMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        [self performIgnoringZMLogError:^{
            sut = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:prefetchResult];
        }];
    }];
    
    // then
    XCTAssertNil(sut);
    
}

@end


@implementation ZMClientMessageTests (ExternalMessage)


- (void)testThatItDecryptsMessageWithExternalBlobCorrectly
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        [self createSelfClient];
        ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        otherUser.remoteIdentifier = NSUUID.createUUID;
        UserClient *firstClient = [self createClientForUser:otherUser createSessionWithSelfUser:YES onMOC:self.syncMOC];
        
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
    }];
}


@end


@implementation ZMClientMessageTests (DataSet)

- (void)testThatItCanUpdateAnExistingLinkPreviewInTheDataSetWithoutCreatingMultipleOnes
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *nonce = NSUUID.createUUID;
        ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:nonce managedObjectContext:self.syncMOC];
        NSData *otrKey = NSData.randomEncryptionKey, *sha256 = NSData.zmRandomSHA256Key;
        
        // when
        {
            ZMTextBuilder *builder = ZMText.builder;
            [builder setContent:self.name];
            ZMLinkPreviewBuilder *previewBuilder = ZMLinkPreview.builder;
            [previewBuilder setUrl:self.name];
            [previewBuilder setUrlOffset:0];
            ZMArticleBuilder *articleBuilder = ZMArticle.builder;
            [articleBuilder setTitle:@"Title"];
            [articleBuilder setSummary:@"Summary"];
            ZMAssetBuilder *assetBuilder = ZMAsset.builder;
            ZMAssetRemoteDataBuilder *remoteBuilder = ZMAssetRemoteData.builder;
            [remoteBuilder setOtrKey:otrKey];
            [remoteBuilder setSha256:sha256];
            [assetBuilder setUploadedBuilder:remoteBuilder];
            [articleBuilder setImageBuilder:assetBuilder];
            [articleBuilder setPermanentUrl:@"www.example.de"];
            [previewBuilder setArticleBuilder:articleBuilder];
            [builder setLinkPreviewArray:@[previewBuilder.build]];
            ZMGenericMessageBuilder *messageBuilder = ZMGenericMessage.builder;
            [messageBuilder setText:builder.build];
            [messageBuilder setMessageId:nonce.transportString];
            ZMGenericMessage *firstMessage = messageBuilder.build;
            [message addData:firstMessage.data];
            
            // then
            XCTAssertEqual(message.dataSet.count, 1lu);
            XCTAssertTrue(message.genericMessage.hasText);
            XCTAssertEqual(message.genericMessage.text.linkPreview.count, 1lu);
        }
        
        // when
        {
            ZMGenericMessageBuilder *secondBuilder = [[ZMGenericMessage builder] mergeFrom:message.genericMessage];
            ZMTextBuilder *builder = secondBuilder.text.toBuilder;
            ZMLinkPreviewBuilder *linkBuilder = [(ZMLinkPreview *)secondBuilder.text.linkPreview.firstObject toBuilder];
            ZMArticleBuilder *articleBuilder = linkBuilder.article.toBuilder;
            ZMAssetBuilder *assetBuilder = linkBuilder.article.image.toBuilder;
            ZMAssetRemoteDataBuilder *remoteBuilder = linkBuilder.article.image.uploaded.toBuilder;
            [remoteBuilder setAssetId:@"Asset ID"];
            [remoteBuilder setAssetToken:@"Asset Token"];
            [assetBuilder setUploadedBuilder:remoteBuilder];
            [articleBuilder setImageBuilder:assetBuilder];
            [linkBuilder setArticleBuilder:articleBuilder];
            [builder setLinkPreviewArray:@[linkBuilder.build]];
            [secondBuilder setTextBuilder:builder];
            [message addData:secondBuilder.build.data];
            
            // then
            XCTAssertEqual(message.dataSet.count, 1lu);
            XCTAssertTrue(message.genericMessage.hasText);
            XCTAssertEqual(message.genericMessage.text.linkPreview.count, 1lu);
            ZMAssetRemoteData *remote = [(ZMLinkPreview *)message.genericMessage.text.linkPreview.firstObject article].image.uploaded;
            XCTAssertEqualObjects(remote.assetId, @"Asset ID");
            XCTAssertEqualObjects(remote.assetToken, @"Asset Token");
        }

    }];
}

@end
