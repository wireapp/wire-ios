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

import XCTest
import WireTesting
@testable import WireSyncEngine
@testable import WireDataModelSupport

class OneOnOneConversationCreationStatusUseCaseTests: XCTestCase {

    private var sut: OneOnOneConversationCreationStatusUseCase!
    private var coreDataStack: CoreDataStack!
    private var mockProtocolSelector: MockOneOnOneProtocolSelectorInterface!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockCoreCrypto: MockCoreCryptoProtocol!
    private var syncMOC: NSManagedObjectContext!
    private var user: ZMUser!
    private var userID: QualifiedID!

    override func setUp() async throws {
        try await super.setUp()
        let coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        syncMOC = coreDataStack.syncContext

        mockProtocolSelector = MockOneOnOneProtocolSelectorInterface()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        sut = OneOnOneConversationCreationStatusUseCase(
            context: syncMOC,
            oneOnOneProtocolSelector: mockProtocolSelector,
            coreCryptoProvider: mockCoreCryptoProvider
        )

        await setupUser()
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
        mockProtocolSelector = nil
        mockCoreCryptoProvider = nil
        mockCoreCrypto = nil
        syncMOC = nil
        user = nil
        super.tearDown()
    }

    private func setupUser() async {
        let uuid = UUID()
        let domain = "domain.com"

        user = await syncMOC.perform { [self] in
            let user = ZMUser.insertNewObject(in: syncMOC)
            user.remoteIdentifier = uuid
            user.domain = domain
            return user
        }

        userID = QualifiedID(uuid: uuid, domain: domain)
    }

    func test_ItReturnsCorrectStatus_WhenConversationExists_Proteus() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .proteus)

        // When
        let status = try await sut.invoke(userID: userID)

        // Then
        XCTAssertEqual(status, .exists(protocol: .proteus, established: nil))
    }

    func test_ItReturnsCorrectStatus_WhenConversationExists_MLS_Established() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: .random())
        mockCoreCrypto.conversationExistsConversationId_MockValue = true

        // When
        let status = try await sut.invoke(userID: userID)

        // Then
        XCTAssertEqual(status, .exists(protocol: .mls, established: true))
    }

    func test_ItReturnsCorrectStatus_WhenConversationExists_MLS_NotEstablished() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: .random())
        mockCoreCrypto.conversationExistsConversationId_MockValue = false

        // When
        let status = try await sut.invoke(userID: userID)

        // Then
        XCTAssertEqual(status, .exists(protocol: .mls, established: false))
    }

    func test_itReturnsCorrectStatus_WhenConversationDoesntExist_Proteus() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .proteus

        // When
        let status = try await sut.invoke(userID: userID)

        // Then
        XCTAssertEqual(status, .doesNotExist(protocol: .proteus))
    }

    func test_itReturnsCorrectStatus_WhenConversationDoesntExist_MLS() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls

        // When
        let status = try await sut.invoke(userID: userID)

        // Then
        XCTAssertEqual(status, .doesNotExist(protocol: .mls))
    }

    func test_itThrowsUserNotFoundError() async {
        // When / Then
        await assertItThrows(error: OneOnOneConversationCreationStatusUseCase.Error.userNotFound) {
            _ = try await self.sut.invoke(userID: .random())
        }
    }

    func test_itThrowsMissingGroupIDError() async {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: nil)

        // When / Then
        await assertItThrows(error: OneOnOneConversationCreationStatusUseCase.Error.missingGroupID) {
            _ = try await self.sut.invoke(userID: userID)
        }
    }

    private func setupOneOnOne(messageProtocol: MessageProtocol, groupID: MLSGroupID? = nil) async {
        await syncMOC.perform { [self] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.messageProtocol = messageProtocol
            conversation.mlsGroupID = groupID
            user.oneOnOneConversation = conversation
        }
    }
}
