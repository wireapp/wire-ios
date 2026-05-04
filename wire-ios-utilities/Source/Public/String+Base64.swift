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

public extension String {

    var utf8Data: Data? {
        data(using: .utf8)
    }

    var base64EncodedData: Data? {
        utf8Data?.base64EncodedData()
    }

    var base64EncodedBytes: [Byte]? {
        base64EncodedData.map { data in
            [UInt8](data)
        }
    }

    var base64EncodedString: String? {
        utf8Data?.base64EncodedString()
    }

    var base64DecodedData: Data? {
        Data(base64Encoded: self)
    }

    var base64DecodedBytes: [Byte]? {
        base64DecodedData.map { data in
            [UInt8](data)
        }
    }

}
