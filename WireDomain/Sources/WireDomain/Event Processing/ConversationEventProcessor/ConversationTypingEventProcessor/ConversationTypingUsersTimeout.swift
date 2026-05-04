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

import WireDataModel

/// Keeping track of typing users timeouts
final class ConversationTypingUsersTimeout: NSObject, ZMTimerClient {

    struct Key: Hashable {
        let userObjectID: NSManagedObjectID
        let conversationObjectID: NSManagedObjectID
    }

    static let defaultTimeout: TimeInterval = 60

    private var timeouts = [Key: Date]()
    private var nextPruneDate: Date?
    private var expirationTimer: ZMTimer?

    typealias VoidClosure = () async -> Void
    var timerFiredCallback: VoidClosure?

    var firstTimeout: Date? {
        timeouts.values.min()
    }

    func add(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID,
        withTimeout timeout: Date
    ) {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        timeouts[key] = timeout
    }

    func remove(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID
    ) {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        timeouts.removeValue(forKey: key)
    }

    func contains(
        _ user: NSManagedObjectID,
        for conversation: NSManagedObjectID
    ) -> Bool {
        let key = Key(userObjectID: user, conversationObjectID: conversation)
        return timeouts[key] != nil
    }

    func userIds(
        in conversation: NSManagedObjectID
    ) -> Set<NSManagedObjectID> {
        let userIds = timeouts.keys
            .filter { $0.conversationObjectID == conversation }
            .map(\.userObjectID)

        return Set(userIds)
    }

    func pruneConversationsThatHaveTimoutBefore(
        date pruneDate: Date
    ) -> Set<NSManagedObjectID> {
        let keysToRemove = timeouts
            .filter { $0.value < pruneDate }
            .keys

        keysToRemove.forEach {
            timeouts.removeValue(forKey: $0)
        }

        return Set(keysToRemove.map(\.conversationObjectID))
    }

    /// Updates next prune date and fire a timer at that specific date.
    /// When timer fires, the provided callback will be called - see `timerDidFire`

    func updateExpirationIfNeeded() {
        guard
            let date = firstTimeout,
            date != nextPruneDate
        else {
            return
        }

        expirationTimer?.cancel()
        expirationTimer = ZMTimer(target: self)
        expirationTimer?.fire(at: date)
        nextPruneDate = date
    }

    func timerDidFire(_ timer: ZMTimer!) {
        guard timer === expirationTimer else {
            return
        }

        Task { [timerFiredCallback] in
            await timerFiredCallback?()
        }
    }
}
