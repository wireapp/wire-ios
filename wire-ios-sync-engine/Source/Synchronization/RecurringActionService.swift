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

protocol RecurringActionServiceInterface {

    func registerAction(_ action: RecurringAction)
    func performActionsIfNeeded()
    func forcePerformAction(id: String)

}

struct RecurringAction {

    typealias Action = () -> Void

    let id: String
    let interval: TimeInterval
    let perform: Action

}

class RecurringActionService: RecurringActionServiceInterface {

    // MARK: - Properties

    var storage: UserDefaults = .standard
    private(set) var actionsByID = [String: RecurringAction]()

    // MARK: - Methods

    public func registerAction(_ action: RecurringAction) {
        actionsByID[action.id] = action
    }

    public func performActionsIfNeeded() {
        for (id, action) in actionsByID {
            guard let lastActionDate = lastCheckDate(for: id) else {
                persistLastCheckDate(for: id)
                return
            }

            if (lastActionDate + action.interval) <= Date() {
                action.perform()
                persistLastCheckDate(for: id)
            }
        }
    }

    public func forcePerformAction(id: String) {
        guard let action = actionsByID[id] else { return }
        action.perform()
        persistLastCheckDate(for: id)
    }

    // MARK: - Helpers

    private func key(for actionID: String) -> String {
        return "lastCheckDate_\(actionID)"
    }

    private func lastCheckDate(for actionID: String) -> Date? {
        return storage.object(forKey: key(for: actionID)) as? Date
    }

    func persistLastCheckDate(for actionID: String) {
        storage.set(Date(), forKey: key(for: actionID))
    }

}
