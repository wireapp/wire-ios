//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Foundation
import WireAPI
import WireCoreCrypto
import XCTest

@testable import WireAPISupport
@testable import WireDomain
@testable import WireDomainSupport

final class MLSTransportTests: XCTestCase {

    private var sut: MLSTransportImpl!
    private var mlsAPI: MLSAPIMock!
    private var conversationEventProcessor: MockConversationEventProcessorProtocol!

    override func setUp() async throws {
        mlsAPI = MLSAPIMock()
        conversationEventProcessor = MockConversationEventProcessorProtocol()
        sut = MLSTransportImpl(
            mlsAPI: mlsAPI,
            conversationEventProcessor: conversationEventProcessor
        )
    }

    override func tearDown() async throws {
        sut = nil
        mlsAPI = nil
        conversationEventProcessor = nil
    }

    func testOnSendCommitBundle_CommitBundleIsPostedToMLSAPI() async throws {
        // Given
        mlsAPI.postCommitBundleBundleCommitBundleUpdateEventReturnValue = []

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle)

        // Then
        XCTAssertEqual(
            mlsAPI.postCommitBundleBundleCommitBundleUpdateEventReceivedInvocations,
            [Scaffolding.commitBundle.toAPIModel()]
        )
    }

    func testOnSendCommitBundle_ConversationEventsAreForwaredToConversationEventProcessor() async throws {
        // Given
        mlsAPI.postCommitBundleBundleCommitBundleUpdateEventReturnValue = [Scaffolding.conversationUpdateEvent]
        conversationEventProcessor.processEvent_MockMethod = { _ in }

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle)

        // Then
        XCTAssertEqual(conversationEventProcessor.processEvent_Invocations, [Scaffolding.conversationEvent])
    }

    func testOnSendCommitBundle_UnknownEventsAreNotForwaredToConversationEventProcessor() async throws {
        // Given
        mlsAPI.postCommitBundleBundleCommitBundleUpdateEventReturnValue = [Scaffolding.unknownUpdateEvent]
        conversationEventProcessor.processEvent_MockMethod = { _ in }

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle)

        // Then
        XCTAssertEqual(conversationEventProcessor.processEvent_Invocations, [])
    }

    func testOnSendCommitBundle_ReturnsSuccessWhenThereIsNoError() async throws {
        // Given
        mlsAPI.postCommitBundleBundleCommitBundleUpdateEventReturnValue = []

        // When
        let result = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle)

        // Then
        XCTAssertEqual(result, .success)
    }

    func testOnSendCommitBundle_ReturnsAbortWhenThereIsAnError() async throws {
        // Given
        mlsAPI.postCommitBundleBundleCommitBundleUpdateEventThrowableError = MLSAPIError.mlsStaleMessage

        // When
        let result = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle)

        // Then
        XCTAssertEqual(result, .abort(reason: try MLSAPIError.mlsStaleMessage.encodeAsString()))
    }

    enum Scaffolding {

        static let conversationID = ConversationID(
            uuid: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
            domain: "example.com"
        )

        static let senderID = UserID(
            uuid: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
            domain: "example.com"
        )

        static let commitBundle = CommitBundle(
            welcome: .random(),
            commit: .random(),
            groupInfo:
            GroupInfoBundle(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: .random()
            )
        )

        static let conversationEvent = ConversationEvent.typing(
            ConversationTypingEvent(
                conversationID: conversationID,
                senderID: senderID,
                isTyping: true
            )
        )

        static let conversationUpdateEvent = UpdateEvent.conversation(conversationEvent)

        static let unknownUpdateEvent = UpdateEvent.unknown(eventType: "Unknown event")

    }
}
