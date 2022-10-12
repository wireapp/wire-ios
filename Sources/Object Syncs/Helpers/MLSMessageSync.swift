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

class MLSMessageSync<Message: MLSMessage>: NSObject, ZMContextChangeTrackerSource, ZMRequestGenerator {

    // MARK: - Types

    public typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

    // MARK: - Properties

    let context: NSManagedObjectContext
    let dependencySync: DependencyEntitySync<Transcoder<Message>>
    let transcoder: Transcoder<Message>

    // MARK: - Life cycle

    init(context: NSManagedObjectContext) {
        self.context = context
        transcoder = Transcoder(context: context)
        dependencySync = DependencyEntitySync(
            transcoder: transcoder,
            context: context
        )

        super.init()
    }

    // MARK: - Change tracker

    var contextChangeTrackers: [ZMContextChangeTracker] {
        return [dependencySync]
    }

    // MARK: - Request generator

    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return dependencySync.nextRequest(for: apiVersion)
    }

    // MARK: - Methods

    func onRequestScheduled(_ handler: @escaping OnRequestScheduledHandler) {
        transcoder.onRequestScheduledHandler = handler
    }

    func sync(_ message: Message, completion: @escaping EntitySyncHandler) {
        guard let mlsController = context.mlsController else {
            Logging.mls.info("not syncing message b/c no mls controller")
            return
        }

        guard let groupID = message.conversation?.mlsGroupID else {
            Logging.mls.info("not syncing message b/c no mls group id")
            return
        }

        Task {
            do {
                Logging.mls.info("preemptively commiting pending proposals before sending message in group (\(groupID))")
                try await mlsController.commitPendingProposals(in: groupID)
            } catch {
                Logging.mls.info("failed: preemptively commiting pending proposals before sending message in group (\(groupID)): \(String(describing: error))")
            }

            context.perform { [dependencySync] in
                dependencySync.synchronize(entity: message, completion: completion)
                RequestAvailableNotification.notifyNewRequestsAvailable(nil)
            }
        }
    }

    func expireMessages(withDependency dependency: NSObject) {
        dependencySync.expireEntities(withDependency: dependency)
    }

}
