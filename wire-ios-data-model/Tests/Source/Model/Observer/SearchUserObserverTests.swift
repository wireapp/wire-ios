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
import WireDataModelSupport
@testable import WireDataModel

final class SearchUserObserverTests: NotificationDispatcherTestBase {
    private final class TestSearchUserObserver: UserObserving {
        var receivedChangeInfo: [UserChangeInfo] = []

        func userDidChange(_ changeInfo: UserChangeInfo) {
            receivedChangeInfo.append(changeInfo)
        }
    }

    private var testObserver: TestSearchUserObserver!

    override func setUp() {
        super.setUp()
        testObserver = TestSearchUserObserver()
    }

    override func tearDown() {
        testObserver = nil
        uiMOC.searchUserObserverCenter.reset()
        super.tearDown()
    }

    func testThatItNotifiesTheObserverOfASmallProfilePictureChange() {
        // given
        let remoteID = UUID()
        let searchUser = makeSearchUser(name: "Hans", remoteIdentifier: remoteID)

        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        token = UserChangeInfo.add(observer: testObserver, for: searchUser, in: uiMOC)

        // when
        searchUser.updateImageData(for: .preview, imageData: verySmallJPEGData())

        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
    }

    func testThatItNotifiesTheObserverOfASmallProfilePictureChangeIfTheInternalUserUpdates() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()
        uiMOC.saveOrRollback()
        let searchUser = makeSearchUser(name: "", remoteIdentifier: nil, user: user)

        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        token = UserChangeInfo.add(observer: testObserver, for: searchUser, in: uiMOC)

        // when
        user.previewProfileAssetIdentifier = UUID().transportString()
        user.setImage(data: verySmallJPEGData(), size: .preview)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        // given
        let remoteID = UUID()
        let searchUser = makeSearchUser(name: "Hans", remoteIdentifier: remoteID)

        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        token = UserChangeInfo.add(observer: testObserver, for: searchUser, in: uiMOC)

        // when
        token = nil
        searchUser.updateImageData(for: .preview, imageData: verySmallJPEGData())

        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 0)
    }

    func testThatItNotifiesObserversWhenConnectingToASearchUserThatHasNoLocalUser() {
        // given
        let remoteID = UUID()
        let searchUser = makeSearchUser(name: "Hans", remoteIdentifier: remoteID)
        let actionHandler = MockActionHandler<ConnectToUserAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        XCTAssertFalse(searchUser.isPendingApprovalByOtherUser)
        uiMOC.searchUserObserverCenter.addSearchUser(searchUser)
        token = UserChangeInfo.add(observer: testObserver, for: searchUser, in: uiMOC)

        // when
        searchUser.connect(completion: { _ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(actionHandler.didPerformAction)
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        guard let note = testObserver.receivedChangeInfo.first else { return XCTFail() }
        XCTAssertEqual(note.user as? ZMSearchUser, searchUser)
        XCTAssertTrue(note.connectionStateChanged)
    }

    // MARK: - Helpers

    private func makeSearchUser(
        name: String,
        remoteIdentifier: UUID?,
        user: ZMUser? = nil
    ) -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            name: name,
            handle: name.lowercased(),
            accentColor: .amber,
            remoteIdentifier: remoteIdentifier,
            user: user,
            searchUsersCache: nil
        )
    }
}
