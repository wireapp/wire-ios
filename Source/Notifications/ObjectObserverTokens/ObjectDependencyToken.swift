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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMCSystem
import ZMUtilities

extension Dictionary {
    
    func mapKeys<T: Hashable>(transform: (Key) -> T) -> [T: Value] {
        var mapping : [T : Value] = [:]
        for (key, value) in self {
            mapping[transform(key)] = value
        }
        return mapping
        
    }
}

public final class ObjectDependencyToken : NSObject, ObjectsDidChangeDelegate, CustomDebugStringConvertible {
    
    public typealias KeysAndOldValues = [KeyPath: NSObject?]
    public typealias DependentKeyChangeObserver = (changedKeyPaths : KeysAndOldValues ) -> Void

    private let keyFromParentObjectToObservedObject : KeyPath?
    private let observedObject : NSObject
    private let observer : DependentKeyChangeObserver
    private let internalObserver : DependentKeyChangeObserver
    private var snapshot : ObjectSnapshot
    private let observedKeyPathToAffectedKey : [KeyPath : KeySet]
    private var dependencyTokens : [KeyPath : TokensWithKeyPathsToObserve]
    private weak var managedObjectContextObserver : ManagedObjectContextObserver?
    
    private var accumulatedChanges = KeySet()
    
    private struct TokensWithKeyPathsToObserve: CustomDebugStringConvertible {

        var tokens : [ObjectDependencyToken]
        var keyPathsToObserve : KeySet
        
        var description : String {
            return "\nTokensWithKeyPathsToObserve \n   tokens: \(self.tokens.map{SwiftDebugging.address($0)}) \n  keyPathsToObserve: \(self.keyPathsToObserve)"
        }
        
        var debugDescription : String {
            return description
        }
        
        func tearDown() {
            for t in tokens {
                t.tearDown();
            }
        }
    }
    
    typealias KeyPathToAffectedKeys = [KeyPath : KeySet]
    
    /**
     Create a Object dependency token. If a ManagedObjectContextObserver is given, this will also observe the dependency of this object.
     */
    public init(
        keyFromParentObjectToObservedObject : KeyPath?,
        observedObject : NSObject,
        keysToObserve: KeySet,
        managedObjectContextObserver: ManagedObjectContextObserver?,
        observer: DependentKeyChangeObserver) {
            
            self.keyFromParentObjectToObservedObject = keyFromParentObjectToObservedObject
            self.observedObject = observedObject
            self.observer = observer
            self.snapshot = ObjectSnapshot(object: observedObject, keys: keysToObserve)
            self.dependencyTokens = [:]
            self.managedObjectContextObserver = managedObjectContextObserver
            
            var closureWrapper : (KeysAndOldValues) -> () = { _ in return }
            
            self.internalObserver = { closureWrapper($0) }
            
            if let managedObjectContextObserver = managedObjectContextObserver {
                (self.observedKeyPathToAffectedKey, self.dependencyTokens) = ObjectDependencyToken.tokensForOtherObjectsThatAffectKey(
                    observedObject,
                    keys:keysToObserve,
                    managedObjectContextObserver: managedObjectContextObserver,
                    observer: { closureWrapper($0) }
                )
            } else {
                self.observedKeyPathToAffectedKey = [KeyPath : KeySet]()
            }
            
            
            super.init()
        
            closureWrapper = {[weak self] changedKeyPaths in
                let keys = KeySet(changedKeyPaths.keys)
                self?.accumulateChangesFromDependentObjects(keys)
            }
        
            managedObjectContextObserver?.addChangeObserver(self, object: self.observedObject)
    }
    
    public func tearDown() {
        if let contextObserver = managedObjectContextObserver {
            for t in self.dependencyTokens.values {
                t.tearDown();
            }
            contextObserver.removeChangeObserver(self, object: self.observedObject)
        }
    }
    
    deinit {
        self.tearDown()
    }
        
    func accumulateChangesFromDependentObjects(changedKeyPaths: KeySet) {
        let changedAffectedKeys: KeySet = {
            var ks = KeySet()
            for kp in changedKeyPaths {
                if let mkp = self.observedKeyPathToAffectedKey[kp] {
                    ks = ks.union(mkp)
                }
            }
            return ks
        }()
        self.accumulatedChanges = self.accumulatedChanges.union(changedAffectedKeys)
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        if changes.updated.contains(self.observedObject) {
            self.accumulatedChanges = KeySet()
            self.objectDidChangeKeys(.All)
        } else if !self.accumulatedChanges.isEmpty {
            let changedKeys = self.accumulatedChanges
            self.accumulatedChanges = KeySet()
            self.objectDidChangeKeys(.Some(changedKeys))
        }
    }
    
    func objectDidChangeKeys(affectedKeys: AffectedKeys) {
        if let (newSnapShot, keysAndOldValues) = self.snapshot.updatedSnapshot(self.observedObject, affectedKeys: affectedKeys) {

            self.snapshot = newSnapShot
            let changedKeys = keysAndOldValues.mapKeys { (key: KeyPath) -> KeyPath in
                self.keyFromParentObjectToObservedObject.map { KeyPath.keyPathForString($0.rawValue+"."+key.rawValue) } ?? key
            }
            
            self.observer(changedKeyPaths : changedKeys)
            self.createOrDeleteDependendTokensIfNeeded(KeySet(changedKeys.keys))
        }
    }
    
    private func getAllDependendObjectsForKeyPath(keyPath: KeyPath) -> Set<NSObject> {
        if let toManyRelationShip = self.observedObject.valueForKey(keyPath.rawValue) as? NSFastEnumeration {
            return Set(Enumerator(toManyRelationShip).allObjects() as! [NSObject])
        } else if let singleRelationshipNonNil = self.observedObject.valueForKey(keyPath.rawValue) as? NSObject {
            return Set(arrayLiteral: singleRelationshipNonNil)
        } else {
            return Set()
        }
    }
    
    func createOrDeleteDependendTokensIfNeeded(affectedKeys: KeySet) {
        
        for keyPath in affectedKeys {
            
            if let tokensWithKeyPathsToObserve = self.dependencyTokens[keyPath] {
                let tokens = tokensWithKeyPathsToObserve.tokens
                let keyPathsToObserve = tokensWithKeyPathsToObserve.keyPathsToObserve
                
                let tokenObjects = Set(tokens.map{$0.observedObject})
                let currentObjects = self.getAllDependendObjectsForKeyPath(keyPath)
                
                
                let objectsToDelete = tokenObjects.subtract(currentObjects)
                let objectsToInsert = currentObjects.subtract(tokenObjects)
                
                var purgedTokens = tokens.filter { token in
                    if objectsToDelete.contains(token.observedObject) {
                        return true
                    }
                    token.tearDown()
                    return false
                }
                purgedTokens.appendContentsOf(
                    objectsToInsert.map {ObjectDependencyToken(
                        keyFromParentObjectToObservedObject: keyPath,
                        observedObject: $0,
                        keysToObserve: keyPathsToObserve,
                        managedObjectContextObserver : self.managedObjectContextObserver!,
                        observer: self.internalObserver
                        )}
                )
                
                let tokensWithKeyPaths = TokensWithKeyPathsToObserve(tokens: purgedTokens, keyPathsToObserve: keyPathsToObserve)
                self.dependencyTokens[keyPath] = tokensWithKeyPaths
            }
        }
    }

    private class func tokensForOtherObjectsThatAffectKey(
        object: NSObject,
        keys: KeySet,
        managedObjectContextObserver : ManagedObjectContextObserver,
        observer: DependentKeyChangeObserver
    ) -> (KeyPathToAffectedKeys , [KeyPath : TokensWithKeyPathsToObserve]) {
        
        var keyNameToTokens : [KeyPath: TokensWithKeyPathsToObserve] = [:]

        let keysToPathsToObserve = DependentObjectsKeysForObservedObjectKeysCache.mappingForObject(object, keysToObserve: keys)
        
        for (objectKey, pathsToObserveInObject) in keysToPathsToObserve.keyPathsOnDependentObjectForKeyOnObservedObject {
            let newTokens = self.tokensForObservingKey(object,
                key: objectKey,
                pathsToObserveInObject: pathsToObserveInObject,
                observer: observer,
                managedObjectContextObserver: managedObjectContextObserver
            )
            keyNameToTokens[objectKey] = TokensWithKeyPathsToObserve(tokens: newTokens, keyPathsToObserve: pathsToObserveInObject)
        }

        return (keysToPathsToObserve.affectedKeysOnObservedObjectForChangedKeysOnDependentObject, keyNameToTokens)
    }
    
    class func tokensForObservingKey(object: NSObject,
        key: KeyPath,
        pathsToObserveInObject: KeySet,
        observer: ObjectDependencyToken.DependentKeyChangeObserver,
        managedObjectContextObserver : ManagedObjectContextObserver
        ) -> [ObjectDependencyToken]
    {
        var tokens : [ObjectDependencyToken] = []
        if let objectToObserve = object.valueForKey(key.rawValue) as? NSObject {
            if let fastEnumerator = objectToObserve as? NSFastEnumeration {
                for nextObject in Enumerator(fastEnumerator) {
                    // Does not compile with Swift 1.1
                    
                    let token = ObjectDependencyToken(
                        keyFromParentObjectToObservedObject: key,
                        observedObject: nextObject as! NSObject,
                        keysToObserve: pathsToObserveInObject,
                        managedObjectContextObserver : managedObjectContextObserver,
                        observer: observer
                    )
                    tokens.append(token)
                }
            } else {
                let token = ObjectDependencyToken(
                    keyFromParentObjectToObservedObject: key,
                    observedObject: objectToObserve,
                    keysToObserve: pathsToObserveInObject,
                    managedObjectContextObserver : managedObjectContextObserver,
                    observer: observer
                )
                tokens.append(token)
            }
        }
        
        return tokens
        
    }
    
    override public var description : String {
        return "ObjectDependencyToken \n Snapshot: {\n \(self.snapshot) \n} \n observedKeyPathToAffectedKey: \(self.observedKeyPathToAffectedKey) \n dependencyTokens: { \n \(dependencyTokens) \n}"
    }
    
    override public var debugDescription : String {
        return description
    }
    
    public func printDescription() {
        print("ObjectDependencyToken \n ObservedObject: \(self.observedObject) \n Snapshot: {\n \(self.snapshot) \n} \n observedKeyPathToAffectedKey: \(self.observedKeyPathToAffectedKey) \n dependencyTokens: { \n \(dependencyTokens) \n}")
    }
}
