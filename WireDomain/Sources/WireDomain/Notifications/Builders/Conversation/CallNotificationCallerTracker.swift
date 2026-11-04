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

import Foundation
import WireNetwork

/// Keeps the first sender of a conference start for a later missed-call notification.
struct CallNotificationCallerTracker {

    private struct Entry: Codable {
        let callerID: UUID
        let callerDomain: String
        let conferenceTimestamp: String?
        let recordedAt: Date

        var caller: UserID {
            UserID(id: callerID, domain: callerDomain)
        }
    }

    private static let storageKey = "callNotificationCallers"
    private static let lock = NSLock()
    private static let maximumAge: TimeInterval = 24 * 60 * 60

    let userDefaults: UserDefaults

    func track(
        callContent: CallContent,
        conversationID: UUID,
        accountID: UUID,
        senderID: UserID,
        now: Date = .now
    ) -> UserID? {
        guard callContent.type == CallContent.CallType.confStart ||
            callContent.type == CallContent.CallType.confEnd else { return nil }

        Self.lock.lock()
        defer { Self.lock.unlock() }
        var entries = userDefaults.data(forKey: Self.storageKey).flatMap {
            try? JSONDecoder().decode([String: Entry].self, from: $0)
        } ?? [:]
        entries = entries.filter { (0 ... Self.maximumAge).contains(now.timeIntervalSince($0.value.recordedAt)) }
        defer {
            if entries.isEmpty {
                userDefaults.removeObject(forKey: Self.storageKey)
            } else if let data = try? JSONEncoder().encode(entries) {
                userDefaults.set(data, forKey: Self.storageKey)
            }
        }

        let key = "\(accountID.uuidString).\(conversationID.uuidString)"
        if callContent.type == CallContent.CallType.confEnd {
            return entries.removeValue(forKey: key)?.caller
        }
        guard callContent.isIncomingCall else { return nil }
        if let existing = entries[key],
           existing.conferenceTimestamp == callContent.conferenceTimestamp ||
           existing.conferenceTimestamp == nil || callContent.conferenceTimestamp == nil {
            return nil
        }
        entries[key] = Entry(
            callerID: senderID.id,
            callerDomain: senderID.domain,
            conferenceTimestamp: callContent.conferenceTimestamp,
            recordedAt: now
        )
        return nil
    }
}
