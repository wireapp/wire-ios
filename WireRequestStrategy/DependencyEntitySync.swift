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

fileprivate let zmLog = ZMSLog(tag: "Dependencies")

public protocol DependencyEntity : AnyObject {
    
    var dependentObjectNeedingUpdateBeforeProcessing : AnyObject? { get }
    var isExpired: Bool { get }
    func expire()
}

class DependencyMap<Key : AnyObject,Value : AnyObject> {
    
    let dependencyToDependents : NSMapTable<AnyObject, AnyObject> = NSMapTable.strongToStrongObjects()
    
    func add(dependency: Value, forEntity entity: Key) {
        zmLog.debug("Adding depedency: \(type(of: dependency)) for entity: \(entity)")
        if var existingDependents = dependencyToDependents.object(forKey: dependency) as? [Key] {
            existingDependents.append(entity)
            dependencyToDependents.setObject(existingDependents as NSArray, forKey: dependency)
        } else {
            dependencyToDependents.setObject([entity] as NSArray, forKey: dependency)
        }
    }
    
    func remove(dependency: Value, forEntity entity: Key) {
        zmLog.debug("Removing depedency: \(type(of: dependency)) for entity: \(entity)")
        if let existingDependents = dependencyToDependents.object(forKey: dependency) as? [Key] {
            dependencyToDependents.setObject(existingDependents.filter({ $0 !== entity }) as NSArray, forKey: dependency)
        }
    }
    
    func entities(withDependency dependency: Value) -> [Key] {
        return dependencyToDependents.object(forKey: dependency) as? [Key] ?? []
    }
    
}

public class DependencyEntitySync<Transcoder : EntityTranscoder> : NSObject, ZMContextChangeTracker, ZMRequestGenerator  where Transcoder.Entity : DependencyEntity {
    
    private var entitiesWithDependencies : DependencyMap<Transcoder.Entity, AnyObject> = DependencyMap()
    private var entitiesWithoutDependencies : [Transcoder.Entity] = []
    private weak var transcoder : Transcoder?
    private var context : NSManagedObjectContext
    
    public init(transcoder: Transcoder, context : NSManagedObjectContext) {
        self.transcoder = transcoder
        self.context = context
    }
    
    public func expireEntities(withDependency dependency: AnyObject) {
        for entity in entitiesWithDependencies.entities(withDependency: dependency) {
            entity.expire()
        }
    }
    
    public func synchronize(entity: Transcoder.Entity) {
        if let dependency = entity.dependentObjectNeedingUpdateBeforeProcessing {
            entitiesWithDependencies.add(dependency: dependency, forEntity: entity)
        } else {
            entitiesWithoutDependencies.append(entity)
        }
    }
    
    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        for object in objects {
            for entity in entitiesWithDependencies.entities(withDependency: object) {
                let newDependency = entity.dependentObjectNeedingUpdateBeforeProcessing
                
                if let newDependency = newDependency, newDependency !== object {
                    entitiesWithDependencies.add(dependency: newDependency, forEntity: entity)
                } else if newDependency == nil {
                    entitiesWithDependencies.remove(dependency: object, forEntity: entity)
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
