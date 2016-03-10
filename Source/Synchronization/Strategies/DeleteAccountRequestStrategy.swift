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


import Foundation
import ZMTransport

/// Requests the account deletion
@objc public class DeleteAccountRequestStrategy: NSObject, RequestStrategy, ZMSingleRequestTranscoder {

    private static let path: String = "/self"
    public static let userDeletionInitiatedKey: String = "ZMUserDeletionInitiatedKey"
    
    private(set) var deleteSync: ZMSingleRequestSync! = nil
    /// The managed object context to operate on
    private let managedObjectContext: NSManagedObjectContext
    private let authStatus: ZMAuthenticationStatus
    
    public init(authStatus: ZMAuthenticationStatus, managedObjectContext: NSManagedObjectContext) {
        self.authStatus = authStatus
        self.managedObjectContext = managedObjectContext
        super.init()
        self.deleteSync = ZMSingleRequestSync(singleRequestTranscoder: self, managedObjectContext: self.managedObjectContext)
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        guard let shouldBeDeleted : NSNumber = self.managedObjectContext.persistentStoreMetadataForKey(self.dynamicType.userDeletionInitiatedKey) as? NSNumber
            where shouldBeDeleted.boolValue
        else {
            return nil
        }
        
        self.deleteSync.readyForNextRequestIfNotBusy()
        return self.deleteSync.nextRequest()
    }
    
    // MARK: - ZMSingleRequestTranscoder
    
    public func requestForSingleRequestSync(sync: ZMSingleRequestSync!) -> ZMTransportRequest! {
        let request = ZMTransportRequest(path: self.dynamicType.path, method: .MethodDELETE, payload: [:], shouldCompress: true)
        return request
    }
    
    public func didReceiveResponse(response: ZMTransportResponse!, forSingleRequest sync: ZMSingleRequestSync!) {
        if response.result == .Success || response.result == .PermanentError {
            self.managedObjectContext.setPersistentStoreMetadata(NSNumber(bool: false), forKey: self.dynamicType.userDeletionInitiatedKey)
            ZMPersistentCookieStorage.deleteAllKeychainItems()
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                ZMUserSessionAuthenticationNotification.notifyAuthenticationDidFail(NSError.userSessionErrorWithErrorCode(.AccountDeleted, userInfo: .None))
            })
        }
    }
}
