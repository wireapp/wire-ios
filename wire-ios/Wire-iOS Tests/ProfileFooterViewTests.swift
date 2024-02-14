//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class ProfileFooterViewTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: ProfileFooterView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = ProfileFooterView()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Unit Test

    func testThatItOnlyAllowsEligibleActionsAsKey() {

        // WHEN: the first action is eligible
        sut.configure(with: [.openOneToOne, .archive])
        XCTAssertEqual(sut.leftAction, .openOneToOne)
        XCTAssertEqual(sut.rightActions, [.archive])

        // WHEN: the first action is not eligible
        sut.configure(with: [.archive, .openOneToOne])
        XCTAssertEqual(sut.leftAction, nil)
        XCTAssertEqual(sut.rightActions, [.archive, .openOneToOne])

        // WHEN: the only action is eligible
        sut.configure(with: [.openOneToOne])
        XCTAssertEqual(sut.leftAction, .openOneToOne)
        XCTAssertEqual(sut.rightActions, [])

        // WHEN: the only action is not eligible
        sut.configure(with: [.archive])
        XCTAssertEqual(sut.leftAction, nil)
        XCTAssertEqual(sut.rightActions, [.archive])
    }

    // MARK: - Snapshot Tests

    func testWithOneAction() {
        sut = setupProfileFooterView(configureProfileActions: [.openOneToOne])
        verify(matching: sut)
    }

    func testWithMultipleActions() {
        sut = setupProfileFooterView(configureProfileActions: [.openOneToOne, .archive])
        verify(matching: sut)
    }

    func testThatItUpdates() {
        sut = setupProfileFooterView(configureProfileActions: [.openOneToOne, .archive, .createGroup])
        verify(matching: sut)
    }

    // MARK: - Helper Method

    func setupProfileFooterView(
        userInterfaceStyle: UIUserInterfaceStyle = .light,
        configureProfileActions: [ProfileAction]
    ) -> ProfileFooterView {
        let view = ProfileFooterView()
        view.overrideUserInterfaceStyle = userInterfaceStyle
        view.frame.size = view.systemLayoutSizeFitting(CGSize(width: 375, height: 0))
        view.configure(with: configureProfileActions)

        return view
    }

}
