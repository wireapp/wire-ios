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
import Testing
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
@testable import WireDomain

class CommitPendingProposalItemTests {

    var sut: CommitPendingProposalItem!

    let repository: MockConversationRepositoryProtocol
    let mlsService: MockMLSServiceInterface
    let conversationID: WireDataModel.QualifiedID
    let mlsGroupID: MLSGroupID

    init() {
        self.repository = MockConversationRepositoryProtocol()
        self.conversationID = .init(uuid: UUID(), domain: String.randomDomain())
        self.mlsGroupID = .random()
        self.mlsService = .init()
        mlsService.commitPendingProposalsIn_MockMethod = { _ in }
        repository.isSelfAnActiveMemberIn_MockValue = true
    }

    private func makeProposalItem() -> CommitPendingProposalItem {
        CommitPendingProposalItem(
            repository: repository,
            conversationID: conversationID,
            groupID: mlsGroupID,
            mlsService: mlsService
        )
    }

    @Test("It calls commitPendingProposal")
    func startCallsCommitPendingProposal() async throws {
        // Given
        sut = makeProposalItem()
        // When
        try await sut.start()

        // Then
        #expect(mlsService.commitPendingProposalsIn_Invocations.count == 1)
    }

    @Test("It does not call commitPendingProposal when selfUser is not part of the group")
    func startDoesNotCallCommitPendingProposalFuture() async throws {
        // Given
        repository.isSelfAnActiveMemberIn_MockValue = false

        sut = makeProposalItem()

        // When
        try await sut.start()

        // Then
        #expect(mlsService.commitPendingProposalsIn_Invocations.isEmpty)
    }

    @Test("It logs properly")
    func loggingDescription() {
        // Given
        sut = makeProposalItem()

        // WHEN / THEN
        #expect(sut.description == "\(sut!)")
    }
}
