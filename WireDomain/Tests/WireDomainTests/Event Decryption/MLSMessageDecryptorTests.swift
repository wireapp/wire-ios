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

@testable import WireAPI
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
@testable import WireDomainSupport
import XCTest

final class MLSMessageDecryptorTests: XCTestCase {

    private var sut: MLSMessageDecryptor!
    private var mlsService: MockMLSServiceInterface!
    private var mlsDecryptionService: MockMLSDecryptionServiceInterface!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        mlsService = MockMLSServiceInterface()
        mlsDecryptionService = MockMLSDecryptionServiceInterface()
        conversationLocalStore = MockConversationLocalStoreProtocol()

        sut = MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        mlsService = nil
        mlsDecryptionService = nil
        conversationLocalStore = nil
        modelHelper = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testDecryptedEventData_It_Decrypts_An_Event_And_Invokes_Repo_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            let conversation = modelHelper.createMLSConversation(
                id: Scaffolding.conversationID.uuid,
                mlsGroupID: Scaffolding.mlsGroupID,
                in: context
            )

            return conversation
        }

        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        let mockDecryptionResult = MLSDecryptResult.message(
            decryptedMessageData,
            .randomAlphanumerical(length: 3)
        )

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.mlsConversationInfoConversation_MockValue = (try XCTUnwrap(Scaffolding.mlsGroupID), true)
        mlsDecryptionService.decryptMessageForSubconversationType_MockValue = [mockDecryptionResult]

        // When

        let event = try await sut.decryptedEventData(from: Scaffolding.makeEvent(content: encryptedMessage))

        // Then

        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(mlsDecryptionService.decryptMessageForSubconversationType_Invocations.count, 1)
        XCTAssertEqual(event.decryptedMessages.first?.message, decryptedMessage)
    }

    private enum Scaffolding {

        static let localDomain = "local.com"

        static let selfUserID = UserID(uuid: UUID(), domain: localDomain)
        static let selfClientID = "selfClientID"
        static let selfClientNumberOfKeys: Int32 = 10

        static let aliceID = UserID(uuid: UUID(), domain: localDomain)
        static let aliceClientID1 = "aliceClientID1"
        static let aliceClientID2 = "aliceClientID2"

        static let conversationID = ConversationID(uuid: UUID(), domain: localDomain)
        static let timestamp = Date()

        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="

        static let mlsGroupID = MLSGroupID(base64Encoded: base64EncodedString)

        static func makeEvent(content: String) -> ConversationMLSMessageAddEvent {
            ConversationMLSMessageAddEvent(
                conversationID: conversationID,
                senderID: aliceID,
                subconversation: nil,
                message: content,
                timestamp: timestamp
            )
        }

    }

}
