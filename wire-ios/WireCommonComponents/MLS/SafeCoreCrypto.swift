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
import CoreCrypto
import WireDataModel

public struct SafeCoreCrypto: SafeCoreCryptoProtocol {

    private let coreCrypto: CoreCryptoWrapper!
    private let safeContext: SafeFileContext

    public static func create(coreCryptoConfiguration: CoreCryptoConfiguration) throws -> SafeCoreCryptoProtocol {
        let coreCrypto = try CoreCryptoWrapper.setup(with: coreCryptoConfiguration)

        return SafeCoreCrypto(coreCryptoWrapper: coreCrypto, coreCryptoConfiguration: coreCryptoConfiguration)
    }

    init(coreCryptoWrapper: CoreCryptoWrapper, coreCryptoConfiguration: CoreCryptoConfiguration) {
        self.coreCrypto = coreCryptoWrapper
        let pathUrl = URL(fileURLWithPath: coreCryptoConfiguration.path)
        self.safeContext = SafeFileContext(fileURL: pathUrl)
    }

    public func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        var result: T
        safeContext.acquireDirectoryLock()
        //TODO: call `restoreFromDisk`
        result = try block(coreCrypto)
        safeContext.releaseDirectoryLock()
        return result
    }
}
