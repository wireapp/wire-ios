//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct PullResourcesSync: PullResourcesSyncProtocol {

    private let pullSelfUserSync: any PullSelfUserSyncProtocol
    private let pullSelfTeamSync: any PullSelfTeamSyncProtocol
    private let pullSelfTeamRolesSync: any PullSelfTeamRolesSyncProtocol
    private let pullSelfTeamMembersSync: any PullSelfTeamMembersSyncProtocol
    private let pullSelfLegalholdInfoSync: any PullSelfLegalholdInfoSyncProtocol
    private let pullUserConnectionsSync: any PullUserConnectionsSyncProtocol
    private let pullAllConversationsSync: any PullAllConversationsSyncProtocol
    private let pullKnownUsersSync: any PullKnownUsersSyncProtocol
    private let pullConversationLabelsSync: any PullConversationLabelsSyncProtocol
    private let pullAllFeatureConfigsSync: any PullAllFeatureConfigsSyncProtocol

    private let logger = WireLogger(tag: "pull-resources")

    init(
        pullSelfUserSync: any PullSelfUserSyncProtocol,
        pullSelfTeamSync: any PullSelfTeamSyncProtocol,
        pullSelfTeamRolesSync: any PullSelfTeamRolesSyncProtocol,
        pullSelfTeamMembersSync: any PullSelfTeamMembersSyncProtocol,
        pullSelfLegalholdInfoSync: any PullSelfLegalholdInfoSyncProtocol,
        pullUserConnectionsSync: any PullUserConnectionsSyncProtocol,
        pullAllConversationsSync: any PullAllConversationsSyncProtocol,
        pullKnownUsersSync: any PullKnownUsersSyncProtocol,
        pullConversationLabelsSync: any PullConversationLabelsSyncProtocol,
        pullAllFeatureConfigsSync: any PullAllFeatureConfigsSyncProtocol
    ) {
        self.pullSelfUserSync = pullSelfUserSync
        self.pullSelfTeamSync = pullSelfTeamSync
        self.pullSelfTeamRolesSync = pullSelfTeamRolesSync
        self.pullSelfTeamMembersSync = pullSelfTeamMembersSync
        self.pullSelfLegalholdInfoSync = pullSelfLegalholdInfoSync
        self.pullUserConnectionsSync = pullUserConnectionsSync
        self.pullAllConversationsSync = pullAllConversationsSync
        self.pullKnownUsersSync = pullKnownUsersSync
        self.pullConversationLabelsSync = pullConversationLabelsSync
        self.pullAllFeatureConfigsSync = pullAllFeatureConfigsSync
    }

    func pull() async throws {
        try await logger.measureTime(label: "pull resources") {
            let teamID = try await pullSelfUser()

            if let teamID {
                try await pullSelfTeam(teamID: teamID)
                try await pullSelfTeamRoles(teamID: teamID)
                try await pullSelfTeamMembers(teamID: teamID)
                try await pullSelfLegalholdInfo(teamID: teamID)
            }

            try await pullUserConnections()
            try await pullAllConversations()

            // Pulling known users must happen after we've discovered
            // user ids from user connections and conversations.
            try await pullKnownUsers()

            try await pullConversationLabels()
            try await pullFeatureConfigs()
        }
    }

    private func pullSelfUser() async throws -> UUID? {
        do {
            logger.debug("pulling self user")
            return try await pullSelfUserSync.pull().teamID
        } catch {
            throw Failure(resourceName: "pull self user", reason: error)
        }
    }

    private func pullSelfTeam(teamID: UUID) async throws {
        do {
            logger.debug("pulling self team")
            try await pullSelfTeamSync.pull(selfTeamID: teamID)
        } catch {
            throw Failure(resourceName: "pull self team", reason: error)
        }
    }

    private func pullSelfTeamRoles(teamID: UUID) async throws {
        do {
            logger.debug("pulling self team roles")
            try await pullSelfTeamRolesSync.pull(selfTeamID: teamID)
        } catch {
            throw Failure(resourceName: "pull self team roles", reason: error)
        }
    }

    private func pullSelfTeamMembers(teamID: UUID) async throws {
        do {
            logger.debug("pulling self members")
            try await pullSelfTeamMembersSync.pull(selfTeamID: teamID)
        } catch {
            throw Failure(resourceName: "pull self team members", reason: error)
        }
    }

    private func pullSelfLegalholdInfo(teamID: UUID) async throws {
        do {
            logger.debug("pulling self legalhold info")
            try await pullSelfLegalholdInfoSync.pull(selfTeamID: teamID)
        } catch {
            throw Failure(resourceName: "pull self legal hold info", reason: error)
        }
    }

    private func pullUserConnections() async throws {
        do {
            logger.debug("pulling user connections")
            try await pullUserConnectionsSync.pull()
        } catch {
            throw Failure(resourceName: "pull user connections", reason: error)
        }
    }

    private func pullAllConversations() async throws {
        do {
            logger.debug("pulling conversations")
            try await pullAllConversationsSync.pull()
        } catch {
            throw Failure(resourceName: "pull conversations", reason: error)
        }
    }

    private func pullKnownUsers() async throws {
        do {
            logger.debug("pulling known users")
            try await pullKnownUsersSync.pull()
        } catch {
            throw Failure(resourceName: "pull known users", reason: error)
        }
    }

    private func pullConversationLabels() async throws {
        do {
            logger.debug("pulling conversation labels")
            try await pullConversationLabelsSync.pull()
        } catch {
            throw Failure(resourceName: "pull conversation labels", reason: error)
        }
    }

    private func pullFeatureConfigs() async throws {
        do {
            logger.debug("pulling feature configs")
            try await pullAllFeatureConfigsSync.pull()
        } catch {
            throw Failure(resourceName: "pull feature configs", reason: error)
        }
    }

}

extension PullResourcesSync {

    struct Failure: Error {

        let resourceName: String
        let reason: any Error

        var description: String {
            "Failed to sync resource '\(resourceName)': \(reason)"
        }

    }

}
