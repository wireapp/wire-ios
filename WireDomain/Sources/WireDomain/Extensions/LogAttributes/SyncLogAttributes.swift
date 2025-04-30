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
    
    // Sync type
    static let initialSync = [LogAttributesKey.syncType: "initial"]
    static let incrementalSync = [LogAttributesKey.syncType: "incremental"]
    
    // Sync version
    static let syncV1 = [LogAttributesKey.syncVersion: "v1"]
    static let syncV2 = [LogAttributesKey.syncVersion: "v2"]
    static let syncV3 = [LogAttributesKey.syncVersion: "v3"]
    
    // MARK: Sync V1 logging
    
    static func legacySyncDidStartAttributes(
        initialSync: Bool
    ) -> LogAttributes {
        let syncTypeLog: LogAttributes = initialSync ? .initialSync : .incrementalSync
        let syncVersionLog: LogAttributes = .syncV1
        let safePublicLog: LogAttributes = .safePublic
        
        return merge(
            syncTypeLog,
            syncVersionLog,
            safePublicLog
        )
    }
    
    static func legacySyncDidFinishAttributes(
        duration: String,
        initialSync: Bool
    ) -> LogAttributes {
        let syncTypeLog: LogAttributes = initialSync ? .initialSync : .incrementalSync
        let syncVersionLog: LogAttributes = .syncV1
        let syncDuration: LogAttributes = [.duration: duration]
        let safePublicLog: LogAttributes = .safePublic
        
        return merge(
            syncTypeLog,
            syncVersionLog,
            syncDuration,
            safePublicLog
        )
    }
    
    static func legacySyncPhaseDidStartAttributes(
        _ syncPhase: String,
        initialSync: Bool
    ) -> Self {
        let syncTypeLog: LogAttributes = initialSync ? .initialSync : .incrementalSync
        let syncVersionLog: LogAttributes = .syncV1
        let syncPhaseLog: LogAttributes = [.syncPhase: syncPhase]
        let safePublicLog: LogAttributes = .safePublic
        
        return merge(
            syncTypeLog,
            syncVersionLog,
            syncPhaseLog,
            safePublicLog
        )
    }
    
    static func legacySyncPhaseDidCompleteAttributes(
        _ syncPhase: String,
        duration: String,
        initialSync: Bool
    ) -> Self {
        let syncTypeLog: LogAttributes = initialSync ? .initialSync : .incrementalSync
        let syncVersionLog: LogAttributes = .syncV1
        let syncDuration: LogAttributes = [.duration: duration]
        let syncPhaseLog: LogAttributes = [.syncPhase: syncPhase]
        let safePublicLog: LogAttributes = .safePublic
        
        return merge(
            syncTypeLog,
            syncVersionLog,
            syncDuration,
            syncPhaseLog,
            safePublicLog
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
