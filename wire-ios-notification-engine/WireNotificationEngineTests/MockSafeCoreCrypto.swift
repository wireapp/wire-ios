//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import CoreCrypto

class MockSafeCoreCrypto: SafeCoreCryptoProtocol {

    var coreCrypto: MockCoreCrypto

    init(coreCrypto: MockCoreCrypto = .init()) {
        self.coreCrypto = coreCrypto
    }

    var performCount = 0
    func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        performCount += 1
        return try block(coreCrypto)
    }

    var unsafePerformCount = 0
    func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        unsafePerformCount += 1
        return try block(coreCrypto)
    }

    var mockMlsInit: ((String) throws -> Void)?

    func mlsInit(clientID: String) throws {
        guard let mock = mockMlsInit else {
            fatalError("no mock for `mlsInit`")
        }

        try mock(clientID)
    }

    var tearDownCount = 0
    func tearDown() throws {
        tearDownCount += 1
    }

}
