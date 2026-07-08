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

import WireCommonComponents
import WireTransport
import XCTest

@testable import Wire

final class NoDefaultBackendViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: NoDefaultBackendViewModel!
    private var sessionManager: MockBackendConfigurationSessionManager!
    private var delegate: MockNoDefaultBackendViewModelDelegate!

    override func setUp() {
        super.setUp()
        sessionManager = MockBackendConfigurationSessionManager()
        delegate = MockNoDefaultBackendViewModelDelegate()
        sut = NoDefaultBackendViewModel(sessionManager: { [weak self] in self?.sessionManager })
        sut.delegate = delegate
    }

    override func tearDown() {
        sut = nil
        sessionManager = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - Invalid input

    func testThatItFails_WhenNoSessionManagerIsAvailable() {
        // GIVEN
        sut = NoDefaultBackendViewModel(sessionManager: { nil })
        sut.delegate = delegate

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        XCTAssertEqual(delegate.failureMessages, [L10n.Localizable.NoDefaultBackend.error])
        XCTAssertTrue(sessionManager.fetchBackendEnvironmentURLs.isEmpty)
    }

    func testThatItFails_WhenInputIsEmpty() {
        // WHEN
        sut.submitConfigurationLink("")

        // THEN
        XCTAssertEqual(delegate.failureMessages, [L10n.Localizable.NoDefaultBackend.error])
        XCTAssertTrue(sessionManager.fetchBackendEnvironmentURLs.isEmpty)
    }

    func testThatItFails_WhenInputIsOnlyWhitespace() {
        // WHEN
        sut.submitConfigurationLink("   \n  ")

        // THEN
        XCTAssertEqual(delegate.failureMessages, [L10n.Localizable.NoDefaultBackend.error])
        XCTAssertTrue(sessionManager.fetchBackendEnvironmentURLs.isEmpty)
    }

    func testThatItFails_WhenInputIsNotAValidConfigurationDeepLink() {
        // WHEN
        sut.submitConfigurationLink("wire://not-a-supported-host")

        // THEN
        XCTAssertEqual(delegate.failureMessages, [L10n.Localizable.NoDefaultBackend.error])
        XCTAssertTrue(sessionManager.fetchBackendEnvironmentURLs.isEmpty)
    }

    // MARK: - Valid input

    func testThatItFetchesTheBackendEnvironment_WhenInputIsAPlainURL() {
        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        XCTAssertEqual(sessionManager.fetchBackendEnvironmentURLs, [URL(string: "https://example.com/config.json")!])
        XCTAssertEqual(delegate.loadingValues, [true, false])
    }

    func testThatItRequestsConfirmation_WhenTheBackendEnvironmentIsFetchedSuccessfully() {
        // GIVEN
        let environment = BackendEnvironment.defaultNoBackend
        sessionManager.fetchBackendEnvironmentResult = .success(environment)

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        XCTAssertEqual(delegate.confirmationRequests.count, 1)
        XCTAssertEqual(delegate.confirmationRequests.first?.environment, environment)
        XCTAssertTrue(sessionManager.markNetworkSessionsAsReadyValues.isEmpty, "should wait for confirmation")
        XCTAssertTrue(sessionManager.switchedBackendEnvironments.isEmpty, "should wait for confirmation")
    }

    func testThatItSwitchesBackend_WhenTheUserConfirmsTheSwitch() {
        // GIVEN
        let environment = BackendEnvironment.defaultNoBackend
        sessionManager.fetchBackendEnvironmentResult = .success(environment)
        let configurationURL = URL(string: "https://example.com/config.json")!

        // WHEN
        sut.submitConfigurationLink(configurationURL.absoluteString)
        delegate.confirmationRequests.first?.didConfirm(true)

        // THEN
        XCTAssertEqual(sessionManager.markNetworkSessionsAsReadyValues, [true])
        XCTAssertEqual(sessionManager.switchedBackendEnvironments, [environment])
        XCTAssertEqual(delegate.loadingValues, [true, false])
        XCTAssertEqual(delegate.configuredURLs, [configurationURL])
    }

    func testThatItDoesNotSwitchBackend_WhenTheUserDeclinesTheSwitch() {
        // GIVEN
        let environment = BackendEnvironment.defaultNoBackend
        sessionManager.fetchBackendEnvironmentResult = .success(environment)

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")
        delegate.confirmationRequests.first?.didConfirm(false)

        // THEN
        XCTAssertTrue(sessionManager.markNetworkSessionsAsReadyValues.isEmpty)
        XCTAssertTrue(sessionManager.switchedBackendEnvironments.isEmpty)
        XCTAssertTrue(delegate.configuredURLs.isEmpty)
    }

    func testThatItFails_WhenFetchingTheBackendEnvironmentFails() {
        // GIVEN
        sessionManager.fetchBackendEnvironmentResult = .failure(MockError.generic)

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        XCTAssertEqual(delegate.loadingValues, [true, false])
        XCTAssertEqual(delegate.failureMessages, [L10n.Localizable.NoDefaultBackend.error])
    }
}

// MARK: - Test doubles

private enum MockError: Error {
    case generic
}

private final class MockBackendConfigurationSessionManager: BackendConfigurationSessionManaging {

    var fetchBackendEnvironmentResult: Result<BackendEnvironment, Error> = .failure(MockError.generic)
    private(set) var fetchBackendEnvironmentURLs: [URL] = []
    private(set) var markNetworkSessionsAsReadyValues: [Bool] = []
    private(set) var switchedBackendEnvironments: [BackendEnvironment] = []

    func fetchBackendEnvironment(at url: URL, completion: @escaping (Result<BackendEnvironment, Error>) -> Void) {
        fetchBackendEnvironmentURLs.append(url)
        completion(fetchBackendEnvironmentResult)
    }

    func markNetworkSessionsAsReady(_ ready: Bool) {
        markNetworkSessionsAsReadyValues.append(ready)
    }

    func switchBackendWithoutResolving(to environment: BackendEnvironment) {
        switchedBackendEnvironments.append(environment)
    }
}

private final class MockNoDefaultBackendViewModelDelegate: NoDefaultBackendViewModelDelegate {

    private(set) var loadingValues: [Bool] = []
    private(set) var failureMessages: [String] = []
    private(set) var configuredURLs: [URL] = []
    private(set) var confirmationRequests: [(environment: BackendEnvironment, didConfirm: (Bool) -> Void)] = []

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didChangeLoading isLoading: Bool) {
        loadingValues.append(isLoading)
    }

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didFailWithMessage message: String) {
        failureMessages.append(message)
    }

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didConfigureBackend configurationURL: URL) {
        configuredURLs.append(configurationURL)
    }

    func noDefaultBackendViewModel(
        _ viewModel: NoDefaultBackendViewModel,
        requestUserConfirmationForBackendSwitch environment: BackendEnvironment,
        didConfirm: @escaping (Bool) -> Void
    ) {
        confirmationRequests.append((environment, didConfirm))
    }
}
