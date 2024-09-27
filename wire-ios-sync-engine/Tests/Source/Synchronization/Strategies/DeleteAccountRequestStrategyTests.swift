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
import WireSyncEngine
import WireTransport

class DeleteAccountRequestStrategyTests: MessagingTest, AccountDeletedObserver {
    // MARK: Internal

    var observers: [Any] = []

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        sut = DeleteAccountRequestStrategy(
            withManagedObjectContext: uiMOC,
            applicationStatus: mockApplicationStatus,
            cookieStorage: cookieStorage
        )
    }

    override func tearDown() {
        sut = nil
        observers = []
        super.tearDown()
    }

    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItGeneratesARequest() {
        // given
        uiMOC.setPersistentStoreMetadata(
            NSNumber(value: true),
            key: DeleteAccountRequestStrategy.userDeletionInitiatedKey
        )

        // when
        let request: ZMTransportRequest? = sut.nextRequest(for: .v0)

        // then
        if let request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.delete)
            XCTAssertEqual(request.path, "/self")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItGeneratesARequestOnlyOnce() {
        // given
        uiMOC.setPersistentStoreMetadata(
            NSNumber(value: true),
            key: DeleteAccountRequestStrategy.userDeletionInitiatedKey
        )

        // when
        let request1: ZMTransportRequest? = sut.nextRequest(for: .v0)
        let request2: ZMTransportRequest? = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request1)
        XCTAssertNil(request2)
    }

    func testThatItSignsUserOutWhenSuccessful() {
        // given
        ZMUser.selfUser(in: uiMOC).remoteIdentifier = UUID()
        uiMOC.setPersistentStoreMetadata(
            NSNumber(value: true),
            key: DeleteAccountRequestStrategy.userDeletionInitiatedKey
        )

        observers.append(AccountDeletedNotification.addObserver(
            observer: self,
            queue: DispatchGroupQueue(queue: .main)
        ))

        // when
        let request1: ZMTransportRequest! = sut.nextRequest(for: .v0)
        request1.complete(with: ZMTransportResponse(
            payload: NSDictionary(),
            httpStatus: 201,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        ))

        // then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(accountDeleted)
    }

    func accountDeleted(accountId: UUID) {
        accountDeleted = true
    }

    // MARK: Fileprivate

    fileprivate var sut: DeleteAccountRequestStrategy!
    fileprivate var mockApplicationStatus: MockApplicationStatus!
    fileprivate let cookieStorage = ZMPersistentCookieStorage()

    // MARK: Private

    private var accountDeleted = false
}
