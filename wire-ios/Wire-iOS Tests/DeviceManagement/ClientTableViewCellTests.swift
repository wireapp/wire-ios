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

import WireTestingPackage
import XCTest

@testable import Wire

final class ClientTableViewCellTests: XCTestCase {

    // MARK: - Properties

    private var sut: ClientTableViewCell!
    private var container: UIView!
    private var snapshotHelper: SnapshotHelper_!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        sut = ClientTableViewCell(style: .default, reuseIdentifier: nil)
        container = containerView(with: sut, snapshotBackgroundColor: nil)
        container.frame = CGRect(x: 0, y: 0, width: 390, height: 84)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helper Method

    func prepareSut(
        shouldDisplayMLSInfo: Bool = false,
        isProteusVerified: Bool = false,
        e2EIdentityCertificateStatus: E2EIdentityCertificateStatus? = nil
    ) {
        sut.viewModel = .mock(
            isProteusVerified: isProteusVerified,
            mlsThumbprint: shouldDisplayMLSInfo ? .mockMlsThumbprint : "",
            e2eIdentityCertificateStatus: e2EIdentityCertificateStatus
        )

    }

    // MARK: - Snapshot Tests

    func testThatMLSInfoIsShown_whenMlsInfoAvailable() {
        // GIVEN && WHEN
        prepareSut(shouldDisplayMLSInfo: true)

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatMLSInfoIsShown_whenMlsInfoIsAvailable_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(shouldDisplayMLSInfo: true)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatMLSInfoIsHidden_whenMlsInfoIsNotAvailable() {
        // GIVEN && WHEN
        prepareSut(shouldDisplayMLSInfo: false)
        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatMLSInfoIsHidden_whenMlsInfoIsNotAvailable_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(shouldDisplayMLSInfo: true)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatProteusBadgeIsDisplayed_whenProteusIsVerified() {
        // GIVEN && WHEN
        prepareSut(isProteusVerified: true)

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatProteusBadgeIsDisplayed_whenProteusIsVerified_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(isProteusVerified: true)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatProteusBadgeIsNotDisplayed_whenProteusIsNotVerified() {
        // GIVEN && WHEN
        prepareSut(isProteusVerified: false)

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatProteusBadgeIsNotDisplayed_whenProteusIsNotVerified_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(isProteusVerified: false)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsValid() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .valid
        )

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsValid_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .valid
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsExpired() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .expired
        )

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsExpired_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .expired
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsRevoked() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .revoked
        )

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsRevoked_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .revoked
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsNotActivated() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .notActivated
        )

        // THEN
        snapshotHelper.verify(matching: container)
    }

    func testThatE2EIStatusAndProteusBadgeIsDisplayed_whenProteusIsNotVerifiedAndE2EIStatusIsNotActivated_inDarkMode() {
        // GIVEN && WHEN
        prepareSut(
            shouldDisplayMLSInfo: true,
            isProteusVerified: true,
            e2EIdentityCertificateStatus: .notActivated
        )

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: container)
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
