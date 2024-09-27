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

import Foundation

public struct BackendMLSPublicKeys: Equatable {
    // MARK: Lifecycle

    public init(removal: MLSPublicKeys = .init()) {
        self.removal = removal
    }

    // MARK: Public

    public struct MLSPublicKeys: Equatable {
        // MARK: Lifecycle

        public init(
            ed25519: Data? = nil,
            ed448: Data? = nil,
            p256: Data? = nil,
            p384: Data? = nil,
            p521: Data? = nil
        ) {
            self.ed25519 = ed25519
            self.ed448 = ed448
            self.p256 = p256
            self.p384 = p384
            self.p521 = p521
        }

        // MARK: Internal

        let ed25519: Data?
        let ed448: Data?
        let p256: Data?
        let p384: Data?
        let p521: Data?
    }

    // MARK: Internal

    let removal: MLSPublicKeys

    func externalSenderKey(for ciphersuite: MLSCipherSuite) -> [Data] {
        let externalSender = switch ciphersuite.signature {
        case .ed25519:
            removal.ed25519
        case .ed448:
            removal.ed448
        case .p256:
            removal.p256
        case .p384:
            removal.p384
        case .p521:
            removal.p521
        }

        return [externalSender]
            .compactMap { $0 }
    }
}
