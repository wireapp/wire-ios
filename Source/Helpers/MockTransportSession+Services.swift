//
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
import WireDataModel

extension MockTransportSession {
    @objc(processServicesSearchRequest:)
    public func processServicesSearchRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard let _ = request.queryParameters["tags"] as? String,
                let startsWith = request.queryParameters["start"] as? String else {
                    return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        }
        
        let predicate = NSPredicate(format: "%K beginswith[c] %@", #keyPath(MockService.name), startsWith)
        
        let services: [MockService] = MockService.fetchAll(in: managedObjectContext, withPredicate: predicate)
        
        let payload: [String : Any] = [
            "services" : services.map { $0.payload },
            "has_more" : false
        ]
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
    }
    
    @objc(processServiceRequest:)
    public func processServiceRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {
        guard let payload = request.payload as? [String: Any?],
              let serviceId = payload["service"] as? String,
              let providerId = payload["provider"] as? String,
              let conversationId = request.RESTComponents(index: 1) else {
                return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil)
        }
        
        // Fetch conversation
        guard let conversation = MockConversation.existingConversation(with: conversationId, managedObjectContext: managedObjectContext) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        guard let service = MockService.existingService(with: serviceId, provider: providerId, managedObjectContext: managedObjectContext) else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
        }
        
        var newServiceUser: MockUser!
        
        self.performRemoteChanges { change in
            newServiceUser = change.insertUser(withName: service.name)
            change.addV3ProfilePicture(to: newServiceUser)
            newServiceUser.accentID = Int16(service.accentID)
            newServiceUser.serviceIdentifier = service.identifier
            newServiceUser.providerIdentifier = service.provider
        }
        
        conversation.addUsers(by: selfUser, addedUsers: [newServiceUser])
        
        let responsePayload: [String: Any?] = [
            "id": newServiceUser.identifier,
            "client": (newServiceUser.clients.anyObject() as! MockUserClient).identifier!,
            "name": newServiceUser.name!,
            "accent_id": newServiceUser.accentID,
            "assets": newServiceUser.assetData,
            "event": [
                "type": "conversation.member-join",
                "conversation": conversation.identifier,
                "from": selfUser.identifier,
                "time": Date().transportString(),
                "data": ["user_ids": [newServiceUser.identifier]]
            ]
        ]
        
        return ZMTransportResponse(payload: responsePayload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
    }
    
    @objc(insertServiceWithName:handle:accentID:identifier:provider:assets:)
    public func insertService(name: String, handle: String, accentID: Int, identifier: String, provider: String, assets: Set<MockAsset>) -> MockService {
        let mockService: MockService = MockService.insert(in: managedObjectContext)
        mockService.name = name
        mockService.handle = handle
        mockService.accentID = accentID
        mockService.identifier = identifier
        mockService.provider = provider
        mockService.assets = assets
        managedObjectContext.saveOrRollback()
        return mockService
    }
}
