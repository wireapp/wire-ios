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

    let removal: MLSPublicKeys

    public init(removal: MLSPublicKeys = .init()) {
        self.removal = removal
    }

    var externalSenderKeys: [Data] {
        return [removal.ed25519, removal.ed448, removal.p256, removal.p384, removal.p521]
            .compactMap(\.self)
    }

    public struct MLSPublicKeys: Equatable {

        let ed25519: Data?
        let ed448: Data?
        let p256: Data?
        let p384: Data?
        let p521: Data?

        public init(ed25519: Data? = nil,
                    ed448: Data? = nil,
                    p256: Data? = nil,
                    p384: Data? = nil,
                    p521: Data? = nil) {
            self.ed25519 = ed25519
            self.ed448 = ed448
            self.p256 = p256
            self.p384 = p384
            self.p521 = p521
        }

    }

}
