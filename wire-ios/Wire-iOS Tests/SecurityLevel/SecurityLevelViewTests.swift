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

import SnapshotTesting
import WireDesign
import WireUtilities
import XCTest

@testable import Wire

final class SecurityLevelViewTests: XCTestCase {

    // MARK: - Properties

    private var sut: SecurityLevelView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = SecurityLevelView()
        sut.backgroundColor = SemanticColors.View.backgroundDefaultWhite
        sut.translatesAutoresizingMaskIntoConstraints = true
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 24)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - SnapshotTests

    func testThatItRendersWithNotClassified() {
        sut.configure(with: .notClassified)
        verifyInAllColorSchemes(matching: sut)
    }

    func testThatItRendersWithClassified() {
        sut.configure(with: .classified)
        verifyInAllColorSchemes(matching: sut)
    }

    func testThatItDoesNotRenderWithNone() {
        sut.configure(with: .none)
        verifyInAllColorSchemes(matching: sut)
    }
}
