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

// MARK: - EntityActionHandler

/// An EntityActionHandler is responsible for performing actions requested by an EntityAction.
///
public protocol EntityActionHandler: AnyObject {
    associatedtype Action

    /// Perform the action represented by Action
    ///
    /// When the action is complete or has failed the EntityActionHandler should
    /// call `notifyResult()` on the action. The EntityActionHandler is expected to
    /// retain the action until this method has been called.
    ///
    func performAction(_ action: Action)
}

// MARK: - EntityAction

/// Represents an action which an entity can request to be performed.
///
public protocol EntityAction {
    associatedtype Result
    associatedtype Failure: Error

    var resultHandler: ResultHandler? { get set }
}

extension EntityAction {
    public typealias ResultHandler = (Swift.Result<Result, Failure>) -> Void

    public static var notificationName: Notification.Name {
        Notification.Name(String(describing: Self.Type.self))
    }

    public static var userInfoKey: String {
        "action"
    }

    /// Request the action to be performed
    public func send(in context: NotificationContext) {
        let notification = NotificationInContext(
            name: Self.notificationName,
            context: context,
            object: nil,
            userInfo: [Self.userInfoKey: self]
        )
        notification.post()
    }

    /// Called by an `EntityActionHandler` when the action has been performed.
    public mutating func notifyResult(_ result: Swift.Result<Result, Failure>) {
        let resultHandler = resultHandler
        self.resultHandler = nil

        DispatchQueue.main.async {
            resultHandler?(result)
        }
    }

    /// Register a result handler which will be called when the action has been performed.
    public mutating func onResult(resultHandler: @escaping ResultHandler) {
        self.resultHandler = resultHandler
    }

    /// Register an action handler
    ///
    /// - parameters:
    ///   - handler: action handler
    ///   - context: context in which to listen for actions
    ///   - queue: queue on which the `performAction()` will be called
    public static func registerHandler<Handler: EntityActionHandler>(
        _ handler: Handler,
        context: NotificationContext,
        queue: OperationQueue? = nil
    ) -> NSObjectProtocol where Handler.Action == Self {
        NotificationInContext.addObserver(
            name: notificationName,
            context: context,
            object: nil,
            queue: queue
        ) { [weak handler] notification in
            guard let action = notification.userInfo[userInfoKey] as? Handler.Action else { return }
            handler?.performAction(action)
        }
    }
}

extension EntityAction {
    /// Notify a success result.
    ///
    /// - Parameter result: The successful result.

    public mutating func succeed(with result: Result) {
        notifyResult(.success(result))
    }

    /// Notify a failed result.
    ///
    /// - Parameter failure: The reason the action failured.

    public mutating func fail(with failure: Failure) {
        notifyResult(.failure(failure))
    }
}

extension EntityAction where Result == Void {
    /// Notify a success result.

    public mutating func succeed() {
        notifyResult(.success(()))
    }
}

// MARK: - Async / Await

extension EntityAction {
    /// Perform the action with the given result handler.
    ///
    /// - Parameters:
    ///   - context the notification context in which to send the action's notification.
    ///   - resultHandler a closure to recieve the action's result.

    @available(*, renamed: "perform(in:)")
    public mutating func perform(
        in context: NotificationContext,
        resultHandler: @escaping ResultHandler
    ) {
        self.resultHandler = resultHandler
        send(in: context)
    }

    /// Perform the action with the given result handler.
    ///
    /// - Parameters:
    ///   - context the notification context in which to send the action's notification.
    ///
    /// - Returns:
    ///   The result of the action.
    ///
    /// - Throws:
    ///   The action's error.

    public mutating func perform(in context: NotificationContext) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            perform(in: context, resultHandler: continuation.resume(with:))
        }
    }
}
