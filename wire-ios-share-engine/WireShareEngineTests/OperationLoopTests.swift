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
import WireDataModel
import WireRequestStrategy
import WireTesting
import XCTest
@testable import WireShareEngine

final class OperationLoopTests: ZMTBaseTest {
    var coreDataStack: CoreDataStack! = nil
    var sut: OperationLoop! = nil

    var uiMoc: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    var syncMoc: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() {
        super.setUp()
        let accountId = UUID()
        let directoryURL = try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let account = Account(userName: "", userIdentifier: accountId)

        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: directoryURL,
            inMemoryStore: true,
            dispatchGroup: dispatchGroup
        )
        coreDataStack.loadStores { error in
            XCTAssertNil(error)
        }

        self.coreDataStack = coreDataStack
        sut = OperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: OperationQueue()
        )
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
        super.tearDown()
    }
}

extension OperationLoopTests {
    func testThatItMergesUiContextInSyncContext() {
        let userID = UUID()

        var syncUser: ZMUser!
        syncMoc.performGroupedBlock { [unowned self] in
            syncUser = ZMUser.fetchOrCreate(with: userID, domain: nil, in: syncMoc)
            syncMoc.saveOrRollback()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNotNil(syncUser)
        XCTAssertNil(syncUser.name)

        uiMoc.performGroupedBlock {
            let uiUser = ZMUser.fetch(with: userID, domain: nil, in: self.uiMoc)!
            uiUser.name = "Jean Claude YouKnowWho"
            XCTAssertNotNil(uiUser)
            self.uiMoc.saveOrRollback()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(syncUser.name, "Jean Claude YouKnowWho")
    }

    func testThatItMergesSyncContextInUIContext() {
        let userID = UUID()

        var syncUser: ZMUser!
        coreDataStack.syncContext.performGroupedBlock { [unowned self] in
            syncUser = ZMUser.fetchOrCreate(with: userID, domain: nil, in: syncMoc)
            syncMoc.saveOrRollback()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNotNil(syncUser)
        XCTAssertNil(syncUser.name)

        var uiUser: ZMUser!
        uiMoc.performGroupedBlock {
            uiUser = ZMUser.fetch(with: userID, domain: nil, in: self.uiMoc)!
            XCTAssertNotNil(uiUser)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMoc.performGroupedAndWait {
            syncUser.name = "Jean Claude YouKnowWho"
            self.syncMoc.saveOrRollback()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(uiUser.name, syncUser.name)
    }

    func testThatItGeneratesTheExpectedRequest() {
        var count = 0
        sut.requestAvailableClosure = {
            count += 1
        }
        XCTAssertEqual(count, 0)

        sut.newRequestsAvailable()
        XCTAssertEqual(count, 1)

        sut.newRequestsAvailable()
        XCTAssertEqual(count, 2)
    }
}
