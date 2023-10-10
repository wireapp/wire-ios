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
import WireDataModel

class MLSMessageSync<Message: MLSMessage>: NSObject, ZMContextChangeTrackerSource, ZMRequestGenerator {

    // MARK: - Types

    public typealias OnRequestScheduledHandler = (_ message: Message, _ request: ZMTransportRequest) -> Void

    // MARK: - Properties

    let context: NSManagedObjectContext
    let dependencySync: DependencyEntitySync<Transcoder<Message>>
    let transcoder: Transcoder<Message>

    // MARK: - Life cycle

    init(
        context: NSManagedObjectContext,
        dependencySync: DependencyEntitySync<Transcoder<Message>>? = nil
    ) {
        self.context = context
        self.transcoder = Transcoder(context: context)
        self.dependencySync = dependencySync ?? DependencyEntitySync(
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

        guard let groupID = message.conversation?.mlsGroupID else {
            WireLogger.mls.info("not syncing message b/c no mls group id")
            return
        }

        let mlsService = context.mlsService

        Task {
            await commitPendingProposals(in: groupID, mlsService: mlsService)

            synchronize(entity: message, in: context) { result, response in

                guard
                    let mlsService = mlsService,
                    let error = SendMLSMessageAction.Failure(from: response),
                    error == .mlsStaleMessage
                else {
                    return completion(result, response)
                }

                Task {
                    WireLogger.mls.info("got stale message error when sending message in group (\(groupID.safeForLoggingDescription)). rejoining group and trying again...")
                    await mlsService.fetchAndRepairGroup(with: groupID)
                    self.synchronize(entity: message, in: self.context, completion: completion)
                }
            }

            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }

    }

    private func synchronize(entity: Message, in context: NSManagedObjectContext, completion: @escaping EntitySyncHandler) {
        context.perform { [dependencySync] in
            dependencySync.synchronize(entity: entity, completion: completion)
        }
    }

    private func commitPendingProposals(
        in groupID: MLSGroupID,
        mlsService: MLSServiceInterface?
    ) async {
        guard let mlsService = mlsService else {
            return
        }

        do {
            WireLogger.mls.info("preemptively commiting pending proposals before sending message in group (\(groupID))")
            try await mlsService.commitPendingProposals(in: groupID)
        } catch {
            WireLogger.mls.info("failed: preemptively commiting pending proposals before sending message in group (\(groupID)): \(String(describing: error))")
        }
    }

    func expireMessages(withDependency dependency: NSObject) {
        dependencySync.expireEntities(withDependency: dependency)
    }

}
