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

struct WireMeetingsMemberRepository: MeetingMemberRepositoryProtocol, @unchecked Sendable {

    let userSession: any UserSession

    @MainActor
    func search(query: String) async throws -> [MeetingMember] {
        guard let searchUsersUseCase = userSession.makeSearchUsersUseCase() else {
            WireLogger.ui.error(
                "userSession.makeSearchUsersUseCase() returned nil, can't search for meeting members",
                attributes: .safePublic
            )
            return []
        }

        let result = await searchUsersUseCase.invoke(
            query: query,
            options: [.contacts, .teamMembers], // in large teams find team members which are not yet known to us
            messageProtocol: .mls // meetings are always mls
        )
        return (result.contacts + result.teamMembers).compactMap { result in
            guard let qualifiedID = result.qualifiedID(localDomain: nil) else { return MeetingMember?.none }
            return MeetingMember(qualifiedID: .init(qualifiedID), name: result.name ?? "", handle: result.handle ?? "")
        }.sorted { $0.name < $1.name }
    }

}
