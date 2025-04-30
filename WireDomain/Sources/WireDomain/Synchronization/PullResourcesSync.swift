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
        try await logger.measureTime(label: "pull resources") {
            let teamID = try await pullSelfUser()
            try await pullSelfUserClients()
            try await pullSelfUserSettings()

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
            try await pullMLSStatus()
        }
    }

    private func pullSelfUser() async throws -> UUID? {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self user")
        ) {
            do {
                return try await pullSelfUserSync.pull().teamID
            } catch {
                throw Failure(resourceName: "pull self user", reason: error)
            }
        }
    }

    private func pullSelfUserClients() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self user clients")
        ) {
            do {
                try await pullSelfUserClientsSync.pull()
            } catch {
                throw Failure(resourceName: "pull self user clients", reason: error)
            }
        }
    }

    private func pullSelfUserSettings() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self user settings")
        ) {
            do {
                try await pullSelfUserSettingsSync.pull()
            } catch {
                throw Failure(resourceName: "pull self user settings", reason: error)
            }
        }
    }

    private func pullSelfTeam(teamID: UUID) async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self team")
        ) {
            do {
                try await pullSelfTeamSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: "pull self team", reason: error)
            }
        }
    }

    private func pullSelfTeamRoles(teamID: UUID) async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self team roles")
        ) {
            do {
                try await pullSelfTeamRolesSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: "pull self team roles", reason: error)
            }
        }
    }

    private func pullSelfTeamMembers(teamID: UUID) async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling self team members")
        ) {
            do {
                try await pullSelfTeamMembersSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: "pull self team members", reason: error)
            }
        }
    }

    private func pullSelfLegalholdInfo(teamID: UUID) async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull self legal hold info")
        ) {
            do {
                try await pullSelfLegalholdInfoSync.pull(selfTeamID: teamID)
            } catch {
                throw Failure(resourceName: "pull self legal hold info", reason: error)
            }
        }
    }

    private func pullUserConnections() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull user connections")
        ) {
            do {
                try await pullUserConnectionsSync.pull()
            } catch {
                throw Failure(resourceName: "pull user connections", reason: error)
            }
        }
    }

    private func pullAllConversations() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull conversations")
        ) {
            do {
                try await pullAllConversationsSync.pull()
            } catch {
                throw Failure(resourceName: "pull conversations", reason: error)
            }
        }
    }

    private func pullKnownUsers() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull known users")
        ) {
            do {
                try await pullKnownUsersSync.pull()
            } catch {
                throw Failure(resourceName: "pull known users", reason: error)
            }
        }
    }

    private func pullConversationLabels() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull conversation labels")
        ) {
            do {
                try await pullConversationLabelsSync.pull()
            } catch {
                throw Failure(resourceName: "pull conversation labels", reason: error)
            }
        }
    }

    private func pullFeatureConfigs() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pull feature configs")
        ) {
            do {
                try await pullAllFeatureConfigsSync.pull()
            } catch {
                throw Failure(resourceName: "pull feature configs", reason: error)
            }
        }
    }

    private func pullMLSStatus() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling MLS status")
        ) {
            do {
                try await pullMLSStatusSync.pull()
            } catch {
                throw Failure(resourceName: "pull MLS status", reason: error)
            }
        }
    }
    
    private func log<T>(
        label: String,
        attributes: LogAttributes,
        block: () async throws -> T?
    ) async throws -> T?  {
        let startMessage = "did start \(label)"
        logger.info(startMessage, attributes: attributes)
        let start = Date.now
        let result = try await block()
        let durationInSeconds = start.timeIntervalSinceNow.magnitude
        var updatedAttributes = attributes
        updatedAttributes[.duration] = String(format: "%.2f", durationInSeconds)
        let completedMessage = "did complete \(label)"
        logger.info(completedMessage, attributes: updatedAttributes)
        return result
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
