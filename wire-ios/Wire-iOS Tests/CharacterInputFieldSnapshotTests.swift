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

final class CharacterInputFieldSnapshotTests: XCTestCase {
    private var snapshotHelper: SnapshotHelper!
    private var sut: CharacterInputField! = nil

    private var rootViewController: UIViewController! {
        (UIApplication.shared.delegate as? AppDelegate)?.mainWindow?.rootViewController
    }

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        let size = CGSize(width: 375, height: 56)
        sut = CharacterInputField(maxLength: 8, characterSet: CharacterSet.decimalDigits, size: size)

        sut.frame = CGRect(origin: .zero, size: size)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut.removeFromSuperview()
        sut = nil
        super.tearDown()
    }

    func testDefaultState() {
        // then
        snapshotHelper.verify(matching: sut)
    }

    func testFocusedState() {
        // given
        rootViewController?.view.addSubview(sut)

        // when
        sut.becomeFirstResponder()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testFocusedDeFocusedState() {
        // given
        rootViewController?.view.addSubview(sut)

        // when
        sut.becomeFirstResponder()
        sut.resignFirstResponder()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testOneCharacterState() {
        // when
        sut.insertText("1")

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testAllCharactersEnteredState() {
        // when
        sut.insertText("12345678")

        // then
        snapshotHelper.verify(matching: sut)
    }
}
