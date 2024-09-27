//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "Dependencies")

// MARK: - DependentObjects

public class DependentObjects<Object: Hashable, Dependency: Hashable> {
    // MARK: Lifecycle

    public init() {
        zmLog.debug("Initialized DependentObject for \(Object.self), \(Dependency.self)")
    }

    // MARK: Public

    /// Adds a Dependency to an
    public func add(dependency: Dependency, for dependent: Object) {
        zmLog.debug("Adding dependency \(toPtr(dependency)) to object \(toPtr(dependent)), object is: \(dependent)")
        let toDependents = dependenciesToDependents[dependency] ?? Set()
        dependenciesToDependents[dependency] = toDependents.union([dependent])

        let toDependencies = dependentsToDependencies[dependent] ?? Set()
        dependentsToDependencies[dependent] = toDependencies.union([dependency])
    }

    /// Return any one dependency for the given dependent
    public func anyDependency(for dependent: Object) -> Dependency? {
        dependentsToDependencies[dependent]?.first
    }

    /// Removes from dependencies those objects for which the `block` returns true
    public func enumerateAndRemoveObjects(for dependency: Dependency, block: (Object) -> Bool) {
        guard let objects = dependenciesToDependents[dependency] else { return }
        let objectsToRemove = objects.filter { block($0) }
        guard !objectsToRemove.isEmpty else { return }
        for item in objectsToRemove {
            remove(dependency: dependency, for: item)
        }
    }

    public func dependencies(for dependent: Object) -> Set<Dependency> {
        dependentsToDependencies[dependent] ?? Set()
    }

    public func dependents(on dependency: Dependency) -> Set<Object> {
        dependenciesToDependents[dependency as Dependency] ?? Set()
    }

    public func remove(dependency: Dependency, for dependent: Object) {
        updateDependents(dependent: dependent, removing: dependency)
        updateDependencies(dependency: dependency, removing: dependent)
    }

    public func removeAllDependencies(for dependent: Object) {
        guard let dependencies = dependentsToDependencies[dependent] else { return }

        for dependency in dependencies {
            remove(dependency: dependency, for: dependent)
        }
    }

    // MARK: Private

    private var dependenciesToDependents: [Dependency: Set<Object>] = [:]
    private var dependentsToDependencies: [Object: Set<Dependency>] = [:] // inverse of the previous one

    private func updateDependencies(dependency: Dependency, removing dependent: Object) {
        guard let currentSet = dependenciesToDependents[dependency] else { return }
        if currentSet.contains(dependent) {
            zmLog.debug("Removing dependency \(toPtr(dependency)) from object \(toPtr(dependent))")
        }
        let newSet = currentSet.subtracting([dependent])
        if newSet.isEmpty {
            dependenciesToDependents.removeValue(forKey: dependency)
        } else {
            dependenciesToDependents[dependency] = newSet
        }
    }

    private func updateDependents(dependent: Object, removing dependency: Dependency) {
        guard let currentSet = dependentsToDependencies[dependent] else { return }
        let newSet = currentSet.subtracting([dependency])
        if currentSet.contains(dependency) {
            zmLog.debug("Removing dependent object \(toPtr(dependent))for dependency \(toPtr(dependency))")
        }
        if newSet.isEmpty {
            dependentsToDependencies.removeValue(forKey: dependent)
        } else {
            dependentsToDependencies[dependent] = newSet
        }
    }
}

// MARK: - DependentObjectsObjc

/// List of dependency.
/// This is an adapter class for Obj-c, because Obj-c can't use generics.
/// We will remove it as soon as all the clients of this class are ported to Swift
@objc
public class DependentObjectsObjc: NSObject {
    // MARK: Lifecycle

    override public init() {
        self.dependentObjects = DependentObjects()
        super.init()
    }

    // MARK: Public

    @objc(addDependentObject:dependency:)
    public func add(dependent: ZMManagedObject, dependency: ZMManagedObject) {
        dependentObjects.add(dependency: dependency, for: dependent)
    }

    @objc(anyDependencyForObject:)
    public func anyDependency(for object: ZMManagedObject) -> ZMManagedObject? {
        dependentObjects.anyDependency(for: object)
    }

    @objc(enumerateAndRemoveObjectsForDependency:usingBlock:)
    public func enumerateAndRemoveObjects(for dependency: ZMManagedObject, block: (ZMManagedObject) -> Bool) {
        dependentObjects.enumerateAndRemoveObjects(for: dependency, block: block)
    }

    // MARK: Internal

    let dependentObjects: DependentObjects<ZMManagedObject, ZMManagedObject>
}

/// Returns a string representing the pointer
private func toPtr(_ instance: Any) -> String {
    if let object = instance as? NSManagedObject {
        return "\(type(of: object))" + (NSString(format: " <%p>", object) as String)
    }
    if let object = instance as? NSObject {
        return "\(type(of: object))" + (NSString(format: " <%p>", object) as String)
    }
    return "\(type(of: instance))"
}
