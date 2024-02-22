//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import WireDataModel

extension XCTestCase {

    private func generatePublicPrivateKey() -> (SecKey, SecKey) {
        var publicKeySec, privateKeySec: SecKey?
        var error: Unmanaged<CFError>?
        let keyattributes = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256
        ] as CFDictionary
        privateKeySec = SecKeyCreateRandomKey(keyattributes, &error)
        if let privateKeySec = privateKeySec {
            publicKeySec = SecKeyCopyPublicKey(privateKeySec)
        }
        return (publicKeySec!, privateKeySec!)
    }

    var validDatabaseKey: VolatileData {
        return VolatileData(from: .zmRandomSHA256Key())
    }

    var malformedDatabaseKey: VolatileData {
        return VolatileData(from: .zmRandomSHA256Key().dropFirst())
    }

}
