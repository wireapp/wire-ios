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

import WireDataModel
import WireSyncEngine

struct SearchResultsEmptyStateInput: Equatable {
    let searchingForBots: Bool
    let hasFilter: Bool
}

struct SearchResultsSectionContent {
    let contacts: [ZMSearchUser]
    let teamMembersAndContacts: [ZMSearchUser]
    let directory: [ZMSearchUser]
    let conversations: [ZMConversation]
    let apps: [any UserType]
    let bots: [any UserType]
    let federation: [ZMSearchUser]
}

struct SearchResultsViewModel {
    var searchGroup: SearchGroup = .people
    var mode: SearchResultsViewControllerMode = .list
    var isAddingParticipants: Bool
    var hasTeam: Bool
    var shouldIncludeGuests: Bool

    var visibleSections: [SearchResultsViewControllerSection] {
        switch (searchGroup, isAddingParticipants, mode, hasTeam) {
        case (.apps, _, _, _):
            [.apps]
        case (.bots, _, _, _):
            [.bots]
        case (.people, true, _, false):
            [.contacts]
        case (.people, true, _, true):
            [.teamMembers]
        case (.people, false, .search, false):
            [.contacts, .conversations, .directory, .federation]
        case (.people, false, .search, true):
            [.teamMembers, .conversations, .directory, .federation]
        case (.people, false, .selection, false):
            [.contacts]
        case (.people, false, .selection, true):
            [.teamMembers]
        case (.people, false, .list, false):
            [.topPeople, .contacts]
        case (.people, false, .list, true):
            [.inviteTeamMember, .teamMembers]
        }
    }

    func emptyStateInput(for query: String) -> SearchResultsEmptyStateInput {
        SearchResultsEmptyStateInput(
            searchingForBots: searchGroup == .apps || searchGroup == .bots,
            hasFilter: !query.isEmpty
        )
    }

    func sectionContent(
        from searchResult: SearchResult,
        excludingParticipantsOf filterConversation: ZMConversation?
    ) -> SearchResultsSectionContent {
        let filteredContacts = contacts(
            searchResult.contacts,
            excludingParticipantsOf: filterConversation
        )
        let filteredTeamMembers = contacts(
            searchResult.teamMembers,
            excludingParticipantsOf: filterConversation
        )

        return SearchResultsSectionContent(
            contacts: filteredContacts,
            teamMembersAndContacts: teamMembersAndContacts(
                teamMembers: filteredTeamMembers,
                contacts: filteredContacts
            ),
            directory: searchResult.directory.filter { !$0.isFederated },
            conversations: searchResult.conversations,
            apps: apps(searchResult.apps, excludingParticipantsOf: filterConversation),
            bots: searchResult.bots,
            federation: searchResult.directory.filter(\.isFederated)
        )
    }

    private func contacts(
        _ contacts: [ZMSearchUser],
        excludingParticipantsOf filterConversation: ZMConversation?
    ) -> [ZMSearchUser] {
        guard let filteredParticipants = filterConversation?.localParticipants else {
            return contacts
        }

        return contacts.filter {
            guard let user = $0.user else {
                return true
            }
            return !filteredParticipants.contains(user)
        }
    }

    private func apps(
        _ apps: [any UserType],
        excludingParticipantsOf filterConversation: ZMConversation?
    ) -> [any UserType] {
        guard let filteredParticipants = filterConversation?.localParticipants else {
            return apps
        }

        return apps
            .compactMap { $0 as? ZMUser }
            .filter { !filteredParticipants.contains($0) }
    }

    private func teamMembersAndContacts(
        teamMembers: [ZMSearchUser],
        contacts: [ZMSearchUser]
    ) -> [ZMSearchUser] {
        guard shouldIncludeGuests else {
            return teamMembers
        }

        return Set(teamMembers + contacts).sorted {
            let name0 = $0.name ?? ""
            let name1 = $1.name ?? ""

            if name0 == name1 {
                let pseudo0 = $0.handle ?? ""
                let pseudo1 = $1.handle ?? ""
                return pseudo0.compare(pseudo1) == .orderedAscending
            }
            return name0.compare(name1) == .orderedAscending
        }
    }
}
