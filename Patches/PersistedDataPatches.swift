//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "Patches")

/// Patches to apply to migrate some persisted data from a previous
/// version of the app - database fixes, local files clean up, etc.
public struct PersistedDataPatch {
    
    /// Max version for which the patch needs to be applied
    let version: FrameworkVersion
    
    /// The patch code
    let block: (NSManagedObjectContext)->()
    
    init(version: String, block: @escaping (NSManagedObjectContext)->()) {
        self.version = FrameworkVersion(version)!
        self.block = block
    }

    /// Apply all patches to the MOC
    public static func applyAll(in moc: NSManagedObjectContext, fromVersion: String? = nil, patches: [PersistedDataPatch]? = nil) {
        zmLog.safePublic("Beginning patches...")

        guard let currentVersion = Bundle(for: BundleAnchor.self).infoDictionary!["CFBundleShortVersionString"] as? String else {
            return zmLog.safePublic("Can't retrieve CFBundleShortVersionString for data model, skipping patches..")
        }

        zmLog.safePublic("current version is: \(currentVersion)")
        
        defer {
            zmLog.safePublic("Saving last patched version: \(currentVersion)")

            if let storeMetadata = moc.metadata {
                zmLog.safePublic("Store metadata before update: \(String(describing: storeMetadata))")
            }

            moc.setPersistentStoreMetadata(currentVersion, key: lastDataModelPatchedVersionKey)
            moc.saveOrRollback()

            if let storeMetadata = moc.metadata {
                zmLog.safePublic("Store metadata after update: \(String(describing: storeMetadata))")
            }
        }
        
        guard
            let previousPatchVersionString = fromVersion ?? (moc.persistentStoreMetadata(forKey: lastDataModelPatchedVersionKey) as? String),
            let previousPatchVersion = FrameworkVersion(previousPatchVersionString)
        else {
            return zmLog.safePublic("No previous patch version stored (expected on fresh installs), skipping patches..")
        }

        zmLog.safePublic("Previous version: \(previousPatchVersion.version)")
    }
}

private class BundleAnchor {}

private extension NSManagedObjectContext {

    var metadata: [String: Any]? {
        guard let store = persistentStoreCoordinator?.persistentStores.first else { return nil }
        return persistentStoreCoordinator?.metadata(for: store)
    }

}

extension String: SafeForLoggingStringConvertible {

    public var safeForLoggingDescription: String {
        return self
    }

}

/// Persistent store key for last data model version
let lastDataModelPatchedVersionKey = "zm_lastDataModelVersionKeyThatWasPatched"


// MARK: - Framework version
/// A framework version (major, minor, patch)
public struct FrameworkVersion: Comparable, Equatable {

    /// Version component (10, 3, 4 -> 10.3.4)
    fileprivate let components: [Int]
    
    /// Major component, *10*.3.4
    public var major: Int {
        return components[0]
    }
    
    /// Minor component, 10.*3*.4
    public var minor: Int {
        return components[1]
    }
    /// Patch component, 10.3.*4*
    public var patch: Int {
        return components[2]
    }
    /// Version in string form
    public let version: String
    
    public init?(_ version: String) {
        self.version = version
        let stringArray = version.components(separatedBy: ".")
        guard stringArray.count <= 3 else {
            return nil
        }
        let asInt = stringArray.map { Int($0) }
        guard asInt.first(where: { $0 == nil }) == nil else {
            return nil
        }
        var components = asInt.compactMap { $0 }
        while components.count < 3 {
            components += [0]
        }
        self.components = components
    }
    
    public static func <(lhs: FrameworkVersion, rhs: FrameworkVersion) -> Bool {
        for comp in zip(lhs.components, rhs.components) {
            if comp.0 < comp.1 {
                return true
            } else if comp.0 > comp.1 {
                return false
            }
        }
        return false
    }
}

public func==(lhs: FrameworkVersion, rhs: FrameworkVersion) -> Bool {
    return lhs.components == rhs.components
}

