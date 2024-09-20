//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import SwiftUI
import WireRequestStrategySupport
import WireTestingPackage
import XCTest

@testable import Wire

final class OtherUserDeviceDetailsViewTests: XCTestCase {

    private let mockProteusId: String = "abcdefghijklmnop"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    private let mockFingerPrint: String = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    private var coreDataFixture: CoreDataFixture!
    private var sut: DeviceInfoViewController<OtherUserDeviceDetailsView>!
    private var client: UserClient!
    private var mockContextProvider: ContextProvider!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        coreDataFixture = CoreDataFixture()
        let otherYearFormatter = WRDateFormatter.otherYearFormatter
        XCTAssertEqual(
            otherYearFormatter.locale.identifier,
            "en_US", "otherYearFormatter.locale.identifier is \(otherYearFormatter.locale.identifier)"
        )
        client = coreDataFixture.mockUserClient()
        mockContextProvider = MockContextProvider()
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        client = nil
        coreDataFixture = nil
        mockContextProvider = nil

        super.tearDown()
    }

    func prepareViewModel(
        mlsThumbprint: String?,
        status: E2EIdentityCertificateStatus,
        isProteusVerificationEnabled: Bool,
        isE2eIdentityEnabled: Bool,
        proteusKeyFingerPrint: String,
        showDebugMenu: Bool = false
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
        case .invalid:
            certificate = .mockInvalid
        }

        let emailCredentials = UserEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")
        let deviceActions = MockDeviceDetailsViewActions()
        deviceActions.getProteusFingerPrint_MockValue = proteusKeyFingerPrint
        let viewModel = DeviceInfoViewModel(title: "some title",
                                            addedDate: "Monday 15 Oct, 2023",
                                            proteusID: mockProteusId,
                                            userClient: client,
                                            isSelfClient: false,
                                            gracePeriod: 0,
                                            mlsCiphersuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                                            isFromConversation: true,
                                            actionsHandler: deviceActions,
                                            conversationClientDetailsActions: MockConversationUserClientDetailsActions())
        viewModel.e2eIdentityCertificate = isE2eIdentityEnabled ? certificate : nil
        viewModel.proteusKeyFingerprint = proteusKeyFingerPrint
        viewModel.isProteusVerificationEnabled = isProteusVerificationEnabled
        return viewModel
    }

    func setupWrappedInNavigationController(
        viewModel: DeviceInfoViewModel
    ) -> UINavigationController {
        sut = DeviceInfoViewController(rootView: OtherUserDeviceDetailsView(viewModel: viewModel))
        return sut.wrapInNavigationController()
    }

    func testWhenMLSViewIsDisabled() {
        let viewModel = prepareViewModel(
            mlsThumbprint: nil,
            status: .notActivated,
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: false,
            proteusKeyFingerPrint: mockFingerPrint
        )

        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testThatIsShowsDebugMenu_WhenE2eidentityViewIsDisabled() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: mockFingerPrint,
                                         showDebugMenu: true)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testWhenE2eidentityViewIsDisabled() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(
                viewModel: viewModel
            )
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: false,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {

        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsInvalid() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .invalid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper.verify(
            matching: setupWrappedInNavigationController(viewModel: viewModel)
        )
    }

    // MARK: - Dark mode

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: setupWrappedInNavigationController(viewModel: viewModel))
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .valid,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: setupWrappedInNavigationController(viewModel: viewModel))
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .revoked,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: setupWrappedInNavigationController(viewModel: viewModel))
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .expired,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: setupWrappedInNavigationController(viewModel: viewModel))
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        let viewModel = prepareViewModel(mlsThumbprint: mockFingerPrint,
                                         status: .notActivated,
                                         isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: true,
                                         proteusKeyFingerPrint: mockFingerPrint)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: setupWrappedInNavigationController(viewModel: viewModel))
    }

}
