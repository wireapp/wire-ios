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
import UIKit

private let zmLog = ZMSLog(tag: "LocalStoreProvider")

@objc public protocol LocalStoreProviderProtocol: NSObjectProtocol {
    var userIdentifier: UUID? { get }
    var appGroupIdentifier: String { get }
    var cachesURL: URL? { get }
    var sharedContainerDirectory: URL? { get }
    var storeExists: Bool { get }
    var contextDirectory: ManagedObjectContextDirectory? { get }
    
    /// Should be called <b>before</b> using ZMUserSession when applications is started if needsToPrepareLocalStore returns true
    /// It will intialize persistent store and perform migration (if needed) on background thread.
    /// - Parameter completionHandler: called when local store is ready to be used (and the ZMUserSession is ready to be initialized). Called on the main thread, it is the responsability of the caller to switch to the desired thread.
    func createStorageStack(migration: (() -> Void)?, completion: @escaping (LocalStoreProviderProtocol) -> Void)
}

protocol FileManagerProtocol: class {
    func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL?
    func cachesURLForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL) -> URL
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
}

extension FileManager: FileManagerProtocol {}

public extension Bundle {
    var appGroupIdentifier: String? {
        return bundleIdentifier.map { "group." + $0 }
    }
}


/// Encapsulates all storage related data and methods. LocalStoreProviderProtocol protocol
/// is used instead of concrete class to let us inject a custom implementation in tests
@objc public class LocalStoreProvider: NSObject {
    
    public let appGroupIdentifier: String
    public let userIdentifier: UUID?
    let bundleIdentifier: String
    public var contextDirectory: ManagedObjectContextDirectory?

    let fileManager: FileManagerProtocol
    init(bundleIdentifier: String, appGroupIdentifier: String, userIdentifier: UUID?, fileManager: FileManagerProtocol) {
        self.bundleIdentifier = bundleIdentifier
        self.appGroupIdentifier = appGroupIdentifier
        self.userIdentifier = userIdentifier
        self.fileManager = fileManager
    }
    
    public convenience init(userIdentifier: UUID?) {
        self.init(
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            appGroupIdentifier: Bundle.main.appGroupIdentifier!,
            userIdentifier: userIdentifier,
            fileManager: FileManager.default
        )
    }
}

extension LocalStoreProvider: LocalStoreProviderProtocol {
    
    public var sharedContainerDirectory: URL? {
        return FileManager.sharedContainerDirectory(for: appGroupIdentifier)
    }
    
    public var cachesURL: URL? {
        return sharedContainerDirectory.map {
            fileManager.cachesURLForAccount(with: userIdentifier, in: $0)
        }
    }
    
    public var storeExists: Bool {
        return StorageStack.shared.storeExists
    }

    public func createStorageStack(migration: (() -> Void)?, completion: @escaping (LocalStoreProviderProtocol) -> Void) {
        precondition(nil != sharedContainerDirectory)

        StorageStack.shared.createManagedObjectContextDirectory(
            forAccountWith: userIdentifier,
            inContainerAt: sharedContainerDirectory!,
            startedMigrationCallback: { migration?() },
            completionHandler: { [weak self] contextDirectory in
                guard let `self` = self else { return }
                self.contextDirectory = contextDirectory
                completion(self)
            }
        )
    }

}
