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
import WireRequestStrategy

public protocol OTREntity : DependencyEntity {
    
    var conversation : ZMConversation { get }
    
}

extension OTREntity {
    
    public var dependentObjectNeedingUpdateBeforeProcessingOTREntity: AnyObject? {
        // FIXME this should be shared with OTRMessage once it also implements the OTREntity protocol
        
        // If we receive a missing payload that includes users that are not part of the conversation,
        // we need to refetch the conversation before recreating the message payload.
        // Otherwise we end up in an endless loop receiving missing clients error
        if conversation.needsToBeUpdatedFromBackend || conversation.remoteIdentifier == nil {
            return conversation
        }
        
        if (conversation.conversationType == .oneOnOne || conversation.conversationType == .connection) && conversation.connection?.needsToBeUpdatedFromBackend == true {
            return conversation.connection
        }
        
        // If we are missing clients, we need to refetch the clients before retrying
        if let selfClient = ZMUser.selfUser(in: conversation.managedObjectContext!).selfClient(), let missingClients = selfClient.missingClients , missingClients.count > 0 {
            
            let activeClients = (conversation.activeParticipants.array as! [ZMUser]).flatMap({ Array($0.clients) })
            
            // Don't block sending of messages in conversations that are not affected by missing clients
            if !missingClients.intersection(Set(activeClients)).isEmpty {
                // make sure that we fetch those clients, even if we somehow gave up on fetching them
                selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
                return selfClient
            }
        }
        
        return nil
    }
    
}
