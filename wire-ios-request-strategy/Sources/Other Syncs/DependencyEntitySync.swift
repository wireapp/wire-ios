//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc public protocol DependencyEntity: AnyObject {
    @objc var dependentObjectNeedingUpdateBeforeProcessing: NSObject? { get }
    @objc var isExpired: Bool { get }
    @objc func expire()
    @objc var expirationDate: Date? { get }
    @objc var expirationReasonCode: NSNumber? { get set }
}

public enum EntitySyncError: Error {
    case expired
    case gaveUpRetrying
    case messageProtocolMissing
}

public typealias EntitySyncHandler = (_ result: Swift.Result<Void, EntitySyncError>, _ response: ZMTransportResponse) -> Void

class DependencyEntitySync<Transcoder: EntityTranscoder>: NSObject, ZMContextChangeTracker, ZMRequestGenerator  where Transcoder.Entity: DependencyEntity {

    private var entitiesWithDependencies: DependentObjects<Transcoder.Entity, NSObject> = DependentObjects()
    private var entitiesWithoutDependencies: [Transcoder.Entity] = []
    private var completionHandlers: [Transcoder.Entity: EntitySyncHandler] = [:]
    private weak var transcoder: Transcoder?
    private var context: NSManagedObjectContext

    public init(transcoder: Transcoder, context: NSManagedObjectContext) {
        self.transcoder = transcoder
        self.context = context
    }

    public func expireEntities(withDependency dependency: NSObject) {
        for entity in entitiesWithDependencies.dependents(on: dependency) {
            if let message = entity as? ZMClientMessage {
                WireLogger.messaging.warn("expiring message \(message.debugInfo) with dependency \(String(describing: dependency))")
            }
            entity.expire()
        }
    }

    public func synchronize(entity: Transcoder.Entity, completion: EntitySyncHandler? = nil) {
        completionHandlers[entity] = completion

        if let dependency = entity.dependentObjectNeedingUpdateBeforeProcessing {
            if let message = entity as? (any ProteusMessage) {
                WireLogger.messaging.debug("adding dependency for message \(message.debugInfo): \(String(describing: dependency))")
            }
            entitiesWithDependencies.add(dependency: dependency, for: entity)
        } else {
            if let message = entity as? (any ProteusMessage) {
                WireLogger.messaging.debug("synchronizing without dependencies for message \(message.debugInfo)")
            }
            entitiesWithoutDependencies.append(entity)
        }
    }

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        for object in objects {
            for entity in entitiesWithDependencies.dependents(on: object) {
                let newDependency = entity.dependentObjectNeedingUpdateBeforeProcessing

                if let newDependency = newDependency, newDependency != object {
                    if let message = entity as? (any ProteusMessage) {
                        WireLogger.messaging.debug("adding new dependency for message \(message.debugInfo): \(String(describing: newDependency))")
                    }
                    entitiesWithDependencies.add(dependency: newDependency, for: entity)
                } else if newDependency == nil {
                    if let message = entity as? (any ProteusMessage) {
                        WireLogger.messaging.debug("removing dependencies for message \(message.debugInfo)")
                    }
                    entitiesWithDependencies.removeAllDependencies(for: entity)
                    entitiesWithoutDependencies.append(entity)
                }
            }
        }
    }

    func nextRequest(for apiVersion: APIVersion) async -> ZMTransportRequest? {
        guard let entity = entitiesWithoutDependencies.first else { return nil }

        if let message = entity as? (any ProteusMessage) {
            WireLogger.messaging.debug("generating request for message \(message.debugInfo)")
        }

        entitiesWithoutDependencies.removeFirst()

        let completionHandler = completionHandlers.removeValue(forKey: entity)

        guard !entity.isExpired else {
            if let message = entity as? (any ProteusMessage) {
                WireLogger.messaging.error("dependency sync will not generate a request for message \(message.debugInfo): entity is expired")
            }

            return nil
        }

        guard let request = transcoder?.request(forEntity: entity, apiVersion: apiVersion) else {
            if let message = entity as? (any ProteusMessage) {
                WireLogger.messaging.error("dependency sync could not generate a request for message \(message.debugInfo): transcoder returned nil")
            }

            return nil
        }

        if let message = entity as? (any ProteusMessage) {
            WireLogger.messaging.debug("generated request for message \(message.debugInfo)")
        }

        request.add(ZMCompletionHandler(on: context, block: { [weak self] (response) in
            guard
                let `self` = self,
                let transcoder = self.transcoder
            else {
                if let message = entity as? (any ProteusMessage) {
                    WireLogger.messaging.debug("dependency sync can not process response for message \(message.debugInfo): missing self or transcoder")
                }
                return
            }

            switch response.result {
            case .success:
                if let message = entity as? (any ProteusMessage) {
                    WireLogger.messaging.debug("dependency sync got a success response for message \(message.debugInfo)")
                }
                transcoder.request(forEntity: entity, didCompleteWithResponse: response)
                completionHandler?(.success(()), response)

            case .expired:
                if let message = entity as? (any ProteusMessage) {
                    WireLogger.messaging.error("dependency sync got an expired response for message \(message.debugInfo)")
                }
                completionHandler?(.failure(EntitySyncError.expired), response)

            default:
                let retry = transcoder.shouldTryToResend(entity: entity, afterFailureWithResponse: response)

                if retry {
                    if let message = entity as? (any ProteusMessage) {
                        WireLogger.messaging.warn("dependency sync will retry request for message \(message.debugInfo)")
                    }
                    self.synchronize(entity: entity, completion: completionHandler)
                } else {
                    if let message = entity as? (any ProteusMessage) {
                        WireLogger.messaging.error("dependency sync gave up retrying for message \(message.debugInfo)")
                    }
                    completionHandler?(.failure(EntitySyncError.gaveUpRetrying), response)
                }
            }
        }))

        return request
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return nil
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {

    }

}
