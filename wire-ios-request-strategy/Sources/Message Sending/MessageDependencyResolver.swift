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
    func waitForDependenciesToResolve(for message: any SendableMessage) async
}

// swiftlint:disable for_where
public class MessageDependencyResolver: MessageDependencyResolverInterface {

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    let context: NSManagedObjectContext

    public func waitForDependenciesToResolve(for message: any SendableMessage) async {

        @Sendable func dependenciesAreResolved() -> Bool {
            let hasDependencies = self.context.performAndWait {
                message.dependentObjectNeedingUpdateBeforeProcessing != nil
            }

            if !hasDependencies {
                WireLogger.messaging.debug("Message dependency resolved")
                return true
            } else {
                WireLogger.messaging.debug("Message has dependency, waiting")
                return false
            }
        }

        if dependenciesAreResolved() {
            return
        }

        await withCheckedContinuation { continuation in
            Task {
                if dependenciesAreResolved() {
                    continuation.resume()
                    return
                }

                for await _ in NotificationCenter.default.notifications(named: .requestAvailableNotification) {
                    if dependenciesAreResolved() {
                        continuation.resume()
                        break
                    }
                }
            }
        }
    }
}
// swiftlint:enable for_where
