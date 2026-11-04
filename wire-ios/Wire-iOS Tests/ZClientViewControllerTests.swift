//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDataModel
import WireDataModelSupport
import XCTest

@testable import Wire

final class ZClientViewControllerTests: XCTestCase {

    private var coreDataFixture: CoreDataFixture!
    private var imageTransformer: MockImageTransformer!
    private var sut: ZClientViewController!
    private var userSession: UserSessionMock!

    override func setUp() async throws {
        try await super.setUp()

        coreDataFixture = try await .init()
        imageTransformer = .init()
        userSession = UserSessionMock(mockUser: .createSelfUser(name: "Bob"))
        userSession.coreDataStack = coreDataFixture.coreDataStack
        sut = ZClientViewController(
            account: Account.mockAccount(imageData: mockImageData),
            contextProvider: DefaultManagedObjectContextProvider(contextProvider: coreDataFixture.coreDataStack),
            selfProfileViewsMonitor: MockSelfProfileViewsMonitorImplementation(didViewSelfProfile: false),
            userSession: userSession,
            trackingManager: nil,
            wireMeetingsFactory: MockWireMeetingsFactoryProtocol(),
            wireMessagingFactory: MockWireMessagingFactoryProtocol.makeDefault()
        )
    }

    override func tearDown() {
        sut = nil
        userSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func testThatCustomPasscodeWillBeDeleted_AfterUserNotifiedOfDisabledApplock() {
        // When
        sut.appLockChangeWarningViewControllerDidDismiss()

        // Then
        XCTAssertEqual(userSession.deleteAppLockPasscodeCalls, 1)
    }

    @MainActor
    func testThatNameOnlyChangeRefreshesAccountInitials() async {
        let user = coreDataFixture.selfUser!
        userSession.selfUser = user
        sut.account.imageData = nil
        user.name = "Bob"
        let changeInfo = UserChangeInfo(object: user)
        changeInfo.changedKeys = [#keyPath(UserType.previewImageData)]
        sut.userDidChange(changeInfo)
        let initialImage = XCTNSPredicateExpectation(predicate: NSPredicate { [self] _, _ in
            sut.cachedAccountImage == .text("B")
        }, object: nil)
        await fulfillment(of: [initialImage], timeout: 2)

        user.name = "Jane Doe"
        changeInfo.changedKeys = [#keyPath(ZMUser.name)]
        sut.userDidChange(changeInfo)
        let renamedImage = XCTNSPredicateExpectation(predicate: NSPredicate { [self] _, _ in
            sut.cachedAccountImage == .text("JD")
        }, object: nil)
        await fulfillment(of: [renamedImage], timeout: 2)
    }
}
