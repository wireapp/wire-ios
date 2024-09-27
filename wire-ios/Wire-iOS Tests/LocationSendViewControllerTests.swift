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

// MARK: - LocationSendViewControllerTests

final class LocationSendViewControllerTests: XCTestCase {
    // MARK: - Properties

    var sut: LocationSendViewController!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = LocationSendViewController()
        sut.overrideUserInterfaceStyle = .light
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersSendControllerCorrectly_ShortAddress() {
        sut.address = "Hackescher Markt"
        verifyInAllPhoneWidths(matching: sut.prepareForSnapshot())
    }

    func testThatItRendersSendControllerCorrectly_MediumAddress() {
        sut.address = "Hackescher Markt, 10178 Berlin"
        verifyInAllPhoneWidths(matching: sut.prepareForSnapshot())
    }

    func testThatItRendersSendControllerCorrectly_LongAddress() {
        sut.address = "Hackescher Markt, Rosenthaler Straße 41, 10178 Berlin"
        verifyInAllPhoneWidths(matching: sut.prepareForSnapshot(heightConstant: 86))
    }
}

// MARK: - Helpers

extension UIViewController {
    fileprivate func prepareForSnapshot(heightConstant: CGFloat = 56) -> UIView {
        view.heightAnchor.constraint(equalToConstant: heightConstant).isActive = true
        return view
    }
}
