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
import XCTest
import WireTesting
@testable import WireDataModel

public class DiskDatabaseTest: ZMTBaseTest {
    var sharedContainerURL : URL!
    var accountId : UUID!
    var moc: NSManagedObjectContext {
        return contextDirectory.uiContext
    }
    var contextDirectory: ManagedObjectContextDirectory!
    
    var storeURL : URL {
        return StorageStack.accountFolder(
            accountIdentifier: accountId,
            applicationContainer: sharedContainerURL
            ).appendingPersistentStoreLocation()
    }
    
    public override func setUp() {
        super.setUp()
        
        accountId = .create()
        sharedContainerURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(UUID().uuidString)")
        cleanUp()
        createDatabase()
        setupCaches()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 1))
        XCTAssert(FileManager.default.fileExists(atPath: storeURL.path))
    }
    
    public override func tearDown() {
        cleanUp()
        contextDirectory = nil
        sharedContainerURL = nil
        accountId = nil
        super.tearDown()
    }
    
    private func setupCaches() {
        contextDirectory.uiContext.zm_userImageCache = UserImageLocalCache(location: nil)
        contextDirectory.uiContext.zm_fileAssetCache = FileAssetCache(location: nil)
        
        contextDirectory.syncContext.performGroupedBlockAndWait {
            self.contextDirectory.syncContext.zm_fileAssetCache = self.contextDirectory.uiContext.zm_fileAssetCache
            self.contextDirectory.syncContext.zm_userImageCache = self.contextDirectory.uiContext.zm_userImageCache
        }
    }
    
    private func createDatabase() {
        StorageStack.reset()
        StorageStack.shared.createStorageAsInMemory = false
        
        let expectation = self.expectation(description: "Created context")
        StorageStack.shared.createManagedObjectContextDirectory(accountIdentifier: accountId, applicationContainer: storeURL, dispatchGroup: self.dispatchGroup) {
            self.contextDirectory = $0
            expectation.fulfill()
        }
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        self.moc.performGroupedBlockAndWait {
            let selfUser = ZMUser.selfUser(in: self.moc)
            selfUser.remoteIdentifier = self.accountId
        }
    }
    
    private func cleanUp() {
        try? FileManager.default.contentsOfDirectory(at: sharedContainerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
        
        StorageStack.reset()
    }
}

extension DiskDatabaseTest {
    
    func createClient(user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: self.moc)
        client.user = user
        client.remoteIdentifier = UUID().transportString()
        return client
    }
    
    func createUser() -> ZMUser {
        let user = ZMUser.insertNewObject(in: self.moc)
        user.remoteIdentifier = UUID()
        return user
    }
    
    func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.moc)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }
    
    func createTeam() -> Team {
        let team = Team.insertNewObject(in: self.moc)
        team.remoteIdentifier = UUID()
        return team
    }
    
    func createMembership(user: ZMUser, team: Team) -> Member {
        let member = Member.insertNewObject(in: self.moc)
        member.user = user
        member.team = team
        return member
    }
    
    func createConnection(to: ZMUser, conversation: ZMConversation) -> ZMConnection {
        let connection = ZMConnection.insertNewObject(in: self.moc)
        connection.to = to
        connection.conversation = conversation
        connection.status = .accepted
        return connection
    }
}
