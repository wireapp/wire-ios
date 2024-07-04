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

// sourcery: AutoMockable
public protocol MessageDependencyResolverInterface {
    func waitForDependenciesToResolve(for message: any SendableMessage) async throws
}

public enum MessageDependencyResolverError: Error, Equatable {
    case securityLevelDegraded
    case legalHoldPendingApproval
}

public class MessageDependencyResolver: MessageDependencyResolverInterface {

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    let context: NSManagedObjectContext

    public func waitForDependenciesToResolve(for message: any SendableMessage) async throws {

        func dependenciesAreResolved() async throws -> Bool {
            let isSecurityLevelDegraded = await self.context.perform {
                message.conversation?.isDegraded == true
            }

            let shouldIgnoreTheSecurityLevelCheck = await self.context.perform {
                message.shouldIgnoreTheSecurityLevelCheck
            }

            let legalHoldPendingApproval = await self.context.perform {
                message.conversation?.legalHoldStatus == .pendingApproval
            }

            if legalHoldPendingApproval {
                throw MessageDependencyResolverError.legalHoldPendingApproval
            }

            if isSecurityLevelDegraded && !shouldIgnoreTheSecurityLevelCheck {
                throw MessageDependencyResolverError.securityLevelDegraded
            }

            let hasDependencies = await self.context.perform {
                message.dependentObjectNeedingUpdateBeforeProcessing != nil
            }

            let logAttributes = await MessageLogAttributesBuilder(context: context).logAttributes(message)

            if !hasDependencies {
                WireLogger.messaging.debug("Message dependency resolved", attributes: logAttributes)
                return true
            } else {
                WireLogger.messaging.debug("Message has dependency, waiting", attributes: logAttributes)
                return false
            }
        }

        if try await dependenciesAreResolved() {
            return
        }

        // swiftlint:disable for_where
        for await _ in NotificationCenter.default.notifications(named: .requestAvailableNotification) {
            if try await dependenciesAreResolved() {
                break
            }
        }
        // swiftlint:enable for_where
    }
}
