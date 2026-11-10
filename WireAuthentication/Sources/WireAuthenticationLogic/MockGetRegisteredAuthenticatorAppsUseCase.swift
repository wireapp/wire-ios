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
import WireAuthenticationAPI

package struct MockGetRegisteredAuthenticatorAppsUseCase: GetRegisteredAuthenticatorAppsUseCaseProtocol {

    package init() {}

    package func invoke() async throws -> [RegisteredAuthenticatorApp] {
        // TODO: [WPB-29475] Fetch registered authenticator apps from the backend when available.
        try await Task.sleep(for: .milliseconds(500))
        return [
            RegisteredAuthenticatorApp(
                name: "Google Authenticator",
                registrationDate: Date(timeIntervalSince1970: 1_790_000_000)
            ),
            RegisteredAuthenticatorApp(
                name: "1Password",
                registrationDate: Date(timeIntervalSince1970: 1_790_086_400)
            )
        ]
    }
}
