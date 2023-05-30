//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct RecurringAction {

    typealias Action = () -> Void

    let id: String
    let interval: TimeInterval
    let perform: Action

}

public protocol RecurringActionServiceInterface {

    func performActionsIfNeeded()
    func registerAction(_ action: RecurringAction)

}

public final class RecurringActionService: NSObject, RecurringActionServiceInterface {

    private var actions = [RecurringAction]()

    public func performActionsIfNeeded() {
        let currentDate = Date()

        actions.forEach { action in

            guard let lastActionDate = lastActionDate(for: action.id) else {
                persistLastActionDate(for: action.id, newDate: currentDate)
                return
            }

            if (lastActionDate + action.interval) <= currentDate {
                action.perform()
                persistLastActionDate(for: action.id, newDate: currentDate)
            }

        }
    }

    public func registerAction(_ action: RecurringAction) {
        actions.append(action)
    }

    // MARK: - Helpers

    func lastActionDate(for actionID: String) -> Date? {
        return userDefaults(for: actionID)?.lastRecurringActionDate
    }

    func persistLastActionDate(for actionID: String, newDate: Date) {
        userDefaults(for: actionID)?.lastRecurringActionDate = newDate
    }

    private func userDefaults(for actionID: String) -> UserDefaults? {
        return UserDefaults(suiteName: "com.wire.recurringAction.\(actionID)")
    }

}

private extension UserDefaults {

    private var lastRecurringActionDateKey: String { "LastRecurringActionDateKey" }

    var lastRecurringActionDate: Date? {

        get {
            return object(forKey: lastRecurringActionDateKey) as? Date
        }

        set {
            set(newValue, forKey: lastRecurringActionDateKey)
        }
    }

}
