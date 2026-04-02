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
@testable import WireDataModel
@testable import WireDataModelSupport

@Suite
struct RemoveEARKeysUseCaseTests {

    let sut: RemoveEARKeysUseCase
    let mockKeyRepository: MockEARKeyRepositoryInterface
    let accountID: UUID

    init() {
        self.accountID = UUID()
        self.mockKeyRepository = MockEARKeyRepositoryInterface()
        mockKeyRepository.deletePublicKeyDescription_MockMethod = { _ in }
        mockKeyRepository.deletePrivateKeyDescription_MockMethod = { _ in }
        mockKeyRepository.deleteDatabaseKeyDescription_MockMethod = { _ in }
        self.sut = RemoveEARKeysUseCase(keyRepository: mockKeyRepository)
    }

    @Test("Deletes all five EAR keys with correct descriptions")
    func invoke_deletesAllExpectedKeys() throws {
        // When
        try sut.invoke(accountID: accountID)

        // Then
        let deletedPublicIDs = mockKeyRepository.deletePublicKeyDescription_Invocations.map(\.id)
        let deletedPrivateIDs = mockKeyRepository.deletePrivateKeyDescription_Invocations.map(\.id)
        let deletedDatabaseIDs = mockKeyRepository.deleteDatabaseKeyDescription_Invocations.map(\.id)

        #expect(deletedPublicIDs.contains(PublicEARKeyDescription.primaryKeyDescription(accountID: accountID).id))
        #expect(deletedPublicIDs.contains(PublicEARKeyDescription.secondaryKeyDescription(accountID: accountID).id))
        #expect(deletedPrivateIDs.contains(PrivateEARKeyDescription.primaryKeyDescription(
            accountID: accountID,
            context: nil
        ).id))
        #expect(deletedPrivateIDs.contains(PrivateEARKeyDescription.secondaryKeyDescription(accountID: accountID).id))
        #expect(deletedDatabaseIDs.contains(DatabaseEARKeyDescription.keyDescription(accountID: accountID).id))
    }

    @Test("Does not delete keys belonging to a different account")
    func invoke_doesNotDeleteOtherAccountKeys() throws {
        // Given
        let otherAccountID = UUID()

        // When
        try sut.invoke(accountID: accountID)

        // Then
        let deletedPublicIDs = mockKeyRepository.deletePublicKeyDescription_Invocations.map(\.id)
        #expect(!deletedPublicIDs.contains(PublicEARKeyDescription.primaryKeyDescription(accountID: otherAccountID).id))
        #expect(!deletedPublicIDs
            .contains(PublicEARKeyDescription.secondaryKeyDescription(accountID: otherAccountID).id))
    }

    @Test("Propagates repository error")
    func invoke_propagatesRepositoryError() {
        // Given
        struct DeletionError: Error {}
        mockKeyRepository.deletePublicKeyDescription_MockError = DeletionError()

        // When / Then
        #expect(throws: DeletionError.self) {
            try sut.invoke(accountID: accountID)
        }
    }

}
