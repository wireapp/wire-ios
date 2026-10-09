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
import WireFoundation
import WireNetwork

/// Tracks conference participation across notification events using app-group preferences.
struct AnsweredElsewhereCallTracker {
    private struct Marker: Codable {
        let conferenceTimestamp: String?
        let recordedAt: Date
    }

    private static let lock = NSLock()
    private static let maximumAge: TimeInterval = 24 * 60 * 60

    let userDefaults: UserDefaults

    /// Records a self `CONFSTART`, clears markers on an unmatched incoming start, and consumes one on `CONFEND`.
    /// - Returns: `true` when the end event consumes a recent participation marker.
    func track(
        callContent: CallContent,
        conversationID: ConversationID,
        accountID: UUID,
        isCallerSelf: Bool
    ) -> Bool {
        guard callContent.type == CallContent.CallType.confStart ||
            callContent.type == CallContent.CallType.confEnd else { return false }

        let key = AnsweredElsewhereCallKey.make(accountID: accountID, conversationID: conversationID.id)
        Self.lock.lock()
        defer { Self.lock.unlock() }

        if callContent.type == CallContent.CallType.confStart {
            if isCallerSelf {
                let marker = Marker(conferenceTimestamp: callContent.conferenceTimestamp, recordedAt: .now)
                userDefaults.set(try? JSONEncoder().encode(marker), forKey: key)
            } else if callContent.isIncomingCall,
                      let marker = readMarker(forKey: key) {
                let oldTimestamp = marker.conferenceTimestamp
                let newTimestamp = callContent.conferenceTimestamp
                if oldTimestamp == nil || newTimestamp == nil || oldTimestamp != newTimestamp {
                    userDefaults.removeObject(forKey: key)
                }
            }
            return false
        }

        let marker = readMarker(forKey: key)
        userDefaults.removeObject(forKey: key)
        guard let marker else { return false }
        return Date.now.timeIntervalSince(marker.recordedAt) <= Self.maximumAge
    }

    private func readMarker(forKey key: String) -> Marker? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Marker.self, from: data)
    }
}
