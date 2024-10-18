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

import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - Helper

extension UIView {

    func layoutForTest(in size: CGSize = CGSize(width: 320, height: 480)) {
        let fittingSize = self.systemLayoutSizeFitting(size)
        self.frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }
}

// MARK: - UserConnectionViewSnapshotTests

final class UserConnectionViewSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var mockUser: MockUserType!
    private var sut: UserConnectionView!

    // MARK: - setUp

    override func setUp() {
        snapshotHelper = SnapshotHelper()
        accentColor = .purple
        mockUser = SwiftMockLoader.mockUsers().first!
        sut = sutForUser(mockUser)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        mockUser = nil
        sut = nil
        UIColor.setAccentOverride(nil)
    }

    // MARK: - Helper Method

    func sutForUser(_ mockUser: MockUserType, isFederated: Bool = false) -> UserConnectionView {
        mockUser.isPendingApprovalByOtherUser = true
        mockUser.isPendingApprovalBySelfUser = false
        mockUser.isConnected = false
        mockUser.isFederated = isFederated
        mockUser.domain = "wire.com"

        let connectionView = UserConnectionView(user: mockUser)
        connectionView.layoutForTest()

        return connectionView
    }

    // MARK: - Snapshot Tests

    func testWithUserName() {
        sut.layoutForTest()
        snapshotHelper.verify(matching: sut)
    }

    func testWithUserName_Federated() {
        sut = sutForUser(mockUser, isFederated: true)
        sut.layoutForTest()
        snapshotHelper.verify(matching: sut)
    }

    func testWithoutUserName() {
        // The last mock user does not have a handle
        mockUser = SwiftMockLoader.mockUsers().last!
        sut = sutForUser(mockUser)
        sut.layoutForTest()
        snapshotHelper.verify(matching: sut)
    }

}
