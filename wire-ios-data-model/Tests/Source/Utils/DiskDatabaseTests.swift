//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireTesting
import XCTest
@testable import WireDataModel

public class DiskDatabaseTest: ZMTBaseTest {
    var cacheURL: URL!
    var sharedContainerURL: URL!
    var accountId: UUID!
    var moc: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    var coreDataStack: CoreDataStack!

    var storeURL: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: accountId,
            applicationContainer: sharedContainerURL
        ).appendingPersistentStoreLocation()
    }

    override public func setUp() {
        super.setUp()

        accountId = .create()
        cacheURL = FileManager.default.randomCacheURL
        sharedContainerURL = cacheURL.appendingPathComponent(UUID().uuidString)
        cleanUp()
        createDatabase()
        setupCaches()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 1))
        XCTAssert(FileManager.default.fileExists(atPath: storeURL.path))
    }

    override public func tearDown() {
        moc.persistentStoreCoordinator?.persistentStores.forEach {
            try! self.moc.persistentStoreCoordinator!.remove($0)
        }

        coreDataStack = nil
        accountId = nil
        cleanUp()
        sharedContainerURL = nil
        super.tearDown()
    }

    private func setupCaches() {
        coreDataStack.viewContext.zm_userImageCache = UserImageLocalCache(location: nil)
        coreDataStack.viewContext.zm_fileAssetCache = FileAssetCache(location: cacheURL)

        coreDataStack.syncContext.performGroupedAndWait {
            self.coreDataStack.syncContext.zm_fileAssetCache = self.coreDataStack.viewContext.zm_fileAssetCache
            self.coreDataStack.syncContext.zm_userImageCache = self.coreDataStack.viewContext.zm_userImageCache
        }
    }

    private func createDatabase() {
        let account = Account(userName: "", userIdentifier: accountId)
        coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            inMemoryStore: false,
            dispatchGroup: dispatchGroup
        )

        coreDataStack.loadStores { error in
            XCTAssertNil(error)
        }

        moc.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.moc)
            selfUser.remoteIdentifier = self.accountId
        }
    }

    private func cleanUp() {
        try? FileManager.default.contentsOfDirectory(
            at: sharedContainerURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
}

extension DiskDatabaseTest {
    func createClient(user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: moc)
        client.user = user
        client.remoteIdentifier = UUID().transportString()
        return client
    }

    func createUser() -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.remoteIdentifier = UUID()
        return user
    }

    func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }

    func createTeam() -> Team {
        let team = Team.insertNewObject(in: moc)
        team.remoteIdentifier = UUID()
        return team
    }

    func createMembership(user: ZMUser, team: Team) -> Member {
        let member = Member.insertNewObject(in: moc)
        member.user = user
        member.team = team
        return member
    }

    func createConnection(to: ZMUser, conversation: ZMConversation) -> ZMConnection {
        let connection = ZMConnection.insertNewObject(in: moc)
        connection.to = to
        to.oneOnOneConversation = conversation
        connection.status = .accepted
        return connection
    }
}
