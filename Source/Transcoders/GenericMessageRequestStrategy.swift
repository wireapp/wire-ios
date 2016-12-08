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

public class GenericMessageEntity : OTREntity {
    
    public var message : ZMGenericMessage
    public var conversation : ZMConversation
    public var completionHandler : (_ response: ZMTransportResponse) -> Void
    
    init(conversation: ZMConversation, message: ZMGenericMessage, completionHandler: @escaping (_ response: ZMTransportResponse) -> Void) {
        self.conversation = conversation
        self.message = message
        self.completionHandler = completionHandler
    }
    
    public var dependentObjectNeedingUpdateBeforeProcessing: AnyObject? {
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

extension GenericMessageEntity : EncryptedPayloadGenerator {
    
    public func encryptedMessagePayloadData() -> (data: Data, strategy: MissingClientsStrategy)? {
        return message.encryptedMessagePayloadData(conversation, externalData: nil)
    }
    
    public var debugInfo: String {
        return "\(self)"
    }
    
}

public class GenericMessageRequestStrategy : OTREntityTranscoder<GenericMessageEntity>, ZMRequestGenerator {
    
    private var sync : DependencyEntitySync<GenericMessageRequestStrategy>?
    private var requestFactory = ClientMessageRequestFactory()
    
    public override init(context: NSManagedObjectContext, clientRegistrationDelegate: ClientRegistrationDelegate) {
        super.init(context: context, clientRegistrationDelegate: clientRegistrationDelegate)
        
        sync = DependencyEntitySync(transcoder: self, context: context)
    }
    
    public func schedule(message: ZMGenericMessage, inConversation conversation: ZMConversation, completionHandler: @escaping (_ response: ZMTransportResponse) -> Void) {
        sync?.synchronize(entity: GenericMessageEntity(conversation: conversation, message: message, completionHandler: completionHandler))
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }
    
    public override func request(forEntity entity: GenericMessageEntity) -> ZMTransportRequest? {
         return requestFactory.upstreamRequestForMessage(entity, forConversationWithId: entity.conversation.remoteIdentifier!)
    }
    
    public override func request(forEntity entity: GenericMessageEntity, didCompleteWithResponse response: ZMTransportResponse) {
        super.request(forEntity: entity, didCompleteWithResponse: response)
        
        entity.completionHandler(response)
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        return sync?.nextRequest()
    }
    
}
