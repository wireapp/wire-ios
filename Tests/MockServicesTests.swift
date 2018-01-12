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
@testable import WireMockTransport

class MockServicesTests: MockTransportSessionTests {
    func testThatInsertedServiceCanBeQueried() {
        // given
        let service1 = sut.insertService(name: "Normal Service", handle: "", accentID: 5, identifier: UUID().transportString(), provider: UUID().transportString(), assets: Set())
        let _ = sut.insertService(name: "Other Service", handle: "", accentID: 5, identifier: UUID().transportString(), provider: UUID().transportString(), assets: Set())
        // when
        
        let response = sut.processServicesSearchRequest(ZMTransportRequest(path: "/services?tags=tutorial&start=Normal", method: .methodGET, payload: nil))
        // then
        XCTAssertEqual(response.httpStatus, 200)
        XCTAssertNotNil(response.payload?.asDictionary()?["services"])
        let services: [[String: AnyHashable]] = response.payload!.asDictionary()!["services"] as! [[String: AnyHashable]]
        XCTAssertEqual(services.count, 1)
        XCTAssertEqual(services[0]["name"], "Normal Service")
        XCTAssertEqual(services[0]["accent_id"], 5)
        XCTAssertEqual(services[0]["id"], service1.identifier)
        XCTAssertEqual(services[0]["provider"], service1.provider)
    }
    
    func testThatItCanAddServiceToTheConversation() {
        // given
        let _ = sut.insertSelfUser(withName: "Antonio")
        let service = sut.insertService(name: "Normal Service", handle: "", accentID: 5, identifier: UUID().transportString(), provider: UUID().transportString(), assets: Set())
        let conversation = sut.insertConversation(withCreator: sut.selfUser, otherUsers: [], type: .group)
        
        XCTAssertEqual(conversation.activeUsers.count, 1)
        // when
        let payload = ["service": service.identifier,
                       "provider": service.provider]
        let response = sut.processServiceRequest(ZMTransportRequest(path: "/conversations/\(conversation.identifier)/bots", method: .methodPOST, payload: payload as ZMTransportData))
        
        // then
        XCTAssertEqual(response.httpStatus, 201)
        XCTAssertNotNil(response.payload?.asDictionary())
        XCTAssertEqual(conversation.activeUsers.count, 2)

        let conversationUser = conversation.activeUsers.firstObject as! MockUser
        XCTAssertNil(conversationUser.serviceIdentifier)
        XCTAssertNil(conversationUser.providerIdentifier)

        let serviceUser = conversation.activeUsers.lastObject as! MockUser

        XCTAssertEqual(serviceUser.serviceIdentifier, service.identifier)
        XCTAssertEqual(serviceUser.providerIdentifier, service.provider)
    }
}

