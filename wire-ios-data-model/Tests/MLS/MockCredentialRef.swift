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

import WireCoreCrypto

final class MockCredentialRef: WireCoreCrypto.CredentialRef, @unchecked Sendable {

    let _cipherSuite: CipherSuite
    let _type: CredentialType

    init(cipherSuite: CipherSuite, type: CredentialType = .basic) {
        self._cipherSuite = cipherSuite
        self._type = type

        super.init(noPointer: .init())
    }

    @_documentation(visibility: private)
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    override func cipherSuite() -> CipherSuite {
        _cipherSuite
    }

    override func type() -> CredentialType {
        _type
    }
}
