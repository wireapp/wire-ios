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

@testable import WireDataModel

final class SearchUserObserverCenterTests: ModelObjectsTests {
    // MARK: Internal

    var sut: SearchUserObserverCenter!

    override func setUp() {
        super.setUp()
        sut = SearchUserObserverCenter(managedObjectContext: uiMOC)
        uiMOC.userInfo[NSManagedObjectContext.SearchUserObserverCenterKey] = sut
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItDeallocates() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = makeSearchUser(
            name: "",
            handle: "",
            accentColor: nil,
            remoteIdentifier: UUID(),
            user: user
        )
        sut.addSearchUser(searchUser)

        // when
        weak var observerCenter = sut
        sut = nil
        uiMOC.userInfo.removeObject(forKey: NSManagedObjectContext.SearchUserObserverCenterKey)

        // then
        XCTAssertNil(observerCenter)
    }

    func testThatItAddsASnapshot() {
        // given
        let searchUser = makeSearchUser(
            name: "Bernd",
            handle: "dasBrot",
            accentColor: .amber,
            remoteIdentifier: UUID()
        )
        XCTAssertEqual(sut.snapshots.count, 0)

        // when
        sut.addSearchUser(searchUser)

        // then
        XCTAssertEqual(sut.snapshots.count, 1)
    }

    func testThatItRemovesAllSnapshotsOnReset() {
        // given
        let searchUser = makeSearchUser(
            name: "Bernd",
            handle: "dasBrot",
            accentColor: .amber,
            remoteIdentifier: UUID()
        )
        sut.addSearchUser(searchUser)
        XCTAssertEqual(sut.snapshots.count, 1)

        // when
        sut.reset()

        // then
        XCTAssertEqual(sut.snapshots.count, 0)
    }

    func testThatItForwardsUserChangeInfosToTheSnapshot() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        user.remoteIdentifier = UUID()

        let searchUser = makeSearchUser(
            name: "",
            handle: "",
            accentColor: nil,
            remoteIdentifier: nil,
            user: user
        )
        sut.addSearchUser(searchUser)

        // expect
        let expectation = customExpectation(description: "notified")
        let token: Any? = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: uiMOC.notificationContext,
            object: searchUser
        ) { _ in
            expectation.fulfill()
        }

        withExtendedLifetime(token) {
            // when
            user.name = "Horst"
            let changeInfo = UserChangeInfo(object: user)
            changeInfo.changedKeys = Set(["name"])
            sut.objectsDidChange(changes: [ZMUser.classIdentifier: [changeInfo]])

            // then
            XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItForwardCallsForUserUpdatesToTheSnapshot() {
        // given
        let searchUser = makeSearchUser(
            name: "Bernd",
            handle: "dasBrot",
            accentColor: .amber,
            remoteIdentifier: UUID()
        )
        sut.addSearchUser(searchUser)

        // expect
        let expectation = customExpectation(description: "notified")
        let token = NotificationInContext.addObserver(
            name: .SearchUserChange,
            context: uiMOC.notificationContext,
            object: searchUser
        ) { note in
            guard let changeInfo = note.changeInfo as? UserChangeInfo else { return }
            XCTAssertTrue(changeInfo.imageMediumDataChanged)
            expectation.fulfill()
        }

        withExtendedLifetime(token) {
            // when
            searchUser.updateImageData(for: .complete, imageData: verySmallJPEGData())

            // then
            XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    // MARK: Private

    // MARK: - Helpers

    private func makeSearchUser(
        name: String,
        handle: String,
        accentColor: ZMAccentColor?,
        remoteIdentifier: UUID?,
        user: ZMUser? = nil
    ) -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            name: name,
            handle: handle,
            accentColor: accentColor,
            remoteIdentifier: remoteIdentifier,
            user: user,
            searchUsersCache: nil
        )
    }
}
