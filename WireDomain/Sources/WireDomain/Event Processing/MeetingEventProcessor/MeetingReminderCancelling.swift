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
import WireCallingData
import WireCallingDomain

protocol MeetingReminderCancelling {
    func cancelAll(accountID: UUID, meetingID: WireCallingDomain.QualifiedID) async
}

extension MeetingReminderScheduler: MeetingReminderCancelling {}

/// Allows session management to remove reminders without depending on WireCallingData directly.
public struct AccountMeetingReminderCanceller {

    public init() {}

    public func cancelAll(accountID: UUID) async {
        await MeetingReminderScheduler().cancelAll(accountID: accountID)
    }

    public func cancelAll(exceptAccountIDs accountIDs: Set<UUID>) async {
        await MeetingReminderScheduler().cancelAll(exceptAccountIDs: accountIDs)
    }

}

/// Persists logout cancellation until notification-center removal finishes.
public struct MeetingReminderCancellationJournal {

    private static let key = "pendingMeetingReminderCancellationAccountIDs"
    private static let lock = NSLock()

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    @discardableResult
    public func record(accountID: UUID) -> UUID {
        let token = UUID()
        Self.lock.withLock {
            var entries = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
            entries[accountID.uuidString] = token.uuidString
            defaults.set(entries, forKey: Self.key)
            _ = defaults.synchronize()
        }
        return token
    }

    public func pending() -> [UUID: UUID] {
        Self.lock.withLock {
            let entries = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
            return Dictionary(uniqueKeysWithValues: entries.compactMap { accountID, token in
                guard let accountID = UUID(uuidString: accountID), let token = UUID(uuidString: token) else {
                    return nil
                }
                return (accountID, token)
            })
        }
    }

    public func clear(accountID: UUID, token: UUID) {
        Self.lock.withLock {
            var entries = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
            guard entries[accountID.uuidString] == token.uuidString else { return }
            entries.removeValue(forKey: accountID.uuidString)
            defaults.set(entries, forKey: Self.key)
            _ = defaults.synchronize()
        }
    }

}
