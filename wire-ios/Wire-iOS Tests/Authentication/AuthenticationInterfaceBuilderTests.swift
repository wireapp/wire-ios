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

import WireNetwork
import WireTestingPackage
import XCTest

@testable import Wire

final class AuthenticationInterfaceBuilderTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var featureProvider: MockAuthenticationFeatureProvider!
    var builder: AuthenticationInterfaceBuilder!
    var defaultEnvironment: BackendEnvironment2!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() async throws {
        try await super.setUp()
        snapshotHelper = SnapshotHelper()
        coreDataFixture = try await CoreDataFixture()
        accentColor = .blue
        defaultEnvironment = BackendEnvironment2(
            title: "mock",
            environmentType: .default,
            config: .init(
                endpoints: .init(
                    restAPIURL: URL(string: "www.wire.com")!,
                    websocketURL: URL(string: "www.wire.com")!,
                    blacklistURL: URL(string: "www.wire.com")!,
                    teamsURL: URL(string: "www.wire.com")!,
                    accountsURL: URL(string: "www.wire.com")!,
                    websiteURL: URL(string: "www.wire.com")!,
                    countlyURL: URL(string: "www.wire.com")!
                ),
                pinnedKeys: [],
                proxyConfig: nil
            )
        )

        featureProvider = MockAuthenticationFeatureProvider()
        builder = AuthenticationInterfaceBuilder(
            featureProvider: featureProvider,
            accountSelector: MockAccountSelector(),
            backendEnvironmentProvider: {
                let backendEnvironmentProvider = MockEnvironment()
                let proxy: FakeProxySettings? = nil
                backendEnvironmentProvider.proxy = proxy
                backendEnvironmentProvider.environmentType = EnvironmentTypeProvider(environmentType: .staging)
                return backendEnvironmentProvider
            },
            defaultEnvironment: defaultEnvironment
        )
    }

    override func tearDown() {
        snapshotHelper = nil
        builder = nil
        featureProvider = nil
        defaultEnvironment = nil

        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - General

    @MainActor
    func testLandingScreen() {
        runSnapshotTest(for: .landingScreen)
    }

    @MainActor
    func testThatItDoesNotGenerateInterfaceForCompanyLoginFlow() {
        runSnapshotTest(for: .companyLogin)
    }

    // MARK: - User Registration

    @MainActor
    func testRegistrationScreen() {
        runSnapshotTest(for: .createCredentials(UnregisteredUser()))
    }

    @MainActor
    func testActivationScreen_Email() {
        let unverifiedEmail = "test@example.com"
        runSnapshotTest(for: .enterActivationCode(unverifiedEmail: unverifiedEmail, user: UnregisteredUser()))
    }

    @MainActor
    func testSetNameScreen() {
        runSnapshotTest(for: .incrementalUserCreation(UnregisteredUser(), .setName))
    }

    @MainActor
    func testSetPasswordScreen() {
        runSnapshotTest(for: .incrementalUserCreation(UnregisteredUser(), .setPassword))
    }

    // MARK: - Login

    @MainActor
    func testLoginScreen_Email() {
        runSnapshotTest(for: .provideCredentials(nil))
    }

    @MainActor
    func testLoginScreen_Email_WithProxyAuthenticated() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider
            .environmentType =
            EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = FakeProxySettings(
            host: "api.example.org",
            port: 1345,
            needsAuthentication: true
        )
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!
        builder = AuthenticationInterfaceBuilder(
            featureProvider: featureProvider,
            accountSelector: MockAccountSelector(),
            backendEnvironmentProvider: { backendEnvironmentProvider },
            defaultEnvironment: defaultEnvironment
        )
        runSnapshotTest(
            for: .provideCredentials(nil),
            customSize: .init(width: CGSize.iPhoneSize.iPhone4_7Inch.width, height: 1000)
        ) // setting higher value for scrollview content
    }

    @MainActor
    func testLoginScreen_Email_WithConfig() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider
            .environmentType =
            EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = nil
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!
        builder = AuthenticationInterfaceBuilder(
            featureProvider: featureProvider,
            accountSelector: MockAccountSelector(),
            backendEnvironmentProvider: { backendEnvironmentProvider },
            defaultEnvironment: defaultEnvironment
        )
        runSnapshotTest(for: .provideCredentials(nil))
    }

    @MainActor
    func testLoginScreen_Email_WithProxyNoAuthentication() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider
            .environmentType =
            EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = FakeProxySettings(
            host: "api.example.org",
            port: 1345,
            needsAuthentication: false
        )
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!

        builder = AuthenticationInterfaceBuilder(
            featureProvider: featureProvider,
            accountSelector: MockAccountSelector(),
            backendEnvironmentProvider: { backendEnvironmentProvider },
            defaultEnvironment: defaultEnvironment
        )
        runSnapshotTest(for: .provideCredentials(nil))
    }

    @MainActor
    func testLoginScreen_Email_PhoneDisabled() {
        featureProvider.allowOnlyEmailLogin = true
        runSnapshotTest(for: .provideCredentials(nil))
    }

    @MainActor
    func testBackupScreen_NewDevice() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .newDevice))
    }

    @MainActor
    func testBackupScreen_LoggedOut() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .loggedOut))
    }

    @MainActor
    func testTooManyDevicesScreen() {
        runSnapshotTest(for: .clientManagement(clients: []))
    }

    @MainActor
    func testClientRemovalScreen() {
        runSnapshotTest(for: .deleteClient(clients: [mockUserClient()]))
    }

    @MainActor
    func testAddEmailPasswordScreen() {
        runSnapshotTest(for: .addEmailAndPassword)
    }

    @MainActor
    func testVerifyEmailLinkTests() {
        let credentials = UserEmailCredentials(email: "test@example.com", password: "12345678")
        runSnapshotTest(for: .pendingEmailLinkVerification(credentials))
    }

    // MARK: - Helpers

    @MainActor
    private func runSnapshotTest(
        for step: AuthenticationFlowStep,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        customSize: CGSize? = nil
    ) {
        if let viewController = builder.makeViewController(for: step, authenticationCoordinator: nil) {
            if !step.needsInterface {
                return XCTFail("An interface was generated but we didn't expect one.", file: file, line: line)
            }

            let navigationController = UINavigationController(
                navigationBarClass: AuthenticationNavigationBar.self,
                toolbarClass: nil
            )
            navigationController.viewControllers = [viewController]

            snapshotHelper.verify(
                matching: navigationController,
                size: customSize,
                file: file,
                testName: testName,
                line: line
            )
        } else {
            XCTAssertFalse(step.needsInterface, "Missing interface.", file: file, line: line)
        }
    }
}
