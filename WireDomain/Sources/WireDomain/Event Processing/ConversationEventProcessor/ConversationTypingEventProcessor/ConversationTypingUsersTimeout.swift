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
import WireDataModel

/// Keeping track of typing users timeouts
final class ConversationTypingUsersTimeout: NSObject, ZMTimerClient, @unchecked Sendable {

    struct Key: Hashable {
        let userObjectID: NSManagedObjectID
        let conversationObjectID: NSManagedObjectID
    }

    static let defaultTimeout: TimeInterval = 60

    // Live events, incremental sync and timer callbacks can access the tracker concurrently.
    private let lock = NSLock()
    private var timeouts = [Key: Date]()
    private var nextPruneDate: Date?
    private var expirationTimer: ZMTimer?

    typealias VoidClosure = () async -> Void
    private var storedTimerFiredCallback: VoidClosure?

    var timerFiredCallback: VoidClosure? {
        get { lock.withLock { storedTimerFiredCallback } }
        set { lock.withLock { storedTimerFiredCallback = newValue } }
    }

    var firstTimeout: Date? {
        lock.withLock { timeouts.values.min() }
    }

    func add(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID,
        withTimeout timeout: Date
    ) {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        lock.withLock { timeouts[key] = timeout }
    }

    func remove(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID
    ) {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        lock.withLock { _ = timeouts.removeValue(forKey: key) }
    }

    func contains(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID
    ) -> Bool {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        return lock.withLock { timeouts[key] != nil }
    }

    func userIds(
        in conversation: NSManagedObjectID
    ) -> Set<NSManagedObjectID> {
        lock.withLock {
            let userIds = timeouts.keys
                .filter { $0.conversationObjectID == conversation }
                .map(\.userObjectID)

            return Set(userIds)
        }
    }

    func pruneConversationsThatHaveTimoutBefore(
        date pruneDate: Date
    ) -> Set<NSManagedObjectID> {
        lock.withLock {
            let keysToRemove = timeouts
                .filter { $0.value < pruneDate }
                .keys

            keysToRemove.forEach {
                timeouts.removeValue(forKey: $0)
            }

            return Set(keysToRemove.map(\.conversationObjectID))
        }
    }

    /// Updates next prune date and fire a timer at that specific date.
    /// When timer fires, the provided callback will be called - see `timerDidFire`

    func updateExpirationIfNeeded() {
        lock.withLock {
            guard
                let date = timeouts.values.min(),
                date != nextPruneDate
            else {
                return
            }

            expirationTimer?.cancel()
            expirationTimer = ZMTimer(target: self)
            expirationTimer?.fire(at: date)
            nextPruneDate = date
        }
    }

    func timerDidFire(_ timer: ZMTimer!) {
        guard lock.withLock({ timer === expirationTimer }) else {
            return
        }

        Task { [self] in
            await timerFiredCallback?()
        }
    }
}
