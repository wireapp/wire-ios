//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import Wire

final class AuthenticationInterfaceBuilderTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var featureProvider: MockAuthenticationFeatureProvider!
    var builder: AuthenticationInterfaceBuilder!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        accentColor = .strongBlue

        featureProvider = MockAuthenticationFeatureProvider()
        builder = AuthenticationInterfaceBuilder(featureProvider: featureProvider, backendEnvironmentProvider: {
            let backendEnvironmentProvider = MockEnvironment()
            let proxy: FakeProxySettings? = nil
            backendEnvironmentProvider.proxy = proxy
            backendEnvironmentProvider.environmentType = EnvironmentTypeProvider(environmentType: .staging)
            return backendEnvironmentProvider
        })
    }

    override func tearDown() {
        builder = nil
        featureProvider = nil

        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - General

    func testLandingScreen() {
        runSnapshotTest(for: .landingScreen)
    }

    func testThatItDoesNotGenerateInterfaceForCompanyLoginFlow() {
        runSnapshotTest(for: .companyLogin)
    }

    // MARK: - User Registration

    func testRegistrationScreen() {
        runSnapshotTest(for: .createCredentials(UnregisteredUser()))
    }

    func testActivationScreen_Phone() {
        let phoneNumber = UnverifiedCredentials.phone("+0123456789")
        runSnapshotTest(for: .enterActivationCode(phoneNumber, user: UnregisteredUser()))
    }

    func testActivationScreen_Email() {
        let email = UnverifiedCredentials.email("test@example.com")
        runSnapshotTest(for: .enterActivationCode(email, user: UnregisteredUser()))
    }

    func testSetNameScreen() {
        runSnapshotTest(for: .incrementalUserCreation(UnregisteredUser(), .setName))
    }

    func testSetPasswordScreen() {
        runSnapshotTest(for: .incrementalUserCreation(UnregisteredUser(), .setPassword))
    }

    func testThatItDoesNotGenerateInterfaceForMarketingConsentStep() {
        runSnapshotTest(for: .incrementalUserCreation(UnregisteredUser(), .provideMarketingConsent))
    }

    // MARK: - Login

    func testLoginScreen_Phone() throws {
        runSnapshotTest(for: .provideCredentials(.phone, nil))
    }

    func testLoginScreen_Email() {
        runSnapshotTest(for: .provideCredentials(.email, nil))
    }

    func testLoginScreen_Email_WithProxyAuthenticated() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider.environmentType = EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = FakeProxySettings(host: "api.example.org", port: 1345, needsAuthentication: true)
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!
        builder = AuthenticationInterfaceBuilder(featureProvider: featureProvider, backendEnvironmentProvider: { backendEnvironmentProvider })
        runSnapshotTest(for: .provideCredentials(.email, nil), customSize: .init(width: CGSize.iPhoneSize.iPhone4_7Inch.width, height: 1000)) // setting higher value for scrollview content
    }

    func testLoginScreen_Email_WithConfig() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider.environmentType = EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = nil
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!
        builder = AuthenticationInterfaceBuilder(featureProvider: featureProvider, backendEnvironmentProvider: { backendEnvironmentProvider })
        runSnapshotTest(for: .provideCredentials(.email, nil))
    }

    func testLoginScreen_Email_WithProxyNoAuthentication() {
        let backendEnvironmentProvider = MockEnvironment()
        backendEnvironmentProvider.environmentType = EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        backendEnvironmentProvider.proxy = FakeProxySettings(host: "api.example.org", port: 1345, needsAuthentication: false)
        backendEnvironmentProvider.backendURL = URL(string: "https://api.example.org")!

        builder = AuthenticationInterfaceBuilder(featureProvider: featureProvider, backendEnvironmentProvider: { backendEnvironmentProvider })
        runSnapshotTest(for: .provideCredentials(.email, nil))
    }

    func testLoginScreen_Email_PhoneDisabled() {
        featureProvider.allowOnlyEmailLogin = true
        runSnapshotTest(for: .provideCredentials(.email, nil))
    }

    func testLoginScreen_PhoneNumberVerification() {
        runSnapshotTest(for: .enterPhoneVerificationCode(phoneNumber: "+0123456789"))
    }

    func testBackupScreen_NewDevice() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .newDevice))
    }

    func testBackupScreen_LoggedOut() {
        runSnapshotTest(for: .noHistory(credentials: nil, context: .loggedOut))
    }

    func testTooManyDevicesScreen() {
        runSnapshotTest(for: .clientManagement(clients: [], credentials: nil))
    }

    func testClientRemovalScreen() {
        runSnapshotTest(for: .deleteClient(clients: [mockUserClient()], credentials: nil))
    }

    func testAddEmailPasswordScreen() {
        runSnapshotTest(for: .addEmailAndPassword)
    }

    func testVerifyEmailLinkTests() {
        let credentials = ZMEmailCredentials(email: "test@example.com", password: "12345678")
        runSnapshotTest(for: .pendingEmailLinkVerification(credentials))
    }

    func testReauthenticate_Email_TokenExpired() {
        let credentials = LoginCredentials(emailAddress: "test@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1, isSignedOut: true))
    }

    func testReauthenticate_Email_DuringLogin() {
        let credentials = LoginCredentials(emailAddress: "test@example.com", phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1, isSignedOut: false))
    }

    func testReauthenticate_EmailAndPhone_TokenExpired() {
        let credentials = LoginCredentials(emailAddress: "test@example.com", phoneNumber: "+33123456789", hasPassword: true, usesCompanyLogin: false)

        // Email should have priority
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1, isSignedOut: true))
    }

    func testReauthenticate_Phone_DuringLogin() {
        let credentials = LoginCredentials(emailAddress: nil, phoneNumber: "+33123456789", hasPassword: true, usesCompanyLogin: false)

        // Email should have priority
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1, isSignedOut: false))
    }

    func testReauthenticate_CompanyLogin() {
        let credentials = LoginCredentials(emailAddress: nil, phoneNumber: nil, hasPassword: false, usesCompanyLogin: true)
        runSnapshotTest(for: .reauthenticate(credentials: credentials, numberOfAccounts: 1, isSignedOut: true))
    }

    func testReauthenticate_NoCredentials() {
        runSnapshotTest(for: .reauthenticate(credentials: nil, numberOfAccounts: 1, isSignedOut: true))
    }

    // MARK: - Helpers

    private func runSnapshotTest(for step: AuthenticationFlowStep,
                                 file: StaticString = #file,
                                 testName: String = #function,
                                 line: UInt = #line,
                                 customSize: CGSize? = nil
        ) {
        if let viewController = builder.makeViewController(for: step) {
            if !step.needsInterface {
                return XCTFail("An interface was generated but we didn't expect one.", file: file, line: line)
            }

            let navigationController = UINavigationController(navigationBarClass: AuthenticationNavigationBar.self, toolbarClass: nil)
            navigationController.viewControllers = [viewController]

            verify(matching: navigationController,
                   customSize: customSize,
                   file: file,
                   testName: testName,
                   line: line)
        } else {
            XCTAssertFalse(step.needsInterface, "Missing interface.", file: file, line: line)
        }
    }

}
