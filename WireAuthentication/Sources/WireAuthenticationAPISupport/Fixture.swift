//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public enum Fixture {

    public static let backendEnvironment = WireAuthenticationBackendEnvironment(
        environmentType: .production,
        config: BackendConfig(
            title: "Mock backend",
            endpoints: Endpoints(
                backendURL: URL(string: "www.mock.com")!,
                backendWSURL: URL(string: "www.mock.com")!,
                blackListURL: URL(string: "www.mock.com")!,
                teamsURL: URL(string: "www.mock.com")!,
                accountsURL: URL(string: "www.mock.com")!,
                websiteURL: URL(string: "www.mock.com")!,
                countlyURL: URL(string: "www.mock.com")!
            ),
            proxySettings: nil,
            pinnedKeys: nil
        ),
        metadata: BackendMetadata(
            apiVersion: .v8,
            domain: "mock.com",
            isFederationEnabled: true
        )
    )

    public static let someCookie = HTTPCookie(properties: [
        .name: "some name",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])!

    public static let someAccessToken = AccessToken(
        userID: UUID(),
        token: "token",
        type: "type",
        expirationDate: Date()
    )

}
