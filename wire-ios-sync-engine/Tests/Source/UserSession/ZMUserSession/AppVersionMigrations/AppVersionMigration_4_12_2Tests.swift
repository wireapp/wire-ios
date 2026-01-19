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
import Testing
import WireDomainSupport
import WireNetwork
import WireNetworkSupport
@testable import WireDataModelSupport
@testable import WireSyncEngine

struct AppVersionMigration_4_12_2Tests {

    let coreDataHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()
    let mockSafeCoreCrypto = MockSafeCoreCrypto()
    let mockProvider = MockCoreCryptoProviderProtocol()

    let stack: CoreDataStack
    let sut: AppVersionMigration_4_12_2

    init() async throws {
        self.stack = try await coreDataHelper.createStack()
        self.sut = AppVersionMigration_4_12_2(
            coreDataStack: stack,
            coreCryptoProvider: mockProvider
        )
        mockProvider.coreCrypto_MockValue = mockSafeCoreCrypto
    }

    @Test("Set correct epoch for all mls conversations")
    func testMigration() async throws {
        enum TestMigrationFailure: Error {
            case notFound
        }

        // GIVEN

        let context = stack.syncContext

        let idA = MLSGroupID.random()
        let idB = MLSGroupID.random()

        let expectedEpochA = UInt64(0)
        let expectedEpochB = UInt64(10)

        mockSafeCoreCrypto.coreCryptoContext.conversationExistsConversationId_MockValue = true
        mockSafeCoreCrypto.coreCryptoContext.conversationEpochConversationId_MockMethod = { conversationID in
            if conversationID == idA.conversationId {
                return expectedEpochA
            } else if conversationID == idB.conversationId {
                return expectedEpochB
            } else {
                throw TestMigrationFailure.notFound
            }
        }

        var conversationA: ZMConversation?
        var conversationB: ZMConversation?
        try await context.perform { [modelHelper, context] in
            conversationA = modelHelper.createMLSConversation(mlsGroupID: idA, epoch: 100, in: context)
            conversationB = modelHelper.createMLSConversation(mlsGroupID: idB, epoch: expectedEpochB, in: context)

            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let updatedConversationA = try XCTUnwrap(conversationA)
            let updatedConversationB = try XCTUnwrap(conversationB)
            XCTAssertEqual(updatedConversationA.epoch, expectedEpochA)
            XCTAssertEqual(updatedConversationB.epoch, expectedEpochB) // unchanged
        }
    }
}
