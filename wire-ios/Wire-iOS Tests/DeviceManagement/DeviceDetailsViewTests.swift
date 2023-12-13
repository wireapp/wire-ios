//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import SwiftUI
import WireSyncEngineSupport

final class DeviceDetailsViewTests: BaseSnapshotTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    var sut: UIHostingController<DeviceDetailsView>!
    var client: UserClient!

    lazy var mockGetUserClientFingerprintUseCaseProtocol: MockGetUserClientFingerprintUseCaseProtocol = {
        let mock = MockGetUserClientFingerprintUseCaseProtocol()
        mock.invokeUserClient_MockMethod = { _ in return "102030405060708090102030405060708090102030405060708090".data(using: .utf8) }
        mock.invokeUserClient_Invocations = [client]
        return mock
    }()

    lazy var kSerialNumber: String = {
        return "abcdefghijklmnopqrstuvwxyz"
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
    }()

    lazy var kFingerPrint: String = { return "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnop"
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
    }()

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        let otherYearFormatter =  WRDateFormatter.otherYearFormatter
        XCTAssertEqual(
            otherYearFormatter.locale.identifier,
            "en_US", "otherYearFormatter.locale.identifier is \(otherYearFormatter.locale.identifier)"
        )
        client = mockUserClient()
    }

    override func tearDown() {
        sut = nil
        client = nil
        coreDataFixture = nil
        super.tearDown()
    }

    func prepareViewModel(
        mode: UIUserInterfaceStyle,
        e2eIdentityProvider: E2eIdentityProviding,
        mlsProvider: MLSProviding,
        isProteusVerificationEnabled: Bool,
        isSelfClient: Bool
    ) -> DeviceInfoViewModel {
        let mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        let emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
        let viewModel = DeviceInfoViewModel(
            title: "some title",
            addedDate: "Monday 15 Oct, 2023",
            proteusID: kSerialNumber,
            isProteusVerificationEnabled: isProteusVerificationEnabled,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: client,
                userSession: mockSession,
                credentials: emailCredentials,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider
            ),
            userSession: mockSession,
            getUserClientFingerprint: mockGetUserClientFingerprintUseCaseProtocol,
            userClient: client,
            isSelfClient: isSelfClient
        )
        viewModel.proteusKeyFingerprint = kFingerPrint
        viewModel.mlsThumbprint = kFingerPrint
        viewModel.isSelfClient = isSelfClient
        return viewModel
    }

    func setupWrappedInNavigationController(
        mode: UIUserInterfaceStyle = .light,
        e2eIdentityProvider: E2eIdentityProviding,
        mlsProvider: MLSProviding,
        isProteusVerificationEnabled: Bool = true,
        isE2EIdentityEnabled: Bool = true,
        isSelfClient: Bool = false,
        e2eIdentityCertificate: E2eIdentityCertificate? = nil
    ) -> UINavigationController {
        let viewModel = prepareViewModel(
            mode: mode,
            e2eIdentityProvider: e2eIdentityProvider,
            mlsProvider: mlsProvider,
            isProteusVerificationEnabled: isProteusVerificationEnabled,
            isSelfClient: isSelfClient
        )
        viewModel.e2eIdentityCertificate = e2eIdentityCertificate
        sut = UIHostingController(rootView: DeviceDetailsView(viewModel: viewModel))
        sut.overrideUserInterfaceStyle = mode
        return  sut.wrapInNavigationController()
    }

    func testWhenE2eidentityViewIsDisabled() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                isE2EIdentityEnabled: false
            )
        )
    }

    func testGivenSelfClientWhenE2eidentityViewIsDisabled() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                isProteusVerificationEnabled: false,
                isE2EIdentityEnabled: false,
                isSelfClient: true
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                isProteusVerificationEnabled: false,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        let e2eIdentityProvider = MockRevokedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        let e2eIdentityProvider = MockExpiredE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                    e2eIdentityProvider: e2eIdentityProvider,
                    mlsProvider: mlsProvider,
                    e2eIdentityCertificate: e2eIdentityProvider.certificate
                )
            )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    // MARK: - Dark mode

    func testGivenSelfClientWhenE2eidentityViewIsDisabledInDarkMode() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                mode: .dark,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                isE2EIdentityEnabled: false,
                isSelfClient: true,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        let e2eIdentityProvider = MockE2eIdentityProvider()
        verify(matching:
                setupWrappedInNavigationController(
                    mode: .dark,
                    e2eIdentityProvider: e2eIdentityProvider,
                    mlsProvider: mlsProvider,
                    e2eIdentityCertificate: e2eIdentityProvider.certificate
                )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(matching:
                setupWrappedInNavigationController(
                    mode: .dark,
                    e2eIdentityProvider: e2eIdentityProvider,
                    mlsProvider: mlsProvider,
                    e2eIdentityCertificate: e2eIdentityProvider.certificate
                )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        let e2eIdentityProvider = MockRevokedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                mode: .dark,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        let e2eIdentityProvider = MockExpiredE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                mode: .dark,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: false)
        verify(
            matching: setupWrappedInNavigationController(
                mode: .dark,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewAndMLSViewIsEnabledThenShowBothTheSections() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: true)
        verify(
            matching: setupWrappedInNavigationController(
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

    func testWhenE2eidentityViewAndMLSViewIsEnabledThenShowBothTheSectionsInDarkMode() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let mlsProvider = MockMLSProvider(isMLSEnbaled: true)
        verify(
            matching: setupWrappedInNavigationController(
                mode: .dark,
                e2eIdentityProvider: e2eIdentityProvider,
                mlsProvider: mlsProvider,
                e2eIdentityCertificate: e2eIdentityProvider.certificate
            )
        )
    }

}
