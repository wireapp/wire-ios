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

import WireLogging
import WireUtilities

/// Sync related logs

public extension LogAttributes {

    private enum Constants {
        static let initial = "initial"
        static let incremental = "incremental"
        static let v1 = "v1"
        static let v2 = "v2"
        static let v3 = "v3"
    }
    
    // MARK: Notification Service Extension
    
    static let newNSE = [
        LogAttributesKey.nse: "new"
    ]
    
    static let legacyNSE = [
        LogAttributesKey.nse: "legacy"
    ]

    // MARK: - Legacy sync (V1)

    static func legacySyncDidStartAttributes(
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: Constants.v1,
            .public: true
        ]
    }

    static func legacySyncDidFinishAttributes(
        duration: String,
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: Constants.v1,
            .duration: duration,
            .public: true
        ]
    }

    static func legacySyncPhaseDidStartAttributes(
        _ phase: String,
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: Constants.v1,
            .syncPhase: phase,
            .public: true
        ]
    }

    static func legacySyncPhaseDidCompleteAttributes(
        _ phase: String,
        duration: String,
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: Constants.v1,
            .syncPhase: phase,
            .duration: duration,
            .public: true
        ]
    }

    // MARK: - New sync (V2, V3)

    static func newSyncAttributes(
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: newSyncVersion,
            .public: true
        ]
    }

    static func newSyncPhaseAttributes(
        _ phase: String,
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial: Constants.incremental,
            .syncVersion: newSyncVersion,
            .syncPhase: phase,
            .public: true
        ]
    }
    
    private static var newSyncVersion: String {
        DeveloperFlag.asyncStreamNotifications.isOn ? Constants.v3 : Constants.v2
    }
}
