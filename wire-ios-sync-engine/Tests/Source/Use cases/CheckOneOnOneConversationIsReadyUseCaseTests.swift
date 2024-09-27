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

import WireTesting
import XCTest
@testable import WireDataModelSupport
@testable import WireSyncEngine

class CheckOneOnOneConversationIsReadyUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        let coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        syncMOC = coreDataStack.syncContext

        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        sut = CheckOneOnOneConversationIsReadyUseCase(
            context: syncMOC,
            coreCryptoProvider: mockCoreCryptoProvider
        )

        await setupUser()
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
        mockCoreCryptoProvider = nil
        mockCoreCrypto = nil
        syncMOC = nil
        user = nil
        super.tearDown()
    }

    func test_ItReturnsTrue_WhenConversationExists_Proteus() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .proteus)

        // When
        let isReady = try await sut.invoke(userID: userID)

        // Then
        XCTAssertTrue(isReady)
    }

    func test_ItReturnsTrue_WhenConversationExists_MLS_Established() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: .random())
        mockCoreCrypto.conversationExistsConversationId_MockValue = true

        // When
        let isReady = try await sut.invoke(userID: userID)

        // Then
        XCTAssertTrue(isReady)
    }

    func test_ItReturnsFalse_WhenConversationExists_MLS_NotEstablished() async throws {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: .random())
        mockCoreCrypto.conversationExistsConversationId_MockValue = false

        // When
        let isReady = try await sut.invoke(userID: userID)

        // Then
        XCTAssertFalse(isReady)
    }

    func test_itReturnsFalse_WhenConversationDoesntExist() async throws {
        // When
        let isReady = try await sut.invoke(userID: userID)

        // Then
        XCTAssertFalse(isReady)
    }

    func test_itThrowsUserNotFoundError() async {
        // When / Then
        await assertItThrows(error: CheckOneOnOneConversationIsReadyError.userNotFound) {
            _ = try await self.sut.invoke(userID: .random())
        }
    }

    func test_itThrowsMissingGroupIDError() async {
        // Given
        await setupOneOnOne(messageProtocol: .mls, groupID: nil)

        // When / Then
        await assertItThrows(error: CheckOneOnOneConversationIsReadyError.missingGroupID) {
            _ = try await self.sut.invoke(userID: userID)
        }
    }

    // MARK: Private

    private var sut: CheckOneOnOneConversationIsReadyUseCase!
    private var coreDataStack: CoreDataStack!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockCoreCrypto: MockCoreCryptoProtocol!
    private var syncMOC: NSManagedObjectContext!
    private var user: ZMUser!
    private var userID: QualifiedID!

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

    private func setupOneOnOne(messageProtocol: MessageProtocol, groupID: MLSGroupID? = nil) async {
        await syncMOC.perform { [self] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.messageProtocol = messageProtocol
            conversation.mlsGroupID = groupID
            user.oneOnOneConversation = conversation
        }
    }
}
