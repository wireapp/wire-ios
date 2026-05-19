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
import WireLogging
import WireNetwork

struct TeamMemberDiscoveryAgent: TeamMemberDiscoveryAgentProtocol {

    private let api: any TeamsAPI
    private let store: any TeamLocalStoreProtocol
    private let journal: Journal

    // MARK: - Life cycle

    init(
        api: any TeamsAPI,
        store: any TeamLocalStoreProtocol,
        journal: Journal
    ) {
        self.api = api
        self.store = store
        self.journal = journal
    }

    // MARK: - TeamMemberDiscoveryAgentProtocol

    func discoverMembers() async {
        guard let selfTeamID = await store.selfTeamID() else {
            WireLogger.sync.debug("team member discovery: self user is not in a team")
            return
        }

        let sinceNotificationID = journal[.lastTeamNotificationID].flatMap(UUID.init(uuidString:))
        if let sinceNotificationID { // TODO: delete this logging
            WireLogger.sync.debug("sinceNotificationID: \(sinceNotificationID.uuidString)", attributes: .safePublic)
        } else {
            WireLogger.sync.debug("sinceNotificationID is nil", attributes: .safePublic)
        }

        do {
            let pager = try api.getNotifications(sinceNotificationID: sinceNotificationID)

            var discoveredCount = 0
            for try await notifications in pager {
                // The `since` cursor is inclusive: the backend returns the
                // cursor notification as the first item of the first page.
                // Drop it so we don't re-process what we already stored.
                let newNotifications = notifications.filter { $0.id != sinceNotificationID }

                let teamMembersInfo = newNotifications.map { notification -> TeamMemberInfo in
                    switch notification.kind {
                    case let .memberJoin(event):
                        TeamMemberInfo(
                            id: event.userID,
                            selfPermission: nil,
                            creatorID: nil,
                            creationDate: event.time
                        )
                    }
                }

                guard !teamMembersInfo.isEmpty else { continue }

                try await store.storeTeamMembers(
                    selfTeamID: selfTeamID,
                    teamMembersInfo: teamMembersInfo
                )
                discoveredCount += teamMembersInfo.count

                // Persist forward progress per page so an interruption
                // doesn't force a full re-walk on the next run.
                if let lastID = newNotifications.last?.id {
                    journal[.lastTeamNotificationID] = lastID.uuidString
                }
            }

            WireLogger.sync.debug("team member discovery: stored \(discoveredCount) member(s)")
        } catch {
            WireLogger.sync.error("team member discovery failed: \(String(describing: error))")
        }
    }

}
