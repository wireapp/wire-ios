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

@Observable
final class ParticipantSelectionViewModel {

    struct Participant: Identifiable, Hashable {
        let id: UUID
        var name: String
        var username: String?
    }

    var searchText = ""
    var isSelectedExpanded = true
    var isContactsExpanded = true
    var selectedIDs: Set<Participant.ID> = []

    // TODO: inject from caller
    let allParticipants: [Participant] = .mock

    var selectedParticipants: [Participant] {
        allParticipants.filter { selectedIDs.contains($0.id) }
    }

    var filteredUnselected: [Participant] {
        let unselected = allParticipants.filter { !selectedIDs.contains($0.id) }
        guard !searchText.isEmpty else { return unselected }
        return unselected.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func toggleSelection(_ id: Participant.ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
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
