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
import WireRequestStrategySupport

final class DeviceDetailsViewTests: BaseSnapshotTestCase, CoreDataFixtureTestHelper {

    private let mockProteusId: String = "abcdefghijklmnop"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    private let mockFingerPrint: String = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    var coreDataFixture: CoreDataFixture!
    var sut: UIHostingController<DeviceDetailsView>!
    var client: UserClient!
    var mockContextProvider: ContextProvider!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        let otherYearFormatter = WRDateFormatter.otherYearFormatter
        XCTAssertEqual(
            otherYearFormatter.locale.identifier,
            "en_US", "otherYearFormatter.locale.identifier is \(otherYearFormatter.locale.identifier)"
        )
        client = mockUserClient()
        mockContextProvider = MockContextProvider()
    }

    override func tearDown() {
        sut = nil
        client = nil
        coreDataFixture = nil
        mockContextProvider = nil

        super.tearDown()
    }

    func prepareViewModel(
        isProteusVerificationEnabled: Bool,
        isE2eIdentityEnabled: Bool,
        proteusKeyFingerPrint: String,
        isSelfClient: Bool
    ) -> DeviceInfoViewModel {
        let mockSession = UserSessionMock(mockUser: .createSelfUser(name: "Joe"))
        mockSession.isE2eIdentityEnabled = isE2eIdentityEnabled

        let emailCredentials = ZMEmailCredentials(email: "test@rad.com", password: "smalsdldl231S#")

        let deviceActionsHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: mockSession,
            credentials: emailCredentials,
            saveFileManager: SaveFileManager(systemFileSavePresenter: MockSystemSaveFilePresenter()),
            getProteusFingerprint: mockSession.mockGetUserClientFingerprintUseCaseProtocol,
            contextProvider: mockContextProvider,
            e2eiCertificateEnrollment: MockEnrollE2EICertificateUseCaseProtocol()
        )

        let viewModel = DeviceInfoViewModel(
            title: "some title",
            addedDate: "Monday 15 Oct, 2023",
            proteusID: mockProteusId,
            userClient: client,
            isSelfClient: isSelfClient,
            gracePeriod: 3,
            isFromConversation: false,
            actionsHandler: deviceActionsHandler,
            conversationClientDetailsActions: deviceActionsHandler,
            debugMenuActionsHandler: deviceActionsHandler,
            showDebugMenu: false
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
        return sut.wrapInNavigationController()
    }

    func testWhenMLSViewIsDisabled() {
        client.e2eIdentityCertificate = nil

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: false,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsDisabled() {
        client.e2eIdentityCertificate = nil

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: mockFingerPrint,
                                         isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testGivenSelfClientWhenE2eidentityViewIsDisabled() {
        client.e2eIdentityCertificate = nil

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: false,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValid() {
        client.e2eIdentityCertificate = .mockValid

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidWhenProteusIsNotVerifiedThenBlueShieldIsNotShown() {
        client.e2eIdentityCertificate = .mockValid

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: false,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevoked() {
        client.e2eIdentityCertificate = .mockRevoked

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpired() {
        client.e2eIdentityCertificate = .mockExpired

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivated() {
        client.e2eIdentityCertificate = .mockNotActivated

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(mode: .light, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityIsEnabledAndCertificateIsExpiredForOtherClient() {
        client.e2eIdentityCertificate = .mockExpired

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityIsEnabledAndCertificateIsNotActivatedForOtherClient() {
        client.e2eIdentityCertificate = .mockNotActivated

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .light, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsInvalid() {
        client.e2eIdentityCertificate = .mockInvalid

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(viewModel: viewModel)

        verify(matching: viewController)
    }

    // MARK: - Dark mode

    func testGivenSelfClientWhenE2eidentityViewIsDisabledInDarkMode() {
        client.e2eIdentityCertificate = nil

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: false,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsDisabledInDarkMode() {
        client.e2eIdentityCertificate = nil

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
                                         isE2eIdentityEnabled: false,
                                         proteusKeyFingerPrint: mockFingerPrint,
                                         isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsValidInDarkMode() {
        client.e2eIdentityCertificate = .mockValid

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsRevokedInDarkMode() {
        client.e2eIdentityCertificate = .mockRevoked

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkMode() {
        client.e2eIdentityCertificate = .mockExpired

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkMode() {
        client.e2eIdentityCertificate = .mockNotActivated

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: true
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsExpiredInDarkModeForOtherClient() {
        client.e2eIdentityCertificate = .mockExpired

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

    func testWhenE2eidentityViewIsEnabledAndCertificateIsNotActivatedInDarkModeForOtherClient() {
        client.e2eIdentityCertificate = .mockNotActivated

        let viewModel = prepareViewModel(
            isProteusVerificationEnabled: true,
            isE2eIdentityEnabled: true,
            proteusKeyFingerPrint: mockFingerPrint,
            isSelfClient: false
        )
        let viewController = setupWrappedInNavigationController(mode: .dark, viewModel: viewModel)

        verify(matching: viewController)
    }

}
