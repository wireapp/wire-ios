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
import WireFoundation
import WireUtilities

final class RecurringActionService: RecurringActionServiceInterface {

    private struct LastCheckDateKey: DefaultsKey {

        let actionID: String

        var rawValue: String {
            "lastCheckDate_\(actionID)"
        }

    }

    // MARK: - Properties

    private(set) var actionsByID = [String: RecurringAction]()
    private let storage: PrivateUserDefaults<LastCheckDateKey>
    private let dateProvider: CurrentDateProviding

    public init(
        userID: UUID,
        storage: UserDefaults,
        dateProvider: CurrentDateProviding
    ) {
        self.storage = PrivateUserDefaults(userID: userID, storage: storage)
        self.dateProvider = dateProvider
    }

    // MARK: - Methods

    public func registerAction(_ action: RecurringAction) {
        actionsByID[action.id] = action

        if action.shouldRunEveryLaunch {
            clearLastCheckDate(for: action.id)
        }
    }

    public func performActionsIfNeeded() async {
        let now = dateProvider.now

        for (id, action) in actionsByID {

            let lastActionDate = lastCheckDate(for: action.id) ?? .distantPast

            if (lastActionDate + action.interval) <= now {
                await action()
                persistLastCheckDate(for: id)
            }
        }
    }

    public func forcePerformAction(id: String) async {
        guard let action = actionsByID[id] else { return }
        await action()
        persistLastCheckDate(for: id)
    }

    public func removeAction(id: String) {
        actionsByID.removeValue(forKey: id)
    }

    // MARK: - Helpers

    private func key(for actionID: String) -> LastCheckDateKey {
        LastCheckDateKey(actionID: actionID)
    }

    private func lastCheckDate(for actionID: String) -> Date? {
        storage.object(forKey: key(for: actionID)) as? Date
    }

    func persistLastCheckDate(for actionID: String) {
        storage.set(dateProvider.now, forKey: key(for: actionID))
    }

    private func clearLastCheckDate(for actionID: String) {
        storage.removeObject(forKey: key(for: actionID))
    }
}
