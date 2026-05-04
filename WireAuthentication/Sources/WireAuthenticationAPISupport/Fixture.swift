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
import WireNetwork

public enum Fixture {

    public static let backendEnvironment = BackendEnvironment2(
        title: "Mock backend",
        environmentType: .default,
        config: .init(
            endpoints: .init(
                restAPIURL: URL(string: "www.mock.com")!,
                websocketURL: URL(string: "www.mock.com")!,
                blacklistURL: URL(string: "www.mock.com")!,
                teamsURL: URL(string: "www.mock.com")!,
                accountsURL: URL(string: "www.mock.com")!,
                websiteURL: URL(string: "www.mock.com")!,
                countlyURL: URL(string: "www.mock.com")!
            ),
            pinnedKeys: [],
            proxyConfig: nil
        )
    )

    public static let backendMetadata = ResolvedBackendMetadata(
        apiVersion: .v8,
        domain: "mock.com",
        isFederationEnabled: true
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

    public static let uuid = UUID()

}
