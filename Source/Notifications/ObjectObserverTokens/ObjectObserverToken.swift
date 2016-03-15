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

extension String {

    func upperCasePreservingCamelCase() -> String {
        var aString = self
        let capitalfirstLetter = String(aString[aString.startIndex]).capitalizedString
        let range = Range(start: aString.startIndex, end: aString.startIndex.advancedBy(1))
        aString.replaceRange(range, with: capitalfirstLetter)
        return aString
    }
}

/// MARK: Base class for observer / change info
public protocol ObjectChangeInfoProtocol : NSObjectProtocol {
    
    init(object: NSObject)
    func setValue(value: AnyObject?, forKey key: String)
    func valueForKey(key: String) -> AnyObject?
    var changedKeys : KeySet { get set }
}

public class ObjectChangeInfo : NSObject, ObjectChangeInfoProtocol {
    
    let object : NSObject
    
    public required init(object: NSObject) {
        self.object = object
    }
    public var changedKeys : KeySet = KeySet()
    
}

/// This is used to wrap UI observers
///
/// The token is read-only, but reset when tearDown() is called.
@objc public class ObjectObserverTokenContainer : NSObject {

    private(set) var token : AnyObject?
    private(set) var object : ObjectInSnapshot?

    public init(object: ObjectInSnapshot, token: AnyObject) {
        self.token = token
        self.object = object
    }
    
    public func tearDown() {
        self.token = nil
    }
}


/// MARK: Common behaviour for all observer tokens
final class ObjectObserverToken<T : ObjectChangeInfoProtocol, B: ObjectObserverTokenContainer>: NSObject {
    
    typealias ObserverCallback = (B, T) -> Void
    
    /// Mapping from key ("name") to variable in T that should be set ("nameChanged")
    private let keyToObjectChangeKeyMap : KeyToKeyTransformation
    /// List of keys for which we want to store a previous value
    private let keyToPreviousValueMap : KeyToKeyTransformation
    private let token : ObjectDependencyToken?
    private let observedObject : NSObject
    private let externalObserver : ObserverCallback
    private var tokenContainers: NSHashTable = NSHashTable.weakObjectsHashTable()
    
    static func tokenWithContainers(
        observedObject: NSObject,
        keysToObserve : KeySet,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback)
        -> ObjectObserverToken<T, B>
    {
        return ObjectObserverToken(observedObject: observedObject, keysToObserve: keysToObserve, keysThatNeedPreviousValue: keysThatNeedPreviousValue, managedObjectContextObserver: managedObjectContextObserver, observer: observer)
            
    }
    
    static func tokenWithContainers(
        observedObject: NSObject,
        keyToKeyTransformation : KeyToKeyTransformation,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback)
        -> ObjectObserverToken<T, B>
    {
        return ObjectObserverToken(observedObject: observedObject, keyToKeyTransformation: keyToKeyTransformation, keysThatNeedPreviousValue: keysThatNeedPreviousValue, managedObjectContextObserver: managedObjectContextObserver, observer: observer)
            
    }
    
    static func token(observedObject: NSObject,
        keysToObserve : KeySet,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback)
        -> ObjectObserverToken<T, B>
    {
        let token = ObjectObserverToken(observedObject: observedObject, keysToObserve: keysToObserve, keysThatNeedPreviousValue: keysThatNeedPreviousValue, managedObjectContextObserver: managedObjectContextObserver, observer: observer)
        return token
    }
    
    
    static func token(observedObject: NSObject,
        keyToKeyTransformation : KeyToKeyTransformation,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback)
        -> ObjectObserverToken<T, B>
    {
        let token = ObjectObserverToken(observedObject: observedObject, keyToKeyTransformation: keyToKeyTransformation, keysThatNeedPreviousValue: keysThatNeedPreviousValue, managedObjectContextObserver: managedObjectContextObserver, observer: observer)
        return token
    }
    
    private convenience init(
        observedObject: NSObject,
        keysToObserve : KeySet,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback
        ) {
        var keyToKeyTransformationMap : [KeyPath : KeyToKeyTransformation.KeyToKeyMappingType] = [:]
        
        for key in keysToObserve {
            keyToKeyTransformationMap[key] = KeyToKeyTransformation.KeyToKeyMappingType.None
        }
        
        self.init(
            observedObject: observedObject,
            keyToKeyTransformation: KeyToKeyTransformation(mapping: keyToKeyTransformationMap),
            keysThatNeedPreviousValue : keysThatNeedPreviousValue,
            managedObjectContextObserver: managedObjectContextObserver,
            observer: observer)
    }
    
    private init(observedObject: NSObject,
        keyToKeyTransformation : KeyToKeyTransformation,
        keysThatNeedPreviousValue : KeyToKeyTransformation,
        managedObjectContextObserver: ManagedObjectContextObserver,
        observer: ObserverCallback
        )
    {
        self.externalObserver = observer
        
        self.observedObject = observedObject
        self.keyToObjectChangeKeyMap = keyToKeyTransformation
        self.keyToPreviousValueMap = keysThatNeedPreviousValue
        let keysToObserve = keysThatNeedPreviousValue.allKeys().union(keyToKeyTransformation.allKeys())
        var wrapper : ([KeyPath:NSObject?]) -> () = { _ in return }
        
        self.token = ObjectDependencyToken(
            keyFromParentObjectToObservedObject: nil,
            observedObject: observedObject,
            keysToObserve: keysToObserve,
            managedObjectContextObserver: managedObjectContextObserver,
            observer: { wrapper($0) }
        )
        
        super.init()
        
        wrapper = {
            [weak self] (changedKeys) in
            self?.keysDidChange(changedKeys)
        }

    }

    func keysDidChange(affectedKeys: [KeyPath:NSObject?]) {
        let objectChangeInfo = T(object: self.observedObject)
        objectChangeInfo.changedKeys = KeySet(affectedKeys.keys)

        for (key, oldValue) in affectedKeys {
            if let fieldName = self.keyToObjectChangeKeyMap.transformKey(key, defaultTransformation: { $0 + "Changed" } ) {
                objectChangeInfo.setValue(1, forKey: fieldName.rawValue)
            }
            if let previousValueFieldName = self.keyToPreviousValueMap.transformKey(key, defaultTransformation: {"previous" + $0.upperCasePreservingCamelCase() } )  {
                objectChangeInfo.setValue(oldValue, forKey: previousValueFieldName.rawValue)
            }
        }
        
        notifyObservers(objectChangeInfo)
    }
    
    // Sends the given changeInfo to all registered observers for this object
    func notifyObservers(changeInfo: T) {
        for container in tokenContainers.allObjects {
            self.externalObserver(container as! B, changeInfo)
        }
    }
    
    func addContainer(container: B) {
        tokenContainers.addObject(container)
    }
    func removeContainer(container: B) {
        tokenContainers.removeObject(container)
        if self.hasNoContainers {
            self.tearDown()
        }
    }
	
    var hasNoContainers: Bool {
		return tokenContainers.count == 0
	}
    

    func tearDown() {
        self.token?.tearDown()
    }
    
    deinit {
        // TODO: Why are we calling tearDown() here? It would be a programming error for it not to have been called at this point.
        self.tearDown()
    }
}
