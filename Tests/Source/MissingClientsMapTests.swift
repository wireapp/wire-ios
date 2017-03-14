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


import XCTest
@testable import WireMessageStrategy
import ZMTesting
import ZMCDataModel


class MissingClientsMapTests: MessagingTestBase {
    
    func testThatItCreatesMissingMapForClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // given
            let user1Client1 = self.createClient()
            let user1Client2 = self.createClient(user1Client1.user)
            let user2Client1 = self.createClient()
            
            // when
            let sut = MissingClientsMap([user1Client1, user1Client2, user2Client1], pageSize: 2)
            
            // then
            guard let user1Id = user1Client1.user?.remoteIdentifier?.transportString(),
                let user2Id = user2Client1.user?.remoteIdentifier?.transportString() else { return XCTFail() }
            
            XCTAssertEqual(sut.payload.keys.count, 2)
            XCTAssertEqual(sut.payload[user1Id]?.count, 2)
            XCTAssertEqual(sut.payload[user2Id]?.count, 1)
            
            self.assertPayloadContainsClient(sut, user1Client1)
            self.assertPayloadContainsClient(sut, user1Client2)
            self.assertPayloadContainsClient(sut, user2Client1)
            self.assertExpectedUserInfo(sut, user1Client1, user1Client2, user2Client1)
        }
    }

    func testThatItPaginatesMissedClientsMapBasedOnUserCountPageSize() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // given
            let user1Client1 = self.createClient()
            let user1Client2 = self.createClient(user1Client1.user)
            
            // when
            let sut = MissingClientsMap([user1Client1, user1Client2], pageSize: 1)
            
            // then
            XCTAssertEqual(sut.payload.keys.count, 1)
            self.assertPayloadContainsClient(sut, user1Client1)
            self.assertPayloadContainsClient(sut, user1Client2)
            self.assertExpectedUserInfo(sut, user1Client1, user1Client2)
        }
    }
    
    func testThatItPaginatesMissedClientsMapBasedOnUserCount_toManyUsers() {
        
        syncMOC.performGroupedBlockAndWait {
            
            // given
            let user1Client1 = self.createClient()
            let user2Client1 = self.createClient()
            let user2Client2 = self.createClient(user2Client1.user)
            let user3Client1 = self.createClient()
            
            // when
            let sut = MissingClientsMap([user1Client1, user2Client1, user2Client2, user3Client1], pageSize: 2)
            
            // then
            XCTAssertEqual(sut.payload.keys.count, 2)
            self.assertPayloadContainsClient(sut, user1Client1)
            self.assertPayloadContainsClient(sut, user2Client1)
            self.assertPayloadContainsClient(sut, user2Client2)
            
            guard let user3Id = user3Client1.user?.remoteIdentifier?.transportString() else { return XCTFail() }
            XCTAssertNil(sut.payload[user3Id])
            self.assertExpectedUserInfo(sut, user1Client1, user2Client1, user2Client2)
        }
    }
    
    // MARK: - Helper
    
    func assertExpectedUserInfo(_ missingClientsMap: MissingClientsMap, _ clients: UserClient...) {
        let identifiers = Set(clients.map { $0.remoteIdentifier! })
        guard let actualClients = missingClientsMap.userInfo["clients"].map(Set.init) else { return XCTFail() }
        XCTAssertEqual(actualClients, identifiers)
    }
    
    func assertPayloadContainsClient(_ missingClientsMap: MissingClientsMap, _ client: UserClient) {
        guard let userId = client.user?.remoteIdentifier?.transportString(), let clientPayload = missingClientsMap.payload[userId] else { return XCTFail()}
        XCTAssertTrue(clientPayload.contains(client.remoteIdentifier!))
    }
    
    func createClient(_ forUser: ZMUser? = nil) -> UserClient {
        let client = UserClient.insertNewObject(in: syncMOC)
        client.remoteIdentifier = UUID.create().transportString()
        let user: ZMUser = forUser ?? ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = forUser?.remoteIdentifier ?? UUID.create()
        client.user = user
        return client
    }
}
