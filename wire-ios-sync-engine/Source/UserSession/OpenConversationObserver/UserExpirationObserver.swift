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

// MARK: - UserExpirationObserver

@objcMembers
public class UserExpirationObserver: NSObject {
    private(set) var expiringUsers: Set<ZMUser> = Set()
    private var timerForUser: [ZMTimer: ZMUser] = [:]
    private let managedObjectContext: NSManagedObjectContext

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    deinit {
        timerForUser.forEach { $0.key.cancel() }
    }

    public func check(usersIn conversation: ZMConversation) {
        check(users: conversation.localParticipants)
    }

    func check(users: Set<ZMUser>) {
        let allWireless = Set(users.filter(\.isWirelessUser)).subtracting(expiringUsers)
        let expired = Set(allWireless.filter(\.isExpired))
        let notExpired = allWireless.subtracting(expired)

        expiringUsers.subtract(expired)

        for item in expired {
            item.needsToBeUpdatedFromBackend = true
        }

        for item in notExpired {
            let timer = ZMTimer(target: self)!
            timer.fire(afterTimeInterval: item.expiresAfter)
            timerForUser[timer] = item
        }

        expiringUsers.formUnion(notExpired)
    }
}

// MARK: ZMTimerClient

extension UserExpirationObserver: ZMTimerClient {
    public func timerDidFire(_ timer: ZMTimer) {
        managedObjectContext.performGroupedBlock {
            guard let user = self.timerForUser[timer] else { fatal("Unknown timer: \(timer)") }
            user.needsToBeUpdatedFromBackend = true
            self.timerForUser[timer] = nil
            self.expiringUsers.remove(user)
        }
    }
}
