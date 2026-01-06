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

import WireLogging
import WireUtilities

/// Sync related logs

public extension LogAttributes {

    private enum Constants {
        static let initial = "initial"
        static let incremental = "incremental"
        /// legacy sync
        static let v1 = "v1"
        /// new sync
        static let v2 = "v2"
        /// consumable-notifications sync
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
            .syncType: initialSync ? Constants.initial : Constants.incremental,
            .syncVersion: Constants.v1,
            .public: true
        ]
    }

    static func legacySyncDidFinishAttributes(
        duration: String,
        initialSync: Bool
    ) -> Self {
        [
            .syncType: initialSync ? Constants.initial : Constants.incremental,
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
            .syncType: initialSync ? Constants.initial : Constants.incremental,
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
            .syncType: initialSync ? Constants.initial : Constants.incremental,
            .syncVersion: Constants.v1,
            .syncPhase: phase,
            .duration: duration,
            .public: true
        ]
    }

    static var incrementalSync: Self {
        [
            .syncType: Constants.incremental,
            .public: true
        ]
    }

    static var initialSync: Self {
        [
            .syncType: Constants.initial
        ]
    }

    // MARK: - New sync (V2, V3)

    static var incrementalSyncV3: Self {
        [
            .syncType: Constants.incremental,
            .syncVersion: Constants.v3,
            .public: true
        ]
    }

    static var incrementalSyncV2: Self {
        [
            .syncType: Constants.incremental,
            .syncVersion: Constants.v2,
            .public: true
        ]
    }

    static func initialSyncAttributes(
        _ phase: String
    ) -> Self {
        [
            .syncType: Constants.initial,
            .syncPhase: phase,
            .public: true
        ]
    }

}

extension LogAttributes {
    static func + (lhs: LogAttributes, rhs: LogAttributes) -> LogAttributes {
        [lhs, rhs].reduce(into: [:]) { result, dict in
            result.merge(dict) { _, new in new }
        }
    }
}
