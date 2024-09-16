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
import WireFoundation

/// Class to proxy WireLogger methods to Objective-C
@objcMembers
public final class WireLoggerObjc: NSObject {

    static func assertionDumpLog(_ message: String) {
        WireLogger.system.critical(message, attributes: .safePublic)
    }

    @objc(logReceivedUpdateEventWithId:)
    static func logReceivedUpdateEvent(eventId: String) {
        WireLogger.updateEvent.info("received event", attributes: [.eventId: eventId], .safePublic)
    }

    @objc(logSaveCoreDataError:)
    static func logSaveCoreData(error: Error) {
        WireLogger.localStorage.error("Failed to save: \(error)", attributes: .safePublic)
    }
}
