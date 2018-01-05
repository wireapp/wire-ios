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
