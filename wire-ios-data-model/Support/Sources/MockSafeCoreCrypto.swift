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
import WireCoreCrypto
import WireDataModel

public class MockSafeCoreCrypto: SafeCoreCryptoProtocol {

    var coreCrypto: MockCoreCryptoProtocol
    var coreCryptoContext: MockCoreCryptoContextProtocol

    public init(
        coreCrypto: MockCoreCryptoProtocol = .init(),
        coreCryptoContext: MockCoreCryptoContextProtocol = .init()
    ) {
        self.coreCrypto = coreCrypto
        self.coreCryptoContext = coreCryptoContext
    }

    var performCount = 0
    func perform<T>(_ block: (CoreCryptoContextProtocol) throws -> T) async rethrows -> T {
        performCount += 1
        return try block(coreCryptoContext)
    }

    var unsafePerformCount = 0
    public func unsafePerform<T>(_ block: (CoreCryptoContextProtocol) async throws -> T) async rethrows -> T {
        unsafePerformCount += 1
        return try await block(coreCryptoContext)
    }

    var performAsyncCount = 0
    public func perform<T>(_ block: (WireCoreCrypto.CoreCryptoContextProtocol) async throws -> T) async rethrows -> T {
        performAsyncCount += 1
        return try await block(coreCryptoContext)
    }

    public func configure(block: (any WireCoreCrypto.CoreCryptoProtocol) async throws -> Void) async throws {
        try await block(coreCrypto)
    }

    var mockMlsInit: ((String) throws -> Void)?

    public func mlsInit(clientID: String) throws {
        guard let mock = mockMlsInit else {
            fatalError("no mock for `mlsInit`")
        }

        try mock(clientID)
    }

    var tearDownCount = 0
    public func tearDown() throws {
        tearDownCount += 1
    }

}
