//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireCoreCrypto
import WireDataModel
import WireNetwork
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetworkSupport

final class MLSTransportTests: XCTestCase {

    private var sut: MLSTransportImpl!
    private var mlsAPI: MockMLSAPI!
    private var conversationEventProcessor: MockConversationEventProcessorProtocol!

    override func setUp() async throws {
        mlsAPI = MockMLSAPI()
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
        mlsAPI.postCommitBundle_MockValue = []

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle.coreCryptoCommitBundle)

        // Then
        XCTAssertEqual(mlsAPI.postCommitBundle_Invocations, [Scaffolding.commitBundle])
    }

    func testOnSendCommitBundle_ConversationEventsAreForwaredToConversationEventProcessor() async throws {
        // Given
        mlsAPI.postCommitBundle_MockValue = [Scaffolding.conversationUpdateEvent]
        conversationEventProcessor.processEvent_MockMethod = { _ in }

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle.coreCryptoCommitBundle)

        // Then
        XCTAssertEqual(conversationEventProcessor.processEvent_Invocations, [Scaffolding.conversationEvent])
    }

    func testOnSendCommitBundle_UnknownEventsAreNotForwaredToConversationEventProcessor() async throws {
        // Given
        mlsAPI.postCommitBundle_MockValue = [Scaffolding.unknownUpdateEvent]
        conversationEventProcessor.processEvent_MockMethod = { _ in }

        // When
        _ = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle.coreCryptoCommitBundle)

        // Then
        XCTAssertEqual(conversationEventProcessor.processEvent_Invocations, [])
    }

    func testOnSendCommitBundle_ReturnsSuccessWhenThereIsNoError() async throws {
        // Given
        mlsAPI.postCommitBundle_MockValue = []

        // When
        let result = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle.coreCryptoCommitBundle)

        // Then
        XCTAssertEqual(result, MlsTransportResponse.success)
    }

    func testOnSendCommitBundle_ReturnsAbortWhenThereIsAnError() async throws {
        // Given
        mlsAPI.postCommitBundle_MockError = MLSAPIError.mlsStaleMessage

        // When
        let result = await sut.sendCommitBundle(commitBundle: Scaffolding.commitBundle.coreCryptoCommitBundle)

        // Then
        let data = try JSONEncoder().encode(MLSTransportError.mlsStaleMessage)
        let expectedReason = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(result, MlsTransportResponse.abort(reason: expectedReason))
    }

    enum Scaffolding {

        static let conversationID = ConversationID(
            id: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
            domain: "example.com"
        )

        static let senderID = UserID(
            id: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
            domain: "example.com"
        )

        static let commitBundle = CommitBundle(
            welcome: .random(),
            commit: .random(),
            groupInfo:
            GroupInfoBundle(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: GroupInfo(bytes: .random())
            ).payload.copyBytes()
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

extension WireNetwork.CommitBundle {
    var coreCryptoCommitBundle: WireCoreCryptoUniffi.CommitBundle {
        .init(
            welcome: welcome != nil ? Welcome(bytes: welcome!) : nil,
            commit: commit,
            groupInfo: GroupInfoBundle(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: GroupInfo(bytes: groupInfo)
            ),
            encryptedMessage: nil
        )
    }
}
