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
        let environment = makeBackendEnvironment(backendURL: "https://account.bella.wire.link")
        availabilityChecker.isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReturnValue = true

        // When
        let result = sut.isAnalyticsTrackingAvailable(for: environment)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(
            availabilityChecker.isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedInvocations,
            [environment]
        )
    }

    func testIsAnalyticsTrackingUnavailableDueToNoConfig() {
        // Given
        sut = makeSUT(useNilConfig: true)
        let environment = makeBackendEnvironment(backendURL: "https://account.bella.wire.link")

        // When
        let result = sut.isAnalyticsTrackingAvailable(for: environment)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(
            availabilityChecker.isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedInvocations,
            []
        )
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

    // MARK: - isAnalyticsTrackingAvailable

    var isAnalyticsTrackingAvailableForDomainStringBoolCallsCount = 0
    var isAnalyticsTrackingAvailableForDomainStringBoolCalled: Bool {
        isAnalyticsTrackingAvailableForDomainStringBoolCallsCount > 0
    }

    var isAnalyticsTrackingAvailableForDomainStringBoolReceivedDomain: String?
    var isAnalyticsTrackingAvailableForDomainStringBoolReceivedInvocations: [String] = []
    var isAnalyticsTrackingAvailableForDomainStringBoolReturnValue: Bool!
    var isAnalyticsTrackingAvailableForDomainStringBoolClosure: ((String) -> Bool)?

    func isAnalyticsTrackingAvailable(for domain: String) -> Bool {
        isAnalyticsTrackingAvailableForDomainStringBoolCallsCount += 1
        isAnalyticsTrackingAvailableForDomainStringBoolReceivedDomain = domain
        isAnalyticsTrackingAvailableForDomainStringBoolReceivedInvocations.append(domain)
        if let isAnalyticsTrackingAvailableForDomainStringBoolClosure {
            return isAnalyticsTrackingAvailableForDomainStringBoolClosure(domain)
        } else {
            return isAnalyticsTrackingAvailableForDomainStringBoolReturnValue
        }
    }

    // MARK: - isAnalyticsTrackingAvailable

    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolCallsCount = 0
    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolCalled: Bool {
        isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolCallsCount > 0
    }

    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedEnvironment: BackendEnvironment2?
    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedInvocations: [BackendEnvironment2] = []
    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReturnValue: Bool!
    var isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolClosure: ((BackendEnvironment2) -> Bool)?

    func isAnalyticsTrackingAvailable(for environment: BackendEnvironment2) -> Bool {
        isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolCallsCount += 1
        isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedEnvironment = environment
        isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReceivedInvocations.append(environment)
        if let isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolClosure {
            return isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolClosure(environment)
        } else {
            return isAnalyticsTrackingAvailableForEnvironmentBackendEnvironment2BoolReturnValue
        }
    }

}
