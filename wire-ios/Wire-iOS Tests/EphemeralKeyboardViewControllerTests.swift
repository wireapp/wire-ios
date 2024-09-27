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

// MARK: - EphemeralKeyboardViewControllerTests

final class EphemeralKeyboardViewControllerTests: CoreDataSnapshotTestCase {
    // MARK: Internal

    var sut: EphemeralKeyboardViewController!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        conversation = createGroupConversation()
        conversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)
        sut = EphemeralKeyboardViewController(conversation: conversation)
    }

    override func tearDown() {
        snapshotHelper = nil
        conversation = nil
        sut = nil
        super.tearDown()
    }

    func testThatItRendersCorrectInitially() {
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectIntially_DarkMode() {
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.prepareForSnapshots())
    }

    // MARK: Private

    private var snapshotHelper: SnapshotHelper!
}

extension UIViewController {
    fileprivate func prepareForSnapshots() -> UIView {
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 290),
            view.widthAnchor.constraint(equalToConstant: 375),
        ])

        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()

        view.layer.speed = 0
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view
    }
}
