////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireProtos

extension MockTransportSession {

    @objc(fetchConversationWithIdentifier:)
    public func fetchConversation(with identifier: String) -> MockConversation? {
        let request = MockConversation.sortedFetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", identifier.lowercased())
        let conversations = managedObjectContext.executeFetchRequestOrAssert(request) as? [MockConversation]
        return conversations?.first
    }
    
    @objc(processReceiptModeUpdateForConversation:payload:)
    public func processReceiptModeUpdate(for conversationId: String, payload: [String:  AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        guard let receiptMode = payload["receipt_mode"] as? Int else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        }
        guard receiptMode != conversation.receiptMode?.intValue else {
            return ZMTransportResponse(payload: nil, httpStatus: 204, transportSessionError: nil)
        }
        
        conversation.receiptMode = NSNumber(value: receiptMode)
        
        let responsePayload = [
            "conversation" : conversation.identifier,
            "type" : "conversation.receipt-mode-update",
            "time" : NSDate().transportString(),
            "from" : selfUser.identifier,
            "data" : ["receipt_mode": receiptMode]] as ZMTransportData
        
        return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)
    }

    @objc(processAccessModeUpdateForConversation:payload:)
    public func processAccessModeUpdate(for conversationId: String, payload: [String : AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        guard let accessRole = payload["access_role"] as? String else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        }
        guard let access = payload["access"] as? [String] else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        }

        conversation.accessRole = accessRole
        conversation.accessMode = access

        let responsePayload = [
            "conversation" : conversation.identifier,
            "type" : "conversation.access-update",
            "time" : NSDate().transportString(),
            "from" : selfUser.identifier,
            "data" : [
                "access_role" : conversation.accessRole,
                "access" : conversation.accessMode
            ]
        ] as ZMTransportData
        return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)
    }
    
    @objc(processFetchLinkForConversation:payload:)
    public func processFetchLink(for conversationId: String, payload: [String: AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        guard Set(conversation.accessMode) == Set(["invite", "code"]) else {
            return ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
        }
        
        guard let link = conversation.link else {
            return ZMTransportResponse(payload: ["label": "no-conversation-code"] as ZMTransportData, httpStatus: 404, transportSessionError: nil)
        }
        
        return ZMTransportResponse(payload: ["uri": link,
                                             "key": "test-key",
                                             "code": "test-code"] as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
    
    @objc(processFetchRolesForConversation:payload:)
    public func processFetchRoles(for conversationId: String, payload: [String: AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        let roles = conversation.team?.roles ?? conversation.nonTeamRoles!
        let payload: [String : Any] = [
            "conversation_roles" : roles.map { $0.payload }
        ]
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
    
    @objc(processCreateLinkForConversation:payload:)
    public func processCreateLink(for conversationId: String, payload: [String: AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        guard Set(conversation.accessMode) == Set(["invite", "code"]) else {
            return ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
        }
        
        // link already exists
        if let link = conversation.link {
            return ZMTransportResponse(payload: ["uri": link,
                                                 "key": "test-key",
                                                 "code": "test-code"] as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        }
        // new link must be created
        else {
            let link = "https://wire-website.com/test-link"
            
            conversation.link = link
            
            let payload = [
                    "conversation" : conversationId,
                    "data" : [
                        "uri" : link,
                        "key" : "test-key",
                        "code" : "test-code"
                    ],
                    "type" : "conversation.code-update",
                    "time" : NSDate().transportString(),
                    "from" : selfUser.identifier
            ] as ZMTransportData
            return ZMTransportResponse(payload: payload, httpStatus: 201, transportSessionError: nil)
        }
        
    }
    
    @objc(processDeleteLinkForConversation:payload:)
    public func processDeleteLink(for conversationId: String, payload: [String: AnyHashable]) -> ZMTransportResponse {
        guard let conversation = fetchConversation(with: conversationId) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        guard Set(conversation.accessMode) == Set(["invite", "code"]) else {
            return ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
        }
        
        // link already exists
        if let _ = conversation.link {
            conversation.link = nil
            return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil)
        }
        // new link must be created
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil)
        }
    }

    /// Returns a response for the POST "/conversations/join" request
    /// - Parameter query: payload
    /// - Returns: response payload depending on code value:
    /// - "existing-conversation-code" -  response payload should have a httpStatus 204
    /// - "test-code" -  response payload should contain a new conversation
    /// - "wrong-code" - there should be an error in the response payload
    @objc(processJoinConversationWithPayload:)
    public func processJoinConversation(with payload: [String: AnyHashable]) -> ZMTransportResponse {
        guard let code = payload["code"] as? String else {
            let payload = ["label" : "no-conversation-code"] as ZMTransportData
            return ZMTransportResponse(payload: payload, httpStatus: 404, transportSessionError: nil)
        }

        switch code {
        case "existing-conversation-code":
            return ZMTransportResponse(payload: nil, httpStatus: 204, transportSessionError: nil)

        case "test-code":
            let creator = insertUserWithName(name: "Bob")
            let conversation = MockConversation.insert(into: managedObjectContext, creator: creator, otherUsers: [], type: .group)

            let responsePayload = [
                "conversation" : conversation.identifier,
                "type" : "conversation.member-join",
                "time" : NSDate().transportString(),
                "data": [
                    "users" : [
                        [
                            "conversation_role": "wire_member",
                            "id": selfUser.identifier
                        ]
                    ],
                    "user_ids": [
                        selfUser.identifier
                    ]
                ],
                "from" : selfUser.identifier] as ZMTransportData
            return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)

        default:
            let payload = ["label" : "no-conversation-code"] as ZMTransportData
            return ZMTransportResponse(payload: payload, httpStatus: 404, transportSessionError: nil)
        }
    }


    /// Returns a response for the GET "/conversations/join" request
    /// - Parameter query: request query
    /// - Returns: response payload containing conversation ID and name depending on code value:
    /// - "existing-conversation-code" -  response payload should contain an existing conversation with a selfUser
    /// - "test-code" -  response payload should contain a new conversation ID
    /// - "wrong-code" - there should be an error in the response payload
    @objc(processFetchConversationIdAndNameWith:)
    public func processFetchConversationIdAndName(with query: [String: AnyHashable]) -> ZMTransportResponse {
        guard let code = query["code"] as? String else {
            let payload = ["label" : "no-conversation-code"] as ZMTransportData
            return ZMTransportResponse(payload: payload, httpStatus: 404, transportSessionError: nil)
        }

        switch code {
        case "existing-conversation-code":
            let conversation = fetchConversation(selfUserIdentifier: selfUser.identifier)
            let responsePayload = [
                "id" : conversation!.identifier,
                "name" : "Test"] as ZMTransportData
            return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)

        case "test-code":
            let responsePayload = [
                "id" : UUID.create().transportString(),
                "name" : "Test"] as ZMTransportData
            return ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)

        default:
            let payload = ["label" : "no-conversation-code"] as ZMTransportData
            return ZMTransportResponse(payload: payload, httpStatus: 404, transportSessionError: nil)
        }
    }

    @objc
    public func processAddOTRMessage(toConversation conversationID: String,
                                     withProtobuffData data: Data,
                                     query: [String: Any]) -> ZMTransportResponse {
        guard
            let conversation = fetchConversation(with: conversationID),
            let otrMetaData = try? NewOtrMessage(serializedData: data),
            let senderClient = otrMessageSender(fromClientId: otrMetaData.sender) else {
                return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        var onlyForUser = query["report_missing"] as? String
        if otrMetaData.reportMissing.count > 0, let userId = otrMetaData.reportMissing.first {
            onlyForUser = UUID(data: userId.uuid)?.transportString()
        }
        
        let missedClients = self.missedClients(fromRecipients: otrMetaData.recipients, conversation: conversation, sender: senderClient, onlyForUserId: onlyForUser)
        let deletedClients = self.deletedClients(fromRecipients: otrMetaData.recipients, conversation: conversation)
        
        let payload: [String: Any] = [
            "missing": missedClients,
            "deleted": deletedClients,
            "time": Date().transportString()
        ]
        
        var statusCode = 412
        if missedClients.isEmpty {
            statusCode = 201
            insertOTRMessageEvents(
                toConversation: conversation,
                recipients: otrMetaData.recipients,
                senderClient: senderClient,
                createEventBlock: { recipient, messageData, decryptedData in
                    let event = conversation.insertOTRMessage(from: senderClient, to: recipient, data: messageData)
                    event.decryptedOTRData = decryptedData
                    return event
                })
        }
        
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: statusCode, transportSessionError: nil)
    }

    private func fetchConversation(selfUserIdentifier: String) -> MockConversation? {
        let request = MockConversation.sortedFetchRequest()
        request.predicate = NSPredicate(format: "selfIdentifier == %@", selfUserIdentifier.lowercased())
        let conversations = managedObjectContext.executeFetchRequestOrAssert(request) as? [MockConversation]
        return conversations?.first
    }
}
