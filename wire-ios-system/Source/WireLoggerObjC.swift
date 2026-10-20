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

import CoreData
import Foundation
import WireLogging

/// Class to proxy WireLogger methods to Objective-C
@objcMembers
public final class WireLoggerObjC: NSObject {

    static func assertionDumpLog(_ message: String) {
        WireLogger.system.critical(message, attributes: .safePublic)
    }

    @objc(logReceivedUpdateEventWithId:)
    static func logReceivedUpdateEvent(eventId: String) {
        WireLogger.updateEvent.info("received event", attributes: [.eventId: eventId], .safePublic)
    }

    @objc(logSaveCoreDataError:)
    static func logSaveCoreData(error: any Error) {
        WireLogger.localStorage.error("Failed to save: \(error)", attributes: .safePublic)
    }

    /// Logs every object found for what should have been a unique identity lookup, so support can
    /// confirm from the logs alone (without needing a customer's database) that duplicate rows -
    /// rather than something else - caused a given symptom. Only reads attributes that are safe to
    /// share externally: the entity name, `primaryKey`, the looked-up `remoteIdentifier`, and `domain`.
    /// Returns the combined details so the caller can include them in the crash message / assertion dump.
    @objc(logDuplicateManagedObjectsWithEntityName:remoteIdentifier:objects:)
    static func logDuplicateManagedObjects(
        entityName: String,
        remoteIdentifier: String,
        objects: [NSManagedObject]
    ) -> String {
        let summary = "Found \(objects.count) \(entityName) objects for remoteIdentifier \(remoteIdentifier) where at most 1 was expected"
        WireLogger.localStorage.error(summary, attributes: .safePublic)
        var lines = [summary]

        for object in objects {
            let attributes = object.entity.attributesByName
            let primaryKey = attributes["primaryKey"] != nil ?
                (object.value(forKey: "primaryKey") as? String ?? "<nil>") : "<n/a>"
            let domain = attributes["domain"] != nil ? (object.value(forKey: "domain") as? String ?? "<nil>") : "<n/a>"

            let line = "Duplicate object entity=\(entityName) primaryKey=\(primaryKey) remoteIdentifier=\(remoteIdentifier) domain=\(domain)"
            WireLogger.localStorage.error(line, attributes: .safePublic)
            lines.append(line)
        }

        return lines.joined(separator: "; ")
    }
}
