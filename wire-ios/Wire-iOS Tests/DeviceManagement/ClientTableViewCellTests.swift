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

@testable import Wire
import XCTest

final class ClientTableViewCellTests: XCTestCase {
    var sut: ClientTableViewCell!
    var container: UIView!

    override func setUp() {
        super.setUp()
        sut = ClientTableViewCell(style: .default, reuseIdentifier: nil)
        container = containerView(with: sut, snapshotBackgroundColor: nil)
        container.frame = CGRect(x: 0, y: 0, width: 390, height: 84)
    }

    func prepareSut(shouldDisplayMLSInfo: Bool = false,
                    isProteusVerified: Bool = false,
                    e2EIdentityCertificateStatus: E2EIdentityCertificateStatus? = nil,
                    userInterfaceStyle: UIUserInterfaceStyle = .light) {
        sut.viewModel = .mock(isProteusVerified: isProteusVerified,
                              mlsThumbprint: shouldDisplayMLSInfo ? .mockMlsThumbprint : "", e2eIdentityCertificateStatus: e2EIdentityCertificateStatus)
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        container.overrideUserInterfaceStyle = userInterfaceStyle
    }

    func testThatMLSInfoIsShown_whenMlsInfoAvailable() {
        prepareSut(shouldDisplayMLSInfo: true)
        verify(matching: container)
    }

    func testThatMLSInfoIsShown_whenMlsInfoIsAvailable_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true, userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatMLSInfoIsHidden_whenMlsInfoIsNotAvailable() {
        prepareSut(shouldDisplayMLSInfo: false)
        verify(matching: container)
    }

    func testThatMLSInfoIsHidden_whenMlsInfoIsNotAvailable_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true, userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatProteusBadgeIsDisplayed_whenProteusIsVerified() {
        prepareSut(isProteusVerified: true)
        verify(matching: container)
    }

    func testThatProteusBadgeIsDisplayed_whenProteusIsVerified_inDarkMode() {
        prepareSut(isProteusVerified: true, userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatProteusBadgeIsNotDisplayed_whenProteusIsNotVerified() {
        prepareSut(isProteusVerified: false)
        verify(matching: container)
    }

    func testThatProteusBadgeIsNotDisplayed_whenProteusIsNotVerified_inDarkMode() {
        prepareSut(isProteusVerified: false, userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsValid() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .valid)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsValid_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .valid,
                   userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsExpired() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .expired)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsExpired_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .expired,
                   userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsRevoked() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .revoked)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsRevoked_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .revoked,
                   userInterfaceStyle: .dark)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsNotActivated() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .notActivated)
        verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsNotActivated_inDarkMode() {
        prepareSut(shouldDisplayMLSInfo: true,
                   isProteusVerified: true,
                   e2EIdentityCertificateStatus: .notActivated,
                   userInterfaceStyle: .dark)
        verify(matching: container)
    }

}

extension ClientTableViewCellModel {
    typealias DeviceDetailsSection = L10n.Localizable.Device.Details.Section

    private static let mockProteusId: String = "abcdefghijklmnop"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    private static let mockFingerPrint: String = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl"
        .uppercased()
        .splitStringIntoLines(charactersPerLine: 16)

    static func mock(title: String = "Lorem ipsum",
                     isProteusVerified: Bool = false,
                     mlsThumbprint: String = mockFingerPrint,
                     proteusId: String = mockProteusId,
                     e2eIdentityCertificateStatus: E2EIdentityCertificateStatus? = nil
    ) -> Self {
        .init(
            title: title,
            proteusLabelText: !proteusId.isEmpty ? DeviceDetailsSection.Proteus.value(proteusId) : "",
            mlsThumbprintLabelText: !mlsThumbprint.isEmpty ? DeviceDetailsSection.Mls.thumbprint(mlsThumbprint) : "",
            isProteusVerified: isProteusVerified,
            e2eIdentityStatus: e2eIdentityCertificateStatus,
            activationDate: .now
        )
    }
}
