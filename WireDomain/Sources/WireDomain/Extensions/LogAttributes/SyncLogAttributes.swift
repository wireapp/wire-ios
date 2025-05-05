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
    
    // NSE
    static let newNSE = [LogAttributesKey.nse: "new"]
    static let legacyNSE = [LogAttributesKey.nse: "legacy"]
    
    // Sync types
    static let initialSync = [LogAttributesKey.syncType: "initial"]
    static let incrementalSync = [LogAttributesKey.syncType: "incremental"]
    
    // Sync versions
    static let syncV1 = [LogAttributesKey.syncVersion: "v1"]
    static let syncV2 = [LogAttributesKey.syncVersion: "v2"]
    static let syncV3 = [LogAttributesKey.syncVersion: "v3"]
    
    // MARK: - Legacy sync (V1)
    
    static func legacySyncDidStartAttributes(
        initialSync: Bool
    ) -> Self {
        baseLegacySyncAttributes(initialSync: initialSync)
    }
    
    static func legacySyncDidFinishAttributes(
        duration: String,
        initialSync: Bool
    ) -> Self {
        merge(
            baseLegacySyncAttributes(initialSync: initialSync),
            [.duration: duration]
        )
    }
    
    static func legacySyncPhaseDidStartAttributes(
        _ phase: String,
        initialSync: Bool
    ) -> Self {
        merge(
            baseLegacySyncAttributes(initialSync: initialSync),
            [.syncPhase: phase]
        )
    }
    
    static func legacySyncPhaseDidCompleteAttributes(
        _ phase: String,
        duration: String,
        initialSync: Bool
    ) -> Self {
        merge(
            baseLegacySyncAttributes(initialSync: initialSync),
            [.syncPhase: phase, .duration: duration]
        )
    }
    
    private static func baseLegacySyncAttributes(
        initialSync: Bool
    ) -> Self {
        merge(
            initialSync ? .initialSync : .incrementalSync,
            .syncV1,
            .safePublic
        )
    }
    
    // MARK: - New sync (V2, V3)
    
    static func newSyncAttributes(
        initialSync: Bool
    ) -> Self {
        baseNewSyncAttributes(initialSync: initialSync)
    }
    
    static func newSyncPhaseAttributes(
        _ phase: String,
        initialSync: Bool
    ) -> Self {
        merge(
            baseNewSyncAttributes(initialSync: initialSync),
            [.syncPhase: phase]
        )
    }
    
    private static func baseNewSyncAttributes(
        initialSync: Bool
    ) -> Self {
        let version = DeveloperFlag.asyncStreamNotifications.isOn ? syncV3 : syncV2
        return merge(
            initialSync ? .initialSync : .incrementalSync,
            version,
            .safePublic
        )
    }
}

private extension LogAttributes {
    static func merge(_ attributes: Self...) -> Self {
        attributes.reduce(into: Self()) { result, dict in
            result.merge(dict) { _, new in new }
        }
    }
}
