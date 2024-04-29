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
@testable import Wire
import XCTest

final class TokenSeparatorAttachmentTests: BaseSnapshotTestCase {
    var sut: TokenSeparatorAttachment!

    override func setUp() {
        super.setUp()
        let token: Token<NSObjectProtocol> = Token(title: "", representedObject: MockUser())
        let tokenField = TokenField()
        tokenField.dotColor = .black

        sut = TokenSeparatorAttachment(token: token, tokenField: tokenField)
    }

    override func tearDown() {
        sut = nil
    }

    func testTokenAttachmentImage() {
        verify(matching: sut.image!)
    }
}
