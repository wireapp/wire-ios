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
import WireLogging

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
            try Task.checkCancellation()
            let hasDependencies = try await context.perform {
                guard self.context.zm_isValidContext else { throw MessageOutboxError.staleAttempt }
                if let row = message as? ZMMessage {
                    guard row.managedObjectContext === self.context, !row.isDeleted, !row.hasBeenDeleted else {
                        throw MessageOutboxError.staleAttempt
                    }
                }
                if message.conversation?.legalHoldStatus == .pendingApproval {
                    throw MessageDependencyResolverError.legalHoldPendingApproval
                }
                if message.conversation?.isDegraded == true, !message.shouldIgnoreTheSecurityLevelCheck {
                    throw MessageDependencyResolverError.securityLevelDegraded
                }
                return message.dependentObjectNeedingUpdateBeforeProcessing != nil
            }
            try Task.checkCancellation()

            let logAttributes = await MessageLogAttributesBuilder(context: context).logAttributes(message)

            if !hasDependencies {
                WireLogger.messaging.debug("Message dependency resolved", attributes: logAttributes)
                return true
            } else {
                WireLogger.messaging.debug("Message has dependency, waiting", attributes: logAttributes)
                return false
            }
        }

        // Subscribe before the first snapshot so a dependency resolved during that read is not lost.
        let (wakeups, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let token = NotificationCenter.default.addObserver(
            forName: .requestAvailableNotification, object: nil, queue: nil
        ) { _ in continuation.yield(()) }
        defer {
            NotificationCenter.default.removeObserver(token)
            continuation.finish()
        }
        if try await dependenciesAreResolved() {
            return
        }

        // swiftlint:disable for_where
        for await _ in wakeups {
            if try await dependenciesAreResolved() {
                break
            }
        }
        // swiftlint:enable for_where
        try Task.checkCancellation()
    }
}
