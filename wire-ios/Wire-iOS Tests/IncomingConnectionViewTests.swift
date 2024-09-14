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

import WireDesign
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - IncomingConnectionViewTests

final class IncomingConnectionViewTests: XCTestCase {

    // MARK: - Properties

    private let sutBackgroundColor = SemanticColors.View.backgroundDefault
    private var snapshotHelper: SnapshotHelper_!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        accentColor = .blue
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersWithUserName() {
        let user = SwiftMockLoader.mockUsers().first!
        let sut = IncomingConnectionView(user: user)

        sut.backgroundColor = sutBackgroundColor
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

    func testThatItRendersWithUnconnectedUser() {
        let user = MockUserType.createUser(name: "Test")
        user.isConnected = false
        let sut = IncomingConnectionView(user: user)

        sut.backgroundColor = .white
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

    func testThatItRendersWithUserName_NoHandle() {
        let user = SwiftMockLoader.mockUsers().last! // The last user does not have a username
        let sut = IncomingConnectionView(user: user)

        sut.backgroundColor = sutBackgroundColor
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

    func testThatItRendersWithSecurityClassification_whenClassified() {
        let user = SwiftMockLoader.mockUsers().first!
        let mockClassificationProvider = MockSecurityClassificationProviding()
        mockClassificationProvider.classificationUsersConversationDomain_MockValue = .classified

        let sut = IncomingConnectionView(user: user, classificationProvider: mockClassificationProvider)

        sut.backgroundColor = sutBackgroundColor
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

    func testThatItRendersWithSecurityClassification_whenNotClassified() {
        let user = SwiftMockLoader.mockUsers().first!
        let mockClassificationProvider = MockSecurityClassificationProviding()
        mockClassificationProvider.classificationUsersConversationDomain_MockValue = .notClassified

        let sut = IncomingConnectionView(user: user, classificationProvider: mockClassificationProvider)

        sut.backgroundColor = sutBackgroundColor
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

    func testThatItRendersWithFederatedUser() {
        let user = SwiftMockLoader.mockUsers().first!
        let mockClassificationProvider = MockSecurityClassificationProviding()
        mockClassificationProvider.classificationUsersConversationDomain_MockValue = .notClassified
        user.isFederated = true

        let sut = IncomingConnectionView(user: user, classificationProvider: mockClassificationProvider)

        sut.backgroundColor = sutBackgroundColor
        snapshotHelper.verify(matching: sut.layoutForTest())
    }

}

// MARK: - UIView extension

private extension UIView {

    func layoutForTest(in size: CGSize = .init(width: 375, height: 667)) -> UIView {
        let fittingSize = systemLayoutSizeFitting(size)
        frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height)
        return self
    }

}
