//
//  CacheLocator.swift
//  WireSyncEngine
//
//  Created by Sabine Geithner on 04.07.17.
//  Copyright © 2017 Zeta Project Gmbh. All rights reserved.
//

import Foundation

private let zmLog = ZMSLog(tag: "ZMUserSession")

extension ZMUserSession {
    
    /// Checks the Library/Caches folder in the shared container directory for files that have not been assigned to a user account 
    /// and moves them to a folder named `wire-account-{accountIdentifier}` if there is no user-account folder yet
    /// It asserts if the caches folder contains unassigned files even though there is already an existing user account folder as this would be considered a programmer error
    public static func moveCachesIfNeeded(appGroupIdentifier: String, accountIdentifier: UUID?) {
        // FIXME: accountIdentifier should be non-nullable
        guard let accountIdentifier = accountIdentifier else { return }
        
        let fm = FileManager.default
        guard let newCacheLocation = fm.cachesURL(forAppGroupIdentifier: appGroupIdentifier, accountIdentifier: accountIdentifier),
              let oldCacheLocation = fm.cachesURL(forAppGroupIdentifier: appGroupIdentifier, accountIdentifier: nil),
              let files = (try? fm.contentsOfDirectory(atPath: oldCacheLocation.path))
        else { return }
        
        // FIXME: Use dictionary grouping in Swift4
        // see https://developer.apple.com/documentation/swift/dictionary/2893436-init
        let result = group(fileNames: files)
        
        if result.assigned.count == 0 {
            result.unassigned.forEach{
                let newLocation = newCacheLocation.appendingPathComponent($0)
                let oldLocation = oldCacheLocation.appendingPathComponent($0)
                zmLog.debug("Moving non-assigned Cache folder from \(oldLocation) to \(newLocation)")
                do {
                    try fm.moveItem(at: oldLocation, to: newLocation)
                }
                catch {
                    zmLog.error("Failed to move non-assigned Cache folder from \(oldLocation) to \(newLocation)")
                }
            }
        } else {
            fatal("Caches folder contains items that have not been assigned to an account. Items should always be assigned to an account. Use `FileManager.cachesURL(forAppGroupIdentifier:accountIdentifier:)` to get the default Cache location for the current account")
        }
    }
    
    
    /// Groups files by checking if the fileName starts with the cachesFolderPrefix
    static func group(fileNames: [String]) -> (assigned : [String], unassigned: [String]) {
        let result : ([String], [String]) = fileNames.reduce(([],[])){ (tempResult, fileName) in
            if fileName.hasPrefix(FileManager.cachesFolderPrefix) {
                return (tempResult.0 + [fileName], tempResult.1)
            }
            return (tempResult.0, tempResult.1 + [fileName])
        }
        return result
    }
    
}
