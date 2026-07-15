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

import Testing
import WireCommonComponents
import WireTransport

@testable import Wire

final class NoDefaultBackendViewModelTests {

    // MARK: - Properties

    private let sessionManager: MockBackendConfigurationSessionManaging
    private let delegate: MockNoDefaultBackendViewModelDelegate
    private var sut: NoDefaultBackendViewModel

    private var fetchBackendEnvironmentResult: Result<BackendEnvironment, Error> = .failure(MockError.generic)

    // MARK: - Life cycle

    init() {
        sessionManager = MockBackendConfigurationSessionManaging()
        delegate = MockNoDefaultBackendViewModelDelegate()
        sut = NoDefaultBackendViewModel(sessionManager: { [sessionManager] in sessionManager })
        sut.delegate = delegate

        sessionManager.markNetworkSessionsAsReady_MockMethod = { _ in }
        sessionManager.switchBackendWithoutResolvingTo_MockMethod = { _ in }
        sessionManager.fetchBackendEnvironmentAtCompletion_MockMethod = { [weak self] _, completion in
            completion(self?.fetchBackendEnvironmentResult ?? .failure(MockError.generic))
        }
    }

    // MARK: - Invalid input

    @Test
    func failsWhenNoSessionManagerIsAvailable() {
        // GIVEN
        sut = NoDefaultBackendViewModel(sessionManager: { nil })
        sut.delegate = delegate

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        #expect(delegate.failureMessages == [L10n.Localizable.NoDefaultBackend.error])
        #expect(sessionManager.fetchBackendEnvironmentAtCompletion_Invocations.isEmpty)
    }

    @Test(arguments: [
        "",
        "   \n  ",
        "wire://not-a-supported-host"
    ])
    func failsWhenInputIsInvalid(input: String) {
        // WHEN
        sut.submitConfigurationLink(input)

        // THEN
        #expect(delegate.failureMessages == [L10n.Localizable.NoDefaultBackend.error])
        #expect(sessionManager.fetchBackendEnvironmentAtCompletion_Invocations.isEmpty)
    }

    // MARK: - Valid input

    @Test
    func fetchesTheBackendEnvironmentWhenInputIsAPlainURL() {
        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        #expect(sessionManager.fetchBackendEnvironmentAtCompletion_Invocations.map { $0.url } == [
            URL(string: "https://example.com/config.json")!
        ])
        #expect(delegate.loadingValues == [true, false])
    }

    @Test
    func requestsConfirmationWhenTheBackendEnvironmentIsFetchedSuccessfully() {
        // GIVEN
        let environment = BackendEnvironment.defaultNoBackend
        fetchBackendEnvironmentResult = .success(environment)

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        #expect(delegate.confirmationRequests.count == 1)
        #expect(delegate.confirmationRequests.first?.environment == environment)
        #expect(sessionManager.markNetworkSessionsAsReady_Invocations.isEmpty, "should wait for confirmation")
        #expect(sessionManager.switchBackendWithoutResolvingTo_Invocations.isEmpty, "should wait for confirmation")
    }

    @Test(arguments: [true, false])
    func switchesBackendOnlyWhenTheUserConfirmsTheSwitch(didConfirm: Bool) {
        // GIVEN
        let environment = BackendEnvironment.defaultNoBackend
        fetchBackendEnvironmentResult = .success(environment)
        let configurationURL = URL(string: "https://example.com/config.json")!

        // WHEN
        sut.submitConfigurationLink(configurationURL.absoluteString)
        delegate.confirmationRequests.first?.didConfirm(didConfirm)

        // THEN
        #expect(delegate.loadingValues == [true, false])
        #expect(sessionManager.markNetworkSessionsAsReady_Invocations == (didConfirm ? [true] : []))
        #expect(sessionManager.switchBackendWithoutResolvingTo_Invocations == (didConfirm ? [environment] : []))
        #expect(delegate.configuredURLs == (didConfirm ? [configurationURL] : []))
    }

    @Test
    func failsWhenFetchingTheBackendEnvironmentFails() {
        // GIVEN
        fetchBackendEnvironmentResult = .failure(MockError.generic)

        // WHEN
        sut.submitConfigurationLink("https://example.com/config.json")

        // THEN
        #expect(delegate.loadingValues == [true, false])
        #expect(delegate.failureMessages == [L10n.Localizable.NoDefaultBackend.error])
    }
}

// MARK: - Test doubles

private enum MockError: Error {
    case generic
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
