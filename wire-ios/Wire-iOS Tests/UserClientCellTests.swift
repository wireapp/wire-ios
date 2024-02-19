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

final class UserClientCellTests: BaseSnapshotTestCase {
    var sut: UserClientCell!
    var container: UIView!

    override func setUp() {
        super.setUp()
        let frame = CGRect(x: 0, y: 0, width: 390, height: 84)
        sut = UserClientCell(frame: frame)
        container = containerView(with: sut, snapshotBackgroundColor: nil)
        container.frame = frame
    }

    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }

    func prepareSut(shouldDisplayMLSInfo: Bool = false,
                    isProteusVerified: Bool = false,
                    e2EIdentityCertificateStatus: E2EIdentityCertificateStatus? = nil,
                    userInterfaceStyle: UIUserInterfaceStyle = .light) {
        sut.viewModel = .mock(isProteusVerified: isProteusVerified,
                              mlsThumbprint: shouldDisplayMLSInfo ? .mockMlsThumbprint : "", e2eIdentityCertificateStatus: e2EIdentityCertificateStatus)
        sut.overrideUserInterfaceStyle = userInterfaceStyle
        container.overrideUserInterfaceStyle = userInterfaceStyle
        sut.layoutIfNeeded()
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
