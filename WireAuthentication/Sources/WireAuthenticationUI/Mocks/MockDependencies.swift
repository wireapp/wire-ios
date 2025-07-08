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
import WireReusableUIComponents

@MainActor
final class MockDependencies {

    var backendInfo: BackendInfo {
        BackendInfo(
            environmentType: environmentType,
            backendConfig: backendConfig
        )
    }

    var environmentType: BackendEnvironmentType {
        .default
    }

    private var backendConfig: BackendConfig {
        _backendConfig
    }

    var backendMetadata: BackendMetadata {
        BackendMetadata(
            apiVersion: .v8,
            domain: "example.com",
            isFederationEnabled: true
        )
    }

    var backendEnvironment: WireAuthenticationBackendEnvironment {
        WireAuthenticationBackendEnvironment(
            environmentType: environmentType,
            config: backendConfig,
            metadata: backendMetadata,
            proxySettings: nil
        )
    }

    var _backendConfig = BackendConfig(
        title: "backen name",
        endpoints: Endpoints(
            backendURL: URL(string: "https://example.com")!,
            backendWSURL: URL(string: "https://example.com")!,
            blackListURL: URL(string: "https://example.com")!,
            teamsURL: URL(string: "https://example.com")!,
            accountsURL: URL(string: "https://example.com")!,
            websiteURL: URL(string: "https://example.com")!,
            countlyURL: URL(string: "https://example.com")!
        ),
        proxySettings: nil,
        pinnedKeys: nil
    )
}
