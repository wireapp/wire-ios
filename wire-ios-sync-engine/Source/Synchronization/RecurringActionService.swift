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

struct RecurringAction {

    typealias Action = () -> Void

    let id: String
    let interval: TimeInterval
    let perform: Action

}

protocol RecurringActionServiceInterface {

    func performActionsIfNeeded()
    func registerAction(_ action: RecurringAction)

}

class RecurringActionService: RecurringActionServiceInterface {

    private var actions = [RecurringAction]()

    public var storage: UserDefaults = .standard

    public func performActionsIfNeeded() {

        actions.forEach { action in

            guard let lastActionDate = lastCheckDate(for: action.id) else {
                persistLastCheckDate(for: action.id)
                return
            }

            if (lastActionDate + action.interval) <= Date() {
                action.perform()
                persistLastCheckDate(for: action.id)
            }

        }
    }

    public func registerAction(_ action: RecurringAction) {
        actions.append(action)
    }

    // MARK: - Helpers

    private func key(for actionID: String) -> String {
        return "lastCheckDate_\(actionID)"
    }

    func lastCheckDate(for actionID: String) -> Date? {
        return storage.object(forKey: key(for: actionID)) as? Date
    }

    func persistLastCheckDate(for actionID: String) {
        storage.set(Date(), forKey: key(for: actionID))
    }

}
