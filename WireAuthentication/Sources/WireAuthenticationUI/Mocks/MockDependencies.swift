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
import WireNetworkInterface
import WireReusableUIComponents

@MainActor
final class MockDependencies {

    var backendEnvironment: BackendEnvironment2 {
        BackendEnvironment2(
            title: "Mock backend",
            environmentType: .default,
            config: .init(
                endpoints: .init(
                    restAPIURL: URL(string: "www.example.com")!,
                    websocketURL: URL(string: "www.example.com")!,
                    blacklistURL: URL(string: "www.example.com")!,
                    teamsURL: URL(string: "www.example.com")!,
                    accountsURL: URL(string: "www.example.com")!,
                    websiteURL: URL(string: "www.example.com")!,
                    countlyURL: nil
                ),
                pinnedKeys: [],
                proxyConfig: nil
            )
        )
    }

    var backendMetadata: ResolvedBackendMetadata {
        ResolvedBackendMetadata(
            apiVersion: .v8,
            domain: "example.com",
            isFederationEnabled: true
        )
    }

}
