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
import XCTest

class SafeCoreCryptoTests: ZMBaseManagedObjectTest {

    func test_performDoesNotBlockWithMock() throws {
        // GIVEN
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCrypto()
        mockCoreCrypto.mockRestoreFromDisk = {}
        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, path: tempURL.path)

        // WHEN / THEN
        XCTAssertNoThrow(try sut.perform { mock in
            try mock.setCallbacks(callbacks: CoreCryptoCallbacksImpl())
        })

    }

    func test_performDoesCallRestoreFromDisk() throws {
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCrypto()
        var called = false
        mockCoreCrypto.mockRestoreFromDisk = {
            called = true
        }

        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, path: tempURL.path)

        // WHEN
        try sut.perform { mock in
            try mock.setCallbacks(callbacks: CoreCryptoCallbacksImpl())
        }

        // THEN
        XCTAssertTrue(called)
    }

    func test_mlsInitCallsCoreCrypto() throws {
        // GIVEN
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCrypto()

        var mlsInitCalled = false
        mockCoreCrypto.mockMlsInit = { _ in
            mlsInitCalled = true
        }

        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, path: tempURL.path)

        // WHEN
        try sut.mlsInit(clientID: "id")

        // THEN
        XCTAssertTrue(mlsInitCalled)
    }

    func test_mlsInitDoesntCallCoreCryptoWhenAlreadyInitialised() throws {
        // GIVEN
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCrypto()

        var mlsInitCalls = 0
        mockCoreCrypto.mockMlsInit = { _ in
            mlsInitCalls += 1
        }

        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, path: tempURL.path)
        try sut.mlsInit(clientID: "id")

        XCTAssertEqual(mlsInitCalls, 1)

        // WHEN
        try sut.mlsInit(clientID: "id")

        XCTAssertEqual(mlsInitCalls, 1)
    }


}
