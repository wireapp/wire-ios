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
import WireFoundation

struct RegisterPersonalAccountBodyV0: Encodable {

    let accentId: Int16 = AccentColor.default.rawValue
    let email: String
    let emailCode: String
    let label: String
    let locale: String
    let name: String
    let password: String

    enum CodingKeys: String, CodingKey {

        case accentId = "accent_id"
        case email
        case emailCode = "email_code"
        case label
        case locale
        case name
        case password

    }

}
