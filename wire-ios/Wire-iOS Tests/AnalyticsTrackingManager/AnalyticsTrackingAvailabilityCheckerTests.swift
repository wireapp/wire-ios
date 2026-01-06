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

import WireAnalyticsSupport
import WireAuthenticationAPI
import WireNetwork
import XCTest

@testable import Wire

final class AnalyticsTrackingAvailabilityCheckerTests: XCTestCase {

    func testIsAnalyticsTrackingAvailable() {
        // Given
        let sut = AnalyticsTrackingAvailabilityChecker()
        let backendConfigs = [
            makeBackendEnvironment(backendURL: "https://prod-nginz-https.wire.com"),
            makeBackendEnvironment(backendURL: "https://staging-nginz-https.zinfra.io")
        ]

        // Then
        for backendConfig in backendConfigs {
            XCTAssertTrue(sut.isAnalyticsTrackingAvailable(for: backendConfig))
        }
    }

    func testIsAnalyticsTrackingUnavailableDueToNonWhitelistedURL() {
        // Given
        let sut = AnalyticsTrackingAvailabilityChecker()
        let environments = [
            makeBackendEnvironment(backendURL: "https://account.bella.wire.link"),
            makeBackendEnvironment(backendURL: "https://some-other.link"),
            makeBackendEnvironment(backendURL: "invalid")
        ]

        // Then
        for environment in environments {
            XCTAssertFalse(
                sut.isAnalyticsTrackingAvailable(for: environment),
                "\(environment.config.endpoints.restAPIURL.absoluteString)"
            )
        }
    }

    private func makeBackendEnvironment(backendURL: String) -> BackendEnvironment2 {
        BackendEnvironment2(
            title: "mock",
            environmentType: .default,
            config: .init(
                endpoints: .init(
                    restAPIURL: URL(string: backendURL)!,
                    websocketURL: URL(string: "https://wire.com")!,
                    blacklistURL: URL(string: "https://wire.com")!,
                    teamsURL: URL(string: "https://wire.com")!,
                    accountsURL: URL(string: "https://wire.com")!,
                    websiteURL: URL(string: "https://wire.com")!,
                    countlyURL: URL(string: "https://wire.com")!
                ),
                pinnedKeys: [],
                proxyConfig: nil
            )
        )
    }

}
