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
public struct CallNotificationCallerTracker {

    private struct Entry: Codable {
        let callerID: UUID
        let callerDomain: String
        let conferenceTimestamp: String?
        let recordedAt: Date
        var endedEventTimestamp: Date?

        var caller: UserID {
            UserID(id: callerID, domain: callerDomain)
        }
    }

    private static let storageKey = "callNotificationCallers"
    private static let lock = NSLock()
    private static let maximumAge: TimeInterval = 24 * 60 * 60

    let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        userDefaults.removeObject(forKey: Self.storageKey)
    }

    public func markEnded(data: Data, conversationID: UUID, accountID: UUID, eventTimestamp: Date, now: Date) {
        guard let content = try? JSONDecoder().decode(CallContent.self, from: data),
              content.type == CallContent.CallType.confEnd else { return }

        Self.lock.lock()
        defer { Self.lock.unlock() }
        let key = key(conversationID: conversationID, accountID: accountID)
        guard var entry = readEntry(forKey: key, now: now) else { return }
        // Keep attribution available if the NSE handles the same end event concurrently.
        entry.endedEventTimestamp = eventTimestamp
        userDefaults.set(try? JSONEncoder().encode(entry), forKey: key)
    }

    func track(
        callContent: CallContent,
        conversationID: UUID,
        accountID: UUID,
        senderID: UserID,
        isCallerSelf: Bool,
        eventTimestamp: Date?,
        now: Date
    ) -> UserID? {
        guard callContent.type == CallContent.CallType.confStart ||
            callContent.type == CallContent.CallType.confEnd else { return nil }

        Self.lock.lock()
        defer { Self.lock.unlock() }
        let key = key(conversationID: conversationID, accountID: accountID)
        let existing = readEntry(forKey: key, now: now)
        if callContent.type == CallContent.CallType.confEnd {
            userDefaults.removeObject(forKey: key)
            guard existing?.endedEventTimestamp == nil || existing?.endedEventTimestamp == eventTimestamp else {
                return nil
            }
            return existing?.caller
        }
        guard !isCallerSelf else {
            userDefaults.removeObject(forKey: key)
            return nil
        }
        guard callContent.isIncomingCall else { return nil }
        if let existing, existing.endedEventTimestamp == nil,
           let timestamp = callContent.conferenceTimestamp, existing.conferenceTimestamp == timestamp {
            return nil
        }
        let entry = Entry(
            callerID: senderID.id,
            callerDomain: senderID.domain,
            conferenceTimestamp: callContent.conferenceTimestamp,
            recordedAt: now
        )
        userDefaults.set(try? JSONEncoder().encode(entry), forKey: key)
        return nil
    }

    private func key(conversationID: UUID, accountID: UUID) -> String {
        "\(Self.storageKey).\(accountID.uuidString).\(conversationID.uuidString)"
    }

    private func readEntry(forKey key: String, now: Date) -> Entry? {
        guard let data = userDefaults.data(forKey: key),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              (0 ... Self.maximumAge).contains(now.timeIntervalSince(entry.recordedAt)) else {
            userDefaults.removeObject(forKey: key)
            return nil
        }
        return entry
    }
}
