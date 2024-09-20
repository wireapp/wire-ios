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

import WireDataModel
import WireFoundation

extension UnregisteredUser {

    /// The dictionary payload that contains the resources to transmit to the backend
    var payload: ZMTransportData {
        guard isComplete else {
            fatalError("Attempt to register an incomplete user.")
        }

        var payload: [String: Any] = [:]
        payload["email"] = unverifiedEmail
        payload["email_code"] = verificationCode!
        payload["accent_id"] = accentColor?.rawValue ?? AccentColor.default.rawValue
        payload["name"] = name!
        payload["locale"] = NSLocale.formattedLocaleIdentifier()
        payload["label"] = CookieLabel.current.value
        payload["password"] = password
        return payload as ZMTransportData
    }
}
