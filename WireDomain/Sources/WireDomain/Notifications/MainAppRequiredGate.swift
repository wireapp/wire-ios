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

struct MainAppRequiredGate {

    static let defaultInterval: TimeInterval = 60 * 60

    private let userDefaults: UserDefaults
    private let interval: TimeInterval

    init(
        userDefaults: UserDefaults,
        interval: TimeInterval = defaultInterval
    ) {
        self.userDefaults = userDefaults
        self.interval = interval
    }

    func markNotified(accountID: UUID, now: Date = .now) {
        let journal = Journal(userID: accountID, storage: userDefaults)
        journal[.mainAppRequiredNotificationLastNotifiedDate] = now
    }

    func shouldNotify(accountID: UUID, now: Date = .now) -> Bool {
        let journal = Journal(userID: accountID, storage: userDefaults)

        guard let lastNotifiedDate = journal[.mainAppRequiredNotificationLastNotifiedDate] else {
            return true
        }

        return now.timeIntervalSince(lastNotifiedDate) >= interval
    }

    static func isMainAppRequiredErrorFoAccount(_ error: any Error) -> UUID? {
        guard let nseUserError = error as? NSEUserScope.Failure,
              case let .mainAppRequired(_, accountID) = nseUserError else {
            return nil
        }

        return accountID
    }
}
