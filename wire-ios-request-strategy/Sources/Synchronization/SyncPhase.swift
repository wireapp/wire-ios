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

@objc public enum SyncPhase: Int, CustomStringConvertible, CaseIterable {

    // start here for slow sync
    case fetchingLastUpdateEventID
    case fetchingTeams
    case fetchingTeamRoles
    case fetchingConnections
    case fetchingConversations
    case fetchingUsers
    case fetchingSelfUser
    case fetchingLegalHoldStatus
    case fetchingLabels
    case fetchingFeatureConfig
    case evaluate1on1ConversationsForMLS
    // following is quick sync only
    case fetchingMissedEvents
    case done

    static let lastSlowSyncPhase: SyncPhase = .evaluate1on1ConversationsForMLS

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
            return "fetchingLastUpdateEventID"
        case .fetchingConnections:
            return "fetchingConnections"
        case .fetchingConversations:
            return "fetchingConversations"
        case .fetchingTeams:
            return "fetchingTeams"
        case .fetchingTeamRoles:
            return "fetchingTeamRoles"
        case .fetchingUsers:
            return "fetchingUsers"
        case .fetchingSelfUser:
            return "fetchingSelfUser"
        case .fetchingLegalHoldStatus:
            return "fetchingLegalHoldStatus"
        case .fetchingLabels:
            return "fetchingLabels"
        case .fetchingFeatureConfig:
            return "fetchingFeatureConfig"
        case .evaluate1on1ConversationsForMLS:
            return "evaluate1on1ConversationsForMLS"
        case .fetchingMissedEvents:
            return "fetchingMissedEvents"
        case .done:
            return "done"
        }
    }
}
