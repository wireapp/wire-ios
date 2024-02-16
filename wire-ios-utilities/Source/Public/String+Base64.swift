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

public extension String {

    var utf8Data: Data? {
        return data(using: .utf8)
    }

    var base64EncodedData: Data? {
        return utf8Data?.base64EncodedData()
    }

    var base64EncodedBytes: [Byte]? {
        return base64EncodedData?.bytes
    }

    var base64EncodedString: String? {
        return utf8Data?.base64EncodedString()
    }

    var base64DecodedData: Data? {
        return Data(base64Encoded: self)
    }

    var base64DecodedBytes: [Byte]? {
        return base64DecodedData?.bytes
    }

}
