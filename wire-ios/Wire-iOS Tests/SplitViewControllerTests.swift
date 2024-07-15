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

import XCTest

@testable import Wire

final class SplitViewControllerTests: XCTestCase {

    var sut: SplitViewController!
    var mockParentViewController: UIViewController!

    override func setUp() {
        super.setUp()

        UIView.setAnimationsEnabled(false)

        sut = SplitViewController()

        mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut)
    }

    override func tearDown() {
        sut = nil
        mockParentViewController = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    func testThatSwitchFromRegularModeToCompactModeChildViewsUpdatesTheirSize() {
        // GIVEN

        // simulate iPad Pro 12.9 inch landscape mode
        let iPadHeight: CGFloat = 1024
        let iPadWidth: CGFloat = 1366
        let listViewWidth: CGFloat = 336
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: iPadWidth, height: iPadHeight))

        let regularTraitCollection = UITraitCollection(horizontalSizeClass: .regular)
        mockParentViewController.setOverrideTraitCollection(regularTraitCollection, forChild: sut)
        sut.view.layoutIfNeeded()

        let leftViewWidth = sut.leftView.frame.width

        // check the width match the hard code value in SplitViewController
        XCTAssertEqual(leftViewWidth, listViewWidth)
        XCTAssertEqual(sut.rightView.frame.width, iPadWidth - listViewWidth)

        // WHEN
        let compactWidth = round(iPadWidth / 3)
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: compactWidth, height: iPadHeight))
        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChild: sut)
        sut.view.layoutIfNeeded()

        // THEN
        XCTAssertEqual(sut.leftView.frame.width, compactWidth)
        XCTAssertEqual(sut.rightView.frame.width, compactWidth)
    }

    private func setupLeftView(isLeftViewControllerRevealed: Bool,
                               animated: Bool = true,
                               file: StaticString = #file,
                               line: UInt = #line) {
        sut.leftViewController = UIViewController()
        sut.rightViewController = UIViewController()

        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChild: sut)

        sut.isLeftViewControllerRevealed = isLeftViewControllerRevealed
        sut.setLeftViewControllerRevealed(isLeftViewControllerRevealed, animated: animated)

        XCTAssertEqual(sut.rightView.frame.origin.x, isLeftViewControllerRevealed ? sut.leftView.frame.size.width : 0, file: file, line: line)
    }

    /// TODO
    func testThatSetLeftViewControllerUnrevealedWithoutAnimationHidesLeftView() {
        // GIVEN
        setupLeftView(isLeftViewControllerRevealed: true, animated: false)

        // WHEN
        sut.setLeftViewControllerRevealed(false, animated: false)

        // THEN
        XCTAssert(sut.leftView.isHidden)
    }
}
