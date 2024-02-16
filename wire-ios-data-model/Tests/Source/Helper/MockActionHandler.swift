//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class MockActionHandler<T: EntityAction>: EntityActionHandler {

    typealias Action = T

    var results: [Result<Action.Result, Action.Failure>]
    var token: Any?
    var didPerformAction: Bool {
        return results.isEmpty
    }
    var performedActions: [Action] = []

    init(results: [Result<Action.Result, Action.Failure>], context: NotificationContext) {
        self.results = results
        token = Action.registerHandler(self, context: context)
    }

    convenience init(result: Result<Action.Result, Action.Failure>, context: NotificationContext) {
        self.init(results: [result], context: context)
    }

    func performAction(_ action: Action) {
        var action = action
        if let result = results.first {
            action.notifyResult(result)
            performedActions.append(action)
            results.removeFirst()
        }
    }

}
