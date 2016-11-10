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
import CoreData
import ZMTransport
import WireRequestStrategy

final class RequestGeneratorStore {
    
    let requestGenerators: [ZMTransportRequestGenerator]
    let changeTrackers : [ZMContextChangeTracker]
    
    private let strategies : [AnyObject]
    
    init(strategies: [AnyObject]) {
        
        self.strategies = strategies
        
        var requestGenerators : [ZMTransportRequestGenerator] = []
        var changeTrackers : [ZMContextChangeTracker] = []
        
        for strategy in strategies {
            
            if let requestGeneratorSource = strategy as? ZMRequestGeneratorSource {
                for requestGenerator in requestGeneratorSource.requestGenerators {
                    requestGenerators.append({
                        return requestGenerator.nextRequest()
                    })
                }
            }
            
            if let contextChangeTrackerSource = strategy as? ZMContextChangeTrackerSource {
                changeTrackers.append(contentsOf: contextChangeTrackerSource.contextChangeTrackers)
            }
            
            if let contextChangeTracker = strategy as? ZMContextChangeTracker {
                changeTrackers.append(contextChangeTracker)
            }
            
            if let requestStrategy = strategy as? RequestStrategy {
                requestGenerators.append({
                    requestStrategy.nextRequest()
                })
            }
        }
        
        self.requestGenerators = requestGenerators
        self.changeTrackers = changeTrackers
    }
    
}


final class OperationLoop : NSObject, RequestAvailableObserver {

    typealias RequestAvailableClosure = () -> Void
    typealias ChangeClosure = (_ changed: Set<NSManagedObject>) -> Void
    typealias SaveClosure = (_ insertedObjects: Set<NSManagedObject>, _ updatedObjects: Set<NSManagedObject>) -> Void

    private let syncContext: NSManagedObjectContext
    private let userContext: NSManagedObjectContext
    private let callBackQueue: OperationQueue
    private var tokens: [NSObjectProtocol] = []
    
    public var changeClosure: ChangeClosure?
    public var requestAvailableClosure: RequestAvailableClosure?

    init(userContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, callBackQueue: OperationQueue = .main) {
        self.userContext = userContext
        self.syncContext = syncContext
        self.callBackQueue = callBackQueue
        
        super.init()
        
        RequestAvailableNotification.addObserver(self)
        
        tokens.append(setupObserver(for: userContext, onSave: userInterfaceContextDidSave))
        tokens.append(setupObserver(for: syncContext, onSave: syncContextDidSave))
    }

    deinit {
        RequestAvailableNotification.removeObserver(self)
        tokens.forEach(NotificationCenter.default.removeObserver)
    }

    func setupObserver(for context: NSManagedObjectContext, onSave: @escaping SaveClosure) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: callBackQueue) { note in
            if let insertedObjects = note.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, let updatedObjects = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                onSave(insertedObjects, updatedObjects)
            }
        }
    }
        
    func syncContextDidSave(insertedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        self.changeClosure?(Set(insertedObjects).union(updatedObjects))
    }
    
    func userInterfaceContextDidSave(insertedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        let insertedObjectsIds = insertedObjects.map({ $0.objectID })
        let updatedObjectsIds = updatedObjects.map({ $0.objectID })
        
        syncContext.performGroupedBlock {
            let insertedObjects = insertedObjectsIds.flatMap({ self.syncContext.object(with: $0) })
            let updatedObjects = updatedObjectsIds.flatMap({ self.syncContext.object(with: $0) })
            

            self.changeClosure?(Set(insertedObjects).union(updatedObjects))
        }
    }
    
    func newRequestsAvailable() {
        requestAvailableClosure?()
    }

}


final class RequestGeneratingOperationLoop {

    private let operationLoop: OperationLoop!
    private let callBackQueue: OperationQueue
    
    private let requestGeneratorStore: RequestGeneratorStore
    private let transportSession: ZMTransportSession

    init(userContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, callBackQueue: OperationQueue = .main, requestGeneratorStore: RequestGeneratorStore, transportSession: ZMTransportSession) {
        self.callBackQueue = callBackQueue
        self.requestGeneratorStore = requestGeneratorStore
        self.transportSession = transportSession
        self.operationLoop = OperationLoop(userContext: userContext, syncContext: syncContext, callBackQueue: callBackQueue)
        operationLoop.changeClosure = objectsDidChange
        operationLoop.requestAvailableClosure = enqueueRequests
    }

    func objectsDidChange(changes: Set<NSManagedObject>) {
        
        requestGeneratorStore.changeTrackers.forEach {
            $0.objectsDidChange(changes)
        }
        
        enqueueRequests()
    }
    
    func enqueueRequests() {
        requestGeneratorStore.requestGenerators.forEach {
            _ = transportSession.attemptToEnqueueSyncRequest(generator: $0)
        }
    }
    
}

