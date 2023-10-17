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

public typealias Byte = UInt8

public extension Data {

    var bytes: [Byte] {
        return [Byte](self)
    }

    static func random(byteCount: UInt = 8) -> Data {
        return Data([Byte].random(length: byteCount))
    }

}

public extension [Byte] {

    var data: Data {
        return Data(self)
    }

    static func random(length: UInt = 8) -> [Byte] {
        return (0..<length).map { _ in
            Byte.random()
        }
    }

}

public extension Byte {

    static func random() -> Byte {
        return random(in: (.min)...(.max))
    }

}
