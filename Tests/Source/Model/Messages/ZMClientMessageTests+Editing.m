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

@interface ZMClientMessageTests_Editing : BaseZMMessageTests

@end


@implementation ZMClientMessageTests_Editing

- (void)checkThatItCanEditAMessageFromSameSender:(BOOL)sameSender shouldEdit:(BOOL)shouldEdit
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    ZMUser *sender;
    if (sameSender) {
        sender = self.selfUser;
    } else {
        sender =[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        sender.remoteIdentifier = [NSUUID createUUID];
    }
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *message = (id)[conversation appendMessageWithText:oldText];
    message.sender = sender;
    [message markAsSent];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    NSUUID *originalNonce = message.nonce;
    
    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.allMessages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    // when
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.allMessages.count, 1u);
    
    if (shouldEdit) {
        XCTAssertEqualObjects(message.textMessageData.messageText, newText);
        XCTAssertEqualObjects(message.normalizedText, newText.lowercaseString);
        XCTAssertEqualObjects(message.genericMessage.edited.replacingMessageId, originalNonce.transportString);
        XCTAssertNotEqualObjects(message.nonce, originalNonce);
    } else {
        XCTAssertEqualObjects(message.textMessageData.messageText, oldText);
    }
}

- (void)testThatItCanEditAMessage_SameSender
{
    [self checkThatItCanEditAMessageFromSameSender:YES shouldEdit:YES];
}

- (void)testThatItCanNotEditAMessage_DifferentSender
{
    [self checkThatItCanEditAMessageFromSameSender:NO shouldEdit:NO];
}

- (void)testThatExtremeCombiningCharactersAreRemovedFromTheMessage
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    // WHEN
    ZMMessage *message = (id)[conversation appendMessageWithText:@"ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂"];
    
    
    // THEN
    XCTAssertEqualObjects(message.textMessageData.messageText, @"test̻̟̙");
}

- (void)testThatItResetsTheLinkPreviewState
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:oldText];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    message.linkPreviewState = ZMLinkPreviewStateDone;
    [message markAsSent];

    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
    
    // when
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateWaitingToBeProcessed);
}

- (void)testThatItDoesNotFetchLinkPreviewIfExplicitlyToldNotTo
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    
    BOOL fetchLinkPreview = NO;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:oldText fetchLinkPreview:fetchLinkPreview];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    [message markAsSent];
    
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
    
    // when
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:fetchLinkPreview];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
}

- (void)testThatItDoesNotEditAMessageThatFailedToSend
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    [message expire];
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    // when
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(message.textMessageData.messageText, oldText);
}

- (void)testThatItUpdatesTheUpdatedTimestampAfterSuccessfulUpdate
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSDate *originalDate = [NSDate dateWithTransportString:[NSDate dateWithTimeIntervalSinceNow:-50].transportString];
    NSDate *updateDate = [NSDate dateWithTransportString:[NSDate dateWithTimeIntervalSinceNow:-20].transportString];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.serverTimestamp = originalDate;
    [message markAsSent];

    conversation.lastModifiedDate = originalDate;
    conversation.lastServerTimeStamp = originalDate;

    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.allMessages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [message updateWithPostPayload:@{@"time" : updateDate.transportString } updatedKeys:nil];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(message.serverTimestamp, originalDate);
    XCTAssertEqualObjects(message.updatedAt, updateDate);
    XCTAssertEqualObjects(message.textMessageData.messageText, newText);
}

- (void)testThatItDoesNotOverwritesEditedTextWhenMessageExpiresButReplacesNonce
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSDate *originalDate = [NSDate dateWithTransportString:[NSDate dateWithTimeIntervalSinceNow:-50].transportString];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.serverTimestamp = originalDate;
    [message markAsSent];

    conversation.lastModifiedDate = originalDate;
    conversation.lastServerTimeStamp = originalDate;
    NSUUID *originalNonce = message.nonce;

    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.allMessages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [message expire];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(message.nonce, originalNonce);
}

- (void)testThatWhenResendingAFailedEditItReappliesTheEdit
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSDate *originalDate = [NSDate dateWithTransportString:[NSDate dateWithTimeIntervalSinceNow:-50].transportString];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMClientMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.serverTimestamp = originalDate;
    [message markAsSent];

    conversation.lastModifiedDate = originalDate;
    conversation.lastServerTimeStamp = originalDate;
    NSUUID *originalNonce = message.nonce;

    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.allMessages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    [message.textMessageData editText:newText mentions:@[] fetchLinkPreview:NO];
    NSUUID *editNonce1 = message.nonce;
    WaitForAllGroupsToBeEmpty(0.5);
    
    [message expire];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [message resend];
    NSUUID *editNonce2 = message.nonce;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotEqualObjects(editNonce2, editNonce1);
    XCTAssertEqualObjects(message.genericMessage.edited.replacingMessageId, originalNonce.transportString);
}

- (ZMUpdateEvent *)createMessageEditUpdateEventWithOldNonce:(NSUUID *)oldNonce newNonce:(NSUUID *)newNonce conversationID:(NSUUID*)conversationID senderID:(NSUUID *)senderID newText:(NSString *)newText
{
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithContent:[ZMMessageEdit editWith:[ZMText textWith:newText mentions:@[] linkPreviews:@[] replyingTo:nil] replacingMessageId:oldNonce] nonce:newNonce];
    
    NSDictionary *payload = @{
                   @"conversation": conversationID.transportString,
                   @"from": senderID.transportString,
                   @"time": [NSDate date].transportString,
                   @"data": @{
                            @"text": genericMessage.data.base64String
                            },
                   @"type": @"conversation.otr-message-add"
                   };
    
    return [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:[NSUUID createUUID]];
}

- (ZMUpdateEvent *)createTextAddedEventWithNonce:(NSUUID *)nonce conversationID:(NSUUID*)conversationID senderID:(NSUUID *)senderID
{
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:@"Yeah!" mentions:@[] linkPreviews:@[] replyingTo:nil] nonce:nonce];
    
    NSDictionary *payload = @{
                              @"conversation": conversationID.transportString,
                              @"from": senderID.transportString,
                              @"time": [NSDate date].transportString,
                              @"data": @{
                                      @"text": genericMessage.data.base64String
                                      },
                              @"type": @"conversation.otr-message-add"
                              };
    
    return [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:[NSUUID createUUID]];
}

- (void)testThatItEditsMessageWithQuote
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSUUID *senderID = self.selfUser.remoteIdentifier;
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *quotedMessage = (id) [conversation appendMessageWithText:@"Quote"];
    ZMMessage *message = (id) [conversation appendText:oldText mentions:@[] replyingToMessage:quotedMessage fetchLinkPreview:NO nonce:NSUUID.createUUID];
    [self.uiMOC saveOrRollback];
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:senderID newText:newText];
    NSUUID *oldNonce = message.nonce;
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(message.textMessageData.messageText, newText);
    XCTAssertTrue(message.textMessageData.hasQuote);
    XCTAssertNotEqualObjects(message.nonce, oldNonce);
    XCTAssertEqualObjects(message.textMessageData.quote, quotedMessage);
}

- (void)testThatReadExpectationIsKeptAfterEdit
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSUUID *senderID = self.selfUser.remoteIdentifier;
    
    self.selfUser.readReceiptsEnabled = YES;
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    ZMClientMessage *message = (id) [conversation appendText:oldText mentions:@[] replyingToMessage:nil fetchLinkPreview:NO nonce:NSUUID.createUUID];
    [message addData:[message.genericMessage setExpectsReadConfirmation:YES].data];
    [self.uiMOC saveOrRollback];
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:senderID newText:newText];
    NSUUID *oldNonce = message.nonce;
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(message.textMessageData.messageText, newText);
    XCTAssertNotEqualObjects(message.nonce, oldNonce);
    XCTAssertTrue(message.needsReadConfirmation);
}

- (void)checkThatItEditsMessageForSameSender:(BOOL)sameSender shouldEdit:(BOOL)shouldEdit
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSUUID *senderID = sameSender ? self.selfUser.remoteIdentifier : [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    
    [message addReaction:@"👻" forUser:self.selfUser];
    [self.uiMOC saveOrRollback];

    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:senderID newText:newText];
    NSUUID *oldNonce = message.nonce;

    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    if (shouldEdit) {
        XCTAssertEqualObjects(message.textMessageData.messageText, newText);
        XCTAssertNotEqualObjects(message.nonce, oldNonce);
        XCTAssertTrue(message.reactions.isEmpty);
        XCTAssertEqual(message.visibleInConversation, conversation);
        XCTAssertNil(message.hiddenInConversation);
    } else {
        XCTAssertEqualObjects(message.textMessageData.messageText, oldText);
        XCTAssertEqualObjects(message.nonce, oldNonce);
        XCTAssertEqual(message.visibleInConversation, conversation);
        XCTAssertNil(message.hiddenInConversation);
    }
}

- (void)testThatEditsMessageWhenSameSender
{
    [self checkThatItEditsMessageForSameSender:YES shouldEdit:YES];
}

- (void)testThatDoesntEditMessageWhenSenderIsDifferent
{
    [self checkThatItEditsMessageForSameSender:NO shouldEdit:NO];
}

- (void)testThatItDoesNotInsertAMessageWithANonceBelongingToAHiddenMessage
{
    // given
    NSString *oldText = @"Hallo";
    NSUUID *senderID = self.selfUser.remoteIdentifier;
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.visibleInConversation = nil;
    message.hiddenInConversation = conversation;
    
    ZMUpdateEvent *updateEvent = [self createTextAddedEventWithNonce:message.nonce conversationID:conversation.remoteIdentifier senderID:senderID];
    
    // when
    __block ZMClientMessage *newMessage;
    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNil(newMessage);
}

- (void)testThatItSetsTheTimestampsOfTheOriginalMessage
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSDate *oldDate = [NSDate dateWithTimeIntervalSinceNow:-20];
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.sender = sender;
    message.serverTimestamp = oldDate;
    
    conversation.lastModifiedDate = oldDate;
    conversation.lastServerTimeStamp = oldDate;
    conversation.lastReadServerTimeStamp = oldDate;
    XCTAssertEqual(conversation.estimatedUnreadCount, 0u);
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:sender.remoteIdentifier newText:newText];
    
    // when
    __block ZMClientMessage *newMessage;

    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, oldDate);
    XCTAssertEqualObjects(conversation.lastServerTimeStamp, oldDate);
    XCTAssertEqualObjects(newMessage.serverTimestamp, oldDate);
    XCTAssertEqualObjects(newMessage.updatedAt, updateEvent.timeStamp);

    XCTAssertEqual(conversation.estimatedUnreadCount, 0u);
}

- (void)testThatItDoesNotReinsertAMessageThatHasBeenPreviouslyHiddenLocally
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSDate *oldDate = [NSDate dateWithTimeIntervalSinceNow:-20];
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    // insert message locally
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.sender = sender;
    message.serverTimestamp = oldDate;
    
    // hide message locally
    [ZMMessage hideMessage:message];
    XCTAssertTrue(message.isZombieObject);
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:sender.remoteIdentifier newText:newText];
    
    // when
    __block ZMClientMessage *newMessage;
    
    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNil(newMessage);
    XCTAssertNil(message.visibleInConversation);
    XCTAssertTrue(message.isZombieObject);
    XCTAssertTrue(message.hasBeenDeleted);
    XCTAssertNil(message.textMessageData);
    XCTAssertNil(message.sender);
    XCTAssertNil(message.senderClientID);
    
    ZMClientMessage *clientMessage = (ZMClientMessage *)message;
    XCTAssertNil(clientMessage.genericMessage);
    XCTAssertEqual(clientMessage.dataSet.count, 0lu);
}

- (void)testThatItClearsReactionsWhenAMessageIsEdited
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:@"Hallo"];

    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;
    
    [message addReaction:@"😱" forUser:self.selfUser];
    [message addReaction:@"🤗" forUser:otherUser];
    
    [self.uiMOC saveOrRollback];
    XCTAssertFalse(message.reactions.isEmpty);

    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce
                                                                       newNonce:NSUUID.createUUID
                                                                 conversationID:conversation.remoteIdentifier
                                                                       senderID:message.sender.remoteIdentifier
                                                                        newText:@"Hello"];
    // when
    __block ZMClientMessage *newMessage;

    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(message.reactions.isEmpty);
    XCTAssertEqual(conversation.allMessages.count, 1lu);

    ZMMessage *editedMessage = conversation.lastMessage;
    XCTAssertTrue(editedMessage.reactions.isEmpty);
    XCTAssertEqualObjects(editedMessage.textMessageData.messageText, @"Hello");
}

- (void)testThatItClearsReactionsWhenAMessageIsEditedRemotely
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:@"Hallo"];
    
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;
    
    [message addReaction:@"😱" forUser:self.selfUser];
    [message addReaction:@"🤗" forUser:otherUser];
    
    [self.uiMOC saveOrRollback];
    XCTAssertFalse(message.reactions.isEmpty);
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce
                                                                       newNonce:NSUUID.createUUID
                                                                 conversationID:conversation.remoteIdentifier
                                                                       senderID:message.sender.remoteIdentifier
                                                                        newText:@"Hello"];
    // when
    __block ZMClientMessage *newMessage;
    
    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(message.reactions.isEmpty);    
    ZMMessage *editedMessage = conversation.lastMessage;
    XCTAssertTrue(editedMessage.reactions.isEmpty);
    XCTAssertEqualObjects(editedMessage.textMessageData.messageText, @"Hello");
}

- (void)testThatMessageNonPersistedIdentifierDoesNotChangeAfterEdit
{
    // given
    NSString *oldText = @"Mamma mia";
    NSString *newText = @"here we go again";
    NSUUID *oldNonce = [NSUUID createUUID];

    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    message.sender = sender;
    message.nonce = oldNonce;

    NSString *oldIdentifier = message.nonpersistedObjectIdentifer;
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:sender.remoteIdentifier newText:newText];

    // when
    __block ZMClientMessage *newMessage;

    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNotEqualObjects(oldNonce, newMessage.nonce);
    XCTAssertEqualObjects(oldIdentifier, newMessage.nonpersistedObjectIdentifer);
}

@end
