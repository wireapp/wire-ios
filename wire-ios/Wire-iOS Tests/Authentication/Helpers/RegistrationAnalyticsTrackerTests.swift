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

import XCTest
import WireAnalyticsSupport
import WireAuthenticationAPI

@testable import Wire

final class RegistrationAnalyticsTrackerTests: XCTestCase {

    func testIsAnalyticsTrackingAvailable() {
        // Given
        let sut = makeSUT()
        let backendConfigs = [
            makeBackendConfig(backendURL: "https://prod-nginz-https.wire.com"),
            makeBackendConfig(backendURL: "https://staging-nginz-https.zinfra.io")
        ]

        // Then
        for backendConfig in backendConfigs {
            XCTAssertTrue(sut.isAnalyticsTrackingAvailable(for: backendConfig))
        }
    }

    func testIsAnalyticsTrackingUnavailableDueToNonWhitelistedURL() {
        // Given
        let sut = makeSUT()
        let backendConfigs = [
            makeBackendConfig(backendURL: "https://account.bella.wire.link"),
            makeBackendConfig(backendURL: "https://some-other.link"),
            makeBackendConfig(backendURL: "invalid")
        ]

        // Then
        for backendConfig in backendConfigs {
            XCTAssertFalse(sut.isAnalyticsTrackingAvailable(for: backendConfig), "\(backendConfig.endpoints.backendURL.absoluteString)")
        }
    }

    func testIsAnalyticsTrackingUnavailableDueToNoConfig() {
        // Given
        let sut = makeSUT(useNilConfig: true)
        let backendConfigs = [
            makeBackendConfig(backendURL: "https://prod-nginz-https.wire.com"),
            makeBackendConfig(backendURL: "https://staging-nginz-https.zinfra.io"),
            makeBackendConfig(backendURL: "https://account.bella.wire.link")
        ]

        // Then
        for backendConfig in backendConfigs {
            XCTAssertFalse(sut.isAnalyticsTrackingAvailable(for: backendConfig), "\(backendConfig.endpoints.backendURL.absoluteString)")
        }
    }

    private func makeBackendConfig(backendURL: String) -> BackendConfig {
        BackendConfig(
            title: "mock",
            endpoints: Endpoints(
                backendURL: URL(string: backendURL)!,
                backendWSURL: URL(string: "https://wire.com")!,
                blackListURL: URL(string: "https://wire.com")!,
                teamsURL: URL(string: "https://wire.com")!,
                accountsURL: URL(string: "https://wire.com")!,
                websiteURL: URL(string: "https://wire.com")!,
                countlyURL: URL(string: "https://wire.com")!
            ),
            proxySettings: .none,
            pinnedKeys: .none
        )
    }

    private func makeSUT(useNilConfig: Bool = false) -> RegistrationAnalyticsTracker {
        let config = AnalyticsServiceConfiguration(secretKey: "", serverHost: URL(string: "https://wire.com")!)
        return RegistrationAnalyticsTracker(
            analyticsServiceConfiguration: useNilConfig ? .none : config,
            countlyProvider: { CountlyProtocolMock() },
            userDefaults: .temporary()
        )
    }

}
