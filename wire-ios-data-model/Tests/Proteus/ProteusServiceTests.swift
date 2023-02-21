//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Foundation
import XCTest
import CoreCryptoSwift
@testable import WireDataModel

class ProteusServiceTests: XCTest {

    var mockCoreCrypto: MockCoreCrypto!
    var sut: ProteusService!

    // MARK: - Set up

    override func setupWithError() throws {
        try super.setupWithError()
        mockCoreCrypto = MockCoreCrypto()
        sut = try ProteusService(coreCrypto: mockCoreCrypto)
    }

    override func tearDown() {
        mockCoreCrypto = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Decrypting messages

    func test_DecryptDataForSession_SessionExists() throws {
        XCTFail()
    }

    func test_DecryptDataForSession_SessionDoesNotExist() throws {
        XCTFail()
    }

}
