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

import WireCallingDomain
import WireLogging
import WireSyncEngine

struct WireMeetingsMemberRepository: MemberRepositoryProtocol, @unchecked Sendable {

    typealias Member = WireCallingDomain.Member

    var userSession: any UserSession

    @MainActor
    func search(query: String) async throws -> [Member] {
        guard let searchUsersUseCase = userSession.makeSearchUsersUseCase() else {
            WireLogger.ui.error("userSession.makeSearchUsersUseCase() returned nil, can't search for meeting members", attributes: .safePublic)
            return []
        }

        let searchOptions: SearchOptions = [
            .contacts,
            .teamMembers,
            .directory, // TODO: check if enabled? needs to work in a large team
            // .federated // TODO: check if enabled?
        ]

        let result = await searchUsersUseCase.invoke(query: query, options: searchOptions, messageProtocol: .mls) // TODO: meetings always mls?
        return (result.contacts + result.teamMembers).compactMap { result in
            guard let user = result.user, let qualifiedID = user.qualifiedID else { return Member?.none }
            return Member(qualifiedID: .init(qualifiedID), name: user.name ?? "", handle: user.handle ?? "")
        }.sorted { $0.name < $1.name }
    }

}
