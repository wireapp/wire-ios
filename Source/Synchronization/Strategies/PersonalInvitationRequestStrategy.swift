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
import ZMTransport
import ZMUtilities


private let zmLog = ZMSLog(tag: "Invitation")


@objc public class PersonalInvitationRequestStrategy: ZMObjectSyncStrategy, RequestStrategy, ZMUpstreamTranscoder, ZMObjectStrategy {
    
    // MARK: - Propery definitions
    
    public private(set) var insertSync: ZMUpstreamInsertedObjectSync! = nil
    
    
    // MARK: - Init
    
    public init(context: NSManagedObjectContext) {
        super.init(managedObjectContext: context)
        self.insertSync = ZMUpstreamInsertedObjectSync(transcoder: self, entityName: ZMPersonalInvitation.entityName(), managedObjectContext: context)
    }
    
    // MARK: - 
    
    private func postNotificationForInvitation(personalInvitation: ZMPersonalInvitation, forStatus status: ZMInvitationStatus) {
        let email = personalInvitation.inviteeEmail
        let phone = personalInvitation.inviteePhoneNumber
        dispatch_async(dispatch_get_main_queue()) {
            var notification: ZMInvitationStatusChangedNotification? = nil
            if email != nil {
                notification = ZMInvitationStatusChangedNotification(forContactEmailAddress: email, status:status)
            } else if phone != nil {
                notification = ZMInvitationStatusChangedNotification(forContactPhoneNumber: phone, status:status)
            }
            if let note = notification {
                NSNotificationCenter.defaultCenter().postNotification(note)
            }
        }
    }
    
    // MARK: - RequestStrategy
    
    @objc public func nextRequest() -> ZMTransportRequest? {
        return self.insertSync.nextRequest()
    }
    
    // MARK: - ZMUpstreamTranscoder
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false;
    }
    
    public func requestForUpdatingObject(managedObject: ZMManagedObject!, forKeys keys: Set<NSObject>!) -> ZMUpstreamRequest! {
        return nil
    }
    
    public func requestForInsertingObject(managedObject: ZMManagedObject!, forKeys keys: Set<NSObject>!) -> ZMUpstreamRequest! {
        if let personalInvitation = managedObject as? ZMPersonalInvitation {
        
            zmLog.info("Will send invitation: \(personalInvitation) to email: \(personalInvitation.inviteeEmail) or phone: \(personalInvitation.inviteePhoneNumber)")
            let path = "/invitations"
            var payload : [String: String] = [
                "locale" : NSLocale.formattedLocaleIdentifier(),
                "message" : personalInvitation.message ?? " ",
            ]
            
            if let email = personalInvitation.inviteeEmail {
                payload["email"] = email
            } else if let phone = personalInvitation.inviteePhoneNumber {
                payload["phone"] = phone
            } else {
                return nil  // invite must have either email or phone number
            }
            
            if let name = personalInvitation.inviteeName {
                payload["invitee_name"] = name
            } else {
                payload["invitee_name"] = " "
            }
            
            let personName = ZMPersonName.personWithName(personalInvitation.inviter.name)
            if let name = personName.givenName {
                payload["inviter_name"] = name
            }
            
            if let conversationID = personalInvitation.conversation?.remoteIdentifier {
                payload["conversation_id"] = conversationID.transportString()
            }
            
            let request = ZMTransportRequest(path: path, method: ZMTransportRequestMethod.MethodPOST, payload: payload)
        
            
            return ZMUpstreamRequest(transportRequest: request)
            
        } else {
            return nil
        }
    }
    
    public func updateInsertedObject(managedObject: ZMManagedObject!, request upstreamRequest: ZMUpstreamRequest!, response: ZMTransportResponse!) {
        zmLog.debug("Did receive \(response.payload) for invitation sending")
        if let personalInvitation = managedObject as? ZMPersonalInvitation {
            if let responseData = response.payload,
                responseDictionary: NSDictionary = responseData.asDictionary(),
                remoteIdentifier = responseDictionary.optionalUuidForKey("id") {
                    zmLog.info("Did send invitation: \(personalInvitation) to email: \(personalInvitation.inviteeEmail) or phone: \(personalInvitation.inviteePhoneNumber)")
                    
                    personalInvitation.remoteIdentifier = remoteIdentifier
                    personalInvitation.serverTimestamp = responseDictionary.dateForKey("created_at")
                    personalInvitation.status = .Sent
                    
                    self.postNotificationForInvitation(personalInvitation, forStatus: .Sent)
            } else if response.payload == nil { // BE created connection request instead of invitation

                guard
                    let connectionURL = response.headers["Location"] as? String,
                    let remoteIdentifierString = connectionURL.componentsSeparatedByString("/").last as NSString?,
                    let remoteIdentifier = remoteIdentifierString.UUID()
                else {
                    zmLog.warn("Could not extract remote identifier for connection")
                    return
                }
                
                ZMConnection(userUUID: remoteIdentifier, inContext: self.managedObjectContext).needsToBeUpdatedFromBackend = true
                
                zmLog.info("Invitation: \(personalInvitation) to email: \(personalInvitation.inviteeEmail) or phone: \(personalInvitation.inviteePhoneNumber) was handled as Connection Request on BE side.")
                personalInvitation.status = .ConnectionRequestSent
                
                self.postNotificationForInvitation(personalInvitation, forStatus: .ConnectionRequestSent)
            }
        } else {
            zmLog.warn("Received response for wrong object")
        }
    }

    public func updateUpdatedObject(managedObject: ZMManagedObject!, requestUserInfo: [NSObject : AnyObject]!, response: ZMTransportResponse!, keysToParse: Set<NSObject>!) -> Bool {
        return false
    }

    // Should return the objects that need to be refetched from the BE in case of upload error
    public func objectToRefetchForFailedUpdateOfObject(managedObject: ZMManagedObject!) -> ZMManagedObject! {
        return nil
    }
    
    public func failedToUpdateInsertedObject(managedObject: ZMManagedObject!, request upstreamRequest: ZMUpstreamRequest!, response: ZMTransportResponse!, keysToParse keys: Set<NSObject>!) -> Bool {
        
        if let invitation = managedObject as? ZMPersonalInvitation {
            self.postNotificationForInvitation(invitation, forStatus: .Failed)
        }
        
        return false
    }
    
    
    // MARK: - ZMObjectStrategy 
    
    public var requestGenerators: [ZMRequestGenerator] {
        return []
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self.insertSync]
    }
    
    public var isSlowSyncDone: Bool {
        return false
    }
    
    public func setNeedsSlowSync() {
        
    }
    
    public func processEvents(events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        // no-op
    }
    
}
