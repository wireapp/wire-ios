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


private let zmLog = ZMSLog(tag: "Invitations")
private let persistantStoreKey = "ZMPendingPersonalInvitationCode"


@objc
public class IncomingPersonalInvitationStrategy : NSObject, RequestStrategy {
    
    private(set) var fetchInvitationSync: ZMSingleRequestSync! = nil
    private(set) var requestInvitationCode: String! = nil
    private let managedObjectContext : NSManagedObjectContext
    
    public func nextRequest() -> ZMTransportRequest? {
        if (self.pendingInvitationCode == nil) {
            return nil
        }
        
        self.fetchInvitationSync.readyForNextRequestIfNotBusy()
        return self.fetchInvitationSync.nextRequest()
    }
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
        self.fetchInvitationSync = ZMSingleRequestSync(singleRequestTranscoder: self, managedObjectContext: managedObjectContext)
    }
    
    public var pendingInvitationCode : String? {
        get {
            return IncomingPersonalInvitationStrategy.retrievePendingInvitation(self.managedObjectContext)
        }
        
        set(code) {
            IncomingPersonalInvitationStrategy.storePendingInvitation(code, context: self.managedObjectContext)
        }
    }
    
    public static func storePendingInvitation(code: String?, context: NSManagedObjectContext!) {
        context.setPersistentStoreMetadata(code, forKey: persistantStoreKey)
        context.enqueueDelayedSave()
    }
    
    static func retrievePendingInvitation(context: NSManagedObjectContext!) -> String? {
        if let code = context.persistentStoreMetadataForKey(persistantStoreKey) as! String? {
            return code;
        }
        
        return nil;
    }
}

extension IncomingPersonalInvitationStrategy : ZMSingleRequestTranscoder {
    
    private func incompleteRegistrationUserFromResponse(response: ZMTransportResponse!) -> ZMIncompleteRegistrationUser? {
        guard
            let dictionary = response.payload.asDictionary(),
            let name = dictionary["name"] as! String?
        else {
            return nil
        }
        
        let incompleteRegistrationUser = ZMIncompleteRegistrationUser()
        incompleteRegistrationUser.name = name
        incompleteRegistrationUser.phoneNumber = dictionary["phone"] as! String?
        incompleteRegistrationUser.emailAddress = dictionary["email"] as! String?
        incompleteRegistrationUser.invitationCode = self.requestInvitationCode
        
        return incompleteRegistrationUser
    }
    
    public func requestForSingleRequestSync(sync: ZMSingleRequestSync!) -> ZMTransportRequest! {
        guard let pendingInvitationCode = self.pendingInvitationCode else {
            return nil
        }
        
        ZMIncomingPersonalInvitationNotification.notifyWillFetchPersonalInvitation()
        self.requestInvitationCode = pendingInvitationCode
        
        return ZMTransportRequest(path: "/invitations/info?code=\(pendingInvitationCode)", method: ZMTransportRequestMethod.MethodGET, payload: nil, authentication: ZMTransportRequestAuth.None)
    }
    
    public func didReceiveResponse(response: ZMTransportResponse!, forSingleRequest sync: ZMSingleRequestSync!) {
        if (response.result == ZMTransportResponseStatus.Success) {
            self.fetchInvitationSync.resetCompletionState()
            self.pendingInvitationCode = nil
            
            if let incompleteRegistrationUser = incompleteRegistrationUserFromResponse(response) {
                ZMIncomingPersonalInvitationNotification.notifyDidReceiveInviteToRegisterAsUser(incompleteRegistrationUser)
            } else {
                let error = NSError.userSessionErrorWithErrorCode(ZMUserSessionErrorCode.UnkownError, userInfo:nil)
                ZMIncomingPersonalInvitationNotification.notifyDidFailFetchPersonalInvitationWithError(error)
            }
        } else if (response.result == ZMTransportResponseStatus.PermanentError) {
            self.pendingInvitationCode = nil
            let error = NSError.userSessionErrorWithErrorCode(ZMUserSessionErrorCode.InvalidInvitationCode, userInfo:nil)
            ZMIncomingPersonalInvitationNotification.notifyDidFailFetchPersonalInvitationWithError(error)
        } else {
            let error = NSError.userSessionErrorWithErrorCode(ZMUserSessionErrorCode.NetworkError, userInfo:nil)
            ZMIncomingPersonalInvitationNotification.notifyDidFailFetchPersonalInvitationWithError(error)
        }
    }
}