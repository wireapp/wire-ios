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
        mlsThumbprint: String?,
        status: E2EIdentityCertificateStatus,
        isProteusVerificationEnabled: Bool,
        isE2eIdentityEnabled: Bool,
        proteusKeyFingerPrint: String,
        isSelfClient: Bool
    ) -> DeviceInfoViewModel {
        let mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        mockSession.isE2eIdentityEnabled = isE2eIdentityEnabled
        var certificate: E2eIdentityCertificate
        switch status {
        case .notActivated:
            certificate = .mockNotActivated
        case .revoked:
            certificate = .mockRevoked
        case .expired:
            certificate = .mockExpired
        case .valid:
            certificate = .mockValid
        }
        let emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")

        let viewModel = DeviceInfoViewModel.map(
            certificate: isE2eIdentityEnabled ? certificate : nil,
            userClient: client,
            title: "some title",
            addedDate: "Monday 15 Oct, 2023",
            proteusID: .mockProteusId,
            isSelfClient: isSelfClient,
            userSession: mockSession,
            credentials: emailCredentials,
            gracePeriod: 3,
            mlsThumbprint: mlsThumbprint,
            getProteusFingerprint: mockSession.mockGetUserClientFingerprintUseCaseProtocol
        )
        viewModel.proteusKeyFingerprint = proteusKeyFingerPrint
        viewModel.isSelfClient = isSelfClient
        viewModel.isProteusVerificationEnabled = isProteusVerificationEnabled
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

    func testWhenMLSViewIsDisabled() {
        let viewModel = prepareViewModel(mlsThumbprint: nil,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testWhenE2eidentityViewIsDisabled() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testGivenSelfClientWhenE2eidentityViewIsDisabled() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {

        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .light, viewModel: viewModel)
        )
    }

    // MARK: - Dark mode

    func testGivenSelfClientWhenE2eidentityViewIsDisabledInDarkMode() {

        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: .mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: .mockFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

}

extension String {
    static var mockProteusId: String {
        "abcdefghijklmnop"
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
    }

    static var mockSerialNumber: String {
        "abcdefghijklmnopqrstuvwxyz"
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
    }

    static var mockFingerPrint: String {
        "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl"
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
    }
}
