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

enum PromotionState: Equatable {
    case idle
    case inProgress
    case succeeded
    case failed
}

@MainActor
final class AdminSelectionViewModel: ObservableObject {

    @Published var searchQuery = ""
    @Published var selectedUser: UserType?
    @Published var promotionState: PromotionState = .idle

    let userSession: UserSession
    private let candidates: [UserType]
    private let onPromote: @MainActor (UserType) async throws -> Void

    var canPromote: Bool {
        switch promotionState {
        case .inProgress:
            false
        default:
            selectedUser != nil
        }
    }

    var filteredCandidates: [UserType] {
        guard !searchQuery.isEmpty else { return candidates }
        let query = searchQuery.lowercased()
        let handleQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
        return candidates.filter {
            ($0.name?.lowercased().contains(query) ?? false) ||
                (!handleQuery.isEmpty && ($0.handle?.lowercased().contains(handleQuery) ?? false))
        }
    }

    init(
        candidates: [UserType],
        userSession: UserSession,
        onPromote: @escaping @MainActor (UserType) async throws -> Void
    ) {
        self.userSession = userSession
        self.onPromote = onPromote
        self.candidates = candidates
    }

    func promote(user: UserType) async {
        promotionState = .inProgress
        do {
            try await onPromote(user)
            promotionState = .succeeded
        } catch {
            promotionState = .failed
        }
    }
}
