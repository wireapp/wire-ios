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

public typealias Byte = UInt8

extension Data {
    public var bytes: [Byte] {
        [Byte](self)
    }

    public static func random(byteCount: UInt = 8) -> Data {
        Data([Byte].random(length: byteCount))
    }
}

extension [Byte] {
    public var data: Data {
        Data(self)
    }

    public static func random(length: UInt = 8) -> [Byte] {
        (0..<length).map { _ in
            Byte.random()
        }
    }
}

extension Byte {
    public static func random() -> Byte {
        random(in: .min...(.max))
    }
}
