//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// An object that is able to send messages to the backend.
///
/// Each message belongs to a conversation that uses a specific message protocol.
/// This sync ensures that each message is sent to the backend using the appropriate
/// protocol.

public class MessageSync<Message: ProteusMessage & MLSMessage>: NSObject, ZMContextChangeTrackerSource, ZMRequestGenerator {

    public typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

    // MARK: - Properties

    private let proteusMessageSync: ProteusMessageSync<Message>
    private let mlsMessageSync: MLSMessageSync<Message>

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext, appStatus: ApplicationStatus) {
        proteusMessageSync = ProteusMessageSync(
            context: context,
            applicationStatus: appStatus
        )

        mlsMessageSync = MLSMessageSync(context: context)
    }

    // MARK: - Change tracker

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return proteusMessageSync.contextChangeTrackers + mlsMessageSync.contextChangeTrackers
    }

    // MARK: - Request generator

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return [proteusMessageSync, mlsMessageSync].nextRequest(for: apiVersion)
    }

    // MARK: - Methods

    public func onRequestScheduled(_ handler: @escaping OnRequestScheduledHandler) {
        proteusMessageSync.onRequestScheduled(handler)
        mlsMessageSync.onRequestScheduled(handler)
    }

    public func sync(_ message: Message, completion: @escaping EntitySyncHandler) {
        guard let conversation = message.conversation else {
            Logging.messageProcessing.warn("failed to sync message b/c message protocol can't be determined")
            completion(.failure(.messageProtocolMissing), .init())
            return
        }

        switch conversation.messageProtocol {
        case .proteus:
            proteusMessageSync.sync(message, completion: completion)

        case .mls:
            mlsMessageSync.sync(message, completion: completion)
        }
    }

    public func expireMessages(withDependency dependency: NSObject) {
        proteusMessageSync.expireMessages(withDependency: dependency)
        mlsMessageSync.expireMessages(withDependency: dependency)
    }

}
