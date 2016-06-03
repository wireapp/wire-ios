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

@import ZMCDataModel;

#import "IntegrationTestBase.h"

@interface AssetUploadAndDownload : IntegrationTestBase
@end



@implementation AssetUploadAndDownload

- (NSArray *)imageMessagesInConversation:(ZMConversation *)conversation {
    NSIndexSet *imageMessageIndexes = [conversation.messages indexesOfObjectsWithOptions:0 passingTest:^BOOL(ZMMessage *msg, NSUInteger idx, BOOL *stop) {
        NOT_USED(idx);
        NOT_USED(stop);
        return [msg isKindOfClass:ZMImageMessage.class];
    }];
    
    return [conversation.messages objectsAtIndexes:imageMessageIndexes];
}

- (void)testThatItReceivesANotificationForAMediumMessageWhenTheDownloadIsRequested
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    // need to fault conversation and messages in order to receive notifications
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    (void) conversation.userDefinedName;
    XCTAssertEqual(conversation.messages.count, 0u);

    // when we insert the medium image
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
        [self.groupConversation insertMediumImageEventFromUser:self.user2 correlationID:[NSUUID createUUID] none:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();

    // then last message is image
    id<ZMConversationMessage> lastMessage = conversation.messages.lastObject;
    XCTAssert(lastMessage.imageMessageData != nil);
    XCTAssertNil(lastMessage.imageMessageData.mediumData);
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:10];

    // when
    MessageWindowChangeObserver *observer = [[MessageWindowChangeObserver alloc] initWithMessageWindow:window];
    [lastMessage requestImageDownload];
    WaitForAllGroupsToBeEmpty(0.5);

    // then we should receive another notification
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    
    MessageWindowChangeInfo *note = observer.notifications.firstObject;
    NSUInteger changedIndex = note.updatedIndexes.firstIndex;
    id<ZMConversationMessage> changedMessage = [window.messages objectAtIndex:changedIndex];
    XCTAssertNotNil(changedMessage.imageMessageData.mediumData);
    XCTAssertEqual(changedMessage.imageMessageData.mediumData.length, (NSUInteger) 317748);
    [observer tearDown];
}

- (void)testThatItReloadsMediumDataIfCacheIsCleared
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    // need to fault conversation and messages in order to receive notifications
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    (void) conversation.userDefinedName;
    XCTAssertEqual(conversation.messages.count, 0u);
    
    // when we insert the medium image
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
        [self.groupConversation insertMediumImageEventFromUser:self.user2 correlationID:[NSUUID createUUID] none:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();
    
    //when cache is cleared
    ZMImageMessage *lastMessage = conversation.messages.lastObject;
    [self.uiMOC.zm_imageAssetCache deleteAssetData:lastMessage.nonce format:ZMImageFormatMedium encrypted:NO];
    XCTAssertNil(lastMessage.mediumData);
    
    // when
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:10];
    MessageWindowChangeObserver *observer = [[MessageWindowChangeObserver alloc] initWithMessageWindow:window];
    [lastMessage requestImageDownload];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then we should receive another notification
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    
    MessageWindowChangeInfo *note = observer.notifications.firstObject;
    NSUInteger changedIndex = note.updatedIndexes.firstIndex;
    id<ZMConversationMessage> changedMessage = [window.messages objectAtIndex:changedIndex];
    XCTAssertNotNil(changedMessage.imageMessageData.mediumData);
    XCTAssertEqual(changedMessage.imageMessageData.mediumData.length, (NSUInteger) 317748);
    [observer tearDown];
}


@end
