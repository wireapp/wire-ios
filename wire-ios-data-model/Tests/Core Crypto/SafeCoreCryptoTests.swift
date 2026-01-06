//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
@testable import WireDataModel
@testable import WireDataModelSupport

class SafeCoreCryptoTests: ZMBaseManagedObjectTest {

    func test_performDoesNotBlockWithMock() async throws {
        // GIVEN
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        let mockCoreCryptoContext = MockCoreCryptoContextProtocol()

        mockCoreCrypto.transaction_MockMethod = { block in
            _ = try await block(mockCoreCryptoContext)
        }

        mockCoreCryptoContext.proteusReloadSessions_MockMethod = {}
        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, databasePath: tempURL.path)

        // WHEN / THEN
        try await sut.perform { _ in }

    }

    func test_performDoesCallRestoreFromDisk() async throws {
        let tempURL = createTempFolder()
        let mockCoreCrypto = MockCoreCryptoProtocol()
        let mockCoreCryptoContext = MockCoreCryptoContextProtocol()

        mockCoreCrypto.transaction_MockMethod = { block in
            _ = try await block(mockCoreCryptoContext)
        }

        mockCoreCryptoContext.proteusReloadSessions_MockMethod = {}

        let sut = SafeCoreCrypto(coreCrypto: mockCoreCrypto, databasePath: tempURL.path)

        // WHEN
        try await sut.perform { _ in }

        // THEN
        XCTAssertEqual(mockCoreCryptoContext.proteusReloadSessions_Invocations.count, 1)
    }

}
