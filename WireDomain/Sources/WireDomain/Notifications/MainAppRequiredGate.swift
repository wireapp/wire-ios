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
    static let lastNotifiedDateKey = "mainAppRequiredNotificationLastNotifiedDate"

    private let userDefaults: UserDefaults
    private let interval: TimeInterval

    init(
        userDefaults: UserDefaults,
        interval: TimeInterval = defaultInterval
    ) {
        self.userDefaults = userDefaults
        self.interval = interval
    }

    func shouldNotify(_ error: any Error, now: Date = .now) -> Bool {
        isMainAppRequiredError(error) && shouldNotify(now: now)
    }

    func shouldNotify(now: Date = .now) -> Bool {
        guard let lastNotifiedDate = userDefaults.object(forKey: Self.lastNotifiedDateKey) as? Date else {
            return true
        }

        return now.timeIntervalSince(lastNotifiedDate) >= interval
    }

    func markNotified(now: Date = .now) {
        userDefaults.set(now, forKey: Self.lastNotifiedDateKey)
    }

    func isMainAppRequiredError(_ error: any Error) -> Bool {
        guard let nseUserError = error as? NSEUserScope.Failure,
              case .mainAppRequired = nseUserError else {
            return false
        }

        return true
    }
}
