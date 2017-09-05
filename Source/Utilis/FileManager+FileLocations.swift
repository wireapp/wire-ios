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
import WireSystem

private let zmLog = ZMSLog(tag: "FileLocation")

public extension FileManager {
    
    /// Returns the URL for the sharedContainerDirectory of the app
    @objc(sharedContainerDirectoryForAppGroupIdentifier:)
    public static func sharedContainerDirectory(for appGroupIdentifier: String) -> URL {
        let fm = FileManager.default
        var sharedContainerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        
        if (nil == sharedContainerURL) {
            // Seems like the shared container is not available. This could happen for series of reasons:
            // 1. The app is compiled with with incorrect provisioning profile (for example with 3rd parties)
            // 2. App is running on simulator and there is no correct provisioning profile on the system
            // 3. Bug with signing
            //
            // The app should allow not having a shared container in cases 1 and 2; in case 3 the app should crash
            
            let deploymentEnvironment = ZMDeploymentEnvironment().environmentType()
            if (TARGET_OS_SIMULATOR == 0 && (deploymentEnvironment == .appStore || deploymentEnvironment == .internal)) {
                require(nil != sharedContainerURL, "Unable to create shared container url using app group identifier: \(appGroupIdentifier)")
            }
            else {
                sharedContainerURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                zmLog.error("ERROR: self.databaseDirectoryURL == nil and deploymentEnvironment = \(deploymentEnvironment)")
                zmLog.error("================================WARNING================================")
                zmLog.error("Wire is going to use APPLICATION SUPPORT directory to host the database")
                zmLog.error("================================WARNING================================")
            }
        }
        
        require(nil != sharedContainerURL)
        return sharedContainerURL!
    }
    
    public static let cachesFolderPrefix : String = "wire-account"

    /// Returns the URL for caches appending the accountIdentifier if specified
    public func cachesURL(forAppGroupIdentifier appGroupIdentifier: String, accountIdentifier: UUID?) -> URL? {
        guard let sharedContainerURL = containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else { return nil }
        return cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL)
    }
    
    /// Returns the URL for caches appending the accountIdentifier if specified
    public func cachesURLForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL) -> URL {
        let url = sharedContainerURL.appendingPathComponent("Library", isDirectory: true)
                                    .appendingPathComponent("Caches", isDirectory: true)
        if let accountIdentifier = accountIdentifier {
            return url.appendingPathComponent("\(type(of:self).cachesFolderPrefix)-\(accountIdentifier.uuidString)", isDirectory: true)
        }
        return url
    }
    
    
}
