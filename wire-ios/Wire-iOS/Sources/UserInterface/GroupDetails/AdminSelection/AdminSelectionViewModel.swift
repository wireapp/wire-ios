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
import WireSyncEngine

@MainActor
final class AdminSelectionViewModel: ObservableObject {

    @Published var searchQuery = ""
    @Published var selectedUser: UserType?

    let userSession: UserSession
    private let candidates: [UserType]
    let onPromote: (UserType) -> Void

    var canPromote: Bool { selectedUser != nil }

    var filteredCandidates: [UserType] {
        guard !searchQuery.isEmpty else { return candidates }
        let query = searchQuery.lowercased()
        // Strip "@" prefix so "@alice" matches handle "alice"
        let handleQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
        return candidates.filter {
            ($0.name?.lowercased().contains(query) ?? false) ||
            (!handleQuery.isEmpty && ($0.handle?.lowercased().contains(handleQuery) ?? false))
        }
    }

    init(
        conversation: ZMConversation,
        userSession: UserSession,
        onPromote: @escaping (UserType) -> Void
    ) {
        self.userSession = userSession
        self.onPromote = onPromote
        self.candidates = conversation.localParticipantsExcludingSelf
            .filter { !$0.isGroupAdmin(in: conversation) }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}
