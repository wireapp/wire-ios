//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import avs
import Combine
import Foundation
import WireDataModelSupport
import XCTest
@testable import WireSyncEngine

final class WireCallCenterTransportMock: WireCallCenterTransport {
    var mockCallConfigResponse: (String, Int)?
    var mockClientsRequestResponse: [AVSClient]?

    func send(
        data: Data,
        conversationId: AVSIdentifier,
        targets: [AVSClient]?,
        overMLSSelfConversation: Bool,
        completionHandler: @escaping ((Int) -> Void)
    ) {}

    func sendSFT(data: Data, url: URL, completionHandler: @escaping ((Result<Data, Error>) -> Void)) {}

    func requestCallConfig(completionHandler: @escaping CallConfigRequestCompletion) {
        if let mockCallConfigResponse {
            completionHandler(mockCallConfigResponse.0, mockCallConfigResponse.1)
        }
    }

    func requestClientsList(conversationId: AVSIdentifier, completionHandler: @escaping ([AVSClient]) -> Void) {
        if let mockClientsRequestResponse {
            completionHandler(mockClientsRequestResponse)
        }
    }
}

final class WireCallCenterV3Tests: MessagingTest {
    var flowManager: FlowManagerMock!
    var mockAVSWrapper: MockAVSWrapper!
    var sut: WireCallCenterV3!
    var otherUser: ZMUser!
    var otherUserID: AVSIdentifier!
    let otherUserClientID = UUID().transportString()
    var selfUserID: AVSIdentifier!
    var oneOnOneConversation: ZMConversation!
    var groupConversation: ZMConversation!
    var oneOnOneConversationID: AVSIdentifier!
    var groupConversationID: AVSIdentifier!
    var clientID: String!
    var mockTransport: WireCallCenterTransportMock!
    var conferenceCalling: Feature!

    override func setUp() {
        super.setUp()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()
        selfUser.domain = BackendInfo.domain
        selfUserID = selfUser.avsIdentifier

        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.domain = BackendInfo.domain
        self.otherUser = otherUser
        otherUserID = otherUser.avsIdentifier

        let oneOnOneConversation = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOneConversation.remoteIdentifier = UUID.create()
        oneOnOneConversation.conversationType = .oneOnOne
        oneOnOneConversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        oneOnOneConversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        self.oneOnOneConversation = oneOnOneConversation
        oneOnOneConversationID = oneOnOneConversation.avsIdentifier!

        let groupConversation = ZMConversation.insertNewObject(in: uiMOC)
        groupConversation.remoteIdentifier = UUID.create()
        groupConversation.conversationType = .group
        groupConversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConversationID = groupConversation.avsIdentifier!
        self.groupConversation = groupConversation

        clientID = "foo"
        flowManager = FlowManagerMock()
        mockAVSWrapper = MockAVSWrapper(userId: selfUserID, clientId: clientID, observer: nil)
        mockTransport = WireCallCenterTransportMock()
        sut = WireCallCenterV3(
            userId: selfUserID,
            clientId: clientID,
            avsWrapper: mockAVSWrapper,
            uiMOC: uiMOC,
            flowManager: flowManager,
            transport: mockTransport
        )
        // set conferenceCalling feature flag
        conferenceCalling = Feature.fetch(name: .conferenceCalling, context: uiMOC)
        conferenceCalling?.status = .enabled
        sut.usePackagingFeatureConfig = true

        try! uiMOC.save()
    }

    override func tearDown() {
        sut = nil
        flowManager = nil
        clientID = nil
        selfUserID = nil
        otherUser = nil
        oneOnOneConversation = nil
        oneOnOneConversationID = nil
        groupConversation = nil
        groupConversationID = nil
        mockTransport = nil
        mockAVSWrapper = nil
        conferenceCalling = nil

        super.tearDown()
    }

    func checkThatItPostsNotification(
        expectedCallState: CallState,
        expectedCallerId: AVSIdentifier,
        expectedConversationId: AVSIdentifier,
        line: UInt = #line,
        file: StaticString = #file,
        actionBlock: () throws -> Void
    ) rethrows {
        // expect
        customExpectation(
            forNotification: WireCallCenterCallStateNotification.notificationName,
            object: nil
        ) { wrappedNote in
            guard let note = wrappedNote
                .userInfo?[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification
            else { return false }
            XCTAssertEqual(
                note.conversationId,
                expectedConversationId,
                "conversationIds are not the same",
                file: file,
                line: line
            )
            XCTAssertEqual(note.callerId, expectedCallerId, "callerIds are not the same", file: file, line: line)
            XCTAssertEqual(note.callState, expectedCallState, "callStates are not the same", file: file, line: line)

            return true
        }

        // when
        try actionBlock()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTheIncomingCallHandler_WithAMLSGroupResolvesToAConferenceCall() throws {
        // GIVEN
        groupConversation.conversationType = .group
        let avsConversationType: AVSConversationType = .mlsConference

        // WHEN
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: false,
            conversationType: avsConversationType
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // THEN
        let id = try XCTUnwrap(groupConversation.avsIdentifier)
        let callSnapshot = try XCTUnwrap(sut.callSnapshots[id])
        XCTAssertTrue(callSnapshot.conversationType.isConference)
    }

    func testThatTheIncomingCallHandlerPostsTheRightNotification_IsVideo() {
        checkThatItPostsNotification(
            expectedCallState: .incoming(video: true, shouldRing: false, degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleIncomingCall(
                conversationId: oneOnOneConversationID,
                messageTime: Date(),
                client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
                isVideoCall: true,
                shouldRing: false,
                conversationType: .oneToOne
            )
        }
    }

    func testThatTheIncomingCallHandlerPostsTheRightNotification() {
        checkThatItPostsNotification(
            expectedCallState: .incoming(video: false, shouldRing: false, degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleIncomingCall(
                conversationId: oneOnOneConversationID,
                messageTime: Date(),
                client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
                isVideoCall: false,
                shouldRing: false,
                conversationType: .oneToOne
            )
        }
    }

    func testThatTheIncomingCallHandlerPostsTheRightNotification_IsVideo_ShouldRing() {
        checkThatItPostsNotification(
            expectedCallState: .incoming(video: true, shouldRing: true, degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleIncomingCall(
                conversationId: oneOnOneConversationID,
                messageTime: Date(),
                client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
                isVideoCall: true,
                shouldRing: true,
                conversationType: .oneToOne
            )
        }
    }

    func testThatTheIncomingCallHandlerPostsTheRightNotification_ShouldRing() {
        checkThatItPostsNotification(
            expectedCallState: .incoming(video: false, shouldRing: true, degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleIncomingCall(
                conversationId: oneOnOneConversationID,
                messageTime: Date(),
                client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
                isVideoCall: false,
                shouldRing: true,
                conversationType: .oneToOne
            )
        }
    }

    func testThatTheMissedCallHandlerPostANotification() {
        // given
        let conversationId = AVSIdentifier.stub
        let userId = AVSIdentifier.stub
        let isVideo = false
        let timestamp = Date()

        // expect
        customExpectation(
            forNotification: WireCallCenterMissedCallNotification.notificationName,
            object: nil
        ) { wrappedNote in
            guard let note = wrappedNote
                .userInfo?[WireCallCenterMissedCallNotification.userInfoKey] as? WireCallCenterMissedCallNotification
            else { return false }
            XCTAssertEqual(note.conversationId, conversationId)
            XCTAssertEqual(note.callerId, userId)
            XCTAssertEqual(note.timestamp.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 1)
            XCTAssertEqual(note.video, isVideo)
            return true
        }

        // when
        sut.handleMissedCall(conversationId: conversationId, messageTime: timestamp, userId: userId, isVideoCall: false)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTheAnsweredCallHandlerPostsTheRightNotification() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleAnsweredCall(conversationId: oneOnOneConversationID)
        }
    }

    func testThatTheEstablishedHandlerPostsTheRightNotification() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        checkThatItPostsNotification(
            expectedCallState: .established,
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        }
    }

    func testThatTheEstablishedHandlerSetsTheStartTime() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNil(sut.establishedDate)

        // when
        checkThatItPostsNotification(
            expectedCallState: .established,
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        }

        // then
        XCTAssertNotNil(sut.establishedDate)
    }

    func testThatTheEstablishedHandlerDoesntSetTheStartTimeIfCallIsAlreadyEstablished() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNil(sut.establishedDate)

        // call is established
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(sut.establishedDate)
        let previousEstablishedDate = sut.establishedDate
        spinMainQueue(withTimeout: 0.1)

        // when
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.establishedDate, previousEstablishedDate)
    }

    func testThatTheClosedCallHandlerPostsTheRightNotification() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        checkThatItPostsNotification(
            expectedCallState: .terminating(reason: .canceled),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            sut.handleCallEnd(
                reason: .canceled,
                conversationId: oneOnOneConversationID,
                messageTime: Date(),
                userId: otherUserID
            )
        }
    }

    func testThatTheMediaStopppedCallHandlerPostsTheRightNotification() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        checkThatItPostsNotification(
            expectedCallState: .mediaStopped,
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            self.sut.handleMediaStopped(conversationId: oneOnOneConversationID)
        }
    }

    func testThatOtherIncomingCallsAreRejectedWhenWeAnswerCall() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssertNoThrow(try sut.answerCall(conversation: oneOnOneConversation, video: false))

        // then
        XCTAssertTrue(mockAVSWrapper.didCallRejectCall)
    }

    func testThatOtherOutgoingCallsAreCanceledWhenWeAnswerCall() throws {
        // given
        try sut.startCall(in: groupConversation, isVideo: false)

        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssertNoThrow(try sut.answerCall(conversation: oneOnOneConversation, video: false))

        // then
        XCTAssertTrue(mockAVSWrapper.didCallEndCall)
    }

    func testThatOtherIncomingCallsAreRejectedWhenWeStartCall() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try sut.startCall(in: groupConversation, isVideo: false)

        // then
        XCTAssertTrue(mockAVSWrapper.didCallRejectCall)
    }

    func testThatItRejectsACall_Group() {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // expect
        customExpectation(
            forNotification: WireCallCenterCallStateNotification.notificationName,
            object: nil
        ) { wrappedNote in
            guard let note = wrappedNote
                .userInfo?[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification
            else { return false }
            XCTAssertEqual(note.conversationId, self.groupConversationID)
            XCTAssertEqual(note.callerId, self.otherUserID)
            XCTAssertEqual(note.callState, .incoming(video: false, shouldRing: false, degraded: false))
            return true
        }

        // when
        sut.rejectCall(conversationId: oneOnOneConversationID)
        sut.handleCallEnd(
            reason: .stillOngoing,
            conversationId: groupConversationID,
            messageTime: Date(),
            userId: otherUserID
        )

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(mockAVSWrapper.didCallRejectCall)
    }

    func testThatItRejectsACall_1on1() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // expect
        customExpectation(
            forNotification: WireCallCenterCallStateNotification.notificationName,
            object: nil
        ) { wrappedNote in
            guard let note = wrappedNote
                .userInfo?[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification
            else { return false }
            XCTAssertEqual(note.conversationId, self.oneOnOneConversationID)
            XCTAssertEqual(note.callerId, self.otherUserID)
            XCTAssertEqual(note.callState, .incoming(video: false, shouldRing: false, degraded: false))
            return true
        }

        // when
        sut.rejectCall(conversationId: oneOnOneConversationID)
        sut.handleCallEnd(
            reason: .stillOngoing,
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            userId: otherUserID
        )

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(mockAVSWrapper.didCallRejectCall)
    }

    func testThatItAnswersACall_oneToOne() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: oneOnOneConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatLeavingAnMLSConferenceLeavesTheSubconversation() throws {
        // Given
        let conversationID = try XCTUnwrap(groupConversationID)
        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = .random()

        let mlsService = MockMLSServiceInterface()
        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        let didLeaveSubconversation = customExpectation(description: "didLeaveSubconversation")
        mlsService
            .leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod =
            { parentID, parentGroupID, subconversationType in
                XCTAssertEqual(parentID, self.uiMOC.performAndWait { self.groupConversation.qualifiedID })
                XCTAssertEqual(parentGroupID, self.uiMOC.performAndWait { self.groupConversation.mlsGroupID })
                XCTAssertEqual(subconversationType, .conference)
                didLeaveSubconversation.fulfill()
            }

        // When
        sut.closeCall(conversationId: conversationID)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItLeavesSubconversationIfNeededOnIncoming() throws {
        // Given
        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = .random()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfClient = setupSelfClient(inMoc: uiMOC)
        selfClient.user = selfUser
        let selfClientID = try XCTUnwrap(MLSClientID(userClient: selfClient))

        let mlsService = MockMLSServiceInterface()
        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        let didLeaveSubconversationIfNeeded = customExpectation(description: "didLeaveSubconversationIfNeeded")
        mlsService
            .leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod = {
                XCTAssertEqual($0, self.uiMOC.performAndWait { self.groupConversation.qualifiedID })
                XCTAssertEqual($1, self.uiMOC.performAndWait { self.groupConversation.mlsGroupID })
                XCTAssertEqual($2, .conference)
                XCTAssertEqual($3, selfClientID)
                didLeaveSubconversationIfNeeded.fulfill()
            }

        // When
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(
                userId: otherUserID,
                clientId: otherUserClientID
            ),
            isVideoCall: false,
            shouldRing: false,
            conversationType: .mlsConference
        )

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItLeavesSubconversationIfNeededOnTerminating() throws {
        // Given
        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = .random()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfClient = setupSelfClient(inMoc: uiMOC)
        selfClient.user = selfUser
        let selfClientID = try XCTUnwrap(MLSClientID(userClient: selfClient))

        let mlsService = MockMLSServiceInterface()
        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        let didLeaveSubconversationIfNeeded = customExpectation(description: "didLeaveSubconversationIfNeeded")
        mlsService
            .leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod = {
                XCTAssertEqual($0, self.uiMOC.performAndWait { self.groupConversation.qualifiedID })
                XCTAssertEqual($1, self.uiMOC.performAndWait { self.groupConversation.mlsGroupID })
                XCTAssertEqual($2, .conference)
                XCTAssertEqual($3, selfClientID)
                didLeaveSubconversationIfNeeded.fulfill()
            }

        // When
        sut.handleCallEnd(
            reason: .normal,
            conversationId: groupConversationID,
            messageTime: nil,
            userId: otherUserID
        )

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItLeavesSubconversationIfNeededOnMissed() throws {
        // Given
        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = .random()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfClient = setupSelfClient(inMoc: uiMOC)
        selfClient.user = selfUser
        let selfClientID = try XCTUnwrap(MLSClientID(userClient: selfClient))

        let mlsService = MockMLSServiceInterface()
        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        let didLeaveSubconversationIfNeeded = customExpectation(description: "didLeaveSubconversationIfNeeded")
        mlsService
            .leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod = {
                XCTAssertEqual($0, self.uiMOC.performAndWait { self.groupConversation.qualifiedID })
                XCTAssertEqual($1, self.uiMOC.performAndWait { self.groupConversation.mlsGroupID })
                XCTAssertEqual($2, .conference)
                XCTAssertEqual($3, selfClientID)
                didLeaveSubconversationIfNeeded.fulfill()
            }

        // When
        sut.handleMissedCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            userId: otherUserID,
            isVideoCall: false
        )

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItAnswersACall_oneToOne_normal() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: oneOnOneConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
            XCTAssertNil(mockAVSWrapper.setVideoStateArguments)
        }
    }

    /// No call to `setUpMLSConference` must be made.
    /// `syncMOC.mlsService` is set to `nil` so that any call would fail.
    func testThatItAnswersACall_oneToOne_mls() throws {
        // given
        oneOnOneConversation.messageProtocol = .mls
        oneOnOneConversation.mlsGroupID = .random()
        syncMOC.performAndWait { syncMOC.mlsService = nil }
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: oneOnOneConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
            XCTAssertNil(mockAVSWrapper.setVideoStateArguments)
        }
    }

    func testThatItAnswersACall_oneToOne_video() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: oneOnOneConversation, video: true)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.video)
            XCTAssertNil(mockAVSWrapper.setVideoStateArguments)
        }
    }

    func testThatItAnswersACall_legacy_largeGroup_audioOnly() throws {
        // given
        // Make sure group conversation has at least 5 participants (including self)
        for _ in 0 ..< 4 {
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = UUID()
            groupConversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        }

        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.audioOnly)
        }
    }

    func testThatItAnswersACall_legacy_smallGroup_normal() throws {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatItAnswersACall_legacy_smallGroup_video() throws {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: true)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.video)
        }
    }

    func testThatItAnswersACall_conference_normal() throws {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .conference
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatItAnswersACall_conference_mls() throws {
        // TODO: [WPB-7346]: enable this (flaky) test again
        throw XCTSkip()

        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .mlsConference
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try assertMLSConference(
            expectedCallState: .answered(degraded: false),
            expectedCallerID: otherUserID,
            expectedConversationID: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: false)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatItAnswersACall_conference_video() throws {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: true,
            shouldRing: true,
            conversationType: .conference
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try checkThatItPostsNotification(
            expectedCallState: .answered(degraded: false),
            expectedCallerId: otherUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            _ = try sut.answerCall(conversation: groupConversation, video: true)

            // then
            XCTAssertEqual(mockAVSWrapper.answerCallArguments?.callType, AVSCallType.video)
        }
    }

    func testThatItStartsACall_oneToOne_normal() throws {
        // given
        try checkThatItPostsNotification(
            expectedCallState: .outgoing(degraded: false),
            expectedCallerId: selfUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            try sut.startCall(in: oneOnOneConversation, isVideo: false)

            // then
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.oneToOne)
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.normal)
        }
    }

    /// No call to `setUpMLSConference` must be made.
    /// `syncMOC.mlsService` is set to `nil` so that any call would fail.
    func testThatItStartsACall_oneToOne_mls() throws {
        // given
        oneOnOneConversation.messageProtocol = .mls
        oneOnOneConversation.mlsGroupID = .random()
        syncMOC.performAndWait { syncMOC.mlsService = nil }
        try checkThatItPostsNotification(
            expectedCallState: .outgoing(degraded: false),
            expectedCallerId: selfUserID,
            expectedConversationId: oneOnOneConversationID
        ) {
            // when
            try sut.startCall(in: oneOnOneConversation, isVideo: false)

            // then
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.oneToOne)
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatItStartsACall_conference_normal() throws {
        // given
        try checkThatItPostsNotification(
            expectedCallState: .outgoing(degraded: false),
            expectedCallerId: selfUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            try sut.startCall(in: groupConversation, isVideo: false)

            // then
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.conference)
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.normal)
        }
    }

    func testThatItStartsACall_conference_mls() throws {
        // TODO: [WPB-7346]: enable this (flaky) test again
        throw XCTSkip()

        try assertMLSConference(
            expectedCallState: .outgoing(degraded: false),
            expectedCallerID: selfUserID,
            expectedConversationID: groupConversationID
        ) {
            // when
            try sut.startCall(in: groupConversation, isVideo: false)

            // then
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.mlsConference)
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.normal)
        }
    }

    func assertMLSConference(
        expectedCallState: CallState,
        expectedCallerID: AVSIdentifier,
        expectedConversationID: AVSIdentifier,
        when block: () throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        // given
        let parentGroupID = MLSGroupID(Data.random())
        let subconversationGroupID = MLSGroupID(Data.random())
        let conferenceInfo1 = MLSConferenceInfo.random()
        let conferenceInfo2 = MLSConferenceInfo.random()

        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = parentGroupID

        let mlsService = MockMLSServiceInterface()

        let didJoinSubgroup = customExpectation(description: "didJoinSubgroup")
        mlsService.createOrJoinSubgroupParentQualifiedIDParentID_MockMethod = {
            defer { didJoinSubgroup.fulfill() }
            XCTAssertEqual(
                $0,
                self.uiMOC.performAndWait { self.groupConversation.qualifiedID },
                "[0] groupConversation.qualifiedID doesn't match",
                file: file,
                line: line
            )
            XCTAssertEqual($1, parentGroupID, "[1] parentGroupID doesn't match", file: file, line: line)
            return subconversationGroupID
        }

        let didGenerateConferenceInfo1 = customExpectation(description: "didGenerateConferenceInfo1")
        mlsService.generateConferenceInfoParentGroupIDSubconversationGroupID_MockMethod = {
            XCTAssertEqual($0, parentGroupID, "[2] parentGroupID doesn't match", file: file, line: line)
            XCTAssertEqual(
                $1,
                subconversationGroupID,
                "[3] subconversationGroupID doesn't match",
                file: file,
                line: line
            )
            defer { didGenerateConferenceInfo1.fulfill() }
            return conferenceInfo1
        }

        let didSetConferenceInfo1 = customExpectation(description: "didSetConferenceInfo1")
        mockAVSWrapper.mockSetMLSConferenceInfo = {
            XCTAssertEqual(
                $0,
                self.uiMOC.performAndWait { self.groupConversation.avsIdentifier },
                "[4] avsIdentifier doesn't match",
                file: file,
                line: line
            )
            XCTAssertEqual($1, conferenceInfo1, "[5] converenceInfo1 doesn't match", file: file, line: line)
            didSetConferenceInfo1.fulfill()
        }

        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        // So we can inform of new conference infos
        let conferenceInfoChangeSubject = PassthroughSubject<MLSConferenceInfo, Never>()
        mlsService.onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockMethod = { _, _ in
            var iterator = conferenceInfoChangeSubject.values.makeAsyncIterator()
            return AsyncThrowingStream {
                await iterator.next()
            }
        }

        try checkThatItPostsNotification(
            expectedCallState: expectedCallState,
            expectedCallerId: expectedCallerID,
            expectedConversationId: expectedConversationID
        ) {
            // when
            try block()
        }

        XCTAssert(
            waitForCustomExpectations(withTimeout: 0.5),
            "[6] waitForCustomExpectations failed",
            file: file,
            line: line
        )
        XCTAssert(
            waitForAllGroupsToBeEmpty(withTimeout: 0.5),
            "[7] waitForAllGroupsToBeEmpty failed",
            file: file,
            line: line
        )

        let didSetConferenceInfo2 = customExpectation(description: "didSetConferenceInfo2")
        mockAVSWrapper.mockSetMLSConferenceInfo = {
            XCTAssertEqual(
                $0,
                self.uiMOC.performAndWait { self.groupConversation.avsIdentifier },
                "[8] avsIdentifier doesn't match",
                file: file,
                line: line
            )
            XCTAssertEqual($1, conferenceInfo2, "[9] conferenceInfo2 doesn't match", file: file, line: line)
            didSetConferenceInfo2.fulfill()
        }

        // and when the conference info changes
        conferenceInfoChangeSubject.send(conferenceInfo2)

        XCTAssert(
            waitForAllGroupsToBeEmpty(withTimeout: 0.5),
            "[A] waitForCustomExpectations failed",
            file: file,
            line: line
        )

        // then we set conference info 2 to avs (see expectations)
        XCTAssert(
            waitForCustomExpectations(withTimeout: 0.5),
            "[B] waitForCustomExpectations failed",
            file: file,
            line: line
        )
    }

    func testThatItDoesNotStartAConferenceCall_IfConferenceCallingFeatureStatusIsDisabled() throws {
        // given
        conferenceCalling.status = .disabled

        // expect
        customExpectation(
            forNotification: WireCallCenterConferenceCallingUnavailableNotification.notificationName,
            object: nil
        )

        // when
        assertItThrows(error: WireCallCenterV3.Failure.missingConferencingPermission) {
            try sut.startCall(in: groupConversation, isVideo: false)
        }

        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // then
        XCTAssertNil(mockAVSWrapper.startCallArguments)
    }

    func testThatItStartsAConferenceCall_IfPackagingFeatureIsDisabledByInternalFlag() throws {
        // given
        sut.usePackagingFeatureConfig = false
        conferenceCalling.status = .disabled

        // when
        try sut.startCall(in: groupConversation, isVideo: false)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.conference)
        XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.normal)
    }

    func testThatItStartsACall_conference_video() throws {
        // given
        try checkThatItPostsNotification(
            expectedCallState: .outgoing(degraded: false),
            expectedCallerId: selfUserID,
            expectedConversationId: groupConversationID
        ) {
            // when
            try sut.startCall(in: groupConversation, isVideo: true)

            // then
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.conversationType, AVSConversationType.conference)
            XCTAssertEqual(mockAVSWrapper.startCallArguments?.callType, AVSCallType.video)
        }
    }

    func testThatItSetsTheCallStartTimeBeforePostingTheNotification() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNil(sut.establishedDate)

        // expect
        customExpectation(forNotification: WireCallCenterCallStateNotification.notificationName, object: nil) { _ in
            XCTAssertNotNil(self.sut.establishedDate)
            return true
        }

        // when
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItBuffersEventsUntilAVSIsReady() {
        // given
        let userId = AVSIdentifier.stub
        let clientId = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userId,
            clientId: clientId
        )

        // when
        sut.processCallEvent(callEvent, completionHandler: {})
        XCTAssertEqual((sut.avsWrapper as! MockAVSWrapper).receivedCallEvents.count, 0)

        // and when
        sut.setCallReady(version: 3)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual((sut.avsWrapper as! MockAVSWrapper).receivedCallEvents.count, 1)
        if let (event, conversationType) = (sut.avsWrapper as! MockAVSWrapper).receivedCallEvents.last {
            XCTAssertEqual(event.conversationId, oneOnOneConversationID)
            XCTAssertEqual(event.userId, userId)
            XCTAssertEqual(event.clientId, clientId)
            XCTAssertEqual(event.data, data)
            XCTAssertEqual(conversationType, .oneToOne)
        }
    }

    func testThatProcessCallEventIsContextSafe() {
        // given
        let userID = AVSIdentifier.stub
        let clientID = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userID,
            clientId: clientID
        )

        sut.setCallReady(version: 3)

        // expect
        let calledCompletionHandler = customExpectation(description: "processCallEvent completion handler called")

        // when
        syncMOC.performAndWait {
            sut.processCallEvent(callEvent) {
                calledCompletionHandler.fulfill()
            }
        }

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallProcessCallEventCompletionHandler() {
        // given
        let userId = AVSIdentifier.stub
        let clientId = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userId,
            clientId: clientId
        )
        sut.setCallReady(version: 3)

        // expect
        let calledCompletionHandler = customExpectation(description: "processCallEvent completion handler called")

        // when
        sut.processCallEvent(callEvent, completionHandler: {
            calledCompletionHandler.fulfill()
        })

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallProcessCallEventCompletionHandlerWhenEmptyingBuffer() {
        // given
        let userId = AVSIdentifier.stub
        let clientId = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userId,
            clientId: clientId
        )

        // expect
        let calledCompletionHandler = customExpectation(description: "processCallEvent completion handler called")

        // when
        sut.processCallEvent(callEvent, completionHandler: {
            calledCompletionHandler.fulfill()
        })
        XCTAssertEqual((sut.avsWrapper as! MockAVSWrapper).receivedCallEvents.count, 0)

        // and when
        sut.setCallReady(version: 2)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTheReceivedCallHandlerPostsTheRightNotification_WithErrorUnknownProtocol() {
        let userId = AVSIdentifier.stub
        let clientId = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userId,
            clientId: clientId
        )
        sut.setCallReady(version: 3)

        // expect
        let calledCompletionHandler = customExpectation(description: "processCallEvent completion handler called")

        customExpectation(
            forNotification: WireCallCenterCallErrorNotification.notificationName,
            object: nil
        ) { wrappedNote in
            guard let note = wrappedNote
                .userInfo?[WireCallCenterCallErrorNotification.userInfoKey] as? WireCallCenterCallErrorNotification
            else { return false }
            XCTAssertEqual(note.error, self.mockAVSWrapper.callError)
            XCTAssertEqual(note.conversationId, self.oneOnOneConversationID)
            return true
        }

        // when

        mockAVSWrapper.callError = .unknownProtocol

        sut.processCallEvent(callEvent, completionHandler: {
            calledCompletionHandler.fulfill()
        })
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTheReceivedCallHandlerDoesntPostNotifications_WithNoError() {
        let userId = AVSIdentifier.stub
        let clientId = "foo"
        let data = verySmallJPEGData()
        let callEvent = CallEvent(
            data: data,
            currentTimestamp: Date(),
            serverTimestamp: Date(),
            conversationId: oneOnOneConversationID,
            userId: userId,
            clientId: clientId
        )
        sut.setCallReady(version: 3)

        // expect
        let calledCompletionHandler = customExpectation(description: "processCallEvent completion handler called")

        // when
        sut.processCallEvent(callEvent, completionHandler: {
            calledCompletionHandler.fulfill()
        })

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatActiveCallsOnlyIncludeExpectedCallStates() {
        // given
        let callStarter = AVSIdentifier.stub
        let activeCallStates: [CallState] = [
            CallState.established,
            CallState.establishedDataChannel,
        ]

        let nonActiveCallStates: [CallState] = [
            CallState.incoming(video: false, shouldRing: false, degraded: false),
            CallState.outgoing(degraded: false),
            CallState.answered(degraded: false),
            CallState.terminating(reason: CallClosedReason.normal),
            CallState.none,
            CallState.unknown,
        ]

        // then
        for callState in nonActiveCallStates {
            sut.createSnapshot(
                callState: callState,
                members: [],
                callStarter: callStarter,
                video: false,
                for: groupConversation.avsIdentifier!,
                conversationType: .oneToOne
            )
            XCTAssertEqual(sut.activeCalls.count, 0)
        }

        for callState in activeCallStates {
            sut.createSnapshot(
                callState: callState,
                members: [],
                callStarter: callStarter,
                video: false,
                for: groupConversation.avsIdentifier!,
                conversationType: .oneToOne
            )
            XCTAssertEqual(sut.activeCalls.count, 1)
        }
    }

    func testThatItMutesMicrophone_WhenHandlingIncomingGroupCall() {
        // given
        let conversationID = AVSIdentifier.stub
        let incomingState = CallState.incoming(video: false, shouldRing: true, degraded: false)
        let incomingCall = CallSnapshotTestFixture.callSnapshot(
            conversationId: conversationID,
            callCenter: sut,
            clients: [],
            state: incomingState
        )
        sut.callSnapshots = [conversationID: incomingCall]
        sut.isMuted = false

        // when
        sut.handle(callState: incomingState, conversationId: conversationID)

        // then
        XCTAssertTrue(sut.isMuted)
    }

    func testThatItDoesntMuteMicrophone_WhenHandlingIncomingGroupCall_WhileAlreadyInACall() {
        // given
        let activeCallConversationId = AVSIdentifier.stub
        let activeCall = CallSnapshotTestFixture.callSnapshot(
            conversationId: activeCallConversationId,
            callCenter: sut,
            clients: [],
            state: .established
        )

        let incomingCallConversationId = AVSIdentifier.stub
        let incomingState = CallState.incoming(video: false, shouldRing: true, degraded: false)
        let incomingCall = CallSnapshotTestFixture.callSnapshot(
            conversationId: incomingCallConversationId,
            callCenter: sut,
            clients: [],
            state: incomingState
        )

        sut.callSnapshots = [
            activeCallConversationId: activeCall,
            incomingCallConversationId: incomingCall,
        ]
        sut.isMuted = false

        // when
        sut.handle(callState: incomingState, conversationId: incomingCallConversationId)

        // then
        XCTAssertFalse(sut.isMuted)
    }

    // MARK: - CBR

    func testThatCBRIsEnabledOnAudioCBRChangeHandler_whenCallIsEstablished() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.handleConstantBitRateChange(enabled: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isContantBitRate(conversationId: oneOnOneConversationID))
    }

    func testThatCBRIsEnabledOnAudioCBRChangeHandler_whenDataChannelIsEstablished() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleDataChannelEstablishement(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.handleConstantBitRateChange(enabled: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isContantBitRate(conversationId: oneOnOneConversationID))
    }

    func testThatCBRIsDisabledOnAudioCBRChangeHandler() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        sut.handleConstantBitRateChange(enabled: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isContantBitRate(conversationId: oneOnOneConversationID))

        // when
        sut.handleConstantBitRateChange(enabled: false)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isContantBitRate(conversationId: oneOnOneConversationID))
    }

    func testThatCBRIsNotEnabledOnAudioCBRChangeHandlerWhenCallIsNotEstablished() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.handleConstantBitRateChange(enabled: false)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isContantBitRate(conversationId: oneOnOneConversationID))
    }

    func testThatCBRIsNotEnabledAfterCallIsTerminated() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        sut.handleConstantBitRateChange(enabled: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.handleCallEnd(
            reason: .normal,
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            userId: otherUserID
        )
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isContantBitRate(conversationId: oneOnOneConversationID))
    }

    // MARK: - Network quality

    func testThatNetworkQualityIsNormalInitially() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.networkQuality(conversationId: oneOnOneConversationID), .normal)
    }

    func testThatNetworkQualityHandlerUpdatesTheQuality() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let quality = NetworkQuality.poor

        // when
        sut.handleNetworkQualityChange(
            conversationId: oneOnOneConversationID,
            userId: otherUserID.identifier.transportString(),
            clientId: otherUserClientID,
            quality: quality
        )
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.networkQuality(conversationId: oneOnOneConversationID), quality)
    }
}

// MARK: - Muted state

extension WireCallCenterV3Tests {
    func testThatMutedStateHandlerUpdatesTheState() {
        class MuteObserver: MuteStateObserver {
            var muted: Bool?
            func callCenterDidChange(muted: Bool) { self.muted = muted }
        }

        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.handleEstablishedCall(conversationId: oneOnOneConversationID)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let observer = MuteObserver()
        let token = WireCallCenterV3.addMuteStateObserver(observer: observer, context: uiMOC)

        // when
        mockAVSWrapper.isMuted = true
        sut.handleMuteChange(muted: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        withExtendedLifetime(token) {
            XCTAssertEqual(true, observer.muted)
        }
    }

    func testThat_ItMutesUser_When_AnsweringCall_InGroupConversation() throws {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .conference
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssertNoThrow(try sut.answerCall(conversation: groupConversation, video: false))

        // then
        XCTAssertTrue(sut.isMuted)
    }

    func testThat_ItDoesntMuteUser_When_AnsweringCall_InOneToOneConversation() throws {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssertNoThrow(try sut.answerCall(conversation: oneOnOneConversation, video: false))

        // then
        XCTAssertFalse(sut.isMuted)
    }

    // MARK: - Ignoring Calls

    func testThatItWhenIgnoringACallItWillSetsTheCallStateToIncomingInactive() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.rejectCall(conversationId: oneOnOneConversationID)

        // then
        XCTAssertEqual(
            sut.callState(conversationId: oneOnOneConversationID),
            .incoming(video: false, shouldRing: false, degraded: false)
        )
    }

    func testThatItWhenRejectingAOneOnOneCallItWilltSetTheCallStateToIncomingInactive() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.rejectCall(conversationId: oneOnOneConversationID)

        // then
        XCTAssertEqual(
            sut.callState(conversationId: oneOnOneConversationID),
            .incoming(video: false, shouldRing: false, degraded: false)
        )
    }

    func testThatItWhenClosingAGroupCallItWillSetsTheCallStateToIncomingInactive() {
        // given
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.closeCall(conversationId: groupConversationID)

        // then
        XCTAssertEqual(
            sut.callState(conversationId: groupConversationID),
            .incoming(video: false, shouldRing: false, degraded: false)
        )
    }

    func testThatItWhenClosingAOneOnOneCallItDoesNotSetTheCallStateToIncomingInactive() {
        // given
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sut.closeCall(conversationId: oneOnOneConversationID)

        // then
        XCTAssertNotEqual(
            sut.callState(conversationId: oneOnOneConversationID),
            .incoming(video: false, shouldRing: false, degraded: false)
        )
    }

    // MARK: - Participants

    func testThatItCreatesAParticipantSnapshotForAnIncomingCall() {
        // when
        sut.handleIncomingCall(
            conversationId: oneOnOneConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .oneToOne
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let actual = sut.callParticipants(conversationId: oneOnOneConversationID, kind: .all)
        let expected = [CallParticipant(
            user: otherUser,
            clientId: otherUserClientID,
            state: .connecting,
            activeSpeakerState: .inactive
        )]
        XCTAssertEqual(actual, expected)
    }

    func callBackMemberHandler(
        conversationId: AVSIdentifier,
        userId: AVSIdentifier,
        clientId: String,
        audioEstablished: Bool
    ) {
        let audioState = audioEstablished ? AudioState.established : .connecting
        let videoState = VideoState.stopped
        let microphoneState = MicrophoneState.unmuted
        let member = AVSParticipantsChange.Member(
            userid: userId.serialized,
            clientid: clientId,
            aestab: audioState,
            vrecv: videoState,
            muted: microphoneState
        )
        let change = AVSParticipantsChange(convid: conversationId.serialized, members: [member])

        let encoded = try! JSONEncoder().encode(change)
        let string = String(decoding: encoded, as: UTF8.self)

        sut.handleParticipantChange(conversationId: conversationId, data: string)
    }

    func testThatItDoesNotIgnore_WhenGroupHandlerIsCalledForOneToOne() throws {
        // when
        try sut.startCall(in: oneOnOneConversation, isVideo: false)
        callBackMemberHandler(
            conversationId: oneOnOneConversationID,
            userId: otherUserID,
            clientId: otherUserClientID,
            audioEstablished: false
        )
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let actual = sut.callParticipants(conversationId: oneOnOneConversationID, kind: .all)
        let expected = [CallParticipant(
            user: otherUser,
            clientId: otherUserClientID,
            state: .connecting,
            activeSpeakerState: .inactive
        )]
        XCTAssertEqual(actual, expected)
    }

    func testThatItUpdatesTheParticipantsWhenGroupHandlerIsCalled() throws {
        // when
        try sut.startCall(in: groupConversation, isVideo: false)
        callBackMemberHandler(
            conversationId: groupConversationID,
            userId: otherUserID,
            clientId: otherUserClientID,
            audioEstablished: false
        )
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let actual = sut.callParticipants(conversationId: groupConversationID, kind: .all)
        let expected = [CallParticipant(
            user: otherUser,
            clientId: otherUserClientID,
            state: .connecting,
            activeSpeakerState: .inactive
        )]
        XCTAssertEqual(actual, expected)
    }

    func testThatItUpdatesTheStateForParticipant() {
        // when
        sut.handleIncomingCall(
            conversationId: groupConversationID,
            messageTime: Date(),
            client: AVSClient(userId: otherUserID, clientId: otherUserClientID),
            isVideoCall: false,
            shouldRing: true,
            conversationType: .group
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        var actual = sut.callParticipants(conversationId: groupConversationID, kind: .all)
        var expected = [CallParticipant(
            user: otherUser,
            clientId: otherUserClientID,
            state: .connecting,
            activeSpeakerState: .inactive
        )]
        XCTAssertEqual(actual, expected)

        // when
        callBackMemberHandler(
            conversationId: groupConversationID,
            userId: otherUserID,
            clientId: otherUserClientID,
            audioEstablished: true
        )
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        actual = sut.callParticipants(conversationId: groupConversationID, kind: .all)
        expected = [CallParticipant(
            user: otherUser,
            clientId: otherUserClientID,
            state: .connected(videoState: .stopped, microphoneState: .unmuted),
            activeSpeakerState: .inactive
        )]
        XCTAssertEqual(actual, expected)
    }

    // MARK: - Call Config

    func testThatCallConfigRequestsAreForwaredToTransportAndAVS() {
        // given
        mockTransport.mockCallConfigResponse = ("call_config", 200)

        // when
        sut.handleCallConfigRefreshRequest()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockAVSWrapper.didUpdateCallConfig)
    }

    // MARK: - Clients Request Handler

    func testThatClientsRequestHandlerSuccessfullyReturnsClientList() {
        // given
        let userId1 = AVSIdentifier.stub
        let userId2 = AVSIdentifier.stub

        mockTransport.mockClientsRequestResponse = [
            AVSClient(userId: userId1, clientId: "client1"),
            AVSClient(userId: userId1, clientId: "client2"),
            AVSClient(userId: userId2, clientId: "client1"),
            AVSClient(userId: userId2, clientId: "client2"),
        ]

        // when
        sut.handleClientsRequest(conversationId: groupConversation.avsIdentifier!) { json in
            do {
                // then
                let data = json.data(using: .utf8)!
                let clientList = try JSONDecoder().decode(WireSyncEngine.AVSClientList.self, from: data)

                let actual = Set(clientList.clients)
                let expected: Set<AVSClient> = [
                    AVSClient(userId: userId1, clientId: "client1"),
                    AVSClient(userId: userId1, clientId: "client2"),
                    AVSClient(userId: userId2, clientId: "client1"),
                    AVSClient(userId: userId2, clientId: "client2"),
                ]

                XCTAssertEqual(actual, expected)
            } catch {
                XCTFail()
            }
        }
    }

    private func createClients(for user: ZMUser, ids: String...) -> [UserClient] {
        ids.map {
            let client = UserClient.insertNewObject(in: self.uiMOC)
            client.remoteIdentifier = $0
            client.user = user
            return client
        }
    }

    // MARK: - Call Degradation

    func testThatCallDidDegradeEndsCall() {
        // When
        sut.callDidDegrade(
            conversationId: AVSIdentifier.stub,
            degradedUser: ZMUser.insertNewObject(in: uiMOC)
        )

        // Then
        XCTAssertTrue(mockAVSWrapper.didCallEndCall)
    }

    func testThatCallDidDegradeUpdatesDegradedUser() {
        // Given
        let conversationId = groupConversation.avsIdentifier!

        sut.callSnapshots = [
            conversationId: CallSnapshotTestFixture.degradedCallSnapshot(
                conversationId: conversationId,
                user: otherUser,
                callCenter: sut
            ),
        ]

        // When
        sut.callDidDegrade(conversationId: conversationId, degradedUser: otherUser)

        // Then
        XCTAssertTrue(sut.callSnapshots[conversationId]?.isDegradedCall ?? false)
    }
}

// MARK: - Active Speakers

extension WireCallCenterV3Tests {
    private enum ActiveSpeakerKind {
        case smoothed
        case realTime
    }

    private typealias ActiveSpeaker = AVSActiveSpeakersChange.ActiveSpeaker

    private func activeSpeakersChange(
        for conversationId: AVSIdentifier,
        clients: [AVSClient],
        activeSpeakerKind kind: ActiveSpeakerKind = .realTime
    ) -> AVSActiveSpeakersChange {
        var activeSpeakers = [ActiveSpeaker]()

        for client in clients {
            activeSpeakers += [ActiveSpeaker(
                userId: client.userId,
                clientId: client.clientId,
                audioLevel: kind == .smoothed ? 100 : 0,
                audioLevelNow: kind == .realTime ? 100 : 0
            )]
        }

        return AVSActiveSpeakersChange(activeSpeakers: activeSpeakers)
    }

    private func callSnapshot(conversationId: AVSIdentifier, clients: [AVSClient]) -> [AVSIdentifier: CallSnapshot] {
        [
            conversationId: CallSnapshotTestFixture.callSnapshot(
                conversationId: conversationId,
                callCenter: sut,
                clients: clients
            ),
        ]
    }

    func test_HandleActiveSpeakersChange_UpdatesActiveSpeakers() throws {
        // GIVEN
        let conversationId = try XCTUnwrap(groupConversationID)
        let client = AVSClient.mockClient

        sut.callSnapshots = callSnapshot(conversationId: conversationId, clients: [client])
        let change = activeSpeakersChange(for: conversationId, clients: [client])
        let activeSpeaker = try XCTUnwrap(change.activeSpeakers.first)

        // WHEN
        sut.handleActiveSpeakersChange(conversationId: conversationId, data: change.data)

        // THEN
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let callSnapshot = try XCTUnwrap(sut.callSnapshots[conversationId])
        XCTAssertEqual(callSnapshot.activeSpeakers.first, activeSpeaker)
    }

    func test_HandleActiveSpeakersChange_PostsNotification_WhenActiveSpeakersChange_IsRelevant() throws {
        // GIVEN
        let conversationId = try XCTUnwrap(groupConversationID)

        // We have one client in the call
        let client = AVSClient.mockClient

        // We set the speaker levels
        let speaker = ActiveSpeaker(
            userId: client.userId,
            clientId: client.clientId,
            audioLevel: 0,
            audioLevelNow: 0
        )

        // We create the call snapshot
        let callSnapshot = CallSnapshotTestFixture.callSnapshot(
            conversationId: conversationId,
            callCenter: sut,
            clients: [client],
            activeSpeakers: [speaker]
        )

        sut.callSnapshots = [conversationId: callSnapshot]

        // We prepare the change of active speaker.
        // They're not relevant if the audio level stays > 0
        let newSpeaker = ActiveSpeaker(
            userId: client.userId,
            clientId: client.clientId,
            audioLevel: 0,
            audioLevelNow: 24
        )

        let change = AVSActiveSpeakersChange(activeSpeakers: [newSpeaker])

        // We set the expectation for notifications.
        // We expect a notification to be sent since there has been a relevant change in active speakers.
        let expectation = XCTNSNotificationExpectation(name: WireCallCenterActiveSpeakersNotification.notificationName)

        // WHEN
        sut.handleActiveSpeakersChange(conversationId: conversationId, data: change.data)

        // THEN
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        wait(for: [expectation], timeout: 0.5)
    }

    func test_HandleActiveSpeakersChange_DoesntPostNotification_WhenActiveSpeakersChange_IsNotRelevant() throws {
        // GIVEN
        let conversationId = try XCTUnwrap(groupConversationID)

        // We have three clients in the call
        let clientOne = AVSClient.mockClient
        let clientTwo = AVSClient.mockClient
        let clientThree = AVSClient.mockClient

        // We set the speaker levels for each client
        let speakerOne = ActiveSpeaker(
            userId: clientOne.userId,
            clientId: clientOne.clientId,
            audioLevel: 0,
            audioLevelNow: 0
        )

        let speakerTwo = ActiveSpeaker(
            userId: clientTwo.userId,
            clientId: clientTwo.clientId,
            audioLevel: 0,
            audioLevelNow: 99
        )

        let speakerThree = ActiveSpeaker(
            userId: clientThree.userId,
            clientId: clientThree.clientId,
            audioLevel: 0,
            audioLevelNow: 38
        )

        // We create the call snapshot
        let callSnapshot = CallSnapshotTestFixture.callSnapshot(
            conversationId: conversationId,
            callCenter: sut,
            clients: [clientOne, clientTwo, clientThree],
            activeSpeakers: [speakerOne, speakerTwo, speakerThree]
        )

        sut.callSnapshots = [conversationId: callSnapshot]

        // We prepare the change of active speakers.
        // They're not relevant if the audio level stays >0
        let newSpeakerTwo = ActiveSpeaker(
            userId: clientTwo.userId,
            clientId: clientTwo.clientId,
            audioLevel: 0,
            audioLevelNow: 24
        )

        let newSpeakerThree = ActiveSpeaker(
            userId: clientThree.userId,
            clientId: clientThree.clientId,
            audioLevel: 0,
            audioLevelNow: 87
        )

        let change = AVSActiveSpeakersChange(activeSpeakers: [speakerOne, newSpeakerTwo, newSpeakerThree])

        // We set a notification expectation
        let expectation = XCTNSNotificationExpectation(name: WireCallCenterActiveSpeakersNotification.notificationName)
        // We expect to NOT receive any notification since there has been no significant change in active speakers
        // So we set the expectation as inverted
        expectation.isInverted = true

        // WHEN
        sut.handleActiveSpeakersChange(conversationId: conversationId, data: change.data)

        // THEN
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        wait(for: [expectation], timeout: 0.5)
    }

    typealias CallParticipantsTestsAssertion = ([CallParticipant], Int) -> Void

    private func testCallParticipants(
        activeSpeakerKind: ActiveSpeakerKind,
        participantsKind: CallParticipantsListKind,
        limit: Int? = nil,
        assertionBlock: CallParticipantsTestsAssertion?
    ) {
        // GIVEN
        let conversationId = groupConversationID!
        let clients = [
            AVSClient(userId: selfUserID, clientId: UUID().transportString()),
            AVSClient(userId: otherUserID, clientId: UUID().transportString()),
        ]

        sut.callSnapshots = callSnapshot(conversationId: conversationId, clients: clients)
        let data = activeSpeakersChange(for: conversationId, clients: clients, activeSpeakerKind: activeSpeakerKind)
            .data

        sut.handleActiveSpeakersChange(conversationId: conversationId, data: data)

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        let participants = sut.callParticipants(
            conversationId: conversationId,
            kind: participantsKind,
            activeSpeakersLimit: limit
        )

        // THEN
        let activeSpeakersAmount = participants.filter {
            guard case .active = $0.activeSpeakerState else {
                return false
            }
            return true
        }.count
        assertionBlock?(participants, activeSpeakersAmount)
    }

    func testThatCallParticipants_LimitsActiveSpeakersCorrectly() {
        testCallParticipants(activeSpeakerKind: .realTime, participantsKind: .all, limit: 1) { _, activeSpeakerAmount in

            XCTAssertEqual(activeSpeakerAmount, 1)
        }
    }

    func testThatCallParticipants_IncludesRealTimeActiveSpeakers_WhenParticipantsKind_All() {
        testCallParticipants(
            activeSpeakerKind: .realTime,
            participantsKind: .all
        ) { participants, activeSpeakerAmount in

            XCTAssertEqual(activeSpeakerAmount, participants.count)
        }
    }

    func testThatCallParticipants_ExcludesSmoothedActiveSpeakers_WhenParticipantsKind_All() {
        testCallParticipants(activeSpeakerKind: .smoothed, participantsKind: .all) { _, activeSpeakerAmount in

            XCTAssertEqual(activeSpeakerAmount, 0)
        }
    }

    func testThatCallParticipants_ReturnsSmoothedActiveSpeakersOnly_WhenParticipantKind_SmoothedActiveSpeakers() {
        testCallParticipants(
            activeSpeakerKind: .smoothed,
            participantsKind: .smoothedActiveSpeakers
        ) { participants, activeSpeakerAmount in

            XCTAssertEqual(activeSpeakerAmount, participants.count)
        }
    }

    func testThatCallParticipants_ExcludesRealTimeActiveSpeakers_WhenParticipantKind_SmoothedActiveSpeakers() {
        testCallParticipants(
            activeSpeakerKind: .realTime,
            participantsKind: .smoothedActiveSpeakers
        ) { _, activeSpeakerAmount in

            XCTAssertEqual(activeSpeakerAmount, 0)
        }
    }

    // MARK: - Request Video Streams

    func testThatRequestVideoStreams_SendsCorrectParameters() {
        // given
        let clientId1 = UUID().transportString()
        let clientId2 = UUID().transportString()
        let conversationId = groupConversationID!
        let clients = [
            AVSClient(userId: selfUserID, clientId: clientId1),
            AVSClient(userId: otherUserID, clientId: clientId2),
        ]

        let expectedResult = AVSVideoStreams(conversationId: conversationId.serialized, clients: clients)

        // when
        sut.requestVideoStreams(conversationId: conversationId, clients: clients)

        // then
        XCTAssertNotNil(mockAVSWrapper.requestVideoStreamsArguments)
        XCTAssertEqual(mockAVSWrapper.requestVideoStreamsArguments?.uuid, conversationId)
        XCTAssertEqual(mockAVSWrapper.requestVideoStreamsArguments?.videoStreams, expectedResult)
    }

    // MARK: - Request new epoch

    func testHandleNewEpochRequest() throws {
        // Given
        let conversationID = try XCTUnwrap(groupConversationID)
        let qualifiedID = try XCTUnwrap(groupConversation.qualifiedID)
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        createsMLSConferenceSnapshot(
            conversationID: conversationID,
            qualifiedID: qualifiedID,
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID
        )

        let mlsService = MockMLSServiceInterface()
        uiMOC.zm_sync.performAndWait {
            uiMOC.zm_sync.mlsService = mlsService
        }

        let didGenereateNewEpoch = customExpectation(description: "didGenerateNewEpoch")
        mlsService.generateNewEpochGroupID_MockMethod = {
            XCTAssertEqual($0, subconversationGroupID)
            didGenereateNewEpoch.fulfill()
        }

        // When
        sut.handleNewEpochRequest(conversationID: conversationID)

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    private func createsMLSConferenceSnapshot(
        conversationID: AVSIdentifier,
        qualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) {
        sut.callSnapshots[conversationID] = CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: (parentGroupID, subconversationGroupID),
            callParticipants: CallParticipantsSnapshot(
                conversationId: conversationID,
                members: [],
                callCenter: sut
            ),
            callState: .established,
            callStarter: selfUserID,
            isVideo: false,
            isGroup: true,
            isConstantBitRate: false,
            videoState: .stopped,
            networkQuality: .normal,
            conversationType: .mlsConference,
            degradedUser: nil,
            activeSpeakers: [],
            videoGridPresentationMode: .allVideoStreams
        )
    }
}

// MARK: - Conversation changes

extension WireCallCenterV3Tests {
    func test_SetClientList_WhenConversationParticipantsChange() throws {
        // Given
        let changeInfo = ConversationChangeInfo(object: groupConversation)
        changeInfo.changedKeys = [#keyPath(ZMConversation.participantRoles)]

        mockTransport.mockClientsRequestResponse = [
            AVSClient(userId: selfUserID, clientId: "client1"),
            AVSClient(userId: otherUserID, clientId: "client2"),
        ]

        let didReceiveClientList = customExpectation(description: "didReceiveClientList")
        sut.clientsRequestCompletionsByConversationId[groupConversationID] = { _ in
            didReceiveClientList.fulfill()
        }

        // When
        sut.conversationDidChange(changeInfo)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_CallIsClosed_WhenSelfUserIsNoLongerAMember() throws {
        // Given
        let selfUserParticipantRole = try XCTUnwrap(groupConversation.participantRoles.first {
            $0.user?.isSelfUser ?? false
        })

        groupConversation.participantRoles.remove(selfUserParticipantRole)

        let changeInfo = ConversationChangeInfo(object: groupConversation)
        changeInfo.changedKeys = [#keyPath(ZMConversation.participantRoles)]

        // When
        sut.conversationDidChange(changeInfo)

        // Then
        XCTAssertTrue(mockAVSWrapper.didCallEndCall)
    }

    func test_SystemMessageIsAppended_WhenProtocolChangesToMLS() throws {
        // Given
        sut.callSnapshots = callSnapshot(conversationId: groupConversation.avsIdentifier!, clients: [])
        groupConversation.messageProtocol = .mls
        let changeInfo = ConversationChangeInfo(object: groupConversation)
        changeInfo.changedKeys = [ZMConversation.messageProtocolKey]

        // When
        sut.conversationDidChange(changeInfo)

        // Then
        let lastMessage = try XCTUnwrap(groupConversation.lastMessage)
        XCTAssertTrue(lastMessage.isSystem)
        let systemMessageData = try XCTUnwrap(lastMessage.systemMessageData)
        XCTAssertEqual(systemMessageData.systemMessageType, .mlsMigrationOngoingCall)
    }

    func test_CallIsClosed_WhenConversationIsDeleted() throws {
        // Given
        groupConversation.isDeletedRemotely = true
        let changeInfo = ConversationChangeInfo(object: groupConversation)
        changeInfo.changedKeys = [#keyPath(ZMConversation.isDeletedRemotely)]

        // When
        sut.conversationDidChange(changeInfo)

        // Then
        XCTAssertTrue(mockAVSWrapper.didCallEndCall)
    }

    func test_CallIsClosed_WhenMlsConversationIsDegraded() throws {
        // Given
        let conversationID = try XCTUnwrap(groupConversationID)
        groupConversation.messageProtocol = .mls
        groupConversation.mlsGroupID = .random()
        groupConversation.mlsVerificationStatus = .degraded

        let mlsService = MockMLSServiceInterface()
        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        let didLeaveSubconversation = customExpectation(description: "didLeaveSubconversation")
        mlsService.leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod = { _, _, _ in
            didLeaveSubconversation.fulfill()
        }

        let changeInfo = ConversationChangeInfo(object: groupConversation)
        changeInfo.changedKeys = ["mlsVerificationStatus"]
        let clients = [
            AVSClient(userId: selfUserID, clientId: UUID().transportString()),
            AVSClient(userId: otherUserID, clientId: UUID().transportString()),
        ]

        sut.callSnapshots = callSnapshot(conversationId: conversationID, clients: clients)

        // When
        sut.conversationDidChange(changeInfo)

        // Then
        XCTAssertTrue(mockAVSWrapper.didCallEndCall)
    }
}

// MARK: - Helpers

extension AVSClient {
    fileprivate static var mockClient: AVSClient {
        AVSClient(
            userId: AVSIdentifier(identifier: UUID(), domain: "wire.com"),
            clientId: UUID().transportString()
        )
    }
}

extension AVSActiveSpeakersChange {
    fileprivate var data: String {
        let encoded = try! JSONEncoder().encode(self)
        return String(decoding: encoded, as: UTF8.self)
    }
}
