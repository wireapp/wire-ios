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
@testable import WireDomain

struct UpdateConversationItemTests {

    let sut: UpdateConversationItem

    var repository: MockConversationRepositoryProtocol
    let conversationID: WireNetwork.QualifiedID

    init() async throws {
        self.repository = MockConversationRepositoryProtocol()
        self.conversationID = .init(id: UUID(), domain: String.randomDomain())
        self.sut = UpdateConversationItem(repository: repository, conversationID: conversationID)
    }

    @Test("It calls repository pull conversation")
    func startsPullConversationSuccessfully() async throws {
        // Given
        repository.pullConversationIdDomain_MockMethod = { _, _ in }
        // When
        try await sut.start()

        // Then
        let invocation = repository.pullConversationIdDomain_Invocations.first
        #expect(invocation?.domain == conversationID.domain && invocation?.id == conversationID.id)
    }

    @Test("It deletes the conversation if not found")
    func startsDeleteConversationIfNotFound() async throws {
        // Given
        repository.pullConversationIdDomain_MockError = ConversationRepositoryError.conversationNotFound
        repository.deleteConversationIdDomain_MockMethod = { _, _ in }
        // When
        try await sut.start()

        // Then
        let invocation = repository.deleteConversationIdDomain_Invocations.first
        #expect(invocation?.domain == conversationID.domain && invocation?.id == conversationID.id)
    }

    @Test("It throws an error in case of non supported error")
    func startThrowsInOtherError() async throws {
        // Given
        let error = NSError(domain: "randomDomain", code: 999)
        repository.pullConversationIdDomain_MockError = error
        // When
        await #expect(throws: error) {
            try await sut.start()
        }

        // Then
        let invocation = repository.pullConversationIdDomain_Invocations.first
        #expect(invocation?.domain == conversationID.domain && invocation?.id == conversationID.id)
    }
}
