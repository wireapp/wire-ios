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
import WireDataModel

public final class MockActionHandler<T: EntityAction>: EntityActionHandler {

    private enum Results {
        case values([Result<Action.Result, Action.Failure>])
        case closure((Action) -> Result<Action.Result, Action.Failure>)
    }

    public typealias Action = T

    private var results: Results
    private var resultClosure: ((Action) -> Result<Action.Result, Action.Failure>)?
    private var token: NSObjectProtocol?

    private let lock = NSRecursiveLock()

    public var performedActions: [Action] = []

    public convenience init(result: Result<Action.Result, Action.Failure>, context: NotificationContext) {
        self.init(results: [result], context: context)
    }

    public init(results: [Result<Action.Result, Action.Failure>], context: NotificationContext) {
        self.results = .values(results)
        self.token = Action.registerHandler(self, context: context)
    }

    public init(context: NotificationContext, results: @escaping (Action) -> Result<Action.Result, Action.Failure>) {
        self.results = .closure(results)
        self.token = Action.registerHandler(self, context: context)
    }

    public func performAction(_ action: Action) {
        // lock to prevent data races accessing `results`.
        lock.lock()
        defer { lock.unlock() }

        var action = action
        switch results {
        case let .values(values):
            if let result = values.first {
                var action = action
                action.notifyResult(result)
                performedActions.append(action)
                var values = values
                values.removeFirst()
                results = .values(values)
            } else {
                assertionFailure("no expected result set")
            }
        case let .closure(closure):
            action.notifyResult(closure(action))
            performedActions.append(action)
        }
    }

}
