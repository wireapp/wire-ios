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
import WireCallingDomain
import WireCallingDomainSupport
import WireFoundation

@testable import WireCallingUI

@MainActor
struct MemberSelectionViewModelTests {

    private let searchMembersUseCase: SearchMembersUseCaseProtocolMock
    private let onSelectRecorder: OnSelectRecorder
    private let viewModel: MemberSelectionViewModel

    init() {
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMemberReturnValue = []

        let recorder = OnSelectRecorder()

        self.searchMembersUseCase = useCase
        self.onSelectRecorder = recorder
        self.viewModel = MemberSelectionViewModel(
            source: useCase,
            onSelect: { recorder.calls.append($0) }
        )
    }

    // MARK: - isSelected / toggleSelection

    @Test("isSelected is false for a member that hasn't been selected")
    func isSelectedFalseForUnknownMember() {
        #expect(viewModel.isSelected(.alice) == false)
    }

    @Test("toggleSelection adds an unselected member")
    func toggleSelection_addsUnselectedMember() {
        // When
        viewModel.toggleSelection(.alice)

        // Then
        #expect(viewModel.isSelected(.alice))
        #expect(viewModel.selectedMembers.count == 1)
        #expect(viewModel.selectedMembers.first?.id == Member.alice.id)
    }

    @Test("toggleSelection removes an already-selected member")
    func toggleSelection_removesSelectedMember() {
        // Given
        viewModel.toggleSelection(.alice)

        // When
        viewModel.toggleSelection(.alice)

        // Then
        #expect(viewModel.isSelected(.alice) == false)
        #expect(viewModel.selectedMembers.isEmpty)
    }

    @Test("toggleSelection only affects the targeted member")
    func toggleSelection_affectsOnlyTargetedMember() {
        // Given
        viewModel.toggleSelection(.alice)
        viewModel.toggleSelection(.bob)

        // When
        viewModel.toggleSelection(.alice)

        // Then
        #expect(viewModel.isSelected(.alice) == false)
        #expect(viewModel.isSelected(.bob))
        #expect(viewModel.selectedMembers.count == 1)
    }

    // MARK: - filteredUnselected

    @Test("filteredUnselected excludes selected members from searchResults")
    func filteredUnselected_excludesSelectedMembers() {
        // Given
        viewModel.searchResults = [.alice, .bob]

        // When
        viewModel.toggleSelection(.alice)

        // Then
        #expect(viewModel.filteredUnselected.count == 1)
        #expect(viewModel.filteredUnselected.first?.id == Member.bob.id)
    }

    @Test("filteredUnselected returns all results when nothing is selected")
    func filteredUnselected_returnsAllWhenNoneSelected() {
        // Given
        viewModel.searchResults = [.alice, .bob]

        // Then
        #expect(viewModel.filteredUnselected.count == 2)
    }

    // MARK: - confirmSelection

    @Test("confirmSelection forwards the current selection to onSelect")
    func confirmSelection_forwardsSelectionToOnSelect() {
        // Given
        viewModel.toggleSelection(.alice)
        viewModel.toggleSelection(.bob)

        // When
        viewModel.confirmSelection()

        // Then
        #expect(onSelectRecorder.calls.count == 1)
        #expect(onSelectRecorder.calls.first?.map(\.id) == [Member.alice, Member.bob].map(\.id))
    }

    @Test("toggleSelection alone does not invoke onSelect")
    func toggleSelection_doesNotInvokeOnSelect() {
        // When
        viewModel.toggleSelection(.alice)

        // Then
        #expect(onSelectRecorder.calls.isEmpty)
    }

    // MARK: - initialSelection

    @Test("initialSelection seeds selectedMembers")
    func initialSelection_seedsSelectedMembers() {
        // Given
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMemberReturnValue = []

        // When
        let viewModel = MemberSelectionViewModel(
            source: useCase,
            initialSelection: [.alice]
        )

        // Then
        #expect(viewModel.isSelected(.alice))
        #expect(viewModel.selectedMembers.count == 1)
    }

    // MARK: - Search

    @Test("initial search populates searchResults")
    func initialSearch_populatesSearchResults() async {
        // Given
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMemberReturnValue = [.alice, .bob]

        // When
        let viewModel = MemberSelectionViewModel(source: useCase)
        await waitForSearchToSettle(viewModel)

        // Then
        #expect(viewModel.searchResults.map(\.id) == [Member.alice, Member.bob].map(\.id))
        #expect(viewModel.hasSearchError == false)
        #expect(viewModel.isSearching == false)
    }

    @Test("search failure sets hasSearchError and clears searchResults")
    func searchFailure_setsHasSearchError() async {
        // Given
        let useCase = SearchMembersUseCaseProtocolMock()
        useCase.invokeQueryStringMemberThrowableError = TestError.failure

        // When
        let viewModel = MemberSelectionViewModel(source: useCase)
        await waitForSearchToSettle(viewModel)

        // Then
        #expect(viewModel.hasSearchError)
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearching == false)
    }

    // MARK: - Async helpers

    private func waitForSearchToSettle(_ viewModel: MemberSelectionViewModel) async {
        while viewModel.isSearching {
            await Task.yield()
        }
    }
}

// MARK: - Helpers

private enum TestError: Error {
    case failure
}

private final class OnSelectRecorder {
    var calls: [[Member]] = []
}

private extension Member {

    static let alice = Member(
        qualifiedID: QualifiedID(id: UUID(), domain: ""),
        name: "Alice",
        handle: "alice"
    )

    static let bob = Member(
        qualifiedID: QualifiedID(id: UUID(), domain: ""),
        name: "Bob",
        handle: "bob"
    )

}
