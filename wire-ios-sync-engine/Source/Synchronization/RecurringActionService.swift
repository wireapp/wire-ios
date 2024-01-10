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
import WireUtilities

struct RecurringAction {

    let id: String
    let interval: TimeInterval
    let perform: () -> Void

    func callAsFunction() {
        perform()
    }
}

// sourcery: AutoMockable
protocol RecurringActionServiceInterface {
    func performActionsIfNeeded()
    func registerAction(_ action: RecurringAction)
}

final class RecurringActionService: RecurringActionServiceInterface {

    private var actions = [RecurringAction]()
    private let storage: UserDefaults
    private let dateProvider: DateProviding

    public init(
        storage: UserDefaults,
        dateProvider: DateProviding
    ) {
        self.storage = storage
        self.dateProvider = dateProvider
    }

    public func performActionsIfNeeded() {
        let now = dateProvider.now
        actions.forEach { action in

            let lastActionDate = lastCheckDate(for: action.id) ?? .distantPast
            if (lastActionDate + action.interval) <= now {
                action()
                persistLastCheckDate(for: action.id)
            }
        }
    }

    public func registerAction(_ action: RecurringAction) {
        actions.append(action)
    }

    // MARK: - Helpers

    private func key(for actionID: String) -> String {
        "lastCheckDate_\(actionID)"
    }

    private func lastCheckDate(for actionID: String) -> Date? {
        storage.object(forKey: key(for: actionID)) as? Date
    }

    private func persistLastCheckDate(for actionID: String) {
        storage.set(dateProvider.now, forKey: key(for: actionID))
    }
}
