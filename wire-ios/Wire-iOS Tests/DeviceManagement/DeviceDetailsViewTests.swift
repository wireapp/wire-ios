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
        e2eIdentityProvider: E2eIdentityProviding,
        isProteusVerificationEnabled: Bool,
        isE2eIdentityEnabled: Bool,
        certificate: E2eIdentityCertificate,
        proteusKeyFingerPrint: String,
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
                saveFileManager: MockSaveFileManager(),
                mlsClientResolver: MockMLSClentResolver()
            ),
            userSession: mockSession,
            getUserClientFingerprint: mockGetUserClientFingerprintUseCaseProtocol,
            userClient: client,
            isSelfClient: isSelfClient
        )
        viewModel.proteusKeyFingerprint = proteusKeyFingerPrint
        viewModel.isE2eIdentityEnabled = isE2eIdentityEnabled
        viewModel.e2eIdentityCertificate = certificate
        viewModel.isSelfClient = isSelfClient
        return viewModel
    }

    func setupWrappedInNavigationController(
        mode: UIUserInterfaceStyle = .light,
        viewModel: DeviceInfoViewModel
    ) -> UINavigationController {
        sut = UIHostingController(rootView: DeviceDetailsView(viewModel: viewModel))
        sut.overrideUserInterfaceStyle = mode
        return  sut.wrapInNavigationController()
    }

    func testWhenE2eidentityViewIsDisabled() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: false,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testGivenSelfClientWhenE2eidentityViewIsDisabled() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: false,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        let e2eIdentityProvider = MockRevokedE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        let e2eIdentityProvider = MockExpiredE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .light, viewModel: viewModel)
        )
    }

    // MARK: - Dark mode

    func testGivenSelfClientWhenE2eidentityViewIsDisabledInDarkMode() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        let e2eIdentityProvider = MockE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        let e2eIdentityProvider = MockValidE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        let e2eIdentityProvider = MockRevokedE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        let e2eIdentityProvider = MockExpiredE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        let e2eIdentityProvider = MockNotActivatedE2eIdentityProvider()
        let viewModel = prepareViewModel(e2eIdentityProvider: e2eIdentityProvider,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         certificate: e2eIdentityProvider.certificate,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

}
