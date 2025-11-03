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
import WireLegacyLogging

struct PullResourcesSync: PullResourcesSyncProtocol {

    private let pullSelfUserSync: any PullSelfUserSyncProtocol
    private let pullSelfUserClientsSync: any PullSelfUserClientsSyncProtocol
    private let pullSelfUserSettingsSync: any PullSelfUserSettingsSyncProtocol
    private let pullSelfTeamSync: any PullSelfTeamSyncProtocol
    private let pullSelfTeamRolesSync: any PullSelfTeamRolesSyncProtocol
    private let pullSelfTeamMembersSync: any PullSelfTeamMembersSyncProtocol
    private let pullSelfLegalholdInfoSync: any PullSelfLegalholdInfoSyncProtocol
    private let pullUserConnectionsSync: any PullUserConnectionsSyncProtocol
    private let pullAllConversationsSync: any PullAllConversationsSyncProtocol
    private let pullKnownUsersSync: any PullKnownUsersSyncProtocol
    private let pullConversationLabelsSync: any PullConversationLabelsSyncProtocol
    private let pullAllFeatureConfigsSync: any PullAllFeatureConfigsSyncProtocol
    private let pullMLSStatusSync: any PullMLSStatusSyncProtocol

    private let logger = WireLogger(tag: "pull-resources")

    init(
        pullSelfUserSync: any PullSelfUserSyncProtocol,
        pullSelfUserClientsSync: any PullSelfUserClientsSyncProtocol,
        pullSelfUserSettingsSync: any PullSelfUserSettingsSyncProtocol,
        pullSelfTeamSync: any PullSelfTeamSyncProtocol,
        pullSelfTeamRolesSync: any PullSelfTeamRolesSyncProtocol,
        pullSelfTeamMembersSync: any PullSelfTeamMembersSyncProtocol,
        pullSelfLegalholdInfoSync: any PullSelfLegalholdInfoSyncProtocol,
        pullUserConnectionsSync: any PullUserConnectionsSyncProtocol,
        pullAllConversationsSync: any PullAllConversationsSyncProtocol,
        pullKnownUsersSync: any PullKnownUsersSyncProtocol,
        pullConversationLabelsSync: any PullConversationLabelsSyncProtocol,
        pullAllFeatureConfigsSync: any PullAllFeatureConfigsSyncProtocol,
        pullMLSStatusSync: any PullMLSStatusSyncProtocol
    ) {
        self.pullSelfUserSync = pullSelfUserSync
        self.pullSelfUserClientsSync = pullSelfUserClientsSync
        self.pullSelfUserSettingsSync = pullSelfUserSettingsSync
        self.pullSelfTeamSync = pullSelfTeamSync
        self.pullSelfTeamRolesSync = pullSelfTeamRolesSync
        self.pullSelfTeamMembersSync = pullSelfTeamMembersSync
        self.pullSelfLegalholdInfoSync = pullSelfLegalholdInfoSync
        self.pullUserConnectionsSync = pullUserConnectionsSync
        self.pullAllConversationsSync = pullAllConversationsSync
        self.pullKnownUsersSync = pullKnownUsersSync
        self.pullConversationLabelsSync = pullConversationLabelsSync
        self.pullAllFeatureConfigsSync = pullAllFeatureConfigsSync
        self.pullMLSStatusSync = pullMLSStatusSync
    }

    func pull() async throws {
        try await pullUserConnections()
        try await pullAllConversations()

        // Pulling known users must happen after we've discovered
        // user ids from user connections and conversations.
        try await pullKnownUsers()

        // Pulling self user must happen after we've pulled known users
        // otherwise some self user values might be overwritten with nil values.
        let teamID = try await pullSelfUser()
        try await pullSelfUserClients()
        try await pullSelfUserSettings()

        if let teamID {
            try await pullSelfTeam(teamID: teamID)
            try await pullSelfTeamRoles(teamID: teamID)
            try await pullSelfTeamMembers(teamID: teamID)
            try await pullSelfLegalholdInfo(teamID: teamID)
        }

        try await pullConversationLabels()
        try await pullFeatureConfigs()
        try await pullMLSStatus()
    }

    private func pullSelfUser() async throws -> UUID? {
        let phase = "pulling self user"

        return try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                return try await pullSelfUserSync.pull().teamID
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfUserClients() async throws {
        let phase = "pulling self user clients"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfUserClientsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfUserSettings() async throws {
        let phase = "pulling self user settings"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfUserSettingsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfTeam(teamID: UUID) async throws {
        let phase = "pulling self team"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfTeamSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfTeamRoles(teamID: UUID) async throws {
        let phase = "pulling self team roles"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfTeamRolesSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfTeamMembers(teamID: UUID) async throws {
        let phase = "pulling self team members"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfTeamMembersSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullSelfLegalholdInfo(teamID: UUID) async throws {
        let phase = "pull self legal hold info"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullSelfLegalholdInfoSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullUserConnections() async throws {
        let phase = "pull user connections"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullUserConnectionsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullAllConversations() async throws {
        let phase = "pull conversations"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullAllConversationsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullKnownUsers() async throws {
        let phase = "pull known users"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullKnownUsersSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullConversationLabels() async throws {
        let phase = "pull conversation labels"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullConversationLabelsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullFeatureConfigs() async throws {
        let phase = "pull feature configs"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullAllFeatureConfigsSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
        }
    }

    private func pullMLSStatus() async throws {
        let phase = "pulling MLS status"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                try await pullMLSStatusSync.pull()
            } catch {
                throw Failure(resourceName: phase, reason: error)
            }
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
