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

@testable import WireDataModel
@testable import WireDataModelSupport

final class IsSelfUserProteusVerifiedUseCaseTests: ZMBaseManagedObjectTest {

    private var sut: IsSelfUserProteusVerifiedUseCase!
    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        setupUsersClientsAndConversation()
        sut = .init(context: context)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testResultIsVerified() {
        // Given
        //

        // When
        let isVerified = sut.invoke()

        // Then
        XCTAssertTrue(isVerified)
    }

    func testResultIsNotVerified() throws {
        // Given
        try context.performAndWait {
            let selfClient = try XCTUnwrap(ZMUser.selfUser(in: context).selfClient())
            selfClient.trustedClients = [selfClient]
        }

        // When
        let isVerified = sut.invoke()

        // Then
        XCTAssertFalse(isVerified)
    }

    // MARK: - Helpers

    private func setupUsersClientsAndConversation() {
        context.performAndWait {
            setupMLSSelfConversation()
            setupSelfUser()
            setupClients()
        }
    }

    private func setupMLSSelfConversation() {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = .init(uuidString: "11AE029E-AFFA-4B81-9095-497797C0C0FA")
        conversation.mlsGroupID = .init(base64Encoded: "qE4EdglNFI53Cm4soIFZ/rUMVL4JfCgcE4eo86QVxSc=")
        conversation.messageProtocol = .mls
        conversation.mlsStatus = .ready
        conversation.conversationType = .`self`
    }

    private func setupSelfUser() {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = .init(uuidString: "36DFE52F-157D-452B-A9C1-98F7D9C1815D")
        selfUser.domain = "example.com"
    }

    private func setupClients() {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = UUID.create().uuidString
        selfClient.user = .selfUser(in: context)
        context.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)

        let otherClient = UserClient.insertNewObject(in: context)
        otherClient.remoteIdentifier = UUID.create().uuidString
        otherClient.user = .selfUser(in: context)

        selfClient.trustedClients = [selfClient, otherClient]
    }
}
