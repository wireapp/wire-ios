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
    ZMMessage *message = (id)[conversation appendMessageWithText:oldText];
    message.sender = sender;
    [message markAsSent];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    NSUUID *originalNonce = message.nonce;
    
    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    // when
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.messages.count, 1u);
    
    if (shouldEdit) {
        XCTAssertEqual(conversation.hiddenMessages.count, 1u);
        
        XCTAssertNotNil(newMessage);
        XCTAssertEqualObjects(newMessage.serverTimestamp, message.serverTimestamp);
        XCTAssertEqual(newMessage.visibleInConversation, conversation);
        XCTAssertEqualObjects(newMessage.textMessageData.messageText, newText);
        XCTAssertEqualObjects(newMessage.genericMessage.edited.replacingMessageId, originalNonce.transportString);
        XCTAssertNotEqualObjects(newMessage.nonce, originalNonce);

        XCTAssertEqual(message.hiddenInConversation, conversation);
        XCTAssertNil(message.visibleInConversation);

        XCTAssertEqualObjects(message.textMessageData.messageText, oldText);
    } else {
        XCTAssertEqual(conversation.hiddenMessages.count, 0u);

        XCTAssertNil(newMessage);
        XCTAssertNil(message.hiddenInConversation);
        XCTAssertEqual(message.visibleInConversation, conversation);
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

- (void)testThatItInsertsTheNewMessageAtTheSameIndex
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id)[conversation appendMessageWithText:oldText];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    [message markAsSent];

    // Add some more messages
    [conversation appendMessageWithText:@"Foo"];
    [conversation appendMessageWithText:@"Foo"];
    [conversation appendMessageWithText:@"Foo"];
    
    NSUInteger oldIndex = [conversation.messages indexOfObject:message];
    
    // when
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:YES];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSUInteger newIndex = [conversation.messages indexOfObject:newMessage];
    XCTAssertEqual(newIndex, oldIndex);
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
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(newMessage.linkPreviewState, ZMLinkPreviewStateWaitingToBeProcessed);
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
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:fetchLinkPreview];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(newMessage.linkPreviewState, ZMLinkPreviewStateDone);
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
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:YES];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    XCTAssertNil(newMessage);
    XCTAssertNil(message.hiddenInConversation);
    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqualObjects(message.textMessageData.messageText, oldText);
}

- (void)checkThatItCanNotEditAnImageMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithImageData:self.verySmallJPEGData];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-20];
    [message markAsSent];

    XCTAssertEqual(message.visibleInConversation, conversation);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    // when
    ZMClientMessage *newMessage = (id)[ZMMessage edit:message newText:@"Foo" mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNil(newMessage);
}

- (void)testThatItClearsTheMessageContentAfterSuccessfulUpdate
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
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    ZMMessage *newMessage = [ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);

    // inserting the newMessage updates the lastModifiedDate
    XCTAssertNotEqualObjects(conversation.lastModifiedDate, originalDate);
    NSDate *lastModifiedDate = conversation.lastModifiedDate;
    
    // when
    [newMessage updateWithPostPayload:@{@"time" : updateDate.transportString } updatedKeys:nil];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(newMessage.serverTimestamp, originalDate);
    XCTAssertEqualObjects(newMessage.updatedAt, updateDate);
    XCTAssertEqualObjects(newMessage.textMessageData.messageText, newText);

    XCTAssertEqualObjects(conversation.lastModifiedDate, lastModifiedDate);
    XCTAssertEqualObjects(conversation.lastServerTimeStamp, originalDate);

    XCTAssertEqual(message.hiddenInConversation, conversation);
    XCTAssertNil(message.visibleInConversation);
    XCTAssertNil(message.textMessageData.messageText);

    ZMClientMessage *clientMessage = (ZMClientMessage *)message;
    XCTAssertNil(clientMessage.genericMessage);
    XCTAssertEqual(clientMessage.dataSet.count, 0lu);
    XCTAssertNil(message.textMessageData);
    XCTAssertNotNil(message.sender);
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
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    ZMMessage *newMessage = [ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);

    // inserting the newMessage updates the lastModifiedDate
    XCTAssertNotEqualObjects(conversation.lastModifiedDate, originalDate);
    NSDate *lastModifiedDate = conversation.lastModifiedDate;
    
    // when
    [newMessage expire];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(newMessage.serverTimestamp, originalDate);
    XCTAssertEqualObjects(newMessage.updatedAt, lastModifiedDate);
    XCTAssertEqualObjects(newMessage.textMessageData.messageText, newText);
    XCTAssertEqualObjects(newMessage.nonce, originalNonce);

    XCTAssertEqualObjects(conversation.lastModifiedDate, lastModifiedDate);
    XCTAssertEqualObjects(conversation.lastServerTimeStamp, originalDate);
    
    XCTAssertTrue(message.isZombieObject);
}

- (void)testThatWhenResendingAFailedEditItInsertsANewMessage
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
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(conversation.hiddenMessages.count, 0u);
    
    ZMMessage *newMessage1 = [ZMMessage edit:message newText:newText mentions:@[] fetchLinkPreview:NO];
    WaitForAllGroupsToBeEmpty(0.5);

    // inserting the newMessage updates the lastModifiedDate
    XCTAssertNotEqualObjects(conversation.lastModifiedDate, originalDate);
    NSDate *lastModifiedDate1 = conversation.lastModifiedDate;
    
    [newMessage1 expire];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [newMessage1 resend];
    WaitForAllGroupsToBeEmpty(0.5);

    // inserting the new editMessage updates the lastModifiedDate
    XCTAssertNotEqualObjects(conversation.lastModifiedDate, lastModifiedDate1);
    NSDate *lastModifiedDate2 = conversation.lastModifiedDate;
    
    // then
    ZMClientMessage *newMessage2 = conversation.messages.lastObject;
    
    XCTAssertEqualObjects(newMessage2.serverTimestamp, originalDate);
    XCTAssertEqualObjects(newMessage2.updatedAt, lastModifiedDate2);
    XCTAssertEqualObjects(newMessage2.textMessageData.messageText, newText);
    XCTAssertNotEqualObjects(newMessage2.nonce, newMessage1.nonce);
    XCTAssertEqualObjects(newMessage2.genericMessage.edited.replacingMessageId, originalNonce.transportString);

    XCTAssertEqualObjects(conversation.lastModifiedDate, lastModifiedDate2);
    XCTAssertEqualObjects(conversation.lastServerTimeStamp, originalDate);
    
    XCTAssertTrue(message.isZombieObject);
}

- (ZMUpdateEvent *)createMessageEditUpdateEventWithOldNonce:(NSUUID *)oldNonce newNonce:(NSUUID *)newNonce conversationID:(NSUUID*)conversationID senderID:(NSUUID *)senderID newText:(NSString *)newText
{
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithContent:[ZMMessageEdit editWith:[ZMText textWith:newText mentions:@[] linkPreviews:@[]] replacingMessageId:oldNonce] nonce:newNonce];
    
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
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithContent:[ZMText textWith:@"Yeah!" mentions:@[] linkPreviews:@[]] nonce:nonce];
    
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


- (void)checkThatItHidesOldMessageAndClearsItsContentWithSameSender:(BOOL)sameSender shouldHide:(BOOL)shouldHide
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
        [ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    if (shouldHide) {
        XCTAssertNil(message.textMessageData.messageText);
        XCTAssertEqualObjects(message.nonce, oldNonce);
        XCTAssertNil(message.visibleInConversation);
        XCTAssertEqual(message.hiddenInConversation, conversation);

        ZMClientMessage *clientMessage = (ZMClientMessage *)message;
        XCTAssertNil(clientMessage.genericMessage);
        XCTAssertEqual(clientMessage.dataSet.count, 0lu);
        XCTAssertNil(message.textMessageData);
        XCTAssertNotNil(message.sender);
        
        XCTAssertTrue(message.reactions.isEmpty);
        XCTAssertEqual(conversation.messages.count, 1lu);
        ZMMessage *editedMessage = conversation.messages.firstObject;

        XCTAssertTrue(editedMessage.reactions.isEmpty);
        XCTAssertEqualObjects(editedMessage.textMessageData.messageText, newText);
    } else {
        XCTAssertNotNil(message.textMessageData.messageText);
        XCTAssertEqualObjects(message.nonce, oldNonce);
        XCTAssertEqual(message.visibleInConversation, conversation);
        XCTAssertNil(message.hiddenInConversation);
    }
}

- (void)testThatItHidesOldMessageAndClearsItsContent_SameSender
{
    [self checkThatItHidesOldMessageAndClearsItsContentWithSameSender:YES shouldHide:YES];
}

- (void)testThatItHidesOldMessageAndClearsItsContent_DifferentSender
{
    [self checkThatItHidesOldMessageAndClearsItsContentWithSameSender:NO shouldHide:NO];
}

- (void)checkThatItInsertsANewMessageWithSameSender:(BOOL)sameSender shouldInsert:(BOOL)shouldInsert
{
    // given
    NSString *oldText = @"Hallo";
    NSString *newText = @"Hello";
    NSUUID *senderID = sameSender ? self.selfUser.remoteIdentifier : [NSUUID createUUID];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMMessage *message = (id) [conversation appendMessageWithText:oldText];
    
    ZMUpdateEvent *updateEvent = [self createMessageEditUpdateEventWithOldNonce:message.nonce newNonce:[NSUUID createUUID] conversationID:conversation.remoteIdentifier senderID:senderID newText:newText];
    NSUUID *newNonce = updateEvent.messageNonce;
    
    // when
    __block ZMClientMessage *newMessage;
    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    if (shouldInsert) {
        XCTAssertNotNil(newMessage);
        XCTAssertEqualObjects(newMessage.textMessageData.messageText, newText);
        XCTAssertEqualObjects(newMessage.nonce, newNonce);
        XCTAssertEqual(newMessage.visibleInConversation, conversation);
        XCTAssertNil(newMessage.hiddenInConversation);

        ZMClientMessage *clientMessage = (ZMClientMessage *)message;
        XCTAssertNil(clientMessage.genericMessage);
        XCTAssertEqual(clientMessage.dataSet.count, 0lu);
        XCTAssertNil(message.textMessageData);
        XCTAssertNotNil(message.sender);
    } else {
        XCTAssertNil(newMessage);
    }
}

- (void)testThatItInsertsANewMessage_SameSender
{
    [self checkThatItInsertsANewMessageWithSameSender:YES shouldInsert:YES];
}

- (void)testThatItInsertsANewMessage_DifferentSender
{
    [self checkThatItInsertsANewMessageWithSameSender:NO shouldInsert:NO];
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
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
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
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
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
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
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
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(message.reactions.isEmpty);
    XCTAssertEqual(conversation.messages.count, 1lu);

    ZMMessage *editedMessage = conversation.messages.firstObject;
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
        newMessage = (id)[ZMClientMessage messageUpdateResultFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil].message;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(message.reactions.isEmpty);
    XCTAssertEqual(conversation.messages.count, 1lu);
    
    ZMMessage *editedMessage = conversation.messages.firstObject;
    XCTAssertTrue(editedMessage.reactions.isEmpty);
    XCTAssertEqualObjects(editedMessage.textMessageData.messageText, @"Hello");
}

@end
