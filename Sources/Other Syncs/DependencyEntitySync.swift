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

@objc public protocol DependencyEntity: class {
    @objc var dependentObjectNeedingUpdateBeforeProcessing : NSObject? { get }
    @objc var isExpired: Bool { get }
    @objc func expire()
}

public class DependencyEntitySync<Transcoder : EntityTranscoder> : NSObject, ZMContextChangeTracker, ZMRequestGenerator  where Transcoder.Entity : DependencyEntity {
    
    private var entitiesWithDependencies : DependentObjects<Transcoder.Entity, NSObject> = DependentObjects()
    private var entitiesWithoutDependencies : [Transcoder.Entity] = []
    private weak var transcoder : Transcoder?
    private var context : NSManagedObjectContext
    
    public init(transcoder: Transcoder, context : NSManagedObjectContext) {
        self.transcoder = transcoder
        self.context = context
    }
    
    public func expireEntities(withDependency dependency: NSObject) {
        for entity in entitiesWithDependencies.dependents(on: dependency) {
            entity.expire()
        }
    }
    
    public func synchronize(entity: Transcoder.Entity) {
        if let dependency = entity.dependentObjectNeedingUpdateBeforeProcessing {
            entitiesWithDependencies.add(dependency: dependency, for: entity)
        } else {
            entitiesWithoutDependencies.append(entity)
        }
    }
    
    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        for object in objects {
            for entity in entitiesWithDependencies.dependents(on: object) {
                let newDependency = entity.dependentObjectNeedingUpdateBeforeProcessing
                
                if let newDependency = newDependency, newDependency != object {
                    entitiesWithDependencies.add(dependency: newDependency, for: entity)
                } else if newDependency == nil {
                    entitiesWithDependencies.remove(dependency: object, for: entity)
                    entitiesWithoutDependencies.append(entity)
                }
            }
        }
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        guard let entity = entitiesWithoutDependencies.first else { return nil }
        
        entitiesWithoutDependencies.removeFirst()
    
        if !entity.isExpired, let request = transcoder?.request(forEntity: entity) {
            
            request.add(ZMCompletionHandler(on: context, block: { [weak self] (response) in
                guard
                    let `self` = self,
                    let transcoder = self.transcoder else { return }
                
                if response.result == .permanentError {
                    let retry = transcoder.shouldTryToResend(entity: entity, afterFailureWithResponse: response)
                    
                    if retry {
                        self.synchronize(entity: entity)
                    }
                } else {
                    transcoder.request(forEntity: entity, didCompleteWithResponse: response)
                }
            }))
            
            return request
        } else {
            return nil
        }
    }
    
    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return nil
    }
    
    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        
    }
    
}
