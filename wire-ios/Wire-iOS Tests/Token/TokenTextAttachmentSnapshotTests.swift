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

final class TokenTextAttachmentSnapshotTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        let token: Token<NSObjectProtocol> = Token(title: "Max Mustermann", representedObject: MockUser())
        let tokenField = TokenField()
        tokenField.tokenTitleColor = .black

        sut = TokenTextAttachment(token: token, tokenField: tokenField)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testTokenAttachmentImage() {
        snapshotHelper.verify(matching: sut.image!)
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: TokenTextAttachment!
}
