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
        status: E2EIdentityCertificateStatus,
        isProteusVerificationEnabled: Bool,
        isE2eIdentityEnabled: Bool,
        proteusKeyFingerPrint: String,
        isSelfClient: Bool
    ) -> DeviceInfoViewModel {
        let mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        mockSession.isE2eIdentityEnabled = isE2eIdentityEnabled
        switch status {
        case .notActivated:
            mockSession.certificate = .mockNotActivated
        case .revoked:
            mockSession.certificate = .mockRevoked
        case .expired:
            mockSession.certificate = .mockExpired
        case .valid:
            mockSession.certificate = .mockValid
        }
        let emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
        let dateFormater = DateFormatter()

        let viewModel = DeviceInfoViewModel.map(
            userClient: client,
            title: "some title",
            addedDate: "Monday 15 Oct, 2023",
            proteusID: kSerialNumber,
            isSelfClient: isSelfClient,
            userSession: mockSession,
            credentials: emailCredentials,
            gracePeriod: 3
        )
        viewModel.proteusKeyFingerprint = proteusKeyFingerPrint
        viewModel.isE2eIdentityEnabled = isE2eIdentityEnabled
        viewModel.isSelfClient = isSelfClient
        viewModel.e2eIdentityCertificate = mockSession.certificate
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
        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testGivenSelfClientWhenE2eidentityViewIsDisabled() {
        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        let viewModel = prepareViewModel(status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        let viewModel = prepareViewModel(status: .valid,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        let viewModel = prepareViewModel(status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        let viewModel = prepareViewModel(status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {

        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .light, viewModel: viewModel)
        )
    }

    // MARK: - Dark mode

    func testGivenSelfClientWhenE2eidentityViewIsDisabledInDarkMode() {

        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: true)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        let viewModel = prepareViewModel(status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        let viewModel = prepareViewModel(status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        let viewModel = prepareViewModel(status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        let viewModel = prepareViewModel(status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: kFingerPrint,
                                         isSelfClient: false)
        verify(
            matching: setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)
        )
    }

}
