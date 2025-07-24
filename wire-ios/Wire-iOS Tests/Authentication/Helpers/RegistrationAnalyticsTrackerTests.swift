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

    private var sut: RegistrationAnalyticsTracker!
    private var availabilityChecker: AnalyticsTrackingAvailabilityCheckerProtocolMock!

    override func setUp() {
        availabilityChecker = AnalyticsTrackingAvailabilityCheckerProtocolMock()
        sut = makeSUT()
    }

    override func tearDown() {
        sut = nil
        availabilityChecker = nil
    }

    func testIsAnalyticsTrackingAvailableCallsChecker() {
        // Given
        let backendConfig = makeBackendConfig(backendURL: "https://account.bella.wire.link")
        availabilityChecker.isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReturnValue = true

        // When
        let result = sut.isAnalyticsTrackingAvailable(for: backendConfig)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(
            availabilityChecker.isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedInvocations,
            [backendConfig]
        )
    }

    func testIsAnalyticsTrackingUnavailableDueToNoConfig() {
        // Given
        sut = makeSUT(useNilConfig: true)
        let backendConfig = makeBackendConfig(backendURL: "https://account.bella.wire.link")

        // When
        let result = sut.isAnalyticsTrackingAvailable(for: backendConfig)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(
            availabilityChecker.isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedInvocations,
            []
        )
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
            availabilityChecker: availabilityChecker,
            countlyProvider: { CountlyProtocolMock() },
            userDefaults: .temporary()
        )
    }

}

private final class AnalyticsTrackingAvailabilityCheckerProtocolMock: AnalyticsTrackingAvailabilityCheckerProtocol {

    //MARK: - isAnalyticsTrackingAvailable

    var isAnalyticsTrackingAvailableForDomainStringBoolCallsCount = 0
    var isAnalyticsTrackingAvailableForDomainStringBoolCalled: Bool {
        return isAnalyticsTrackingAvailableForDomainStringBoolCallsCount > 0
    }
    var isAnalyticsTrackingAvailableForDomainStringBoolReceivedDomain: (String)?
    var isAnalyticsTrackingAvailableForDomainStringBoolReceivedInvocations: [(String)] = []
    var isAnalyticsTrackingAvailableForDomainStringBoolReturnValue: Bool!
    var isAnalyticsTrackingAvailableForDomainStringBoolClosure: ((String) -> Bool)?

    func isAnalyticsTrackingAvailable(for domain: String) -> Bool {
        isAnalyticsTrackingAvailableForDomainStringBoolCallsCount += 1
        isAnalyticsTrackingAvailableForDomainStringBoolReceivedDomain = domain
        isAnalyticsTrackingAvailableForDomainStringBoolReceivedInvocations.append(domain)
        if let isAnalyticsTrackingAvailableForDomainStringBoolClosure = isAnalyticsTrackingAvailableForDomainStringBoolClosure {
            return isAnalyticsTrackingAvailableForDomainStringBoolClosure(domain)
        } else {
            return isAnalyticsTrackingAvailableForDomainStringBoolReturnValue
        }
    }

    //MARK: - isAnalyticsTrackingAvailable

    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolCallsCount = 0
    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolCalled: Bool {
        return isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolCallsCount > 0
    }
    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedBackendConfig: (BackendConfig)?
    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedInvocations: [(BackendConfig)] = []
    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReturnValue: Bool!
    var isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolClosure: ((BackendConfig) -> Bool)?

    func isAnalyticsTrackingAvailable(for backendConfig: BackendConfig) -> Bool {
        isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolCallsCount += 1
        isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedBackendConfig = backendConfig
        isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReceivedInvocations.append(backendConfig)
        if let isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolClosure = isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolClosure {
            return isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolClosure(backendConfig)
        } else {
            return isAnalyticsTrackingAvailableForBackendConfigBackendConfigBoolReturnValue
        }
    }

}
