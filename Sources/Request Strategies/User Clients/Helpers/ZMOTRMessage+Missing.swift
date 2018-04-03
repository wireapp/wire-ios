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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import WireDataModel

@objc public protocol SelfClientDeletionDelegate {
    
    /// Invoked when the self client needs to be deleted
    func deleteSelfClient()
}


/// MARK: - Missing and deleted clients
public extension ZMOTRMessage {

    @objc func parseMissingClientsResponse(_ response: ZMTransportResponse, clientRegistrationDelegate: ClientRegistrationDelegate) -> Bool {
        return self.parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate)
    }

}

extension ZMConversation {
    
    /// If a missing client is not in this conversation, then we are out of sync with the BE
    /// and we should refetch
    func checkIfMissingActiveParticipant(_ user: ZMUser) {
        // are we out of sync?
        guard !self.activeParticipants.contains(user) else { return }
        
        self.needsToBeUpdatedFromBackend = true
        if(self.conversationType == .oneOnOne || self.conversationType == .connection) {
            if(user.connection == nil) {
                if(self.connection == nil) {
                    user.connection = ZMConnection.insertNewObject(in: self.managedObjectContext!)
                    self.connection = user.connection
                } else {
                    user.connection = self.connection
                }
            }
        } else if (self.connection == nil) {
            self.connection = user.connection
        }
        user.connection?.needsToBeUpdatedFromBackend = true
    }
}
