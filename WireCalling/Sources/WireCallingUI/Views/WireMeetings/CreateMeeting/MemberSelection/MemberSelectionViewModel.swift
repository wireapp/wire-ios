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
import Observation
import WireCallingDomain
import WireLogging

@MainActor
@Observable
final class MemberSelectionViewModel {

    private let source: any MemberRepositoryProtocol
    private let onSelect: ([Member]) -> Void

    var searchText: String = "" {
        didSet { scheduleSearch() }
    }

    var searchResults: [Member] = []
    var selectedMembers: [Member] = []
    var isSearching = false
    var hasSearchError = false
    var isSelectedExpanded = true
    var isContactsExpanded = true

    private var searchTask: Task<Void, Never>?

    init(
        source: any MemberRepositoryProtocol,
        initialSelection: [Member] = [],
        onSelect: @escaping ([Member]) -> Void = { _ in }
    ) {
        self.source = source
        self.selectedMembers = initialSelection
        self.onSelect = onSelect
        scheduleSearch(debounce: .zero) // initial load is immediate
    }

    // MARK: - Derived state

    var filteredUnselected: [Member] {
        let selectedIDs = Set(selectedMembers.map(\.id))
        return searchResults.filter { !selectedIDs.contains($0.id) }
    }

    func isSelected(_ member: Member) -> Bool {
        selectedMembers.contains { $0.id == member.id }
    }

    // MARK: - Actions

    func toggleSelection(_ member: Member) {
        if let index = selectedMembers.firstIndex(where: { $0.id == member.id }) {
            selectedMembers.remove(at: index)
        } else {
            selectedMembers.append(member)
        }
    }

    func confirmSelection() {
        onSelect(selectedMembers)
    }

    func retrySearch() {
        scheduleSearch(debounce: .zero)
    }

    // MARK: - Search

    private func scheduleSearch(debounce: Duration = .milliseconds(300)) {
        searchTask?.cancel()
        let query = searchText
        isSearching = true

        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                if debounce > .zero {
                    try await Task.sleep(for: debounce)
                }
                try Task.checkCancellation()

                let results = try await source.search(query: query)
                try Task.checkCancellation()

                searchResults = results
                hasSearchError = false
                isSearching = false
            } catch is CancellationError {
                // If we were cancelled (e.g. a new query arrived), keep `isSearching` true and let the latest task own
                // it.
                return
            } catch {
                WireLogger.ui.warn("failed to search for meeting members to select", attributes: .safePublic)
                WireLogger.ui.warn("\(error)")
                searchResults = []
                hasSearchError = true
                isSearching = false
            }
        }
    }
}
