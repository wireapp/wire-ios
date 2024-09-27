//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@objc
public enum SyncPhase: Int, CustomStringConvertible, CaseIterable {
    // start here for slow sync
    case fetchingLastUpdateEventID
    case fetchingTeams
    case fetchingTeamMembers
    case fetchingTeamRoles
    case fetchingConnections
    case fetchingConversations
    case fetchingUsers
    case fetchingSelfUser
    case fetchingLegalHoldStatus
    case fetchingLabels
    case fetchingFeatureConfig
    case updateSelfSupportedProtocols
    case evaluate1on1ConversationsForMLS
    // following is quick sync only
    case fetchingMissedEvents
    case done

    // MARK: Public

    public var isLastSlowSyncPhase: Bool {
        self == Self.lastSlowSyncPhase
    }

    public var isSyncing: Bool {
        self != .done
    }

    public var nextPhase: SyncPhase {
        SyncPhase(rawValue: rawValue + 1) ?? .done
    }

    public var description: String {
        switch self {
        case .fetchingLastUpdateEventID:
            "fetchingLastUpdateEventID"
        case .fetchingConnections:
            "fetchingConnections"
        case .fetchingConversations:
            "fetchingConversations"
        case .fetchingTeams:
            "fetchingTeams"
        case .fetchingTeamMembers:
            "fetchingTeamMembers"
        case .fetchingTeamRoles:
            "fetchingTeamRoles"
        case .fetchingUsers:
            "fetchingUsers"
        case .fetchingSelfUser:
            "fetchingSelfUser"
        case .fetchingLegalHoldStatus:
            "fetchingLegalHoldStatus"
        case .fetchingLabels:
            "fetchingLabels"
        case .fetchingFeatureConfig:
            "fetchingFeatureConfig"
        case .updateSelfSupportedProtocols:
            "updateSelfSupportedProtocols"
        case .evaluate1on1ConversationsForMLS:
            "evaluate1on1ConversationsForMLS"
        case .fetchingMissedEvents:
            "fetchingMissedEvents"
        case .done:
            "done"
        }
    }

    // MARK: Internal

    static let lastSlowSyncPhase: SyncPhase = .evaluate1on1ConversationsForMLS
}
