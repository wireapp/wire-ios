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
import WireUtilities
@testable import WireDataModel

extension MLSGroupID {

    static func random() -> MLSGroupID {
        return MLSGroupID(Data.random(byteCount: 32))
    }

}

extension MLSClientID {

    static func random() -> MLSClientID {
        return MLSClientID(
            userID: UUID.create().transportString(),
            clientID: .random(length: 8),
            domain: .randomDomain()
        )
    }

}

extension QualifiedID {

    static func random() -> QualifiedID {
        return QualifiedID(
            uuid: .create(),
            domain: .randomDomain()
        )
    }

}

extension String {

    static func randomDomain(hostLength: UInt = 5) -> String {
        return "\(String.random(length: hostLength)).com"
    }

    static func random(length: UInt) -> String {
        let randomChars = (0..<length).compactMap { _ in
            "a...z".randomElement()
        }

        return String(randomChars)
    }

}

