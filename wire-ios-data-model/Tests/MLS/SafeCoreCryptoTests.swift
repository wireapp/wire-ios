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
@testable import WireDataModel
@testable import WireDataModelSupport
import XCTest

class SafeCoreCryptoTests: ZMBaseManagedObjectTest {

    func test_performDoesNotBlockWithMock() async throws {
        // GIVEN
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.restoreFromDisk_MockMethod = {}
        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, databasePath: tempURL.path)

        // WHEN / THEN
        await sut.perform { _ in }

    }

    func test_performDoesCallRestoreFromDisk() async throws {
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        var called = false
        mockCoreCrypto.setCallbacksCallbacks_MockMethod = { _ in }
        mockCoreCrypto.restoreFromDisk_MockMethod = {
            called = true
        }

        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, databasePath: tempURL.path)

        // WHEN
        await sut.perform { _ in }

        // THEN
        XCTAssertTrue(called)
    }

}
