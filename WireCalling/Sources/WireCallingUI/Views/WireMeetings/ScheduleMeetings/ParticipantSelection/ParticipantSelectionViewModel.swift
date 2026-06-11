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

protocol ParticipantSource: Sendable {
    func search(query: String) async throws -> [ParticipantSelectionViewModel.Participant]
}

@MainActor
@Observable
final class ParticipantSelectionViewModel {

    struct Participant: Identifiable, Hashable, Sendable {
        let id: UUID
        var name: String
        var username: String?
    }

    private let source: any ParticipantSource

    var searchText: String = "" {
        didSet { scheduleSearch() }
    }
    var searchResults: [Participant] = []
    var selectedParticipants: [Participant] = []
    var isSearching = false
    var isSelectedExpanded = true
    var isContactsExpanded = true

    private var searchTask: Task<Void, Never>?

    init(source: any ParticipantSource) {
        self.source = source
        scheduleSearch(debounce: .zero) // initial load is immediate
    }

    // MARK: - Derived state

    var filteredUnselected: [Participant] {
        let selectedIDs = Set(selectedParticipants.map(\.id))
        return searchResults.filter { !selectedIDs.contains($0.id) }
    }

    func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains { $0.id == participant.id }
    }

    // MARK: - Actions

    func toggleSelection(_ participant: Participant) {
        if let index = selectedParticipants.firstIndex(where: { $0.id == participant.id }) {
            selectedParticipants.remove(at: index)
        } else {
            selectedParticipants.append(participant)
        }
    }

    // MARK: - Search

    private func scheduleSearch(debounce: Duration = .milliseconds(300)) {
        searchTask?.cancel()
        let query = searchText
        isSearching = true
        searchTask = Task { [weak self] in
            if debounce > .zero {
                try? await Task.sleep(for: debounce)
                guard !Task.isCancelled else { return }
            }
            guard let self else { return }
            do {
                let results = try await source.search(query: query)
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch is CancellationError {
                return
            } catch {
                // TODO: surface error
            }
            isSearching = false
        }
    }
}

// MARK: - Mock

struct MockParticipantSource: ParticipantSource {

    let participants: [ParticipantSelectionViewModel.Participant]

    init(participants: [ParticipantSelectionViewModel.Participant] = .mock) {
        self.participants = participants
    }

    func search(query: String) async throws -> [ParticipantSelectionViewModel.Participant] {
        guard !query.isEmpty else { return participants }
        return participants.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

private extension Array where Element == ParticipantSelectionViewModel.Participant {
    static var mock: Self {
        [
            .init(id: UUID(), name: "Martin Koch-Johansen", username: "username"),
            .init(id: UUID(), name: "Olga Heaney", username: "username"),
            .init(id: UUID(), name: "Margarete Springer", username: "username"),
            .init(id: UUID(), name: "Lorenzo Schmeler", username: nil),
            .init(id: UUID(), name: "Jaqueline Olaho", username: nil),
            .init(id: UUID(), name: "Katie Armstrong", username: "username"),
            .init(id: UUID(), name: "Zachary Ratke", username: "username"),
            .init(id: UUID(), name: "Marco Weissnat", username: "username"),
            .init(id: UUID(), name: "Deborah Schoen", username: "username")
        ]
    }
}
