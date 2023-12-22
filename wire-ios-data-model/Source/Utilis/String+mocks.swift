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

    static func mockCertificate() -> String {
                """
            -----BEGIN CERTIFICATE-----
            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
            -----END CERTIFICATE-----
            """
    }

    static func mockSerialNumber() -> String {
        String(repeating: "abcdefghijklmno", count: 2)
    }

    static func mockThumbprint() -> String {
        String(repeating: "abcdefghijklmno", count: 4)
    }
}
