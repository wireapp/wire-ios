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

import UIKit
import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - MockDestination

final class MockDestination: NSObject, ShareDestination {
    // MARK: Lifecycle

    init(
        displayName: String,
        avatarView: UIView? = nil,
        securityLevel: ZMConversationSecurityLevel = .notSecure,
        showsGuestIcon: Bool = false,
        isUnderLegalHold: Bool = false
    ) {
        self.displayNameWithFallback = displayName
        self.securityLevel = securityLevel
        self.avatarView = avatarView
        self.showsGuestIcon = showsGuestIcon
        self.isUnderLegalHold = isUnderLegalHold
    }

    // MARK: Internal

    var isUnderLegalHold: Bool

    var showsGuestIcon: Bool

    var displayNameWithFallback: String

    var securityLevel: ZMConversationSecurityLevel

    var avatarView: UIView?
}

// MARK: - ShareDestinationCellTests

final class ShareDestinationCellTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .red
        sut = ShareDestinationCell(style: .default, reuseIdentifier: "reuseIdentifier")

        sut.backgroundColor = .black
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        destination = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .notSecure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .notSecure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked_LegalHold() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .notSecure,
            isUnderLegalHold: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Unchecked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .notSecure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Unchecked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .notSecure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Checked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .notSecure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Checked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .notSecure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Checked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .notSecure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Checked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .notSecure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .secure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .secure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked_Guest_LegalHold() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .secure,
            showsGuestIcon: true,
            isUnderLegalHold: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Unchecked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .secure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Unchecked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .secure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Checked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .secure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Checked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "John Burger",
            avatarView: mockAvatarView,
            securityLevel: .secure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Checked() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .secure
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Checked_Guest() {
        // GIVEN
        let destination = MockDestination(
            displayName: "His Majesty John Carl Steven Bob Burger II",
            avatarView: mockAvatarView,
            securityLevel: .secure,
            showsGuestIcon: true
        )
        // WHEN
        sut.destination = destination

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ShareDestinationCell<MockDestination>!
    private var destination: MockDestination?

    private var mockAvatarView: UIImageView {
        // just using a simple UIImageView, since ConversationAvatarView is covered in ConversationAvatarViewTests
        let imageView = UIImageView(image: image(inTestBundleNamed: "unsplash_burger.jpg"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
}

// MARK: - Helper

extension UITableViewCell {
    fileprivate func prepareForSnapshotWithCellSelected() -> UITableView {
        let view = prepareForSnapshots()
        view.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        return view
    }
}
