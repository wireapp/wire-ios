////
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

// sourcery: AutoMockable
public protocol MessageDependencyResolverInterface {
    func waitForDependenciesToResolve(for message: any SendableMessage) async -> Swift.Result<Void, MessageDependencyResolverError>
}

public enum MessageDependencyResolverError: Error, Equatable {
    case securityLevelDegraded
}

public class MessageDependencyResolver: MessageDependencyResolverInterface {

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    let context: NSManagedObjectContext

    public func waitForDependenciesToResolve(for message: any SendableMessage) async -> Swift.Result<Void, MessageDependencyResolverError> {

        @Sendable func dependenciesAreResolved() -> Swift.Result<Bool, MessageDependencyResolverError> {
            if (self.context.performAndWait {
                message.conversation?.securityLevel == .secureWithIgnored
            }) {
                return .failure(MessageDependencyResolverError.securityLevelDegraded)
            }

            let hasDependencies = self.context.performAndWait {
                message.dependentObjectNeedingUpdateBeforeProcessing != nil
            }

            if !hasDependencies {
                WireLogger.messaging.debug("Message dependency resolved")
                return .success(true)
            } else {
                WireLogger.messaging.debug("Message has dependency, waiting")
                return .success(false)
            }
        }

        let result = dependenciesAreResolved()
        let continueWaiting = result.isOne(of: .success(false))

        if !continueWaiting {
            return result.map { _ in Void() }
        }

        return await withCheckedContinuation { continuation in
            Task {
                let result = dependenciesAreResolved()
                let continueWaiting = result.isOne(of: .success(false))

                if !continueWaiting {
                    continuation.resume(returning: result.map({ _ in Void() }))
                    return
                }

                for await _ in NotificationCenter.default.notifications(named: .requestAvailableNotification) {
                    let result = dependenciesAreResolved()
                    let continueWaiting = result.isOne(of: .success(false))

                    if !continueWaiting {
                        continuation.resume(returning: result.map({ _ in Void() }))
                        break
                    }
                }
            }
        }
    }
}
